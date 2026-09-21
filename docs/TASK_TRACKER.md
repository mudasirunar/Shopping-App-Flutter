# Task Tracker & Phase Execution Roadmap
## Project: Flutter Shopping App (Task 04)

---

## Progress Overview
| Phase | Title | Status | Completion Date |
| :---: | :--- | :---: | :---: |
| **Phase 1** | Planning, Documentation, Repository Skeletons & Git Baseline | 🟡 In Progress | - |
| **Phase 2** | Core Domain Models, Paisa Math, Phone Validator & Unit Tests | ⚪ Not Started | - |
| **Phase 3** | Product Catalog JSON, Search/Filter/Sort & Product Details Screen | ⚪ Not Started | - |
| **Phase 4** | Shopping Cart State, UID-Keyed Persistence & Delivery Rules | ⚪ Not Started | - |
| **Phase 5** | Authentication, Serverless Backend (Brevo OTP) & Reset Flow | ⚪ Not Started | - |
| **Phase 6** | Simulated Checkout, Idempotent Order Submission & Firestore Rules | ⚪ Not Started | - |
| **Phase 7** | Order History, Confirmation, Edge Case Verification & Polishing | ⚪ Not Started | - |

---

## Detailed Phase Breakdown

### Phase 1: Planning, Documentation, Repository Skeletons & Git Baseline
- [x] Analyze internship PDF requirements (`Task_04_Flutter_Shopping_App.pdf`).
- [x] Create project documentation:
  - [x] `docs/PRD.md`
  - [x] `docs/ARCHITECTURE.md`
  - [x] `docs/DESIGN.md`
  - [x] `docs/AGENTS.md`
  - [x] `docs/TASK_TRACKER.md`
- [ ] Create repository `.gitignore` (safeguarding docs, ignoring flutter build artifacts, APKs, `.env`, credentials).
- [ ] Initialize clean Flutter project (`shopping_app/`) for Android & iOS only with bundle ID `com.mudasir.shopping_app`.
- [ ] Configure Flutter application display names and verify build settings.
- [ ] Initialize `backend/` skeleton with Vercel serverless function structure and `.env.example`.
- [ ] Review initial git status and request user permission to commit and push initial baseline.

### Phase 2: Core Domain Models, Paisa Math, Phone Validator & Unit Tests
- [ ] Define immutable models:
  - [ ] `Product` (`id`, `name`, `description`, `category`, `image`, `pricePaisa`)
  - [ ] `CartItem` (`product`, `quantity` clamped between 1 and 10)
  - [ ] `DeliveryInfo` (`fullName`, `phone`, `streetAddress`, `city`)
  - [ ] `Order` & `OrderSnapshotItem`
- [ ] Build utility helpers:
  - [ ] `CurrencyFormatter` for integer paisa to `PKR X,XXX.XX` representation
  - [ ] `PhoneValidator` for Pakistani 11-digit `^03\d{9}$` format
  - [ ] Cart total calculation engine (subtotal, PKR 200 delivery under 5,000, free delivery at 5,000+)
- [ ] Implement automated unit tests:
  - [ ] `currency_test.dart`
  - [ ] `cart_calculation_test.dart` (including test fixture: PKR 1,000 + PKR 1,500 = Subtotal 3,500, Delivery 200, Total 3,700; PKR 5,000 = Free delivery)
  - [ ] `phone_validator_test.dart`
- [ ] Run `flutter test` to ensure all mathematical and validation rules pass.

### Phase 3: Product Catalog JSON, Search/Filter/Sort & Product Details Screen
- [ ] Create bundled `assets/catalog/products.json` with 12+ items across 3 categories (Electronics, Fashion, Home).
- [ ] Add clean product image assets and fallback icon handling.
- [ ] Implement `CatalogService` and `CatalogProvider`.
- [ ] Build `ProductCatalogScreen`:
  - [ ] Sticky/Integrated Search Bar with instant filtering
  - [ ] Horizontal Category Filter pills (All, Electronics, Fashion, Home)
  - [ ] Sorting selector (Price: Low to High, Price: High to Low, Default)
  - [ ] 2-column responsive product card grid
  - [ ] Empty state with reset filters button
  - [ ] Cart badge icon in AppBar with total items count
