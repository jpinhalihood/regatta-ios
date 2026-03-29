---
name: modern-fullstack-development
description: >
  Senior-level fullstack developer skill for building scalable, production-grade
  web applications with TypeScript, Next.js App Router, TailwindCSS, and Shadcn.
  Use this skill whenever the user wants to build UI, components, pages, API routes,
  hooks, or any frontend code — even if they just say "build me a component",
  "create a page for X", "wire up the frontend", "scaffold the UI", "add a form
  for", "connect to the API", or "set up Next.js". Always triggers for: new
  features, component creation, API route handlers, auth UI, data fetching hooks,
  refactoring, or any code generation task in a TS/JS frontend project. Reads the
  Handoff Contract from rest-api-designer when available and scaffolds the entire
  frontend — typed API client, route structure, components — with no re-interviewing.
---

# Modern Fullstack Development

A senior-level skill for building production-grade frontend code with TypeScript,
Next.js App Router, TailwindCSS, and Shadcn. Opinionated by default. Ships complete,
tested, accessible code — no TODOs, no placeholders.

## Pipeline Position

```
Project Brief → API Design (Handoff Contract) → Prisma Schema → [THIS SKILL]
                                                                       │
                                              /app routes, components, │
                                              typed API client, hooks  │
                                                                       │
                                                          Frontend Contract
                                                     (feeds testing/deploy skills)
```

---

## Step 1: Mode Detection

**First action — always.** Scan context and attached files for a `## Handoff Contract`
section before asking any questions.

### Handoff Mode ← USE THIS WHEN CONTRACT IS PRESENT

When a Handoff Contract exists (produced by rest-api-designer):

1. **Extract from contract:**
   - `project` → app name, used for naming conventions
   - `resources` → generates typed API client methods + TypeScript interfaces
   - `auth` → wires correct auth pattern (JWT handler, middleware, session hooks)
   - `base_url` → sets API base in the client config
   - `database_hint` → informs whether to use server components with direct Prisma
     calls or API routes as the data layer

2. **Scaffold immediately — no questions.** Produce the full output defined in
   Step 4. Surface assumptions in the Frontend Contract at the end.

3. **Stack defaults in Handoff Mode:**
   - Framework: Next.js 14+ App Router
   - Styling: TailwindCSS + Shadcn/ui
   - Auth: `jose` for JWT verification, middleware-based route protection
   - Data fetching: Server Components for initial load, SWR for client-side mutations
   - Forms: React Hook Form + Zod
   - API client: typed fetch wrapper (see `references/api-client-patterns.md`)

### Standard Mode ← USE WHEN NO CONTRACT IS PRESENT

Collect before writing any code:

| Field | Question | Default |
|---|---|---|
| `framework` | Next.js App Router, Vite+React, Vue? | Next.js App Router |
| `styling` | Tailwind + Shadcn, plain Tailwind, CSS modules? | Tailwind + Shadcn |
| `auth` | JWT, session, OAuth, none? | JWT |
| `data_layer` | API routes, direct DB (Prisma), external API? | API routes |
| `task` | What specifically needs to be built? | **Required** |

Only ask for missing critical pieces. If the task is clear, start with stack
defaults and note assumptions.

---

## Step 2: Pre-Code Plan

Before writing any code, output a brief plan:

```
Building: {what}
Approach: {architecture decision — why this structure}
Files to create/modify:
  - {path} — {what it does}
  - {path} — {what it does}
Assumptions:
  - {anything inferred that the user should know}
```

Wait for "go" only if the plan reveals something non-obvious. For clear tasks,
proceed immediately after showing the plan.

---

## Step 3: Code Standards

These are non-negotiable in every file produced.

### TypeScript
- Strict mode always (`"strict": true` in tsconfig)
- No `any` — use `unknown` and narrow, or define a type
- Define explicit return types on all functions and hooks
- Prefer `interface` for object shapes, `type` for unions and primitives
- Co-locate types with the code that uses them; export only what's consumed elsewhere

### Component Rules
- `const` over `function` declarations: `const MyComponent = () => {}`
- Early returns for guards, loading, error states — before the main render
- Event handlers prefixed with `handle`: `handleClick`, `handleSubmit`, `handleKeyDown`
- No inline styles — Tailwind classes only
- `class:` directive over ternary in class bindings where framework supports it
- No semicolons
- Descriptive names: `userProfileCard` not `card1`, `handleFormSubmit` not `submit`

### Accessibility (WCAG 2.2 AA — non-negotiable)
- All interactive elements: `tabIndex`, `aria-label`, `onKeyDown` alongside `onClick`
- Images: meaningful `alt` text (empty string `alt=""` for decorative)
- Forms: `<label>` associated with every input via `htmlFor` / `id`
- Color contrast: never rely on color alone to convey information
- Focus management: trap focus in modals, restore on close
- Semantic HTML first — `<button>` not `<div onClick>`

### SOLID in React
- **S** — one component, one responsibility. If it does two things, split it.
- **O** — extend via props/composition, not by modifying existing components
- **D** — depend on abstractions (hooks, context) not concrete implementations
- If a requested feature violates these: note it, suggest the decoupled approach,
  then write what they asked if they still want it

### Security (OWASP)
- Never trust client input — validate with Zod on both client and server
- Never expose secrets in client components (`NEXT_PUBLIC_` prefix = public)
- Sanitize all user-generated content before rendering
- Auth checks in middleware AND in server components/actions (defense in depth)
- No `dangerouslySetInnerHTML` without explicit sanitization

---

## Step 4: Scaffold Output

### When in Handoff Mode — full scaffold

Produce this complete structure. Read `references/api-client-patterns.md` before
generating the API client. Read `references/component-templates.md` for standard
component shapes.

