# Backend Functional Specification — FashionConnect

> This document is the single source of truth for backend development. It defines the functional scope, controllers, routers, endpoints, validation rules, authorization model, response contracts, workflows, and database interactions for the FashionConnect platform.

---

## 1. Project Overview

### 1.1 Project Description

FashionConnect is a multi-role e-commerce and marketplace platform designed for the Egyptian market. The platform supports brand onboarding, catalog management, product discovery, cart and checkout, order fulfillment, delivery operations, payments, payouts, messaging, reviews, moderation, and admin governance.

The platform is built around a modular monolith architecture with REST APIs, PostgreSQL persistence, JWT-based authentication, and async events for notifications, payments, and admin operations.

### 1.2 Business Goals

- Enable trusted brand onboarding and marketplace growth.
- Support end-user discovery, cart, checkout, and order tracking.
- Support COD-first commerce with digital payments via Stripe and Paymob.
- Provide delivery-company and courier workflows for last-mile operations.
- Provide admin controls for moderation, disputes, payouts, and ranking.
- Ensure secure, auditable, and maintainable backend operations.

### 1.3 Target Users

- End users
- Brand owners
- Admins
- Sub-admins
- Delivery companies
- Couriers

### 1.4 User Roles and Permissions

| Role             | Primary Responsibilities                                                  | Permissions                     |
| ---------------- | ------------------------------------------------------------------------- | ------------------------------- |
| Admin            | Platform governance, verification, disputes, payouts, moderation, ranking | Full platform administration    |
| Sub-admin        | Scoped operational tasks                                                  | Limited admin permissions       |
| Brand            | Manage brand account, catalog, products, orders, payouts                  | Own-brand operations only       |
| End user         | Browse, buy, review, chat, manage wishlist/cart                           | Own account and own orders only |
| Delivery company | Manage delivery fleet and assignments                                     | Own delivery company operations |
| Courier          | Execute deliveries and submit proof                                       | Assigned orders only            |
| Guest            | Browse public catalog and brand profiles                                  | Public read-only access         |

### 1.5 Main Features

- Authentication and identity management
- Brand registration and verification
- Product catalog and variants
- Wishlist management
- Cart and checkout
- Order lifecycle and reviews
- Delivery company and courier workflows
- Payments, wallets, and payouts
- Messaging and notifications
- Admin governance and moderation

---

## 2. Feature Breakdown

### 2.1 Authentication & Identity

- Description: Register users, verify identity via OTP, issue JWT tokens, manage refresh tokens, and invalidate sessions.
- Business Rules:
  - Passwords must never be stored in plaintext.
  - OTPs must expire and be single-use.
  - Refresh tokens must be revocable.
  - Account roles determine access scope.
- Roles: Guest, End User, Brand, Admin, Delivery Company, Courier
- Dependencies: Users table, OTP table, refresh token table, password hashing utility, JWT service

### 2.2 Profiles & Addresses

- Description: Manage user profile data and address records.
- Business Rules:
  - A user may have multiple addresses but only one default address.
  - Profile updates must not change account ownership or role.
- Roles: End User
- Dependencies: Auth module, users, addresses

### 2.3 Brand Onboarding & Verification

- Description: Brand registration, document upload, verification status management, and public profile access.
- Business Rules:
  - Verification tier transitions are governed by admin review.
  - Brand documents are reviewable and auditable.
  - Public brand profiles are only available for approved brands.
- Roles: Guest, Brand, Admin
- Dependencies: Users, brands, brand_documents, admin workflow

### 2.4 Catalog & Product Management

- Description: Categories, products, variants, product media, low-stock visibility, and wishlist behavior.
- Business Rules:
  - Products use soft-delete semantics.
  - Category deletion must preserve history or reassign references.
  - Variant uniqueness is enforced by product_id + color + size.
- Roles: Brand, Admin, Guest, End User
- Dependencies: Brands, categories, products, variants, product_media

### 2.5 Cart & Checkout

- Description: End users build carts, update quantities, and proceed to checkout.
- Business Rules:
  - Checkout must be atomic.
  - Cart can contain multi-brand products.
  - Checkout creates one order and multiple sub-orders per brand.
- Roles: End User
- Dependencies: Cart, products, variants, payments, addresses, discounts

### 2.6 Orders, Fulfillment & Reviews

- Description: Manage orders, sub-orders, status transitions, acceptance/rejection, handoff, tracking, and customer reviews.
- Business Rules:
  - Sub-order status changes must be auditable.
  - Reviews should only be created for completed purchases.
  - Brand acceptance/rejection is required before handoff.
- Roles: End User, Brand, Admin, Delivery Company, Courier
- Dependencies: Orders, sub_orders, order_items, reviews, delivery

### 2.7 Delivery & Courier Operations

- Description: Receive orders from the platform, assign couriers, track status, submit proof of delivery, and reconcile COD.
- Business Rules:
  - Proof of delivery is required for successful delivery completion.
  - COD reconciliation must be auditable.
  - Status transitions notify the customer.
- Roles: Delivery Company, Courier, Brand, Admin
- Dependencies: sub_orders, delivery_companies, couriers, delivery_proofs, cod_reconciliations

### 2.8 Payments, Payouts & Wallets

