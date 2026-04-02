#!/usr/bin/env python3
"""
VIO World Monitor — Real-time System + Network + Services Dashboard
Integrated with VS Code, accessible via browser.
© 2026 VIO Super AI — Proprietary Software
"""

import http.server
import json
import os
import platform
import errno
import socket
import socketserver
import ssl
import threading
import time
import urllib.error
import urllib.request
from collections import deque
from datetime import datetime

import psutil

# ─────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────
PORT = 7777
REFRESH_INTERVAL = 3  # seconds
HISTORY_MAX = 120  # data points (~6 min at 3s)

# Services to probe (name, url, timeout)
WORLD_SERVICES = [
    ("GitHub", "https://github.com", 5),
    ("Google", "https://www.google.com", 5),
    ("Cloudflare DNS", "https://1.1.1.1", 5),
    ("PyPI", "https://pypi.org", 5),
    ("npm Registry", "https://registry.npmjs.org", 5),
    ("Docker Hub", "https://hub.docker.com", 5),
    ("Homebrew API", "https://formulae.brew.sh/api/formula.json", 5),
]

# ─────────────────────────────────────────────────────────────
# Global state
# ─────────────────────────────────────────────────────────────
monitor_data = {
    "running": False,
    "system": {},
    "network": {},
    "services": [],
    "processes": [],
    "history_cpu": deque(maxlen=HISTORY_MAX),
    "history_ram": deque(maxlen=HISTORY_MAX),
    "history_net_sent": deque(maxlen=HISTORY_MAX),
    "history_net_recv": deque(maxlen=HISTORY_MAX),
    "last_update": None,
    "start_time": None,
    "alerts": deque(maxlen=50),
}

_prev_net = None


class ReusableTCPServer(socketserver.TCPServer):
    """TCP server with address reuse to reduce restart collisions."""

    allow_reuse_address = True


