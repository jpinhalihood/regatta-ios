# API Client Patterns

Typed fetch wrapper and resource client patterns for Next.js App Router projects.
Always read this before generating API client code in Handoff Mode.

---

## The Base Client (`lib/api/client.ts`)

The base client is a thin typed wrapper around `fetch`. It handles:
- Auth header injection (reads JWT from cookie/localStorage)
- Base URL configuration
- Error normalization into a consistent shape
- Response type inference

```typescript
// lib/api/client.ts

interface ApiError {
  code: string
  message: string
  details?: Record<string, string>[]
  requestId?: string
}

interface ApiResponse<T> {
  data: T | null
  error: ApiError | null
  status: number
}

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? '/api/v1'

const getAuthHeader = (): Record<string, string> => {
  if (typeof window === 'undefined') return {}
  const token = localStorage.getItem('access_token')
  return token ? { Authorization: `Bearer ${token}` } : {}
}

export const apiClient = async <T>(
  path: string,
  options: RequestInit = {}
): Promise<ApiResponse<T>> => {
  const url = `${API_BASE}${path}`

  const response = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...getAuthHeader(),
      ...options.headers,
    },
  })

  if (!response.ok) {
    const error: ApiError = await response.json().catch(() => ({
      code: 'UNKNOWN_ERROR',
      message: `Request failed with status ${response.status}`,
    }))
    return { data: null, error, status: response.status }
  }

  // Handle 204 No Content
  if (response.status === 204) {
    return { data: null, error: null, status: 204 }
  }

  const data: T = await response.json()
  return { data, error: null, status: response.status }
}
```

---

## Resource Client Pattern (`lib/api/{resource}.ts`)

One file per resource. Each file exports typed CRUD functions that use `apiClient`.
Generate one of these for every resource in the Handoff Contract.

```typescript
// lib/api/users.ts
import { apiClient } from './client'

// --- Types (derived from Handoff Contract resource fields) ---

export interface User {
  id: string
  email: string
  name: string
  role: 'USER' | 'ADMIN'
  createdAt: string
  updatedAt: string
}

export interface CreateUserInput {
  email: string
  name: string
  password: string
  role?: 'USER' | 'ADMIN'
}

export interface UpdateUserInput {
  name?: string
  role?: 'USER' | 'ADMIN'
}

export interface UserListParams {
  page?: number
  limit?: number
  cursor?: string
  role?: 'USER' | 'ADMIN'
}

interface PaginatedResponse<T> {
  data: T[]
  pagination: {
    cursor?: string
    hasMore: boolean
    total?: number
  }
}

// --- API Methods ---

export const usersApi = {
  list: (params?: UserListParams) => {
    const query = new URLSearchParams(
      Object.entries(params ?? {})
        .filter(([, v]) => v !== undefined)
        .map(([k, v]) => [k, String(v)])
    ).toString()
    return apiClient<PaginatedResponse<User>>(`/users${query ? `?${query}` : ''}`)
  },

  get: (id: string) =>
    apiClient<User>(`/users/${id}`),

  create: (input: CreateUserInput) =>
    apiClient<User>('/users', {
      method: 'POST',
      body: JSON.stringify(input),
    }),

  update: (id: string, input: UpdateUserInput) =>
    apiClient<User>(`/users/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(input),
    }),

  delete: (id: string) =>
    apiClient<void>(`/users/${id}`, { method: 'DELETE' }),
}
```

### Rules for resource clients
- Name the export `{resource}Api` (camelCase): `usersApi`, `postsApi`, `ordersApi`
- All methods return `Promise<ApiResponse<T>>` via `apiClient` — never throw
- Types live in the same file as the client that uses them
- List methods always accept an optional params object (even if currently unused)
- Never hardcode IDs, tokens, or base URLs

---

## SWR Hooks (`lib/hooks/use-{resource}.ts`)

Wrap resource clients in SWR hooks for client-side data fetching with caching,
revalidation, and optimistic updates.

```typescript
// lib/hooks/use-users.ts
import useSWR, { type KeyedMutator } from 'swr'
import { usersApi, type User, type UserListParams } from '@/lib/api/users'

interface UseUsersReturn {
  users: User[]
  isLoading: boolean
  error: string | null
  mutate: KeyedMutator<User[]>
  hasMore: boolean
}

/**
 * Fetches and caches the user list with SWR.
 * Automatically revalidates on window focus.
 * @param params - Optional filters (role, cursor, limit)
 */
