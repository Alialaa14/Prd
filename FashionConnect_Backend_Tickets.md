# FashionConnect Backend Implementation Tickets

This document converts the API contract and backend functional spec into a practical backlog of implementation tickets for controllers and routers.

## Ticket Format

Each ticket includes:
- Controller
- Endpoint
- Description
- Required input
- Expected return response
- Notes / business rules

---

## Epic 1: Authentication & Identity

### Ticket A1 — Auth: Register Account
- Endpoint: POST /api/v1/auth/register
- Description: Create a new user account for end users, brands, delivery companies, or couriers and issue authentication tokens.
- Required input:
  - role (required): end_user | brand | delivery_company | courier
  - name (required)
  - phone (required)
  - password (required)
  - email (optional)
  - brandProfile (optional)
- Return response:
  - 201: success with user object, accessToken, refreshToken
- Notes:
  - Password must be hashed.
  - Phone must be unique and valid.

### Ticket A2 — Auth: Login
- Endpoint: POST /api/v1/auth/login
- Description: Authenticate a user with phone/email and password.
- Required input:
  - login (required)
  - password (required)
- Return response:
  - 200: success with accessToken, refreshToken, user summary
- Notes:
  - Accept either email or phone.

### Ticket A3 — Auth: Send OTP
- Endpoint: POST /api/v1/auth/otp/send
- Description: Send a one-time password to the user for verification.
- Required input:
  - phone or email (required)
- Return response:
  - 200 or 201: success message and OTP delivery status
- Notes:
  - OTP should be short-lived and single-use.

### Ticket A4 — Auth: Verify OTP
- Endpoint: POST /api/v1/auth/otp/verify
- Description: Verify the OTP submitted by the user.
- Required input:
  - phone/email (required)
  - otp (required)
- Return response:
  - 200: success with verification status
- Notes:
  - Expired or invalid OTP should fail.

### Ticket A5 — Auth: Refresh Token
- Endpoint: POST /api/v1/auth/refresh
- Description: Issue a new access token using a valid refresh token.
- Required input:
  - refreshToken (required)
- Return response:
  - 200: success with new accessToken and refreshToken
- Notes:
  - Must validate token and revoke old token if needed.

### Ticket A6 — Auth: Logout
- Endpoint: POST /api/v1/auth/logout
- Description: Invalidate the current session and revoke refresh tokens.
- Required input:
  - current access token or refresh token context
- Return response:
  - 200: success confirmation
- Notes:
  - Must clear session state.

---

## Epic 2: User Profiles & Addresses

### Ticket U1 — User Profile: Get Current Profile
- Endpoint: GET /api/v1/users/me
- Description: Return the authenticated user profile.
- Required input:
  - None beyond auth context
- Return response:
  - 200: success with user profile data
- Notes:
  - Must enforce authentication.

### Ticket U2 — User Profile: Update Current Profile
- Endpoint: PATCH /api/v1/users/me
- Description: Update profile fields for the current user.
- Required input:
  - profile fields such as name, email, avatar, preferences
- Return response:
  - 200: success with updated profile
- Notes:
  - Role and ownership must not change.

### Ticket U3 — User Profile: List Addresses
- Endpoint: GET /api/v1/users/addresses
- Description: List all addresses belonging to the current user.
- Required input:
  - None
- Return response:
  - 200: success with list of addresses
- Notes:
  - Only one default address is allowed.

### Ticket U4 — User Profile: Create Address
- Endpoint: POST /api/v1/users/addresses
- Description: Create a new delivery address for the user.
- Required input:
  - street, city, state, country, postalCode, phone, label, isDefault (optional)
- Return response:
  - 201: success with created address object
- Notes:
  - If marked default, existing default must be updated.

### Ticket U5 — User Profile: Update Address
- Endpoint: PATCH /api/v1/users/addresses/{addressId}
- Description: Update an existing address.
- Required input:
  - address fields to change
- Return response:
  - 200: success with updated address
- Notes:
  - Ownership must be verified.

