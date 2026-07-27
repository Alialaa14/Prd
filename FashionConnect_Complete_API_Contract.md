# FashionConnect — Complete Backend API Contract

> This document is the implementation-oriented API contract for the FashionConnect platform. It is derived from the provided business requirements, functional specification, PRD, and database schema. No implementation code is included.

---

## 1. Scope and Conventions

### 1.1 Base URL

- Base path: `/api/v1`

### 1.2 Authentication

- Authentication is handled via Bearer JWT.
- Public endpoints do not require authentication.

### 1.3 Authorization Model

- Roles: `admin`, `sub_admin`, `brand`, `end_user`, `delivery_company`, `courier`, `guest`

### 1.4 Shared Response Envelope

Success response:

```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": {}
}
```

Error response:

```json
{
  "success": false,
  "message": "Validation failed"
}
```

### 1.5 Common Headers

| Header          | Required    | Description                                 |
| --------------- | ----------- | ------------------------------------------- |
| `Authorization` | Conditional | Bearer token for protected routes           |
| `Content-Type`  | Conditional | `application/json` or `multipart/form-data` |
| `X-Request-Id`  | Optional    | Correlation ID for tracing                  |

---

## 2. Feature Inventory

| Feature                       | Purpose                                                          | Related Tables                                                             |
| ----------------------------- | ---------------------------------------------------------------- | -------------------------------------------------------------------------- |
| Authentication & Identity     | Register, authenticate, verify OTP, manage sessions              | `users`, `otp_codes`, `refresh_tokens`                                     |
| Profiles & Addresses          | Manage user profile and delivery addresses                       | `users`, `addresses`                                                       |
| Brand Onboarding              | Register and verify brand accounts                               | `brands`, `brand_documents`                                                |
| Catalog Management            | Create and manage categories, products, variants                 | `categories`, `products`, `variants`, `product_media`                      |
| Wishlist                      | Save and manage favorite products                                | `wishlists`, `products`                                                    |
| Cart & Checkout               | Build carts and create orders                                    | `carts`, `cart_items`, `orders`, `sub_orders`, `transactions`              |
| Orders & Fulfillment          | Manage order lifecycle and handoff                               | `orders`, `sub_orders`, `order_items`, `sub_order_status_history`          |
| Reviews                       | Allow customers to review products and brands                    | `reviews`, `review_images`                                                 |
| Delivery & Courier Operations | Assign and complete deliveries                                   | `delivery_companies`, `couriers`, `delivery_proofs`, `cod_reconciliations` |
| Payments, Wallets & Payouts   | Create payments, process webhooks, manage wallets and payouts    | `transactions`, `wallets`, `wallet_transactions`, `payouts`                |
| Messaging & Notifications     | Chat and notification delivery                                   | `chat_threads`, `chat_messages`, `notifications`                           |
| Admin Governance              | Moderate content, handle disputes, manage ranking and sub-admins | `disputes`, `moderation_flags`, `admin_audit_log`, `ranking_scores`        |
| File Uploads                  | Upload documents, images, and proof-of-delivery media            | `uploads` (logical storage boundary)                                       |

---

## 3. Controllers and Routes

## 3.1 AuthController

### Controller Summary

- Purpose: Handle account creation, authentication, OTP verification, token refresh, and logout.
- Description: This controller governs identity lifecycle and token management for all roles.
- Authentication Required: No for register/login/OTP; Yes for refresh/logout.
- Authorized Roles: `guest`, `end_user`, `brand`, `admin`, `delivery_company`, `courier`

### Routes

### Route 1: Register Account

- HTTP Method: `POST`
- Endpoint: `/auth/register`
- Description: Create a user account and assign a role.
- Authentication Required: No
- Authorized Roles: `guest`

#### Request Input

- Headers
  - `Content-Type: application/json`
- Path Parameters
  - None
- Query Parameters
  - None
- Request Body
  - `role` (required): `end_user | brand | delivery_company | courier`
  - `name` (required): string
  - `email` (optional): valid email
  - `phone` (required): string
  - `password` (required): string
  - `brandProfile` (optional): object for brand onboarding
- Required Fields: `role`, `name`, `phone`, `password`
- Optional Fields: `email`, `brandProfile`
- Data Types: string, object
- Validation Rules:
  - `phone` must be valid and unique
  - `password` must be at least 8 characters
  - `role` must be one of the allowed values
  - `email` must be valid if provided
- Example Request JSON

```json
{
  "role": "end_user",
  "name": "Ahmed Hassan",
  "phone": "+201001234567",
  "email": "ahmed@example.com",
  "password": "StrongPass123"
}
```

#### Success Response

- Status Code: `201`
- Example JSON

```json
{
  "success": true,
  "message": "Account created successfully",
  "data": {
    "user": {
      "id": "uuid",
      "name": "Ahmed Hassan",
      "role": "end_user",
      "phone": "+201001234567",
      "email": "ahmed@example.com"
    },
    "accessToken": "jwt",
    "refreshToken": "jwt"
  }
}
```

- Data Object Fields:
  - `user.id`: unique identifier
  - `user.name`: display name
  - `user.role`: assigned role
  - `user.phone`: phone number
  - `user.email`: email address if provided
  - `accessToken`: short-lived JWT
  - `refreshToken`: long-lived refresh token

#### Error Responses

- Validation Error

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

- Conflict

```json
{
  "success": false,
  "message": "Conflict"
}
```

- Internal Server Error

```json
{
  "success": false,
  "message": "Internal server error"
}
```

#### Business Logic

- Create a new account record.
- Hash the password.
- Save an OTP and token context if required by the role.
- Issue access and refresh tokens.
- Side effects: send welcome notification, create default profile state, emit account-created event.

---

### Route 2: Login

- HTTP Method: `POST`
- Endpoint: `/auth/login`
- Description: Authenticate using phone or email and password.
- Authentication Required: No
- Authorized Roles: `guest`

#### Request Input

- Headers
  - `Content-Type: application/json`
- Path Parameters
  - None
- Query Parameters
  - None
- Request Body
  - `login` (required): string
  - `password` (required): string
- Required Fields: `login`, `password`
- Optional Fields: None
- Data Types: string
- Validation Rules:
  - `login` must be a valid email or phone
  - `password` must not be empty
- Example Request JSON

```json
{
  "login": "ahmed@example.com",
  "password": "StrongPass123"
}
```

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "accessToken": "jwt",
    "refreshToken": "jwt",
    "user": {
      "id": "uuid",
      "name": "Ahmed Hassan",
      "role": "end_user"
    }
  }
}
```

#### Error Responses

- Validation Error
- Unauthorized

```json
{
  "success": false,
  "message": "Unauthorized"
}
```

- Internal Server Error

#### Business Logic

- Verify the credentials.
- Validate the account status.
- Return new tokens.
- Side effects: update last-login timestamp, log authentication event.

---

### Route 3: Send OTP

- HTTP Method: `POST`
- Endpoint: `/auth/otp/send`
- Description: Send an OTP for verification or checkout completion.
- Authentication Required: No
- Authorized Roles: `guest`, `end_user`, `brand`, `delivery_company`, `courier`

#### Request Input

- Request Body
  - `phone` (required): string
  - `purpose` (required): string
- Validation Rules:
  - `phone` must be valid
  - `purpose` must be supported
- Example Request JSON

```json
{
  "phone": "+201001234567",
  "purpose": "verification"
}
```

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "OTP sent successfully",
  "data": {
    "expiresIn": 300
  }
}
```

