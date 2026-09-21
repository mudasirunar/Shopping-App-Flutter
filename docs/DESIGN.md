# UI/UX Design System Specification
## Project: Flutter Shopping App (Task 04)

---

## 1. Design Principles & Anti-Patterns

### 1.1 Core Principles
- **Clarity Over Decoration:** Clean whitespace, precise typography, and unambiguous affordances. Every UI element exists to serve customer browsing, cart management, or checkout clarity.
- **Predictable & Usable:** Follow standard e-commerce mobile conventions (bottom navigation / app bar cart badge, intuitive stepper controls, instant feedback upon adding to cart).
- **Graceful States:** Every view must purposefully handle **Loading**, **Empty**, **Error/Retry**, and **Success** states without awkward layout shifts.
- **Keyboard & Screen Resilient:** Zero render overflow errors on small screens; all forms must wrap in keyboard-aware scroll views with appropriate bottom padding.

### 1.2 Anti-Patterns (Strictly Prohibited)
- ❌ **No AI-style neon gradients** (e.g. purple-to-cyan rainbow fills).
- ❌ **No excessive glassmorphism** or heavy backdrop blurs that degrade readability.
- ❌ **No heavy diffuse shadows or intense neon glows**.
- ❌ **No pointless floating shapes or distracting ornamental badges**.

---

## 2. Color Palette & Semantic Tokens

| Token Name | Hex Code | Purpose / Usage |
| :--- | :--- | :--- |
| `primary` | `#0F172A` (Slate 900) | Primary brand color, headers, primary buttons |
| `primaryContainer` | `#F1F5F9` (Slate 100) | Secondary surface fills, badge backgrounds |
| `accent` | `#059669` (Emerald 600)| Free delivery indicators, success checkmarks |
| `accentSurface` | `#ECFDF5` (Emerald 50) | Free delivery progress bar, positive banner background |
| `background` | `#F8FAFC` (Slate 50)  | Scaffold background |
| `surface` | `#FFFFFF` (Pure White)| Product cards, sheets, bottom navigation |
| `borderSubtle` | `#E2E8F0` (Slate 200)| Dividers, card borders, inactive inputs |
| `borderFocus` | `#0F172A` (Slate 900) | Focused text fields |
| `textPrimary` | `#0F172A` (Slate 900) | High-emphasis body text and headings |
| `textSecondary`| `#475569` (Slate 600) | Metadata, categories, secondary labels |
| `textMuted` | `#94A3B8` (Slate 400) | Placeholders, disabled actions |
| `error` | `#DC2626` (Red 600)   | Validation errors, failed writes, out-of-stock |
| `errorSurface` | `#FEF2F2` (Red 50)    | Error banners and alert backgrounds |
| `demoNotice` | `#F59E0B` (Amber 500) | Subtle demo / simulated checkout alert badge |

---

## 3. Typography Hierarchy

Using modern system sans-serif (Inter / Roboto typography standards):

- **Display / H1:** 24sp, SemiBold (FontWeight.w600), LetterSpacing: -0.5px. Used for main screen headings (Catalog, Checkout, Order History).
- **Headline / H2:** 18sp, SemiBold (FontWeight.w600). Used for section titles, modal headers.
- **Title / H3:** 16sp, Medium (FontWeight.w500). Used for product titles in cards, summary row titles.
- **Body Regular:** 14sp, Regular (FontWeight.w400), Height: 1.4. Used for product descriptions, form inputs.
- **Body Strong:** 14sp, SemiBold (FontWeight.w600). Used for prices and key metrics.
- **Caption / Label:** 12sp, Medium (FontWeight.w500). Used for category chips, badge tags, form helper text.
- **Paisa Price Format:** Always display currency as `PKR X,XXX.XX` (e.g. `PKR 1,500.00`) with consistent tabular numerals.

---

## 4. Spacing, Elevation & Corner Radii

### 4.1 Spacing Scale
- `space-4`: 4px (tight grouping, badge padding)
- `space-8`: 8px (icon-to-text spacing, chip padding)
- `space-12`: 12px (card inner element padding)
- `space-16`: 16px (standard screen margin, card padding)
- `space-24`: 24px (section breaks, form row separation)
- `space-32`: 32px (major layout blocks)

