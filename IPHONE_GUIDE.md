# 📱 VIO Super AI - Guida iPhone & Email Notifications

## Come Usare VIO Super AI dal tuo iPhone 15

### 🎯 Panoramica

Ora puoi monitorare e controllare il tuo Mac direttamente dal tuo **iPhone 15** anche quando sei fuori casa! Il sistema include:

1. ✉️ **Notifiche Email** - Ricevi aggiornamenti via email come le notifiche GitHub
2. 📱 **Dashboard Web per iPhone** - Interfaccia touch-friendly accessibile da Safari
3. 🔄 **Sincronizzazione Real-time** - Vedi lo stato del Mac in tempo reale

---

## 📧 PARTE 1: Notifiche Email

### Configurazione Email

#### Step 1: Installa Dipendenze
```bash
pip3 install flask
```

#### Step 2: Configura Email
```bash
# Avvia il configuratore email
python3 email_notifier.py
```

Questo creerà il file: `~/.vio_super_ai/email_config.json`

#### Step 3: Modifica Configurazione
Apri il file con un editor:
```bash
nano ~/.vio_super_ai/email_config.json
```

Inserisci i tuoi dati:
```json
{
  "smtp_server": "smtp.gmail.com",
  "smtp_port": 587,
  "sender_email": "tua-email@gmail.com",
  "sender_password": "tua-app-password",
  "recipient_email": "tua-email@gmail.com",
  "enabled": true
}
```

### 🔐 Come Ottenere Gmail App Password

1. Vai su: https://myaccount.google.com/security
2. Attiva **Verifica in due passaggi** (se non già attiva)
3. Cerca **"Password per le app"** o **"App passwords"**
4. Seleziona:
   - App: **Mail**
   - Dispositivo: **Mac**
5. Google genererà una password di 16 caratteri
6. Copia questa password nel file config (senza spazi)

**IMPORTANTE:** Usa l'App Password, NON la tua password Gmail normale!

### 📬 Tipi di Notifiche Email

#### 1. Status Update (Ogni 30 minuti)
Ricevi aggiornamenti regolari sullo stato del sistema:
- CPU e RAM usage
- Memory pressure
- Processi terminati
- Uptime del sistema

#### 2. Critical Alerts (Immediati)
Notifiche immediate per:
- RAM >95% (rischio freeze)
- CPU >95% (sovraccarico)
- Processi problematici terminati

#### 3. Work Session Updates (Come GitHub)
Notifiche stile GitHub per:
- Inizio/fine sessione di monitoring
- Progressi e statistiche
- Attività del sistema

### 🔧 Come Usare le Notifiche Email

```python
from email_notifier import EmailNotifier

# Inizializza
notifier = EmailNotifier()

# Invia status update
notifier.send_status_update(stats, killed_processes_count)

# Invia alert critico
notifier.send_critical_alert("High RAM", "RAM at 96%", stats)

# Invia work session update (come GitHub)
notifier.send_work_session_update({
    'title': 'System Monitor - Sessione Attiva',
    'status': 'Running smoothly',
    'details': 'Sistema ottimizzato, 3 processi terminati',
    'duration': '2h 15m',
    'tasks_completed': 5,
    'tasks_remaining': 0
})
```

---

## 📱 PARTE 2: Dashboard Web per iPhone

### Configurazione Dashboard

#### Step 1: Installa Flask (se non già fatto)
```bash
pip3 install flask
```

#### Step 2: Avvia il Server Web
```bash
python3 web_dashboard.py
```

Vedrai un messaggio tipo:
```
* Running on http://0.0.0.0:5000
```

#### Step 3: Trova l'IP del tuo Mac
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

Esempio output:
```
inet 192.168.1.100 netmask 0xffffff00
```

L'IP è: **192.168.1.100**

#### Step 4: Accedi dal tuo iPhone

1. Apri **Safari** sul tuo iPhone 15
2. Digita nella barra indirizzi:
   ```
   http://192.168.1.100:5000
   ```
   (Sostituisci `192.168.1.100` con il TUO IP Mac)

3. Premi **Invio**