#### Error Responses

- Validation Error
- Conflict
- Internal Server Error

#### Business Logic

- Generate a one-time OTP.
- Store it with expiration timestamp.
- Side effects: send SMS notification.

---

### Route 4: Verify OTP

- HTTP Method: `POST`
- Endpoint: `/auth/otp/verify`
- Description: Validate OTP received by the user.
- Authentication Required: No
- Authorized Roles: `guest`, `end_user`, `brand`, `delivery_company`, `courier`

#### Request Input

- Request Body
  - `phone` (required): string
  - `code` (required): string
  - `purpose` (required): string
- Validation Rules:
  - OTP must match and not be expired
- Example Request JSON

```json
{
  "phone": "+201001234567",
  "code": "123456",
  "purpose": "verification"
}
```

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "OTP verified successfully",
  "data": {
    "verified": true
  }
}
```

#### Error Responses

- Validation Error
- Not Found
- Internal Server Error

#### Business Logic

- Check OTP validity.
- Mark verification as complete.
- Side effects: update user verification state and emit verification event.

---

### Route 5: Refresh Token

- HTTP Method: `POST`
- Endpoint: `/auth/refresh`
- Description: Rotate an access token using a refresh token.
- Authentication Required: Yes
- Authorized Roles: All authenticated roles

#### Request Input

- Request Body
  - `refreshToken` (required): string
- Validation Rules:
  - Token must be valid and not revoked
- Example Request JSON

```json
{
  "refreshToken": "refresh.jwt"
}
```

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Token refreshed successfully",
  "data": {
    "accessToken": "jwt"
  }
}
```

#### Error Responses

- Unauthorized
- Internal Server Error

#### Business Logic

- Validate refresh token and rotate access token.
- Side effects: revoke old token if policy requires it.

---

### Route 6: Logout

- HTTP Method: `POST`
- Endpoint: `/auth/logout`
- Description: Invalidate current refresh token.
- Authentication Required: Yes
- Authorized Roles: All authenticated roles

#### Request Input

- Request Body
  - `refreshToken` (required): string
- Validation Rules:
  - Token must belong to the current user
- Example Request JSON

```json
{
  "refreshToken": "refresh.jwt"
}
```

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Logged out successfully",
  "data": {}
}
```

#### Error Responses

- Unauthorized
- Internal Server Error

#### Business Logic

- Revoke refresh token.
- Side effects: clear active session references.

---

## 3.2 UserProfileController

### Controller Summary

- Purpose: Manage authenticated user profile, delivery addresses, and account-related profile data.
- Description: This controller allows end users and other roles to view and update their own profile data.
- Authentication Required: Yes
- Authorized Roles: `end_user`, `brand`, `admin`, `delivery_company`, `courier`

### Routes

### Route 1: Get Current Profile

- HTTP Method: `GET`
- Endpoint: `/users/me`
- Description: Retrieve the authenticated user profile.
- Authentication Required: Yes
- Authorized Roles: All authenticated roles

#### Request Input

- Headers: `Authorization`
- Path Parameters: None
- Query Parameters: None
- Request Body: None
- Validation Rules: Token must be valid
- Example Request JSON
  - None

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Profile retrieved successfully",
  "data": {
    "id": "uuid",
    "name": "Ahmed Hassan",
    "email": "ahmed@example.com",
    "phone": "+201001234567",
    "role": "end_user"
  }
}
```

#### Error Responses

- Unauthorized
- Not Found
- Internal Server Error

#### Business Logic

- Read the current account profile.
- Side effects: none.

---

### Route 2: Update Current Profile

- HTTP Method: `PATCH`
- Endpoint: `/users/me`
- Description: Update profile information for the authenticated account.
- Authentication Required: Yes
- Authorized Roles: All authenticated roles

#### Request Input

- Request Body
  - `name` (optional): string
  - `email` (optional): string
  - `phone` (optional): string
  - `profilePictureUrl` (optional): string
- Validation Rules:
  - `email` must be valid if supplied
  - `phone` must be unique if changed
- Example Request JSON

```json
{
  "name": "Ahmed El Hassan",
  "profilePictureUrl": "https://cdn.example.com/avatar.png"
}
```

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "id": "uuid",
    "name": "Ahmed El Hassan"
  }
}
```

#### Error Responses

- Validation Error
- Unauthorized
- Internal Server Error

#### Business Logic

- Apply safe profile updates.
- Side effects: audit profile change.

---

### Route 3: List Addresses

- HTTP Method: `GET`
- Endpoint: `/users/me/addresses`
- Description: Retrieve all saved addresses for the authenticated user.
- Authentication Required: Yes
- Authorized Roles: `end_user`, `brand`, `delivery_company`

#### Request Input

- Query Parameters: `defaultOnly` (optional, boolean)
- Validation Rules: None beyond authentication

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Addresses retrieved successfully",
  "data": {
    "items": [
      {
        "id": "uuid",
        "governorate": "Cairo",
        "street": "Main Street",
        "contactPhone": "+201001234567",
        "isDefault": true
      }
    ]
  }
}
```

#### Error Responses

- Unauthorized
- Internal Server Error

#### Business Logic

- Return address records belonging to the authenticated user.
- Side effects: none.

---

### Route 4: Create Address

- HTTP Method: `POST`
- Endpoint: `/users/me/addresses`
- Description: Add a new address.
- Authentication Required: Yes
- Authorized Roles: `end_user`, `brand`, `delivery_company`

#### Request Input

- Request Body
  - `governorate` (required): string
  - `street` (required): string
  - `contactPhone` (required): string
  - `isDefault` (optional): boolean
- Validation Rules:
  - Only one default address may exist
- Example Request JSON

```json
{
  "governorate": "Cairo",
  "street": "12 Street",
  "contactPhone": "+201001234567",
  "isDefault": true
}
```

#### Success Response

- Status Code: `201`
- Example JSON

```json
{
  "success": true,
  "message": "Address created successfully",
  "data": {
    "id": "uuid"
  }
}
```

#### Error Responses

- Validation Error
- Conflict
- Internal Server Error

#### Business Logic

- Create a new address linked to the authenticated user.
- Side effects: if marked as default, ensure previous default flags are reset.

---

### Route 5: Update Address

- HTTP Method: `PATCH`
- Endpoint: `/users/me/addresses/{addressId}`
- Description: Update an address owned by the user.
- Authentication Required: Yes
- Authorized Roles: `end_user`, `brand`, `delivery_company`

#### Request Input

- Path Parameters: `addressId`
- Request Body: same fields as create, partial updates allowed
- Validation Rules: address must belong to current user

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Address updated successfully",
  "data": {
    "id": "uuid"
  }
}
```

#### Error Responses

- Unauthorized
- Not Found
- Validation Error

#### Business Logic

- Update only the allowed address fields.
- Side effects: none.

---

### Route 6: Delete Address

- HTTP Method: `DELETE`
- Endpoint: `/users/me/addresses/{addressId}`
- Description: Remove an address.
- Authentication Required: Yes
- Authorized Roles: `end_user`, `brand`, `delivery_company`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Address deleted successfully",
  "data": {}
}
```

