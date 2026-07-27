# FashionConnect — Project Documentation

## Phase 1: Project Overview

## 1. Executive Summary

FashionConnect is a multi-role e-commerce and fulfillment platform designed for the Egyptian market with a strong emphasis on local payment behaviors, delivery logistics, trust, and operational control. The platform serves three core business constituencies:

- End-users who browse products, place orders, track deliveries, and interact with brands.
- Brands that manage catalogues, inventory, fulfillment, advertising, and payouts.
- Operational partners such as delivery companies and couriers that execute last-mile delivery and reconciliation.

The business model is a marketplace-style platform where brands sell through FashionConnect, the platform handles discovery, payments, order orchestration, delivery handoff, dispute handling, and admin governance. The platform must support both digital payments and cash-on-delivery (COD), which is a core requirement in the Egyptian market. This requirement materially affects the architecture, especially for payments, reconciliation, fraud prevention, and operational workflows.

The documentation provided here is intended to be the single source of truth for product, engineering, QA, DevOps, design, and business stakeholders. It aligns the business rationale from the supplied BA spec with the implemented data model and API design direction.

### Product Positioning

FashionConnect is not a simple storefront platform. It is a marketplace operating system that combines:

- Commerce transactions
- Brand verification and trust management
- Delivery orchestration
- Payment routing and settlement
- Admin governance and moderation
- Notification and communication flows

### Strategic Intent

The platform is designed to reduce friction across the complete commerce lifecycle:

1. Brand onboarding and verification
2. Product discovery and purchase
3. Order fulfillment
4. Delivery execution
5. Customer support and dispute resolution
6. Financial reconciliation and payout oversight

### Architectural Direction

The supplied schema and API direction indicate a modular SaaS architecture using:

- RESTful APIs
- Role-based authentication and authorization
- PostgreSQL as the primary transactional data store
- Background jobs for ranking, notifications, reporting, reconciliation, and moderation
- Event-driven integration points for payments and delivery

---

## 2. Business Goals

### Primary Business Goals

1. Create a trusted fashion marketplace that supports local market realities.
2. Enable brands to onboard quickly, manage products, and receive payouts through a governed process.
3. Increase conversion by supporting payment methods that are culturally and commercially relevant, especially COD and local wallet-based methods.
4. Improve customer confidence through verified brands, reviews, chat support, order tracking, and dispute handling.
5. Reduce operational losses from failed deliveries and payment disputes.
6. Create a scalable platform foundation capable of supporting future growth features such as loyalty, referrals, subscriptions, and analytics.

### Business Outcomes

- Increase GMV through improved conversion and retention
- Improve trust and reduce return-related losses
- Reduce operational friction between brands, customers, and delivery companies
- Enable admin oversight over payments, brand verification, rankings, and disputes
- Create a platform that can expand into more advanced commerce capabilities over time

### Product Outcomes

- Short onboarding cycle for trusted brands
- Self-serve catalog management for brands
- Fast, reliable checkout experience for end-users
- Transparent order lifecycle for all stakeholders
- Centralized moderation and dispute handling

---

## 3. Problem Statement

FashionConnect addresses a fundamental problem in modern fashion commerce in Egypt: customers want a trustworthy digital marketplace, but the market requires a solution that respects local realities such as COD, mobile-first behavior, Arabic/English bilingual expectations, and regional delivery constraints.

Without a strong platform, several business and operational risks arise:

- Brands struggle to gain visibility and trust in a fragmented market.
- Customers may be pushed to off-platform channels such as Instagram, WhatsApp, or direct phone sales.
- Merchants may experience high operational friction due to manual order handling and fragmented fulfillment.
- Delivery failures and unpaid COD obligations can create serious financial loss and customer dissatisfaction.
- Admin and operations teams lack centralized oversight over disputes, payouts, ranking, and moderation.

The platform must therefore serve as both a commerce layer and an operational control layer.

---

## 4. Target Users

### 4.1 End-Users

End-users are consumers who browse, compare, buy, track, and review products. They expect a simple, reliable, and trustworthy shopping experience that feels mobile-first and local.

### 4.2 Brands

Brands are sellers or retailers who want to onboard to the platform, distribute products, manage catalogues, respond to customer interactions, fulfill orders, and receive payouts.

### 4.3 Admins