- [ ] Build `ProductDetailsScreen`:
  - [ ] High-res image display with fallback
  - [ ] Category tag, title, formatted PKR price, detailed description
  - [ ] Bottom action bar with "Add to Cart" and feedback snackbar

### Phase 4: Shopping Cart State, UID-Keyed Persistence & Delivery Rules
- [ ] Implement `CartStorageService` (SharedPreferences partitioned by `cart_${uid}`).
- [ ] Implement `CartProvider`:
  - [ ] Quantity management (1 to 10 limits, increment/decrement)
  - [ ] Explicit removal action (trash icon at 1)
  - [ ] Dynamic subtotal, delivery fee calculation, and grand total
  - [ ] Free delivery threshold indicator / progress bar
  - [ ] Multi-account isolation: listener on auth changes to switch/clear cart cache
- [ ] Build `CartScreen`:
  - [ ] Cart item rows with stepper controls
  - [ ] Free delivery unlocked / progress banner
  - [ ] Order summary breakdown card
  - [ ] "Proceed to Checkout" button (disabled if empty)
  - [ ] Empty cart state with "Start Shopping" button

### Phase 5: Authentication, Serverless Backend (Brevo OTP) & Reset Flow
- [ ] Set up Firebase Auth client integration in Flutter (`AuthService`, `AuthProvider`).
- [ ] Build `backend/` serverless endpoints:
  - [ ] `/api/send-reset-otp.js` using Brevo API
  - [ ] `/api/verify-reset-otp.js` using Firebase Admin SDK
  - [ ] `.env.example` documenting Brevo credentials and Firebase Admin setup
- [ ] Build Flutter Auth screens:
  - [ ] Login screen (email, password validation, link to sign-up & forgot password)
  - [ ] Sign Up screen (enforcing minimum 8-character password validation)
  - [ ] Forgot Password screen (trigger Brevo OTP email)
  - [ ] OTP Verification & Password Reset screen (enforcing minimum 8-character new password)
- [ ] Implement route guards: prevent unauthenticated access to checkout and order history.
- [ ] Implement sign-out: verify all visible user data and active cart are completely cleared.

### Phase 6: Simulated Checkout, Idempotent Order Submission & Firestore Rules
- [ ] Build `CheckoutScreen`:
  - [ ] Notice banner: "Demo Checkout — Cash on Delivery only"
  - [ ] Delivery form: Full Name, Phone (`03XXXXXXXXX`), Street Address, City
  - [ ] Read-only order summary breakdown
  - [ ] SingleChildScrollView with keyboard avoidance
- [ ] Implement idempotent order submission in `OrderProvider` / `FirestoreService`:
  - [ ] Generate stable UUID `orderId` per attempt
  - [ ] Prevent duplicate taps (loading state & disabled button)
  - [ ] Write document to `users/{uid}/orders/{orderId}` with server timestamp
  - [ ] Ensure Firestore write succeeds BEFORE clearing cart or navigating
  - [ ] Network failure recovery: preserve cart and retain `orderId` for retry
- [ ] Define and verify `firestore.rules` for owner-only create/read, client update/delete denied.

### Phase 7: Order History, Confirmation, Edge Case Verification & Polishing
- [ ] Build `OrderConfirmationScreen` showing order ID, items, delivery details, and timestamp.
- [ ] Build `OrderHistoryScreen` with orders sorted newest first, showing snapshot items.
- [ ] Test edge cases:
  - [ ] Empty cart behavior
  - [ ] Restart app to verify cart restoration
  - [ ] Account A -> Account B switching (verify cart & order history isolation)
  - [ ] Network disconnect retry test (verify duplicate order prevention)
  - [ ] Small-screen keyboard overflow verification
- [ ] Configure Android and iOS release settings (bundle ID, app name, permissions, ProGuard).
- [ ] Generate comprehensive `README.md` with setup instructions and submission details.
