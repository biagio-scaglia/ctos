<div align="center">

# ⚡ CTOS Companion

### Il tuo sistema di sorveglianza digitale personale

*Ispirato all'universo Watch Dogs — sicurezza reale, estetica hacker*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Android-8.0%2B-3DDC84?logo=android)](https://developer.android.com)
[![Licenza](https://img.shields.io/badge/Licenza-MIT-cyan)](#legale)

</div>

---

## Cos'è CTOS?

**CTOS Companion** è un'app di sicurezza Android nello stile di Watch Dogs: monitora in tempo reale le app installate, le connessioni di rete, il consumo delle risorse e ti avvisa quando qualcosa di sospetto accade sul tuo dispositivo.

Non un antivirus classico. Un **centro di controllo** visivo che ti mostra esattamente cosa stanno facendo le tue app — e perché dovresti preoccuparti.

---

## Funzionalità

### 🛡️ Dashboard Rischio
Punteggio di rischio globale (0–100) calcolato in tempo reale da app, rete ed eventi. Radar visivo con tutti i processi attivi.

### 🔍 Scanner App
Analisi di ogni app installata con:
- Permessi pericolosi (fotocamera, microfono, posizione, contatti…)
- Wakelocks, uso CPU e RAM
- Traffico di rete generato
- Servizi di accessibilità abilitati
- Avvio automatico al boot

### 🌐 Monitor di Rete
Connessioni TCP attive in tempo reale con:
- Geolocalizzazione dell'IP remoto
- Rilevamento datacenter / cloud
- Rilevamento nodi Tor
- Punteggio di sospetto per ogni connessione
- Grafico traffico live (Kbps / Mbps)

### 🔒 Rilevamento VPN
Controlla se il traffico è protetto da VPN. Notifica quando la VPN cade o viene attivata.

### 👁️ Security Guardian
Servizio in primo piano sempre attivo. Analizza app e connessioni ogni 30 secondi e genera alert intelligenti con cooldown di 4 ore (niente spam).

### 📅 Scansione Periodica (WorkManager)
- Scansione automatica ogni 6 ore in background
- Briefing giornaliero alle 8:00 con il riepilogo della sicurezza
- Funziona anche quando l'app è chiusa

### 📱 Widget Home Screen
Widget 2×2 sempre visibile sulla schermata principale:
- Punteggio di rischio colorato (verde → rosso)
- Stato VPN (attivo / non attivo)
- Ultima scansione eseguita
- Tap per aprire CTOS direttamente

### 🔗 Analisi URL
Analisi euristica di URL prima di aprirli. Rilevamento di domini sospetti, typosquatting, redirect pericolosi.

### 📊 Timeline & Centro Minacce
Log cronologico di tutti gli eventi con filtri. Lista ordinata per rischio di app e connessioni sospette.

---

## Permessi Richiesti

| Permesso | Motivo |
|---|---|
| `PACKAGE_USAGE_STATS` | Statistiche d'uso delle app (CPU, RAM, rete) |
| `READ_PHONE_STATE` | Identificazione del dispositivo |
| `POST_NOTIFICATIONS` | Alert di sicurezza in tempo reale |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Mantiene il Guardian attivo in background |
| `INTERNET` | Geolocalizzazione IP, rilevamento Tor |
| `FOREGROUND_SERVICE` | Servizio di protezione persistente |
| `RECEIVE_BOOT_COMPLETED` | Riavvio automatico del Guardian al boot |

> **Nota**: CTOS non legge contenuti di altre app, non intercetta il traffico e non carica dati su server esterni.

---

## Build

```bash
# Installa dipendenze
flutter pub get

# Avvia in debug
flutter run

# Build APK release
flutter build apk --release
```

**Requisiti:**
- Flutter 3.x
- Android SDK 26+ (Android 8.0 Oreo)
- Java 17+ (consigliato Java 21)
- Gradle 8.9 / AGP 8.6.1

---

## Architettura

```
lib/
├── core/
│   ├── theme/          # Colori, stile cyberpunk (CtosColors)
│   └── utils/          # Motori di calcolo rischio e sospetto
├── data/
│   ├── models/         # AppInfo, NetworkConnection, VpnStatus…
│   └── local/          # Hive DB, storico eventi
├── services/
│   ├── device_monitor_service.dart   # Scanner app nativo
│   ├── network_service.dart          # Connessioni TCP reali
│   ├── vpn_detection_service.dart    # Rilevamento VPN
│   ├── security_guardian_service.dart # Alert intelligenti
│   └── notification_service.dart    # Push + coda in-app
└── presentation/
    ├── providers/      # Riverpod state management
    ├── screens/        # Dashboard, Scan, Network, Timeline…
    └── widgets/        # HUD components, radar, grafici

android/
├── CtosProtectionService.kt   # Foreground service persistente
├── CtosBackgroundWorker.kt    # WorkManager (scan 6h + briefing)
├── CtosWidget.kt              # AppWidgetProvider home screen
├── BootReceiver.kt            # Riavvio automatico al boot
└── MainActivity.kt            # Bridge Flutter ↔ Android
```

---

## Stack Tecnologico

| Layer | Tecnologia |
|---|---|
| UI | Flutter + flutter_animate |
| State | Riverpod |
| Database locale | Hive |
| Grafici | FL Chart + Custom Painters |
| Background | WorkManager (androidx.work) |
| Native Bridge | Android MethodChannel |
| Permessi | permission_handler |

---

## Legale

CTOS Companion legge esclusivamente API pubbliche di Android (pacchetti installati, statistiche di rete, batteria, connessioni TCP da `/proc/net/tcp`).

**Non intercetta** il traffico di terze parti, **non bypassa** restrizioni di sistema, **non carica** dati su server remoti.

Progettato per scopi educativi e per la consapevolezza della sicurezza personale.

---

<div align="center">

*"In un mondo connesso, la privacy è potere."*

**CTOS Companion** — Vedi tutto. Controlla tutto.

</div>
