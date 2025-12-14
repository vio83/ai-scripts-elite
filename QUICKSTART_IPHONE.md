# 🚀 VIO Super AI - Quick Start per iPhone & Email

## Setup Rapido (10 minuti)

### 1️⃣ Installazione Completa

```bash
# Clona repo (se non già fatto)
git clone https://github.com/vio83/ai-scripts-elite.git
cd ai-scripts-elite

# Installa tutto (dependencies + config)
chmod +x install_complete.sh
./install_complete.sh
```

### 2️⃣ Configura Email Notifications

```bash
# Modifica il file di configurazione
nano ~/.vio_super_ai/email_config.json
```

Inserisci i tuoi dati:
```json
{
  "smtp_server": "smtp.gmail.com",
  "smtp_port": 587,
  "sender_email": "tua-email@gmail.com",
  "sender_password": "tua-app-password-16-caratteri",
  "recipient_email": "tua-email@gmail.com",
  "enabled": true
}
```

**Gmail App Password:**
1. https://myaccount.google.com/security
2. Attiva "Verifica in due passaggi"
3. "Password per le app" → Mail → Genera
4. Copia la password di 16 caratteri

### 3️⃣ Avvia Dashboard Web

```bash
python3 web_dashboard.py
```

Vedrai:
```
* Running on http://0.0.0.0:5000
```

### 4️⃣ Trova IP del Mac

```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

Esempio output:
```
inet 192.168.1.100
```

### 5️⃣ Connetti iPhone

1. Apri **Safari** su iPhone 15
2. Digita: `http://192.168.1.100:5000`
3. Vedrai la dashboard VIO Super AI! 🎉
4. Premi **Condividi** → **Aggiungi a Home** per l'icona

---

## 📧 Test Email Veloce

```bash
python3 -c "
from email_notifier import EmailNotifier
notifier = EmailNotifier()
notifier.send_email('Test VIO', 'Funziona!', '<h1>Test OK</h1>')
"
```

Se ricevi l'email = tutto OK! ✅

---

## 🎮 Comandi Rapidi

```bash
# Dashboard per iPhone
python3 web_dashboard.py

# Monitor MINIMALIST
python3 mac_system_monitor.py

# Monitor ELITE
python3 mac_system_monitor_elite.py

# Test email
python3 email_notifier.py
```

Con symlink installati:
```bash
vio-dashboard       # Dashboard iPhone
vio-monitor         # Monitor MINIMALIST
vio-monitor-elite   # Monitor ELITE
```

---

## 📱 Dashboard iPhone - Features

✅ Real-time CPU/RAM/Disk monitoring
✅ Top 5 processi con emoji (🥇🥈🥉)
✅ Progress bar colorate (verde→giallo→rosso)
✅ Controlli Start/Stop touch-friendly
✅ Auto-refresh ogni 2 secondi
✅ Design iOS-native con gradienti
✅ Funziona su iOS Tahoe 2026/26.1

---

## 📧 Email Notifications - Tipi

**1. Status Update (ogni 30 min)**
- CPU, RAM, Disk usage
- Memory pressure
- Processi uccisi
- Uptime

**2. Critical Alert (immediato)**
- RAM >95%
- CPU >95%
- Processi problematici

**3. Work Session (come GitHub)**
- Progressi lavoro
- Statistiche sessione
- Tasks completed

---

## 🌍 Accesso da Fuori Casa

### Opzione A: VPN (Sicuro ✅)
1. Configura VPN su Mac
2. Connetti iPhone a VPN
3. Usa stesso IP locale

### Opzione B: Ngrok (Facile)
```bash
brew install ngrok
ngrok http 5000
```

Usa URL pubblico su iPhone ovunque!

### Opzione C: Port Forwarding (Avanzato)
Configura router per esporre porta 5000

---

## 🆘 Problemi Comuni

### iPhone non si connette?
```bash
# Disabilita firewall Mac temporaneamente
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off
```

### Email non arrivano?
- Verifica Gmail App Password (16 caratteri)
- Controlla `"enabled": true` nel config
- Guarda cartella spam

### Dashboard lenta?
- Riduci intervallo aggiornamento (da 2 a 5 sec)
- Usa WiFi invece di dati cellulare

---

## 📖 Documentazione Completa

- **IPHONE_GUIDE.md** - Guida completa in italiano (10K)
- **README.md** - Documentazione generale
- **VERSION_COMPARISON.md** - Confronto versioni

---

## ✅ Checklist Finale

Prima di uscire di casa:

- [ ] Dashboard web avviata: `python3 web_dashboard.py`
- [ ] Email config completa e testata
- [ ] iPhone connesso e funzionante
- [ ] Icona su Home Screen creata
- [ ] IP Mac salvato o VPN configurata

---

## 🎉 Risultato

Ora hai:
✅ Monitoring Mac dal tuo iPhone 15
✅ Notifiche email come GitHub
✅ Controllo remoto completo
✅ Dashboard professionale
✅ Tutto via Safari (no Terminal su iPhone!)

---

© 2025 VIO Super AI - Proprietary Software
Soluzione Completa per iPhone 15 con iOS Tahoe 2026/26.1