- Description: Create payment intents, receive gateway webhooks, handle refunds and wallet behavior, and approve payouts.
- Business Rules:
  - Payments must be idempotent.
  - Wallet balances must be derived from ledger events.
  - Payouts require admin approval.
- Roles: End User, Brand, Admin
- Dependencies: orders, transactions, payouts, wallets, wallet_transactions

### 2.9 Messaging & Notifications

- Description: Support user-to-brand chat, message reporting, and asynchronous notifications.
- Business Rules:
  - Chat threads are shared across roles.
  - Notification delivery is asynchronous.
- Roles: End User, Brand, Admin, Courier
- Dependencies: chat_threads, chat_messages, notifications, notification_templates

### 2.10 Admin Governance & Trust

- Description: Moderate disputes, review content, manage ranking overrides, and create sub-admin accounts.
- Business Rules:
  - Admin actions must be logged.
  - Ranking override actions must be auditable.
  - Disputes must have evidence and outcome tracking.
- Roles: Admin, Sub-admin
- Dependencies: disputes, moderation_flags, admin_audit_log, ranking_scores

---

## 3. Controllers

### 3.1 AuthController

- Purpose: Register users, authenticate users, send and verify OTP, refresh tokens, and log out.
- Business Logic: Validate identity, create hashed passwords, issue JWTs, manage OTP lifecycle, and revoke refresh tokens.
- Authorization: Public for register/login/OTP; protected for logout/refresh.
- Validation Requirements: Email/phone/password/role validation, OTP validation, token validation.
- Database Tables Used: users, refresh_tokens, otp_codes
- Possible Errors: invalid_credentials, user_exists, otp_expired, token_invalid, rate_limited
- Dependencies: JWT service, OTP service, password hashing utility

### 3.2 UserController

- Purpose: Manage authenticated user profile and profile-related resources.
- Business Logic: Read and update profile fields, manage addresses, read wallet and loyalty state.
- Authorization: Self-service only for end users; admins may read user data.
- Validation Requirements: Profile field validation, address validation, ownership checks.
- Database Tables Used: users, addresses, wallets, loyalty_points
- Possible Errors: not_found, forbidden, duplicate_default_address
- Dependencies: Auth middleware

### 3.3 BrandController

- Purpose: Manage brand onboarding, profile, category and product ownership, order access, and payout visibility.
- Business Logic: Register brand applications, update brand profile, manage catalog access, and expose brand public profile data.
- Authorization: Public for registration and public profile; owner/admin for private access.
- Validation Requirements: Brand profile validation, document validation, ownership validation.
- Database Tables Used: brands, brand_documents, brand_social_links, brand_followers, products, categories, sub_orders, payouts
- Possible Errors: not_found, invalid_state_transition, brand_not_verified, forbidden
- Dependencies: Admin verification workflow

### 3.4 CategoryController

- Purpose: Manage categories for a brand.
- Business Logic: List, create, edit, and soft-delete categories while preserving referential integrity.
- Authorization: Brand owner or admin.
- Validation Requirements: Category name validation, parent category validation, active-product dependency checks.
- Database Tables Used: categories, products
- Possible Errors: category_in_use, invalid_parent
- Dependencies: Brand ownership checks

### 3.5 ProductController

- Purpose: Manage products and variants for a brand.
- Business Logic: Create, update, list, delete, and bulk-import products and media.
- Authorization: Brand owner or admin.
- Validation Requirements: Product payload validation, variant validation, stock validation, media validation.
- Database Tables Used: products, product_media, variants, product_discounts
- Possible Errors: invalid_variant, stock_invalid, not_found
- Dependencies: CategoryController, upload service

### 3.6 WishlistController

- Purpose: Manage user wishlist entries.
- Business Logic: List, add, remove wishlist items and optionally support alert preferences.
- Authorization: Self-service only.
- Validation Requirements: Product existence validation and ownership checks.
- Database Tables Used: wishlists, products
- Possible Errors: already_exists, not_found
- Dependencies: ProductController

### 3.7 CartController

- Purpose: Manage end-user cart contents.
- Business Logic: Read cart, add/remove items, update quantity, and compute price snapshots.
- Authorization: Self-service only.
- Validation Requirements: Variant availability, quantity validation, ownership validation.
- Database Tables Used: carts, cart_items, variants
- Possible Errors: out_of_stock, variant_not_found, cart_not_found
- Dependencies: Product/Variant rules

### 3.8 CheckoutController

- Purpose: Convert a cart into one checkout-level order and multiple brand-level sub-orders.
- Business Logic: Validate address and payment method, create order/sub-order/order_items, apply discounts, create payment intent, and mark payment status.
- Authorization: Self-service only.
- Validation Requirements: Address presence, payment method validation, stock validation, discount validation.
- Database Tables Used: orders, sub_orders, order_items, discount_usages, transactions, carts, cart_items
- Possible Errors: payment_failed, inventory_insufficient, address_invalid, invalid_discount
- Dependencies: CartController, PaymentController, Address validation

### 3.9 OrderController

- Purpose: Manage user-facing order history and tracking.
- Business Logic: List orders, expose order detail, show tracking history, and manage return requests.
- Authorization: Owner or admin.
- Validation Requirements: Ownership validation, order existence validation, status validation.
- Database Tables Used: orders, sub_orders, sub_order_status_history, order_items, returns
- Possible Errors: not_found, forbidden, invalid_transition
- Dependencies: CheckoutController, Delivery workflow

