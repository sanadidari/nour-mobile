# NOUR - Mobile Enterprise Solution for Professional Missions

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Feature--Driven-blue?style=for-the-badge)](https://flutter.dev)

**NOUR** is a high-performance, enterprise-grade mobile application built with Flutter. It's designed to manage professional missions, dashboards, and complex user workflows with a focus on modularity, scalability, and maintainability.

---

## 🏗️ Architecture: Feature-Driven Design

As a senior-led project, NOUR follows a **Feature-Driven Architecture**. This approach ensures that the codebase remains organized and scalable as the project grows, allowing for independent development and testing of different application modules.

-   **`core/`**: Contains shared components, utilities, themes, and base classes used across the entire application.
-   **`features/`**: Each feature (Auth, Dashboard, Missions, Profile) is self-contained with its own logic, UI, and data models.
-   **`services/`**: Centralized logic for API interactions, local storage, and third-party integrations.
-   **`models/`**: Strongly-typed data structures ensuring type safety throughout the app.

---

## 🚀 Key Features

-   **Modular Mission Management**: Interactive dashboard to track and manage professional missions in real-time.
-   **Advanced Authentication**: Secure login flow with state management integration.
-   **Professional Dashboard**: Visual data representation for business-critical insights.
-   **Service-Oriented Logic**: Decoupled business logic from UI using robust service patterns.
-   **Multi-environment Support**: Ready for production-scale deployments.

---

## 🛠️ Tech Stack

-   **Frontend**: [Flutter](https://flutter.dev/) (latest stable) / Dart.
-   **State Management**: Provider / Riverpod (Clean state separation).
-   **Theme Engine**: Custom "Crystal Gold" navigation experience for professional institutional aesthetics.
-   **Data layer**: REST API integration with robust error handling and local caching.

---

## 📈 Senior Engineering Highlights

-   **Clean Code**: Strict adherence to SOLID principles and Clean Architecture patterns.
-   **Scalability**: Built to handle complex feature expansions without technical debt accumulation.
-   **Custom Tooling**: Custom scripts for data extraction, logo processing, and automated refactoring included in the repository.

---

## ⚙️ Getting Started

### Prerequisites

-   Flutter SDK (stable channel)
-   Dart SDK

### Installation

1.  Clone the repository.
2.  Run `flutter pub get`.
3.  Ensure your environment keys are set up in a local `.env` file (see `.env.example`).
4.  Launch the app: `flutter run`.

---

### 👨‍💻 Developer Note
*This project was developed with a focus on high-end mobile engineering standards, utilizing modern Flutter patterns and an AI-assisted development workflow for maximum efficiency and code quality.*
