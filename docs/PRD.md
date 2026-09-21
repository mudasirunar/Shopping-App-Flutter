# Product Requirements Document (PRD)
## Project: Flutter Shopping App (Task 04)
**Organization:** Anas Technologies / Flutter Internship  
**Package / Bundle ID:** `com.mudasir.shopping_app`  
**Platforms:** Android, iOS  
**State Management:** Provider  
**Backend & Cloud Services:** Firebase Auth, Cloud Firestore, Vercel Serverless (Node.js + Brevo API for Password Reset)

---

## 1. Executive Summary & Objectives
The goal is to build a production-grade, highly polished Flutter shopping application for Android and iOS featuring a bundled product catalog, persistent multi-user cart, reliable simulated checkout, personal order history backed by Firebase Firestore, and an isolated serverless backend for secure password reset emails via Brevo.

The app reuses core authentication principles while placing strong emphasis on robust state management, account isolation, tamper-proof monetary calculations using integer paisa, and rock-solid Firestore security rules.

---

## 2. Target Users & Personas
- **E-Commerce Shoppers (Mobile Users):** Browse products, filter and sort by price, view specifications, adjust cart quantities, place Cash on Delivery orders, and review past order history.
- **Demo / Internship Reviewers:** Evaluators testing cart persistence across app restarts, account isolation between multiple accounts, idempotency of order submission, Firestore security rule enforcement, edge-case validations, and code architecture.

---

## 3. Core Functional Requirements

### 3.1 Authentication & Account Management
- **Email & Password Authentication:**
  - Secure sign up with email and password (passwords must be at least 8 characters long).
  - Sign in with credential validation.
  - Profile state awareness (logged-in vs guest / unauthenticated).
  - Sign out: Must immediately clear all in-memory user data, cart state, and navigation state.
- **Custom Password Reset Service (Serverless Backend):**
  - Dedicated serverless backend deployed on Vercel (`/backend`).
  - Integrates Brevo (formerly Sendinblue) API to dispatch transactional reset OTP / links to the user's email.
  - Integrates Firebase Admin SDK to securely verify and complete password resets without exposing secret service keys to mobile clients.
  - `.env` protection for Brevo API key, sender email, and Firebase service account credentials.

### 3.2 Product Catalog
- **Bundled Product Catalog:**
  - Bundled local JSON asset containing at least 12 realistic sample products across 3 distinct categories (e.g., Electronics, Fashion / Apparel, Home & Living).
  - Each item schema:
    - `id` (String, unique)
    - `name` (String)
    - `description` (String)
    - `category` (String)
    - `image` (Asset path / URL with graceful local fallback)
    - `pricePaisa` (Integer, monetary representation where 1 PKR = 100 paisa)
- **Search, Filter & Sort Working Together:**
  - Full-text search matching product titles/names (case-insensitive, trimmed).
  - Category selector (All + individual categories).
  - Price sorting (Low to High, High to Low, Default/Featured).
  - Combined query state: Search + filter + sort operate simultaneously.
  - Clear empty/no-results state with quick reset action.
  - Fallback placeholder for missing or broken images.

### 3.3 Product Details
- Hero product image with placeholder and error handling.
- Category tag, product name, and formatted PKR price (calculated from paisa).
- Detailed description.
- Prominent "Add to Cart" action with immediate visual feedback (e.g., snackbar / sheet) showing current quantity in cart.

### 3.4 Persistent Shopping Cart
- **Behavior & Limits:**
  - Adding an existing product increases quantity (no duplicate rows).
  - Allowed quantity per item: **1 to 10**.
  - Increment (+) disabled or capped at 10; decrement (-) reduces quantity until 1, with a separate explicit "Remove" action or prompt.
- **Multi-User Local Persistence:**
  - Cart data is persisted locally (using SharedPreferences / secure storage) keyed uniquely by the user's Firebase UID (`cart_<uid>`).
  - Automatically restored upon app restart for the logged-in user.
  - Account switching (User A -> User B) completely swaps carts; User B never sees User A's items.
  - Guest/unauthenticated cart handling: Checkout and order history strictly require authentication.
