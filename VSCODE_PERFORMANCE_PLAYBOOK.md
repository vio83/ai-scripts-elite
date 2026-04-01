# VS Code Performance Playbook (Mac) - VIO AI Orchestra

## 1) Baseline operativo

Obiettivo: mantenere VS Code reattivo sotto carico durante sviluppo Python e automazioni.

KPI target:

- Apertura workspace: <= 5s
- Ricerca globale (Ctrl/Cmd+Shift+F): <= 1s su pattern comuni
- Input latency editor: percezione fluida senza lag
- CPU extension host: stabile, senza picchi continui

## 2) Ottimizzazioni gia' applicate in questo workspace

File modificato: .vscode/settings.json

Interventi:

- Riduzione watchers su cartelle rumorose
- Esclusione dalla search di output forense e cache Python
- Riduzione costo azioni automatiche al salvataggio
- Tuning Python/Pylance in modalita' openFilesOnly
- Riduzione overhead grafico editor e SCM

## 3) Runbook manutenzione rapida

Script pronti:

- ./vscode_turbo_mac.sh
- ./scripts/vscode_autopilot/install_vscode_autopilot.sh

Cosa fa:

- Chiude VS Code
- Ripulisce log vecchi, workspaceStorage inattivo e GPU cache sopra soglia
- Applica preset performance al repo VIO AI Orchestra
- Produce report automatici su stato editor ed estensioni
- Riapre il repo target in VS Code

Quando usarlo:

- Subito, quando VS Code e' lento
- Dopo aggiornamenti estensioni
- Dopo sessioni lunghe o regressioni di performance

## 4) Diagnostica professionale (manuale)

Nel Command Palette:

1. Developer: Show Running Extensions
2. Extension Bisect
3. Developer: Startup Performance

Criteri intervento:

- Disabilitare estensioni con startup cost alto non critiche
- Tenere attive solo estensioni utili al progetto corrente
- Evitare piu' linter/formatter in concorrenza sullo stesso file type

## 5) Profilo estensioni consigliato per questo progetto

Mantieni essenziali:

- Python
- Pylance
- GitHub Copilot

Valuta disattivazione nel workspace se non usate ora:

- Tool cloud pesanti non necessari nella sessione
- Estensioni UI non critiche
- Duplicati di linting/formatting

## 6) Hardening prestazioni continuative

Routine automatica giornaliera:

1. Installa autopilota con ./scripts/vscode_autopilot/install_vscode_autopilot.sh --run-now --target-repo /Users/padronavio/Projects/vio83-ai-orchestra
2. Lascia attivo il LaunchAgent giornaliero
3. Controlla i report in ~/Library/Application Support/VIO/vscode-autopilot/reports
4. Apri Startup Performance solo se i report mostrano regressioni

## 7) Comandi veloci

- chmod +x ./vscode_turbo_mac.sh
- ./vscode_turbo_mac.sh
- chmod +x ./scripts/vscode_autopilot/install_vscode_autopilot.sh
- ./scripts/vscode_autopilot/install_vscode_autopilot.sh --run-now --target-repo /Users/padronavio/Projects/vio83-ai-orchestra

## 8) Note importanti

- La manutenzione automatica giornaliera usa modalita' bilanciata per evitare pulizie distruttive inutili.
- I preset vengono applicati solo al repo target dichiarato.
- La pulizia deep resta opzionale e manuale tramite ./vscode_turbo_mac.sh --mode deep.
