---
name: rest-api-designer
description: >
  Expert RESTful API architect that designs complete, production-grade APIs from
  scratch or from requirements. Use this skill whenever the user wants to design,
  plan, spec, or scaffold a REST API — even if they just say "API", "endpoints",
  "routes", "backend", "CRUD", "build me a service", or "how should I structure
  my API". Always triggers for: designing new APIs, reviewing or improving
  existing API designs, creating OpenAPI/Swagger specs, generating route
  scaffolding, planning auth or versioning strategy, or any request to "build
  an API for X". Produces: API design documents (Markdown), OpenAPI 3.1 specs
  (YAML), and framework-agnostic code scaffolding (routes, controllers,
  middleware). Covers resource modeling, auth (JWT/OAuth/API keys), versioning,
  pagination, filtering, error handling, rate limiting, and security.
---

# REST API Designer

An expert skill for designing production-grade RESTful APIs from scratch —
framework-agnostic, covering the full design lifecycle from resource modeling
through OpenAPI specs and code scaffolding.

## Workflow Overview

1. **Gather requirements** — Understand the domain, resources, and constraints
2. **Model resources** — Design URL structure, relationships, and operations
3. **Design cross-cutting concerns** — Auth, versioning, errors, pagination
4. **Produce outputs** — Design doc, OpenAPI spec, code scaffolding
5. **Review checklist** — Validate against REST best practices

---

## Step 1: Requirements Gathering

Before designing, collect:

- **Domain description**: What is the application? (e-commerce, SaaS, social, etc.)
- **Primary resources**: What are the main entities? (Users, Orders, Products...)
- **Consumers**: Who calls this API? (Web frontend, mobile app, third-party, internal services)
- **Auth requirements**: Public endpoints? User auth? Machine-to-machine?
- **Scale expectations**: Approximate request volume, data size
- **Existing constraints**: Database already chosen? Existing schemas to respect?

If the user provides a description or existing system, **extract what you can and proceed** — only ask for missing critical pieces.

### Quick-start domains (skip interview, apply template)
For well-known domains, jump straight to design using `references/domain-templates.md`:
- **E-commerce**: products, orders, carts, users, reviews, categories
- **SaaS / multi-tenant**: tenants, users, memberships, subscriptions, billing
- **Blog / CMS**: posts, authors, tags, comments, media, categories
- **Social / community**: users, posts, follows, likes, notifications
- **Auth service**: users, sessions, tokens, roles, permissions

---

## Step 2: Resource Modeling

### Naming Rules

| Rule | Good | Bad |
|---|---|---|
| Plural nouns for collections | `/users` | `/user`, `/getUsers` |
| Lowercase, hyphen-separated | `/blog-posts` | `/blogPosts`, `/BlogPosts` |
| No verbs in path | `/orders/{id}/cancel` (POST) | `/cancelOrder` |
| Nested for ownership (max 2 levels) | `/users/{id}/orders` | `/users/{id}/orders/{oid}/items/{iid}/reviews` |
| Resource identifiers in path | `/users/{userId}` | `/users?id=123` |

### Standard CRUD Mapping

| Operation | Method | Path | Success Code |
|---|---|---|---|
| List collection | GET | `/resources` | 200 |
| Create resource | POST | `/resources` | 201 |
| Get single | GET | `/resources/{id}` | 200 |
| Full replace | PUT | `/resources/{id}` | 200 |
| Partial update | PATCH | `/resources/{id}` | 200 |
| Delete | DELETE | `/resources/{id}` | 204 |

### Non-CRUD Actions

Use POST with a verb sub-resource for actions that don't map to CRUD:
```
POST /orders/{id}/cancel
POST /users/{id}/verify-email
POST /payments/{id}/refund
POST /sessions  (login)
DELETE /sessions/{id}  (logout)
```

### Relationship Patterns

```
# Owned sub-resources (always scoped to parent)
GET    /users/{userId}/addresses
POST   /users/{userId}/addresses
DELETE /users/{userId}/addresses/{addressId}

# Many-to-many associations
POST   /posts/{postId}/tags        # add tag to post
DELETE /posts/{postId}/tags/{tagId} # remove tag from post
GET    /posts/{postId}/tags        # list tags on post

# Cross-resource queries (use top-level with filter)
GET /orders?userId={userId}        # preferred over /users/{id}/all-orders-ever
```

---

## Step 3: Cross-Cutting Concerns

### 3a. Versioning

Read `references/versioning.md` for full guidance. Quick decision:

| Strategy | Format | When to use |
|---|---|---|
| **URL path** (recommended) | `/v1/users` | Public APIs, clear deprecation path |
| Header | `API-Version: 2024-01-01` | Internal/partner APIs (Stripe-style) |
| Query param | `?version=2` | Avoid — pollutes every request |

**Always version from day one.** Default: URL path versioning at `/v1/`.

Breaking vs. non-breaking changes:
- **Non-breaking** (safe to add without new version): new optional fields, new endpoints, new optional query params
- **Breaking** (requires new version): removing fields, changing field types, changing URL structure, changing auth scheme

### 3b. Authentication & Authorization