### Ticket U6 — User Profile: Delete Address
- Endpoint: DELETE /api/v1/users/addresses/{addressId}
- Description: Delete a user address.
- Required input:
  - addressId in path
- Return response:
  - 200 or 204: success confirmation
- Notes:
  - Must prevent deletion of the only remaining default address unless reassigned.

---

## Epic 3: Brand Onboarding & Verification

### Ticket B1 — Brand: Register Brand
- Endpoint: POST /api/v1/brands/register
- Description: Register a new brand account and start onboarding.
- Required input:
  - brandName, owner details, contact info, brandProfile
- Return response:
  - 201: success with brand record and onboarding state
- Notes:
  - Must support verification lifecycle.

### Ticket B2 — Brand: Upload Brand Documents
- Endpoint: POST /api/v1/brands/documents
- Description: Upload verification documents for the brand.
- Required input:
  - file(s) and document metadata
- Return response:
  - 201: success with uploaded document metadata
- Notes:
  - Must validate file type and size.

### Ticket B3 — Brand: Get Verification Status
- Endpoint: GET /api/v1/brands/me/verification
- Description: Return the current verification state of the brand.
- Required input:
  - None
- Return response:
  - 200: success with verification status and review details
- Notes:
  - Only owner/admin should access private status.

### Ticket B4 — Brand: Get Public Brand Profile
- Endpoint: GET /api/v1/brands/{brandId}/public
- Description: Return public brand profile information for approved brands.
- Required input:
  - brandId in path
- Return response:
  - 200: success with public profile data
- Notes:
  - Only approved brands should be visible publicly.

### Ticket B5 — Brand: Update Brand Profile
- Endpoint: PATCH /api/v1/brands/me
- Description: Update brand profile information.
- Required input:
  - profile fields such as description, social links, logo, business info
- Return response:
  - 200: success with updated profile
- Notes:
  - Must enforce ownership.

---

## Epic 4: Categories

### Ticket C1 — Category: List Categories
- Endpoint: GET /api/v1/categories
- Description: List categories available to the authenticated brand or public consumer.
- Required input:
  - None
- Return response:
  - 200: success with category list
- Notes:
  - Must support parent/child hierarchy if applicable.

### Ticket C2 — Category: Create Category
- Endpoint: POST /api/v1/categories
- Description: Create a new category for a brand.
- Required input:
  - name (required), parentId (optional), description (optional)
- Return response:
  - 201: success with created category object
- Notes:
  - Validate parent category if provided.

### Ticket C3 — Category: Update Category
- Endpoint: PATCH /api/v1/categories/{categoryId}
- Description: Update category details.
- Required input:
  - updated category fields
- Return response:
  - 200: success with updated category
- Notes:
  - Must enforce ownership/admin access.

### Ticket C4 — Category: Delete Category
- Endpoint: DELETE /api/v1/categories/{categoryId}
- Description: Soft-delete or remove a category safely.
- Required input:
  - categoryId in path
- Return response:
  - 200 or 204: success confirmation
- Notes:
  - Preserve data integrity and references.

---

## Epic 5: Products & Variants

### Ticket P1 — Product: List Products
- Endpoint: GET /api/v1/products
- Description: Retrieve products for public browsing or brand-owned catalog.
- Required input:
  - query params such as search, category, brand, page, limit
- Return response:
  - 200: success with product list
- Notes:
  - Public listing should be available for approved content.

### Ticket P2 — Product: Create Product
- Endpoint: POST /api/v1/products
- Description: Create a product and its initial variants.
- Required input:
  - name, description, price, categoryId, brandId, variants, stock, media
- Return response:
  - 201: success with created product data
- Notes:
  - Validate variant payload and stock values.

### Ticket P3 — Product: Update Product
- Endpoint: PATCH /api/v1/products/{productId}
- Description: Update product details and related metadata.
- Required input:
  - updated product fields
- Return response:
  - 200: success with updated product
- Notes:
  - Ownership and permission checks are required.