- **Monetary Calculations:**
  - **Integer Paisa Rule:** All prices, subtotals, delivery fees, and grand totals are calculated and stored internally as integer paisa (preventing floating point inaccuracies).
  - Subtotal = $\sum (\text{pricePaisa} \times \text{quantity})$.
  - Delivery Fee:
    - Empty cart: PKR 0 (0 paisa).
    - Subtotal < PKR 5,000 (500,000 paisa): **Fixed PKR 200 (20,000 paisa)**.
    - Subtotal $\ge$ PKR 5,000 (500,000 paisa): **Free Delivery (PKR 0)**.
  - Grand Total = Subtotal + Delivery Fee (No tax or discounts required).
  - Display format: Formatted as PKR with 2 decimal places (e.g., `PKR 1,250.00`, `PKR 5,000.00`).

### 3.5 Checkout & Order Placement
- **Form Fields & Validations:**
  - Full Name: Required, trimmed, minimum 3 characters.
  - Mobile Number: Required, trimmed, validated against Pakistani local 11-digit mobile format starting with `03` (regex: `^03\d{9}$`). Clear helper text explaining the format (e.g., `03001234567`).
  - Street Address: Required, trimmed.
  - City: Required, trimmed.
- **Demo Mode Notice:**
  - Clearly labeled as "Demo / Simulated Checkout".
  - Payment method explicitly marked as "Cash on Delivery (Simulated)". No real bank or card processing.
- **Reliability & Idempotency:**
  - Empty cart disables checkout navigation and submission.
  - Submit button shows loading spinner and is disabled during write operations.
  - Generates a **stable Client Order ID** (UUID v4) for each checkout attempt; repeated taps or retry after a network error reuses the same order ID to avoid duplicate orders in Firestore.
  - Order must be confirmed written to Firestore **before** showing the confirmation screen or clearing the local cart.
  - If the write fails or network interrupts, the cart remains intact and an actionable retry error is shown.

### 3.6 Order History & Confirmation
- **Data Path:** `users/{uid}/orders/{orderId}`.
- **Document Payload:**
  - `orderId`: String
  - `items`: Array of snapshot maps:
    - `productId`, `name`, `unitPricePaisa`, `quantity`, `subtotalPaisa`, `image`
  - `deliveryInfo`: Map of `fullName`, `phone`, `streetAddress`, `city`
  - `subtotalPaisa`: Integer
  - `deliveryPaisa`: Integer
  - `totalPaisa`: Integer
  - `status`: String (`placed`)
  - `createdAt`: Firestore ServerTimestamp (`FieldValue.serverTimestamp()`)
- **Ordering:**
  - Order history sorted newest first (`orderBy('createdAt', descending: true)`).
  - Snapshot integrity: Past orders display items as purchased, immune to catalog updates or price changes.

---

## 4. Firestore Security Rules Specifications
Firestore rules must be included in the repository at `firestore.rules`.
- `match /users/{userId}/orders/{orderId}`:
  - `allow create`: If `request.auth != null && request.auth.uid == userId` and schema fields match requirements.
  - `allow read`: If `request.auth != null && request.auth.uid == userId`.
  - `allow update, delete`: `false` (clients are strictly denied modifying or deleting past orders).

---

## 5. Non-Functional Requirements
- **Performance:** Instant catalog loading, 60fps scrolling, efficient Provider state notifications.
- **UI/UX:** Minimal, clean, modern, zero AI-gimmick gradients or excessive blur. Proper empty states, loading skeletons, error states with retry, and keyboard-safe layouts (`SingleChildScrollView`).
- **Platforms:** Android and iOS only. Release builds must build cleanly with correct ProGuard / multidex / signing configurations.
- **Code Quality:** Strong typing, lint compliance with `flutter_lints`, comprehensive unit tests for cart calculations, and modular directory separation.

---

## 6. Evaluation Criteria & Scoring Mapping
1. **Catalog, search, filters and navigation (15 pts):** Bundled 12+ items, 3 categories, search + filter + sort combination, fallback images.
2. **Cart behavior, persistence and calculations (25 pts):** 1..10 quantity bounds, uid-keyed local persistence, integer paisa arithmetic, PKR 200 delivery under 5,000 PKR, free at 5,000+ PKR.
3. **Checkout reliability and order history (25 pts):** Pakistani phone validation (`^03\d{9}$`), idempotent order submission, Firestore write-before-clear, order snapshots, newest first.
4. **Access rules and account isolation (15 pts):** Multi-user cart isolation, `firestore.rules` owner read/create only, client update/delete denied.
5. **UI, validation and code quality (10 pts):** Clean architecture, no keyboard overflow, robust error handling, minimal design.
6. **Documentation and demonstration (10 pts):** PRD, ARCHITECTURE, DESIGN, AGENTS, TASK_TRACKER, README, reproducible test fixtures.
