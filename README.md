# Shopping App — Flutter & Firebase E-Commerce Application

A production-grade mobile shopping application for Android and iOS built with Flutter, Provider state management, Firebase Cloud Firestore, and a serverless backend for transactional email verification.

---

## 📌 Features Overview

- **Bundled Product Catalog**: Bundled local catalog containing 50 products across 5 distinct categories (Electronics, Fashion, Home & Living, Books & Stationery, Health & Fitness) with high-resolution CDN images and fallback handling.
- **Unified Discovery Engine**: Real-time title search, category filtering chips, and price sorting (Featured, Price: Low to High, Price: High to Low) operating in unison with clean empty states.
- **Dynamic Responsive Grid**: Automatically detects screen layout and row densities; single-product rows expand into wide horizontal cards showcasing descriptions and badges without empty space.
- **Product Details**: Image carousel/hero display, stock availability, category tags, specs breakdown, assurance badges, quantity adjustment, and floating Add-to-Cart bar.
- **Persistent Shopping Cart**: Multi-user local persistence partitioned by user identity (`cart_<uid>` and `cart_guest`), 1 to 10 quantity clamping, and explicit item removal.
- **Wishlist Management**: Local & cloud-synced wishlist with instant toggle, item count badges, profile integration, and custom exploration shortcuts.
- **Address Book Management**: Multi-address management strictly enforcing a 3-address cap with default selection and inline edit/delete dialogs.
- **Simulated Checkout**: Local 11-digit Pakistan mobile number validation (`03XXXXXXXXX`) with live feedback, address selector, Cash on Delivery option, and demo disclaimers.
- **Reliable & Idempotent Order Submission**: Stable client UUID generation preventing duplicate orders during retries or rapid taps, and a strict write-before-clear rule ensuring orders are committed to Firestore before the cart is emptied.
- **Firestore Order History**: Document storage under `users/{uid}/orders/{orderId}` with immutable item snapshots, delivery details, server timestamps, and newest-first ordering.
- **Universal Confirmation Dialog**: Standardized modal (`AppConfirmationDialog`) featuring centered icons, clear messaging, and contextual destructive/primary actions.
- **Snappy SnackBar Engine**: Unified feedback utility (`AppSnackBar`) featuring instant queue clearing (`clearSnackBars()`), 1.6s auto-dismissal for quick alerts, 3.2s auto-dismissal for action snackbars, and safe gesture arena handling.
- **Serverless Password Reset**: Vercel serverless backend integrating Brevo API for 6-digit email OTPs and Firebase Admin SDK for privileged password updates.

---

## 🛠️ Environment & Dependencies

### Flutter & Dart SDK
- **Flutter SDK**: `3.47.4` (Channel stable)
- **Dart SDK**: `3.13.3`

### Key Packages
| Package | Version | Purpose |
| :--- | :--- | :--- |
| `provider` | `^6.1.2` | Reactive state management across views |
| `firebase_core` | `^3.12.1` | Core Firebase client initialization |
| `firebase_auth` | `^5.5.1` | Email & password authentication |
| `cloud_firestore` | `^5.6.5` | Cloud order persistence and querying |
| `shared_preferences` | `^2.5.2` | UID-keyed local persistence for cart, wishlist & addresses |
| `uuid` | `^4.5.1` | Idempotent UUID v4 order ID generation |
| `http` | `^1.3.0` | Secure HTTPS communication with serverless backend |
| `intl` | `^0.20.2` | Date formatting and currency formatting |
| `flutter_lints` | `^6.0.0` | Static analysis and code quality standards |

---

## 🗄️ Data Structures & Schemas

### 1. Product Model (`Product`)
```dart
{
  "id": "prod_001",
  "name": "Sony WH-1000XM5 Wireless Headphones",
  "description": "Industry-leading noise cancellation...",
  "category": "Electronics",
  "image": "https://images.unsplash.com/photo-...",
  "pricePaisa": 8999900 // 89,999.00 PKR in integer paisa
}
```

### 2. Cart Item Model (`CartItem`)
```dart
{
  "product": Product,
  "quantity": 2 // Clamped strictly between 1 and 10
}
```

### 3. Firestore Order Document (`users/{uid}/orders/{orderId}`)
```json
{
  "orderId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "items": [
    {
      "productId": "prod_001",
      "name": "Sony WH-1000XM5 Wireless Headphones",
      "unitPricePaisa": 8999900,
      "quantity": 1,
      "subtotalPaisa": 8999900,
      "image": "https://images.unsplash.com/..."
    }
  ],
  "deliveryInfo": {
    "fullName": "Mudasir Unar",
    "phone": "03001234567",
    "streetAddress": "House 123, Street 4",
    "city": "Karachi",
    "province": "Sindh"
  },
  "subtotalPaisa": 8999900,
  "deliveryPaisa": 0,
  "totalPaisa": 8999900,
  "status": "placed",
  "createdAt": "FieldValue.serverTimestamp()"
}
```