def get_local_ip():
    """Best-effort local IP detection."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.settimeout(0.5)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"


# ─────────────────────────────────────────────────────────────
# Data collectors
# ─────────────────────────────────────────────────────────────
def collect_system():
    vm = psutil.virtual_memory()
    disk = psutil.disk_usage("/")
    try:
        load = os.getloadavg()
    except (OSError, AttributeError):
        load = (0, 0, 0)

    boot = datetime.fromtimestamp(psutil.boot_time())
    uptime = datetime.now() - boot
    cpu_freq = psutil.cpu_freq()

    return {
        "hostname": platform.node(),
        "os": f"{platform.system()} {platform.release()}",
        "arch": platform.machine(),
        "python": platform.python_version(),
        "cpu_count": psutil.cpu_count(logical=True),
        "cpu_freq_mhz": round(cpu_freq.current, 0) if cpu_freq else 0,
        "cpu_percent": psutil.cpu_percent(interval=0.5),
        "ram_percent": vm.percent,
        "ram_used_gb": round(vm.used / (1024**3), 2),
        "ram_total_gb": round(vm.total / (1024**3), 2),
        "ram_available_gb": round(vm.available / (1024**3), 2),
        "swap_percent": psutil.swap_memory().percent,
        "disk_percent": disk.percent,
        "disk_used_gb": round(disk.used / (1024**3), 1),
        "disk_total_gb": round(disk.total / (1024**3), 1),
        "disk_free_gb": round(disk.free / (1024**3), 1),
        "load_1": round(load[0], 2),
        "load_5": round(load[1], 2),
        "load_15": round(load[2], 2),
        "process_count": len(psutil.pids()),
        "uptime_str": f"{uptime.days}d {uptime.seconds // 3600}h {(uptime.seconds % 3600) // 60}m",
        "pressure": "CRITICAL" if vm.percent > 90 else "HIGH" if vm.percent > 80 else "MODERATE" if vm.percent > 60 else "LOW",
    }


def collect_network():
    global _prev_net
    counters = psutil.net_io_counters()
    now = time.time()

    speed_up = 0.0
    speed_down = 0.0
    if _prev_net:
        dt = now - _prev_net["time"]
        if dt > 0:
            speed_up = (counters.bytes_sent - _prev_net["sent"]) / dt
            speed_down = (counters.bytes_recv - _prev_net["recv"]) / dt

    _prev_net = {"sent": counters.bytes_sent, "recv": counters.bytes_recv, "time": now}

    connections = psutil.net_connections(kind="inet")
    active = sum(1 for c in connections if c.status == "ESTABLISHED")
    listening = sum(1 for c in connections if c.status == "LISTEN")

    return {
        "local_ip": get_local_ip(),
        "total_sent_gb": round(counters.bytes_sent / (1024**3), 2),
        "total_recv_gb": round(counters.bytes_recv / (1024**3), 2),
        "speed_up_kbs": round(speed_up / 1024, 1),
        "speed_down_kbs": round(speed_down / 1024, 1),
        "packets_sent": counters.packets_sent,
        "packets_recv": counters.packets_recv,
        "active_connections": active,
        "listening_ports": listening,
    }


def collect_services():
    results = []
    ctx = ssl.create_default_context()
    for name, url, timeout in WORLD_SERVICES:
        start = time.time()
        status = "DOWN"
        latency_ms = 0
        try:
            req = urllib.request.Request(url, method="HEAD")
            req.add_header("User-Agent", "VIO-WorldMonitor/1.0")
            with urllib.request.urlopen(req, timeout=timeout, context=ctx) as resp:
                if resp.status < 400:
                    status = "UP"
                else:
                    status = f"HTTP {resp.status}"
        except urllib.error.HTTPError as e:
            # Some services return 405 for HEAD but are still up
            if e.code in (405, 403, 301, 302, 308):
                status = "UP"
            else:
                status = f"HTTP {e.code}"
        except Exception:
            status = "DOWN"
        latency_ms = round((time.time() - start) * 1000, 0)
        results.append({"name": name, "url": url, "status": status, "latency_ms": latency_ms})
    return results


def collect_processes(n=10):
    procs = []
    for p in psutil.process_iter(["pid", "name", "cpu_percent", "memory_percent", "status"]):
        try:
            info = p.info
            if info["cpu_percent"] is not None and info["memory_percent"] is not None:
                procs.append(info)
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
    procs.sort(key=lambda x: (x["cpu_percent"] or 0) + (x["memory_percent"] or 0), reverse=True)
    return [
        {
            "pid": p["pid"],
            "name": p["name"],
            "cpu": round(p["cpu_percent"], 1),
            "mem": round(p["memory_percent"], 1),
            "status": p["status"],
        }
        for p in procs[:n]
    ]


def check_alerts(sys_data, net_data):
    ts = datetime.now().strftime("%H:%M:%S")
    if sys_data.get("ram_percent", 0) > 90:
        monitor_data["alerts"].appendleft(f"[{ts}] CRITICAL: RAM al {sys_data['ram_percent']}%")
    elif sys_data.get("ram_percent", 0) > 80:
        monitor_data["alerts"].appendleft(f"[{ts}] WARNING: RAM al {sys_data['ram_percent']}%")

    if sys_data.get("cpu_percent", 0) > 95:
        monitor_data["alerts"].appendleft(f"[{ts}] CRITICAL: CPU al {sys_data['cpu_percent']}%")

    if sys_data.get("disk_percent", 0) > 90:
        monitor_data["alerts"].appendleft(f"[{ts}] WARNING: Disco al {sys_data['disk_percent']}%")


# ─────────────────────────────────────────────────────────────
# Background loop
# ─────────────────────────────────────────────────────────────
def background_loop():
    service_check_counter = 0
    while monitor_data["running"]:
        try:
            sys_data = collect_system()
            net_data = collect_network()
            proc_data = collect_processes(10)

            # Services only every ~30s to avoid hammering
            service_check_counter += 1
            if service_check_counter >= 10:
                svc_data = collect_services()
                monitor_data["services"] = svc_data
                service_check_counter = 0

            monitor_data["system"] = sys_data
            monitor_data["network"] = net_data
            monitor_data["processes"] = proc_data

            monitor_data["history_cpu"].append(sys_data.get("cpu_percent", 0))
            monitor_data["history_ram"].append(sys_data.get("ram_percent", 0))
            monitor_data["history_net_sent"].append(net_data.get("speed_up_kbs", 0))
            monitor_data["history_net_recv"].append(net_data.get("speed_down_kbs", 0))

            check_alerts(sys_data, net_data)
            monitor_data["last_update"] = datetime.now().isoformat()
        except Exception as e:
            monitor_data["alerts"].appendleft(f"[ERR] {e}")
        time.sleep(REFRESH_INTERVAL)


# ─────────────────────────────────────────────────────────────
# HTTP Server (no Flask needed — zero extra deps beyond psutil)
# ─────────────────────────────────────────────────────────────
DASHBOARD_HTML = r"""<!DOCTYPE html>
<html lang="it">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>VIO World Monitor</title>
<style>
:root{--bg:#0d1117;--card:#161b22;--accent:#58a6ff;--green:#3fb950;--yellow:#d29922;--red:#f85149;--text:#c9d1d9;--dim:#8b949e;--border:#30363d}
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,BlinkMacSystemFont,'SF Pro',system-ui,sans-serif;background:var(--bg);color:var(--text);min-height:100vh}
.top-bar{background:linear-gradient(90deg,#0d1117 0%,#161b22 100%);border-bottom:1px solid var(--border);padding:12px 20px;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:100}
.top-bar h1{font-size:18px;font-weight:700;background:linear-gradient(135deg,var(--accent),var(--green));-webkit-background-clip:text;-webkit-text-fill-color:transparent}
.top-bar .status{font-size:12px;display:flex;align-items:center;gap:6px}
.dot{width:8px;height:8px;border-radius:50%;display:inline-block}
.dot.on{background:var(--green);box-shadow:0 0 6px var(--green)}
.dot.off{background:var(--red)}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(340px,1fr));gap:14px;padding:14px;max-width:1400px;margin:0 auto}
.card{background:var(--card);border:1px solid var(--border);border-radius:12px;padding:16px;transition:border-color .2s}
.card:hover{border-color:var(--accent)}
.card h2{font-size:13px;text-transform:uppercase;letter-spacing:1px;color:var(--dim);margin-bottom:12px;display:flex;align-items:center;gap:8px}
.card h2 .icon{font-size:16px}
.stat-row{display:flex;justify-content:space-between;align-items:center;padding:6px 0;border-bottom:1px solid rgba(48,54,61,.5)}
.stat-row:last-child{border:none}
.stat-label{font-size:13px;color:var(--dim)}
.stat-val{font-size:14px;font-weight:600;font-variant-numeric:tabular-nums}
.bar-wrap{width:100%;height:6px;background:rgba(88,166,255,.15);border-radius:3px;margin-top:4px;overflow:hidden}
.bar-fill{height:100%;border-radius:3px;transition:width .6s ease}
.bar-fill.ok{background:var(--green)}.bar-fill.warn{background:var(--yellow)}.bar-fill.crit{background:var(--red)}
.svc-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px}
.svc-item{background:rgba(88,166,255,.05);border:1px solid var(--border);border-radius:8px;padding:10px;display:flex;justify-content:space-between;align-items:center}
.svc-name{font-size:12px;font-weight:600}
.svc-badge{font-size:11px;padding:2px 8px;border-radius:4px;font-weight:700}
.svc-badge.up{background:rgba(63,185,80,.15);color:var(--green)}
.svc-badge.down{background:rgba(248,81,73,.15);color:var(--red)}
.svc-latency{font-size:11px;color:var(--dim)}
.proc-table{width:100%;border-collapse:collapse;font-size:12px}
.proc-table th{text-align:left;padding:4px 8px;color:var(--dim);font-weight:600;border-bottom:1px solid var(--border)}
.proc-table td{padding:4px 8px;border-bottom:1px solid rgba(48,54,61,.3)}
.proc-table tr:hover td{background:rgba(88,166,255,.05)}
.chart-wrap{position:relative;height:80px;margin-top:8px}
canvas{width:100%!important;height:80px!important;border-radius:6px}
.alert-list{max-height:140px;overflow-y:auto;font-size:12px;font-family:'SF Mono',monospace}
.alert-item{padding:4px 0;border-bottom:1px solid rgba(48,54,61,.3);color:var(--yellow)}
.alert-item.crit{color:var(--red)}
.footer{text-align:center;font-size:11px;color:var(--dim);padding:16px}
@media(max-width:600px){.grid{grid-template-columns:1fr}.svc-grid{grid-template-columns:1fr}}
</style>
</head>
<body>
<div class="top-bar">
  <h1>&#127760; VIO World Monitor</h1>
  <div class="status"><span class="dot" id="dot"></span><span id="status-text">Connecting…</span></div>
