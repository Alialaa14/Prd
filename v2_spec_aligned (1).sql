-- =====================================================================
-- FashionConnect — Schema V2 (Corrected)
-- "Aligned to the uploaded functional spec and business rules"
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE user_role AS ENUM ('admin', 'sub_admin', 'brand', 'end_user', 'delivery_company', 'courier');
CREATE TYPE language_pref AS ENUM ('ar', 'en');
CREATE TYPE brand_verification_tier AS ENUM ('pending', 'basic_verified', 'trusted_verified', 'suspended');
CREATE TYPE sub_order_status AS ENUM (
    'pending', 'accepted', 'rejected', 'preparing', 'ready',
    'picked_up', 'in_transit', 'delivered', 'returned', 'cancelled'
);
CREATE TYPE payment_method AS ENUM ('card_stripe', 'card_paymob', 'wallet', 'cod', 'fawry', 'installment');
CREATE TYPE payment_status AS ENUM ('unpaid', 'paid', 'refunded', 'partial_refund', 'failed');
CREATE TYPE dispute_type AS ENUM ('order', 'chat', 'product');
CREATE TYPE dispute_status AS ENUM ('open', 'investigating', 'resolved', 'dismissed');

-- ---------------------------------------------------------------------
-- AUTH / USERS
-- ---------------------------------------------------------------------
CREATE TABLE users (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone                VARCHAR(20) UNIQUE NOT NULL,
    email                VARCHAR(255) UNIQUE,
    password_hash        VARCHAR(255),
    role                 user_role NOT NULL DEFAULT 'end_user',
    is_verified          BOOLEAN NOT NULL DEFAULT FALSE,
    is_banned            BOOLEAN NOT NULL DEFAULT FALSE,
    profile_picture_url  TEXT,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE permissions (
    permission_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code           VARCHAR(50) UNIQUE NOT NULL,
    description    TEXT
);

CREATE TABLE user_permissions (
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    permission_id  UUID NOT NULL REFERENCES permissions(permission_id) ON DELETE CASCADE,
    granted_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    granted_by     UUID REFERENCES users(id),
    PRIMARY KEY (user_id, permission_id)
);

CREATE TABLE refresh_tokens (
    token_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash   VARCHAR(255) NOT NULL,
    device_info  TEXT,
    expires_at   TIMESTAMPTZ NOT NULL,
    revoked_at   TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE otp_codes (
    otp_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code_hash   VARCHAR(255) NOT NULL,
    purpose     VARCHAR(30) NOT NULL,
    expires_at  TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE addresses (
    address_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    label         VARCHAR(50),
    governorate   VARCHAR(100) NOT NULL,
    city          VARCHAR(100),
    street        TEXT NOT NULL,
    building_no   VARCHAR(20),
    contact_phone VARCHAR(20) NOT NULL,
    is_default    BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- BRANDS + VERIFICATION
-- ---------------------------------------------------------------------
CREATE TABLE brands (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                  UUID NOT NULL REFERENCES users(id),
    display_name             VARCHAR(255) NOT NULL,
    owner_national_id        VARCHAR(100),
    bank_iban                VARCHAR(50),
    verification_status      brand_verification_tier NOT NULL DEFAULT 'pending',
    rating                   NUMERIC(2,1) DEFAULT 0,
    logo_url                 TEXT,
    followers_count          INT NOT NULL DEFAULT 0,
    viewed_times             BIGINT NOT NULL DEFAULT 0,
    is_promoted              BOOLEAN NOT NULL DEFAULT FALSE,
    is_active                BOOLEAN NOT NULL DEFAULT TRUE,
    balance                  NUMERIC(12,2) NOT NULL DEFAULT 0,
    payment_details          JSONB,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE brand_documents (
    document_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    brand_id      UUID NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
    doc_type      VARCHAR(40) NOT NULL,
    file_url      TEXT NOT NULL,
    reviewed_by   UUID REFERENCES users(id),
    reviewed_at   TIMESTAMPTZ,
    status        VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE brand_social_links (
    brand_id  UUID NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
    platform  VARCHAR(30) NOT NULL,
    url       TEXT NOT NULL,
    PRIMARY KEY (brand_id, platform)
);

CREATE TABLE brand_followers (
    brand_id     UUID NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    followed_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (brand_id, user_id)
);

-- ---------------------------------------------------------------------
-- CATALOG
-- ---------------------------------------------------------------------
CREATE TABLE categories (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_ar       VARCHAR(100) NOT NULL,
    name_en       VARCHAR(100),
    image_url     TEXT,
    parent_id     UUID REFERENCES categories(id),
    is_hidden     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE products (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    brand_id        UUID NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
    category_id     UUID REFERENCES categories(id),
    name_ar         VARCHAR(255) NOT NULL,
    name_en         VARCHAR(255),
    description_ar  TEXT,
    description_en  TEXT,
    viewed_count    BIGINT NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE product_media (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id    UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    media_type    VARCHAR(10) NOT NULL CHECK (media_type IN ('photo','video')),
    url           TEXT NOT NULL,
    sort_order    INT NOT NULL DEFAULT 0
);

CREATE TABLE variants (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id           UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    sku                  VARCHAR(100) UNIQUE NOT NULL,
    color                VARCHAR(50),
    size                 VARCHAR(20),
    price                NUMERIC(10,2) NOT NULL,
    stock                INT NOT NULL DEFAULT 0,
    low_stock_threshold  INT NOT NULL DEFAULT 5,
    sold_count           INT NOT NULL DEFAULT 0,
    is_available         BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (product_id, color, size)
);

CREATE TABLE discounts (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code           VARCHAR(50) UNIQUE,
    value          NUMERIC(10,2) NOT NULL,
    discount_type  VARCHAR(10) NOT NULL DEFAULT 'percent' CHECK (discount_type IN ('percent','flat')),
    scope          VARCHAR(20) NOT NULL DEFAULT 'product' CHECK (scope IN ('product','brand','platform')),
    brand_id       UUID REFERENCES brands(id),
    expires_at     TIMESTAMPTZ,
    is_valid       BOOLEAN NOT NULL DEFAULT TRUE,
    usage_limit    INT,
    used_times     INT NOT NULL DEFAULT 0,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE product_discounts (
    product_id   UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    discount_id  UUID NOT NULL REFERENCES discounts(id) ON DELETE CASCADE,
    PRIMARY KEY (product_id, discount_id)
);

CREATE TABLE wishlists (
    user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id            UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    alert_on_price_drop   BOOLEAN NOT NULL DEFAULT FALSE,
    alert_on_restock      BOOLEAN NOT NULL DEFAULT FALSE,
    added_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, product_id)
);

-- ---------------------------------------------------------------------
-- CART
-- ---------------------------------------------------------------------
CREATE TABLE carts (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE cart_items (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cart_id     UUID NOT NULL REFERENCES carts(id) ON DELETE CASCADE,
    variant_id  UUID NOT NULL REFERENCES variants(id),
    quantity    INT NOT NULL CHECK (quantity > 0),
    unit_price  NUMERIC(10,2) NOT NULL,
    UNIQUE (cart_id, variant_id)
);

-- ---------------------------------------------------------------------
-- DELIVERY
-- ---------------------------------------------------------------------
CREATE TABLE delivery_companies (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name          VARCHAR(150) NOT NULL,
    address       TEXT,
    contact_info  JSONB,
    is_verified   BOOLEAN NOT NULL DEFAULT FALSE,
    is_banned     BOOLEAN NOT NULL DEFAULT FALSE,
    balance       NUMERIC(12,2) NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE delivery_zones (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    delivery_company_id  UUID NOT NULL REFERENCES delivery_companies(id) ON DELETE CASCADE,
    name_ar              VARCHAR(100) NOT NULL,
    name_en              VARCHAR(100) NOT NULL,
    governorate          VARCHAR(100) NOT NULL,
    base_fee             NUMERIC(10,2) NOT NULL,
    per_km_fee           NUMERIC(5,2) DEFAULT 0,
    estimated_days_min   INT,
    estimated_days_max   INT,
    is_active            BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE couriers (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    delivery_company_id     UUID NOT NULL REFERENCES delivery_companies(id) ON DELETE CASCADE,
    user_id                 UUID REFERENCES users(id),
    name                    VARCHAR(150) NOT NULL,
    photo_url               TEXT,
    phone_number            VARCHAR(20),
    plate_number            VARCHAR(20),
    national_id_doc_url     TEXT,
    driving_license_doc_url TEXT,
    vehicle_license_doc_url TEXT,
    is_verified             BOOLEAN NOT NULL DEFAULT FALSE,
    is_banned               BOOLEAN NOT NULL DEFAULT FALSE,
    coverage_zone_id        UUID REFERENCES delivery_zones(id),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- ORDERS -> SUB-ORDERS
-- ---------------------------------------------------------------------
CREATE TABLE orders (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number    BIGSERIAL UNIQUE,
    user_id         UUID NOT NULL REFERENCES users(id),
    address_id      UUID NOT NULL REFERENCES addresses(id),
    payment_method  payment_method NOT NULL,
    payment_status  payment_status NOT NULL DEFAULT 'unpaid',
    total_amount    NUMERIC(10,2) NOT NULL,
    discount_id     UUID REFERENCES discounts(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE sub_orders (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id              UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    brand_id              UUID NOT NULL REFERENCES brands(id),
    status                sub_order_status NOT NULL DEFAULT 'pending',
    subtotal              NUMERIC(10,2) NOT NULL,
    discount_amount       NUMERIC(10,2) NOT NULL DEFAULT 0,
    delivery_fee          NUMERIC(10,2) NOT NULL DEFAULT 0,
    total                 NUMERIC(10,2) NOT NULL,
    cod_amount            NUMERIC(10,2),
    brand_earnings        NUMERIC(10,2),
    platform_commission   NUMERIC(10,2),
    delivery_company_id   UUID REFERENCES delivery_companies(id),
    courier_id            UUID REFERENCES couriers(id),
    delivery_otp_hash     VARCHAR(255),
    accepted_at           TIMESTAMPTZ,
    delivered_at          TIMESTAMPTZ,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE sub_order_status_history (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sub_order_id  UUID NOT NULL REFERENCES sub_orders(id) ON DELETE CASCADE,
    status        sub_order_status NOT NULL,
    note          TEXT,
    changed_by    UUID REFERENCES users(id),
    changed_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE order_items (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sub_order_id  UUID NOT NULL REFERENCES sub_orders(id) ON DELETE CASCADE,
    variant_id    UUID NOT NULL REFERENCES variants(id),
    quantity      INT NOT NULL CHECK (quantity > 0),
    unit_price    NUMERIC(10,2) NOT NULL
);

CREATE TABLE discount_usages (
    discount_id  UUID NOT NULL REFERENCES discounts(id) ON DELETE CASCADE,
    user_id      UUID NOT NULL REFERENCES users(id),
    order_id     UUID NOT NULL REFERENCES orders(id),
    used_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (discount_id, user_id, order_id)
);

CREATE TABLE returns (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sub_order_id   UUID NOT NULL REFERENCES sub_orders(id),
    order_item_id  UUID NOT NULL REFERENCES order_items(id),
    reason         TEXT NOT NULL,
    status         VARCHAR(20) NOT NULL DEFAULT 'requested',
    resolution     VARCHAR(20),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- DELIVERY PROOFS / COD RECONCILIATION
-- ---------------------------------------------------------------------
CREATE TABLE delivery_proofs (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sub_order_id  UUID NOT NULL REFERENCES sub_orders(id) ON DELETE CASCADE,
    photo_url     TEXT,
    otp_verified  BOOLEAN NOT NULL DEFAULT FALSE,
    signed_by     VARCHAR(150),
    submitted_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE cod_reconciliations (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    delivery_company_id   UUID NOT NULL REFERENCES delivery_companies(id),
    sub_order_id          UUID NOT NULL REFERENCES sub_orders(id),
    amount_collected      NUMERIC(10,2) NOT NULL,
    amount_remitted       NUMERIC(10,2) NOT NULL DEFAULT 0,
    remitted_at           TIMESTAMPTZ,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- PAYMENTS / PAYOUTS / WALLET
-- ---------------------------------------------------------------------
CREATE TABLE transactions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id        UUID REFERENCES orders(id),
    gateway         VARCHAR(20) NOT NULL,
    gateway_ref     VARCHAR(255),
    amount          NUMERIC(10,2) NOT NULL,
    status          payment_status NOT NULL DEFAULT 'unpaid',
    raw_payload     JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE payouts (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    brand_id       UUID NOT NULL REFERENCES brands(id),
    amount         NUMERIC(12,2) NOT NULL,
    status         VARCHAR(20) NOT NULL DEFAULT 'pending',
    approved_by    UUID REFERENCES users(id),
    approved_at    TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE wallets (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    balance     NUMERIC(12,2) NOT NULL DEFAULT 0,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE wallet_transactions (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id    UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
    amount       NUMERIC(10,2) NOT NULL,
    reason       VARCHAR(30) NOT NULL,
    order_id     UUID REFERENCES orders(id),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE loyalty_points (
    user_id         UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    points_balance  INT NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE referrals (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referrer_id        UUID NOT NULL REFERENCES users(id),
    referred_user_id   UUID UNIQUE REFERENCES users(id),
    status             VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- REVIEWS / RATINGS
-- ---------------------------------------------------------------------
CREATE TABLE reviews (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id),
    product_id          UUID REFERENCES products(id),
    brand_id            UUID REFERENCES brands(id),
    order_item_id       UUID REFERENCES order_items(id),
    rating              SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment             TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (product_id IS NOT NULL OR brand_id IS NOT NULL)
);

CREATE TABLE review_images (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    review_id   UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
    url         TEXT NOT NULL
);

-- ---------------------------------------------------------------------
-- CHAT
-- ---------------------------------------------------------------------
CREATE TABLE chat_threads (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id),
    brand_id    UUID NOT NULL REFERENCES brands(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, brand_id)
);

CREATE TABLE chat_messages (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id   UUID NOT NULL REFERENCES chat_threads(id) ON DELETE CASCADE,
    sender_id   UUID NOT NULL REFERENCES users(id),
    body        TEXT NOT NULL,
    is_flagged  BOOLEAN NOT NULL DEFAULT FALSE,
    sent_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- NOTIFICATIONS
-- ---------------------------------------------------------------------
CREATE TABLE notification_templates (
    id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code     VARCHAR(50) UNIQUE NOT NULL,
    channel  VARCHAR(20) NOT NULL,
    body_ar  TEXT NOT NULL,
    body_en  TEXT
);

CREATE TABLE notifications (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    template_id  UUID REFERENCES notification_templates(id),
    payload      JSONB,
    is_read      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- ADVERTISING / RANKING
-- ---------------------------------------------------------------------
CREATE TABLE ad_packages (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name           VARCHAR(100) NOT NULL,
    price          NUMERIC(10,2) NOT NULL,
    duration_days  INT NOT NULL,
    boost_weight   NUMERIC(5,2) NOT NULL DEFAULT 1.0
);

CREATE TABLE ad_campaigns (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    brand_id     UUID NOT NULL REFERENCES brands(id),
    package_id   UUID NOT NULL REFERENCES ad_packages(id),
    starts_at    TIMESTAMPTZ NOT NULL,
    ends_at      TIMESTAMPTZ NOT NULL,
    budget       NUMERIC(10,2),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE ranking_scores (
    brand_id       UUID PRIMARY KEY REFERENCES brands(id) ON DELETE CASCADE,
    organic_score  NUMERIC(10,4) NOT NULL DEFAULT 0,
    paid_score     NUMERIC(10,4) NOT NULL DEFAULT 0,
    final_score    NUMERIC(10,4) NOT NULL DEFAULT 0,
    computed_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- TRUST, SAFETY, ADMIN
-- ---------------------------------------------------------------------
CREATE TABLE disputes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type            dispute_type NOT NULL,
    raised_by       UUID NOT NULL REFERENCES users(id),
    order_id        UUID REFERENCES orders(id),
    chat_message_id UUID REFERENCES chat_messages(id),
    product_id      UUID REFERENCES products(id),
    status          dispute_status NOT NULL DEFAULT 'open',
    outcome         TEXT,
    refund_amount   NUMERIC(10,2),
    resolved_by     UUID REFERENCES users(id),
    resolved_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE dispute_evidence (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dispute_id  UUID NOT NULL REFERENCES disputes(id) ON DELETE CASCADE,
    url         TEXT NOT NULL,
    media_type  VARCHAR(10) NOT NULL CHECK (media_type IN ('photo','video','document'))
);

CREATE TABLE moderation_flags (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_type  VARCHAR(20) NOT NULL,
    content_id    UUID NOT NULL,
    reason        TEXT,
    flagged_by    UUID REFERENCES users(id),
    status        VARCHAR(20) NOT NULL DEFAULT 'pending',
    reviewed_by   UUID REFERENCES users(id),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE admin_audit_log (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id     UUID NOT NULL REFERENCES users(id),
    action       VARCHAR(100) NOT NULL,
    target_type  VARCHAR(50),
    target_id    UUID,
    details      JSONB,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
