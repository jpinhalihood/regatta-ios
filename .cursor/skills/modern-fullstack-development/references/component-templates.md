# Component Templates

Standard component shapes for resource-based UI. Use these as the base when
generating components in Handoff Mode. Every template follows the code standards
defined in SKILL.md — no semicolons, const declarations, early returns, WCAG 2.2 AA.

---

## Resource Card (`{resource}-card.tsx`)

Displays a single resource in a list or grid. Receives a typed resource object
as a prop. Emits edit/delete callbacks — never handles mutations internally.

```typescript
// components/{resource}/{resource}-card.tsx
import { type User } from '@/lib/api/users'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'

interface UserCardProps {
  user: User
  onEdit: (user: User) => void
  onDelete: (id: string) => void
  isDeleting?: boolean
}

const UserCard = ({ user, onEdit, onDelete, isDeleting = false }: UserCardProps) => {
  const handleEditClick = () => onEdit(user)

  const handleDeleteClick = () => onDelete(user.id)

  const handleDeleteKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' || e.key === ' ') onDelete(user.id)
  }

  return (
    <Card className="relative">
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium">{user.name}</CardTitle>
        <Badge variant={user.role === 'ADMIN' ? 'default' : 'secondary'}>
          {user.role}
        </Badge>
      </CardHeader>
      <CardContent>
        <p className="text-sm text-muted-foreground">{user.email}</p>
        <p className="text-xs text-muted-foreground mt-1">
          Joined {new Date(user.createdAt).toLocaleDateString()}
        </p>

        <div className="flex gap-2 mt-4">
          <Button
            variant="outline"
            size="sm"
            onClick={handleEditClick}
            aria-label={`Edit ${user.name}`}
          >
            Edit
          </Button>
          <Button
            variant="destructive"
            size="sm"
            onClick={handleDeleteClick}
            onKeyDown={handleDeleteKeyDown}
            disabled={isDeleting}
            aria-label={`Delete ${user.name}`}
            tabIndex={0}
          >
            {isDeleting ? 'Deleting...' : 'Delete'}
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}

export default UserCard
```

### Rules for card components
- Props: resource object + callbacks (`onEdit`, `onDelete`, `onSelect`)
- Never fetch data or mutate — pure display + event emission
- Loading state via `isDeleting`, `isUpdating` boolean props (not internal state)
- Format dates with `toLocaleDateString()` — never raw ISO strings
- Status/role fields → `<Badge>` with variant mapped to value

---

## Resource Form (`{resource}-form.tsx`)

Handles both create and edit. Receives an optional resource for edit mode —
absence means create mode. Uses React Hook Form + Zod.

