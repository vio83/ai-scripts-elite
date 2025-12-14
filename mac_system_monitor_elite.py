#!/usr/bin/env python3
"""
VIO Super AI - Mac System Monitor ELITE EDITION
Enhanced Visual Design with Maximum Optimization
Proprietary Code - Copyright © 2025 VIO Super AI
"""

import psutil
import time
import subprocess
import os
import sys
from datetime import datetime
from collections import defaultdict, deque
import json
import pickle
from pathlib import Path

# VIO Super AI ELITE Color Scheme - Enhanced Visual Design
COLORS = {
    'HEADER': '\033[95m',
    'OKBLUE': '\033[94m',
    'OKCYAN': '\033[96m',
    'OKGREEN': '\033[92m',
    'WARNING': '\033[93m',
    'FAIL': '\033[91m',
    'ENDC': '\033[0m',
    'BOLD': '\033[1m',
    'UNDERLINE': '\033[4m',
    'DIM': '\033[2m',
    'BLINK': '\033[5m',
    'BG_BLACK': '\033[40m',
    'BG_BLUE': '\033[44m',
    'BG_CYAN': '\033[46m',
    'BG_GREEN': '\033[42m',
    'BG_RED': '\033[41m',
}

# Configuration
CONFIG = {
    'RAM_THRESHOLD': 85,
    'CPU_THRESHOLD': 90,
    'CHECK_INTERVAL': 2,
    'HISTORY_SIZE': 100,
    'ML_ENABLED': True,
    'NOTIFICATIONS_ENABLED': True,
    'AUTO_KILL_ENABLED': True,
    'PEC_NOTIFICATIONS': True,
    'ELITE_GRAPHICS': True,  # Enable enhanced graphics
}

