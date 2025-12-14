#!/usr/bin/env python3
"""
VIO Super AI - Mac System Monitor & Auto-Optimizer
Professional-grade system monitoring and auto-optimization for macOS
World Record Level Quality - Guinness World Records Professional Standards
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

# VIO Super AI Color Scheme - Professional Elite Branding
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
    'BG_BLACK': '\033[40m',
    'BG_BLUE': '\033[44m',
    'BG_CYAN': '\033[46m',
}

# Configuration
CONFIG = {
    'RAM_THRESHOLD': 85,  # Percentage
    'CPU_THRESHOLD': 90,  # Percentage
    'CHECK_INTERVAL': 2,   # Seconds
    'HISTORY_SIZE': 100,   # Number of samples to keep
    'ML_ENABLED': True,
    'NOTIFICATIONS_ENABLED': True,
    'AUTO_KILL_ENABLED': True,
    'PEC_NOTIFICATIONS': True,
}

class MacSystemMonitor:
    """VIO Super AI System Monitor - World-Class Performance Monitoring"""
    
    def __init__(self):
        self.history = defaultdict(lambda: deque(maxlen=CONFIG['HISTORY_SIZE']))
        self.process_scores = defaultdict(float)
        self.killed_processes = []
        self.alerts_sent = set()
        self.data_dir = Path.home() / '.vio_super_ai'
        self.data_dir.mkdir(exist_ok=True)
        self.load_ml_model()
        
    def load_ml_model(self):
        """Load machine learning model for process prediction"""
        model_path = self.data_dir / 'process_model.pkl'
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
        model_path = self.data_dir / 'process_model.pkl'
        try:
            with open(model_path, 'wb') as f:
                pickle.dump(self.ml_model, f)
        except Exception as e:
            print(f"{COLORS['WARNING']}Warning: Could not save ML model: {e}{COLORS['ENDC']}")
    
    def clear_screen(self):
        """Clear terminal screen"""
        os.system('clear')
    
    def print_header(self):
        """Print professional VIO Super AI header"""
        # Get system info for header
        ram_total_gb = psutil.virtual_memory().total / (1024**3)
        
        header = f"""
{COLORS['BOLD']}{COLORS['OKBLUE']}╔{'═' * 74}╗
{COLORS['OKBLUE']}║{COLORS['ENDC']}           SYSTEM MONITOR - MAC AIR 2020 ({int(ram_total_gb)}GB RAM){' ' * 25}{COLORS['BOLD']}{COLORS['OKBLUE']}║
{COLORS['OKBLUE']}╚{'═' * 74}╝{COLORS['ENDC']}
"""
        print(header)
    
    def get_system_stats(self):
        """Get current system statistics"""
        vm = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        # Get load averages (macOS specific)
        try:
            load_avg = os.getloadavg()
        except (OSError, AttributeError):
            load_avg = (0, 0, 0)
        
        # Get uptime
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
        
        # Determine memory pressure
        if stats['ram_percent'] > 85:
            stats['memory_pressure'] = 'High'
        elif stats['ram_percent'] > 60:
            stats['memory_pressure'] = 'Moderate'
        else:
            stats['memory_pressure'] = 'Low'
        
        # Store in history for ML
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
        
        # Sort by combined resource usage
        processes.sort(key=lambda x: x['cpu_percent'] + x['memory_percent'], reverse=True)
        return processes[:n]
    
    def predict_problematic_process(self, process_info):
        """Use ML to predict if process will become problematic"""
        proc_name = process_info['name']
        
        # Update ML model with historical data
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
        
        # Calculate running average
        samples = model['samples']
        model['avg_cpu'] = (model['avg_cpu'] * samples + process_info['cpu_percent']) / (samples + 1)
        model['avg_mem'] = (model['avg_mem'] * samples + process_info['memory_percent']) / (samples + 1)
        model['samples'] += 1
        
        # Calculate risk score
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
        
        # Check thresholds
        ram_critical = stats['ram_percent'] > CONFIG['RAM_THRESHOLD']
        cpu_critical = stats['cpu_percent'] > CONFIG['CPU_THRESHOLD']
        
        if not (ram_critical or cpu_critical):
            return False
        
        # Don't kill system critical processes
        critical_processes = ['kernel_task', 'launchd', 'WindowServer', 'loginwindow', 
                             'systemstats', 'python3', 'Terminal', 'iTerm2']
        if process_info['name'] in critical_processes:
            return False
        
        # Check if process is consuming excessive resources
        proc_heavy = (process_info['cpu_percent'] > 50 or 
                     process_info['memory_percent'] > 20)
        
        # Use ML prediction
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
            
            # Try graceful termination first
            proc.terminate()
            
            # Wait for process to terminate
            try:
                proc.wait(timeout=3)
            except psutil.TimeoutExpired:
                # Force kill if necessary
                proc.kill()
            
            self.killed_processes.append({
                'name': proc_name,
                'pid': process_info['pid'],
                'timestamp': datetime.now().isoformat(),
                'cpu': process_info['cpu_percent'],
                'mem': process_info['memory_percent'],
            })
            
            # Update ML model
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
        """Send PEC (Posta Elettronica Certificata) notification for critical issues"""
        if not CONFIG['PEC_NOTIFICATIONS']:
            return
        
        # Log to file for PEC integration
        pec_log = self.data_dir / 'pec_notifications.log'
        timestamp = datetime.now().isoformat()
        
        try:
            with open(pec_log, 'a') as f:
                f.write(f"[{timestamp}] CRITICAL: {message}\n")
            
            # Also send system notification
            self.send_notification("VIO Super AI - CRITICAL", message, 'critical')
        except Exception as e:
            print(f"{COLORS['FAIL']}PEC Notification Error: {e}{COLORS['ENDC']}")
    
    def print_stats_display(self, stats, processes):
        """Print beautiful statistics display matching user's design"""
        
        # CPU Section
        print(f"\n┌─ CPU Usage")
        cpu_bar = self.create_progress_bar(stats['cpu_percent'], 50)
        print(f"│ {cpu_bar}  {int(stats['cpu_percent'])}%")
        print(f"└─ Load (1/5/15 min): {stats['load_avg_1']:.2f} {stats['load_avg_5']:.2f} {stats['load_avg_15']:.3f}")
        
        # RAM Section
        print(f"\n┌─ RAM Usage ({int(stats['ram_total_gb'])}GB Total)")
        ram_bar = self.create_progress_bar(stats['ram_percent'], 50)
        print(f"│ {ram_bar}  {int(stats['ram_percent'])}%")
        print(f"├─ Used: {stats['ram_used_gb']:.1f}G | Cached: {stats['ram_cached_gb']:.1f}G | Free: {stats['ram_free_gb']:.1f}G")
        print(f"└─ Memory Pressure: {stats['memory_pressure']}")
        
        # Disk Section
        print(f"\n┌─ Disk Usage")
        disk_bar = self.create_progress_bar(stats['disk_percent'], 50)
        print(f"│ {disk_bar}  {int(stats['disk_percent'])}%")
        print(f"└─ Space: {int(stats['disk_used_gb'])}Gi / {int(stats['disk_total_gb'])}Gi")
        
        # Top Memory Consumers
        print(f"\n┌─ Top Memory Consumers")
        for i, proc in enumerate(processes[:3]):
            if i == len(processes[:3]) - 1:
                print(f"│ {proc['name']:<40} {proc['memory_percent']:>5.1f}%")
                print(f"└─")
            else:
                print(f"│ {proc['name']:<40} {proc['memory_percent']:>5.1f}%")
        
        # System Info
        uptime_str = f"{stats['uptime_days']}d {stats['uptime_hours']}h {stats['uptime_minutes']}m"
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        print(f"\n┌─ System Info")
        print(f"│ Uptime: {uptime_str}  │  Processes: {stats['process_count']}")
        print(f"│ Date: {timestamp}")
        print(f"└─ Press Ctrl+C to exit  │  Update: every {CONFIG['CHECK_INTERVAL']} seconds")
        
        # Bottom separator
        print(f"\n{'━' * 76}")
    
    def create_progress_bar(self, percent, width=50):
        """Create visual progress bar matching user's design"""
        filled = int(width * percent / 100)
        bar = '█' * filled + '░' * (width - filled)
        return bar
    
    def auto_optimize(self, stats, processes):
        """Auto-optimization engine to prevent system freezes"""
        critical_state = False
        
        # Check for critical conditions
        if stats['ram_percent'] > CONFIG['RAM_THRESHOLD']:
            critical_state = True
            message = f"RAM usage critical: {stats['ram_percent']:.1f}%"
            self.send_notification("VIO Super AI - RAM Critical", message, 'warning')
            
            if stats['ram_percent'] > 95:
                self.send_pec_notification(f"CRITICAL RAM: {stats['ram_percent']:.1f}% - System freeze imminent!")
        
        if stats['cpu_percent'] > CONFIG['CPU_THRESHOLD']:
            critical_state = True
            message = f"CPU usage critical: {stats['cpu_percent']:.1f}%"
            self.send_notification("VIO Super AI - CPU Critical", message, 'warning')
            
            if stats['cpu_percent'] > 95:
                self.send_pec_notification(f"CRITICAL CPU: {stats['cpu_percent']:.1f}% - System freeze imminent!")
        
        # Intelligent process killing
        if critical_state and CONFIG['AUTO_KILL_ENABLED']:
            for proc in processes:
                if self.should_kill_process(proc, stats):
                    if self.kill_process(proc):
                        message = f"Killed process: {proc['name']} (PID: {proc['pid']})"
                        self.send_notification("VIO Super AI - Process Terminated", message, 'info')
                        # Only kill one process per cycle to avoid system instability
                        break
    
    def run(self):
        """Main monitoring loop"""
        print(f"{COLORS['OKGREEN']}Starting VIO Super AI System Monitor...{COLORS['ENDC']}")
        self.send_notification("VIO Super AI", "System Monitor Started", 'info')
        
        try:
            while True:
                self.clear_screen()
                self.print_header()
                
                # Get current stats
                stats = self.get_system_stats()
                processes = self.get_top_processes(10)
                
                # Predict problematic processes
                if CONFIG['ML_ENABLED']:
                    for proc in processes:
                        self.predict_problematic_process(proc)
                
                # Auto-optimization
                self.auto_optimize(stats, processes)
                
                # Display
                self.print_stats_display(stats, processes)
                
                # Save ML model periodically
                if len(self.history['cpu_percent']) % 20 == 0:
                    self.save_ml_model()
                
                time.sleep(CONFIG['CHECK_INTERVAL'])
                
        except KeyboardInterrupt:
            print(f"\n\n{COLORS['OKCYAN']}Shutting down VIO Super AI System Monitor...{COLORS['ENDC']}")
            self.save_ml_model()
            self.send_notification("VIO Super AI", "System Monitor Stopped", 'info')
            
            # Save session report
            self.save_session_report()
            
            print(f"{COLORS['OKGREEN']}Session saved. Goodbye!{COLORS['ENDC']}\n")
    
    def save_session_report(self):
        """Save session report for analysis"""
        report_path = self.data_dir / 'session_reports.json'
        report = {
            'timestamp': datetime.now().isoformat(),
            'processes_killed': self.killed_processes,
            'total_killed': len(self.killed_processes),
            'alerts_sent': len(self.alerts_sent),
        }
        
        try:
            reports = []
            if report_path.exists():
                with open(report_path, 'r') as f:
                    reports = json.load(f)
            
            reports.append(report)
            
            # Keep only last 100 reports
            reports = reports[-100:]
            
            with open(report_path, 'w') as f:
                json.dump(reports, f, indent=2)
        except Exception as e:
            print(f"{COLORS['WARNING']}Could not save session report: {e}{COLORS['ENDC']}")


def main():
    """Main entry point"""
    # Check if running on macOS
    if sys.platform != 'darwin':
        print(f"{COLORS['FAIL']}Error: This tool is designed for macOS only.{COLORS['ENDC']}")
        sys.exit(1)
    
    # Check for required dependencies
    try:
        import psutil
    except ImportError:
        print(f"{COLORS['FAIL']}Error: psutil is required. Install with: pip3 install psutil{COLORS['ENDC']}")
        sys.exit(1)
    
    monitor = MacSystemMonitor()
    monitor.run()


if __name__ == '__main__':
    main()