</div>
<div class="grid">
  <!-- SYSTEM -->
  <div class="card">
    <h2><span class="icon">&#9889;</span> Sistema</h2>
    <div class="stat-row"><span class="stat-label">Host</span><span class="stat-val" id="hostname">—</span></div>
    <div class="stat-row"><span class="stat-label">OS</span><span class="stat-val" id="os">—</span></div>
    <div class="stat-row"><span class="stat-label">Uptime</span><span class="stat-val" id="uptime">—</span></div>
    <div class="stat-row"><span class="stat-label">Processi</span><span class="stat-val" id="procs">—</span></div>
  </div>
  <!-- CPU -->
  <div class="card">
    <h2><span class="icon">&#128187;</span> CPU</h2>
    <div class="stat-row"><span class="stat-label">Utilizzo</span><span class="stat-val" id="cpu-pct">—</span></div>
    <div class="bar-wrap"><div class="bar-fill ok" id="cpu-bar" style="width:0%"></div></div>
    <div class="stat-row"><span class="stat-label">Core</span><span class="stat-val" id="cpu-cores">—</span></div>
    <div class="stat-row"><span class="stat-label">Load Avg</span><span class="stat-val" id="load-avg">—</span></div>
    <div class="chart-wrap"><canvas id="chart-cpu"></canvas></div>
  </div>
  <!-- RAM -->
  <div class="card">
    <h2><span class="icon">&#128200;</span> Memoria RAM</h2>
    <div class="stat-row"><span class="stat-label">Utilizzo</span><span class="stat-val" id="ram-pct">—</span></div>
    <div class="bar-wrap"><div class="bar-fill ok" id="ram-bar" style="width:0%"></div></div>
    <div class="stat-row"><span class="stat-label">Usata / Totale</span><span class="stat-val" id="ram-detail">—</span></div>
    <div class="stat-row"><span class="stat-label">Pressione</span><span class="stat-val" id="pressure">—</span></div>
    <div class="chart-wrap"><canvas id="chart-ram"></canvas></div>
  </div>
  <!-- DISCO -->
  <div class="card">
    <h2><span class="icon">&#128190;</span> Disco</h2>
    <div class="stat-row"><span class="stat-label">Utilizzo</span><span class="stat-val" id="disk-pct">—</span></div>
    <div class="bar-wrap"><div class="bar-fill ok" id="disk-bar" style="width:0%"></div></div>
    <div class="stat-row"><span class="stat-label">Libero</span><span class="stat-val" id="disk-free">—</span></div>
  </div>
  <!-- RETE -->
  <div class="card">
    <h2><span class="icon">&#127760;</span> Rete</h2>
    <div class="stat-row"><span class="stat-label">IP Locale</span><span class="stat-val" id="local-ip">—</span></div>
    <div class="stat-row"><span class="stat-label">&#8593; Upload</span><span class="stat-val" id="net-up">—</span></div>
    <div class="stat-row"><span class="stat-label">&#8595; Download</span><span class="stat-val" id="net-down">—</span></div>
    <div class="stat-row"><span class="stat-label">Connessioni attive</span><span class="stat-val" id="net-conn">—</span></div>
    <div class="stat-row"><span class="stat-label">Porte in ascolto</span><span class="stat-val" id="net-listen">—</span></div>
    <div class="chart-wrap"><canvas id="chart-net"></canvas></div>
  </div>
  <!-- SERVIZI MONDO -->
  <div class="card" style="grid-column:span 2">
    <h2><span class="icon">&#127758;</span> Servizi Globali</h2>
    <div class="svc-grid" id="svc-grid"><div class="svc-item"><span class="svc-name">Caricamento…</span></div></div>
  </div>
  <!-- TOP PROCESSI -->
  <div class="card" style="grid-column:span 2">
    <h2><span class="icon">&#128202;</span> Top Processi</h2>
    <table class="proc-table">
      <thead><tr><th>#</th><th>Nome</th><th>PID</th><th>CPU%</th><th>RAM%</th><th>Stato</th></tr></thead>
      <tbody id="proc-body"><tr><td colspan="6">Caricamento…</td></tr></tbody>
    </table>
  </div>
  <!-- ALERTS -->
  <div class="card" style="grid-column:span 2">
    <h2><span class="icon">&#128680;</span> Alerts</h2>
    <div class="alert-list" id="alert-list"><div class="alert-item">In attesa di dati…</div></div>
  </div>