### Ticket P4 — Product: Delete Product
- Endpoint: DELETE /api/v1/products/{productId}
- Description: Remove a product from the catalog safely.
- Required input:
  - productId in path
- Return response:
  - 200 or 204: success confirmation
- Notes:
  - Use soft-delete semantics.

### Ticket P5 — Product: Bulk Import Products
- Endpoint: POST /api/v1/products/import
- Description: Import multiple products in one request.
- Required input:
  - array of product payloads
- Return response:
  - 201: success with imported item count and summary
- Notes:
  - Validate all rows before commit.

### Ticket P6 — Product: List Low Stock Products
- Endpoint: GET /api/v1/products/low-stock
- Description: List products that are below the configured stock threshold.
- Required input:
  - None or optional filters
- Return response:
  - 200: success with low-stock products
- Notes:
  - Useful for inventory management.

---

## Epic 6: Wishlist

### Ticket W1 — Wishlist: List Wishlist
- Endpoint: GET /api/v1/wishlist
- Description: Retrieve the current user’s wishlist.
- Required input:
  - None
- Return response:
  - 200: success with items array
- Notes:
  - Must be scoped to the authenticated user.

### Ticket W2 — Wishlist: Add to Wishlist
- Endpoint: POST /api/v1/wishlist
- Description: Add a product to the current user’s wishlist.
- Required input:
  - productId (required)
- Return response:
  - 201: success with wishlist item data
- Notes:
  - Prevent duplicate entries.

### Ticket W3 — Wishlist: Remove from Wishlist
- Endpoint: DELETE /api/v1/wishlist/{productId}
- Description: Remove a product from the wishlist.
- Required input:
  - productId in path
- Return response:
  - 200 or 204: success confirmation
- Notes:
  - Ownership must be enforced.

---

## Epic 7: Cart

### Ticket T1 — Cart: Get Cart
- Endpoint: GET /api/v1/cart
- Description: Retrieve the current user’s cart with all items and price snapshots.
- Required input:
  - None
- Return response:
  - 200: success with cart object
- Notes:
  - Must return current pricing and availability context.

### Ticket T2 — Cart: Add Cart Item
- Endpoint: POST /api/v1/cart/items
- Description: Add a product variant to the current cart.
- Required input:
  - variantId (required), quantity (required)
- Return response:
  - 201: success with cart item object
- Notes:
  - Validate stock availability.

### Ticket T3 — Cart: Update Cart Item
- Endpoint: PATCH /api/v1/cart/items/{itemId}
- Description: Update the quantity of an existing cart item.
- Required input:
  - quantity (required)
- Return response:
  - 200: success with updated cart item
- Notes:
  - Must reject invalid or unavailable quantities.

### Ticket T4 — Cart: Remove Cart Item
- Endpoint: DELETE /api/v1/cart/items/{itemId}
- Description: Remove an item from the cart.
- Required input:
  - itemId in path
- Return response:
  - 200 or 204: success confirmation
- Notes:
  - Ownership must be enforced.

---

## Epic 8: Checkout

### Ticket O1 — Checkout: Create Checkout
- Endpoint: POST /api/v1/checkout
- Description: Convert the user cart into a checkout order, split into brand sub-orders, and prepare payment.
- Required input:
  - addressId, paymentMethod, coupon/discount if applicable
- Return response:
  - 201: success with checkout/order summary and payment intent info
- Notes:
  - Must be atomic and validate stock, address, and payment method.

---

## Epic 9: Orders & Tracking

### Ticket OR1 — Order: List Orders
- Endpoint: GET /api/v1/orders
- Description: List orders for the current user.
- Required input:
  - None or query filters
- Return response:
  - 200: success with orders list
- Notes:
  - Must enforce ownership/admin access.

### Ticket OR2 — Order: Get Order Detail
- Endpoint: GET /api/v1/orders/{orderId}
- Description: Retrieve order details and item breakdown.
- Required input:
  - orderId in path
- Return response:
  - 200: success with order details
