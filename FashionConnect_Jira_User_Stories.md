# FashionConnect Jira User Stories

## Epic 1: Authentication & Identity

### US-001: User can register a new account
- As a guest user,
- I want to register a new account with my role, name, phone, and password,
- so that I can access the platform.

#### Acceptance Criteria
- A user can register as end_user, brand, delivery_company, or courier.
- Required fields are validated.
- Password is securely hashed.
- A successful registration returns user details and JWT tokens.
- Duplicate phone numbers are rejected.

---

### US-002: User can log in securely
- As a registered user,
- I want to log in using my phone or email and password,
- so that I can access my account.

#### Acceptance Criteria
- Login accepts either email or phone.
- Valid credentials return access and refresh tokens.
- Invalid credentials return an authentication error.
- Passwords are not returned in responses.

---

### US-003: User can verify OTP
- As a user,
- I want to verify an OTP sent to my phone or email,
- so that I can complete identity verification.

#### Acceptance Criteria
- OTP is accepted only if it is valid and not expired.
- Invalid or expired OTP returns an error.
- Successful verification updates the account state.

---

### US-004: User can refresh authentication tokens
- As an authenticated user,
- I want to refresh my access token,
- so that I can stay signed in without re-authenticating.

#### Acceptance Criteria
- Valid refresh tokens issue a new access token.
- Invalid or revoked refresh tokens are rejected.
- Old tokens are invalidated where appropriate.

---

### US-005: User can log out
- As an authenticated user,
- I want to log out,
- so that my session is terminated securely.

#### Acceptance Criteria
- Logout invalidates the current session.
- Subsequent requests with the old token are rejected.
- The operation returns a success response.

---

## Epic 2: User Profiles & Addresses

### US-006: User can view their profile
- As an authenticated user,
- I want to view my profile details,
- so that I can manage my account information.

#### Acceptance Criteria
- The authenticated user can retrieve their own profile.
- Profile data is returned in a consistent structure.
- Unauthorized access is blocked.

---

### US-007: User can update their profile
- As an authenticated user,
- I want to update my profile information,
- so that my account details stay current.

#### Acceptance Criteria
- Supported profile fields can be updated.
- Role and ownership fields cannot be changed through this endpoint.
- The updated profile is returned in the response.

---

### US-008: User can manage delivery addresses
- As an authenticated user,
- I want to create, update, and delete delivery addresses,
- so that I can use them for checkout.

#### Acceptance Criteria
- A user can create a new address.
- A user can update an existing address.
- A user can delete an address.
- Only one address can be marked as default.

---

## Epic 3: Brand Onboarding

### US-009: Brand can register and start onboarding
- As a brand owner,
- I want to register a brand account and start onboarding,
- so that I can sell on the platform.

#### Acceptance Criteria
- Brand registration creates a brand record and onboarding state.
- Required business details are validated.
- The response includes brand onboarding information.

---

### US-010: Brand can upload verification documents
- As a brand owner,
- I want to upload verification documents,
- so that my brand can be reviewed and approved.

#### Acceptance Criteria
- Files can be uploaded through the API.
- File type and size are validated.
- Upload success returns a file reference or URL.

---

### US-011: Brand can view verification status
- As a brand owner,
- I want to view my verification status,
- so that I know whether my account is approved or pending review.

#### Acceptance Criteria
- The current verification state is returned.
- The response includes review-related details when applicable.
- Unauthorized users cannot access private verification data.

---

### US-012: Public users can view approved brand profiles
- As a guest or customer,
- I want to view public brand profiles,
- so that I can discover brands on the platform.

#### Acceptance Criteria
- Approved brands are returned through the public profile endpoint.
- Unapproved brands are not exposed publicly.
- The response structure is consistent and safe for public consumption.

---

## Epic 4: Catalog Management

### US-013: Brand can manage categories
- As a brand owner or admin,
- I want to create, update, and delete categories,
- so that I can organize products in my catalog.

#### Acceptance Criteria
- Categories can be listed.
- New categories can be created.
- Existing categories can be updated.
- Categories can be deleted safely using soft-delete or safe reassignment rules.

---

### US-014: Brand can create and manage products
- As a brand owner,
- I want to create, update, and delete products,
- so that I can manage my catalog.