4. Vedrai la dashboard VIO Super AI! 🎉

### 🎨 Features Dashboard iPhone

La dashboard è ottimizzata per iPhone:

✅ **Touch-Friendly**
- Bottoni grandi e facili da premere
- Scroll fluido
- Design responsive

✅ **Real-Time Updates**
- Aggiornamento automatico ogni 2 secondi
- CPU e RAM con barre di progresso colorate
- Top 5 processi più pesanti

✅ **Controlli Diretti**
- ▶️ Start - Avvia monitoring
- ⏸️ Stop - Pausa monitoring
- Controllo completo dal telefono

✅ **Visuals Professionali**
- Gradienti colorati
- Emoji indicators (🥇🥈🥉)
- Barre di stato dinamiche
- Design simile alle app iOS native

### 📲 Salvare Dashboard come App

Per avere un'icona sulla home screen dell'iPhone:

1. Apri la dashboard in Safari
2. Premi il pulsante **Condividi** (quadrato con freccia)
3. Scorri e seleziona **"Aggiungi a Home"**
4. Dai un nome: "VIO Super AI"
5. Premi **Aggiungi**

Ora hai un'icona sulla home che apre direttamente la dashboard! 📱

---

## 🌍 PARTE 3: Accesso da Fuori Casa

### Opzione A: VPN (Consigliato e Sicuro)

#### Con Mac Built-in VPN
1. Sul Mac: Vai in **System Settings** > **General** > **Sharing**
2. Attiva **Screen Sharing** e **Remote Login**
3. Configura VPN in **System Settings** > **Network**

#### iPhone Setup
1. Su iPhone: **Settings** > **VPN**
2. Aggiungi nuova configurazione VPN
3. Connettiti alla VPN
4. Accedi alla dashboard usando l'IP locale

### Opzione B: Port Forwarding (Avanzato)

⚠️ **ATTENZIONE: Richiede configurazione router**

1. Accedi al router (solitamente 192.168.1.1)
2. Trova sezione **Port Forwarding**
3. Crea regola:
   - External Port: 5000
   - Internal IP: IP del Mac
   - Internal Port: 5000
4. Trova il tuo IP pubblico: https://whatismyipaddress.com
5. Accedi da iPhone: `http://TUO_IP_PUBBLICO:5000`

**Nota Sicurezza:** Questa opzione espone il server pubblicamente. Consiglio VPN!

### Opzione C: Ngrok (Più Semplice per Test)

```bash
# Installa ngrok
brew install ngrok

# Avvia tunnel
ngrok http 5000
```

Ngrok ti darà un URL tipo:
```
https://abc123.ngrok.io
```

Usa questo URL sul tuo iPhone ovunque tu sia! 🌍

---

## 🔄 PARTE 4: Integrazione Completa

### Script Combinato: Monitor + Email + Web

Crea un nuovo file: `vio_monitor_complete.py`

```python
#!/usr/bin/env python3
from mac_system_monitor import MacSystemMonitor
from email_notifier import EmailNotifier
import threading
import time

# Inizializza componenti
monitor = MacSystemMonitor()
notifier = EmailNotifier()

# Funzione per inviare updates periodici
def send_periodic_updates():
    while True:
        time.sleep(1800)  # Ogni 30 minuti
        if hasattr(monitor, 'get_system_stats'):
            stats = monitor.get_system_stats()
            notifier.send_status_update(stats, len(monitor.killed_processes))

# Avvia thread email
email_thread = threading.Thread(target=send_periodic_updates, daemon=True)
email_thread.start()

# Avvia monitoring
print("VIO Super AI - Sistema Completo Avviato")
print("- Monitoring attivo")
print("- Notifiche email abilitate")
print("- Dashboard web: http://YOUR_IP:5000")
monitor.run()
```

Poi avvia:
```bash
# Terminal 1: Web Dashboard
python3 web_dashboard.py

# Terminal 2: Monitor con Email
python3 vio_monitor_complete.py
```

---

## 📊 PARTE 5: Auto-Start per Continuità

### Avvio Automatico Mac