- Notes:
  - Includes tracking and fulfillment state.

### Ticket OR3 — Order: Get Tracking Timeline
- Endpoint: GET /api/v1/orders/{orderId}/tracking
- Description: Return shipment and status history for an order.
- Required input:
  - orderId in path
- Return response:
  - 200: success with tracking timeline
- Notes:
  - Useful for customer-facing order tracking.

### Ticket OR4 — Order: Create Return Request
- Endpoint: POST /api/v1/orders/{orderId}/returns
- Description: Create a return request for a purchased order.
- Required input:
  - reason, optional images or notes
- Return response:
  - 201: success with return request object
- Notes:
  - Must validate order status and ownership.

---

## Epic 10: Brand Order Management

### Ticket BO1 — Brand Order: List Incoming Orders
- Endpoint: GET /api/v1/brands/orders
- Description: Return incoming sub-orders that belong to the current brand.
- Required input:
  - None
- Return response:
  - 200: success with incoming orders list
- Notes:
  - Enforce brand ownership.

### Ticket BO2 — Brand Order: Accept Order
- Endpoint: PATCH /api/v1/brands/orders/{subOrderId}/accept
- Description: Accept a sub-order for fulfillment.
- Required input:
  - subOrderId in path
- Return response:
  - 200: success with updated sub-order status
- Notes:
  - Follow status transition rules.

### Ticket BO3 — Brand Order: Reject Order
- Endpoint: PATCH /api/v1/brands/orders/{subOrderId}/reject
- Description: Reject a brand-side sub-order.
- Required input:
  - reason (required)
- Return response:
  - 200: success with rejected order status
- Notes:
  - Must log the decision and notify stakeholders.

### Ticket BO4 — Brand Order: Hand Off to Delivery
- Endpoint: PATCH /api/v1/brands/orders/{subOrderId}/handoff
- Description: Hand off an accepted order to the delivery workflow.
- Required input:
  - subOrderId in path
- Return response:
  - 200: success with handoff confirmation
- Notes:
  - Must validate handoff readiness.

---

## Epic 11: Reviews

### Ticket R1 — Review: Submit Product Review
- Endpoint: POST /api/v1/reviews/products
- Description: Submit a review for a purchased product.
- Required input:
  - productId, rating, comment, optional images
- Return response:
  - 201: success with review object
- Notes:
  - Only completed purchases should be eligible.

### Ticket R2 — Review: Submit Brand Review
- Endpoint: POST /api/v1/reviews/brands
- Description: Submit a review for a brand.
- Required input:
  - brandId, rating, comment
- Return response:
  - 201: success with review object
- Notes:
  - Must be based on a completed customer experience.

---

## Epic 12: Delivery Company Operations

### Ticket D1 — Delivery Company: Receive Order Webhook
- Endpoint: POST /api/v1/delivery/webhook
- Description: Receive partner webhook events for orders and tracking updates.
- Required input:
  - webhook payload from delivery provider
- Return response:
  - 200 or 202: success acknowledgment
- Notes:
  - Must be idempotent.

### Ticket D2 — Delivery Company: List Orders
- Endpoint: GET /api/v1/delivery/orders
- Description: List orders assigned to or managed by a delivery company.
- Required input:
  - None
- Return response:
  - 200: success with orders list
- Notes:
  - Scope should be company-specific.

### Ticket D3 — Delivery Company: Assign Courier
- Endpoint: POST /api/v1/delivery/orders/{orderId}/assign-courier
- Description: Assign a courier to a delivery order.
- Required input:
  - courierId, optional assignment metadata
- Return response:
  - 200: success with assignment result
- Notes:
  - Must validate courier eligibility.

### Ticket D4 — Delivery Company: Configure Auto-Assignment Rules
- Endpoint: POST /api/v1/delivery/auto-assignment
- Description: Configure delivery auto-assignment rules for the company.
- Required input:
  - assignment rules payload
- Return response:
  - 201 or 200: success with configured rule set
- Notes:
  - Useful for operational automation.

---

