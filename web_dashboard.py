#!/usr/bin/env python3
"""
VIO Super AI - Web Dashboard for iPhone
Provides web-based interface accessible from iPhone
© 2025 VIO Super AI - Proprietary Software
"""

from flask import Flask, render_template, jsonify, request
import psutil
import os
import json
from datetime import datetime
from pathlib import Path
import threading
import time

app = Flask(__name__)

# Global state
monitor_state = {
    'running': False,
    'stats': {},
    'processes': [],
    'killed_count': 0,
    'last_update': None
}

def get_system_stats():
    """Get current system statistics"""
    try:
        vm = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        try:
            load_avg = os.getloadavg()
        except (OSError, AttributeError):
            load_avg = (0, 0, 0)
        
        boot_time = datetime.fromtimestamp(psutil.boot_time())
        uptime_delta = datetime.now() - boot_time
        
        stats = {
            'cpu_percent': psutil.cpu_percent(interval=1),
            'ram_percent': vm.percent,
            'ram_used_gb': vm.used / (1024**3),
            'ram_total_gb': vm.total / (1024**3),
            'ram_free_gb': vm.available / (1024**3),
            'disk_percent': disk.percent,
            'disk_used_gb': disk.used / (1024**3),
            'disk_total_gb': disk.total / (1024**3),
            'load_avg_1': load_avg[0],
            'load_avg_5': load_avg[1],
            'load_avg_15': load_avg[2],
            'process_count': len(psutil.pids()),
            'uptime_days': uptime_delta.days,
            'uptime_hours': uptime_delta.seconds // 3600,
            'uptime_minutes': (uptime_delta.seconds % 3600) // 60,
            'timestamp': datetime.now().isoformat(),
        }
        
        if stats['ram_percent'] > 85:
            stats['memory_pressure'] = 'High'
        elif stats['ram_percent'] > 60:
            stats['memory_pressure'] = 'Moderate'
        else:
            stats['memory_pressure'] = 'Low'
        
        return stats
    except Exception as e:
        print(f"Error getting stats: {e}")
        return {}

def get_top_processes(n=10):
    """Get top N resource-consuming processes"""
    try:
        processes = []
        for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
            try:
                info = proc.info
                if info['cpu_percent'] is not None and info['memory_percent'] is not None:
                    processes.append(info)
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass
        
        processes.sort(key=lambda x: x['cpu_percent'] + x['memory_percent'], reverse=True)
        return processes[:n]
    except Exception as e:
        print(f"Error getting processes: {e}")
        return []

def update_monitor_state():
    """Background task to update monitor state"""
    while monitor_state['running']:
        try:
            monitor_state['stats'] = get_system_stats()
            monitor_state['processes'] = get_top_processes(5)
            monitor_state['last_update'] = datetime.now().isoformat()
            time.sleep(2)
        except Exception as e:
            print(f"Error in background update: {e}")
            time.sleep(5)

@app.route('/')
def index():
    """Main dashboard page"""
    return render_template('dashboard.html')

@app.route('/api/stats')
def api_stats():
    """API endpoint for system stats"""
    return jsonify({
        'success': True,
        'stats': monitor_state['stats'],
        'processes': monitor_state['processes'],
        'killed_count': monitor_state['killed_count'],
        'last_update': monitor_state['last_update']
    })

@app.route('/api/start', methods=['POST'])
def api_start():
    """Start monitoring"""
    if not monitor_state['running']:
        monitor_state['running'] = True
        thread = threading.Thread(target=update_monitor_state, daemon=True)
        thread.start()
        return jsonify({'success': True, 'message': 'Monitoring started'})
    return jsonify({'success': False, 'message': 'Already running'})

@app.route('/api/stop', methods=['POST'])
def api_stop():
    """Stop monitoring"""
    monitor_state['running'] = False
    return jsonify({'success': True, 'message': 'Monitoring stopped'})