### 4.2 Border Radius
- `radius-sm`: 6px (chips, small badges)
- `radius-md`: 10px (buttons, input fields)
- `radius-lg`: 16px (product cards, modal sheets)

### 4.3 Elevation & Shadows
- Use subtle, single-step shadows for physical separation:
  - Cards: `BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))`
  - App bar / Bottom bar: Subtle border bottom/top `#E2E8F0` rather than heavy shadow.

---

## 5. Screen Layout & Component Specifications

### 5.1 Product Catalog Screen
- **App Bar:**
  - Search bar integrated into the header with instant clear button.
  - Cart icon with reactive badge count showing total quantity.
- **Category Filter Bar:**
  - Horizontal scrolling row of clean pills: `All`, `Electronics`, `Fashion`, `Home & Living`.
  - Selected state: Filled `#0F172A`, white text. Unselected: Border `#E2E8F0`, dark text.
- **Sort & Result Bar:**
  - Shows result count ("Showing 12 items") and a dropdown filter for sorting ("Price: Low to High", "Price: High to Low", "Featured").
- **Product Grid:**
  - 2-column responsive grid with aspect ratio ~ 0.72.
  - Card contains:
    - Product image with subtle rounded corners and fallback icon if asset missing.
    - Category tag in muted caption.
    - Product name (max 2 lines, overflow ellipsis).
    - Price in bold (`PKR 2,499.00`).
    - Quick "Add" icon button or quantity badge if already in cart.
- **Empty State:**
  - Clean illustration / icon, heading "No products found", description "Try adjusting your search or category filter", and "Reset Filters" action button.

### 5.2 Product Details Screen
- Large hero image preview.
- Category tag pill.
- Title and bold price display.
- Scrollable detailed description with high line-height readability.
- Sticky bottom action bar containing:
  - Quantity selector (1 to 10) if already in cart, or prominent "Add to Cart" button with price subtotal.

### 5.3 Shopping Cart Screen
- **Item Row:**
  - Thumbnail image, product name, single unit price.
  - Stepper widget: `[-]` Button, Quantity Text (1..10), `[+]` Button.
  - Decrementing from 1 triggers a confirmation or displays a red trash icon `[🗑️]` to clearly delete the row.
  - Line total formatted accurately.
- **Order Calculations Card:**
  - Free delivery threshold progress bar:
    - If subtotal < PKR 5,000: Shows "Add PKR X more for Free Delivery!" with a clean progress bar.
    - If subtotal >= PKR 5,000: Shows green checkmark "You unlocked Free Delivery!".
  - Breakdown table:
    - Subtotal: `PKR X,XXX.XX`
    - Delivery Fee: `PKR 200.00` or `FREE` (in Emerald green)
    - Total: `PKR X,XXX.XX` (in prominent bold)
- **Checkout Action:**
  - Prominent "Proceed to Checkout" button. Disabled if cart is empty.

### 5.4 Checkout Screen
- **Demo Mode Banner:**
  - Top alert banner: "ℹ️ Demo Checkout — No real payment or shipment will take place. Orders are placed as simulated Cash on Delivery."
- **Shipping Information Form:**
  - Full Name (required, trimmed).
  - Mobile Number:
    - Prefix display or helper text: "Format: 03XXXXXXXXX (11 digits)".
    - Inline regex validation with real-time error message if digits don't match `^03\d{9}$`.
  - Street Address (required, trimmed, multiline).
  - City (required, trimmed).
- **Payment Method Selection:**
  - Pre-selected and locked to: "Cash on Delivery (Simulated Demo)".
- **Order Summary Card:**
  - Items summary preview, subtotal, delivery fee, grand total.
- **Submit Button:**
  - "Place Order (Demo COD)" with loading indicator state and disabled tap during submission.

### 5.5 Order History & Confirmation Screens
- **Order Confirmation:**
  - Success checkmark icon.
  - Display assigned Order ID (e.g., `#ORD-8F21A3`).
  - Summary of placed items, delivery details, and timestamp.
  - Buttons: "View Order History", "Continue Shopping".
- **Order History:**
  - List of past orders ordered newest first.
  - Card shows Order ID, formatted date/time, status badge (`Placed`), snapshot item count, and Grand Total.
  - Expandable / tap to view full snapshot details with item prices and delivery address.
  - Empty state: "No orders yet" with "Start Shopping" button.
