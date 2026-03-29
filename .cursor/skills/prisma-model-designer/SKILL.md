---
name: prisma-model-designer
description: >
  Expert Prisma database schema designer for Open Claw installations targeting
  PostgreSQL and SQLite. Use this skill whenever the user asks to design Prisma
  models from scratch, convert/migrate existing SQL schemas or ERDs into Prisma,
  or model relations between entities — even if they just say "database", "schema",
  "models", "tables", "migrate", or "Prisma". Always triggers for: new schema
  design requests, "convert this SQL to Prisma", "how should I model X", or any
  data modeling task in a Node.js/TypeScript project. Primary output is always a
  complete, ready-to-use `schema.prisma` file.
---

# Prisma Model Designer

An expert skill for designing new Prisma schemas from scratch and migrating existing SQL/ERD schemas to Prisma — targeting **PostgreSQL** and **SQLite**.

## Workflow Overview

1. **Gather requirements** — Understand the domain, entities, and relations
2. **Design schema** — Write idiomatic `schema.prisma` with best practices
3. **Add relations** — Model all relationships explicitly and correctly
4. **Output** — Deliver a complete, validated `schema.prisma` file
5. **Review & explain** — Summarize decisions and trade-offs

---

## Step 1: Requirements Gathering

**First: check for a Handoff Contract.** Before asking any questions, scan the
conversation context and any attached files for a `## Handoff Contract` section
(produced by the rest-api-designer skill). If found, use **Handoff Mode** and skip
the interview entirely.

### Mode A — Design from Scratch
Collect before writing:
- **Domain description**: What is the application about?
- **Entities**: List of models/tables needed
- **Relations**: How models relate to each other
- **Database target**: PostgreSQL (default) or SQLite
- **Special needs**: Soft deletes, audit fields, enums, JSON fields

### Mode B — Migrate Existing SQL to Prisma
If the user provides existing SQL (DDL), a table list, or an ERD description:
1. Parse all `CREATE TABLE` statements to identify models, columns, types, and constraints
2. Map SQL types → Prisma types (see table below)
3. Identify foreign keys and reconstruct both sides of each relation
4. Preserve indexes, unique constraints, and defaults
5. Produce a complete `schema.prisma` — do NOT ask for clarification unless truly ambiguous

### Handoff Mode — Consume Handoff Contract ← USE THIS WHEN AVAILABLE

When a `## Handoff Contract` block is present in context or an attached `.md` file:

1. **Parse the contract** — extract `project`, `auth`, `database_hint`, `resources`, and `enums`
2. **Map resources → Prisma models** — each resource entry becomes one model
3. **Map fields** — use the type/constraint data directly:
   - `constraints: [pk]` → `@id`
   - `constraints: [cuid]` → `@default(cuid())`
   - `constraints: [unique]` → `@unique`
   - `constraints: [indexed]` → add to `@@index([])`
   - `constraints: [optional]` → field type becomes `Type?`
   - `constraints: [fk:ModelName]` → this is the foreign key field for a relation
4. **Build relations** — use the `relations` array to wire up both sides of every relation:
   - `one-to-many` → parent gets `Child[]`, child gets `parent Parent @relation(...)`
   - `one-to-one` → one side gets `@unique` on the FK field
   - `many-to-many` → create explicit join model using `through` value if provided
   - Apply `onDelete` value from contract
5. **Set database target** — use `database_hint` to set the `datasource provider`
6. **Apply SQLite limitations** if `database_hint: sqlite` (see Step 2 below)
7. **Do NOT ask the user any questions** — build the complete schema and deliver it

**Handoff Mode output note:** Add a brief header comment to the schema file:
```prisma
// Generated from Handoff Contract: {project}
// Source: {api-name}-api-design.md
```

**SQL → Prisma type mapping:**

| SQL Type (PG / SQLite) | Prisma Type |
|---|---|
| `VARCHAR`, `TEXT`, `CHAR` | `String` |
| `INT`, `INTEGER`, `SMALLINT` | `Int` |
| `BIGINT` | `BigInt` |
| `FLOAT`, `REAL`, `DOUBLE` | `Float` |
| `DECIMAL`, `NUMERIC` | `Decimal` |
| `BOOLEAN`, `BOOL` | `Boolean` |
| `TIMESTAMP`, `DATETIME` | `DateTime` |
| `UUID` | `String @db.Uuid` (PG) / `String` (SQLite) |
| `JSON`, `JSONB` | `Json` (PG only) |
| `SERIAL`, `AUTOINCREMENT` | `Int @id @default(autoincrement())` |

If the user provides a description or existing SQL, extract all information yourself. Only ask for missing critical pieces.

---

## Step 2: Schema Design Principles

### File Structure

**PostgreSQL:**
```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

**SQLite:**
```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL") // e.g. "file:./dev.db"
}
```

### SQLite Limitations to be aware of
- No native `Json` field type — use `String` and serialize manually
- No `Decimal` — use `Float` instead
- No `enum` support at the DB level — Prisma emulates with `String` constraints
- No `@db.Uuid` — use plain `String`
- Foreign keys require `PRAGMA foreign_keys = ON` at runtime

### Model Best Practices

**IDs**: Use `cuid()` or `uuid()` as default for portability. Use `autoincrement()` only when explicitly requested.
```prisma
id  String  @id @default(cuid())
```

**Timestamps**: Always include unless told not to:
```prisma
createdAt  DateTime  @default(now())
updatedAt  DateTime  @updatedAt
```

**Soft deletes**: Add when user mentions "archiving" or "not truly deleting":
```prisma
deletedAt  DateTime?
```

**Naming**:
- Model names: `PascalCase` singular (`User`, `BlogPost`)
- Field names: `camelCase` (`firstName`, `createdAt`)
- DB table/column overrides: use `@@map` / `@map` when snake_case is needed

---

## Step 3: Relation Patterns

Read `references/relations.md` for detailed patterns. Quick reference:

### One-to-Many (most common)
```prisma
model User {
  id     String  @id @default(cuid())
  posts  Post[]
}