#### Error Responses

- Unauthorized
- Not Found

#### Business Logic

- Remove an address only if it is not currently used in a pending order.
- Side effects: none.

---

## 3.3 BrandController

### Controller Summary

- Purpose: Manage brand registration, profile updates, public visibility, and brand-level operations.
- Description: Supports brand onboarding, verification workflow, profile editing, and public profile access.
- Authentication Required: No for public registration or public profile; Yes for private operations.
- Authorized Roles: `guest`, `brand`, `admin`

### Routes

### Route 1: Register Brand

- HTTP Method: `POST`
- Endpoint: `/brands/register`
- Description: Submit a new brand application.
- Authentication Required: No
- Authorized Roles: `guest`

#### Request Input

- Request Body
  - `name` (required): string
  - `address` (required): object or string
  - `contact` (required): object or string
  - `category` (required): string
- Validation Rules:
  - Brand name must be unique
  - Contact information must be valid
- Example Request JSON

```json
{
  "name": "Fashion House",
  "address": "Cairo",
  "contact": "sales@fashionhouse.com",
  "category": "Clothing"
}
```

#### Success Response

- Status Code: `201`
- Example JSON

```json
{
  "success": true,
  "message": "Brand registration submitted successfully",
  "data": {
    "brandId": "uuid",
    "verificationStatus": "pending"
  }
}
```

#### Error Responses

- Validation Error
- Conflict
- Internal Server Error

#### Business Logic

- Create a brand record with `pending` verification status.
- Side effects: create verification queue entry and notify admin.

---

### Route 2: Upload Brand Documents

- HTTP Method: `POST`
- Endpoint: `/brands/{brandId}/documents`
- Description: Upload verification documents for brand onboarding.
- Authentication Required: Yes
- Authorized Roles: `brand`

#### Request Input

- Path Parameters: `brandId`
- Headers: `Content-Type: multipart/form-data`
- Request Body: document files and metadata
- Validation Rules:
  - File type and size must be allowed
  - Brand must be owned by the authenticated user
- Example Request JSON
  - Multipart form data

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Documents uploaded successfully",
  "data": {
    "brandId": "uuid"
  }
}
```

#### Error Responses

- Validation Error
- Forbidden
- Internal Server Error

#### Business Logic

- Save brand documents and attach them to the brand verification record.
- Side effects: create audit event.

---

### Route 3: Get Verification Status

- HTTP Method: `GET`
- Endpoint: `/brands/{brandId}/verification-status`
- Description: Retrieve current brand verification tier and missing requirements.
- Authentication Required: Yes for owner; public for approved brands if allowed by policy
- Authorized Roles: `brand`, `admin`, `guest`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Verification status retrieved successfully",
  "data": {
    "brandId": "uuid",
    "verificationStatus": "basic_verified",
    "missingRequirements": []
  }
}
```

#### Error Responses

- Unauthorized
- Not Found
- Internal Server Error

#### Business Logic

- Return verification state based on approved documents and review state.
- Side effects: none.

---

### Route 4: Get Public Brand Profile

- HTTP Method: `GET`
- Endpoint: `/brands/{brandId}`
- Description: Retrieve public brand profile information.
- Authentication Required: No
- Authorized Roles: `guest`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Brand profile retrieved successfully",
  "data": {
    "id": "uuid",
    "name": "Fashion House",
    "verificationStatus": "trusted_verified",
    "rating": 4.8,
    "logoUrl": "https://cdn.example.com/logo.png"
  }
}
```

#### Error Responses

- Not Found
- Internal Server Error

#### Business Logic

- Expose only public information for approved brands.
- Side effects: none.

---

### Route 5: Update Brand Profile

- HTTP Method: `PATCH`
- Endpoint: `/brands/{brandId}`
- Description: Update brand profile details.
- Authentication Required: Yes
- Authorized Roles: `brand`

#### Request Input

- Request Body
  - `name` (optional): string
  - `logoUrl` (optional): string
  - `address` (optional): object or string
  - `contact` (optional): string
- Validation Rules: only brand owner may update the record

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Brand profile updated successfully",
  "data": {
    "id": "uuid"
  }
}
```

#### Error Responses

- Validation Error
- Forbidden
- Internal Server Error

#### Business Logic

- Update the brand profile after ownership validation.
- Side effects: audit event.

---

## 3.4 CategoryController

### Controller Summary

- Purpose: Manage brand categories.
- Description: Allows brands to create, edit, and delete categories while preserving integrity.
- Authentication Required: Yes
- Authorized Roles: `brand`, `admin`

### Routes

### Route 1: List Categories

- HTTP Method: `GET`
- Endpoint: `/brands/{brandId}/categories`
- Description: List categories for a brand.
- Authentication Required: Conditional
- Authorized Roles: `brand`, `admin`, `guest`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Categories retrieved successfully",
  "data": {
    "items": [
      {
        "id": "uuid",
        "name": "Men's Wear"
      }
    ]
  }
}
```

#### Error Responses

- Not Found
- Internal Server Error

#### Business Logic

- Return categories belonging to the requested brand.
- Side effects: none.

---

### Route 2: Create Category

- HTTP Method: `POST`
- Endpoint: `/brands/{brandId}/categories`
- Description: Create a new category.
- Authentication Required: Yes
- Authorized Roles: `brand`

#### Request Input

- Request Body
  - `name` (required): string
  - `imageUrl` (optional): string
- Validation Rules:
  - Category name must be unique within the brand
- Example Request JSON

```json
{
  "name": "Women's Wear",
  "imageUrl": "https://cdn.example.com/category.png"
}
```

#### Success Response

- Status Code: `201`
- Example JSON

```json
{
  "success": true,
  "message": "Category created successfully",
  "data": {
    "id": "uuid"
  }
}
```

#### Error Responses

- Validation Error
- Forbidden
- Internal Server Error

#### Business Logic

- Create category and link it to the brand.
- Side effects: none.

---

### Route 3: Update Category

- HTTP Method: `PATCH`
- Endpoint: `/brands/{brandId}/categories/{catId}`
- Description: Update an existing category.
- Authentication Required: Yes
- Authorized Roles: `brand`

#### Request Input

- Path Parameters: `brandId`, `catId`
- Request Body: partial category payload
- Validation Rules: category must belong to the brand

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Category updated successfully",
  "data": {
    "id": "uuid"
  }
}
```

#### Error Responses

- Validation Error
- Not Found
- Forbidden

#### Business Logic

- Edit the category if it belongs to the brand.
- Side effects: none.

---

### Route 4: Delete Category