```typescript
// components/{resource}/{resource}-form.tsx
'use client'

import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { type User, type CreateUserInput } from '@/lib/api/users'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'

// Zod schema — single source of truth for validation
const userFormSchema = z.object({
  name: z.string().min(1, 'Name is required').max(100),
  email: z.string().email('Must be a valid email'),
  password: z.string().min(8, 'Password must be at least 8 characters').optional(),
  role: z.enum(['USER', 'ADMIN']),
})

type UserFormValues = z.infer<typeof userFormSchema>

interface UserFormProps {
  user?: User                                    // present = edit mode
  onSubmit: (values: UserFormValues) => Promise<void>
  onCancel: () => void
  isSubmitting?: boolean
}

const UserForm = ({ user, onSubmit, onCancel, isSubmitting = false }: UserFormProps) => {
  const isEditMode = !!user

  const {
    register,
    handleSubmit,
    setValue,
    formState: { errors },
  } = useForm<UserFormValues>({
    resolver: zodResolver(userFormSchema),
    defaultValues: {
      name: user?.name ?? '',
      email: user?.email ?? '',
      role: user?.role ?? 'USER',
    },
  })

  const handleFormSubmit = handleSubmit(async (values) => {
    await onSubmit(values)
  })

  return (
    <form onSubmit={handleFormSubmit} noValidate className="space-y-4">
      <div className="space-y-2">
        <Label htmlFor="name">Name</Label>
        <Input
          id="name"
          {...register('name')}
          aria-describedby={errors.name ? 'name-error' : undefined}
          aria-invalid={!!errors.name}
        />
        {errors.name && (
          <p id="name-error" className="text-sm text-destructive" role="alert">
            {errors.name.message}
          </p>
        )}
      </div>

      <div className="space-y-2">
        <Label htmlFor="email">Email</Label>
        <Input
          id="email"
          type="email"
          {...register('email')}
          aria-describedby={errors.email ? 'email-error' : undefined}
          aria-invalid={!!errors.email}
        />
        {errors.email && (
          <p id="email-error" className="text-sm text-destructive" role="alert">
            {errors.email.message}
          </p>
        )}
      </div>

      {!isEditMode && (
        <div className="space-y-2">
          <Label htmlFor="password">Password</Label>
          <Input
            id="password"
            type="password"
            {...register('password')}
            aria-describedby={errors.password ? 'password-error' : undefined}
            aria-invalid={!!errors.password}
          />
          {errors.password && (
            <p id="password-error" className="text-sm text-destructive" role="alert">
              {errors.password.message}
            </p>
          )}
        </div>
      )}

      <div className="space-y-2">
        <Label htmlFor="role">Role</Label>
        <Select
          defaultValue={user?.role ?? 'USER'}
          onValueChange={(value) => setValue('role', value as 'USER' | 'ADMIN')}
        >
          <SelectTrigger id="role" aria-label="Select role">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="USER">User</SelectItem>
            <SelectItem value="ADMIN">Admin</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <div className="flex gap-2 pt-2">
        <Button type="submit" disabled={isSubmitting}>
          {isSubmitting ? 'Saving...' : isEditMode ? 'Save changes' : 'Create user'}
        </Button>
        <Button type="button" variant="outline" onClick={onCancel}>
          Cancel
        </Button>
      </div>
    </form>
  )
}

export default UserForm
```

### Rules for form components
- Always `'use client'` at the top
- One Zod schema per form — derive the type with `z.infer<typeof schema>`
- `defaultValues` from the resource prop (edit mode) or empty strings (create mode)
- Error messages via `role="alert"` and `aria-describedby` — screen reader accessible
- Password fields: only show in create mode, never pre-fill in edit mode
- `onSubmit` is always async and lives in the parent — form only calls it
- Enum fields → `<Select>`, not `<input type="text">`

---

## Resource Table (`{resource}-table.tsx`)

Displays a list of resources in a sortable, paginated table. Uses SWR hook for
data. Handles loading, empty, and error states.