### 3.10 BrandOrderController

- Purpose: Manage incoming brand-side order operations.
- Business Logic: List incoming sub-orders, accept/reject orders, and hand off to delivery companies.
- Authorization: Brand owner only.
- Validation Requirements: Brand ownership validation, status transition validation.
- Database Tables Used: sub_orders, sub_order_status_history, delivery_companies
- Possible Errors: invalid_transition, unauthorized, not_found
- Dependencies: Order lifecycle rules

### 3.11 ReviewController

- Purpose: Create and moderate product and brand reviews.
- Business Logic: Validate order ownership and create review records with optional images.
- Authorization: Self-service for creating reviews; admin for moderation.
- Validation Requirements: Rating validation, purchase validation, image validation.
- Database Tables Used: reviews, review_images, order_items
- Possible Errors: invalid_order_item, duplicate_review
- Dependencies: OrderController

### 3.12 DeliveryCompanyController

- Purpose: Manage delivery company operations and fee configuration.
- Business Logic: Receive webhook orders, list assigned orders, configure auto-assignment rules, create or update courier coverage, and expose reconciliation reports.
- Authorization: Delivery company owner or admin.
- Validation Requirements: Company ownership validation, zone validation, fee configuration validation.
- Database Tables Used: delivery_companies, delivery_zones, couriers, cod_reconciliations, sub_orders
- Possible Errors: invalid_zone, courier_not_found, unauthorized
- Dependencies: Brand handoff workflow

### 3.13 CourierController

- Purpose: Manage courier execution tasks.
- Business Logic: List assigned orders, update status, submit proof of delivery, and expose earnings summary.
- Authorization: Assigned courier only.
- Validation Requirements: Status transition validation, proof presence validation, courier ownership validation.
- Database Tables Used: sub_orders, sub_order_status_history, delivery_proofs
- Possible Errors: invalid_status, proof_required
- Dependencies: DeliveryCompanyController

### 3.14 PaymentController

- Purpose: Create payment intents and reconcile successful payments.
- Business Logic: Create gateway payment intents, map gateway responses to order/payment state, and support wallet interactions.
- Authorization: Self-service for user-created payment intents; public for webhooks.
- Validation Requirements: Payment method validation, amount validation, idempotency handling.
- Database Tables Used: transactions, orders, wallets, wallet_transactions
- Possible Errors: payment_failed, duplicate_event, webhook_invalid
- Dependencies: CheckoutController, notification system

### 3.15 PaymentWebhookController

- Purpose: Receive asynchronous payment webhooks from Stripe and Paymob.
- Business Logic: Verify signatures, match gateway references, update transaction/payment status, and trigger downstream events.
- Authorization: Public.
- Validation Requirements: Webhook signature and payload validation.
- Database Tables Used: transactions, orders
- Possible Errors: webhook_invalid, duplicate_event
- Dependencies: PaymentController

### 3.16 PayoutController

- Purpose: Manage payout listing and admin approval workflow.
- Business Logic: List brand payouts and approve or reject pending payouts.
- Authorization: Brand owner for own payout history; admin for approval.
- Validation Requirements: Amount validation, payout state validation, admin permission validation.
- Database Tables Used: payouts, admin_audit_log
- Possible Errors: payout_not_found, already_processed
- Dependencies: Payment and brand modules

### 3.17 WalletController

- Purpose: Retrieve wallet records and transactions.
- Business Logic: Expose wallet balance and wallet transaction history.
- Authorization: Self-service only.
- Validation Requirements: User ownership validation.
- Database Tables Used: wallets, wallet_transactions
- Possible Errors: not_found
- Dependencies: PaymentController

### 3.18 ChatController

- Purpose: Manage chat threads and messages.
- Business Logic: Create threads, list messages, send messages, and report suspicious or abusive messages.
- Authorization: Thread participants or admin.
- Validation Requirements: Thread membership validation, content validation, report validation.
- Database Tables Used: chat_threads, chat_messages
- Possible Errors: thread_not_found, unauthorized
- Dependencies: User/brand identity

### 3.19 NotificationController

- Purpose: List and mark notifications as read.
- Business Logic: Retrieve notifications for the authenticated user and update read state.
- Authorization: Self-service only.
- Validation Requirements: Notification ownership validation.
- Database Tables Used: notifications
- Possible Errors: not_found
- Dependencies: Notification templates and events

### 3.20 AdminController

- Purpose: Provide administration dashboards and governance tools.
- Business Logic: Expose KPI data, manage disputes, flags, ranking overrides, and sub-admin permissions.
- Authorization: Admin or scoped sub-admin only.
- Validation Requirements: Admin permission validation, audit log generation.
- Database Tables Used: orders, users, brands, transactions, disputes, moderation_flags, ranking_scores, admin_audit_log
- Possible Errors: forbidden, invalid_action
- Dependencies: All core business modules

---

## 4. API Endpoints

Base path: /api/v1

### 4.1 Authentication Endpoints