- HTTP Method: `DELETE`
- Endpoint: `/brands/{brandId}/categories/{catId}`
- Description: Soft-delete a category.
- Authentication Required: Yes
- Authorized Roles: `brand`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Category deleted successfully",
  "data": {}
}
```

#### Error Responses

- Conflict
- Forbidden
- Internal Server Error

#### Business Logic

- Prevent deletion if active products depend on it unless reassigned.
- Side effects: mark category as inactive and preserve historical integrity.

---

## 3.5 ProductController

### Controller Summary

- Purpose: Manage products, variants, and media for a brand.
- Description: Allows catalog creation, bulk import, and low-stock tracking.
- Authentication Required: Yes for creation/edit; No for public browsing.
- Authorized Roles: `brand`, `admin`, `guest`, `end_user`

### Routes

### Route 1: List Products

- HTTP Method: `GET`
- Endpoint: `/brands/{brandId}/products`
- Description: List products for a brand.
- Authentication Required: Conditional
- Authorized Roles: `brand`, `admin`, `guest`, `end_user`

#### Query Parameters

- `category` (optional)
- `stockStatus` (optional)
- `page` (optional)
- `limit` (optional)

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Products retrieved successfully",
  "data": {
    "items": [
      {
        "id": "uuid",
        "name": "Classic Shirt"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 1
    }
  }
}
```

#### Error Responses

- Not Found
- Internal Server Error

#### Business Logic

- Return products linked to the brand, respecting visibility and stock rules.
- Side effects: none.

---

### Route 2: Create Product

- HTTP Method: `POST`
- Endpoint: `/brands/{brandId}/products`
- Description: Create a new product with variants.
- Authentication Required: Yes
- Authorized Roles: `brand`

#### Request Input

- Request Body
  - `name` (required): string
  - `description` (optional): string
  - `categoryId` (optional): string
  - `price` (required): number
  - `variants` (required): array
  - `media` (optional): array
- Validation Rules:
  - Product must belong to the brand
  - Variants must be valid and unique
  - Price must be positive
- Example Request JSON

```json
{
  "name": "Classic Shirt",
  "price": 350,
  "variants": [
    {
      "color": "black",
      "size": "M",
      "stock": 10
    }
  ]
}
```

#### Success Response

- Status Code: `201`
- Example JSON

```json
{
  "success": true,
  "message": "Product created successfully",
  "data": {
    "id": "uuid"
  }
}
```

#### Error Responses

- Validation Error
- Forbidden
- Internal Server Error

#### Business Logic

- Create product and linked variant records.
- Side effects: allow future low-stock and ranking updates.

---

### Route 3: Update Product

- HTTP Method: `PATCH`
- Endpoint: `/brands/{brandId}/products/{productId}`
- Description: Update product metadata and variants.
- Authentication Required: Yes
- Authorized Roles: `brand`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Product updated successfully",
  "data": {
    "id": "uuid"
  }
}
```

#### Error Responses

- Validation Error
- Not Found
- Forbidden

#### Business Logic

- Update permitted product fields and variants.
- Side effects: log inventory changes.

---

### Route 4: Delete Product

- HTTP Method: `DELETE`
- Endpoint: `/brands/{brandId}/products/{productId}`
- Description: Soft-delete a product.
- Authentication Required: Yes
- Authorized Roles: `brand`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Product deleted successfully",
  "data": {}
}
```

#### Error Responses

- Forbidden
- Not Found
- Internal Server Error

#### Business Logic

- Mark product inactive rather than hard-delete.
- Side effects: maintain historical order references.

---

### Route 5: Bulk Import Products

- HTTP Method: `POST`
- Endpoint: `/brands/{brandId}/products/bulk-import`
- Description: Import a catalog via CSV upload.
- Authentication Required: Yes
- Authorized Roles: `brand`

#### Request Input

- Headers: `Content-Type: multipart/form-data`
- Request Body: CSV file
- Validation Rules: CSV schema must be valid

#### Success Response

- Status Code: `202`
- Example JSON

```json
{
  "success": true,
  "message": "Bulk import accepted",
  "data": {
    "jobId": "uuid",
    "status": "queued"
  }
}
```

#### Error Responses

- Validation Error
- Forbidden
- Internal Server Error

#### Business Logic

- Queue import for asynchronous processing.
- Side effects: create async import job, notify brand on completion.

---

### Route 6: List Low Stock Products

- HTTP Method: `GET`
- Endpoint: `/brands/{brandId}/products/low-stock`
- Description: Retrieve variants below the stock threshold.
- Authentication Required: Yes
- Authorized Roles: `brand`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Low stock products retrieved successfully",
  "data": {
    "items": []
  }
}
```

#### Error Responses

- Forbidden
- Internal Server Error

#### Business Logic

- Return inventory items that require replenishment.
- Side effects: generate low-stock alert events.

---

## 3.6 WishlistController

### Controller Summary

- Purpose: Manage product wishlist items for end users.
- Description: Allows a user to save and remove favorite products.
- Authentication Required: Yes
- Authorized Roles: `end_user`

### Routes

### Route 1: List Wishlist

- HTTP Method: `GET`
- Endpoint: `/users/{userId}/wishlist`
- Description: Retrieve the authenticated user's wishlist.
- Authentication Required: Yes
- Authorized Roles: `end_user`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Wishlist retrieved successfully",
  "data": {
    "items": []
  }
}
```

#### Error Responses

- Forbidden
- Internal Server Error

#### Business Logic

- Return wishlist entries associated with the user.
- Side effects: none.

---

### Route 2: Add to Wishlist

- HTTP Method: `POST`
- Endpoint: `/users/{userId}/wishlist`
- Description: Save a product in the wishlist.
- Authentication Required: Yes
- Authorized Roles: `end_user`

#### Request Input

- Request Body
  - `productId` (required): string
- Validation Rules: product must exist

#### Success Response

- Status Code: `201`
- Example JSON

```json
{
  "success": true,
  "message": "Item added to wishlist",
  "data": {
    "id": "uuid"
  }
}
```

#### Error Responses

- Validation Error
- Conflict
- Internal Server Error

#### Business Logic

- Create a wishlist record.
- Side effects: send price/stock alert preference event if configured.

---

### Route 3: Remove from Wishlist

- HTTP Method: `DELETE`
- Endpoint: `/users/{userId}/wishlist/{itemId}`
- Description: Remove an item from the wishlist.
- Authentication Required: Yes
- Authorized Roles: `end_user`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Item removed from wishlist",
  "data": {}
}
```

#### Error Responses

- Not Found
- Forbidden
- Internal Server Error

#### Business Logic

- Delete the wishlist row.
- Side effects: none.

---

## 3.7 CartController

### Controller Summary

- Purpose: Manage cart contents for an end user.
- Description: Supports add/update/remove operations and cart view.
- Authentication Required: Yes
- Authorized Roles: `end_user`

### Routes

### Route 1: Get Cart

- HTTP Method: `GET`
- Endpoint: `/users/{userId}/cart`
- Description: Retrieve the authenticated user's cart.
- Authentication Required: Yes
- Authorized Roles: `end_user`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Cart retrieved successfully",
  "data": {
    "items": []
  }
}
```

#### Error Responses

- Forbidden
- Internal Server Error

#### Business Logic

- Return cart items for the user.
- Side effects: none.

---

### Route 2: Add Cart Item

- HTTP Method: `POST`
- Endpoint: `/users/{userId}/cart/items`
- Description: Add a product variant to the cart.
- Authentication Required: Yes
- Authorized Roles: `end_user`

#### Request Input

- Request Body
  - `productId` (required): string
  - `variantId` (required): string
  - `qty` (required): positive integer
- Validation Rules:
  - Variant must exist and be in stock
  - Quantity must be positive
- Example Request JSON

```json
{
  "productId": "uuid",
  "variantId": "uuid",
  "qty": 2
}
```