Read `references/auth-patterns.md` for full patterns. Quick selection:

| Use Case | Recommended Pattern |
|---|---|
| User-facing web/mobile app | JWT Bearer tokens (access + refresh) |
| Machine-to-machine / server | API keys (in `Authorization: Bearer` header) |
| Third-party OAuth (social login) | OAuth 2.0 Authorization Code flow |
| Internal microservices | mTLS or shared secret in header |
| Public read + authenticated write | Mixed: public GET, JWT for mutations |

**Always:**
- Tokens in `Authorization: Bearer <token>` header, never in URLs
- HTTPS only — document this explicitly in the spec
- Separate authentication (who are you) from authorization (what can you do)
- Return `401 Unauthorized` for missing/invalid credentials, `403 Forbidden` for valid credentials lacking permission

### 3c. Error Handling

**Standard error response envelope — use consistently across all endpoints:**

```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "Request validation failed",
    "details": [
      {
        "field": "email",
        "issue": "Must be a valid email address"
      }
    ],
    "requestId": "req_01HX5Y3Z...",
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

**HTTP Status Code Reference:**

| Code | When to use |
|---|---|
| 200 OK | Successful GET, PUT, PATCH |
| 201 Created | Successful POST that creates a resource |
| 204 No Content | Successful DELETE, or action with no body |
| 400 Bad Request | Malformed request, validation failure |
| 401 Unauthorized | Missing or invalid authentication |
| 403 Forbidden | Authenticated but not authorized |
| 404 Not Found | Resource doesn't exist |
| 409 Conflict | Duplicate resource, state conflict |
| 422 Unprocessable Entity | Syntactically valid but semantically wrong |
| 429 Too Many Requests | Rate limit exceeded |
| 500 Internal Server Error | Unexpected server error |
| 503 Service Unavailable | Maintenance or overload |

Read `references/error-catalog.md` for a full error code catalog by domain.

### 3d. Pagination, Filtering & Sorting

**Cursor-based pagination (recommended for large/real-time datasets):**
```
GET /posts?limit=20&cursor=eyJpZCI6MTIzfQ==
Response headers:
  X-Next-Cursor: eyJpZCI6MTQzfQ==
  X-Has-More: true
```

**Offset-based pagination (acceptable for small, stable datasets):**
```
GET /products?page=2&pageSize=25
Response body includes:
  "pagination": { "page": 2, "pageSize": 25, "total": 847, "totalPages": 34 }
```

**Filtering:**
```
GET /orders?status=pending&createdAfter=2024-01-01&userId=usr_123
GET /products?minPrice=10&maxPrice=100&category=electronics&inStock=true
```

**Sorting:**
```
GET /posts?sort=createdAt&order=desc
GET /products?sort=price,name&order=asc,asc   # multi-field
```

**Field selection (sparse fieldsets):**
```
GET /users?fields=id,email,name   # return only requested fields
```

### 3e. Rate Limiting & Security

**Always include in response headers:**
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 847
X-RateLimit-Reset: 1705312800
Retry-After: 60  (on 429 responses only)
```

**Rate limit tiers (framework-agnostic defaults):**
- Public unauthenticated: 60 req/min per IP
- Authenticated standard: 1000 req/min per user
- Authenticated premium / service: 10,000 req/min per key
- Sensitive endpoints (login, password reset): 10 req/min per IP

**Security headers to document:**
```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Content-Security-Policy: default-src 'none'
```