| Method | Endpoint         | Purpose                                              | Auth | Roles                  |
| ------ | ---------------- | ---------------------------------------------------- | ---- | ---------------------- |
| POST   | /auth/register   | Create a user/brand/delivery-company/courier account | No   | Guest                  |
| POST   | /auth/login      | Authenticate a user and return a JWT                 | No   | Guest                  |
| POST   | /auth/otp/send   | Send OTP for verification or checkout completion     | No   | Guest                  |
| POST   | /auth/otp/verify | Verify OTP                                           | No   | Guest                  |
| POST   | /auth/refresh    | Refresh access token                                 | Yes  | Any authenticated role |
| POST   | /auth/logout     | Invalidate refresh token                             | Yes  | Any authenticated role |

#### POST /auth/register

- Request Body: { phone, email?, password, role, name?, brandProfile? }
- Validation Rules: phone required, password min length 8, role enum, email format if provided
- Success Response: 201 with user object and token
- Error Responses: 400 validation error, 409 conflict

#### POST /auth/login

- Request Body: { login: phone|email, password }
- Success Response: 200 with accessToken, refreshToken, user profile
- Error Responses: 401 unauthorized

#### POST /auth/otp/send

- Request Body: { phone, purpose }
- Success Response: 200 with message
- Error Responses: 400 validation error, 429 rate limit

#### POST /auth/otp/verify

- Request Body: { phone, code, purpose }
- Success Response: 200 with verified status
- Error Responses: 400 invalid code, 410 expired code

#### POST /auth/refresh

- Request Body: { refreshToken }
- Success Response: 200 with new accessToken
- Error Responses: 401 invalid or revoked token

#### POST /auth/logout

- Request Body: { refreshToken }
- Success Response: 200 with success message
- Error Responses: 401 unauthorized

### 4.2 User and Profile Endpoints

| Method | Endpoint                            | Purpose                | Auth | Roles                       |
| ------ | ----------------------------------- | ---------------------- | ---- | --------------------------- |
| GET    | /users/me                           | Get current profile    | Yes  | Any authenticated role      |
| PATCH  | /users/me                           | Update current profile | Yes  | Any authenticated role      |
| GET    | /users/me/addresses                 | List addresses         | Yes  | End user / Brand / Delivery |
| POST   | /users/me/addresses                 | Create address         | Yes  | End user / Brand / Delivery |
| PATCH  | /users/me/addresses/{addressId}     | Update address         | Yes  | End user / Brand / Delivery |
| DELETE | /users/me/addresses/{addressId}     | Delete address         | Yes  | End user / Brand / Delivery |
| GET    | /users/{userId}/wallet              | Get wallet balance     | Yes  | Self or admin               |
| GET    | /users/{userId}/wallet/transactions | Get wallet history     | Yes  | Self or admin               |
| GET    | /users/{userId}/loyalty-points      | Get loyalty points     | Yes  | Self or admin               |
| POST   | /users/{userId}/referrals           | Create referral        | Yes  | End user                    |
| GET    | /users/{userId}/referrals/status    | Get referral status    | Yes  | End user                    |

### 4.3 Brand Endpoints

| Method | Endpoint                                   | Purpose                      | Auth          | Roles                                   |
| ------ | ------------------------------------------ | ---------------------------- | ------------- | --------------------------------------- |
| POST   | /brands/register                           | Register a new brand         | No            | Guest                                   |
| POST   | /brands/{brandId}/documents                | Upload brand documents       | Yes           | Brand owner                             |
| GET    | /brands/{brandId}/verification-status      | Get verification status      | Yes or Public | Brand owner / Admin / Guest if approved |
| GET    | /brands/{brandId}                          | Get public brand profile     | No            | Guest                                   |
| PATCH  | /brands/{brandId}                          | Update brand profile         | Yes           | Brand owner                             |
| GET    | /brands/{brandId}/categories               | List categories              | Yes or Public | Brand owner / Admin / Guest             |
| POST   | /brands/{brandId}/categories               | Create category              | Yes           | Brand owner                             |
| PATCH  | /brands/{brandId}/categories/{categoryId}  | Update category              | Yes           | Brand owner                             |
| DELETE | /brands/{brandId}/categories/{categoryId}  | Delete category              | Yes           | Brand owner                             |
| GET    | /brands/{brandId}/products                 | List products                | Yes or Public | Brand owner/Admin/Guest                 |
| POST   | /brands/{brandId}/products                 | Create product               | Yes           | Brand owner                             |
| PATCH  | /brands/{brandId}/products/{productId}     | Update product               | Yes           | Brand owner                             |
| DELETE | /brands/{brandId}/products/{productId}     | Delete product               | Yes           | Brand owner                             |
| POST   | /brands/{brandId}/products/bulk-import     | Import products from CSV     | Yes           | Brand owner                             |
| GET    | /brands/{brandId}/products/low-stock       | List low-stock products      | Yes           | Brand owner                             |
| POST   | /brands/{brandId}/ads/campaigns            | Create ad campaign           | Yes           | Brand owner                             |
| GET    | /brands/{brandId}/ranking-score            | Get ranking score            | Yes or Public | Brand owner / Admin / Guest             |
| GET    | /brands/{brandId}/orders                   | List incoming sub-orders     | Yes           | Brand owner                             |
| PATCH  | /brands/{brandId}/orders/{orderId}/accept  | Accept sub-order             | Yes           | Brand owner                             |
| PATCH  | /brands/{brandId}/orders/{orderId}/reject  | Reject sub-order             | Yes           | Brand owner                             |
| PATCH  | /brands/{brandId}/orders/{orderId}/handoff | Hand off to delivery company | Yes           | Brand owner                             |
| GET    | /brands/{brandId}/analytics/sales          | Sales analytics              | Yes           | Brand owner                             |
| GET    | /brands/{brandId}/analytics/benchmark      | Benchmark analytics          | Yes           | Brand owner                             |
| GET    | /brands/{brandId}/payouts                  | Payout history               | Yes           | Brand owner                             |

