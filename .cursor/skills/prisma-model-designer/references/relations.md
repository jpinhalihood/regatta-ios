# Prisma Relations Reference

## Relation Naming Disambiguating

When two models have multiple relations between them, name them:

```prisma
model User {
  writtenPosts  Post[] @relation("PostAuthor")
  likedPosts    Post[] @relation("PostLikes")
}

model Post {
  author    User   @relation("PostAuthor", fields: [authorId], references: [id])
  authorId  String
  likedBy   User[] @relation("PostLikes")
}
```

## Optional vs Required Relations

**Required** (child cannot exist without parent):
```prisma
author   User   @relation(fields: [authorId], references: [id])
authorId String  // non-nullable
```

**Optional** (child can exist without parent):
```prisma
author   User?  @relation(fields: [authorId], references: [id])
authorId String? // nullable
```

## Implicit Many-to-Many (simple, no extra fields)

Use only when join table needs NO extra fields:
```prisma
model Post {
  tags Tag[]
}
model Tag {
  posts Post[]
}
```
Prisma creates `_PostToTag` behind the scenes.

## Explicit Many-to-Many (recommended)

Always prefer when you might need extra fields on the relation later:
```prisma
model PostTag {
  postId    String
  tagId     String
  post      Post     @relation(fields: [postId], references: [id], onDelete: Cascade)
  tag       Tag      @relation(fields: [tagId], references: [id], onDelete: Cascade)
  createdAt DateTime @default(now())
  createdBy String?  // who added the tag

  @@id([postId, tagId])
}
```

## Self-Referential Patterns

### Adjacency list (simple parent/child)
```prisma
model Node {
  id       String  @id @default(cuid())
  parentId String?
  parent   Node?   @relation("tree", fields: [parentId], references: [id])
  children Node[]  @relation("tree")
}
```

### Closure table pattern (for deep trees with fast queries)
Use a separate `NodeClosure` model with `ancestor` + `descendant` + `depth`.

## Polymorphic Relations (Prisma workaround)

Prisma doesn't support polymorphic natively. Use union models:
```prisma
// Instead of polymorphic "commentable", use:
model Comment {
  id      String  @id @default(cuid())
  post    Post?   @relation(fields: [postId], references: [id])
  postId  String?
  video   Video?  @relation(fields: [videoId], references: [id])
  videoId String?
  // enforce at application layer that exactly one is set
}
```

## Cascade Behaviors

```
onDelete: Cascade   → delete child when parent deleted
onDelete: Restrict  → block parent deletion if children exist (safe default)
onDelete: SetNull   → set FK to null (field must be optional)
onDelete: NoAction  → database-level no action

onUpdate: Cascade   → propagate PK change to FK (rare)
onUpdate: Restrict  → block PK update if children reference it
```
