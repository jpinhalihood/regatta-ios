# OpenAPI 3.1 Template & Patterns

Use this as the canonical template when producing OpenAPI specs. Always produce
complete, valid specs — never partial snippets unless explicitly asked.

## Table of Contents
1. [Top-level structure](#top-level-structure)
2. [Info block](#info-block)
3. [Servers](#servers)
4. [Security schemes](#security-schemes)
5. [Reusable components](#reusable-components)
6. [Path patterns](#path-patterns)
7. [Schema patterns](#schema-patterns)

---

## Top-Level Structure

```yaml
openapi: "3.1.0"

info:
  title: My Service API
  version: "1.0.0"
  description: |
    Complete description of what this API does.
    
    ## Authentication
    All endpoints require a Bearer token unless marked as public.
    
    ## Rate Limiting
    Standard: 1000 requests/minute. Headers: X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset.
  contact:
    name: API Support
    email: api@example.com
    url: https://docs.example.com
  license:
    name: MIT
    url: https://opensource.org/licenses/MIT

servers:
  - url: https://api.example.com/v1
    description: Production
  - url: https://staging-api.example.com/v1
    description: Staging
  - url: http://localhost:3000/v1
    description: Local development

tags:
  - name: Users
    description: User management and profiles
  - name: Orders
    description: Order lifecycle management

security:
  - BearerAuth: []   # Applied globally; override per-endpoint as needed

paths:
  # ... endpoints here

components:
  securitySchemes:
    # ... auth schemes
  schemas:
    # ... all request/response schemas
  parameters:
    # ... reusable parameters
  responses:
    # ... reusable error responses
```

---

## Security Schemes

```yaml
components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: JWT access token. Obtain via POST /auth/login.

    ApiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key
      description: API key for machine-to-machine access.

    OAuth2:
      type: oauth2
      flows:
        authorizationCode:
          authorizationUrl: https://auth.example.com/oauth/authorize
          tokenUrl: https://auth.example.com/oauth/token
          scopes:
            read:users: Read user profiles
            write:users: Create and update users
            read:orders: Read orders
            write:orders: Create and update orders
```

---

## Reusable Components

### Reusable Parameters

```yaml
components:
  parameters:
    # Pagination
    PageParam:
      name: page
      in: query
      schema:
        type: integer
        minimum: 1
        default: 1
      description: Page number (1-indexed)

    PageSizeParam:
      name: pageSize
      in: query
      schema:
        type: integer
        minimum: 1
        maximum: 100
        default: 20
      description: Items per page

    CursorParam:
      name: cursor
      in: query
      schema:
        type: string
      description: Opaque cursor for cursor-based pagination

    LimitParam:
      name: limit
      in: query
      schema:
        type: integer
        minimum: 1
        maximum: 100
        default: 20

    # Sorting
    SortParam:
      name: sort
      in: query
      schema:
        type: string
      description: "Field to sort by (prefix with - for descending). E.g.: sort=-createdAt"

    # Common path params
    ResourceId:
      name: id
      in: path
      required: true
      schema:
        type: string
      description: Resource unique identifier
```

### Reusable Responses

```yaml
components:
  responses:
    BadRequest:
      description: Request validation failed
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            error:
              code: VALIDATION_FAILED
              message: Request validation failed
              details:
                - field: email
                  issue: Must be a valid email address
              requestId: req_01HX5Y3Z
              timestamp: "2024-01-15T10:30:00Z"

    Unauthorized:
      description: Authentication required or token invalid
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            error:
              code: UNAUTHORIZED
              message: Invalid or expired authentication token
              requestId: req_01HX5Y3Z
              timestamp: "2024-01-15T10:30:00Z"

    Forbidden:
      description: Insufficient permissions
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'

    NotFound:
      description: Resource not found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            error:
              code: NOT_FOUND
              message: The requested resource was not found
              requestId: req_01HX5Y3Z
              timestamp: "2024-01-15T10:30:00Z"

    Conflict:
      description: Resource already exists or state conflict
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'

    TooManyRequests:
      description: Rate limit exceeded
      headers:
        Retry-After:
          schema:
            type: integer
          description: Seconds until rate limit resets
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'

    InternalError:
      description: Unexpected server error
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
```

### Core Schemas

```yaml
components:
  schemas:
    # Standard error envelope
    ErrorResponse:
      type: object
      required: [error]
      properties:
        error:
          type: object
          required: [code, message]
          properties:
            code:
              type: string
              description: Machine-readable error code
              example: VALIDATION_FAILED
            message:
              type: string
              description: Human-readable error message
            details:
              type: array
              items:
                type: object
                properties:
                  field:
                    type: string
                  issue:
                    type: string
            requestId:
              type: string
              description: Request trace ID for support
            timestamp:
              type: string
              format: date-time

    # Cursor pagination envelope
    CursorPage:
      type: object
      required: [data, pagination]
      properties:
        data:
          type: array
          items: {}   # Override with $ref in each endpoint
        pagination:
          type: object
          required: [limit, hasMore]
          properties:
            limit:
              type: integer
            hasMore:
              type: boolean
            nextCursor:
              type: string
              nullable: true

    # Offset pagination envelope
    OffsetPage:
      type: object
      required: [data, pagination]
      properties:
        data:
          type: array
          items: {}
        pagination:
          type: object
          required: [page, pageSize, total, totalPages]
          properties:
            page:
              type: integer
            pageSize:
              type: integer
            total:
              type: integer
            totalPages:
              type: integer

    # Timestamps mixin (reference in description, copy fields into schemas)
    Timestamps:
      type: object
      readOnly: true
      properties:
        createdAt:
          type: string
          format: date-time
        updatedAt:
          type: string
          format: date-time
```

---

## Path Patterns

### Collection Endpoint (GET list + POST create)

```yaml
paths:
  /users:
    get:
      operationId: listUsers
      summary: List users
      description: Returns a paginated list of users. Results are sorted by createdAt descending by default.
      tags: [Users]
      parameters:
        - $ref: '#/components/parameters/PageParam'
        - $ref: '#/components/parameters/PageSizeParam'
        - name: status
          in: query
          schema:
            type: string
            enum: [active, inactive, suspended]
          description: Filter by account status
        - name: search
          in: query
          schema:
            type: string
          description: Full-text search on name and email
        - $ref: '#/components/parameters/SortParam'
      responses:
        '200':
          description: Paginated list of users
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/OffsetPage'
                  - type: object
                    properties:
                      data:
                        type: array
                        items:
                          $ref: '#/components/schemas/User'
              example:
                data:
                  - id: usr_01HX5Y3Z
                    email: jane@example.com
                    name: Jane Smith
                    status: active
                    createdAt: "2024-01-15T10:30:00Z"
                    updatedAt: "2024-01-15T10:30:00Z"
                pagination:
                  page: 1
                  pageSize: 20
                  total: 142
                  totalPages: 8
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '500':
          $ref: '#/components/responses/InternalError'

    post:
      operationId: createUser
      summary: Create a user
      tags: [Users]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserRequest'
            example:
              email: jane@example.com
              name: Jane Smith
              password: "S3cur3P@ssw0rd!"
      responses:
        '201':
          description: User created successfully
          headers:
            Location:
              schema:
                type: string
              description: URL of the created user
              example: /v1/users/usr_01HX5Y3Z
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '400':
          $ref: '#/components/responses/BadRequest'
        '409':
          $ref: '#/components/responses/Conflict'
        '500':
          $ref: '#/components/responses/InternalError'
```

### Single Resource Endpoint (GET / PUT / PATCH / DELETE)

```yaml
  /users/{id}:
    parameters:
      - $ref: '#/components/parameters/ResourceId'

    get:
      operationId: getUser
      summary: Get a user
      tags: [Users]
      responses:
        '200':
          description: User found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '404':
          $ref: '#/components/responses/NotFound'

    patch:
      operationId: updateUser
      summary: Partially update a user
      tags: [Users]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UpdateUserRequest'
      responses:
        '200':
          description: User updated
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '404':
          $ref: '#/components/responses/NotFound'

    delete:
      operationId: deleteUser
      summary: Delete a user
      tags: [Users]
      responses:
        '204':
          description: User deleted
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '404':
          $ref: '#/components/responses/NotFound'
```

### Action Endpoint (POST verb sub-resource)

```yaml
  /orders/{id}/cancel:
    post:
      operationId: cancelOrder
      summary: Cancel an order
      description: Cancels an order if it is in a cancellable state (pending or processing).
      tags: [Orders]
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      requestBody:
        required: false
        content:
          application/json:
            schema:
              type: object
              properties:
                reason:
                  type: string
                  description: Cancellation reason
      responses:
        '200':
          description: Order cancelled
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Order'
        '409':
          description: Order cannot be cancelled in its current state
          $ref: '#/components/responses/Conflict'
```

### Public Endpoint (no auth)

```yaml
  /products:
    get:
      operationId: listProducts
      summary: List products (public)
      tags: [Products]
      security: []   # Overrides global security — makes this endpoint public
      parameters:
        - $ref: '#/components/parameters/CursorParam'
        - $ref: '#/components/parameters/LimitParam'
      responses:
        '200':
          description: Product listing
```

---

## Schema Patterns

### Resource Schema (full read model)

```yaml
components:
  schemas:
    User:
      type: object
      required: [id, email, name, status, createdAt, updatedAt]
      properties:
        id:
          type: string
          readOnly: true
          description: Unique user identifier
          example: usr_01HX5Y3Z
        email:
          type: string
          format: email
          example: jane@example.com
        name:
          type: string
          example: Jane Smith
        status:
          type: string
          enum: [active, inactive, suspended]
          example: active
        avatarUrl:
          type: string
          format: uri
          nullable: true
          example: https://cdn.example.com/avatars/usr_01HX5Y3Z.jpg
        createdAt:
          type: string
          format: date-time
          readOnly: true
        updatedAt:
          type: string
          format: date-time
          readOnly: true

    CreateUserRequest:
      type: object
      required: [email, name, password]
      properties:
        email:
          type: string
          format: email
        name:
          type: string
          minLength: 1
          maxLength: 100
        password:
          type: string
          format: password
          minLength: 8
          writeOnly: true

    UpdateUserRequest:
      type: object
      minProperties: 1   # At least one field required for PATCH
      properties:
        name:
          type: string
          minLength: 1
          maxLength: 100
        avatarUrl:
          type: string
          format: uri
          nullable: true
```

### Enum with description

```yaml
    OrderStatus:
      type: string
      enum: [pending, processing, shipped, delivered, cancelled, refunded]
      description: |
        - `pending`: Order placed, awaiting payment confirmation
        - `processing`: Payment confirmed, being prepared
        - `shipped`: In transit
        - `delivered`: Successfully delivered
        - `cancelled`: Cancelled before shipment
        - `refunded`: Refunded after delivery
```
