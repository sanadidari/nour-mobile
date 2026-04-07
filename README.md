# ⚖️ WITI Field (NOUR) - Digital Infrastructure for Institutional Bailiffs
🔗 [Live Case Study](https://sanadidari.com/witi/nour) | [WITI Ecosystem](https://sanadidari.com/witi)

**WITI Field** (codename: **NOUR**) is the specialized professional mobile ecosystem developed for the **Regional Council of Bailiffs** (Court of Appeal of Tetouan, Morocco). 

Currently in live field-testing, it bridges the gap between official judicial missions and modern high-trust digital documentation.

---

## 🏗️ Engineering Architecture & State Management

**WITI Field** is built with a **Feature-Driven Architecture** (FDA) and **Clean Architecture** principles, prioritizing high reliability and auditable code.

- **State Management**: **Riverpod** with **Code Generation** (`riverpod_generator`) for a precise, typed, and reactive state.
- **Dependency Injection**: Modular provider-based DI, enabling seamless mocking and unit testing of business logic.
- **Storage Strategy**: Local-first caching with **SQLite/Isar** for offline field durability, synced with **Supabase Real-time** via **Row-Level Security (RLS)**.
- **Hardware Integration**: Custom camera flows, GPS anti-spoofing, and **Google ML Kit Document Scanner** for high-integrity capture.

### 📁 Project Structure (lib/)
- `/features`: Domain-specific logic (Missions, Identity, Acts, Notifications).
- `/core`: Shared infrastructure, themes, and cross-cutting utilities.
- `/services`: Supabase listeners, Location handlers, and OCR connectors.
- `/providers`: High-level state managers and data flow orchestrators.

---

## 🔒 Institutional Security & Integrity
- **Field Authentication**: Deep integration with **WITI Governance** for authenticated mission assignment.
- **Evidence Verification**: Real-time integration with **WITI Certify (QRPRUF)** protocols for cryptographic proof of presence.

### 🏗️ Architectural Overview
```mermaid
graph TD
    A[UI Layer - Flutter] --> B[Domain Layer - Business Logic]
    B --> C[Data Layer - Repository Pattern]
    C --> D[(Local DB - Offline First)]
    C --> E[Remote - Supabase RLS Protected]
    subgraph "Modular Feature Architecture"
    B
    C
    end
```

---

## 📱 App Screenshots

> Live field deployment — Regional Council of Bailiffs, Court of Appeal of Tetouan, Morocco.

### Dashboard & Navigation
| Dark Mode | Light Mode | News & Activity |
|-----------|------------|-----------------|
| ![Dashboard Dark](doc/screenshots/nour1.jpeg) | ![Dashboard Light](doc/screenshots/nour2.jpeg) | ![News Home](doc/screenshots/news_home.jpeg) |

### Mission Workflow
| Intervention Form | Subject & Reference | GPS Proof |
|-------------------|---------------------|-----------|
| ![Form 1](doc/screenshots/nour6.jpeg) | ![Form 2](doc/screenshots/nour7.jpeg) | ![GPS Proof](doc/screenshots/nour8.jpeg) |

### Institutional Data
| Bailiff Directory | Regional Council | Legal Library |
|-------------------|------------------|---------------|
| ![Directory](doc/screenshots/nour4.jpeg) | ![Council](doc/screenshots/nour5.jpeg) | ![Library](doc/screenshots/nour3.jpeg) |

### Profile & Settings
| Dark Mode | Light Mode |
|-----------|------------|
| ![Settings Dark](doc/screenshots/dark_mode_settings.jpeg) | ![Settings Light](doc/screenshots/light_mode_settings.jpeg) |

---

## 🚀 Getting Started (Developers)

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Stable)
- [Dart VM](https://dart.dev/get-started/dart-sdk)
- [Supabase CLI](https://supabase.com/docs/guides/cli)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/sanadidari/nour.git
   cd nour
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Generate code (Riverpod & Freezed):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. Run the app:
   ```bash
   flutter run
   ```

---

## 🧪 Testing & CI/CD Status
- **Automated Testing**: Unit tests for domain logic located in `test/`.
- **CI/CD Pipeline**: Configured via **GitHub Actions** for automated static analysis (Lints) and test verification.

---

## 📜 License
Part of the **WITI Ecosystem**. License: **MIT License**.

---
*Developed by @sanadidari - Senior Full-Stack Engineer | Founder of Sanadidari SARL*