Admins are internal platform operators who manage trust, governance, dispute handling, payouts, ranking control, reporting, and platform integrity.

### 4.4 Delivery Companies

Delivery companies are logistics partners that receive orders from the platform, manage courier assignments, handle delivery execution, and reconcile COD payments.

### 4.5 Couriers

Couriers are the last-mile delivery actors who receive assigned orders, update delivery status, and submit proof of delivery.

### 4.6 Sub-Admins

Sub-admins are internal platform users with scoped permissions to specific operational domains such as payouts, disputes, or support.

---

## 5. User Roles

### 5.1 Admin

#### Responsibilities

- Govern platform trust and integrity
- Approve, reject, suspend, or re-verify brands
- Review disputes and moderation flags
- Approve payouts and oversee financial reconciliation
- Monitor platform health, ranking quality, and ad performance
- Manage delivery company onboarding and operational oversight
- Manage scoped sub-admin access

#### Permissions

- Full read access to platform data and operational reports
- Ability to approve or reject brand verification requests
- Ability to suspend brands or enforce moderation actions
- Ability to approve payouts above configured thresholds
- Ability to override ranking outcomes for business or operational reasons
- Ability to manage sub-admin roles and permissions

#### Limitations

- Must not create or alter product catalogues directly unless explicitly delegated
- Must not bypass audit logging or approval controls
- Must not approve payouts without appropriate authorization and audit trail

#### Dashboard

- GMV and orders overview
- Active brands and users
- Payment and payout reconciliation metrics
- Dispute queue metrics
- Delivery performance SLA metrics
- Ranking health and anomalies

#### Main Workflow

1. Review pending brand verification requests
2. Approve or reject application and notify the brand
3. Monitor disputes and moderation flags
4. Review transaction and payout reconciliation data
5. Approve payouts and resolve escalations
6. Adjust ranking or moderation interventions as needed

---

### 5.2 Brand

#### Responsibilities

- Register and maintain a brand presence on the platform
- Submit verification and KYC documentation
- Manage catalogue categories, products, and variants
- Monitor stock and low-stock conditions
- Launch advertising campaigns
- Receive incoming orders and manage fulfillment handoff
- Track payouts and sales analytics

#### Permissions

- Access to their own brand profile and documentation
- Ability to create and update categories and products
- Ability to launch ad campaigns and review ranking influence
- Ability to accept, reject, or hand off orders
- Ability to view analytics and payout history

#### Limitations

- Cannot modify another brand’s catalogue or financial records
- Cannot bypass verification requirements
- Cannot approve payouts directly; payouts are governed by admin workflow
- Cannot override platform-wide ranking logic without an approved admin action

#### Dashboard

- Verification status
- Inventory and low-stock alerts
- Orders pending action
- Sales analytics and conversion metrics
- Payout balance and payout history

#### Main Workflow

1. Register brand and submit required documents
2. Await verification approval or tier upgrade
3. Create categories and products
4. Configure inventory, pricing, and promotions
5. Receive orders and accept or reject them according to SLA
6. Handoff orders to a delivery company
7. Monitor payouts and analytics

---

### 5.3 End-User

#### Responsibilities

- Discover brands and products
- Compare products and evaluate trust signals
- Add products to cart and complete checkout
- Choose payment method, including COD if applicable
- Track order status and delivery progress
- Submit reviews and participate in marketplace interactions

#### Permissions

- Access to public catalogues and public brand profiles
- Ability to manage own cart, wishlist, orders, and profile
- Ability to chat with brands about products or orders
- Ability to submit ratings and reviews

#### Limitations

- Cannot access admin or partner systems
- Cannot manipulate pricing or order status externally
- Cannot access other users’ orders or private account information

#### Dashboard

- Order history
- Wishlist and saved items
- Notifications and chat threads
- Account and address management

#### Main Workflow

1. Browse or search for products or brands
2. Review product detail and trust signals
3. Add items to cart and checkout
4. Choose payment method and address
5. Track order status after placement
6. Receive delivery confirmation and optionally review the experience

---

### 5.4 Delivery Company

#### Responsibilities

- Receive orders from the platform via API or webhook
- Assign orders to couriers
- Manage fleet coverage, zones, and fee tiers
- Monitor SLA and delivery performance
- Reconcile COD collections and remittances

#### Permissions

