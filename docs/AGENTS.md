# AGENTS.md — Operational Guidelines for AI Agents
## Project: Flutter Shopping App (Task 04)

---

## 1. Primary Directives & Rules of Engagement

### 1.1 Git Operations Policy (STRICT)
- ⚠️ **DO NOT execute important Git commands without explicit user permission.**
- Prohibited automated commands:
  - `git commit`
  - `git push`
  - `git pull`
  - `git branch` / `git checkout` / `git switch`
  - `git merge` / `git rebase`
  - `git reset` / `git revert`
- **Workflow:** Whenever changes are ready for Git staging/committing/pushing:
  1. Inspect status with read-only commands (`git status`, `git diff`).
  2. Explain the pending commit message and branch target to the user.
  3. **Stop and ask for user permission before running the actual commit/push command.**

### 1.2 Documentation Integrity
- The `docs/` folder MUST always be tracked in Git. **Never add `docs/` to `.gitignore`.**
- Always consult and update `docs/TASK_TRACKER.md` as work progresses across phases.
- Do not perform undocumented ad-hoc changes. Keep `docs/PRD.md`, `docs/ARCHITECTURE.md`, and `docs/DESIGN.md` in sync if technical decisions evolve.

### 1.3 Target Platforms & Identifier Requirements
- **Platforms:** Android and iOS ONLY. Do not initialize or add web, macos, windows, or linux platforms unless explicitly commanded by the user.
- **Package / Bundle ID:** MUST adhere to `com.mudasir.<appname>` (e.g., `com.mudasir.shopping_app`).
- Ensure `android/app/build.gradle` (or `build.gradle.kts`) and iOS `project.pbxproj` match this bundle identifier.

---

## 2. Code Quality & Architectural Standards

### 2.1 Separation of Concerns
- **UI (`views/`, `widgets/`):** Pure presentation. Must never execute network requests, direct database reads, or business calculations.
- **State (`providers/`):** Encapsulates screen state, user interactions, and reactive bindings using `ChangeNotifier`.
- **Services (`services/`):** Isolated modules interfacing with Firebase Auth, Cloud Firestore, SharedPreferences, and the Backend API.
- **Models (`models/`):** Pure immutable data structures with type-safe `fromJson` and `toJson`.

### 2.2 Financial Calculation Rules
- Every monetary value MUST be represented internally as an **integer paisa** (1 PKR = 100 paisa).
- Never use Dart `double` for currency math to avoid rounding artifacts.
- Currency formatting must be centralized in a dedicated utility (`CurrencyFormatter.formatPaisa(int paisa)` -> `"PKR 1,500.00"`).
- Free delivery threshold:
  - $\text{subtotalPaisa} \ge 500{,}000$ (PKR 5,000) $\implies \text{deliveryFee} = 0$.
  - $\text{subtotalPaisa} < 500{,}000 \implies \text{deliveryFee} = 20{,}000$ (PKR 200).
  - Empty cart $\implies \text{subtotal} = 0, \text{delivery} = 0, \text{total} = 0$.

### 2.3 Form & Input Validation
- All string inputs in forms must be trimmed before validation.
- Passwords must be at least 8 characters long for all authentication, registration, and reset flows.
- Pakistani mobile numbers must strictly match `^03\d{9}$` (11 digits starting with `03`). Helpful validation messages must guide the user on the expected format.

### 2.4 Cart Persistence & Multi-Account Isolation
- Cart data must be persisted locally in `SharedPreferences` partitioned by Firebase UID (`cart_${uid}`).
- When a user logs in, load `cart_${uid}`.
- When a user logs out, clear in-memory state immediately so subsequent users never see lingering data.
- Restore cart on application cold-start if a user session is active.

### 2.5 Order Idempotency & Error Handling
- Each checkout submission generates a unique UUID `orderId`.
- On failed network transmission or Firestore timeout, **retain the same `orderId`** on retry to prevent duplicate order generation in Firestore.
- Write to Firestore MUST succeed before the local cart is cleared or the order confirmation screen is displayed.
- On error, preserve the cart items and display a clear, non-blocking retry banner.

### 2.6 Serverless Backend & Environment Secrets
- Secrets (`BREVO_API_KEY`, Firebase Service Account JSON, admin tokens) MUST NEVER be committed to Git or embedded in the Flutter client code.
- Place secrets exclusively in `backend/.env` (which is git-ignored) and document them in `backend/.env.example`.

---

## 3. UI/UX Rules
- **No AI cliches:** No excessive neon gradients, no heavy glassmorphism, no neon glows.
- Clean typography and spacing (using `docs/DESIGN.md`).
- Implement proper **loading**, **empty**, **error**, and **retry** states for all async views.
- Ensure all screens with form inputs wrap in `SingleChildScrollView` to prevent keyboard overflow issues.