</div>
<div class="footer">VIO World Monitor v1.0 &mdash; &copy; 2026 VIO Super AI &mdash; <span id="last-upd">—</span></div>

<script>
// Mini chart renderer (no deps)
class MiniChart{constructor(id,color,maxPts){this.canvas=document.getElementById(id);this.ctx=this.canvas.getContext('2d');this.color=color;this.maxPts=maxPts;this.data=[]}
push(v){this.data.push(v);if(this.data.length>this.maxPts)this.data.shift();this.draw()}
draw(){const c=this.ctx,w=this.canvas.width=this.canvas.offsetWidth*2,h=this.canvas.height=80*2;
c.clearRect(0,0,w,h);if(this.data.length<2)return;
const max=Math.max(100,...this.data),step=w/(this.maxPts-1);
c.beginPath();c.moveTo(0,h);
for(let i=0;i<this.data.length;i++){const x=i*step,y=h-(this.data[i]/max)*h*0.9;if(i===0)c.moveTo(x,y);else c.lineTo(x,y)}
c.lineTo((this.data.length-1)*step,h);c.lineTo(0,h);c.closePath();
const g=c.createLinearGradient(0,0,0,h);g.addColorStop(0,this.color+'66');g.addColorStop(1,this.color+'08');c.fillStyle=g;c.fill();
c.beginPath();for(let i=0;i<this.data.length;i++){const x=i*step,y=h-(this.data[i]/max)*h*0.9;if(i===0)c.moveTo(x,y);else c.lineTo(x,y)}
c.strokeStyle=this.color;c.lineWidth=2;c.stroke()}}