- Access to assigned orders and courier performance metrics
- Ability to configure fee tiers and auto-assignment rules
- Ability to add, remove, and manage couriers

#### Limitations

- Cannot alter brand catalogue or product data
- Cannot access unrelated delivery company data
- Cannot directly change user account information

#### Dashboard

- Orders by status
- Courier assignments
- Delivery performance metrics
- COD reconciliation view
- Fee and zone configuration

#### Main Workflow

1. Receive order handoff from the platform
2. Assign order manually or via automation
3. Monitor status transitions and delivery outcomes
4. Reconcile COD payment collections
5. Report delivery performance and settlement status

---

### 5.5 Courier

#### Responsibilities

- View assigned orders for the day or upcoming window
- Update order status as movement progresses
- Submit proof of delivery
- Confirm delivery to the intended recipient where required

#### Permissions

- Access to assigned orders and delivery details
- Ability to change status and upload proof
- Ability to view route information if enabled

#### Limitations

- Cannot access unrelated orders
- Cannot modify customer account details or platform pricing
- Cannot approve brand verification or payouts

#### Dashboard

- Assigned orders list
- Delivery status timeline
- Route summary and stop list
- Earnings summary

#### Main Workflow

1. Receive assigned orders
2. Pick up or initiate transit
3. Update operational status
4. Submit proof of delivery or OTP confirmation
5. Complete the job and trigger reconciliation updates

---

### 5.6 Sub-Admin

#### Responsibilities

- Operate within a scoped domain such as payouts, disputes, or support
- Assist in platform operations without full admin privileges

#### Permissions

- Permissions are granted through explicit scope mapping
- Examples include payout approval, dispute resolution, or moderation review

#### Limitations

- Cannot access outside assigned scopes
- Must operate under audit logging and approval constraints

#### Dashboard

- Domain-specific queue and summary metrics

#### Main Workflow

1. Log in with scoped permissions
2. Review assigned queue items
3. Take action under the permitted domain
4. Record actions for audit review

---

## 6. Business Rules

### Authentication and Identity

- All protected endpoints require authentication.
- Authentication is based on Bearer tokens and JWT-style access tokens.
- OTP verification is required for critical onboarding and checkout-related authentication flows.
- Refresh tokens must be revocable and device-scoped.

### Brand Verification

- Brands progress through verification tiers: pending, basic_verified, trusted_verified, and suspended.
- Trusted verification unlocks enhanced platform privileges, including improved ranking and lower commissions where defined.
- Brand documents must be reviewed before a brand becomes fully eligible for advanced functionality.

### Catalog and Product Management

- Categories may be deleted only through soft-delete or reassignment logic to preserve historical integrity.
- Product deletion must preserve references in historical orders and review data.
- Variant uniqueness is enforced at the product level for size/color combinations.

### Orders and Checkout

- Checkout creates one order-level record and one sub-order per brand in the cart.
- Delivery fees are calculated per sub-order based on brand origin and customer governorate.
- COD is a first-class payment mode and must be reconciled as a financial workflow.

### Delivery and Fulfillment

- Brand handoff triggers delivery company intake.
- Delivery status transitions must be auditable and tied to proof-of-delivery or OTP confirmation.
- COD collection and remittance are critical operational and financial workflows.

### Payments and Payouts

- Financial data must be append-only and auditable.
- Payout approval must follow an authorization workflow and should support dual authorization above a configured threshold.
- Wallets and brand balances are derived from ledger data and should not be treated as source-of-truth transaction records.

### Trust, Safety, and Moderation

- Chat abuse, product issues, and order disputes must feed a central queue.
- Admin moderation actions must be logged.
- Reviews feed ranking and vendor trust scoring.

---

## 7. Assumptions

The following assumptions are made based on the supplied requirements and schema:

1. The platform will support a multi-role marketplace model with distinct experiences for each role.
2. Authentication will use JWT-based access tokens and refresh tokens.
3. The primary transactional database will be PostgreSQL.
4. The platform will support both digital and COD payment methods.
5. The platform will support Arabic and English content and UI flows.
6. Admin governance will be enforced through role-based and permission-based access control.
7. Orders will be split into sub-orders to support multi-brand carts.
8. A background job layer will handle ranking, notification dispatch, reconciliation, and reporting.
9. The system will use event-driven integration for payment providers and delivery partners.
10. The platform will support a public storefront view for brands and products, while private operations remain authenticated.