Crea file: `~/Library/LaunchAgents/com.viosuperai.monitor.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.viosuperai.monitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/python3</string>
        <string>/path/to/web_dashboard.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

Carica:
```bash
launchctl load ~/Library/LaunchAgents/com.viosuperai.monitor.plist
```

Ora si avvia automaticamente ad ogni login!

---

## 🎯 Quick Start per iPhone

### Setup Veloce (5 minuti)

```bash
# 1. Installa dipendenze
pip3 install flask

# 2. Configura email
python3 email_notifier.py
# Modifica ~/.vio_super_ai/email_config.json

# 3. Trova IP Mac
ifconfig | grep "inet " | grep -v 127.0.0.1

# 4. Avvia dashboard
python3 web_dashboard.py

# 5. Su iPhone, apri Safari e vai a:
#    http://TUO_IP_MAC:5000
```

---

## 🆘 Troubleshooting iPhone

### Problema: Non riesco a connettermi dal iPhone

**Soluzione 1: Controlla Firewall Mac**
```bash
# Disabilita temporaneamente per test
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off

# Oppure aggiungi eccezione per Python
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/local/bin/python3
```

**Soluzione 2: Verifica Stessa Rete WiFi**
- Mac e iPhone devono essere sulla stessa rete WiFi
- Verifica nome rete su entrambi i dispositivi

**Soluzione 3: Prova con IP Diverso**
```bash
# Lista tutti gli IP
ifconfig
# Prova ogni IP inet che vedi
```

### Problema: Email non arrivano

**Checklist:**
1. ✅ Hai usato Gmail App Password (non password normale)?
2. ✅ Hai attivato `"enabled": true` nel config?
3. ✅ Hai verificato l'email destinatario?
4. ✅ Controlla spam/posta indesiderata

**Test email manuale:**
```python
from email_notifier import EmailNotifier
notifier = EmailNotifier()
notifier.send_email("Test", "This is a test", "<h1>Test</h1>")
```

### Problema: Dashboard lenta su iPhone

**Ottimizzazioni:**
1. Riduci intervallo aggiornamento nel codice (da 2 a 5 secondi)
2. Limita numero processi mostrati (da 5 a 3)
3. Usa connessione WiFi invece di dati cellulare

---

## 📱 Screenshot Dashboard iPhone

La dashboard su iPhone 15 mostra:

```
╔════════════════════════════════════╗
║  🚀 VIO Super AI Monitor          ║
║  iPhone Dashboard                 ║
╠════════════════════════════════════╣
║  ✅ Connected & Monitoring         ║
╠════════════════════════════════════╣
║  ⚡ System Status                  ║
║  CPU Usage          42.3%         ║
║  [████████████░░░░░░░░░]          ║
║  RAM Usage          61.2%         ║
║  [███████████████░░░░░]           ║
║  Memory Pressure    Moderate      ║
╠════════════════════════════════════╣
║  📊 Top Processes                  ║
║  🥇 Safari          2.3%          ║
║  🥈 Chrome          1.8%          ║
║  🥉 WebKit          1.4%          ║
╠════════════════════════════════════╣
║  [▶️ Start]  [⏸️ Stop]            ║
╚════════════════════════════════════╝
```

---

## ✅ Checklist Finale

Prima di uscire di casa:

- [ ] Dashboard web avviata su Mac
- [ ] Email notifications configurate e testate
- [ ] iPhone connesso e dashboard funzionante
- [ ] Salvata icona dashboard su home screen iPhone
- [ ] VPN configurata (se accedi da fuori)
- [ ] Auto-start configurato (opzionale)

---

## 🎉 Risultato Finale

Ora puoi:

✅ **Monitorare il Mac dal tuo iPhone 15** ovunque tu sia
✅ **Ricevere notifiche email** come quelle di GitHub
✅ **Controllare il sistema da remoto** con touch
✅ **Vedere statistiche real-time** con grafica professionale
✅ **Lavorare fuori casa** senza problemi

**Nessun Terminal necessario su iPhone** - tutto via Safari! 🎊

---

© 2025 VIO Super AI - Proprietary Software
Soluzione Completa per iPhone 15 con iOS Tahoe 2026/26.1
