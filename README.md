# Flutter Shopping App (Task 04)

> **Internship Assignment:** Anas Technologies / Flutter Internship  
> **Bundle Identifier:** `com.mudasir.shopping_app`  
> **Platforms:** Android & iOS only  
> **Architecture:** Clean Layered Architecture with Provider State Management  
> **Cloud & Backend Services:** Firebase Auth, Cloud Firestore, Vercel Serverless (Node.js + Brevo API for Password Reset)

---

## 📌 Project Overview
A production-grade mobile shopping application featuring:
- **Product Catalog:** Bundled JSON catalog with 12+ items across 3 categories, search, category filtering, and price sorting working simultaneously.
- **Product Details:** Clean modern UI, full description, and Add to Cart action.
- **Persistent Shopping Cart:** Local persistence partitioned by Firebase UID (`cart_${uid}`), 1..10 quantity limits, separate remove action, and account isolation.
- **Accurate Financial Arithmetic:** Stored strictly as **integer paisa** (1 PKR = 100 paisa) and rendered with two decimal places. Subtotal < PKR 5,000 incurs fixed PKR 200 delivery fee; PKR 5,000+ unlocks Free Delivery.
- **Simulated Checkout:** Pakistani 11-digit phone validation (`03XXXXXXXXX`), demo Cash on Delivery notice, and idempotent order submission using stable client order IDs.
- **Firestore Order History:** Server timestamp, item snapshots, newest first ordering, protected by strict security rules (`firestore.rules`).
- **Serverless Password Reset:** Custom Vercel serverless backend integrating Brevo API for transactional email OTPs and Firebase Admin SDK for secure password resets.

---

## 🗂️ Project Structure

```
.
├── docs/                               # Project Documentation (Committed to Git)
│   ├── PRD.md                          # Product Requirements Document
│   ├── ARCHITECTURE.md                 # System & Data Architecture
│   ├── DESIGN.md                       # UI/UX Specifications & Design System
│   ├── AGENTS.md                       # AI Agent Guidelines & Operations Policy
│   └── TASK_TRACKER.md                 # Phased Execution Roadmap
├── shopping_app/                       # Flutter Mobile Application
│   ├── android/                        # Android project (com.mudasir.shopping_app)
│   ├── ios/                            # iOS project (com.mudasir.shopping_app)
│   ├── assets/catalog/products.json    # Bundled product catalog
│   ├── lib/                            # Application source code
│   └── test/                           # Automated unit and widget tests
├── backend/                            # Vercel Serverless Backend
│   ├── api/
│   │   ├── send-reset-otp.js           # Brevo OTP email dispatcher
│   │   └── verify-reset-otp.js         # Firebase Admin password updater
│   ├── lib/                            # Firebase Admin & Brevo client helpers
│   ├── .env.example                    # Backend environment variable template
│   └── vercel.json                     # Vercel serverless configuration
├── firestore.rules                     # Cloud Firestore Security Rules
├── .gitignore                          # Global gitignore (Safeguarding docs/)
└── README.md                           # Main Project README
```

---

## 🚀 Setup & Execution Instructions

### 1. Flutter Mobile App
```bash
cd shopping_app
flutter pub get
flutter run
```

### 2. Backend (Serverless on Local / Vercel)
```bash
cd backend
npm install
cp .env.example .env
# Fill in BREVO_API_KEY, SENDER_EMAIL, and serviceAccountKey.json
npm start
```

---

## 🔒 Security & Secrets Policy
- **Never commit `.env` or service account keys.**
- The `docs/` directory is permanently tracked in version control.
- Client writes strictly enforce data schema and ownership in `firestore.rules`.