---

## 8. Constraints

### Functional Constraints

- The solution must support multi-role access with clearly different business flows for each role.
- The system must support real-world logistics and COD reconciliation, which increases financial complexity.
- The system must preserve auditability for sensitive operations such as payouts, disputes, and admin overrides.

### Technical Constraints

- The provided schema contains implementation inconsistencies that must be corrected before production use.
- The system must support asynchronous workflows such as payments, notifications, and background jobs.
- The architecture must be extensible for future features like loyalty, subscriptions, support tickets, and analytics.

### Business Constraints

- The solution must be suitable for the Egyptian market, including local payment methods and regional delivery behavior.
- The platform must support bilingual experiences.
- Strong trust and fraud-prevention controls are mandatory due to the marketplace nature of the business.

### Operational Constraints

- Delivery partner integrations and payout workflows cannot be treated as simple synchronous operations.
- Admin oversight is required for high-risk financial and trust functions.

---

## 9. Success Metrics

### Business Metrics

- Increase in completed orders and conversion rate
- Reduction in abandoned carts
- Increase in verified brand onboarding completion
- Improvement in brand retention and repeat purchases
- Reduction in customer support tickets related to order status

### Operational Metrics

- Order acceptance SLA compliance
- Delivery success rate
- COD reconciliation accuracy
- Payout processing turnaround time
- Dispute resolution turnaround time

### Product Metrics

- Search-to-purchase conversion rate
- Average time to first order for newly onboarded users
- Review velocity and review quality
- Notification engagement rate
- Chat response times for brands

### Engineering Metrics

- API availability and latency
- Error rate for checkout and payments
- Background job success rate
- Deployment frequency and rollback rate

---

## 10. Glossary

| Term              | Definition                                                                                  |
| ----------------- | ------------------------------------------------------------------------------------------- |
| Admin             | Internal platform operator responsible for governance, trust, and oversight.                |
| Brand             | Seller or retail operator that lists products and fulfils orders on the platform.           |
| End-User          | Customer who browses, buys, tracks, and reviews products.                                   |
| Sub-Order         | A per-brand order slice created from a checkout-level order for multi-brand carts.          |
| COD               | Cash on delivery, a primary payment method in the target market.                            |
| Verification Tier | A trust classification used to determine brand readiness and platform privileges.           |
| Ranking Score     | A precomputed score used to decide brand visibility and promotion.                          |
| Payout            | A financial transfer from the platform to a brand after settlement and approval.            |
| Dispute           | A conflict or issue raised by a user, brand, or system around orders, chat, or products.    |
| Moderation Flag   | A flagged item requiring review by admins or moderators.                                    |
| Delivery Company  | Fulfillment partner that receives handoff from the platform and manages delivery execution. |
| Courier           | Last-mile operational actor assigned to deliver an order.                                   |
| OTP               | One-time password used to verify identity or confirm delivery-related actions.              |
| Wallet            | A stored-value account used for refunds, cashback, or future purchases.                     |
| Loyalty Points    | Points accrued to reward repeat customer behavior.                                          |
| Ad Campaign       | A paid promotion that improves product or brand visibility.                                 |

---

## Open Issues and Clarifications Required Before Phase 2

The following items require confirmation before the next phase is produced, because they affect implementation scope and architecture:

1. The supplied SQL schema contains syntax errors and placeholders that must be corrected before implementation. Examples include:
   - `isBanned:` in the users table
   - `payment_details ?` in the brands table
   - references to `delivery_companies` and `couriers` from `sub_orders` before those tables are declared

2. The platform’s exact deployment model should be confirmed:
   - Monolith or modular services?
   - REST-only or hybrid with GraphQL?
   - Event bus and queueing platform desired?

3. The expected identity model should be confirmed:
   - Should user routes use token-based identity exclusively, or should path parameters such as `/users/{userId}` remain normative for internal use?

4. The product scope for Phase 2 should be confirmed:
   - Is the initial release intended to cover the full roadmap or only MVP scope?

5. The admin and sub-admin role model should be finalized:
   - Are there fixed permission scopes or a dynamic permission system?

Once these points are approved, I will proceed with Phase 2 and expand the documentation into full functional requirements for every module.