### 4.4 Catalog and Discovery Endpoints

| Method | Endpoint              | Purpose            | Auth | Roles |
| ------ | --------------------- | ------------------ | ---- | ----- |
| GET    | /brands               | List public brands | No   | Guest |
| GET    | /products/search      | Search products    | No   | Guest |
| GET    | /products/{productId} | Get product detail | No   | Guest |

### 4.5 Cart, Checkout and Order Endpoints

| Method | Endpoint                                  | Purpose               | Auth | Roles            |
| ------ | ----------------------------------------- | --------------------- | ---- | ---------------- |
| GET    | /users/{userId}/cart                      | Get cart              | Yes  | End user         |
| POST   | /users/{userId}/cart/items                | Add item to cart      | Yes  | End user         |
| PATCH  | /users/{userId}/cart/items/{itemId}       | Update cart item      | Yes  | End user         |
| DELETE | /users/{userId}/cart/items/{itemId}       | Remove cart item      | Yes  | End user         |
| POST   | /users/{userId}/checkout                  | Create checkout/order | Yes  | End user         |
| GET    | /users/{userId}/orders                    | List orders           | Yes  | End user / Admin |
| GET    | /users/{userId}/orders/{orderId}          | Get order detail      | Yes  | End user / Admin |
| GET    | /users/{userId}/orders/{orderId}/tracking | Get tracking timeline | Yes  | End user / Admin |
| POST   | /orders/{orderId}/returns                 | Create return request | Yes  | End user         |

### 4.6 Review Endpoints

| Method | Endpoint                      | Purpose               | Auth | Roles    |
| ------ | ----------------------------- | --------------------- | ---- | -------- |
| POST   | /products/{productId}/reviews | Submit product review | Yes  | End user |
| POST   | /brands/{brandId}/reviews     | Submit brand review   | Yes  | End user |

### 4.7 Wishlist Endpoints

| Method | Endpoint                          | Purpose              | Auth | Roles    |
| ------ | --------------------------------- | -------------------- | ---- | -------- |
| GET    | /users/{userId}/wishlist          | List wishlist        | Yes  | End user |
| POST   | /users/{userId}/wishlist          | Add to wishlist      | Yes  | End user |
| DELETE | /users/{userId}/wishlist/{itemId} | Remove from wishlist | Yes  | End user |

### 4.8 Delivery Company Endpoints

| Method | Endpoint                                               | Purpose                   | Auth | Roles            |
| ------ | ------------------------------------------------------ | ------------------------- | ---- | ---------------- |
| POST   | /delivery-companies/{id}/orders/webhook                | Receive order push        | No   | Delivery company |
| GET    | /delivery-companies/{id}/orders                        | List orders               | Yes  | Delivery company |
| PATCH  | /delivery-companies/{id}/orders/{orderId}/assign       | Assign courier            | Yes  | Delivery company |
| PATCH  | /delivery-companies/{id}/auto-assign-rules             | Configure auto assignment | Yes  | Delivery company |
| GET    | /delivery-companies/{id}/couriers                      | List couriers             | Yes  | Delivery company |
| POST   | /delivery-companies/{id}/couriers                      | Add courier               | Yes  | Delivery company |
| DELETE | /delivery-companies/{id}/couriers/{courierId}          | Remove courier            | Yes  | Delivery company |
| PATCH  | /delivery-companies/{id}/couriers/{courierId}/coverage | Set coverage              | Yes  | Delivery company |
| GET    | /delivery-companies/{id}/fee-tiers                     | List fee tiers            | Yes  | Delivery company |
| POST   | /delivery-companies/{id}/fee-tiers                     | Create fee tier           | Yes  | Delivery company |
| GET    | /delivery-companies/{id}/dashboard                     | Delivery dashboard        | Yes  | Delivery company |
| GET    | /delivery-companies/{id}/reconciliation                | Reconciliation report     | Yes  | Delivery company |

### 4.9 Courier Endpoints

| Method | Endpoint                               | Purpose                  | Auth | Roles   |
| ------ | -------------------------------------- | ------------------------ | ---- | ------- |
| GET    | /couriers/{id}/orders                  | List assigned orders     | Yes  | Courier |
| GET    | /couriers/{id}/orders/{orderId}        | View assigned order      | Yes  | Courier |
| PATCH  | /couriers/{id}/orders/{orderId}/status | Update delivery status   | Yes  | Courier |
| POST   | /couriers/{id}/orders/{orderId}/proof  | Submit proof of delivery | Yes  | Courier |
| GET    | /couriers/{id}/earnings                | Earnings summary         | Yes  | Courier |
| GET    | /couriers/{id}/route                   | Route information        | Yes  | Courier |

### 4.10 Payment Endpoints