const cpuChart=new MiniChart('chart-cpu','#58a6ff',120);
const ramChart=new MiniChart('chart-ram','#3fb950',120);
const netChart=new MiniChart('chart-net','#d29922',120);

function barClass(v){return v>90?'crit':v>70?'warn':'ok'}
function pressureColor(p){return p==='CRITICAL'?'var(--red)':p==='HIGH'?'var(--yellow)':p==='MODERATE'?'var(--accent)':'var(--green)'}

function update(){
fetch('/api/data').then(r=>r.json()).then(d=>{
  document.getElementById('dot').className='dot on';
  document.getElementById('status-text').textContent='Live — aggiornamento ogni 3s';
  const s=d.system||{},n=d.network||{};
  // System
  document.getElementById('hostname').textContent=s.hostname||'—';
  document.getElementById('os').textContent=s.os||'—';
  document.getElementById('uptime').textContent=s.uptime_str||'—';
  document.getElementById('procs').textContent=s.process_count||'—';
  // CPU
  const cpu=s.cpu_percent||0;
  document.getElementById('cpu-pct').textContent=cpu.toFixed(1)+'%';
  const cpuBar=document.getElementById('cpu-bar');cpuBar.style.width=cpu+'%';cpuBar.className='bar-fill '+barClass(cpu);
  document.getElementById('cpu-cores').textContent=(s.cpu_count||'—')+' core @ '+(s.cpu_freq_mhz||0)+' MHz';
  document.getElementById('load-avg').textContent=(s.load_1||0)+' / '+(s.load_5||0)+' / '+(s.load_15||0);
  cpuChart.push(cpu);
  // RAM
  const ram=s.ram_percent||0;
  document.getElementById('ram-pct').textContent=ram.toFixed(1)+'%';
  const ramBar=document.getElementById('ram-bar');ramBar.style.width=ram+'%';ramBar.className='bar-fill '+barClass(ram);
  document.getElementById('ram-detail').textContent=(s.ram_used_gb||0)+' / '+(s.ram_total_gb||0)+' GB';
  const pEl=document.getElementById('pressure');pEl.textContent=s.pressure||'—';pEl.style.color=pressureColor(s.pressure);
  ramChart.push(ram);
  // Disk
  const disk=s.disk_percent||0;
  document.getElementById('disk-pct').textContent=disk.toFixed(1)+'%';
  const diskBar=document.getElementById('disk-bar');diskBar.style.width=disk+'%';diskBar.className='bar-fill '+barClass(disk);
  document.getElementById('disk-free').textContent=(s.disk_free_gb||0)+' GB liberi su '+(s.disk_total_gb||0)+' GB';
  // Network
  document.getElementById('local-ip').textContent=n.local_ip||'—';
  document.getElementById('net-up').textContent=(n.speed_up_kbs||0).toFixed(1)+' KB/s';
  document.getElementById('net-down').textContent=(n.speed_down_kbs||0).toFixed(1)+' KB/s';
  document.getElementById('net-conn').textContent=n.active_connections||'—';
  document.getElementById('net-listen').textContent=n.listening_ports||'—';
  netChart.push(n.speed_down_kbs||0);
  // Services
  const svcs=d.services||[];
  if(svcs.length){
    document.getElementById('svc-grid').innerHTML=svcs.map(sv=>{
      const up=sv.status==='UP';
      return `<div class="svc-item"><div><div class="svc-name">${sv.name}</div><div class="svc-latency">${sv.latency_ms}ms</div></div><span class="svc-badge ${up?'up':'down'}">${sv.status}</span></div>`
    }).join('')}
  // Processes
  const procs=d.processes||[];
  document.getElementById('proc-body').innerHTML=procs.map((p,i)=>`<tr><td>${i+1}</td><td>${p.name}</td><td>${p.pid}</td><td>${p.cpu}%</td><td>${p.mem}%</td><td>${p.status}</td></tr>`).join('');
  // Alerts
  const alerts=d.alerts||[];
  if(alerts.length){document.getElementById('alert-list').innerHTML=alerts.map(a=>`<div class="alert-item${a.includes('CRITICAL')?' crit':''}">${a}</div>`).join('')}
  // Footer
  document.getElementById('last-upd').textContent='Ultimo aggiornamento: '+new Date().toLocaleTimeString('it-IT');
}).catch(()=>{
  document.getElementById('dot').className='dot off';
  document.getElementById('status-text').textContent='Disconnesso';
})}
setInterval(update,3000);update();
</script>
</body>
</html>"""


class WorldMonitorHandler(http.server.BaseHTTPRequestHandler):
    """HTTP handler — serves dashboard and API."""

    def log_message(self, format, *args):
        pass  # Suppress default logging

    def _send_json(self, data, status=200):
        payload = json.dumps(data).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(payload)

    def _send_html(self, html, status=200):
        payload = html.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self):
        if self.path == "/api/data":
            self._send_json(
                {
                    "system": monitor_data["system"],
                    "network": monitor_data["network"],
                    "services": monitor_data["services"],
                    "processes": monitor_data["processes"],
                    "alerts": list(monitor_data["alerts"]),
                    "history_cpu": list(monitor_data["history_cpu"]),
                    "history_ram": list(monitor_data["history_ram"]),
                    "last_update": monitor_data["last_update"],
                }
            )
        elif self.path == "/api/health":
            self._send_json({"status": "ok", "running": monitor_data["running"]})
        elif self.path == "/":
            self._send_html(DASHBOARD_HTML)
        else:
            self.send_error(404)

    def do_HEAD(self):
        if self.path == "/api/health":
            self.send_response(200)
            self.end_headers()
        else:
            self.send_error(404)


def probe_running_monitor(port, timeout=1.0):
    """Return True if a World Monitor instance is already serving the health endpoint."""
    url = f"http://127.0.0.1:{port}/api/health"
    try:
        with urllib.request.urlopen(url, timeout=timeout) as response:
            if response.status != 200:
                return False
            payload = json.loads(response.read().decode("utf-8"))
            return payload.get("status") == "ok"
    except Exception:
        return False


def create_server(host, start_port, max_tries=20):
    """Bind server on the requested port, fallback to next available ports if occupied.
    Falls back to 127.0.0.1 if binding on 0.0.0.0 is forbidden (e.g. sandboxed env).
    """
    for delta in range(max_tries):
        candidate_port = start_port + delta
        try:
            server = ReusableTCPServer((host, candidate_port), WorldMonitorHandler)
            return server, candidate_port
        except OSError as exc:
            if exc.errno == errno.EADDRINUSE:
                continue
            if exc.errno == errno.EPERM and host != "127.0.0.1":
                print(f"[WARN] Binding su {host} non consentito (EPERM), fallback a 127.0.0.1")
                return create_server("127.0.0.1", start_port, max_tries)
            raise
    raise OSError(errno.EADDRINUSE, f"No free port available from {start_port} to {start_port + max_tries - 1}")


def main():
    requested_port = PORT

    if probe_running_monitor(requested_port):
        print(f"\n[INFO] World Monitor gia attivo su http://localhost:{requested_port}")
        print("[INFO] Nessuna nuova istanza avviata per evitare conflitti.\n")
        return

    bind_host = "0.0.0.0"
    server, active_port = create_server(bind_host, requested_port)

    banner = f"""