class MacSystemMonitorElite:
    """VIO Super AI ELITE System Monitor - Enhanced Visual Design"""
    
    def __init__(self):
        self.history = defaultdict(lambda: deque(maxlen=CONFIG['HISTORY_SIZE']))
        self.process_scores = defaultdict(float)
        self.killed_processes = []
        self.alerts_sent = set()
        self.data_dir = Path.home() / '.vio_super_ai_elite'
        self.data_dir.mkdir(exist_ok=True)
        self.load_ml_model()
        self.frame_count = 0
        
    def load_ml_model(self):
        """Load machine learning model for process prediction"""
        model_path = self.data_dir / 'process_model_elite.pkl'
        if model_path.exists():
            try:
                with open(model_path, 'rb') as f:
                    self.ml_model = pickle.load(f)
            except (OSError, pickle.PickleError, EOFError) as e:
                print(f"{COLORS['WARNING']}Warning: Could not load ML model: {e}{COLORS['ENDC']}")
                self.ml_model = {}
        else:
            self.ml_model = {}
    
    def save_ml_model(self):
        """Save machine learning model"""
        model_path = self.data_dir / 'process_model_elite.pkl'
        try:
            with open(model_path, 'wb') as f:
                pickle.dump(self.ml_model, f)
        except Exception as e:
            print(f"{COLORS['WARNING']}Warning: Could not save ML model: {e}{COLORS['ENDC']}")
    
    def clear_screen(self):
        """Clear terminal screen"""
        os.system('clear')
    
    def print_elite_header(self):
        """Print enhanced VIO Super AI ELITE header with animations"""
        ram_total_gb = psutil.virtual_memory().total / (1024**3)
        
        # Animated header with color gradient effect
        header = f"""
{COLORS['BOLD']}{COLORS['OKCYAN']}╔{'═' * 78}╗
{COLORS['OKCYAN']}║{COLORS['HEADER']}                    ✦ VIO SUPER AI - ELITE EDITION ✦                     {COLORS['OKCYAN']}║
{COLORS['OKCYAN']}╠{'═' * 78}╣
{COLORS['OKCYAN']}║{COLORS['OKBLUE']}    ██╗   ██╗██╗ ██████╗     ███████╗██╗   ██╗██████╗ ███████╗██████╗     {COLORS['OKCYAN']}║
{COLORS['OKCYAN']}║{COLORS['OKBLUE']}    ██║   ██║██║██╔═══██╗    ██╔════╝██║   ██║██╔══██╗██╔════╝██╔══██╗    {COLORS['OKCYAN']}║
{COLORS['OKCYAN']}║{COLORS['OKBLUE']}    ██║   ██║██║██║   ██║    ███████╗██║   ██║██████╔╝█████╗  ██████╔╝    {COLORS['OKCYAN']}║
{COLORS['OKCYAN']}║{COLORS['OKBLUE']}    ╚██╗ ██╔╝██║██║   ██║    ╚════██║██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗    {COLORS['OKCYAN']}║
{COLORS['OKCYAN']}║{COLORS['OKBLUE']}     ╚████╔╝ ██║╚██████╔╝    ███████║╚██████╔╝██║     ███████╗██║  ██║    {COLORS['OKCYAN']}║
{COLORS['OKCYAN']}║{COLORS['OKBLUE']}      ╚═══╝  ╚═╝ ╚═════╝     ╚══════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝    {COLORS['OKCYAN']}║
{COLORS['OKCYAN']}╠{'═' * 78}╣
{COLORS['OKCYAN']}║{COLORS['OKGREEN']}              🚀 AI-Powered System Monitor & Auto-Optimizer 🚀             {COLORS['OKCYAN']}║
{COLORS['OKCYAN']}║{COLORS['WARNING']}                   Mac Air 2020 • {int(ram_total_gb)}GB RAM • ELITE Mode                 {COLORS['OKCYAN']}║
{COLORS['OKCYAN']}║{COLORS['DIM']}                © 2025 VIO Super AI - Proprietary Software                 {COLORS['OKCYAN']}║
{COLORS['OKCYAN']}╚{'═' * 78}╝{COLORS['ENDC']}
"""
        print(header)
    
    def get_system_stats(self):
        """Get current system statistics"""
        vm = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        try:
            load_avg = os.getloadavg()
        except (OSError, AttributeError):
            load_avg = (0, 0, 0)
        
        boot_time = datetime.fromtimestamp(psutil.boot_time())
        uptime_delta = datetime.now() - boot_time
        uptime_days = uptime_delta.days
        uptime_hours = uptime_delta.seconds // 3600
        uptime_minutes = (uptime_delta.seconds % 3600) // 60
        
        stats = {
            'cpu_percent': psutil.cpu_percent(interval=1, percpu=False),
            'cpu_per_core': psutil.cpu_percent(interval=1, percpu=True),
            'ram_percent': vm.percent,
            'ram_used_gb': vm.used / (1024**3),
            'ram_total_gb': vm.total / (1024**3),
            'ram_cached_gb': getattr(vm, 'cached', 0) / (1024**3),
            'ram_free_gb': vm.available / (1024**3),
            'swap_percent': psutil.swap_memory().percent,
            'disk_percent': disk.percent,
            'disk_used_gb': disk.used / (1024**3),
            'disk_total_gb': disk.total / (1024**3),
            'load_avg_1': load_avg[0],
            'load_avg_5': load_avg[1],
            'load_avg_15': load_avg[2],
            'process_count': len(psutil.pids()),
            'uptime_days': uptime_days,
            'uptime_hours': uptime_hours,
            'uptime_minutes': uptime_minutes,
            'timestamp': datetime.now().isoformat(),
        }
        
        if stats['ram_percent'] > 85:
            stats['memory_pressure'] = 'High'
        elif stats['ram_percent'] > 60:
            stats['memory_pressure'] = 'Moderate'
        else:
            stats['memory_pressure'] = 'Low'
        
        for key, value in stats.items():
            if isinstance(value, (int, float)):
                self.history[key].append(value)
        
        return stats
    
    def get_top_processes(self, n=10):
        """Get top N resource-consuming processes"""
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
    
    def predict_problematic_process(self, process_info):
        """Use ML to predict if process will become problematic"""
        proc_name = process_info['name']
        
        if proc_name not in self.ml_model:
            self.ml_model[proc_name] = {
                'kill_count': 0,
                'max_cpu': 0,
                'max_mem': 0,
                'avg_cpu': 0,
                'avg_mem': 0,
                'samples': 0,
            }
        
        model = self.ml_model[proc_name]
        model['max_cpu'] = max(model['max_cpu'], process_info['cpu_percent'])
        model['max_mem'] = max(model['max_mem'], process_info['memory_percent'])
        
        samples = model['samples']
        model['avg_cpu'] = (model['avg_cpu'] * samples + process_info['cpu_percent']) / (samples + 1)
        model['avg_mem'] = (model['avg_mem'] * samples + process_info['memory_percent']) / (samples + 1)
        model['samples'] += 1
        
        risk_score = (
            model['kill_count'] * 10 +
            (model['max_cpu'] / 100) * 5 +
            (model['max_mem'] / 100) * 5 +
            (model['avg_cpu'] / 100) * 3 +
            (model['avg_mem'] / 100) * 3
        )
        
        self.process_scores[proc_name] = risk_score
        return risk_score
    
    def should_kill_process(self, process_info, stats):
        """Determine if process should be killed"""
        if not CONFIG['AUTO_KILL_ENABLED']:
            return False
        
        ram_critical = stats['ram_percent'] > CONFIG['RAM_THRESHOLD']
        cpu_critical = stats['cpu_percent'] > CONFIG['CPU_THRESHOLD']
        
        if not (ram_critical or cpu_critical):
            return False
        
        critical_processes = ['kernel_task', 'launchd', 'WindowServer', 'loginwindow', 
                             'systemstats', 'python3', 'Terminal', 'iTerm2']
        if process_info['name'] in critical_processes:
            return False
        
        proc_heavy = (process_info['cpu_percent'] > 50 or 
                     process_info['memory_percent'] > 20)
        
        if CONFIG['ML_ENABLED']:
            risk_score = self.predict_problematic_process(process_info)
            ml_suggests_kill = risk_score > 15
        else:
            ml_suggests_kill = False
        
        return proc_heavy or ml_suggests_kill
    
    def kill_process(self, process_info):
        """Intelligently kill a process"""
        try:
            proc = psutil.Process(process_info['pid'])
            proc_name = process_info['name']
            
            proc.terminate()
            
            try:
                proc.wait(timeout=3)
            except psutil.TimeoutExpired:
                proc.kill()
            
            self.killed_processes.append({
                'name': proc_name,
                'pid': process_info['pid'],
                'timestamp': datetime.now().isoformat(),
                'cpu': process_info['cpu_percent'],
                'mem': process_info['memory_percent'],
            })
            
            if proc_name in self.ml_model:
                self.ml_model[proc_name]['kill_count'] += 1
            
            return True
        except Exception as e:
            return False
    
    def send_notification(self, title, message, level='info'):
        """Send macOS native notification"""
        if not CONFIG['NOTIFICATIONS_ENABLED']:
            return
        
        try:
            script = f'''
                display notification "{message}" with title "{title}" sound name "Ping"
            '''
            subprocess.run(['osascript', '-e', script], check=False, capture_output=True)
        except (OSError, subprocess.SubprocessError):
            pass
    
    def send_pec_notification(self, message):
        """Send PEC notification for critical issues"""
        if not CONFIG['PEC_NOTIFICATIONS']:
            return
        
        pec_log = self.data_dir / 'pec_notifications.log'
        timestamp = datetime.now().isoformat()
        
        try:
            with open(pec_log, 'a') as f:
                f.write(f"[{timestamp}] CRITICAL: {message}\n")
            
            self.send_notification("VIO Super AI ELITE - CRITICAL", message, 'critical')
        except Exception as e:
            print(f"{COLORS['FAIL']}PEC Notification Error: {e}{COLORS['ENDC']}")
    
    def create_elite_progress_bar(self, percent, width=40):
        """Create enhanced visual progress bar with color gradients"""
        filled = int(width * percent / 100)
        
        # Color gradient based on percentage
        if percent > 90:
            bar_color = COLORS['FAIL']
            indicator = '█'
        elif percent > 75:
            bar_color = COLORS['WARNING']
            indicator = '█'
        elif percent > 50:
            bar_color = COLORS['OKCYAN']
            indicator = '▓'
        else:
            bar_color = COLORS['OKGREEN']
            indicator = '▓'
        
        bar = indicator * filled + '░' * (width - filled)
        return f"{bar_color}{bar}{COLORS['ENDC']}"
    
    def get_status_emoji(self, percent, type='default'):
        """Get status emoji based on percentage"""
        if type == 'cpu' or type == 'ram':
            if percent > 90:
                return '🔴'
            elif percent > 75:
                return '🟡'
            elif percent > 50:
                return '🟢'
            else:
                return '🟢'
        return '⚡'
    
    def print_elite_stats_display(self, stats, processes):
        """Print enhanced statistics display with ELITE graphics"""
        
        # Main statistics panel with enhanced design
        print(f"\n{COLORS['BOLD']}{COLORS['OKCYAN']}╔{'═' * 78}╗{COLORS['ENDC']}")
        print(f"{COLORS['BOLD']}{COLORS['OKCYAN']}║{COLORS['HEADER']} ⚡ SYSTEM PERFORMANCE DASHBOARD{' ' * 47}║{COLORS['ENDC']}")
        print(f"{COLORS['BOLD']}{COLORS['OKCYAN']}╠{'═' * 78}╣{COLORS['ENDC']}")
        
        # CPU Panel with emoji indicator
        cpu_emoji = self.get_status_emoji(stats['cpu_percent'], 'cpu')
        cpu_bar = self.create_elite_progress_bar(stats['cpu_percent'], 40)
        cpu_color = COLORS['FAIL'] if stats['cpu_percent'] > 90 else COLORS['WARNING'] if stats['cpu_percent'] > 75 else COLORS['OKGREEN']
        print(f"{COLORS['OKCYAN']}║{COLORS['ENDC']} {cpu_emoji} {COLORS['BOLD']}CPU Usage:{COLORS['ENDC']} {cpu_bar} {cpu_color}{stats['cpu_percent']:5.1f}%{COLORS['ENDC']}  {COLORS['OKCYAN']}║{COLORS['ENDC']}")
        print(f"{COLORS['OKCYAN']}║{COLORS['ENDC']}   {COLORS['DIM']}↳ Load Avg:{COLORS['ENDC']} {stats['load_avg_1']:.2f} (1m) • {stats['load_avg_5']:.2f} (5m) • {stats['load_avg_15']:.3f} (15m){' ' * 14}{COLORS['OKCYAN']}║{COLORS['ENDC']}")
        
        # Separator
        print(f"{COLORS['OKCYAN']}╟{'─' * 78}╢{COLORS['ENDC']}")
        
        # RAM Panel with emoji indicator
        ram_emoji = self.get_status_emoji(stats['ram_percent'], 'ram')
        ram_bar = self.create_elite_progress_bar(stats['ram_percent'], 40)
        ram_color = COLORS['FAIL'] if stats['ram_percent'] > 85 else COLORS['WARNING'] if stats['ram_percent'] > 70 else COLORS['OKGREEN']
        pressure_color = COLORS['FAIL'] if stats['memory_pressure'] == 'High' else COLORS['WARNING'] if stats['memory_pressure'] == 'Moderate' else COLORS['OKGREEN']
        
        print(f"{COLORS['OKCYAN']}║{COLORS['ENDC']} {ram_emoji} {COLORS['BOLD']}RAM Usage:{COLORS['ENDC']} {ram_bar} {ram_color}{stats['ram_percent']:5.1f}%{COLORS['ENDC']}  {COLORS['OKCYAN']}║{COLORS['ENDC']}")
        print(f"{COLORS['OKCYAN']}║{COLORS['ENDC']}   {COLORS['DIM']}↳ Used:{COLORS['ENDC']} {stats['ram_used_gb']:.1f}G • {COLORS['DIM']}Cached:{COLORS['ENDC']} {stats['ram_cached_gb']:.1f}G • {COLORS['DIM']}Free:{COLORS['ENDC']} {stats['ram_free_gb']:.1f}G • {COLORS['DIM']}Pressure:{COLORS['ENDC']} {pressure_color}{stats['memory_pressure']}{COLORS['ENDC']}{' ' * 14}{COLORS['OKCYAN']}║{COLORS['ENDC']}")
        
        # Separator
        print(f"{COLORS['OKCYAN']}╟{'─' * 78}╢{COLORS['ENDC']}")
        
        # Disk Panel
        disk_bar = self.create_elite_progress_bar(stats['disk_percent'], 40)
        disk_color = COLORS['FAIL'] if stats['disk_percent'] > 90 else COLORS['WARNING'] if stats['disk_percent'] > 80 else COLORS['OKGREEN']
        print(f"{COLORS['OKCYAN']}║{COLORS['ENDC']} 💾 {COLORS['BOLD']}Disk Usage:{COLORS['ENDC']} {disk_bar} {disk_color}{stats['disk_percent']:5.1f}%{COLORS['ENDC']} {COLORS['OKCYAN']}║{COLORS['ENDC']}")
        print(f"{COLORS['OKCYAN']}║{COLORS['ENDC']}   {COLORS['DIM']}↳ Used:{COLORS['ENDC']} {int(stats['disk_used_gb'])}Gi / {int(stats['disk_total_gb'])}Gi{' ' * 46}{COLORS['OKCYAN']}║{COLORS['ENDC']}")
        
        print(f"{COLORS['BOLD']}{COLORS['OKCYAN']}╚{'═' * 78}╝{COLORS['ENDC']}")
        
        # Top Processes Panel
        print(f"\n{COLORS['BOLD']}{COLORS['OKCYAN']}╔{'═' * 78}╗{COLORS['ENDC']}")
        print(f"{COLORS['BOLD']}{COLORS['OKCYAN']}║{COLORS['HEADER']} 📊 TOP RESOURCE CONSUMERS{' ' * 51}║{COLORS['ENDC']}")
        print(f"{COLORS['BOLD']}{COLORS['OKCYAN']}╠{'═' * 78}╣{COLORS['ENDC']}")
        print(f"{COLORS['OKCYAN']}║{COLORS['BOLD']} {'RANK':<6} {'PROCESS NAME':<35} {'CPU%':<8} {'MEM%':<8} {'RISK':<8}║{COLORS['ENDC']}")
        print(f"{COLORS['OKCYAN']}╟{'─' * 78}╢{COLORS['ENDC']}")
        
        for i, proc in enumerate(processes[:5], 1):
            risk_score = self.process_scores.get(proc['name'], 0)
            
            # Rank with medal emojis
            if i == 1:
                rank = '🥇'
            elif i == 2:
                rank = '🥈'
            elif i == 3:
                rank = '🥉'
            else:
                rank = f'{i}.'
            
            # Risk color coding
            if risk_score > 20:
                risk_color = COLORS['FAIL']
                risk_icon = '⚠️ '
            elif risk_score > 10:
                risk_color = COLORS['WARNING']
                risk_icon = '⚡'
            else:
                risk_color = COLORS['OKGREEN']
                risk_icon = '✓ '
            
            proc_name = proc['name'][:33] + '..' if len(proc['name']) > 35 else proc['name']
            print(f"{COLORS['OKCYAN']}║{COLORS['ENDC']} {rank:<6} {proc_name:<35} {proc['cpu_percent']:>6.1f}%  {proc['memory_percent']:>6.1f}%  {risk_color}{risk_icon}{risk_score:>5.1f}{COLORS['ENDC']} {COLORS['OKCYAN']}║{COLORS['ENDC']}")
        
        print(f"{COLORS['BOLD']}{COLORS['OKCYAN']}╚{'═' * 78}╝{COLORS['ENDC']}")
        
        # System Info & Status Panel
        uptime_str = f"{stats['uptime_days']}d {stats['uptime_hours']}h {stats['uptime_minutes']}m"
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        print(f"\n{COLORS['BOLD']}{COLORS['OKCYAN']}╔{'═' * 78}╗{COLORS['ENDC']}")
        print(f"{COLORS['BOLD']}{COLORS['OKCYAN']}║{COLORS['HEADER']} 📈 SYSTEM STATUS & INTELLIGENCE{' ' * 45}║{COLORS['ENDC']}")
        print(f"{COLORS['BOLD']}{COLORS['OKCYAN']}╠{'═' * 78}╣{COLORS['ENDC']}")
        
        # ML Status
        ml_icon = '🤖' if CONFIG['ML_ENABLED'] else '⭕'
        ml_status = f"{COLORS['OKGREEN']}ACTIVE{COLORS['ENDC']}" if CONFIG['ML_ENABLED'] else f"{COLORS['WARNING']}INACTIVE{COLORS['ENDC']}"
        
        # Auto-Kill Status
        kill_icon = '⚔️ ' if CONFIG['AUTO_KILL_ENABLED'] else '🛡️ '
        kill_status = f"{COLORS['OKGREEN']}ENABLED{COLORS['ENDC']}" if CONFIG['AUTO_KILL_ENABLED'] else f"{COLORS['WARNING']}DISABLED{COLORS['ENDC']}"
        
        print(f"{COLORS['OKCYAN']}║{COLORS['ENDC']} 🕐 {COLORS['BOLD']}Uptime:{COLORS['ENDC']} {uptime_str:<15} 📊 {COLORS['BOLD']}Processes:{COLORS['ENDC']} {stats['process_count']:<10}{' ' * 21}{COLORS['OKCYAN']}║{COLORS['ENDC']}")
        print(f"{COLORS['OKCYAN']}║{COLORS['ENDC']} {ml_icon} {COLORS['BOLD']}ML Engine:{COLORS['ENDC']} {ml_status:<20} {kill_icon}{COLORS['BOLD']}Auto-Kill:{COLORS['ENDC']} {kill_status:<20}{' ' * 6}{COLORS['OKCYAN']}║{COLORS['ENDC']}")
        print(f"{COLORS['OKCYAN']}║{COLORS['ENDC']} 🎯 {COLORS['BOLD']}Killed:{COLORS['ENDC']} {len(self.killed_processes):<18} 📅 {COLORS['BOLD']}Time:{COLORS['ENDC']} {timestamp}{' ' * 15}{COLORS['OKCYAN']}║{COLORS['ENDC']}")
        
        if self.killed_processes:
            last_killed = self.killed_processes[-1]
            print(f"{COLORS['OKCYAN']}║{COLORS['ENDC']} ⚠️  {COLORS['WARNING']}Last Terminated:{COLORS['ENDC']} {last_killed['name'][:30]:<30} (PID: {last_killed['pid']}){' ' * 8}{COLORS['OKCYAN']}║{COLORS['ENDC']}")
        
        print(f"{COLORS['BOLD']}{COLORS['OKCYAN']}╚{'═' * 78}╝{COLORS['ENDC']}")
        
        # Footer
        print(f"\n{COLORS['DIM']}{'─' * 78}{COLORS['ENDC']}")
        print(f"{COLORS['OKCYAN']}⚡ Press Ctrl+C to exit{COLORS['ENDC']} │ {COLORS['DIM']}Update: every {CONFIG['CHECK_INTERVAL']}s{COLORS['ENDC']} │ {COLORS['WARNING']}© 2025 VIO Super AI - ELITE Edition{COLORS['ENDC']}")
        print(f"{COLORS['DIM']}{'─' * 78}{COLORS['ENDC']}")
    
    def auto_optimize(self, stats, processes):
        """Auto-optimization engine"""
        critical_state = False
        
        if stats['ram_percent'] > CONFIG['RAM_THRESHOLD']:
            critical_state = True
            message = f"RAM usage critical: {stats['ram_percent']:.1f}%"
            self.send_notification("VIO Super AI ELITE - RAM Critical", message, 'warning')
            
            if stats['ram_percent'] > 95:
                self.send_pec_notification(f"CRITICAL RAM: {stats['ram_percent']:.1f}% - System freeze imminent!")
        
        if stats['cpu_percent'] > CONFIG['CPU_THRESHOLD']:
            critical_state = True
            message = f"CPU usage critical: {stats['cpu_percent']:.1f}%"
            self.send_notification("VIO Super AI ELITE - CPU Critical", message, 'warning')
            
            if stats['cpu_percent'] > 95:
                self.send_pec_notification(f"CRITICAL CPU: {stats['cpu_percent']:.1f}% - System freeze imminent!")
        
        if critical_state and CONFIG['AUTO_KILL_ENABLED']:
            for proc in processes:
                if self.should_kill_process(proc, stats):
                    if self.kill_process(proc):
                        message = f"Killed process: {proc['name']} (PID: {proc['pid']})"
                        self.send_notification("VIO Super AI ELITE - Process Terminated", message, 'info')
                        break
    
    def run(self):
        """Main monitoring loop"""
        print(f"{COLORS['OKGREEN']}Starting VIO Super AI ELITE System Monitor...{COLORS['ENDC']}")
        self.send_notification("VIO Super AI ELITE", "System Monitor Started - ELITE Mode", 'info')
        
        try:
            while True:
                self.clear_screen()
                self.print_elite_header()
                
                stats = self.get_system_stats()
                processes = self.get_top_processes(10)
                
                if CONFIG['ML_ENABLED']:
                    for proc in processes:
                        self.predict_problematic_process(proc)
                
                self.auto_optimize(stats, processes)
                self.print_elite_stats_display(stats, processes)
                
                if len(self.history['cpu_percent']) % 20 == 0:
                    self.save_ml_model()
                
                self.frame_count += 1
                time.sleep(CONFIG['CHECK_INTERVAL'])
                
        except KeyboardInterrupt:
            print(f"\n\n{COLORS['OKCYAN']}Shutting down VIO Super AI ELITE System Monitor...{COLORS['ENDC']}")
            self.save_ml_model()
            self.send_notification("VIO Super AI ELITE", "System Monitor Stopped", 'info')
            self.save_session_report()
            print(f"{COLORS['OKGREEN']}Session saved. Goodbye!{COLORS['ENDC']}\n")
    
    def save_session_report(self):
        """Save session report"""
        report_path = self.data_dir / 'session_reports_elite.json'
        report = {
            'timestamp': datetime.now().isoformat(),
            'processes_killed': self.killed_processes,
            'total_killed': len(self.killed_processes),
            'alerts_sent': len(self.alerts_sent),
            'frames_rendered': self.frame_count,
        }
        
        try:
            reports = []
            if report_path.exists():
                with open(report_path, 'r') as f:
                    reports = json.load(f)
            
            reports.append(report)
            reports = reports[-100:]
            
            with open(report_path, 'w') as f:
                json.dump(reports, f, indent=2)
        except Exception as e:
            print(f"{COLORS['WARNING']}Could not save session report: {e}{COLORS['ENDC']}")


def main():
    """Main entry point"""
    if sys.platform != 'darwin':
        print(f"{COLORS['FAIL']}Error: This tool is designed for macOS only.{COLORS['ENDC']}")
        sys.exit(1)
    
    try:
        import psutil
    except ImportError:
        print(f"{COLORS['FAIL']}Error: psutil is required. Install with: pip3 install psutil{COLORS['ENDC']}")
        sys.exit(1)
    
    monitor = MacSystemMonitorElite()
    monitor.run()


if __name__ == '__main__':
    main()