---

## 💰 Calculation Rules & Financial Logic

All monetary values are calculated and stored internally as **integer paisa** (where 1 PKR = 100 paisa) to eliminate floating-point arithmetic errors.

1. **Subtotal**:
   $$\text{Subtotal} = \sum (\text{item.pricePaisa} \times \text{item.quantity})$$
2. **Delivery Fee Policy**:
   - **Empty Cart**: PKR 0.00 (0 paisa).
   - **Subtotal < PKR 5,000** (< 500,000 paisa): **Fixed PKR 200.00** (20,000 paisa).
   - **Subtotal $\ge$ PKR 5,000** ($\ge$ 500,000 paisa): **Free Delivery (PKR 0.00)**.
3. **Grand Total**:
   $$\text{Grand Total} = \text{Subtotal} + \text{Delivery Fee}$$
4. **Display Representation**: Formatted with thousands separators and 2 decimal places (e.g., `PKR 3,700.00`).

### Test Fixtures
- **Fixture 1**: 2 x Product A (PKR 1,000 each) + 1 x Product B (PKR 1,500)
  - Subtotal: PKR 3,500.00 (350,000 paisa)
  - Delivery: PKR 200.00 (20,000 paisa)
  - **Grand Total**: **PKR 3,700.00** (370,000 paisa)
- **Fixture 2**: Products totaling exactly PKR 5,000.00 (500,000 paisa)
  - Subtotal: PKR 5,000.00
  - Delivery: PKR 0.00 (**Free**)
  - **Grand Total**: **PKR 5,000.00**

---

## 🔒 Security & Access Rules (`firestore.rules`)

Cloud Firestore is locked down with ownership-based access control:
- **`match /users/{userId}/orders/{orderId}`**:
  - `allow create`: Permitted only if caller is authenticated (`request.auth.uid == userId`) and payload adheres to the required schema.
  - `allow read`: Permitted only to the authenticated owner.
  - `allow update, delete`: **Strictly denied (`false`)**. Once placed, past orders cannot be altered or deleted by clients.
- **Client Handshake Token**: Serverless backend endpoints are shielded by `x-app-security-token` header validation, rejecting automated bot requests.

---

## 🚀 Setup & Execution Instructions

### 1. Prerequisites
- Flutter SDK `3.47.4` or compatible 3.x release installed and added to `PATH`.
- Node.js `18+` (for local serverless testing).

### 2. Flutter Mobile Application Setup
```bash
# Navigate to app directory
cd shopping_app

# Install dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run all unit and widget tests
flutter test

# Launch on connected simulator, emulator, or physical device
flutter run
```

### 3. Firebase Configuration Files
- **Android**: Place `google-services.json` inside `shopping_app/android/app/`.
- **iOS**: Place `GoogleService-Info.plist` inside `shopping_app/ios/Runner/`.

### 4. Serverless Backend Setup (Local & Vercel)
The backend service lives in `/backend` and provides transactional email reset OTP dispatch via Brevo and password updates via Firebase Admin.

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Configure environment variables
cp .env.example .env
# Edit .env and supply your credentials:
# BREVO_API_KEY=...
# SENDER_EMAIL=...
# SENDER_NAME=...
# APP_SECURITY_TOKEN=...
# Place serviceAccountKey.json in the backend/ directory

# Run local development server
npm start
```

---

## ⚠️ Known Limitations & Design Decisions

1. **Client-Calculated Prices**:
   - In this application architecture, catalog pricing and cart totals are computed client-side using immutable integer paisa models.
   - For an enterprise-scale commercial production deployment, price calculation and final billing would be re-validated on a secure server or cloud function before final payment capture to safeguard against client tampering.
2. **Simulated Payment Gateway**:
   - Checkout is intentionally designed for demonstration and simulation purposes using **Cash on Delivery (COD)**. No live payment gateway or banking API is connected.
3. **Cart & Wishlist Guest Fallback**:
   - Guest carts and wishlists are stored locally under `cart_guest` and `wishlist_guest`. Authenticated users receive private isolated keys (`cart_<uid>`, `wishlist_<uid>`).

---

## 🤖 AI Assistance Disclosure

In accordance with transparency best practices, AI tooling was utilized during the development of this project for:
- Initial Stitch AI UI design token definitions and styling guidelines.
- Python automation scripts for catalog expansion and high-resolution CDN metadata aggregation.
- Writing comprehensive unit and widget tests for edge cases (cart limit clamping, phone validator regex, and SnackBar gesture arena lifecycle).