export const useUsers = (params?: UserListParams): UseUsersReturn => {
  const key = ['users', params]

  const { data, error, isLoading, mutate } = useSWR(key, async () => {
    const response = await usersApi.list(params)
    if (response.error) throw new Error(response.error.message)
    return response.data
  })

  return {
    users: data?.data ?? [],
    isLoading,
    error: error?.message ?? null,
    mutate,
    hasMore: data?.pagination.hasMore ?? false,
  }
}

/**
 * Fetches a single user by ID with SWR.
 * Returns null if ID is undefined (hook is disabled).
 * @param id - The user ID, or undefined to disable the hook
 */
export const useUser = (id: string | undefined) => {
  const { data, error, isLoading, mutate } = useSWR(
    id ? ['users', id] : null,
    async () => {
      const response = await usersApi.get(id!)
      if (response.error) throw new Error(response.error.message)
      return response.data
    }
  )

  return {
    user: data,
    isLoading,
    error: error?.message ?? null,
    mutate,
  }
}
```

### Rules for SWR hooks
- One file per resource: `use-users.ts`, `use-posts.ts`
- Export named hooks: `useUsers`, `useUser` (singular for single item)
- SWR key is always `[resourceName, params]` — never a plain string
- Unwrap the `ApiResponse` inside the fetcher — hooks return plain data, not wrappers
- Always include JSDoc explaining what the hook fetches and its disable condition

---

## Auth Pattern (`lib/api/auth.ts` + `middleware.ts`)

### JWT token management

```typescript
// lib/api/auth.ts
import { apiClient } from './client'

export interface LoginInput {
  email: string
  password: string
}

export interface AuthTokens {
  accessToken: string
  refreshToken: string
  expiresIn: number
}

export interface AuthUser {
  id: string
  email: string
  role: string
}

export const authApi = {
  login: (input: LoginInput) =>
    apiClient<AuthTokens>('/auth/login', {
      method: 'POST',
      body: JSON.stringify(input),
    }),

  refresh: (refreshToken: string) =>
    apiClient<AuthTokens>('/auth/refresh', {
      method: 'POST',
      body: JSON.stringify({ refreshToken }),
    }),

  logout: () =>
    apiClient<void>('/auth/logout', { method: 'POST' }),

  me: () =>
    apiClient<AuthUser>('/auth/me'),
}

// Token helpers (client-side only)
export const tokenStore = {
  get: () => localStorage.getItem('access_token'),
  set: (token: string) => localStorage.setItem('access_token', token),
  clear: () => {
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
  },
}
```

### Middleware (route protection)

```typescript
// middleware.ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
import { jwtVerify } from 'jose'

const PUBLIC_ROUTES = ['/login', '/register', '/api/auth/login', '/api/auth/register']

export const middleware = async (request: NextRequest): Promise<NextResponse> => {
  const { pathname } = request.nextUrl

  if (PUBLIC_ROUTES.some(route => pathname.startsWith(route))) {
    return NextResponse.next()
  }

  const token = request.cookies.get('access_token')?.value

  if (!token) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  try {
    const secret = new TextEncoder().encode(process.env.JWT_SECRET)
    await jwtVerify(token, secret)
    return NextResponse.next()
  } catch {
    return NextResponse.redirect(new URL('/login', request.url))
  }
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
}
```

---

## Server Component Data Fetching

For initial page loads in server components — no SWR, no client-side fetch:

```typescript
// app/(dashboard)/users/page.tsx
import { cookies } from 'next/headers'
import { usersApi } from '@/lib/api/users'

// Server component — runs on the server, has access to cookies
const UsersPage = async () => {
  // Pass server-side token directly
  const cookieStore = cookies()
  const token = cookieStore.get('access_token')?.value

  const response = await usersApi.list()

  if (response.error || !response.data) {
    // Let Next.js error boundary handle this
    throw new Error(response.error?.message ?? 'Failed to load users')
  }

  return <UserTable initialData={response.data.data} />
}

export default UsersPage
```

---

## Generating clients from the Handoff Contract

When in Handoff Mode, for each resource in the contract:

1. Create `lib/api/{resource-lowercase}.ts` using the resource client pattern above
2. Map Handoff Contract field types to TypeScript types:
   - `String` → `string`
   - `Int`, `Float` → `number`
   - `Boolean` → `boolean`
   - `DateTime` → `string` (ISO 8601 — parse with `new Date()` where needed)
   - `Json` → `Record<string, unknown>`
   - Enum values → TypeScript string union: `'VALUE_A' | 'VALUE_B'`
3. Mark optional fields (`constraints: [optional]`) with `?` in the interface
4. Create `lib/hooks/use-{resource}.ts` with `useResources` and `useResource` hooks
5. Add the resource to `lib/types/api.ts` as a re-export for convenience