```typescript
// components/{resource}/{resource}-table.tsx
'use client'

import { useState } from 'react'
import { useUsers } from '@/lib/hooks/use-users'
import { usersApi, type User } from '@/lib/api/users'
import UserCard from './user-card'
import UserForm from './user-form'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'

const UserTable = () => {
  const { users, isLoading, error, mutate } = useUsers()
  const [editingUser, setEditingUser] = useState<User | null>(null)
  const [deletingId, setDeletingId] = useState<string | null>(null)
  const [isCreating, setIsCreating] = useState(false)

  // Early returns for loading and error states
  if (isLoading) {
    return (
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3" role="status" aria-label="Loading users">
        {Array.from({ length: 6 }).map((_, i) => (
          <Skeleton key={i} className="h-40 rounded-lg" />
        ))}
      </div>
    )
  }

  if (error) {
    return (
      <div className="text-center py-12" role="alert">
        <p className="text-destructive">{error}</p>
        <Button variant="outline" className="mt-4" onClick={() => mutate()}>
          Try again
        </Button>
      </div>
    )
  }

  if (users.length === 0) {
    return (
      <div className="text-center py-12">
        <p className="text-muted-foreground">No users yet.</p>
        <Button className="mt-4" onClick={() => setIsCreating(true)}>
          Create first user
        </Button>
      </div>
    )
  }

  const handleEdit = (user: User) => setEditingUser(user)

  const handleDelete = async (id: string) => {
    setDeletingId(id)
    await usersApi.delete(id)
    await mutate()
    setDeletingId(null)
  }

  const handleCreateSubmit = async (values: Parameters<typeof usersApi.create>[0]) => {
    await usersApi.create(values)
    await mutate()
    setIsCreating(false)
  }

  const handleEditSubmit = async (values: Parameters<typeof usersApi.update>[1]) => {
    if (!editingUser) return
    await usersApi.update(editingUser.id, values)
    await mutate()
    setEditingUser(null)
  }

  return (
    <>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-lg font-semibold">Users ({users.length})</h2>
        <Button onClick={() => setIsCreating(true)}>Add user</Button>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {users.map((user) => (
          <UserCard
            key={user.id}
            user={user}
            onEdit={handleEdit}
            onDelete={handleDelete}
            isDeleting={deletingId === user.id}
          />
        ))}
      </div>

      <Dialog open={isCreating} onOpenChange={setIsCreating}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Create user</DialogTitle>
          </DialogHeader>
          <UserForm
            onSubmit={handleCreateSubmit}
            onCancel={() => setIsCreating(false)}
          />
        </DialogContent>
      </Dialog>

      <Dialog open={!!editingUser} onOpenChange={() => setEditingUser(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit user</DialogTitle>
          </DialogHeader>
          {editingUser && (
            <UserForm
              user={editingUser}
              onSubmit={handleEditSubmit}
              onCancel={() => setEditingUser(null)}
            />
          )}
        </DialogContent>
      </Dialog>
    </>
  )
}

export default UserTable
```

### Rules for table/list components
- Always `'use client'` — these components manage local UI state
- Use the SWR hook — never fetch directly in the component
- Three mandatory states: loading (skeletons), empty (with CTA), error (with retry)
- Mutations: call API directly → call `mutate()` to revalidate SWR cache
- Modals for create/edit — `Dialog` from Shadcn, never inline forms
- `deletingId` pattern for per-row loading state (not a global `isDeleting` boolean)

---

## Page Component (`app/(dashboard)/{resource}/page.tsx`)

Server component. Fetches initial data server-side, passes to client components.

```typescript
// app/(dashboard)/users/page.tsx
import { Suspense } from 'react'
import UserTable from '@/components/user/user-table'
import { Skeleton } from '@/components/ui/skeleton'

// Metadata for the page
export const metadata = {
  title: 'Users',
  description: 'Manage your users',
}

const UsersPage = () => (
  <div className="container mx-auto py-8">
    <div className="mb-8">
      <h1 className="text-3xl font-bold tracking-tight">Users</h1>
      <p className="text-muted-foreground">Manage and configure user accounts.</p>
    </div>

    <Suspense
      fallback={
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 6 }).map((_, i) => (
            <Skeleton key={i} className="h-40 rounded-lg" />
          ))}
        </div>
      }
    >
      <UserTable />
    </Suspense>
  </div>
)

export default UsersPage
```

### Rules for page components
- Server components by default — no `'use client'`
- Always export `metadata`
- Wrap client components in `<Suspense>` with a skeleton fallback
- No data fetching in the page itself — delegate to the table/list component
- Path: `app/(dashboard)/{resource}/page.tsx`

---

## Adapting Templates to Other Resources

When generating for a resource other than `User`:

1. Replace `User` / `user` / `users` with the resource name throughout
2. Replace fields (`name`, `email`, `role`) with the fields from the Handoff Contract
3. Map enum values from the contract to `<SelectItem>` entries in the form
4. Adjust the card display to show the most meaningful 2-3 fields for that resource
5. Adjust the Zod schema field validations to match field types and constraints:
   - `String` required → `z.string().min(1, '...')`
   - `String` optional → `z.string().optional()`
   - `Int` → `z.number().int()`
   - `Boolean` → `z.boolean()`
   - `DateTime` → `z.string().datetime()` or a date picker
   - Enum → `z.enum([...values])`