## Epic 13: Courier Workflows

### Ticket CR1 — Courier: List Assigned Orders
- Endpoint: GET /api/v1/couriers/orders
- Description: Return all orders assigned to the current courier.
- Required input:
  - None
- Return response:
  - 200: success with assigned orders
- Notes:
  - Must restrict to assigned orders only.

### Ticket CR2 — Courier: Get Assigned Order Detail
- Endpoint: GET /api/v1/couriers/orders/{orderId}
- Description: Retrieve full detail for a single assigned order.
- Required input:
  - orderId in path
- Return response:
  - 200: success with assigned order details
- Notes:
  - Must enforce courier ownership.

### Ticket CR3 — Courier: Update Delivery Status
- Endpoint: PATCH /api/v1/couriers/orders/{orderId}/status
- Description: Update delivery progress status for an assigned order.
- Required input:
  - status (required), optional notes
- Return response:
  - 200: success with updated status
- Notes:
  - Status transitions must be validated.

### Ticket CR4 — Courier: Submit Proof of Delivery
- Endpoint: POST /api/v1/couriers/orders/{orderId}/proof
- Description: Upload delivery proof for the completed handoff.
- Required input:
  - proof file and metadata
- Return response:
  - 201: success with proof reference
- Notes:
  - Proof is required for successful delivery completion.

---

## Epic 14: Payments

### Ticket PM1 — Payment: Create Payment Intent
- Endpoint: POST /api/v1/payments/intents
- Description: Create a payment intent for checkout or order payment.
- Required input:
  - amount, currency, paymentMethod, orderId or checkout context
- Return response:
  - 201: success with payment intent details
- Notes:
  - Must be idempotent.

### Ticket PM2 — Payment: Stripe Webhook
- Endpoint: POST /api/v1/payments/webhooks/stripe
- Description: Receive and process Stripe webhook events.
- Required input:
  - Stripe webhook payload
- Return response:
  - 200: success acknowledgment
- Notes:
  - Must be secure and event-idempotent.

### Ticket PM3 — Payment: Paymob Webhook
- Endpoint: POST /api/v1/payments/webhooks/paymob
- Description: Receive and process Paymob webhook events.
- Required input:
  - Paymob webhook payload
- Return response:
  - 200: success acknowledgment
- Notes:
  - Must reconcile payment state correctly.

---

## Epic 15: Wallets

### Ticket WL1 — Wallet: Get Wallet Balance
- Endpoint: GET /api/v1/wallets/me
- Description: Return the current user or brand wallet balance.
- Required input:
  - None
- Return response:
  - 200: success with wallet balance data
- Notes:
  - Balances should be derived from ledger events.

### Ticket WL2 — Wallet: Get Wallet Transactions
- Endpoint: GET /api/v1/wallets/me/transactions
- Description: List wallet transaction history.
- Required input:
  - None or pagination filters
- Return response:
  - 200: success with transaction list
- Notes:
  - Must support financial traceability.

---

## Epic 16: Payouts

### Ticket PY1 — Payout: List Brand Payouts
- Endpoint: GET /api/v1/payouts
- Description: List payouts belonging to the current brand.
- Required input:
  - None
- Return response:
  - 200: success with payouts list
- Notes:
  - Support pending and completed states.

### Ticket PY2 — Payout: Approve Payout
- Endpoint: PATCH /api/v1/payouts/{payoutId}/approve
- Description: Approve a payout request for admin review.
- Required input:
  - payoutId in path
- Return response:
  - 200: success with approved payout confirmation
- Notes:
  - Requires admin authorization and audit logging.

---

## Epic 17: Chats

### Ticket CH1 — Chat: Create Chat Thread
- Endpoint: POST /api/v1/chats
- Description: Start a chat thread between a user and a brand.
- Required input:
  - brandId (required)
- Return response:
  - 201: success with threadId
- Notes:
  - Notify the counterpart.

### Ticket CH2 — Chat: List Messages
- Endpoint: GET /api/v1/chats/{threadId}/messages
- Description: Retrieve all messages in a given thread.
- Required input:
  - threadId in path
