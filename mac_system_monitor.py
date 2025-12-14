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
    'CHECK_INTERVAL': 5,   # Seconds
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
            except:
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
        header = f"""
{COLORS['BOLD']}{COLORS['HEADER']}{'=' * 80}
{COLORS['OKCYAN']}    ██╗   ██╗██╗ ██████╗     ███████╗██╗   ██╗██████╗ ███████╗██████╗ 
{COLORS['OKCYAN']}    ██║   ██║██║██╔═══██╗    ██╔════╝██║   ██║██╔══██╗██╔════╝██╔══██╗
{COLORS['OKCYAN']}    ██║   ██║██║██║   ██║    ███████╗██║   ██║██████╔╝█████╗  ██████╔╝
{COLORS['OKCYAN']}    ╚██╗ ██╔╝██║██║   ██║    ╚════██║██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗
{COLORS['OKCYAN']}     ╚████╔╝ ██║╚██████╔╝    ███████║╚██████╔╝██║     ███████╗██║  ██║
{COLORS['OKCYAN']}      ╚═══╝  ╚═╝ ╚═════╝     ╚══════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝
{COLORS['HEADER']}                                                                                
{COLORS['OKGREEN']}           AI System Monitor & Auto-Optimizer - World Record Quality
{COLORS['OKBLUE']}                  Professional Guinness Standards Edition
{COLORS['HEADER']}{'=' * 80}{COLORS['ENDC']}
"""
        print(header)
    
    def get_system_stats(self):
        """Get current system statistics"""
        stats = {
            'cpu_percent': psutil.cpu_percent(interval=1, percpu=False),
            'cpu_per_core': psutil.cpu_percent(interval=1, percpu=True),
            'ram_percent': psutil.virtual_memory().percent,
            'ram_used_gb': psutil.virtual_memory().used / (1024**3),
            'ram_total_gb': psutil.virtual_memory().total / (1024**3),
            'swap_percent': psutil.swap_memory().percent,
            'disk_percent': psutil.disk_usage('/').percent,
            'timestamp': datetime.now().isoformat(),
        }
        
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
        except:
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
        """Print beautiful statistics display"""
        # System Stats Box
        print(f"\n{COLORS['BOLD']}{COLORS['OKBLUE']}╔{'═' * 78}╗{COLORS['ENDC']}")
        print(f"{COLORS['BOLD']}{COLORS['OKBLUE']}║{COLORS['OKCYAN']} SYSTEM STATISTICS{' ' * 60}║{COLORS['ENDC']}")
        print(f"{COLORS['BOLD']}{COLORS['OKBLUE']}╠{'═' * 78}╣{COLORS['ENDC']}")
        
        # CPU Display
        cpu_color = (COLORS['FAIL'] if stats['cpu_percent'] > CONFIG['CPU_THRESHOLD'] 
                    else COLORS['WARNING'] if stats['cpu_percent'] > 70 
                    else COLORS['OKGREEN'])
        cpu_bar = self.create_progress_bar(stats['cpu_percent'], 50)
        print(f"{COLORS['OKBLUE']}║{COLORS['ENDC']} {COLORS['BOLD']}CPU Usage:{COLORS['ENDC']}    {cpu_color}{stats['cpu_percent']:5.1f}%{COLORS['ENDC']} {cpu_bar} {COLORS['OKBLUE']}║{COLORS['ENDC']}")
        
        # RAM Display
        ram_color = (COLORS['FAIL'] if stats['ram_percent'] > CONFIG['RAM_THRESHOLD'] 
                    else COLORS['WARNING'] if stats['ram_percent'] > 70 
                    else COLORS['OKGREEN'])
        ram_bar = self.create_progress_bar(stats['ram_percent'], 50)
        print(f"{COLORS['OKBLUE']}║{COLORS['ENDC']} {COLORS['BOLD']}RAM Usage:{COLORS['ENDC']}    {ram_color}{stats['ram_percent']:5.1f}%{COLORS['ENDC']} {ram_bar} {COLORS['OKBLUE']}║{COLORS['ENDC']}")
        print(f"{COLORS['OKBLUE']}║{COLORS['ENDC']}   Used: {stats['ram_used_gb']:.2f} GB / Total: {stats['ram_total_gb']:.2f} GB{' ' * 25}{COLORS['OKBLUE']}║{COLORS['ENDC']}")
        
        # Swap Display
        swap_color = (COLORS['FAIL'] if stats['swap_percent'] > 80 
                     else COLORS['WARNING'] if stats['swap_percent'] > 50 
                     else COLORS['OKGREEN'])
        swap_bar = self.create_progress_bar(stats['swap_percent'], 50)
        print(f"{COLORS['OKBLUE']}║{COLORS['ENDC']} {COLORS['BOLD']}SWAP Usage:{COLORS['ENDC']}   {swap_color}{stats['swap_percent']:5.1f}%{COLORS['ENDC']} {swap_bar} {COLORS['OKBLUE']}║{COLORS['ENDC']}")
        
        # Disk Display
        disk_color = (COLORS['FAIL'] if stats['disk_percent'] > 90 
                     else COLORS['WARNING'] if stats['disk_percent'] > 80 
                     else COLORS['OKGREEN'])
        disk_bar = self.create_progress_bar(stats['disk_percent'], 50)
        print(f"{COLORS['OKBLUE']}║{COLORS['ENDC']} {COLORS['BOLD']}Disk Usage:{COLORS['ENDC']}   {disk_color}{stats['disk_percent']:5.1f}%{COLORS['ENDC']} {disk_bar} {COLORS['OKBLUE']}║{COLORS['ENDC']}")
        
        print(f"{COLORS['BOLD']}{COLORS['OKBLUE']}╚{'═' * 78}╝{COLORS['ENDC']}")
        
        # Top Processes Box
        print(f"\n{COLORS['BOLD']}{COLORS['OKBLUE']}╔{'═' * 78}╗{COLORS['ENDC']}")
        print(f"{COLORS['BOLD']}{COLORS['OKBLUE']}║{COLORS['OKCYAN']} TOP RESOURCE-CONSUMING PROCESSES{' ' * 44}║{COLORS['ENDC']}")
        print(f"{COLORS['BOLD']}{COLORS['OKBLUE']}╠{'═' * 78}╣{COLORS['ENDC']}")
        print(f"{COLORS['OKBLUE']}║{COLORS['BOLD']} {'PID':<8} {'PROCESS NAME':<30} {'CPU%':<8} {'MEM%':<8} {'RISK':<8}║{COLORS['ENDC']}")
        print(f"{COLORS['BOLD']}{COLORS['OKBLUE']}╠{'═' * 78}╣{COLORS['ENDC']}")
        
        for proc in processes[:10]:
            risk_score = self.process_scores.get(proc['name'], 0)
            risk_color = (COLORS['FAIL'] if risk_score > 20 
                         else COLORS['WARNING'] if risk_score > 10 
                         else COLORS['OKGREEN'])
            
            proc_name = proc['name'][:28] + '..' if len(proc['name']) > 30 else proc['name']
            print(f"{COLORS['OKBLUE']}║{COLORS['ENDC']} {proc['pid']:<8} {proc_name:<30} "
                  f"{proc['cpu_percent']:>6.1f}%  {proc['memory_percent']:>6.1f}%  "
                  f"{risk_color}{risk_score:>6.1f}{COLORS['ENDC']}  {COLORS['OKBLUE']}║{COLORS['ENDC']}")
        
        print(f"{COLORS['BOLD']}{COLORS['OKBLUE']}╚{'═' * 78}╝{COLORS['ENDC']}")
        
        # Status Info
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        auto_kill_status = f"{COLORS['OKGREEN']}ENABLED{COLORS['ENDC']}" if CONFIG['AUTO_KILL_ENABLED'] else f"{COLORS['WARNING']}DISABLED{COLORS['ENDC']}"
        ml_status = f"{COLORS['OKGREEN']}ACTIVE{COLORS['ENDC']}" if CONFIG['ML_ENABLED'] else f"{COLORS['WARNING']}INACTIVE{COLORS['ENDC']}"
        
        print(f"\n{COLORS['OKCYAN']}Status:{COLORS['ENDC']} Auto-Kill: {auto_kill_status} | ML Prediction: {ml_status} | "
              f"Processes Killed: {COLORS['BOLD']}{len(self.killed_processes)}{COLORS['ENDC']}")
        print(f"{COLORS['OKCYAN']}Time:{COLORS['ENDC']} {timestamp} | "
              f"{COLORS['OKCYAN']}Next check in:{COLORS['ENDC']} {CONFIG['CHECK_INTERVAL']} seconds")
        
        if self.killed_processes:
            last_killed = self.killed_processes[-1]
            print(f"{COLORS['WARNING']}Last killed:{COLORS['ENDC']} {last_killed['name']} "
                  f"(PID: {last_killed['pid']}, CPU: {last_killed['cpu']:.1f}%, MEM: {last_killed['mem']:.1f}%)")
        
        print(f"\n{COLORS['OKCYAN']}Press Ctrl+C to exit{COLORS['ENDC']}")
    
    def create_progress_bar(self, percent, width=50):
        """Create visual progress bar"""
        filled = int(width * percent / 100)
        bar = '█' * filled + '░' * (width - filled)
        
        if percent > 90:
            color = COLORS['FAIL']
        elif percent > 70:
            color = COLORS['WARNING']
        else:
            color = COLORS['OKGREEN']
        
        return f"{color}{bar}{COLORS['ENDC']}"
    
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
