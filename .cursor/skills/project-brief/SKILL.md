---
name: project-brief
description: >
  The front door for any new software project. Use this skill whenever the user
  wants to start building something — even if they just say "I want to build X",
  "let's start a new project", "I have an idea for an app", "help me plan this",
  or "where do I start". Triggers for: new project kickoffs, app ideas, SaaS
  concepts, MVP planning, or any request to go from idea to working spec.
  Collects a single structured brief from the user, then orchestrates the full
  pipeline: API design → Handoff Contract → Prisma schema — with zero
  re-interviewing between steps. Always use this skill before reaching for
  rest-api-designer or prisma-model-designer on a greenfield project.
---

# Project Brief

The single front door for a new software project. You describe what you're
building **once**. This skill collects a structured brief, then drives the full
design pipeline autonomously — API spec, Handoff Contract, Prisma schema, and
frontend scaffold — without asking you the same questions twice.

## How It Works

```
You → [one brief] → Project Brief
                         │
                         └─→ rest-api-designer → API Design Doc + OpenAPI spec
                                                         │
                                                 Handoff Contract
                                              ┌──────┤  ├──────────────┐
                                              ▼      │                 ▼
                              prisma-model-designer  │       ios-development
                                     │               ▼      (iOS client, SwiftUI)
                                schema.prisma  modern-fullstack-development        
                                              (web frontend, Next.js)
                                                     │
                                        [Frontend Contract + iOS Contract]
                                                     │
                                              [You review once]
```

Both `modern-fullstack-development` and `ios-development` consume the **same**
Handoff Contract — same resources, same auth, same base URL. Web and iOS stay
in sync from one source of truth.

---

## Step 1: Collect the Brief

Ask the user for a project description. A single conversational message is
enough — extract everything you can from it. Only ask follow-up questions for
**genuinely missing critical pieces**. The goal is ONE round of back-and-forth,
not an interview.

### What to extract from the description:

| Field | Extract from | Default if missing |
|---|---|---|
| `project_name` | explicit name or infer from domain | "my-project" |
| `description` | what the app does in one sentence | required — ask |
| `domain` | e-commerce / SaaS / blog / social / auth / custom | infer or ask |
| `primary_users` | who uses it (end users, admins, machines) | "end users" |
| `api_consumers` | web frontend / mobile / third-party / internal | "web frontend" |
| `auth_style` | JWT / API key / OAuth2 / none | JWT |
| `database` | postgresql / sqlite | postgresql |
| `key_resources` | main entities / data objects | required — ask if not clear |
| `special_requirements` | soft deletes / multi-tenant / file uploads / real-time | none |

### Minimum viable brief (what you need before proceeding):
- A description of what the app does
- A rough list of the key resources/entities (even informal: "users, posts, comments")

Everything else has a safe default. Don't block on it.

---

## Step 2: Confirm and Synthesize

Before running the pipeline, show the user a concise confirmation:

```
Here's what I'm building from:

**Project:** {project_name}
**What it does:** {description}
**Key resources:** {resource list}
**Auth:** {auth_style}
**Database:** {database}
**Special requirements:** {list or "none"}

I'll now produce:
1. API design doc + OpenAPI spec
2. Handoff Contract (wires the two skills together)
3. Prisma schema

Reply "go" to proceed, or correct anything above.
```

Wait for confirmation before proceeding.

---

## Step 3: Run the Pipeline

### 3a. Invoke rest-api-designer

Trigger the REST API designer with the full brief as context. It will produce:
- `{project_name}-api-design.md` (includes the Handoff Contract at the bottom)
- `{project_name}-openapi.yaml`
- `{project_name}-scaffolding/`

**Important:** Do not summarize or abbreviate the brief when passing it. Give
the full context so the API designer doesn't have to ask questions.

Tell the user: *"Designing the API..."* while this runs.

### 3b. Invoke prisma-model-designer

Immediately after the API design is complete, invoke the Prisma skill with the
`{project_name}-api-design.md` file in context. The Handoff Contract at the
bottom of that file will trigger **Handoff Mode** — the Prisma skill will build
the schema with zero additional questions.

Tell the user: *"Building the database schema from the API design..."*

### 3c. Invoke modern-fullstack-development

Immediately after the schema is complete, invoke the frontend skill with the
`{project_name}-api-design.md` file in context. The Handoff Contract triggers
**Handoff Mode** — it scaffolds the full web frontend: typed API client, SWR
hooks, route structure, components, middleware, and tests.

Tell the user: *"Scaffolding the web frontend..."*

### 3d. Invoke ios-development (if iOS client requested)

