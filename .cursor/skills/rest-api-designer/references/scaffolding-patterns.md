# Code Scaffolding Patterns

Framework-agnostic structure first, then language-specific examples.
Always generate complete, runnable stubs — not pseudocode.

## Directory Structure (universal)

```
{api-name}-scaffolding/
├── routes/
│   ├── index.{ext}          # route registry / router mount
│   ├── users.{ext}
│   ├── orders.{ext}
│   └── auth.{ext}
├── controllers/
│   ├── users.controller.{ext}
│   ├── orders.controller.{ext}
│   └── auth.controller.{ext}
├── middleware/
│   ├── auth.middleware.{ext}
│   ├── validate.middleware.{ext}
│   ├── rateLimit.middleware.{ext}
│   └── errorHandler.middleware.{ext}
├── types/                    # or schemas/ for runtime validation
│   ├── user.types.{ext}
│   └── order.types.{ext}
└── README.md
```

---

## Node.js / Express (TypeScript)

### routes/users.ts
```typescript
import { Router } from 'express';
import { authenticate } from '../middleware/auth.middleware';
import { validate } from '../middleware/validate.middleware';
import {
  listUsers,
  createUser,
  getUser,
  updateUser,
  deleteUser,
} from '../controllers/users.controller';
import { CreateUserSchema, UpdateUserSchema } from '../types/user.types';

const router = Router();

router.get('/',    authenticate, listUsers);
router.post('/',   authenticate, validate(CreateUserSchema), createUser);
router.get('/:id', authenticate, getUser);
router.patch('/:id', authenticate, validate(UpdateUserSchema), updateUser);
router.delete('/:id', authenticate, deleteUser);

export default router;
```

### controllers/users.controller.ts
```typescript
import { Request, Response, NextFunction } from 'express';

/**
 * GET /users
 * List users with pagination and optional filters.
 */
export async function listUsers(req: Request, res: Response, next: NextFunction) {
  try {
    const { page = 1, pageSize = 20, status, search, sort } = req.query;

    // TODO: call service layer
    // const result = await UserService.list({ page, pageSize, status, search, sort });

    res.json({
      data: [],
      pagination: {
        page: Number(page),
        pageSize: Number(pageSize),
        total: 0,
        totalPages: 0,
      },
    });
  } catch (err) {
    next(err);
  }
}

/**
 * POST /users
 * Create a new user.
 */
export async function createUser(req: Request, res: Response, next: NextFunction) {
  try {
    const { email, name, password } = req.body;

    // TODO: call service layer
    // const user = await UserService.create({ email, name, password });

    const user = { id: 'usr_placeholder', email, name, createdAt: new Date() };

    res.status(201)
      .header('Location', `/v1/users/${user.id}`)
      .json(user);
  } catch (err) {
    next(err);
  }
}

/**
 * GET /users/:id
 * Get a single user by ID.
 */
export async function getUser(req: Request, res: Response, next: NextFunction) {
  try {
    const { id } = req.params;

    // TODO: call service layer
    // const user = await UserService.findById(id);
    // if (!user) return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'User not found' } });

    res.json({ id, email: 'placeholder@example.com', name: 'Placeholder' });
  } catch (err) {
    next(err);
  }
}

/**
 * PATCH /users/:id
 * Partially update a user.
 */
export async function updateUser(req: Request, res: Response, next: NextFunction) {
  try {
    const { id } = req.params;
    const updates = req.body;

    // TODO: call service layer
    // const user = await UserService.update(id, updates, req.user);

    res.json({ id, ...updates });
  } catch (err) {
    next(err);
  }
}

/**
 * DELETE /users/:id
 * Delete a user.
 */
export async function deleteUser(req: Request, res: Response, next: NextFunction) {
  try {
    const { id } = req.params;

    // TODO: call service layer
    // await UserService.delete(id, req.user);

    res.status(204).send();
  } catch (err) {
    next(err);
  }
}
```

### middleware/auth.middleware.ts
```typescript
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

export function authenticate(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({
      error: {
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
        requestId: req.id,
        timestamp: new Date().toISOString(),
      },
    });
  }

  const token = authHeader.slice(7);

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET!) as { sub: string; role: string };
    (req as any).user = { id: payload.sub, role: payload.role };
    next();
  } catch (err) {
    if (err instanceof jwt.TokenExpiredError) {
      return res.status(401).json({
        error: { code: 'TOKEN_EXPIRED', message: 'Access token has expired' }
      });
    }
    return res.status(401).json({
      error: { code: 'TOKEN_INVALID', message: 'Invalid authentication token' }
    });
  }
}
```

