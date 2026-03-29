# Error Code Catalog

## Error Response Envelope (always use this shape)

```json
{
  "error": {
    "code": "MACHINE_READABLE_CODE",
    "message": "Human-readable description",
    "details": [            // optional — for validation errors
      { "field": "email", "issue": "Must be a valid email address" }
    ],
    "requestId": "req_01HX5Y3Z",   // always include for support tracing
    "timestamp": "2024-01-15T10:30:00Z",
    "docs": "https://docs.example.com/errors/MACHINE_READABLE_CODE"  // optional
  }
}
```

---

## Standard Error Codes by Category

### Authentication & Authorization (401, 403)

| Code | HTTP | When |
|---|---|---|
| `UNAUTHORIZED` | 401 | No auth credentials provided |
| `TOKEN_INVALID` | 401 | Malformed or invalid token |
| `TOKEN_EXPIRED` | 401 | Access token has expired |
| `TOKEN_REVOKED` | 401 | Token explicitly revoked |
| `REFRESH_TOKEN_INVALID` | 401 | Refresh token invalid or expired |
| `API_KEY_INVALID` | 401 | API key not found or revoked |
| `FORBIDDEN` | 403 | Valid auth, insufficient permissions |
| `TENANT_SUSPENDED` | 403 | Account or tenant suspended |
| `EMAIL_NOT_VERIFIED` | 403 | Action requires verified email |
| `MFA_REQUIRED` | 403 | Multi-factor authentication required |
| `SCOPE_INSUFFICIENT` | 403 | Token missing required scope |

### Validation (400, 422)

| Code | HTTP | When |
|---|---|---|
| `VALIDATION_FAILED` | 400 | One or more fields failed validation |
| `REQUIRED_FIELD_MISSING` | 400 | Required field not present |
| `INVALID_FORMAT` | 400 | Field format incorrect (email, UUID, date) |
| `INVALID_ENUM_VALUE` | 400 | Field value not in allowed enum |
| `VALUE_OUT_OF_RANGE` | 400 | Number/string outside min/max |
| `BODY_REQUIRED` | 400 | Request body missing |
| `INVALID_JSON` | 400 | Malformed JSON body |
| `UNSUPPORTED_CONTENT_TYPE` | 415 | Content-Type not supported |
| `UNPROCESSABLE_ENTITY` | 422 | Valid format, invalid semantics |
| `INVALID_QUERY_PARAM` | 400 | Query parameter value invalid |

### Resource Errors (404, 409, 410)

| Code | HTTP | When |
|---|---|---|
| `NOT_FOUND` | 404 | Resource does not exist |
| `ENDPOINT_NOT_FOUND` | 404 | Route doesn't exist |
| `GONE` | 410 | Resource permanently deleted |
| `CONFLICT` | 409 | General state conflict |
| `DUPLICATE_RESOURCE` | 409 | Unique constraint violated |
| `EMAIL_ALREADY_EXISTS` | 409 | Email already registered |
| `USERNAME_TAKEN` | 409 | Username not available |
| `SLUG_TAKEN` | 409 | URL slug already in use |
| `OPTIMISTIC_LOCK_CONFLICT` | 409 | Concurrent modification detected |

### State Machine Errors (409, 422)

| Code | HTTP | When |
|---|---|---|
| `INVALID_STATE_TRANSITION` | 409 | Action not allowed in current state |
| `ORDER_NOT_CANCELLABLE` | 409 | Order status prevents cancellation |
| `PAYMENT_ALREADY_CAPTURED` | 409 | Payment in non-refundable state |
| `SUBSCRIPTION_ALREADY_ACTIVE` | 409 | Cannot re-activate active subscription |

### Rate Limiting (429)

| Code | HTTP | When |
|---|---|---|
| `RATE_LIMIT_EXCEEDED` | 429 | General rate limit hit |
| `TOO_MANY_LOGIN_ATTEMPTS` | 429 | Login brute force protection |
| `TOO_MANY_REQUESTS_PER_IP` | 429 | IP-level rate limit |
| `QUOTA_EXCEEDED` | 429 | Monthly/billing quota exhausted |
| `CONCURRENT_LIMIT_EXCEEDED` | 429 | Too many simultaneous requests |

### Server Errors (500, 502, 503)

| Code | HTTP | When |
|---|---|---|
| `INTERNAL_ERROR` | 500 | Unexpected server error |
| `DATABASE_ERROR` | 500 | Database operation failed |
| `UPSTREAM_ERROR` | 502 | Dependency service failed |
| `SERVICE_UNAVAILABLE` | 503 | Planned maintenance or overload |
| `TIMEOUT` | 504 | Request processing timed out |

---

## Domain-Specific Error Codes

### E-commerce
```
PRODUCT_OUT_OF_STOCK          409   Cannot add to cart
INSUFFICIENT_INVENTORY        409   Quantity not available
CART_EMPTY                    422   Checkout requires items
SHIPPING_UNAVAILABLE          422   No shipping to destination
COUPON_INVALID                400   Coupon code not found
COUPON_EXPIRED                400   Coupon past expiry date
COUPON_ALREADY_USED           409   Single-use coupon redeemed
PAYMENT_DECLINED              422   Card declined by issuer
PAYMENT_REQUIRES_ACTION       402   3DS authentication needed
REFUND_WINDOW_EXPIRED         409   Past refund eligibility period
```

### SaaS / Subscriptions
```
PLAN_LIMIT_REACHED            403   Feature limit for current plan
FEATURE_NOT_AVAILABLE         403   Feature not in current plan
SUBSCRIPTION_REQUIRED         402   Active subscription needed
TRIAL_EXPIRED                 402   Free trial ended
BILLING_REQUIRED              402   Payment method needed
SEAT_LIMIT_REACHED            409   Max team members for plan
```

### Files & Media
```
FILE_TOO_LARGE                413   Exceeds size limit
UNSUPPORTED_FILE_TYPE         415   MIME type not allowed
FILE_INFECTED                 422   Virus/malware detected
FILE_CORRUPTED                422   Cannot process file
STORAGE_QUOTA_EXCEEDED        507   Storage limit reached
```

---

## Error Response Examples

### Validation failure (400)
```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "Request validation failed",
    "details": [
      { "field": "email", "issue": "Must be a valid email address" },
      { "field": "password", "issue": "Must be at least 8 characters" },
      { "field": "age", "issue": "Must be a positive integer" }
    ],
    "requestId": "req_01HX5Y3Z",
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

### Rate limit (429)
```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests. Please slow down.",
    "requestId": "req_01HX5Y3Z",
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```
Response headers: `Retry-After: 47` (seconds until reset)

### State conflict (409)
```json
{
  "error": {
    "code": "ORDER_NOT_CANCELLABLE",
    "message": "Order cannot be cancelled because it has already shipped",
    "details": [
      { "field": "status", "issue": "Current status 'shipped' does not allow cancellation" }
    ],
    "requestId": "req_01HX5Y3Z",
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```
