# FashionConnect — Functional & RESTful API Specification
### Business Analysis Deliverable — Role Breakdown, Endpoint Design, and Feature Roadmap

*Prepared as a bridge document between the business-logic README and technical architecture. Base API path assumed: `/api/v1`. Auth assumed via Bearer token (JWT) with role-based scopes; every endpoint below inherits an implicit `Authorization` requirement unless marked **Public**.*

---

## 0. How to Read This Document

For each role you'll find three layers:
1. **Business Function** — what the capability does and why it exists (the "job to be done").
2. **Functional Breakdown Table** — the discrete features under that function, with business rules.
3. **RESTful API Design** — resource-oriented endpoints (Method, Route, Purpose, Request/Response notes, Business Rule).

This mirrors how a BA would hand off a requirements spec to engineering: functionality first (the *what/why*), API contract second (the *how it's exposed*).

---

## 1. Cross-Cutting Resources (Shared by All Roles)

These aren't role-specific but every role depends on them, so they're defined once.

| Resource | Method | Route | Purpose |
|---|---|---|---|
| Auth | POST | `/auth/register` | Register account (role determined by payload: user/brand/delivery-company/courier) |
| Auth | POST | `/auth/login` | Email or phone + password login, returns JWT |
| Auth | POST | `/auth/otp/send` | Send SMS OTP (primary verification method — see Section 7) |
| Auth | POST | `/auth/otp/verify` | Verify OTP, activates account/completes checkout auth |
| Auth | POST | `/auth/refresh` | Refresh access token |
| Auth | POST | `/auth/logout` | Invalidate refresh token |
| Chat | GET/POST | `/chats/{threadId}/messages` | Unified chat thread (user↔brand, used across roles) |
| Chat | POST | `/chats/{threadId}/report` | Flag abusive message → feeds Admin moderation queue |
| Notifications | GET | `/notifications` | List notifications for the authenticated identity (any role) |
| Notifications | PATCH | `/notifications/{id}/read` | Mark as read |
| Payments | POST | `/payments/intents` | Create a payment intent (Stripe/Paymob router decides gateway) |
| Payments | POST | `/payments/webhooks/stripe` | Stripe async payment confirmation |
| Payments | POST | `/payments/webhooks/paymob` | Paymob async payment confirmation (cards, wallets, Fawry) |
| Files | POST | `/uploads` | Generic signed-upload endpoint (product photos, KYC docs, proof-of-delivery photos) |

**Business rule:** Chat is a single underlying resource (`threadId`) reused by End-User↔Brand conversations rather than separate endpoints per role — this keeps moderation and reporting centralized for Admin (Section 2).

---

## 2. Admin

### 2.1 Business Function
The Admin role is the **governance and trust layer**. Its job is to ensure nothing revenue-generating (payouts, ad spend) or trust-critical (brand verification, disputes) happens without a checkpoint. Admin is largely a *read + approve/override* role, not a content-creation role.

### 2.2 Functional Breakdown

| Function | Description | Business Rule |
|---|---|---|
| Platform dashboard | Aggregate KPIs: GMV, active brands/users, orders by status, commission revenue, ad revenue, delivery performance | Should be a materialized/cached view, not live-computed on every load (ties to Section 9 data-model note on ranking jobs) |
| Brand lifecycle mgmt | Approve / reject / suspend / re-verify brands | Verification tiers (Pending → Basic → Trusted) drive ranking multipliers and commission — see 3.1 |
| Category taxonomy governance | Standardize/merge category names across brands | Prevents catalog fragmentation ("Men's Wear" x50 variants) |
| Advertising & ranking control | Define ad packages/pricing, monitor ranking algorithm health, manual override | Manual override must be logged (audit trail) to prevent abuse of the override itself |
| Payments & payouts oversight | Reconcile gateway transactions, approve payouts, handle refund disputes | Payout approval should require dual authorization above a configurable threshold |
| Delivery company mgmt | Onboard/offboard delivery companies, monitor SLA | SLA metrics: on-time %, return rate, COD reconciliation accuracy |
| Dispute resolution | Order disputes, chat abuse reports, fake product reports | Central queue feeding from multiple sources (chat reports, order disputes, product flags) |
| Content moderation | Review flagged chat messages/products/images | Should support both AI-assisted pre-flagging and manual queue |
| Reporting & analytics | Exportable reports for finance/ops/growth | CSV/PDF export, scheduled email delivery recommended |
| Role & permission mgmt | Sub-admins with scoped permissions | Enables finance-admin / support-admin separation of duties — a control, not just convenience |

### 2.3 RESTful API Design — `/admin`

| Method | Route | Purpose | Notes |
|---|---|---|---|
| GET | `/admin/dashboard` | Platform-wide KPI snapshot | Query params: `dateFrom`, `dateTo`, `granularity` |
| GET | `/admin/brands` | List brands with verification status filter | `?status=pending\|basic_verified\|trusted\|suspended` |
| GET | `/admin/brands/{brandId}` | Full brand profile incl. docs & scorecard | Includes linked vendor-scorecard data (Section 8.5) |
| PATCH | `/admin/brands/{brandId}/verify` | Move brand through verification tiers | Body: `{ tier, notes }` — triggers notification to brand |
| PATCH | `/admin/brands/{brandId}/reject` | Reject application | Body: `{ reason }` |
| PATCH | `/admin/brands/{brandId}/suspend` | Suspend an active brand | Requires `reason`, logged to audit trail |
| GET | `/admin/categories/pending` | Categories awaiting standardization | |
| PATCH | `/admin/categories/{id}/merge` | Merge duplicate categories into canonical one | Body: `{ targetCategoryId }` |
| GET | `/admin/ad-packages` | List ad pricing tiers | |
| POST | `/admin/ad-packages` | Create new ad package/tier | |
| GET | `/admin/ranking/health` | Ranking algorithm health metrics | Detects anomalies (e.g., one brand dominating via spend) |
| POST | `/admin/ranking/override` | Manually pin/demote a brand in ranking | Audit-logged (see 2.2 rule) |
| GET | `/admin/transactions` | Gateway transaction reconciliation view | Filters: `gateway`, `status`, `dateRange` |
| GET | `/admin/payouts` | Pending/completed brand payouts | |
| POST | `/admin/payouts/{payoutId}/approve` | Approve a payout | Consider dual-auth for amounts above threshold |
| GET | `/admin/disputes` | Unified dispute queue (orders/chat/products) | `?type=order\|chat\|product` |
| PATCH | `/admin/disputes/{disputeId}/resolve` | Resolve with outcome | Body: `{ outcome, refundAmount?, notes }` |
| GET | `/admin/moderation/flags` | Flagged content queue | |
| PATCH | `/admin/moderation/flags/{flagId}` | Action a flag (remove/dismiss/escalate) | |
| GET | `/admin/reports/{type}` | Generate report (finance/ops/growth) | `?format=csv\|pdf` |
| GET | `/admin/sub-admins` | List scoped sub-admin accounts | |
| POST | `/admin/sub-admins` | Create sub-admin with permission scope | Body: `{ email, permissions: [] }` |
| PATCH | `/admin/sub-admins/{id}/permissions` | Update permission scope | |
| GET | `/admin/delivery-companies` | List delivery partners + SLA metrics | |
| PATCH | `/admin/delivery-companies/{id}/status` | Onboard/offboard/suspend | |

---

## 3. Brand / Retail Shop

### 3.1 Business Function
The Brand role is the **supply side** of the marketplace — a self-service storefront operator. Its functions split into four business jobs: *get verified*, *manage catalog*, *win visibility (ads/ranking)*, and *fulfill & get paid*.

### 3.2 Functional Breakdown

| Function | Description | Business Rule |
|---|---|---|
| Brand registration | Submit legal name, address, contact, logo, business category | Entry point to verification funnel |
| Verification/KYC | Submit Commercial Registration, Tax ID, National ID, IBAN | IBAN must match legal entity name (fraud prevention — see 8.3) |
| Verification tiers | Pending → Basic Verified → Trusted Verified | Trusted unlocks ranking multiplier + lower commission (retention lever) |
| Category management | Create/edit/delete categories | Delete requires reassignment or soft-delete to preserve order history |
| Product management | CRUD products, variants (size/color), SKU, stock | Bulk CSV upload required for brands with large catalogs |
| Low-stock alerts | Notify brand when variant stock crosses threshold | Prevents overselling |
| Advertising | Purchase ranking promotion / ad packages | Ranking = weighted organic + paid score (formula in README Section 3.4) — protects against pure pay-to-win |
| Order management | View/accept/reject/prepare/hand off orders | SLA timer on acceptance feeds Admin auto-escalation (8.3) |
| Storefront chat | Respond to pre-sale questions | Shared chat resource (Section 1) |
| Sales analytics | Views, conversion, best-sellers, return rate | |
| Payouts | Pending balance, next payout date, history | Tied to Admin payout-approval workflow (2.3) |

### 3.3 RESTful API Design — `/brands`

| Method | Route | Purpose | Notes |
|---|---|---|---|
| POST | `/brands/register` **(Public)** | Submit new brand application | Body: name, address, contact, category |
| POST | `/brands/{brandId}/documents` | Upload KYC docs (CR, Tax ID, National ID, IBAN proof) | Multipart; drives verification tier |
| GET | `/brands/{brandId}/verification-status` | Check current tier + missing requirements | |
| GET | `/brands/{brandId}` **(Public for approved brands)** | Public brand profile page | |
| PATCH | `/brands/{brandId}` | Update brand profile | Owner-only |
| GET | `/brands/{brandId}/categories` | List brand's categories | |
| POST | `/brands/{brandId}/categories` | Create category | Body: `{ name, imageUrl }` |
| PATCH | `/brands/{brandId}/categories/{catId}` | Edit category | |
| DELETE | `/brands/{brandId}/categories/{catId}` | Delete (soft) category | Blocks if active products attached unless reassigned |
| GET | `/brands/{brandId}/products` | List products | Filters: category, stock status |
| POST | `/brands/{brandId}/products` | Create product | Body incl. variants array |
| PATCH | `/brands/{brandId}/products/{productId}` | Edit product | |
| DELETE | `/brands/{brandId}/products/{productId}` | Soft-delete product | |
| POST | `/brands/{brandId}/products/bulk-import` | CSV bulk upload | Async job; returns job ID + status endpoint |
| GET | `/brands/{brandId}/products/low-stock` | List variants under stock threshold | |
| POST | `/brands/{brandId}/ads/campaigns` | Purchase/launch ad package | Body: `{ packageId, budget, duration }` |
| GET | `/brands/{brandId}/ranking-score` | Current rank score + simplified breakdown | Publishes the "why" without exposing raw weights (README 3.4) |
| GET | `/brands/{brandId}/orders` | Incoming orders (sub-orders, per data-model note in Sec 9) | `?status=pending\|accepted\|preparing\|handed_off` |
| PATCH | `/brands/{brandId}/orders/{orderId}/accept` | Accept order | Starts SLA fulfillment clock |
| PATCH | `/brands/{brandId}/orders/{orderId}/reject` | Reject order | Body: `{ reason }` |
| PATCH | `/brands/{brandId}/orders/{orderId}/handoff` | Hand off to delivery company | Triggers delivery-company webhook (Section 5) |
| GET | `/brands/{brandId}/analytics/sales` | Sales/conversion/return analytics | |
| GET | `/brands/{brandId}/analytics/benchmark` | Anonymized category-average comparison | Feature 8.2 — paid-tier gated |
| GET | `/brands/{brandId}/payouts` | Payout history + pending balance | |

---

## 4. End-User

### 4.1 Business Function
The End-User role is the **demand side** — discover, evaluate, buy, and stay engaged. The core business risk here is leakage to off-platform channels (Instagram/WhatsApp direct sales), which is why discovery, trust signals (ratings/verified badge), and retention hooks matter as much as checkout itself.

### 4.2 Functional Breakdown

| Function | Description | Business Rule |
|---|---|---|
| Discovery | Browse/search/filter brands by category, price, rating, verified badge | Verified badge must be trustworthy (ties to 3.1 criteria) |
| Brand page | View brand profile, categories, products | Public |
| Chat with brand | Pre-sale questions, sizing, order status | Shared chat resource |
| Cart | Multi-brand cart, split into per-brand sub-orders at checkout | Each brand fulfills independently — drives per-sub-order delivery fee calc (Section 9) |
| Checkout & payments | Stripe (intl cards) + Paymob (local cards/wallets/Fawry) | COD is first-class (Section 7), not bolted on |
| Order tracking | Status timeline + live delivery tracking | |
| Ratings & reviews | On products and brands | Feeds ranking score (3.4) and vendor scorecard (8.5) |
| Wishlist | Save favorites | Feeds price/stock alert feature (8.1) |
| Notifications | Order updates, price drops, chat replies | Channel priority: WhatsApp > SMS > email (Section 7) |

### 4.3 RESTful API Design — `/users` and public catalog routes

| Method | Route | Purpose | Notes |
|---|---|---|---|
| GET | `/brands` **(Public)** | Discover/search/filter brands | `?category=&minRating=&verified=true&sort=ranking` |
| GET | `/products/search` **(Public)** | Search products across brands | Full-text + filter params |
| GET | `/products/{productId}` **(Public)** | Product detail incl. variants | |
| POST | `/chats` | Start a chat thread with a brand | Body: `{ brandId }` |
| GET | `/users/{userId}/cart` | View cart (grouped by brand) | |
| POST | `/users/{userId}/cart/items` | Add item to cart | Body: `{ productId, variantId, qty }` |
| PATCH | `/users/{userId}/cart/items/{itemId}` | Update quantity | |
| DELETE | `/users/{userId}/cart/items/{itemId}` | Remove item | |
| POST | `/users/{userId}/checkout` | Convert cart → order (splits into sub-orders per brand) | Body: `{ addressId, paymentMethod }`; `paymentMethod` includes `cod` |
| GET | `/users/{userId}/orders` | Order history | |
| GET | `/users/{userId}/orders/{orderId}` | Order detail with sub-order breakdown | |
| GET | `/users/{userId}/orders/{orderId}/tracking` | Live status timeline | |
| POST | `/products/{productId}/reviews` | Submit product review | Body: `{ rating, comment, photos[] }` |
| POST | `/brands/{brandId}/reviews` | Submit brand review | |
| GET | `/users/{userId}/wishlist` | List wishlist | |
| POST | `/users/{userId}/wishlist` | Add item | Body: `{ productId }` |
| DELETE | `/users/{userId}/wishlist/{itemId}` | Remove item | |

---

## 5. Delivery Company

### 5.1 Business Function
The Delivery Company is a **logistics fulfillment partner**, integrated via API. Its core business job is: receive orders, get them to a courier, get them delivered, and reconcile cash — the last part being disproportionately important given COD volume in Egypt.

### 5.2 Functional Breakdown

| Function | Description | Business Rule |
|---|---|---|
| Order intake | Receive orders pushed via webhook | Triggered by brand handoff (3.3) |
| Manual assignment | Dispatcher assigns order → courier | |
| Auto-assignment engine | Rules-based (nearest courier, load, zone coverage) | Manual override always available |
| Fleet management | Add/remove couriers, define coverage zones/hours | |
| Fee configuration | Delivery fee tiers by zone/weight/distance | Zone tiers: Cairo/Giza, Delta, Upper Egypt, remote (Section 7) |
| Dashboard | Orders by status, fees earned, avg delivery time, COD collected vs remitted | |
| Reconciliation reporting | Match cash collected by couriers against amount owed to brand/platform | Critical given COD share of Egyptian e-commerce |

### 5.3 RESTful API Design — `/delivery-companies`

| Method | Route | Purpose | Notes |
|---|---|---|---|
| POST | `/delivery-companies/{id}/orders/webhook` | Receive order push from platform | Triggered on brand handoff |
| GET | `/delivery-companies/{id}/orders` | List orders by status | `?status=pending\|assigned\|in_transit\|delivered\|returned\|failed` |
| PATCH | `/delivery-companies/{id}/orders/{orderId}/assign` | Manually assign to courier | Body: `{ courierId }` |
| PATCH | `/delivery-companies/{id}/auto-assign-rules` | Configure auto-assignment rules | Body: `{ strategy: "nearest"\|"least_load"\|"zone", params }` |
| GET | `/delivery-companies/{id}/couriers` | List fleet | |
| POST | `/delivery-companies/{id}/couriers` | Add courier | |
| DELETE | `/delivery-companies/{id}/couriers/{courierId}` | Remove courier | |
| PATCH | `/delivery-companies/{id}/couriers/{courierId}/coverage` | Set coverage zone/hours | |
| GET | `/delivery-companies/{id}/fee-tiers` | List fee configuration | |
| POST | `/delivery-companies/{id}/fee-tiers` | Create fee tier | Body: `{ zone, weightRange, distanceRange, fee }` |
| GET | `/delivery-companies/{id}/dashboard` | Ops dashboard | |
| GET | `/delivery-companies/{id}/reconciliation` | COD reconciliation report | `?period=` |

---

## 6. Delivery Agent (Courier)

### 6.1 Business Function
The Courier is the **last-mile execution layer**. The business job is narrow and operational: know what to deliver today, prove it was delivered, get paid for it.

### 6.2 Functional Breakdown

| Function | Description | Business Rule |
|---|---|---|
| Assigned orders list | Today/upcoming assignments | |
| Order detail | Customer info, address, map pin, items, COD amount, notes | |
| Status update | picked up → in transit → delivered / failed / returned | Status changes should notify the End-User (Section 1 notifications) |
| Proof of delivery | Photo and/or OTP/signature | Required for delivered status — protects against disputes (8.3) |
| Earnings summary | Daily/weekly fees earned | |
| Route view | Multi-stop route when carrying several orders | Recommended addition; expanded in 8.4 |

### 6.3 RESTful API Design — `/couriers`

| Method | Route | Purpose | Notes |
|---|---|---|---|
| GET | `/couriers/{id}/orders` | Assigned orders | `?date=today\|upcoming` |
| GET | `/couriers/{id}/orders/{orderId}` | Order detail | Includes COD amount, map pin |
| PATCH | `/couriers/{id}/orders/{orderId}/status` | Update delivery status | Body: `{ status, notes? }` |
| POST | `/couriers/{id}/orders/{orderId}/proof` | Submit proof of delivery | Multipart photo and/or `{ otp }` |
| GET | `/couriers/{id}/earnings` | Earnings summary | `?period=daily\|weekly` |
| GET | `/couriers/{id}/route` | Optimized multi-stop route for active orders | Ties to 8.4 route optimization feature |

---

## 7. Egypt-Market-Fit Features — Business Rationale Summary

| Feature | Business Value | Suggested API Surface |
|---|---|---|
| COD as first-class payment | Captures the majority-share payment method; without it, large addressable-market exclusion | `checkout.paymentMethod = "cod"`; reconciliation endpoints in Section 5 |
| Fawry / mobile wallet cash-in | Digitizes unbanked/card-hesitant users | Routed through `/payments/intents` → Paymob gateway |
| Installment/BNPL (valU, Aman, Souhoola) | Raises AOV on higher-ticket fashion items | New `paymentMethod` options + partner webhook endpoints |
| Arabic (RTL) + English bilingual UI | Trust/conversion driver for majority-language segment | Client-side/i18n concern; API should return locale-aware content fields |
| Governorate-based delivery zone engine | Prevents brand/delivery losses from flat-fee mispricing | `fee-tiers` resource (Section 5.3) |
| WhatsApp Business API notifications | Higher open-rate than SMS/email, fewer "where's my order" tickets | New notification channel in `/notifications` dispatch logic |
| SMS OTP primary verification | Higher signup/checkout completion than email | Already reflected in `/auth/otp/*` (Section 1) |
| Clothing-specific return/exchange workflow | Near-mandatory for apparel; protects brand ratings | New `/orders/{id}/returns` resource (see Section 8 recommendation) |
| Per-brand size-guide assistant | Directly reduces #1 clothing-return cause | New `/brands/{id}/size-guide` resource |
| E-invoicing / ETA integration | Tax compliance; positions platform as serious B2B partner | Server-side integration triggered on order completion, no new client-facing endpoint needed |
| COD trust/risk score per customer | Cuts failed-delivery costs | `/users/{id}/cod-risk-score` (internal/admin-readable) |
| In-app wallet for refunds | Faster than bank refunds; improves retention | `/users/{id}/wallet`, `/users/{id}/wallet/transactions` |
| Multi-courier fallback | Avoids losing sales in underserved geographies | Delivery-company selection logic in order-handoff step |
| Ramadan/Eid seasonal campaign tooling | Drives ad spend exactly at demand peaks | `/brands/{id}/campaigns` (flash sale, countdown banner config) |

---

## 8. Additional Recommended Features — API Impact

Organized by the same categories as the source README, with the *new* endpoints each would require.

### 8.1 Growth & Retention (End-User)
| Feature | New/Extended Endpoints |
|---|---|
| Loyalty/cashback points | `GET/POST /users/{id}/loyalty-points` |
| Abandoned cart recovery | Background job + `/notifications` dispatch; no new user-facing endpoint |
| Referral program | `POST /users/{id}/referrals`, `GET /users/{id}/referrals/status` |
| Wishlist stock/price alerts | Extends existing `/users/{id}/wishlist` with alert subscription flag |
| Gift cards & gift wrapping | `POST /gift-cards`, `PATCH /users/{id}/checkout` to add `giftWrap: true` |
| Delivery time-slot scheduling | Extend `POST /users/{id}/checkout` with `preferredSlot` field |

### 8.2 Brand Enablement & Revenue
| Feature | New/Extended Endpoints |
|---|---|
| Tiered SaaS subscription plans | `GET /subscription-plans`, `POST /brands/{id}/subscription` |
| Brand analytics benchmarking | `GET /brands/{id}/analytics/benchmark` (listed above, gated by plan) |
| Bulk inventory sync via webhook | `POST /brands/{id}/inventory/webhook` (inbound from brand's POS/ERP) |
| Influencer/affiliate marketplace | `POST /affiliates`, `GET /affiliates/{code}/performance` |
| "Authenticity/Local Designer" badge | Extend brand profile: `badges: ["verified", "local_designer"]` |

### 8.3 Trust, Safety & Fraud Prevention
| Feature | New/Extended Endpoints |
|---|---|
| Fraud/risk engine | Internal service; exposes `GET /admin/fraud-flags` |
| Buyer protection guarantee | `POST /orders/{id}/protection-claim` |
| Photo/video dispute evidence | Extend `POST /admin/disputes` intake to accept media attachments |
| Automated SLA enforcement | Background job auto-triggers `PATCH /admin/disputes` escalation or auto-cancel + refund |

### 8.4 Operations & Delivery Intelligence
| Feature | New/Extended Endpoints |
|---|---|
| Demand heatmaps | `GET /delivery-companies/{id}/heatmap` |
| Failed-delivery/return-to-brand workflow | `POST /orders/{id}/return-to-brand` |
| Multi-drop route optimization | Extends `GET /couriers/{id}/route` (already listed, Section 6.3) |

### 8.5 Platform Intelligence (Admin)
| Feature | New/Extended Endpoints |
|---|---|
| Vendor scorecard | `GET /admin/brands/{id}/scorecard` |
| Public API/developer access | `POST /developer/api-keys` (scoped to large/verified brands) |
| In-app support ticketing | `GET/POST /support-tickets`, `PATCH /support-tickets/{id}` |

---

## 9. Data Model Notes (carried from source, relevant to API design)

- **Order vs. Sub-order**: an `Order` is a checkout-level entity; it decomposes into `SubOrder` records, one per brand. All brand-, delivery-, and courier-facing endpoints in Sections 3, 5, 6 should operate on `SubOrder`, not `Order`.
- **Delivery fee** is computed per sub-order (brand origin × customer governorate), not platform-wide — this belongs in the fee-tier resource (5.3), evaluated at checkout time (4.3).
- **Ranking score** is a scheduled batch computation (e.g., nightly job), not computed per request — `GET /brands/{id}/ranking-score` should read from a precomputed value, not calculate live.

---

## 10. Suggested Prioritization (BA Roadmap View)

A rough MoSCoW-style cut to sequence build order, based on what blocks core transactions vs. what compounds value later:

| Priority | Features |
|---|---|
| **Must-have (MVP)** | Brand verification & catalog, cart/checkout with COD + Stripe/Paymob, order lifecycle (accept→deliver), basic Admin dashboard & dispute queue, courier app (status + proof of delivery) |
| **Should-have (Fast Follow)** | Ranking/ads system, return/exchange workflow, size-guide assistant, WhatsApp notifications, reconciliation reporting |
| **Could-have (Growth Phase)** | Loyalty points, referral program, wallet, influencer marketplace, brand subscription tiers, analytics benchmarking |
| **Won't-have (Yet)** | Public developer API, demand heatmaps, multi-drop route optimization — valuable but only once order volume justifies the engineering investment |

---

*This document translates the FashionConnect business-logic README into a role-by-role functional spec and RESTful API contract, intended as a handoff artifact between product/business stakeholders and the engineering team.*