### middleware/errorHandler.middleware.ts
```typescript
import { Request, Response, NextFunction } from 'express';

export function errorHandler(err: Error, req: Request, res: Response, next: NextFunction) {
  console.error({ err, requestId: (req as any).id });

  // Known operational errors
  if ((err as any).statusCode) {
    return res.status((err as any).statusCode).json({
      error: {
        code: (err as any).code || 'ERROR',
        message: err.message,
        requestId: (req as any).id,
        timestamp: new Date().toISOString(),
      },
    });
  }

  // Unknown errors — don't leak details
  res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred',
      requestId: (req as any).id,
      timestamp: new Date().toISOString(),
    },
  });
}
```

### types/user.types.ts (with Zod)
```typescript
import { z } from 'zod';

export const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  password: z.string().min(8),
});

export const UpdateUserSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  avatarUrl: z.string().url().nullable().optional(),
}).refine(data => Object.keys(data).length > 0, {
  message: 'At least one field must be provided',
});

export type CreateUserInput = z.infer<typeof CreateUserSchema>;
export type UpdateUserInput = z.infer<typeof UpdateUserSchema>;

export type User = {
  id: string;
  email: string;
  name: string;
  status: 'active' | 'inactive' | 'suspended';
  avatarUrl: string | null;
  createdAt: Date;
  updatedAt: Date;
};
```

---

## Python / FastAPI

### routes/users.py
```python
from fastapi import APIRouter, Depends, Query
from typing import Optional
from ..controllers.users_controller import (
    list_users, create_user, get_user, update_user, delete_user
)
from ..middleware.auth import get_current_user
from ..types.user_types import CreateUserRequest, UpdateUserRequest

router = APIRouter(prefix="/users", tags=["Users"])

@router.get("/")
async def users_list(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    status: Optional[str] = None,
    search: Optional[str] = None,
    current_user=Depends(get_current_user),
):
    return await list_users(page=page, page_size=page_size, status=status, search=search)

@router.post("/", status_code=201)
async def users_create(
    body: CreateUserRequest,
    current_user=Depends(get_current_user),
):
    return await create_user(body)

@router.get("/{user_id}")
async def users_get(user_id: str, current_user=Depends(get_current_user)):
    return await get_user(user_id)

@router.patch("/{user_id}")
async def users_update(
    user_id: str,
    body: UpdateUserRequest,
    current_user=Depends(get_current_user),
):
    return await update_user(user_id, body)

@router.delete("/{user_id}", status_code=204)
async def users_delete(user_id: str, current_user=Depends(get_current_user)):
    await delete_user(user_id)
```

### types/user_types.py
```python
from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional
from enum import Enum

class UserStatus(str, Enum):
    active = "active"
    inactive = "inactive"
    suspended = "suspended"

class CreateUserRequest(BaseModel):
    email: EmailStr
    name: str
    password: str

    @field_validator('name')
    def name_length(cls, v):
        if len(v) < 1 or len(v) > 100:
            raise ValueError('Name must be 1-100 characters')
        return v

    @field_validator('password')
    def password_length(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters')
        return v

class UpdateUserRequest(BaseModel):
    name: Optional[str] = None
    avatar_url: Optional[str] = None

class UserResponse(BaseModel):
    id: str
    email: EmailStr
    name: str
    status: UserStatus
    avatar_url: Optional[str] = None
    created_at: str
    updated_at: str
```

---

## Go / Chi

### routes/users.go
```go
package routes

import (
    "github.com/go-chi/chi/v5"
    "myapi/controllers"
    "myapi/middleware"
)

func UserRoutes(r chi.Router) {
    r.Group(func(r chi.Router) {
        r.Use(middleware.Authenticate)

        r.Get("/users", controllers.ListUsers)
        r.Post("/users", controllers.CreateUser)
        r.Get("/users/{id}", controllers.GetUser)
        r.Patch("/users/{id}", controllers.UpdateUser)
        r.Delete("/users/{id}", controllers.DeleteUser)
    })
}
```

### controllers/users.go
```go
package controllers

import (
    "encoding/json"
    "net/http"
    "github.com/go-chi/chi/v5"
)

func ListUsers(w http.ResponseWriter, r *http.Request) {
    // TODO: parse query params, call service, return JSON
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]any{
        "data": []any{},
        "pagination": map[string]any{"page": 1, "pageSize": 20, "total": 0},
    })
}

func GetUser(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")
    // TODO: call service, handle not found
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]string{"id": id})
}
```

---

## scaffolding/README.md Template

```markdown
# {API Name} — Code Scaffolding

Generated by rest-api-designer skill. All handlers are stubs — implement the service layer.

## Stack
- Language: {language}
- Framework: {framework}
- Validation: {validation library}
- Auth: JWT Bearer tokens

## Setup
{installation steps}

## Structure
- `routes/` — URL routing and middleware application
- `controllers/` — Request/response handling (thin layer)
- `middleware/` — Auth, validation, error handling
- `types/` — Request/response types and validation schemas

## Next Steps
1. Implement service layer (business logic + DB calls)
2. Wire up database connection
3. Add environment configuration
4. Implement auth token generation in `POST /auth/login`
5. Add logging middleware
6. Add tests
```