#### Success Response

- Status Code: `201`
- Example JSON

```json
{
  "success": true,
  "message": "Cart item added successfully",
  "data": {
    "cartItemId": "uuid"
  }
}
```

#### Error Responses

- Validation Error
- Conflict
- Internal Server Error

#### Business Logic

- Create or update a cart item.
- Side effects: validate stock and price snapshot.

---

### Route 3: Update Cart Item

- HTTP Method: `PATCH`
- Endpoint: `/users/{userId}/cart/items/{itemId}`
- Description: Update quantity of a cart item.
- Authentication Required: Yes
- Authorized Roles: `end_user`

#### Request Input

- Request Body
  - `qty` (required): integer
- Validation Rules: quantity must be positive

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Cart item updated successfully",
  "data": {
    "itemId": "uuid"
  }
}
```

#### Error Responses

- Validation Error
- Not Found
- Internal Server Error

#### Business Logic

- Update the quantity of a cart item.
- Side effects: recalculate cart totals.

---

### Route 4: Remove Cart Item

- HTTP Method: `DELETE`
- Endpoint: `/users/{userId}/cart/items/{itemId}`
- Description: Remove an item from the cart.
- Authentication Required: Yes
- Authorized Roles: `end_user`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Cart item removed successfully",
  "data": {}
}
```

#### Error Responses

- Not Found
- Forbidden
- Internal Server Error

#### Business Logic

- Remove the cart item from the active cart.
- Side effects: recalculate cart totals.

---

## 3.8 CheckoutController

### Controller Summary

- Purpose: Convert a cart into an order and create associated sub-orders.
- Description: Handles checkout, payment initiation, and order creation.
- Authentication Required: Yes
- Authorized Roles: `end_user`

### Routes

### Route 1: Create Checkout

- HTTP Method: `POST`
- Endpoint: `/users/{userId}/checkout`
- Description: Create an order from the user cart.
- Authentication Required: Yes
- Authorized Roles: `end_user`

#### Request Input

- Request Body
  - `addressId` (required): string
  - `paymentMethod` (required): string
  - `couponCode` (optional): string
- Validation Rules:
  - Cart must not be empty
  - Address must belong to the user
  - Payment method must be supported
  - Inventory must be sufficient
- Example Request JSON

```json
{
  "addressId": "uuid",
  "paymentMethod": "cod"
}
```

#### Success Response

- Status Code: `201`
- Example JSON

```json
{
  "success": true,
  "message": "Checkout completed successfully",
  "data": {
    "orderId": "uuid",
    "orderNumber": "ORD-1001",
    "paymentStatus": "pending",
    "totalAmount": 700,
    "subOrders": []
  }
}
```

#### Error Responses

- Validation Error
- Conflict
- Internal Server Error

#### Business Logic

- Validate cart contents and address.
- Create a parent order and one sub-order per brand.
- Create payment intent or payment record.
- Side effects: create transaction, notify user and brand, emit order-created event.

---

## 3.9 OrderController

### Controller Summary

- Purpose: Manage user-facing order history and tracking.
- Description: Exposes orders, details, and tracking events.
- Authentication Required: Yes
- Authorized Roles: `end_user`, `admin`

### Routes

### Route 1: List Orders

- HTTP Method: `GET`
- Endpoint: `/users/{userId}/orders`
- Description: Retrieve the authenticated user's order history.
- Authentication Required: Yes
- Authorized Roles: `end_user`, `admin`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Orders retrieved successfully",
  "data": {
    "items": []
  }
}
```

#### Error Responses

- Forbidden
- Internal Server Error

#### Business Logic

- Return all orders owned by the user or accessible to admin.
- Side effects: none.

---

### Route 2: Get Order Detail

- HTTP Method: `GET`
- Endpoint: `/users/{userId}/orders/{orderId}`
- Description: Retrieve full order details.
- Authentication Required: Yes
- Authorized Roles: `end_user`, `admin`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Order retrieved successfully",
  "data": {
    "id": "uuid",
    "orderNumber": "ORD-1001",
    "status": "pending",
    "totalAmount": 700,
    "subOrders": []
  }
}
```

#### Error Responses

- Not Found
- Forbidden
- Internal Server Error

#### Business Logic

- Return order and sub-order breakdown.
- Side effects: none.

---

### Route 3: Get Tracking Timeline

- HTTP Method: `GET`
- Endpoint: `/users/{userId}/orders/{orderId}/tracking`
- Description: Retrieve order status updates over time.
- Authentication Required: Yes
- Authorized Roles: `end_user`, `admin`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Tracking retrieved successfully",
  "data": {
    "timeline": []
  }
}
```

#### Error Responses

- Not Found
- Forbidden
- Internal Server Error

#### Business Logic

- Return status history for the order and sub-orders.
- Side effects: none.

---

### Route 4: Create Return Request

- HTTP Method: `POST`
- Endpoint: `/orders/{orderId}/returns`
- Description: Request a return for an order.
- Authentication Required: Yes
- Authorized Roles: `end_user`

#### Request Input

- Request Body
  - `reason` (required): string
  - `items` (optional): array
- Validation Rules: return only allowed for eligible order states

#### Success Response

- Status Code: `201`
- Example JSON

```json
{
  "success": true,
  "message": "Return request created successfully",
  "data": {
    "returnId": "uuid"
  }
}
```

#### Error Responses

- Validation Error
- Conflict
- Internal Server Error

#### Business Logic

- Create a return request and attach it to the order.
- Side effects: notify support/admin.

---

## 3.10 BrandOrderController

### Controller Summary

- Purpose: Enable brand-side order operations.
- Description: Allows a brand to accept, reject, or hand off incoming sub-orders.
- Authentication Required: Yes
- Authorized Roles: `brand`

### Routes

### Route 1: List Incoming Orders

- HTTP Method: `GET`
- Endpoint: `/brands/{brandId}/orders`
- Description: List sub-orders for a brand.
- Authentication Required: Yes
- Authorized Roles: `brand`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Incoming orders retrieved successfully",
  "data": {
    "items": []
  }
}
```

#### Error Responses

- Forbidden
- Internal Server Error

#### Business Logic

- Return sub-orders belonging to the brand.
- Side effects: none.

---

### Route 2: Accept Order

- HTTP Method: `PATCH`
- Endpoint: `/brands/{brandId}/orders/{orderId}/accept`
- Description: Accept a sub-order.
- Authentication Required: Yes
- Authorized Roles: `brand`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Order accepted successfully",
  "data": {
    "status": "accepted"
  }
}
```

#### Error Responses

- Validation Error
- Forbidden
- Internal Server Error

#### Business Logic

- Transition the sub-order from pending to accepted.
- Side effects: start SLA timer and notify customer.

---

### Route 3: Reject Order

- HTTP Method: `PATCH`
- Endpoint: `/brands/{brandId}/orders/{orderId}/reject`
- Description: Reject a sub-order.
- Authentication Required: Yes
- Authorized Roles: `brand`

#### Request Input

- Request Body
  - `reason` (required): string

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Order rejected successfully",
  "data": {
    "status": "rejected"
  }
}
```

#### Error Responses

- Validation Error
- Forbidden
- Internal Server Error

#### Business Logic