| Method | Endpoint                          | Purpose               | Auth | Roles       |
| ------ | --------------------------------- | --------------------- | ---- | ----------- |
| POST   | /payments/intents                 | Create payment intent | Yes  | End user    |
| POST   | /payments/webhooks/stripe         | Stripe webhook        | No   | Public      |
| POST   | /payments/webhooks/paymob         | Paymob webhook        | No   | Public      |
| GET    | /brands/{brandId}/payouts         | Payout history        | Yes  | Brand owner |
| POST   | /admin/payouts/{payoutId}/approve | Approve payout        | Yes  | Admin       |

### 4.11 Chat and Notification Endpoints

| Method | Endpoint                   | Purpose                   | Auth | Roles                      |
| ------ | -------------------------- | ------------------------- | ---- | -------------------------- |
| POST   | /chats                     | Create chat thread        | Yes  | End user / Brand           |
| GET    | /chats/{threadId}/messages | List messages             | Yes  | Thread participant / Admin |
| POST   | /chats/{threadId}/messages | Send message              | Yes  | Thread participant         |
| POST   | /chats/{threadId}/report   | Report thread/message     | Yes  | Thread participant         |
| GET    | /notifications             | Get notifications         | Yes  | Any authenticated role     |
| PATCH  | /notifications/{id}/read   | Mark notification as read | Yes  | Any authenticated role     |

### 4.12 Admin Endpoints

| Method | Endpoint                              | Purpose                        | Auth | Roles |
| ------ | ------------------------------------- | ------------------------------ | ---- | ----- |
| GET    | /admin/dashboard                      | Platform dashboard             | Yes  | Admin |
| GET    | /admin/brands                         | List brands                    | Yes  | Admin |
| GET    | /admin/brands/{brandId}               | Brand detail                   | Yes  | Admin |
| PATCH  | /admin/brands/{brandId}/verify        | Verify brand                   | Yes  | Admin |
| PATCH  | /admin/brands/{brandId}/reject        | Reject brand                   | Yes  | Admin |
| PATCH  | /admin/brands/{brandId}/suspend       | Suspend brand                  | Yes  | Admin |
| GET    | /admin/categories/pending             | Pending categories             | Yes  | Admin |
| PATCH  | /admin/categories/{id}/merge          | Merge categories               | Yes  | Admin |
| GET    | /admin/ad-packages                    | List ad packages               | Yes  | Admin |
| POST   | /admin/ad-packages                    | Create ad package              | Yes  | Admin |
| GET    | /admin/ranking/health                 | Ranking health                 | Yes  | Admin |
| POST   | /admin/ranking/override               | Override ranking               | Yes  | Admin |
| GET    | /admin/transactions                   | Transaction reconciliation     | Yes  | Admin |
| GET    | /admin/payouts                        | List payouts                   | Yes  | Admin |
| GET    | /admin/disputes                       | List disputes                  | Yes  | Admin |
| PATCH  | /admin/disputes/{disputeId}/resolve   | Resolve dispute                | Yes  | Admin |
| GET    | /admin/moderation/flags               | List moderation flags          | Yes  | Admin |
| PATCH  | /admin/moderation/flags/{flagId}      | Handle moderation flag         | Yes  | Admin |
| GET    | /admin/reports/{type}                 | Export reports                 | Yes  | Admin |
| GET    | /admin/sub-admins                     | List sub-admins                | Yes  | Admin |
| POST   | /admin/sub-admins                     | Create sub-admin               | Yes  | Admin |
| PATCH  | /admin/sub-admins/{id}/permissions    | Update sub-admin permissions   | Yes  | Admin |
| GET    | /admin/delivery-companies             | List delivery companies        | Yes  | Admin |
| PATCH  | /admin/delivery-companies/{id}/status | Update delivery company status | Yes  | Admin |

### 4.13 Upload Endpoint

| Method | Endpoint | Purpose                                      | Auth | Roles                              |
| ------ | -------- | -------------------------------------------- | ---- | ---------------------------------- |
| POST   | /uploads | Upload files for documents, media, and proof | Yes  | Brand / End user / Courier / Admin |

---

## 5. Response Format

All successful responses must follow:

```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": {}
}
```

All error responses must follow:

```json
{
  "success": false,
  "message": "Validation failed"
}
```