```
{project}/
├── lib/
│   ├── api/
│   │   ├── client.ts          ← typed fetch wrapper with auth headers
│   │   └── {resource}.ts      ← one file per resource (CRUD methods, typed)
│   ├── hooks/
│   │   └── use-{resource}.ts  ← SWR hooks for each resource
│   └── types/
│       └── api.ts             ← TypeScript interfaces from Handoff Contract
├── app/
│   ├── (auth)/
│   │   ├── login/page.tsx
│   │   └── register/page.tsx
│   ├── (dashboard)/
│   │   └── {resource}/
│   │       ├── page.tsx       ← server component, initial data fetch
│   │       ├── [id]/page.tsx  ← detail page
│   │       └── _components/   ← route-local components
│   └── api/                   ← API routes if data_layer = api routes
│       └── {resource}/route.ts
├── components/
│   ├── ui/                    ← Shadcn primitives (auto-generated)
│   └── {resource}/
│       ├── {resource}-card.tsx
│       ├── {resource}-form.tsx
│       └── {resource}-table.tsx
└── middleware.ts              ← JWT verification, route protection
```

### When in Standard Mode — task-scoped output

Produce only what the task requires. Follow the same file naming conventions.
Never produce partial files — every file must be complete and runnable.

### Output rules (always)
- Every file complete — no TODOs, no `// implement this`, no placeholders
- All imports explicit and correct
- Types defined before use
- Zod schemas alongside forms
- JSDoc on every hook and complex utility:
  ```typescript
  /**
   * Fetches and caches {resource} list with SWR.
   * @param filters - Optional query filters passed to the API
   * @returns {data, isLoading, error, mutate}
   */
  ```

---

## Step 5: Testing (Definition of Done)

Every output includes tests. This is not optional.

### Unit tests (Jest)
- Coverage target: **80% of new lines minimum**
- Test file co-located: `{component}.test.tsx` next to `{component}.tsx`
- Test: happy path, loading state, error state, edge cases
- Mock API calls — never hit real endpoints in unit tests

```typescript
// Example structure
describe('UserCard', () => {
  it('renders user name and email', () => { ... })
  it('shows skeleton while loading', () => { ... })
  it('shows error state on fetch failure', () => { ... })
  it('calls onDelete when delete button clicked', () => { ... })
})
```

### E2E tests (Playwright)
- Write for critical user flows only (auth, primary CRUD, key conversions)
- Place in `e2e/{feature}.spec.ts`
- Use page object model for reusable selectors

### What doesn't need tests
- Shadcn/ui primitives (already tested by the library)
- Pure type definitions
- Static config files

---

## Step 6: Commit Message

After every code output, produce a ready-to-use commit message:

```
{type}({scope}): {imperative description}

{body — what and why, not how}
```

Types: `feat`, `fix`, `refactor`, `test`, `chore`, `docs`, `style`, `perf`

Examples:
```
feat(users): add user profile page with edit form

Scaffolds the /app/(dashboard)/users/[id] route with server-side data
fetching, optimistic updates via SWR mutation, and Zod-validated form.
Includes Playwright E2E test for the edit flow.
```

```
refactor(api-client): extract typed fetch wrapper from components

Moves inline fetch calls into lib/api/client.ts to centralize auth
header injection and error normalization. No behavior change.
```

---

## Step 7: Frontend Contract

**Always append this when building in Handoff Mode or producing a significant scaffold.**
This is the audit trail and handoff point for downstream skills.

```markdown
---
## Frontend Contract
<!-- MACHINE-READABLE: consumed by testing-skill, deploy-skill, project-brief -->

project: {project}
framework: next.js-app-router
styling: tailwind + shadcn
auth: {jwt | session | oauth | none}
api_base: {base_url}

pages:
  - route: {/path}
    component: {FilePath}
    auth_required: {true | false}
    data_sources: [{resource.method}]

components:
  - name: {ComponentName}
    path: {FilePath}
    props: [{propName: type}]
    tested: {true | false}

api_client:
  - resource: {ResourceName}
    methods: [{list, get, create, update, delete}]
    path: lib/api/{resource}.ts
    typed: true

hooks:
  - name: use{Resource}
    path: lib/hooks/use-{resource}.ts
    swr: {true | false}

coverage:
  unit_tests: {pass | partial | none}
  e2e_tests: {pass | partial | none}
  a11y_checked: {true | false}

not_implemented:
  - {anything explicitly skipped and why}

next_steps:
  - {suggested follow-on work}
```

---

## Step 8: Interaction Rules

- **Critique first:** Feature violates SOLID → suggest decoupled approach before
  writing. One sentence, not a lecture. Then write what they asked if they confirm.
- **Refactor by default:** Spaghetti code in context → offer to split into testable
  units before adding the new feature.
- **No lectures:** State the issue once, move on. Don't repeat SOLID/OWASP concerns
  after the first mention.
- **Complete or nothing:** Never produce partial implementations. If scope is too
  large for one response, say so and propose a sequenced plan.

---

## Reference Files

| File | When to read |
|---|---|
| `references/api-client-patterns.md` | Always in Handoff Mode — typed fetch wrapper and resource client patterns |
| `references/component-templates.md` | When generating resource components (card, form, table) |

---

## Upstream Skills

This skill is fed by:
- **rest-api-designer** → Handoff Contract defines resources, auth, base URL
- **prisma-model-designer** → schema informs whether to use direct DB calls or API routes
- **project-brief** → orchestrates the full pipeline including this skill

## Downstream Skills

This skill feeds:
- **testing-skill** (future) → Frontend Contract lists coverage gaps and untested flows
- **deploy-skill** (future) → Frontend Contract lists routes, auth requirements, env vars needed