model Post {
  id       String  @id @default(cuid())
  author   User    @relation(fields: [authorId], references: [id])
  authorId String
}
```

### Many-to-Many (explicit join table — preferred over implicit)
```prisma
model Post {
  id   String       @id @default(cuid())
  tags PostTag[]
}

model Tag {
  id    String    @id @default(cuid())
  posts PostTag[]
}

model PostTag {
  post      Post     @relation(fields: [postId], references: [id])
  postId    String
  tag       Tag      @relation(fields: [tagId], references: [id])
  tagId     String
  createdAt DateTime @default(now())

  @@id([postId, tagId])
}
```

### One-to-One
```prisma
model User {
  id      String   @id @default(cuid())
  profile Profile?
}

model Profile {
  id     String @id @default(cuid())
  user   User   @relation(fields: [userId], references: [id])
  userId String @unique
}
```

### Self-Referential (trees, categories, employees)
```prisma
model Category {
  id       String     @id @default(cuid())
  name     String
  parent   Category?  @relation("CategoryTree", fields: [parentId], references: [id])
  parentId String?
  children Category[] @relation("CategoryTree")
}
```

---

## Step 4: Advanced Features

### Enums
Supported natively in PostgreSQL. For SQLite, Prisma maps enums to `String` in the DB.
```prisma
enum Role {
  USER
  ADMIN
  MODERATOR
}

model User {
  role Role @default(USER)
}
```

### Indexes
```prisma
model Post {
  @@index([authorId, createdAt])   // compound index
  @@unique([slug])                 // unique constraint
}
```

For PostgreSQL full-text search, use `@@index` with `type: BrinIndex` or rely on raw SQL — Prisma doesn't have a `@@fulltext` for PG (that's MySQL only).

### JSON Fields (PostgreSQL only)
```prisma
model Product {
  metadata Json?
}
```
For SQLite, store as `String` and parse with `JSON.parse()` / `JSON.stringify()`.

### Multi-schema (PostgreSQL only)
```prisma
generator client {
  provider        = "prisma-client-js"
  previewFeatures = ["multiSchema"]
}

model User {
  @@schema("auth")
}
```

---

## Step 5: Output — schema.prisma File

**Always produce a single, complete `schema.prisma` file** — never partial snippets unless the user explicitly asks for one model only.

- Use a `prisma` code block
- Include the `generator` + `datasource` header
- All models in a logical order (independent models first, then dependent ones)
- Add inline comments explaining non-obvious decisions

```prisma
// schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ... models follow
```

---

## Step 6: Schema Review Checklist

Before finalizing, verify:

- [ ] All models have `@id` field
- [ ] All relations have both sides defined
- [ ] Foreign key fields named consistently (`<model>Id` pattern)
- [ ] `@updatedAt` present on all mutable models
- [ ] Enums used instead of magic strings
- [ ] Indexes on all foreign keys and frequently queried fields
- [ ] Cascading deletes explicitly set (`onDelete: Cascade` or `Restrict`)
- [ ] No circular required relations (would break seeding)
- [ ] **SQLite**: No `Json` fields (use `String`), no `Decimal` (use `Float`), no `@db.Uuid`
- [ ] **PostgreSQL**: `@db.Text` for long strings, `@db.Uuid` for UUID columns if desired

---

## Cascade Delete Reference

| Scenario | `onDelete` value |
|---|---|
| Child must be deleted with parent | `Cascade` |
| Child can exist without parent | `SetNull` (field must be optional) |
| Prevent parent deletion if children exist | `Restrict` |
| Default (Prisma default) | `SetDefault` |

```prisma
author   User   @relation(fields: [authorId], references: [id], onDelete: Cascade)
```

---

## Common Domain Templates

For well-known domains, apply standard patterns from `references/domain-templates.md`:
- **E-commerce**: User, Product, Order, OrderItem, Cart, CartItem, Category, Review
- **Blog/CMS**: User, Post, Tag, Comment, Category, Media
- **SaaS/Multi-tenant**: Tenant, User, Membership, Subscription, Plan
- **Auth**: User, Session, Account, VerificationToken (NextAuth compatible)

---

## Explaining Your Decisions

After every schema, include a brief **Design Notes** section:
- Why you chose certain relation types
- Any trade-offs made (e.g., explicit vs. implicit M:M)
- Performance considerations (indexes, denormalization)
- Suggestions for future schema evolution

---

## Upstream Skills

This skill is designed to be fed by:
- **rest-api-designer** — via the Handoff Contract appended to the API design doc
- **project-brief** — which orchestrates both skills in sequence

When a Handoff Contract is present, always use **Handoff Mode**. The goal is zero
re-interviewing — the user described their project once, and both skills
build from that single source of truth.
