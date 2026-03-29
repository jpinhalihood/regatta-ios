# API Versioning Reference

## Strategy Comparison

| Strategy | Example | Pros | Cons | Best for |
|---|---|---|---|---|
| **URL path** | `/v1/users` | Explicit, cacheable, easy to test | Verbose URLs | Public APIs, strong deprecation needs |
| **Date-based header** | `API-Version: 2024-01-15` | Clean URLs, Stripe-style | Less discoverable | Internal/partner APIs |
| **Semver header** | `Accept-Version: 2.1.0` | Familiar versioning | Complex negotiation | Library-style APIs |
| **Content negotiation** | `Accept: application/vnd.api.v2+json` | True REST | Very complex | Rarely recommended |
| **Query param** | `?version=2` | Simple | Pollutes URLs, caching issues | Avoid |

**Default recommendation: URL path versioning** (`/v1/`, `/v2/`)

---

## URL Path Versioning (Recommended)

### Structure
```
https://api.example.com/v1/users
https://api.example.com/v2/users   # when breaking changes needed
```

### Rules
- Version the **entire API surface** under `/v{N}/`
- Integer major versions only (`v1`, `v2` — not `v1.2`)
- New version only for **breaking changes** — add non-breaking changes to current version
- Maintain at least the previous version for 6–12 months after deprecation

### Deprecation process
```
1. Announce deprecation date at least 3 months in advance
2. Add Deprecation header to responses from old version:
   Deprecation: true
   Sunset: Sat, 01 Jan 2025 00:00:00 GMT
   Link: <https://api.example.com/v2/users>; rel="successor-version"
3. Log and alert on usage of deprecated endpoints
4. Sunset (shut down) after date passes
```

### OpenAPI multi-version servers
```yaml
servers:
  - url: https://api.example.com/v2
    description: Production (current)
  - url: https://api.example.com/v1
    description: Production (deprecated — sunset 2025-01-01)
```

---

## Date-Based Header Versioning (Stripe-style)

### Structure
```
GET /users
API-Version: 2024-06-01
```

### Rules
- Client pins to a date — they get API behavior as of that date
- New dates added when breaking changes ship
- Client must explicitly opt in to new dates
- Old dates supported for 12–24 months

### Implementation
```
# Response always echoes the version used
API-Version: 2024-06-01

# Available versions in response headers
API-Version-Latest: 2024-12-01
API-Version-Sunset: 2024-01-01 (if applicable)
```

---

## What Requires a New Version (Breaking Changes)

**ALWAYS version bump:**
- Removing a field from a response
- Renaming a field
- Changing a field's data type (string → integer)
- Changing a field from optional to required in a request
- Removing an endpoint
- Changing URL structure
- Changing auth scheme
- Changing pagination format
- Removing enum values

**SAFE to add without version bump (non-breaking):**
- Adding new optional fields to responses
- Adding new endpoints
- Adding new optional query parameters
- Adding new enum values (with caution — clients must handle unknown values)
- Loosening validation (accepting more values)
- Adding new optional request body fields
- Improving error messages (same code, better message)

---

## Changelog Template

Include in API design doc and OpenAPI info description:

```markdown
## Changelog

### v1.2.0 — 2024-06-01
- Added `GET /users?search=` full-text search parameter
- Added `avatarUrl` field to User response
- Added `POST /orders/{id}/duplicate` endpoint

### v1.1.0 — 2024-03-15
- Added cursor-based pagination to `GET /products`
- Added `X-RateLimit-*` headers to all responses
- Improved error messages for 422 responses

### v1.0.0 — 2024-01-15
- Initial release
```