#### Acceptance Criteria
- Products can be created with variants, pricing, stock, and media.
- Existing products can be updated.
- Products can be deleted safely.
- Product ownership is enforced.

---

### US-015: Brand can bulk import products
- As a brand owner,
- I want to import multiple products in one request,
- so that I can onboard inventory efficiently.

#### Acceptance Criteria
- A batch of products can be imported.
- Validation errors are returned clearly.
- The API returns a summary of imported records.

---

### US-016: Admin or brand can view low-stock products
- As a brand owner or admin,
- I want to view products that are running low on stock,
- so that I can restock inventory in time.

#### Acceptance Criteria
- Low-stock products are returned in a dedicated endpoint.
- Filters and thresholds can be applied.
- The response contains the relevant product and stock details.

---

## Epic 5: Wishlist

### US-017: User can manage wishlist items
- As an authenticated user,
- I want to add and remove products from my wishlist,
- so that I can save items I want to buy later.

#### Acceptance Criteria
- A user can list wishlist items.
- A user can add a product to the wishlist.
- A user can remove a product from the wishlist.
- Duplicate wishlist entries are prevented.

---

## Epic 6: Cart & Checkout

### US-018: User can manage cart items
- As an authenticated user,
- I want to add, update, and remove items in my cart,
- so that I can prepare for checkout.

#### Acceptance Criteria
- The cart can be retrieved.
- Items can be added with quantities.
- Quantities can be updated.
- Items can be removed.
- Stock validation is enforced.

---

### US-019: User can place an order from the cart
- As an authenticated user,
- I want to create a checkout and place an order,
- so that I can purchase selected items.

#### Acceptance Criteria
- Checkout creates an order and sub-orders for each brand.
- Address and payment details are validated.
- Stock and discounts are validated.
- A payment intent is created for supported payment methods.

---

## Epic 7: Orders & Returns

### US-020: User can view order history
- As an authenticated user,
- I want to view my orders and order details,
- so that I can track my purchases.

#### Acceptance Criteria
- Orders can be listed.
- Order details can be retrieved.
- The response is scoped to the authenticated user or admin.

---

### US-021: User can track order progress
- As an authenticated user,
- I want to view the tracking timeline of my order,
- so that I can follow fulfillment progress.

#### Acceptance Criteria
- The tracking timeline is returned for an order.
- Status history is shown in chronological order.
- Unauthorized access is blocked.

---

### US-022: User can request a return
- As an authenticated user,
- I want to create a return request for an order,
- so that I can return an item if needed.

#### Acceptance Criteria
- A return request can be submitted for eligible orders.
- The request contains a reason and optional details.
- Invalid or ineligible orders are rejected.

---

## Epic 8: Brand Order Management

### US-023: Brand can manage incoming orders
- As a brand owner,
- I want to view and manage incoming sub-orders,
- so that I can fulfill customer orders.

#### Acceptance Criteria
- The brand can list incoming orders.
- The brand can accept or reject a sub-order.
- The brand can hand off accepted orders to delivery.
- Status transitions are validated.

---

## Epic 9: Reviews

### US-024: Customer can review products
- As a customer,
- I want to submit a review for a purchased product,
- so that I can share my experience.

#### Acceptance Criteria
- Reviews can be submitted for completed purchases.
- Required review fields are validated.
- Review creation returns the created review object.

---

### US-025: Customer can review brands
- As a customer,
- I want to submit a review for a brand,
- so that I can provide feedback on the brand experience.

#### Acceptance Criteria
- Reviews can be submitted for a brand.
- Required fields are validated.
- The API stores the review and returns the created record.

---

## Epic 10: Delivery & Courier Operations

### US-026: Delivery company can receive shipment updates
- As a delivery company,
- I want to receive delivery webhooks,
- so that order status updates are reflected in the platform.

#### Acceptance Criteria
- Webhook payloads are accepted securely.
- Duplicate events are handled safely.
- Order status is updated based on the webhook payload.

---

### US-027: Delivery company can manage assigned orders
- As a delivery company,
- I want to list and assign orders to couriers,
- so that deliveries can be coordinated efficiently.

#### Acceptance Criteria
- Orders can be listed for the company.
- Couriers can be assigned to orders.
- Assignment rules are validated.

---

