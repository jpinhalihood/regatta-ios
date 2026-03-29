# Domain Templates

Quick-start resource maps for common API domains. Apply these when the user's
domain matches — skip the full interview and jump to design with these as the base.

---

## E-Commerce API

### Resources & Endpoints

```
# Catalog (public)
GET    /products                    list with filters: category, minPrice, maxPrice, inStock, sort
GET    /products/{id}
GET    /categories
GET    /categories/{id}/products

# Cart (session or user)
GET    /cart
POST   /cart/items                  { productId, quantity }
PATCH  /cart/items/{itemId}         { quantity }
DELETE /cart/items/{itemId}
POST   /cart/apply-coupon           { code }
DELETE /cart/coupon

# Orders
POST   /orders                      checkout — creates order from cart
GET    /orders                      user's orders
GET    /orders/{id}
POST   /orders/{id}/cancel
POST   /orders/{id}/return-request

# Users
POST   /auth/register
POST   /auth/login
GET    /users/me
PATCH  /users/me
GET    /users/me/addresses
POST   /users/me/addresses
PATCH  /users/me/addresses/{id}
DELETE /users/me/addresses/{id}

# Reviews
GET    /products/{id}/reviews
POST   /products/{id}/reviews       requires purchase verification
PATCH  /reviews/{id}
DELETE /reviews/{id}
```

### Key schemas
- **Product**: id, name, slug, description, price, compareAtPrice, currency, sku, inventory, images[], categories[], status (active/inactive/draft)
- **Order**: id, userId, status (pending/processing/shipped/delivered/cancelled/refunded), items[], subtotal, tax, shipping, total, currency, shippingAddress, billingAddress, paymentMethod
- **OrderItem**: id, orderId, productId, productName, sku, quantity, unitPrice, total
- **CartItem**: id, productId, productName, quantity, unitPrice, imageUrl
- **Address**: id, userId, line1, line2, city, state, postalCode, country, isDefault

### Auth: JWT with refresh tokens. Cart accessible without auth (session ID), merged on login.

---

## SaaS / Multi-Tenant API

### Resources & Endpoints

```
# Auth
POST   /auth/login
POST   /auth/refresh
POST   /auth/logout
POST   /auth/register              creates user + new org
POST   /auth/accept-invite         { token }

# Organizations (tenants)
GET    /organizations/me           current org
PATCH  /organizations/me
GET    /organizations/me/members
POST   /organizations/me/members   invite: { email, role }
PATCH  /organizations/me/members/{userId}  { role }
DELETE /organizations/me/members/{userId}

# Subscriptions & Billing
GET    /billing/subscription
POST   /billing/subscription       { planId, paymentMethodId }
PATCH  /billing/subscription       { planId } — upgrade/downgrade
DELETE /billing/subscription       cancel
GET    /billing/invoices
GET    /billing/usage

# API Keys
GET    /api-keys
POST   /api-keys                   { name, scopes[] }
DELETE /api-keys/{id}
POST   /api-keys/{id}/rotate

# Core resource (example: projects)
GET    /projects
POST   /projects
GET    /projects/{id}
PATCH  /projects/{id}
DELETE /projects/{id}
```

### Key schemas
- **Organization**: id, name, slug, plan (free/starter/pro/enterprise), status, createdAt
- **Member**: userId, orgId, role (owner/admin/member/viewer), joinedAt
- **Subscription**: id, orgId, planId, status (active/trialing/past_due/cancelled), currentPeriodEnd, cancelAtPeriodEnd
- **Plan**: id, name, price, currency, interval (month/year), limits{}

### Auth: JWT. All resources scoped to org via `orgId` in JWT. Role-based access per endpoint.
### Multi-tenant rule: every DB query MUST include `WHERE org_id = ?`. Never trust client-provided orgId.

---

## Blog / CMS API

### Resources & Endpoints

```
# Public (no auth required)
GET    /posts                       filter: status=published, category, tag, author, search
GET    /posts/{slug}
GET    /posts/{id}/related
GET    /categories
GET    /tags
GET    /authors/{id}

# Authenticated
POST   /posts                       { title, content, slug, categoryId, tags[], status }
PATCH  /posts/{id}
DELETE /posts/{id}
POST   /posts/{id}/publish
POST   /posts/{id}/unpublish

GET    /posts/{id}/comments
POST   /posts/{id}/comments
PATCH  /comments/{id}
DELETE /comments/{id}
POST   /comments/{id}/moderate      admin only

# Media
POST   /media                       multipart upload
GET    /media
DELETE /media/{id}
```

### Key schemas
- **Post**: id, title, slug, excerpt, content (markdown/HTML), status (draft/published/archived), authorId, categoryId, tags[], featuredImageUrl, publishedAt, readingTimeMinutes, seoTitle, seoDescription
- **Comment**: id, postId, authorName, authorEmail, content, status (pending/approved/spam), parentId (for threading)
- **Category**: id, name, slug, description, parentId
- **Tag**: id, name, slug

### Auth: Public GET endpoints, JWT required for mutations. Role: author (own posts) vs editor (all posts) vs admin.

---

## Social / Community API

### Resources & Endpoints

```
# Users & Profiles
POST   /auth/register
POST   /auth/login
GET    /users/{id}                  public profile
GET    /users/me
PATCH  /users/me
GET    /users/{id}/posts
GET    /users/{id}/followers
GET    /users/{id}/following
POST   /users/{id}/follow
DELETE /users/{id}/follow

# Feed & Posts
GET    /feed                        authenticated user's feed
GET    /posts
POST   /posts                       { content, mediaUrls[], visibility }
GET    /posts/{id}
PATCH  /posts/{id}
DELETE /posts/{id}
POST   /posts/{id}/like
DELETE /posts/{id}/like
GET    /posts/{id}/comments
POST   /posts/{id}/comments
POST   /posts/{id}/report

# Notifications
GET    /notifications
POST   /notifications/mark-read
DELETE /notifications/{id}
GET    /notifications/preferences
PATCH  /notifications/preferences

# Messages (if applicable)
GET    /conversations
POST   /conversations               { participantIds[] }
GET    /conversations/{id}/messages
POST   /conversations/{id}/messages { content }
```

### Key schemas
- **User**: id, username, displayName, bio, avatarUrl, followersCount, followingCount, postsCount, isVerified, isPrivate
- **Post**: id, authorId, content, mediaUrls[], likesCount, commentsCount, visibility (public/followers/private), createdAt
- **Notification**: id, userId, type (like/comment/follow/mention), actorId, resourceId, resourceType, isRead, createdAt

### Auth: JWT. Public profiles configurable. Feed is always authenticated.

---

## Internal / Microservice API

### Design principles for internal APIs
- Simpler auth: shared secret header (`X-Internal-Secret`) or mTLS
- Less strict versioning: header-based `API-Version`
- Richer error detail: stack traces acceptable in non-prod
- More permissive CORS: only trusted internal origins
- No rate limiting (or very high limits): trusted callers
- No pagination limit maximums: callers are trusted services

### Typical resource pattern
```
GET    /internal/users/{id}         fetch user for auth service
POST   /internal/events             publish domain event
GET    /internal/health
GET    /internal/metrics
POST   /internal/webhooks/stripe    inbound webhook
```
