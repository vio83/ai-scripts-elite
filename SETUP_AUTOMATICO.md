# 🚀 Setup Automatico Permanente - Guida Completa

## Come Automatizzare Tutto Permanentemente

### 📋 Risposta Rapida

**NON devi collegare l'iPhone al Mac!** Tutto funziona via rete WiFi/Internet.

Il Mac esegue il server, l'iPhone si connette via Safari.

---

## 🎯 Setup in 3 Passi

### PASSO 1: Setup Iniziale Mac (Una Volta Sola)

```bash
# 1. Vai nella cartella del progetto
cd /path/to/ai-scripts-elite

# 2. Esegui installazione completa
chmod +x install_complete.sh
./install_complete.sh

# Questo installa:
# - Python dependencies (Flask, psutil)
# - Configura email
# - Crea comandi facili (vio-monitor, vio-dashboard)
```

### PASSO 2: Avvio Automatico Mac (Permanente)

Usa lo script di auto-start che creerò per te:

```bash
# Esegui questo comando UNA VOLTA
./setup_autostart.sh

# Questo configurerà:
# - Avvio automatico al login Mac
# - Dashboard web sempre attiva
# - Email notifications sempre attive
```

### PASSO 3: Connetti iPhone (Ogni Volta)

```bash
# Sul Mac, trova il tuo IP:
ifconfig | grep "inet " | grep -v 127.0.0.1

# Su iPhone:
# 1. Apri Safari
# 2. Vai a: http://TUO_IP_MAC:5000
# 3. Aggiungi a Home Screen
# 4. Fatto! Ora hai l'icona sulla home
```

---

## 🔄 Automazione Completa

### Opzione A: Auto-Start al Login Mac (Consigliato)

Lo script `setup_autostart.sh` creerà un file che:
- Si avvia automaticamente quando accendi il Mac
- Resta attivo in background
- Dashboard sempre disponibile su porta 5000
- Email notifications sempre attive

### Opzione B: Sempre Attivo (24/7)

Per mantenere il Mac sempre acceso e il servizio sempre attivo:

```bash
# 1. Impedisci sleep del Mac
sudo pmset -a displaysleep 0
sudo pmset -a sleep 0
sudo pmset -a disksleep 0

# 2. Avvia servizio permanente
./run_permanent.sh
```

---

## 📱 Uso iPhone (Senza Cavi!)

### Connessione In Casa (Stessa WiFi)

```
1. Mac connesso al WiFi di casa
2. iPhone connesso allo STESSO WiFi
3. Safari su iPhone → http://192.168.1.XXX:5000
4. Funziona! ✅
```

### Connessione Fuori Casa

**Opzione 1: VPN (Sicura)**
```
1. Configura VPN sul Mac
2. iPhone si connette a VPN
3. Usa stesso IP locale
4. Funziona ovunque! 🌍
```

**Opzione 2: Ngrok (Facile)**
```bash
# Sul Mac (una volta)
brew install ngrok

# Ogni volta che esci
ngrok http 5000

# Usa URL pubblico su iPhone ovunque!
```

---

## 🤖 Automazione Permanente - Script Inclusi

Ho creato questi script per te:

### 1. `setup_autostart.sh`
Configura avvio automatico permanente
```bash
./setup_autostart.sh
```

### 2. `run_permanent.sh`
Avvia tutti i servizi in background
```bash
./run_permanent.sh
```

### 3. `stop_all.sh`
Ferma tutti i servizi
```bash
./stop_all.sh
```

### 4. `check_status.sh`
Verifica se tutto è attivo
```bash
./check_status.sh
```

---

## 📧 Email Automatiche

### Setup Una Volta:

```bash
# 1. Configura email
nano ~/.vio_super_ai/email_config.json

# 2. Inserisci:
{
  "smtp_server": "smtp.gmail.com",
  "smtp_port": 587,
  "sender_email": "tua-email@gmail.com",
  "sender_password": "app-password-16-caratteri",
  "recipient_email": "tua-email@gmail.com",
  "enabled": true
}
```

### Gmail App Password:
1. https://myaccount.google.com/security
2. "Verifica in due passaggi" → Attiva
3. "Password per le app" → Mail → Genera
4. Copia password (16 caratteri senza spazi)

### Riceverai Email:
- ✉️ Ogni 30 minuti: Status update
- 🚨 Immediate: Critical alerts (RAM/CPU >95%)
- 📊 Su richiesta: Work session updates

---

## 🎮 Comandi Rapidi

Dopo l'installazione, puoi usare:

```bash
# Dashboard iPhone (auto-start disponibile)
vio-dashboard

# Monitor MINIMALIST
vio-monitor

# Monitor ELITE
vio-monitor-elite

# Setup auto-start
./setup_autostart.sh

# Avvia permanente (background)
./run_permanent.sh

# Ferma tutto
./stop_all.sh

# Controlla status
./check_status.sh
```

---