def create_dashboard_html():
    """Create the dashboard HTML template"""
    template_dir = Path(__file__).parent / 'templates'
    template_dir.mkdir(exist_ok=True)
    
    html_content = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <title>VIO Super AI Monitor</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #333;
            min-height: 100vh;
            padding: 10px;
        }
        
        .container {
            max-width: 800px;
            margin: 0 auto;
        }
        
        .header {
            background: rgba(255, 255, 255, 0.95);
            border-radius: 15px;
            padding: 20px;
            margin-bottom: 15px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        
        .header h1 {
            font-size: 24px;
            color: #667eea;
            margin-bottom: 5px;
        }
        
        .header p {
            color: #666;
            font-size: 14px;
        }
        
        .card {
            background: rgba(255, 255, 255, 0.95);
            border-radius: 15px;
            padding: 20px;
            margin-bottom: 15px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        
        .card h2 {
            font-size: 18px;
            color: #667eea;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
        }
        
        .card h2::before {
            content: '';
            display: inline-block;
            width: 4px;
            height: 18px;
            background: #667eea;
            margin-right: 10px;
            border-radius: 2px;
        }
        
        .stat-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px 0;
            border-bottom: 1px solid #eee;
        }
        
        .stat-item:last-child {
            border-bottom: none;
        }
        
        .stat-label {
            font-weight: 600;
            color: #555;
            font-size: 14px;
        }
        
        .stat-value {
            font-weight: bold;
            font-size: 16px;
            color: #667eea;
        }
        
        .progress-bar {
            width: 100%;
            height: 8px;
            background: #e0e0e0;
            border-radius: 10px;
            overflow: hidden;
            margin-top: 8px;
        }
        
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
            transition: width 0.3s ease;
        }
        
        .progress-fill.warning {
            background: linear-gradient(90deg, #f6b93b 0%, #e58e26 100%);
        }
        
        .progress-fill.danger {
            background: linear-gradient(90deg, #eb3b5a 0%, #fc5c65 100%);
        }
        
        .process-list {
            list-style: none;
        }
        
        .process-item {
            padding: 10px;
            background: #f8f9fa;
            border-radius: 8px;
            margin-bottom: 8px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .process-name {
            font-weight: 600;
            color: #333;
            font-size: 13px;
            flex: 1;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }
        
        .process-stats {
            font-size: 12px;
            color: #667eea;
            font-weight: bold;
            margin-left: 10px;
        }
        
        .controls {
            display: flex;
            gap: 10px;
            margin-top: 15px;
        }
        
        .btn {
            flex: 1;
            padding: 12px;
            border: none;
            border-radius: 10px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s;
        }
        
        .btn:active {
            transform: scale(0.95);
        }
        
        .btn-start {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        .btn-stop {
            background: linear-gradient(135deg, #eb3b5a 0%, #fc5c65 100%);
            color: white;
        }
        
        .status {
            text-align: center;
            padding: 10px;
            border-radius: 10px;
            margin-bottom: 15px;
            font-weight: 600;
        }
        
        .status.active {
            background: #d4edda;
            color: #155724;
        }
        
        .status.inactive {
            background: #f8d7da;
            color: #721c24;
        }
        
        .footer {
            text-align: center;
            color: rgba(255, 255, 255, 0.9);
            font-size: 12px;
            padding: 20px;
        }
        
        .emoji {
            font-size: 20px;
            margin-right: 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 VIO Super AI Monitor</h1>
            <p>iPhone Dashboard - Real-time System Monitoring</p>
        </div>
        
        <div id="status" class="status inactive">
            ⭕ Not Connected
        </div>
        
        <div class="card">
            <h2>⚡ System Status</h2>
            <div class="stat-item">
                <span class="stat-label">CPU Usage</span>
                <span class="stat-value" id="cpu-value">--</span>
            </div>
            <div class="progress-bar">
                <div class="progress-fill" id="cpu-bar" style="width: 0%"></div>
            </div>
            
            <div class="stat-item">
                <span class="stat-label">RAM Usage</span>
                <span class="stat-value" id="ram-value">--</span>
            </div>
            <div class="progress-bar">
                <div class="progress-fill" id="ram-bar" style="width: 0%"></div>
            </div>
            
            <div class="stat-item">
                <span class="stat-label">Memory Pressure</span>
                <span class="stat-value" id="pressure-value">--</span>
            </div>
            
            <div class="stat-item">
                <span class="stat-label">Disk Usage</span>
                <span class="stat-value" id="disk-value">--</span>
            </div>
            
            <div class="stat-item">
                <span class="stat-label">Load Average</span>
                <span class="stat-value" id="load-value">--</span>
            </div>
        </div>
        
        <div class="card">
            <h2>📊 Top Processes</h2>
            <ul class="process-list" id="process-list">
                <li class="process-item">
                    <span class="process-name">Loading...</span>
                </li>
            </ul>
        </div>
        
        <div class="card">
            <h2>📈 System Info</h2>
            <div class="stat-item">
                <span class="stat-label">Uptime</span>
                <span class="stat-value" id="uptime-value">--</span>
            </div>
            <div class="stat-item">
                <span class="stat-label">Processes</span>
                <span class="stat-value" id="process-count">--</span>
            </div>
            <div class="stat-item">
                <span class="stat-label">Last Update</span>
                <span class="stat-value" id="last-update">--</span>
            </div>
        </div>
        
        <div class="card">
            <h2>🎮 Controls</h2>
            <div class="controls">
                <button class="btn btn-start" onclick="startMonitoring()">▶️ Start</button>
                <button class="btn btn-stop" onclick="stopMonitoring()">⏸️ Stop</button>
            </div>
        </div>
        
        <div class="footer">
            © 2025 VIO Super AI - Proprietary Software<br>
            Real-time Monitoring for iPhone
        </div>
    </div>
    
    <script>
        let updateInterval;
        
        function updateStats() {
            fetch('/api/stats')
                .then(response => response.json())
                .then(data => {
                    if (data.success && data.stats) {
                        const stats = data.stats;
                        
                        // Update status
                        document.getElementById('status').className = 'status active';
                        document.getElementById('status').textContent = '✅ Connected & Monitoring';
                        
                        // Update CPU
                        const cpuPercent = stats.cpu_percent || 0;
                        document.getElementById('cpu-value').textContent = cpuPercent.toFixed(1) + '%';
                        const cpuBar = document.getElementById('cpu-bar');
                        cpuBar.style.width = cpuPercent + '%';
                        cpuBar.className = 'progress-fill' + (cpuPercent > 90 ? ' danger' : cpuPercent > 70 ? ' warning' : '');
                        
                        // Update RAM
                        const ramPercent = stats.ram_percent || 0;
                        document.getElementById('ram-value').textContent = ramPercent.toFixed(1) + '%';
                        const ramBar = document.getElementById('ram-bar');
                        ramBar.style.width = ramPercent + '%';
                        ramBar.className = 'progress-fill' + (ramPercent > 85 ? ' danger' : ramPercent > 70 ? ' warning' : '');
                        
                        // Update other stats
                        document.getElementById('pressure-value').textContent = stats.memory_pressure || '--';
                        document.getElementById('disk-value').textContent = (stats.disk_percent || 0).toFixed(1) + '%';
                        document.getElementById('load-value').textContent = 
                            (stats.load_avg_1 || 0).toFixed(2) + ' / ' + 
                            (stats.load_avg_5 || 0).toFixed(2) + ' / ' + 
                            (stats.load_avg_15 || 0).toFixed(2);
                        
                        // Update uptime
                        const uptime = (stats.uptime_days || 0) + 'd ' + 
                                      (stats.uptime_hours || 0) + 'h ' + 
                                      (stats.uptime_minutes || 0) + 'm';
                        document.getElementById('uptime-value').textContent = uptime;
                        document.getElementById('process-count').textContent = stats.process_count || '--';
                        
                        // Update processes
                        if (data.processes && data.processes.length > 0) {
                            const processList = document.getElementById('process-list');
                            processList.innerHTML = data.processes.map((proc, idx) => 
                                `<li class="process-item">
                                    <span class="emoji">${idx === 0 ? '🥇' : idx === 1 ? '🥈' : idx === 2 ? '🥉' : '•'}</span>
                                    <span class="process-name">${proc.name}</span>
                                    <span class="process-stats">${proc.memory_percent.toFixed(1)}%</span>
                                </li>`
                            ).join('');
                        }
                        
                        // Update timestamp
                        const now = new Date();
                        document.getElementById('last-update').textContent = now.toLocaleTimeString();
                    }
                })
                .catch(error => {
                    console.error('Error fetching stats:', error);
                    document.getElementById('status').className = 'status inactive';
                    document.getElementById('status').textContent = '⭕ Connection Error';
                });
        }
        
        function startMonitoring() {
            fetch('/api/start', { method: 'POST' })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        if (!updateInterval) {
                            updateInterval = setInterval(updateStats, 2000);
                            updateStats();
                        }
                    }
                });
        }
        
        function stopMonitoring() {
            fetch('/api/stop', { method: 'POST' })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        if (updateInterval) {
                            clearInterval(updateInterval);
                            updateInterval = null;
                        }
                        document.getElementById('status').className = 'status inactive';
                        document.getElementById('status').textContent = '⏸️ Monitoring Paused';
                    }
                });
        }
        
        // Auto-start monitoring on load
        window.addEventListener('load', () => {
            startMonitoring();
        });
    </script>
</body>
</html>
"""
    
    with open(template_dir / 'dashboard.html', 'w') as f:
        f.write(html_content)
    
    print(f"Dashboard template created at: {template_dir / 'dashboard.html'}")

if __name__ == '__main__':
    print("VIO Super AI - Web Dashboard for iPhone")
    print("=" * 60)
    
    # Create template
    create_dashboard_html()
    
    print("\nStarting web server...")
    print("Access from iPhone:")
    print("  1. Find your Mac's IP address: ifconfig | grep 'inet '")
    print("  2. Open Safari on iPhone")
    print("  3. Go to: http://YOUR_MAC_IP:5000")
    print("\nExample: http://192.168.1.100:5000")
    print("\nPress Ctrl+C to stop")
    print("=" * 60)
    
    # Start Flask app
    app.run(host='0.0.0.0', port=5000, debug=False)
