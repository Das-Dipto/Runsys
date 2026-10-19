# Runsys — Property Management Platform 🔑

[![Flutter](https://img.shields.io/badge/Flutter-3.10.8+-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![Google Play](https://img.shields.io/badge/Google_Play-Download-414141?style=flat-square&logo=google-play&logoColor=white)](https://play.google.com/store/apps/details?id=app.runsys.runsys)
[![App Store](https://img.shields.io/badge/App_Store-Download-414141?style=flat-square&logo=apple&logoColor=white)](https://apps.apple.com/us/app/runsys/id6781288788)

**Runsys** is a comprehensive property operations and management platform built specifically for short-term rental hosts, co-hosts, and distributed field teams.

Engineered entirely from scratch as a zero-to-one mobile product, Runsys eliminates administrative fragmentation (spreadsheets, disconnected chat groups) by centralizing turnovers, inspections, cleaning schedules, and maintenance tracking into a unified interface.

---

## 🏗 Architectural & Engineering Scope

- **Zero-to-One Development:** Architected and developed end-to-end from conception, handling core UI/UX workflows, network layers, and state boundaries independently.
- **Field-Ready Execution:** Built robust data handling for field agents operating across varying network conditions, ensuring seamless task completion syncing.
- **Continuous Maintenance & Optimization:** Actively maintained post-launch, resolving synchronization edge cases and refining state management for optimal battery and memory performance.

---

## 🌟 Core Modules & Features

- **Automated Turnover Orchestration:** Dynamic scheduling workflows that align property cleaning and maintenance cycles directly with real-time booking updates.
- **Granular Task Management:** Direct task assignment workflows for field cleaners and inspectors, featuring property-specific custom checklists.
- **Photo-Verified Audits & Reporting:** Integrated hardware pipelines (`image_picker`, `image_cropper`) allowing field operators to capture real-time photo verification and submit on-the-spot incident reports.
- **Operational Analytics:** Dashboards tracking unit occupancy rates, maintenance history logs, response metrics, and owner-ready reporting tools.

---

## 🛠 Technical Stack

- **Framework:** Flutter SDK (`^3.10.8`) / Dart
- **State Management:** Provider (`provider`)
- **Hardware Integration:** `device_info_plus` (device verification), `image_picker`, `image_cropper`
- **Data & Rendering:** HTTP client, Shared Preferences, Flutter HTML (`flutter_html`) for checklist document parsing
- **Build & Distribution:** Configured with custom launcher assets and adaptive icons across Android and iOS targets.

---

## 💻 Getting Started

### Prerequisites
- Flutter SDK `3.10.8` or higher
- Dart SDK `^3.10.8`