### 5.1 Validation Error Example

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    {
      "field": "phone",
      "message": "Phone is required"
    }
  ]
}
```

### 5.2 Unauthorized Example

```json
{
  "success": false,
  "message": "Unauthorized"
}
```

### 5.3 Forbidden Example

```json
{
  "success": false,
  "message": "Forbidden"
}
```

### 5.4 Not Found Example

```json
{
  "success": false,
  "message": "Resource not found"
}
```

### 5.5 Conflict Example

```json
{
  "success": false,
  "message": "Conflict"
}
```

### 5.6 Internal Server Error Example

```json
{
  "success": false,
  "message": "Internal server error"
}
```

### 5.7 Pagination Response (when applicable)

```json
{
  "success": true,
  "message": "Products retrieved successfully",
  "data": {
    "items": [],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 120,
      "pages": 6
    }
  }
}
```

---

## 6. Returned Data

### 6.1 GET /users/me

Returned fields:

- id
- phone
- email
- role
- isVerified
- profilePictureUrl
- createdAt
- updatedAt

### 6.2 GET /brands/{brandId}

Returned fields:

- id
- displayName
- verificationStatus
- rating
- logoUrl
- followersCount
- isActive
- socialLinks
- categories
- products

### 6.3 GET /products/{productId}

Returned fields:

- id
- nameAr/nameEn
- descriptionAr/descriptionEn
- brand
- category
- media
- variants
- averageRating
- isActive

### 6.4 POST /users/{userId}/checkout

Returned fields:

- orderId
- orderNumber
- paymentStatus
- totalAmount
- subOrders[]
- transactionId

### 6.5 GET /users/{userId}/orders/{orderId}

Returned fields:

- id
- orderNumber
- totalAmount
- paymentStatus
- address
- subOrders[]
- trackingTimeline[]

### 6.6 GET /couriers/{id}/orders/{orderId}

Returned fields:

- id
- status
- address
- codAmount
- deliveryProof
- notes

---

## 7. Business Workflow

### 7.1 Authentication Workflow

1. Client submits credentials or OTP request.
2. AuthController validates input.
3. System checks user record and password hash.
4. On success, JWT and refresh token are issued.
5. Refresh token is stored hashed.
6. Client uses access token for protected routes.

### 7.2 Brand Registration and Verification Workflow

1. Guest submits brand registration data.
2. BrandController creates a brand record and links it to a user account.
3. Brand uploads verification documents.
4. Admin verifies, rejects, or suspends the brand.
5. Verification status updates and notifications are dispatched.

### 7.3 Catalog and Product Workflow

1. Brand creates categories.
2. Brand creates products and variants.
3. Product media is uploaded.
4. Product becomes searchable and visible when active.
5. Admin may moderate or disable content.

### 7.4 Cart and Checkout Workflow

1. User adds products to cart.
2. Cart item prices are stored as snapshots.
3. User submits checkout.
4. System validates stock, address, payment method, and discounts.
5. Order and sub-orders are created.
6. Payment intent is created and transaction is recorded.
7. Notifications are sent to user and brand.

### 7.5 Order Fulfillment Workflow

1. Brand receives sub-order.
2. Brand accepts or rejects.
3. If accepted, brand prepares order and hands off to delivery company.
4. Delivery company assigns courier.
5. Courier updates status and submits proof.
6. Order status is updated and customer is notified.

### 7.6 Payment and Payout Workflow

1. Checkout creates transaction record.
2. Gateway webhook updates transaction status.
3. On success, order payment status is marked paid.
4. Brand payout becomes eligible and requires admin approval.
5. Approved payouts are recorded in payout history.

### 7.7 Messaging Workflow

1. User or brand starts a thread.
2. Messages are stored in chat_messages.
3. Notifications are created for the receiver.
4. Admin may moderate flagged content.

### 7.8 Admin Governance Workflow

1. Admin reviews dashboard metrics and queues.
2. Admin resolves disputes, flags, and brand verification requests.
3. Admin audit log captures the action and target.
4. Notifications are sent to affected users or brands.

---

## 8. Validation Rules

### 8.1 Authentication Validation

- phone: required for register/login; format validation
- email: optional; must be valid email if provided
- password: minimum 8 characters; strong policy recommended
- role: enum of admin, sub_admin, brand, end_user, delivery_company, courier

### 8.2 Address Validation

- governorate: required
- street: required
- contactPhone: required
- isDefault: boolean

### 8.3 Brand Validation

- displayName: required
- ownerNationalId and bankIban: optional at registration, required for full verification
- verificationStatus: enum values pending/basic_verified/trusted_verified/suspended

### 8.4 Product Validation

- nameAr/nameEn: required
- brandId: required
- categoryId: optional but must exist when provided
- variants: at least one required on create
- price: positive decimal
- stock: non-negative integer

### 8.5 Order and Checkout Validation

- addressId: required
- paymentMethod: required and must match one of payment_method enum values
- quantity: positive integer
- discount: optional and must be valid

### 8.6 Review Validation

- rating: integer 1-5
- comment: optional but length bounded
- orderItemId: required for purchase-linked reviews

### 8.7 Delivery Validation

- courierId: required for assignment
- status: enum values from sub_order_status
- proof: required for delivered status

---

## 9. Authorization Matrix

| Endpoint Group              | Admin | Sub-admin    | Brand                    | End User                 | Delivery Company | Courier              | Guest                         |
| --------------------------- | ----- | ------------ | ------------------------ | ------------------------ | ---------------- | -------------------- | ----------------------------- |
| Auth register/login/OTP     | No    | No           | No                       | No                       | No               | No                   | Yes                           |
| User profile and addresses  | Yes   | Limited      | No                       | Yes (self)               | No               | No                   | No                            |
| Brand registration/profile  | Yes   | Limited      | Yes (self)               | No                       | No               | No                   | Yes (register/public profile) |
| Catalog browse              | Yes   | Yes          | Yes                      | Yes                      | Yes              | Yes                  | Yes                           |
| Cart and checkout           | Yes   | No           | No                       | Yes (self)               | No               | No                   | No                            |
| Orders and tracking         | Yes   | Limited      | Yes (own brand)          | Yes (self)               | No               | No                   | No                            |
| Delivery company operations | Yes   | Limited      | No                       | No                       | Yes (self)       | No                   | No                            |
| Courier operations          | Yes   | Limited      | No                       | No                       | No               | Yes (self)           | No                            |
| Payments and payouts        | Yes   | Limited      | Yes (own payouts)        | Yes (self)               | No               | No                   | No                            |
| Messaging                   | Yes   | Limited      | Yes (thread participant) | Yes (thread participant) | No               | Yes (if participant) | No                            |
| Admin governance            | Yes   | Yes (scoped) | No                       | No                       | No               | No                   | No                            |

---

## 10. Database Operations

### 10.1 Authentication and Users

- Tables Read: users, refresh_tokens, otp_codes, permissions, user_permissions
- Tables Written: users, refresh_tokens, otp_codes, user_permissions
- Transactions: Preferred for registration and OTP verification flows
- Foreign Keys: users -> user_permissions, refresh_tokens -> users, otp_codes -> users
- Cascade Behavior: user deletion cascades refresh_tokens and permissions

### 10.2 Brands and Catalog

- Tables Read: brands, brand_documents, categories, products, variants, product_media
- Tables Written: brands, brand_documents, categories, products, variants, product_media, product_discounts, ad_campaigns, ranking_scores
- Transactions: Recommended for create/update product flows with media and discounts
- Foreign Keys: products.brand_id -> brands.id, variants.product_id -> products.id
- Cascade Behavior: brand deletion cascades dependent brand records and products

### 10.3 Cart and Checkout

- Tables Read: carts, cart_items, variants, discounts, addresses, users
- Tables Written: carts, cart_items, orders, sub_orders, order_items, transactions, discount_usages
- Transactions: Mandatory for checkout and atomic order creation
- Foreign Keys: cart_items.variant_id -> variants.id, order_items.sub_order_id -> sub_orders.id
- Cascade Behavior: cart deletion cascades cart_items, order deletion cascades sub_orders and order_items

### 10.4 Delivery and Courier

- Tables Read: sub_orders, delivery_companies, delivery_zones, couriers, delivery_proofs, cod_reconciliations
- Tables Written: sub_orders, sub_order_status_history, delivery_proofs, cod_reconciliations
- Transactions: Recommended around status updates and proof submission
- Foreign Keys: sub_orders.delivery_company_id -> delivery_companies.id, sub_orders.courier_id -> couriers.id
- Cascade Behavior: deleting a sub-order cascades history and proofs

### 10.5 Payments and Wallets

- Tables Read: transactions, payouts, wallets, wallet_transactions
- Tables Written: transactions, payouts, wallets, wallet_transactions
- Transactions: Required for wallet and payout updates
- Foreign Keys: wallet_transactions.wallet_id -> wallets.id
- Cascade Behavior: wallet deletion cascades wallet_transactions

### 10.6 Admin Governance

- Tables Read: disputes, moderation_flags, admin_audit_log, ranking_scores
- Tables Written: disputes, dispute_evidence, moderation_flags, admin_audit_log, ranking_scores
- Transactions: Recommended for dispute resolution and ranking override workflows
- Foreign Keys: disputes.raised_by -> users.id, disputes.resolved_by -> users.id
- Cascade Behavior: dispute deletion cascades evidence records

---

## 11. Recommended Backend Folder Structure

```text
src/
  app/
    bootstrap/
    config/
    constants/
    middlewares/
    routes/
    controllers/
    services/
    use-cases/
    validators/
    repositories/
    dto/
    types/
    utils/
    errors/
    events/
    jobs/
    sockets/
    docs/
  prisma/
    schema.prisma
    migrations/
  tests/
    unit/
    integration/
    e2e/
  docs/