- Update the order state to rejected with a reason.
- Side effects: notify user and relevant admin queue.

---

### Route 4: Hand Off to Delivery

- HTTP Method: `PATCH`
- Endpoint: `/brands/{brandId}/orders/{orderId}/handoff`
- Description: Hand off a sub-order to the delivery partner.
- Authentication Required: Yes
- Authorized Roles: `brand`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Order handed off successfully",
  "data": {
    "status": "handed_off"
  }
}
```

#### Error Responses

- Validation Error
- Forbidden
- Internal Server Error

#### Business Logic

- Transfer the sub-order to delivery-company processing.
- Side effects: invoke delivery webhook or queue event.

---

## 3.11 ReviewController

### Controller Summary

- Purpose: Submit and moderate reviews for products and brands.
- Description: Allows end users to review purchases and lets admins moderate reviews.
- Authentication Required: Yes
- Authorized Roles: `end_user`, `admin`

### Routes

### Route 1: Submit Product Review

- HTTP Method: `POST`
- Endpoint: `/products/{productId}/reviews`
- Description: Submit a review for a purchased product.
- Authentication Required: Yes
- Authorized Roles: `end_user`

#### Request Input

- Request Body
  - `rating` (required): integer, 1 to 5
  - `comment` (optional): string
  - `photos` (optional): array
- Validation Rules:
  - Review must be tied to a completed purchase
  - Duplicate review is not allowed

#### Success Response

- Status Code: `201`
- Example JSON

```json
{
  "success": true,
  "message": "Review submitted successfully",
  "data": {
    "reviewId": "uuid"
  }
}
```

#### Error Responses

- Validation Error
- Conflict
- Internal Server Error

#### Business Logic

- Validate purchase completion and create a review record.
- Side effects: update product/brand rating aggregates.

---

### Route 2: Submit Brand Review

- HTTP Method: `POST`
- Endpoint: `/brands/{brandId}/reviews`
- Description: Submit a review for a brand.
- Authentication Required: Yes
- Authorized Roles: `end_user`

#### Success Response

- Status Code: `201`
- Example JSON

```json
{
  "success": true,
  "message": "Brand review submitted successfully",
  "data": {
    "reviewId": "uuid"
  }
}
```

#### Error Responses

- Validation Error
- Conflict
- Internal Server Error

#### Business Logic

- Create a brand review record.
- Side effects: update vendor scorecard.

---

## 3.12 DeliveryCompanyController

### Controller Summary

- Purpose: Manage delivery-company operations and fleet configuration.
- Description: Supports order intake, courier assignment, fee tiers, and reconciliation.
- Authentication Required: Yes for internal operations; No for webhook intake.
- Authorized Roles: `delivery_company`, `admin`

### Routes

### Route 1: Receive Order Webhook

- HTTP Method: `POST`
- Endpoint: `/delivery-companies/{id}/orders/webhook`
- Description: Receive platform handoff payload.
- Authentication Required: No
- Authorized Roles: `delivery_company`

#### Request Input

- Request Body: order handoff payload
- Validation Rules: payload must contain required order metadata

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Order webhook processed successfully",
  "data": {
    "accepted": true
  }
}
```

#### Error Responses

- Validation Error
- Internal Server Error

#### Business Logic

- Accept incoming delivery order.
- Side effects: create delivery task and notify dispatcher.

---

### Route 2: List Orders

- HTTP Method: `GET`
- Endpoint: `/delivery-companies/{id}/orders`
- Description: List delivery orders by status.
- Authentication Required: Yes
- Authorized Roles: `delivery_company`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Delivery orders retrieved successfully",
  "data": {
    "items": []
  }
}
```

#### Error Responses

- Forbidden
- Internal Server Error

#### Business Logic

- Return assigned or available delivery tasks.
- Side effects: none.

---

### Route 3: Assign Courier

- HTTP Method: `PATCH`
- Endpoint: `/delivery-companies/{id}/orders/{orderId}/assign`
- Description: Manually assign a courier to an order.
- Authentication Required: Yes
- Authorized Roles: `delivery_company`

#### Request Input

- Request Body
  - `courierId` (required): string
- Validation Rules: courier must belong to the delivery company

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Courier assigned successfully",
  "data": {
    "orderId": "uuid"
  }
}
```

#### Error Responses

- Validation Error
- Forbidden
- Internal Server Error

#### Business Logic

- Link the order to a courier.
- Side effects: notify courier and end user.

---

### Route 4: Configure Auto-Assignment Rules

- HTTP Method: `PATCH`
- Endpoint: `/delivery-companies/{id}/auto-assign-rules`
- Description: Configure automatic assignment rules.
- Authentication Required: Yes
- Authorized Roles: `delivery_company`

#### Request Input

- Request Body
  - `strategy` (required): string
  - `params` (required): object

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Auto-assignment rules updated successfully",
  "data": {
    "strategy": "nearest"
  }
}
```

#### Error Responses

- Validation Error
- Forbidden
- Internal Server Error

#### Business Logic

- Save dispatch heuristics for automatic assignment.
- Side effects: none.

---

## 3.13 CourierController

### Controller Summary

- Purpose: Manage courier assignment tasks and delivery execution.
- Description: Lets couriers see assigned jobs, update status, and upload proof of delivery.
- Authentication Required: Yes
- Authorized Roles: `courier`

### Routes

### Route 1: List Assigned Orders

- HTTP Method: `GET`
- Endpoint: `/couriers/{id}/orders`
- Description: Retrieve assigned delivery orders.
- Authentication Required: Yes
- Authorized Roles: `courier`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Assigned orders retrieved successfully",
  "data": {
    "items": []
  }
}
```

#### Error Responses

- Forbidden
- Internal Server Error

#### Business Logic

- Return orders assigned to the courier.
- Side effects: none.

---

### Route 2: Get Assigned Order Detail

- HTTP Method: `GET`
- Endpoint: `/couriers/{id}/orders/{orderId}`
- Description: Retrieve detail for a specific assigned order.
- Authentication Required: Yes
- Authorized Roles: `courier`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Assigned order retrieved successfully",
  "data": {
    "id": "uuid",
    "status": "assigned"
  }
}
```

#### Error Responses

- Not Found
- Forbidden
- Internal Server Error

#### Business Logic

- Return the assigned order details.
- Side effects: none.

---

### Route 3: Update Delivery Status

- HTTP Method: `PATCH`
- Endpoint: `/couriers/{id}/orders/{orderId}/status`
- Description: Update the order delivery lifecycle status.
- Authentication Required: Yes
- Authorized Roles: `courier`

#### Request Input

- Request Body
  - `status` (required): string
  - `notes` (optional): string
- Validation Rules: status must be valid and follow state transitions

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Delivery status updated successfully",
  "data": {
    "status": "delivered"
  }
}
```

#### Error Responses

- Validation Error
- Forbidden
- Internal Server Error

#### Business Logic

- Move the order through the delivery status lifecycle.
- Side effects: notify customer and update audit events.

---

### Route 4: Submit Proof of Delivery

- HTTP Method: `POST`
- Endpoint: `/couriers/{id}/orders/{orderId}/proof`
- Description: Upload proof of delivery for an order.
- Authentication Required: Yes
- Authorized Roles: `courier`