╔══════════════════════════════════════════════════════════╗
║   🌍  VIO WORLD MONITOR v1.0                            ║
║   Real-time System • Network • Global Services          ║
║   © 2026 VIO Super AI                                   ║
╠══════════════════════════════════════════════════════════╣
║   Dashboard: http://localhost:{active_port}                     ║
║   LAN:       http://{get_local_ip()}:{active_port}              ║
║   API:       http://localhost:{active_port}/api/data            ║
║   Health:    http://localhost:{active_port}/api/health           ║
╠══════════════════════════════════════════════════════════╣
║   Ctrl+C per fermare                                    ║
╚══════════════════════════════════════════════════════════╝
"""
    print(banner)

    # Start background collection
    monitor_data["running"] = True
    monitor_data["start_time"] = datetime.now().isoformat()
    bg = threading.Thread(target=background_loop, daemon=True)
    bg.start()

    # Kick off first service check immediately
    threading.Thread(target=lambda: monitor_data.update({"services": collect_services()}), daemon=True).start()

    # Start HTTP server (0.0.0.0 for LAN access)
    with server as httpd:
        if active_port != requested_port:
            print(f"[WARN] Porta {requested_port} occupata, uso la porta {active_port}.")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n⏹  World Monitor fermato.")
            monitor_data["running"] = False


if __name__ == "__main__":
    main()