If the user wants an iOS app (ask during brief collection if unclear), invoke
the iOS skill with the same `{project_name}-api-design.md` file in context.
The Handoff Contract triggers **Handoff Mode** — it scaffolds the full Swift
client: MVVM structure, URLSession API layer, SwiftUI views, SwiftData models,
Keychain auth, and XCTest coverage.

Tell the user: *"Scaffolding the iOS client..."*

The web frontend and iOS client are built from the **same** Handoff Contract —
resources, auth, and base URL are identical in both.

### 3e. Produce the Pipeline Summary

Once all skills have run, output a single summary:

```markdown
# {project_name} — Build Complete

## What was produced

### Backend
| File | Description |
|---|---|
| `{project_name}-api-design.md` | Full API design + Handoff Contract |
| `{project_name}-openapi.yaml` | OpenAPI 3.1 spec |
| `schema.prisma` | Prisma schema, ready for `prisma migrate dev` |

### Web Frontend
| File / Folder | Description |
|---|---|
| `lib/api/` | Typed API client — one file per resource |
| `lib/hooks/` | SWR data fetching hooks |
| `app/(auth)/` | Login + register pages |
| `app/(dashboard)/` | Dashboard routes, one per resource |
| `components/{resource}/` | Card, form, and table components |
| `middleware.ts` | JWT route protection |

### iOS Client
| File / Folder | Description |
|---|---|
| `Core/Network/` | URLSession API client + Keychain auth |
| `Core/Auth/` | AuthService, AuthViewModel |
| `Core/Push/` | Push notification registration + handling |
| `Core/Navigation/` | Deep link routing |
| `Features/{Resource}/` | ViewModel + View + SwiftData model per resource |

## To get running

**Backend + Web:**
1. `prisma migrate dev --name init` — create your database
2. Copy `.env.example` → `.env`, fill in `DATABASE_URL` and `JWT_SECRET`
3. `npm run dev` — start Next.js

**iOS:**
1. Open `{project_name}.xcodeproj` in Xcode
2. Set `API_BASE_URL` in the scheme environment variables
3. Run on simulator or device

## Review checklist
- [ ] API design — resources and endpoints correct?
- [ ] Schema — relations, indexes, cascade behavior?
- [ ] Web frontend — components match UI expectations?
- [ ] iOS client — views and navigation flow correct?
- [ ] Auth — JWT wired on both platforms?
```

---

## Step 4: Handle Feedback

After the pipeline runs, the user may want to:

**Adjust the API** — re-trigger `rest-api-designer` with specific changes, then
re-run `prisma-model-designer` and `modern-fullstack-development` from the
updated Handoff Contract.

**Adjust the schema only** — re-trigger `prisma-model-designer` in Mode A or B
with specific model changes. Update the Handoff Contract manually if needed.

**Adjust the frontend only** — re-trigger `modern-fullstack-development` with
the existing Handoff Contract and describe what to change.

**Add a resource** — add it to both the API design and the Handoff Contract,
then regenerate the schema model and frontend components for the new resource only.

Always tell the user which files are being updated so they know what changed.

---

## Domain Quick-Starts

For known domains, apply these resource defaults (supplement with user's list):

### E-commerce
```
resources: User, Product, Category, Order, OrderItem, Cart, CartItem, Review, Address
auth: JWT
special: soft deletes on Product, Order history immutable
```

### SaaS / Multi-tenant
```
resources: Tenant, User, Membership, Plan, Subscription, InviteToken
auth: JWT
special: every resource scoped to tenantId, soft deletes everywhere
```

### Blog / CMS
```
resources: User, Post, Category, Tag, Comment, Media
auth: JWT (public reads, auth writes)
special: Post has status enum (DRAFT/PUBLISHED/ARCHIVED)
```

### Social / Community
```
resources: User, Post, Comment, Like, Follow, Notification
auth: JWT
special: Follow is self-referential on User, Like is polymorphic
```

### Auth Service (standalone)
```
resources: User, Session, RefreshToken, Role, Permission
auth: API key for service-to-service
special: Session has device/IP metadata, RefreshToken rotation
```

---

## Reference Files

| File | When to read |
|---|---|
| `references/brief-examples.md` | Examples of good briefs and their pipeline outputs |

---

## Principles

**One source of truth.** The user describes the project once. The Handoff
Contract carries that description forward. No skill asks the user to repeat
themselves.

**Opinionated defaults.** PostgreSQL, JWT, cuid IDs, cursor pagination,
ISO 8601 dates. Don't ask about these unless the user raises them.

**Review at the end, not the middle.** Run the full pipeline, then ask for
feedback. Don't pause between API design and schema for approval — the
Handoff Contract ensures they'll be consistent.

**Corrections are cheap.** It's faster to run the pipeline and adjust than
to perfect the brief upfront. Encourage the user to say "go" and iterate.
