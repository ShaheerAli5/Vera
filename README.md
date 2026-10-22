# VERA

<p align="center">
  <strong style="font-size: 20px;">Private Location & Time-Unlocked Moments Mobile Platform</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Flutter_BLoC-8A2BE2?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter BLoC" />
  <img src="https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white" alt="Node.js" />
  <img src="https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white" alt="TypeScript" />
  <img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL" />
  <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker" />
</p>

---

## 📌 Project Overview

**VERA** is a modern, dark-themed social mobile application built with **Flutter** and backed by a **Node.js/TypeScript API**, **PostgreSQL**, and **Private Object Storage**. 

VERA enables users to send and receive private **"Moments"** that unlock only when specific server-validated conditions (such as physical location coordinates or time/date bounds) are satisfied.

---

## ✨ Features & Screen Highlights

### 📱 Mobile UI & Experience

| Screen | Description |
|---|---|
| **Splash Screen** | Features an infinity loop custom painter (`InfinityPainter`), glowing branding, dark gradient backdrop, and navigation to **Get Started** or **Sign In**. |
| **Sign In Screen** | Dark glassmorphic authentication interface supporting Apple & Google social sign-in, email/password input, glowing purple gradient CTA, and navigation to registration. |
| **Create Account Screen** | Account setup with user name input, email validation, Terms & Privacy checkbox, social sign-up options, and account creation CTA. |
| **Home Feed Screen** | Main feed with sub-navigation tabs (**For You**, **Discover**, **Your Moments**) displaying location and time-locked moment cards. |
| **Moment Cards** | Interactive feed cards displaying a blurred background preview, glassmorphic floating user badge (*"John Travolta - 2h ago"*), center lock icon, and bottom location unlock banner (*"Opens when you're at Tokyo Tower"*). |
| **Glassmorphic Navigation Bar** | Floating translucent bottom navigation bar with active tab highlighting, Search, Messages, Profile icons, and a prominent center **`+`** create button. |

---

## 🔄 User Navigation Flow

```text
                     ┌────────────────────────┐
                     │     Splash Screen      │
                     └───────────┬────────────┘
                                 │
                   ┌─────────────┴─────────────┐
                   ▼                           ▼
       ┌───────────────────────┐   ┌───────────────────────┐
       │ Create Account Screen │ ◄─┤    Sign In Screen     │
       └───────────┬───────────┘   └───────────┬───────────┘
                   │                           │
                   └─────────────┬─────────────┘
                                 ▼
                     ┌────────────────────────┐
                     │    Home Feed Screen    │
                     │  (For You / Discover)  │
                     └────────────────────────┘
```

---

## 🏗️ Architecture & Technology Stack

### Mobile Client (Flutter)
- **Framework:** Flutter SDK (`^3.13.5`) / Dart
- **State Management:** `flutter_bloc` (`Cubit` & `Bloc` pattern)
- **Design System:** Custom Dark Glassmorphism with Material 3 Cupertino-inspired icons and purple gradient accents (`#9044FB` to `#C057FF` on dark `#090A17` background).
- **Responsive Layouts:** Dynamic screen width/height scaling using `MediaQuery` and `LayoutBuilder` builders ensuring responsive rendering across various device viewports.

### Backend Services (Node.js / TypeScript)
- **Runtime & Language:** Node.js with TypeScript
- **Modular Domain Design:** Divided into domain modules under `backend/src/modules/` (`auth`, `moments`, `invitations`, `users`, `notifications`, `replies`, `moderation`).
- **Database:** PostgreSQL 16 (versioned migrations under `backend/migrations/`)
- **Media Storage:** Private Object Storage (S3-compatible) with temporary, expiring signed URLs.
- **Containerization:** Docker Compose setup for local database infrastructure (`backend/compose.yaml`).

---

## 📁 Repository Directory Structure

```text
Vera/
├── assets/
│   └── images/                       # App asset images (Apple/Google logos & splash background)
├── lib/                              # Flutter application source code
│   ├── main.dart                     # App root entrypoint & theme configuration
│   └── features/
│       ├── account/                  # Auth & Account domain & presentation
│       │   ├── domain/entities/      # AccountDraft model entity
│       │   └── presentation/pages/   # create_account_screen.dart & sign_in_screen.dart
│       ├── home/                     # Home Feed & Moments domain & presentation
│       │   ├── domain/entities/      # Moment model entity
│       │   └── presentation/
│       │       ├── pages/            # home_screen.dart
│       │       └── widgets/          # moment_card.dart & bottom_nav_bar.dart
│       └── splash/                   # Splash Screen feature
│           └── presentation/pages/   # splash_screen.dart
├── backend/                          # Node.js/TypeScript backend service
│   ├── compose.yaml                  # Local PostgreSQL 16 Docker Compose configuration
│   ├── .env.example                  # Environment variable configuration template
│   ├── docs/                         # Backend conventions & API documentation
│   ├── migrations/                   # PostgreSQL versioned migrations
│   ├── src/
│   │   ├── config/                   # Backend configuration setup
│   │   ├── middleware/               # Auth & validation middleware
│   │   ├── modules/                  # Domain modules (auth, moments, users, etc.)
│   │   └── shared/                   # Shared backend utilities
│   └── tests/                        # Backend integration and unit tests
├── docs/                             # Architecture, DevOps & decision documentation
│   ├── architecture.md               # System boundaries & security rules
│   ├── decisions.md                  # Kickoff decision log
│   ├── devops-handoff.md             # DevOps deployment & operations guide
│   └── setup-checklist.md            # Setup & configuration checklist
├── infra/                            # Deployment & infrastructure configurations
└── pubspec.yaml                      # Flutter project dependencies & asset manifest
```

---

## 🔒 Security & Privacy Boundaries

1. **Server-Side Authorization Authority:**
   - Client applications or URLs are never treated as security boundaries.
   - Every private moment request must be authenticated, authorized, and verified against server-side date/location rules using server UTC time.

2. **Private Content Protection:**
   - Locked moment previews never expose private media, body content, or recipient details.
   - Original media is stored in private storage buckets and delivered strictly via temporary expiring signed URLs post-authorization.

3. **Zero Secrets in Source Code:**
   - No database credentials, API keys, or private certificates are stored in repository files or client binaries.

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>=3.13.5`)
- [Dart SDK](https://dart.dev/get-dart)
- [Docker & Docker Desktop](https://www.docker.com/) (for backend database environment)

---

### 📲 Running the Mobile App

1. **Clone the repository:**
   ```bash
   git clone https://github.com/YourUsername/Vera.git
   cd Vera
   ```

2. **Fetch Flutter packages:**
   ```bash
   flutter pub get
   ```

3. **Run the app on an emulator or device:**
   ```bash
   flutter run
   ```

---

### 🐳 Setting Up Local Backend Environment

1. **Navigate to the backend directory:**
   ```bash
   cd backend
   ```

2. **Configure environment variables:**
   ```bash
   cp .env.example .env
   ```

3. **Start local PostgreSQL database:**
   ```bash
   docker compose up -d postgres
   ```
   *PostgreSQL will run locally on `localhost:5432` (Database: `vera`, User: `vera`).*

---

## 📄 Related Documentation

- [Architecture Foundation](docs/architecture.md)
- [DevOps & Operations Handoff Guide](docs/devops-handoff.md)
- [Backend API Conventions](backend/docs/api-conventions.md)
- [MVP Decisions Log](docs/decisions.md)
- [Stage A Setup Checklist](docs/setup-checklist.md)

---

## 📄 License

This project is proprietary and confidential. All rights reserved.