- Return response:
  - 200: success with messages list
- Notes:
  - Must enforce participant authorization.

### Ticket CH3 — Chat: Send Message
- Endpoint: POST /api/v1/chats/{threadId}/messages
- Description: Send a message in an existing thread.
- Required input:
  - content (required)
- Return response:
  - 201: success with messageId
- Notes:
  - Create notification events asynchronously.

### Ticket CH4 — Chat: Report Thread or Message
- Endpoint: POST /api/v1/chats/{threadId}/report
- Description: Report abusive or suspicious content.
- Required input:
  - reason (required), optional messageId
- Return response:
  - 201: success with reportId
- Notes:
  - Must be routed to moderation.

---

## Epic 18: Notifications

### Ticket N1 — Notification: List Notifications
- Endpoint: GET /api/v1/notifications
- Description: List notifications for the current user.
- Required input:
  - None
- Return response:
  - 200: success with notifications list
- Notes:
  - Must be scoped to the authenticated identity.

### Ticket N2 — Notification: Mark Notification as Read
- Endpoint: PATCH /api/v1/notifications/{id}/read
- Description: Mark a notification as read.
- Required input:
  - notificationId in path
- Return response:
  - 200: success confirmation
- Notes:
  - Must enforce ownership.

---

## Epic 19: Admin Governance

### Ticket AD1 — Admin: Get Platform Dashboard
- Endpoint: GET /api/v1/admin/dashboard
- Description: Return platform KPIs and operational summaries.
- Required input:
  - optional dateFrom, dateTo, granularity query params
- Return response:
  - 200: success with dashboard metrics
- Notes:
  - Must be restricted to admin or sub-admin.

### Ticket AD2 — Admin: List Brands for Review
- Endpoint: GET /api/v1/admin/brands
- Description: Retrieve brands requiring review or governance actions.
- Required input:
  - None
- Return response:
  - 200: success with brands list
- Notes:
  - Required for verification and moderation.

### Ticket AD3 — Admin: Verify, Reject, or Suspend Brand
- Endpoint: PATCH /api/v1/admin/brands/{brandId}/verify or /reject or /suspend
- Description: Update brand verification or status.
- Required input:
  - tier or reason depending on action
- Return response:
  - 200: success with updated brandId
- Notes:
  - Must log admin audit action and notify the brand.

### Ticket AD4 — Admin: List Payouts for Review
- Endpoint: GET /api/v1/admin/payouts
- Description: Retrieve payouts pending review or oversight.
- Required input:
  - None
- Return response:
  - 200: success with payouts list
- Notes:
  - Admin-only view.

### Ticket AD5 — Admin: Resolve Disputes
- Endpoint: PATCH /api/v1/admin/disputes/{disputeId}/resolve
- Description: Resolve a dispute and record the outcome.
- Required input:
  - outcome (required), refundAmount (optional), notes (optional)
- Return response:
  - 200: success with disputeId
- Notes:
  - Must create audit trail and potentially process refund.

---

## Epic 20: File Uploads

### Ticket UP1 — Upload: Upload File
- Endpoint: POST /api/v1/uploads
- Description: Upload a file for profile images, documents, product media, or delivery proof.
- Required input:
  - multipart/form-data file and metadata
- Return response:
  - 201: success with fileId and public/signed URL
- Notes:
  - Must validate size and allowed file types.

---

## Suggested Implementation Order

1. Authentication & identity
2. User profile and addresses
3. Brand onboarding
4. Catalog management
5. Wishlist and cart
6. Checkout and orders
7. Delivery and courier workflow
8. Payments, wallets, payouts
9. Messaging and notifications
10. Admin governance and uploads

---

## Recommended Ticket Fields for Jira / Azure DevOps

For each ticket, add:
- Title
- Description
- Acceptance Criteria
- Endpoint
- Required Input
- Expected Response
- Role/Authorization
- Priority
- Story Points