#### Request Input

- Headers: `Content-Type: multipart/form-data`
- Request Body: photo and/or OTP payload
- Validation Rules: proof required for delivered state

#### Success Response

- Status Code: `201`
- Example JSON

```json
{
  "success": true,
  "message": "Proof uploaded successfully",
  "data": {
    "proofId": "uuid"
  }
}
```

#### Error Responses

- Validation Error
- Forbidden
- Internal Server Error

#### Business Logic

- Persist proof-of-delivery evidence.
- Side effects: trigger dispute protection and update delivery state.

---

## 3.14 PaymentController

### Controller Summary

- Purpose: Create payment intents and manage payment state.
- Description: Supports checkout payment creation and gateway-backed payment flows.
- Authentication Required: Yes for creation; No for webhook endpoints.
- Authorized Roles: `end_user`, `admin`

### Routes

### Route 1: Create Payment Intent

- HTTP Method: `POST`
- Endpoint: `/payments/intents`
- Description: Create a payment intent for an order.
- Authentication Required: Yes
- Authorized Roles: `end_user`

#### Request Input

- Request Body
  - `orderId` (required): string
  - `amount` (required): number
  - `currency` (required): string
  - `paymentMethod` (required): string
- Validation Rules: order must be valid and payable

#### Success Response

- Status Code: `201`
- Example JSON

```json
{
  "success": true,
  "message": "Payment intent created successfully",
  "data": {
    "transactionId": "uuid",
    "status": "pending"
  }
}
```

#### Error Responses

- Validation Error
- Conflict
- Internal Server Error

#### Business Logic

- Create a transaction record and initiate gateway processing.
- Side effects: emit payment-created event and notify the user.

---

### Route 2: Stripe Webhook

- HTTP Method: `POST`
- Endpoint: `/payments/webhooks/stripe`
- Description: Receive Stripe payment status updates.
- Authentication Required: No
- Authorized Roles: `guest`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Stripe webhook processed successfully",
  "data": {}
}
```

#### Error Responses

- Validation Error
- Internal Server Error

#### Business Logic

- Verify webhook signature and update payment state.
- Side effects: update order status and notify downstream services.

---

### Route 3: Paymob Webhook

- HTTP Method: `POST`
- Endpoint: `/payments/webhooks/paymob`
- Description: Receive Paymob payment confirmation and reconciliation updates.
- Authentication Required: No
- Authorized Roles: `guest`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Paymob webhook processed successfully",
  "data": {}
}
```

#### Error Responses

- Validation Error
- Internal Server Error

#### Business Logic

- Update transaction status based on gateway callback.
- Side effects: synchronize wallet or payout state as required.

---

## 3.15 WalletController

### Controller Summary

- Purpose: Expose wallet balance and transaction history.
- Description: Lets users view wallet details and admin review wallet records.
- Authentication Required: Yes
- Authorized Roles: `end_user`, `admin`

### Routes

### Route 1: Get Wallet Balance

- HTTP Method: `GET`
- Endpoint: `/users/{userId}/wallet`
- Description: Retrieve the authenticated user's wallet balance.
- Authentication Required: Yes
- Authorized Roles: `end_user`, `admin`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Wallet retrieved successfully",
  "data": {
    "balance": 0
  }
}
```

#### Error Responses

- Forbidden
- Internal Server Error

#### Business Logic

- Return wallet balance derived from ledger entries.
- Side effects: none.

---

### Route 2: Get Wallet Transactions

- HTTP Method: `GET`
- Endpoint: `/users/{userId}/wallet/transactions`
- Description: List wallet transaction history.
- Authentication Required: Yes
- Authorized Roles: `end_user`, `admin`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Wallet transactions retrieved successfully",
  "data": {
    "items": []
  }
}
```

#### Error Responses

- Forbidden
- Internal Server Error

#### Business Logic

- Return ledger transactions belonging to the wallet.
- Side effects: none.

---

## 3.16 PayoutController

### Controller Summary

- Purpose: Track payouts and approve payouts for brands.
- Description: Supports payout history retrieval and admin approval workflows.
- Authentication Required: Yes
- Authorized Roles: `brand`, `admin`

### Routes

### Route 1: List Brand Payouts

- HTTP Method: `GET`
- Endpoint: `/brands/{brandId}/payouts`
- Description: Retrieve payouts for a brand.
- Authentication Required: Yes
- Authorized Roles: `brand`, `admin`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Payouts retrieved successfully",
  "data": {
    "items": []
  }
}
```

#### Error Responses

- Forbidden
- Internal Server Error

#### Business Logic

- Return payout records for the brand.
- Side effects: none.

---

### Route 2: Approve Payout

- HTTP Method: `POST`
- Endpoint: `/admin/payouts/{payoutId}/approve`
- Description: Approve a pending payout.
- Authentication Required: Yes
- Authorized Roles: `admin`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Payout approved successfully",
  "data": {
    "payoutId": "uuid"
  }
}
```

#### Error Responses

- Validation Error
- Forbidden
- Internal Server Error

#### Business Logic

- Transition payout from pending to approved after validation.
- Side effects: append admin audit entry and notify brand.

---

## 3.17 ChatController

### Controller Summary

- Purpose: Manage chat threads and inbound message handling.
- Description: Allows end users or brands to start, view, and report chat threads.
- Authentication Required: Yes
- Authorized Roles: `end_user`, `brand`, `admin`, `courier`

### Routes

### Route 1: Create Chat Thread

- HTTP Method: `POST`
- Endpoint: `/chats`
- Description: Start a conversation between user and brand.
- Authentication Required: Yes
- Authorized Roles: `end_user`, `brand`

#### Request Input

- Request Body
  - `brandId` (required): string
- Validation Rules: brand must be valid

#### Success Response

- Status Code: `201`
- Example JSON

```json
{
  "success": true,
  "message": "Chat thread created successfully",
  "data": {
    "threadId": "uuid"
  }
}
```

#### Error Responses

- Validation Error
- Conflict
- Internal Server Error

#### Business Logic

- Create a thread and link participants.
- Side effects: notify the counterpart.

---

### Route 2: List Messages