### US-028: Courier can update delivery status
- As a courier,
- I want to update the delivery status of assigned orders,
- so that customers can see real-time progress.

#### Acceptance Criteria
- The courier can update the status of assigned orders.
- Status transitions are validated.
- The updated status is returned to the client.

---

### US-029: Courier can submit proof of delivery
- As a courier,
- I want to upload proof of delivery,
- so that delivery completion is documented.

#### Acceptance Criteria
- Proof can be uploaded for a completed delivery.
- The API stores and returns a proof reference.
- Missing proof blocks successful completion where required.

---

## Epic 11: Payments, Wallets & Payouts

### US-030: User can create a payment intent
- As a customer,
- I want to create a payment intent for checkout,
- so that I can complete payment securely.

#### Acceptance Criteria
- Payment intents are created for supported payment methods.
- Required payment fields are validated.
- The response includes payment intent details.

---

### US-031: Platform can receive payment webhooks
- As a payment processor integration,
- I want to receive Stripe and Paymob webhooks,
- so that payment statuses are synchronized.

#### Acceptance Criteria
- Webhook payloads are accepted.
- Events are processed idempotently.
- Payment state changes are reflected correctly.

---

### US-032: User can view wallet balance and transactions
- As a user or brand,
- I want to view my wallet balance and transaction history,
- so that I can track financial activity.

#### Acceptance Criteria
- Wallet balance is returned.
- Transaction history can be listed.
- The data is scoped to the authenticated account.

---

### US-033: Admin can approve payouts
- As an admin,
- I want to approve brand payouts,
- so that funds can be released securely.

#### Acceptance Criteria
- Pending payouts can be listed.
- Admin approval updates payout status.
- Audit records are created for the action.

---

## Epic 12: Messaging & Notifications

### US-034: User can start a chat thread
- As a customer or brand,
- I want to create a chat thread,
- so that I can communicate with each other.

#### Acceptance Criteria
- A thread can be created between a valid user and brand.
- The API returns the created thread identifier.
- Participants are linked correctly.

---

### US-035: User can send and view messages
- As a participant in a chat,
- I want to send messages and view message history,
- so that I can communicate within the thread.

#### Acceptance Criteria
- Messages can be listed for a thread.
- New messages can be created.
- Authorization ensures only participants can access the thread.

---

### US-036: User can report chat content
- As a chat participant,
- I want to report inappropriate content,
- so that moderation can review it.

#### Acceptance Criteria
- A report can be created for a message or thread.
- The reason is validated.
- The API returns a report identifier.

---

### US-037: User can view and mark notifications as read
- As an authenticated user,
- I want to view my notifications and mark them as read,
- so that I can manage updates from the platform.

#### Acceptance Criteria
- Notifications can be listed.
- Notifications can be marked as read.
- Access is scoped to the authenticated user.

---

## Epic 13: Admin Governance

### US-038: Admin can view platform dashboard
- As an admin or sub-admin,
- I want to view platform dashboard metrics,
- so that I can monitor business health and operations.

#### Acceptance Criteria
- Dashboard metrics are returned for the requested date range.
- The endpoint is restricted to authorized admin roles.
- The response includes core KPIs such as GMV and active users.

---

### US-039: Admin can review brands and manage verification
- As an admin,
- I want to review brands and change their verification status,
- so that the marketplace remains trustworthy.

#### Acceptance Criteria
- Brands can be listed for review.
- Admin can verify, reject, or suspend a brand.
- Audit logs are created for each action.

---

### US-040: Admin can resolve disputes
- As an admin,
- I want to resolve disputes,
- so that customer issues are handled consistently.

#### Acceptance Criteria
- A dispute can be resolved with an outcome and optional refund amount.
- The action is logged for audit purposes.
- The response confirms the dispute outcome.

---

## Epic 14: File Uploads

### US-041: User can upload files
- As an authenticated user or brand,
- I want to upload files,
- so that I can attach documents, media, and proof of delivery.

#### Acceptance Criteria
- Files can be uploaded through the API.
- Allowed file types and size limits are enforced.
- The response returns a file identifier or accessible URL.

---

## Suggested Jira fields
- Summary: User can register a new account
- Issue Type: Story
- Priority: High
- Labels: backend, auth, api
- Acceptance Criteria: Included above
- Epic Link: Authentication & Identity