**Security rules:**
- Validate and sanitize ALL inputs server-side
- Use UUIDs or opaque IDs (never expose sequential integers for sensitive resources)
- Enforce object-level authorization on every request (re-check ownership, don't trust client)
- Never return stack traces or internal errors to clients in production
- Log all auth failures with IP, user agent, and timestamp

---

## Step 4: Producing Outputs

This skill produces **three deliverable types**. Always produce all three unless the user specifies otherwise.

### Output A: API Design Document

A human-readable Markdown document. Structure:
```
# {API Name} API Design
## Overview
## Base URL & Versioning
## Authentication
## Resources
  ### {Resource}
    #### Endpoints
    #### Request/Response Examples
## Error Handling
## Rate Limiting
## Changelog
```

Save as: `{api-name}-api-design.md`

### Output B: OpenAPI 3.1 Spec

A complete, valid OpenAPI 3.1 YAML spec. Read `references/openapi-template.md` for
the canonical template and patterns to follow.

Key requirements:
- `openapi: "3.1.0"` at top
- Full `info` block with title, version, description, contact
- All servers listed (prod, staging, local)
- `components/schemas` for all request/response bodies (no inline schemas)
- `components/securitySchemes` defined and applied globally + per-endpoint overrides
- `components/responses` for reusable error responses (400, 401, 403, 404, 429, 500)
- `components/parameters` for reusable path/query params (pagination, filters)
- Tags for grouping endpoints by resource
- Examples on all request/response bodies

Save as: `{api-name}-openapi.yaml`

### Output C: Code Scaffolding

Framework-agnostic route + controller structure. Read `references/scaffolding-patterns.md`
for language-specific patterns (Node/Express, Python/FastAPI, Go/Chi, etc.).

Always produce:
- **Router / route definitions** — URL patterns and HTTP methods mapped to handlers
- **Controller stubs** — One function per endpoint with JSDoc/docstrings, typed params, error handling structure
- **Middleware stubs** — Auth middleware, rate limiter, validation middleware
- **Types / schemas** — Request/response types or validation schemas

Save as: `{api-name}-scaffolding/` directory with `routes/`, `controllers/`, `middleware/`, `types/`

### Output D: Handoff Contract

**Always append this section to the API Design Document.** It is a machine-readable
summary consumed by downstream skills (prisma-model-designer, project-brief) so they
can continue work without re-interviewing the user.

Append verbatim at the bottom of `{api-name}-api-design.md`:

```markdown
---
## Handoff Contract
<!-- MACHINE-READABLE: consumed by prisma-model-designer and project-brief -->

project: {api-name}
description: {one-line description of what the API does}
auth: {JWT | API-Key | OAuth2 | None}
database_hint: {postgresql | sqlite | unknown}
base_url: /v1

resources:
  - name: {ModelName}
    fields:
      - name: id
        type: String
        constraints: [pk, cuid]
      - name: {fieldName}
        type: {String | Int | Boolean | DateTime | Float | Json}
        constraints: [{optional, unique, indexed, fk:<ModelName>}]
    relations:
      - model: {RelatedModel}
        type: {one-to-one | one-to-many | many-to-many}
        through: {JoinModel}   # only for many-to-many
        onDelete: {Cascade | SetNull | Restrict}
    enums:
      - name: {EnumName}
        values: [{VALUE_A, VALUE_B}]

enums:
  - name: {EnumName}
    values: [{VALUE_A, VALUE_B}]

notes:
  - {Any design decision the Prisma skill should know about}
```

**Rules for populating the contract:**
- One entry per API resource that maps to a database table
- Include ALL fields visible in the OpenAPI spec request/response schemas
- Mark foreign key fields with `fk:<ModelName>` in constraints
- Infer `onDelete` from business logic (e.g. "delete user → delete posts" = Cascade)
- `database_hint` comes from user input or defaults to `postgresql`
- Do NOT include pagination/filter query params as fields — those are API concerns only
- If a field is in the API but clearly derived/computed (not stored), omit it

---

## Step 5: Design Review Checklist

Before finalizing any API design, verify:

**Resource Design**
- [ ] All collection endpoints use plural nouns
- [ ] No verbs in resource paths (except action sub-resources)
- [ ] Nesting max 2 levels deep
- [ ] Consistent ID parameter naming (`{resourceId}` pattern)

**HTTP Semantics**
- [ ] GET requests are idempotent and safe (no side effects)
- [ ] POST for create returns 201 with `Location` header
- [ ] DELETE returns 204 with empty body
- [ ] PATCH used for partial update, PUT for full replace
- [ ] Appropriate status codes on all paths (success AND error)

**Auth & Security**
- [ ] Every endpoint has explicit auth requirement documented
- [ ] 401 vs 403 used correctly
- [ ] No sensitive data in URL paths or query params
- [ ] Rate limiting documented

**Consistency**
- [ ] Same field naming convention throughout (camelCase recommended for JSON)
- [ ] Dates in ISO 8601 format (`2024-01-15T10:30:00Z`)
- [ ] IDs consistently prefixed or formatted (e.g., `usr_`, `ord_` or UUIDs)
- [ ] Error responses use the same envelope shape everywhere
- [ ] Pagination uses the same pattern across all list endpoints

**OpenAPI Spec**
- [ ] All schemas defined in `components/schemas` (no inline)
- [ ] All endpoints have at least one 4xx response documented
- [ ] All required vs. optional fields marked correctly
- [ ] Examples provided for request/response bodies

**Handoff Contract**
- [ ] Appended to the bottom of the API design doc
- [ ] Every resource that maps to a DB table is listed
- [ ] All relations include `type` and `onDelete`
- [ ] `auth` and `database_hint` are populated
- [ ] No API-only concerns (pagination params, computed fields) included as schema fields

---

## Explaining Your Decisions

After every design, include a **Design Notes** section:
- Key resource modeling decisions and trade-offs
- Why a specific auth pattern was chosen
- Pagination strategy rationale
- Any deliberate deviations from REST convention and why
- Suggested future API evolution path (v2 considerations)

---

## Reference Files

| File | When to read |
|---|---|
| `references/openapi-template.md` | Always — when producing OpenAPI spec |
| `references/auth-patterns.md` | When designing auth — JWT, OAuth, API keys |
| `references/versioning.md` | When advising on versioning strategy |
| `references/error-catalog.md` | When defining error codes and catalog |
| `references/scaffolding-patterns.md` | When producing code scaffolding |
| `references/domain-templates.md` | When working with a known domain type |

## Downstream Skills

This skill's outputs feed directly into:
- **prisma-model-designer** — consumes the Handoff Contract to build `schema.prisma` with no re-interviewing
- **project-brief** — consumes the Handoff Contract to orchestrate the full build pipeline

Always produce Output D (Handoff Contract) so these skills can operate autonomously.