- HTTP Method: `GET`
- Endpoint: `/chats/{threadId}/messages`
- Description: Retrieve messages in a thread.
- Authentication Required: Yes
- Authorized Roles: Thread participants and `admin`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Messages retrieved successfully",
  "data": {
    "items": []
  }
}
```

#### Error Responses

- Forbidden
- Not Found
- Internal Server Error

#### Business Logic

- Return messages for authorized participants.
- Side effects: none.

---

### Route 3: Send Message

- HTTP Method: `POST`
- Endpoint: `/chats/{threadId}/messages`
- Description: Send a message to an existing thread.
- Authentication Required: Yes
- Authorized Roles: Thread participants

#### Request Input

- Request Body
  - `content` (required): string
- Validation Rules: content must not be empty

#### Success Response

- Status Code: `201`
- Example JSON

```json
{
  "success": true,
  "message": "Message sent successfully",
  "data": {
    "messageId": "uuid"
  }
}
```

#### Error Responses

- Validation Error
- Forbidden
- Internal Server Error

#### Business Logic

- Persist the message and create notification events.
- Side effects: send asynchronous notification.

---

### Route 4: Report Thread or Message

- HTTP Method: `POST`
- Endpoint: `/chats/{threadId}/report`
- Description: Report abusive or suspicious content.
- Authentication Required: Yes
- Authorized Roles: Thread participants, `admin`

#### Request Input

- Request Body
  - `messageId` (optional): string
  - `reason` (required): string
- Validation Rules: reason must be supplied

#### Success Response

- Status Code: `201`
- Example JSON

```json
{
  "success": true,
  "message": "Report submitted successfully",
  "data": {
    "reportId": "uuid"
  }
}
```

#### Error Responses

- Validation Error
- Internal Server Error

#### Business Logic

- Create a moderation report for admin review.
- Side effects: add to moderation queue.

---

## 3.18 NotificationController

### Controller Summary

- Purpose: List and mark notifications as read.
- Description: Exposes notifications to the authenticated identity.
- Authentication Required: Yes
- Authorized Roles: All authenticated roles

### Routes

### Route 1: List Notifications

- HTTP Method: `GET`
- Endpoint: `/notifications`
- Description: Retrieve the current user's notifications.
- Authentication Required: Yes
- Authorized Roles: All authenticated roles

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Notifications retrieved successfully",
  "data": {
    "items": []
  }
}
```

#### Error Responses

- Unauthorized
- Internal Server Error

#### Business Logic

- Return notifications linked to the current user.
- Side effects: none.

---

### Route 2: Mark Notification as Read

- HTTP Method: `PATCH`
- Endpoint: `/notifications/{id}/read`
- Description: Mark a notification as read.
- Authentication Required: Yes
- Authorized Roles: All authenticated roles

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Notification marked as read",
  "data": {}
}
```

#### Error Responses

- Not Found
- Forbidden
- Internal Server Error

#### Business Logic

- Update notification read state.
- Side effects: none.

---

## 3.19 AdminController

### Controller Summary

- Purpose: Provide admin governance and operational controls.
- Description: Covers dashboard insights, verification, disputes, moderation, ranking overrides, payout oversight, and sub-admin management.
- Authentication Required: Yes
- Authorized Roles: `admin`, `sub_admin`

### Routes

### Route 1: Get Platform Dashboard

- HTTP Method: `GET`
- Endpoint: `/admin/dashboard`
- Description: Retrieve KPI and operational dashboard data.
- Authentication Required: Yes
- Authorized Roles: `admin`, `sub_admin`

#### Query Parameters

- `dateFrom` (optional)
- `dateTo` (optional)
- `granularity` (optional)

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Dashboard retrieved successfully",
  "data": {
    "gmv": 0,
    "activeUsers": 0,
    "activeBrands": 0
  }
}
```

#### Error Responses

- Forbidden
- Internal Server Error

#### Business Logic

- Aggregate dashboard metrics from orders, brands, payments, and delivery data.
- Side effects: none.

---

### Route 2: List Brands for Admin Review

- HTTP Method: `GET`
- Endpoint: `/admin/brands`
- Description: Review brand applications and active brands.
- Authentication Required: Yes
- Authorized Roles: `admin`, `sub_admin`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Brands retrieved successfully",
  "data": {
    "items": []
  }
}
```

#### Error Responses

- Forbidden
- Internal Server Error

#### Business Logic

- Return brand records for review and governance.
- Side effects: none.

---

### Route 3: Verify/Reject/Suspend Brand

- HTTP Method: `PATCH`
- Endpoint: `/admin/brands/{brandId}/verify` or `/admin/brands/{brandId}/reject` or `/admin/brands/{brandId}/suspend`
- Description: Update brand verification or status.
- Authentication Required: Yes
- Authorized Roles: `admin`

#### Request Input

- Request Body
  - `tier` (for verify) or `reason` (for reject/suspend)
- Validation Rules: admin must have permission and the brand must exist

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Brand status updated successfully",
  "data": {
    "brandId": "uuid"
  }
}
```

#### Error Responses

- Validation Error
- Forbidden
- Internal Server Error

#### Business Logic

- Change verification state and update ranking eligibility.
- Side effects: notify brand, append audit log, possibly trigger ranking recalculation.

---

### Route 4: List Payouts for Admin Review

- HTTP Method: `GET`
- Endpoint: `/admin/payouts`
- Description: Review pending and completed payouts.
- Authentication Required: Yes
- Authorized Roles: `admin`

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Payouts retrieved successfully",
  "data": {
    "items": []
  }
}
```

#### Error Responses

- Forbidden
- Internal Server Error

#### Business Logic

- Return payout records requiring oversight.
- Side effects: none.

---

### Route 5: Resolve Disputes

- HTTP Method: `PATCH`
- Endpoint: `/admin/disputes/{disputeId}/resolve`
- Description: Resolve a dispute and record the outcome.
- Authentication Required: Yes
- Authorized Roles: `admin`

#### Request Input

- Request Body
  - `outcome` (required): string
  - `refundAmount` (optional): number
  - `notes` (optional): string

#### Success Response

- Status Code: `200`
- Example JSON

```json
{
  "success": true,
  "message": "Dispute resolved successfully",
  "data": {
    "disputeId": "uuid"
  }
}
```

#### Error Responses

- Validation Error
- Forbidden
- Internal Server Error

#### Business Logic

- Resolve disputes and log admin action.
- Side effects: create audit trail and possibly process refund.

---

## 3.20 UploadController

### Controller Summary

- Purpose: Handle generic file uploads for documents, images, and proofs.
- Description: Accepts multipart uploads for profile pictures, brand docs, product media, and delivery proof.
- Authentication Required: Yes
- Authorized Roles: `brand`, `end_user`, `courier`, `admin`

### Routes

### Route 1: Upload File

- HTTP Method: `POST`
- Endpoint: `/uploads`
- Description: Upload a file that will be stored and linked to the relevant resource.
- Authentication Required: Yes
- Authorized Roles: `brand`, `end_user`, `courier`, `admin`

#### Request Input

- Headers: `Content-Type: multipart/form-data`
- Request Body: file and metadata
- Validation Rules:
  - File type and size must be allowed
  - The authenticated user must be authorized for the target resource

#### Success Response

- Status Code: `201`
- Example JSON

```json
{
  "success": true,
  "message": "File uploaded successfully",
  "data": {
    "fileId": "uuid",
    "url": "https://cdn.example.com/file"
  }
}
```

#### Error Responses

- Validation Error
- Forbidden
- Internal Server Error

#### Business Logic

- Store file and return a public or signed URL.
- Side effects: create audit or media-link record.

---

## 4. Cross-Cutting Business Rules

- All protected routes require a valid JWT.
- All mutations affecting money, order state, brand verification, or moderation must be logged.
- Checkout, payment, and payout transitions must be transactional.
- Brand profiles are only publicly visible if the brand has an approved verification state.
- Reviews must only be created for completed purchases.
- Delivery proof is required for a successful delivered status.
- Admin actions must be auditable.
- Product deletion should be soft-deletion to preserve order history.
- Category deletion should preserve references or require reassignment.

---

## 5. Notes for Implementers

- This contract intentionally avoids implementation-specific code.
- The routes above reflect the functional scope documented in the requirements and schema.
- Any future extensions should be added as new routes or versioned endpoints under `/api/v2` if the contract changes materially.