```

### 11.1 Module Mapping

- routes/: define router files grouped by domain
- controllers/: expose HTTP request handling
- services/: implement business logic
- validators/: input validation and sanitization
- repositories/: Prisma-based data access wrappers
- jobs/: async worker tasks such as notifications and ranking recalculation
- sockets/: real-time event handling for chat and live order updates
- docs/: OpenAPI and Swagger metadata

---

## 12. Development Notes

### 12.1 General Notes

- All protected routes must require JWT authentication.
- All admin operations must be logged to admin_audit_log.
- All mutations affecting money or order state must be transactional.
- Public endpoints must never expose internal-only data.

### 12.2 Performance Considerations

- Use pagination for list endpoints.
- Materialize ranking scores instead of computing them on request.
- Avoid N+1 queries in product listings, order history, and admin dashboards.

### 12.3 Security Considerations

- Hash passwords and refresh tokens.
- Validate all input server-side.
- Restrict file uploads to approved MIME types.
- Enforce ownership and role-based access control consistently.
- Use rate limiting on auth and payment webhook endpoints.

### 12.4 Edge Cases

- Duplicate OTP requests
- Invalid checkout address
- Payment webhook replay
- Existing wishlist item re-add
- Brand verification state transitions
- Order transitions from invalid states
- Delivery proof submitted for the wrong sub-order

### 12.5 Possible Improvements

- Add event-driven notifications via queue workers.
- Add soft-delete and audit layers to all domain entities.
- Add idempotency keys for payment and webhook flows.
- Add role-scoped permission checks for sub-admin accounts.

---

## 13. Implementation Readiness Summary

This functional specification covers the full backend contract required to implement the FashionConnect platform in a consistent, modular, and production-ready manner. It includes:

- complete router and controller responsibilities
- endpoint inventories
- response contracts
- validation and authorization behavior
- workflow design
- database interaction expectations
- deployment and development structure guidance