## ✅ Checklist Setup Permanente

### Setup Iniziale (Una Volta):
- [ ] Eseguito `./install_complete.sh`
- [ ] Configurato email in `~/.vio_super_ai/email_config.json`
- [ ] Eseguito `./setup_autostart.sh`
- [ ] Testato connessione iPhone: `http://IP_MAC:5000`
- [ ] Aggiunto icona su Home Screen iPhone

### Dopo Ogni Riavvio Mac:
- [ ] Il servizio si avvia AUTOMATICAMENTE ✅
- [ ] Niente da fare manualmente!

### Ogni Volta Usi iPhone:
- [ ] Apri icona su Home Screen
- [ ] Vedi dashboard in tempo reale
- [ ] Tutto funziona!

---

## 🔍 Come Verificare Che Funzioni

### Sul Mac:
```bash
# Verifica servizi attivi
./check_status.sh

# Dovresti vedere:
# ✅ Web Dashboard: RUNNING on port 5000
# ✅ Monitor: ACTIVE
# ✅ Email: CONFIGURED
```

### Su iPhone:
```
1. Apri Safari
2. Vai a http://IP_MAC:5000
3. Vedi dashboard con dati real-time? ✅
4. Premi Start? ✅
5. Vedi CPU/RAM aggiornati? ✅
```

### Email:
```
1. Controlla inbox
2. Ricevuto "VIO Super AI - Status Update"? ✅
3. Email con grafici e statistiche? ✅
```

---

## 🆘 Risoluzione Problemi

### Dashboard non si apre su iPhone?

```bash
# Sul Mac - Controlla firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off

# Verifica che servizio è attivo
./check_status.sh

# Riavvia servizio
./stop_all.sh
./run_permanent.sh
```

### Email non arrivano?

```bash
# Test email manuale
python3 -c "
from email_notifier import EmailNotifier
n = EmailNotifier()
n.send_email('Test', 'Funziona!', '<h1>OK</h1>')
"
```

### Servizio non parte automaticamente?

```bash
# Ri-configura auto-start
./setup_autostart.sh

# Verifica LaunchAgent
ls -la ~/Library/LaunchAgents/com.viosuperai.*

# Test manuale
launchctl load ~/Library/LaunchAgents/com.viosuperai.dashboard.plist
```

---

## 💡 Consigli Pro

### Per Massima Affidabilità:

1. **Impedisci Sleep Mac**
```bash
sudo pmset -a displaysleep 0
sudo pmset -a sleep 0
```

2. **Auto-Start Garantito**
```bash
./setup_autostart.sh
# Riavvia Mac per testare
```

3. **Backup Configurazione**
```bash
cp ~/.vio_super_ai/email_config.json ~/Desktop/backup_email_config.json
```

4. **VPN per Accesso Remoto**
- Più sicuro di port forwarding
- Funziona ovunque
- Nessuna configurazione router

---

## 📊 Cosa Succede Automaticamente

### Quando Accendi il Mac:
1. ✅ Dashboard web si avvia automaticamente
2. ✅ Monitor sistema inizia tracking
3. ✅ Email notifications attive
4. ✅ Porta 5000 aperta per iPhone

### Quando Usi iPhone:
1. ✅ Apri Safari o icona Home Screen
2. ✅ Dashboard si connette automaticamente
3. ✅ Dati in tempo reale (2 sec refresh)
4. ✅ Controlli touch funzionanti

### Durante il Giorno:
1. ✅ Email ogni 30 min (status update)
2. ✅ Alert immediati se RAM/CPU >95%
3. ✅ ML impara comportamento processi
4. ✅ Auto-kill processi pesanti

---

## 🎯 Risultato Finale

### Configurazione Una Volta:
```bash
./install_complete.sh     # Setup iniziale
./setup_autostart.sh      # Auto-start permanente
```

### Poi Per Sempre:
- ✅ Mac si accende → Tutto si avvia automaticamente
- ✅ iPhone apre Safari → Dashboard funziona
- ✅ Email arrivano → Notifiche come GitHub
- ✅ Zero manutenzione necessaria

### Nessun Cavo iPhone!
- ✅ Tutto via WiFi/Internet
- ✅ Nessun collegamento fisico
- ✅ Funziona a distanza
- ✅ iPhone indipendente

---

## 📱 In Pratica

### Oggi (Setup):
```bash
# 1. Sul Mac
cd ai-scripts-elite
./install_complete.sh
./setup_autostart.sh

# 2. Su iPhone
Safari → http://IP_MAC:5000
Aggiungi a Home Screen
```

### Domani e Sempre:
```bash
# Sul Mac: NIENTE! (tutto automatico)

# Su iPhone:
# - Apri icona Home Screen
# - Vedi dashboard
# - Fatto!
```

---

© 2025 VIO Super AI - Proprietary Software
Setup Automatico Permanente per iPhone 15 (iOS Tahoe 2026/26.1)
