# CTOS Companion

**Device Security Monitor** — Watch Dogs / CTOS style mobile security app built with Flutter.

## Features

- **Risk Dashboard** — Global device risk score (0-100) calculated from apps, network, and events
- **App Scanner** — Suspicion score per app based on permissions, wake locks, CPU/RAM, network
- **Network Monitor** — Live connections with geolocation, datacenter detection, and suspicion scoring
- **VPN Detection** — Detects active VPN interfaces and alerts on connection/disconnection
- **App Behavior Tracking** — 7-day history per app, trend analysis (improving/worsening)
- **Security Guardian** — Always-on real-time protection with proactive alerts
- **URL Safety Checker** — Heuristic analysis of URLs before you click them
- **Timeline** — Chronological event log with filtering
- **Threat Center** — Ranked list of suspicious apps and connections

## Stack

- Flutter + Dart (cross-platform)
- Riverpod (state management)
- Hive (local database)
- FL Chart (graphs)
- Flutter Animate (animations)
- Custom painters (radar, gauge, scanlines)
- Android MethodChannel for native APIs

## Setup

```bash
flutter pub get
flutter run
```

Requires Android SDK 26+ (Android 8.0).

## Architecture

```
lib/
├── core/          # Theme, colors, utilities (suspicion/risk engines)
├── data/          # Models, Hive adapters, local DB service
├── services/      # Device monitor, network, VPN, guardian, audio
├── presentation/
│   ├── providers/ # Riverpod providers
│   ├── screens/   # All 6 screens
│   └── widgets/   # Reusable HUD components, charts
```

## Legal

This app reads only publicly available device APIs (installed packages, network stats, battery).
It does NOT intercept third-party traffic or bypass any system restrictions.
Designed for educational and security awareness purposes.
