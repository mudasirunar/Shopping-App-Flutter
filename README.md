# Shopping App

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
├── .gitignore                          # Global gitignore
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
- Client writes strictly enforce data schema and ownership in `firestore.rules`.
