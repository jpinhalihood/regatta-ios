---
name: ios-development
description: >
  Senior-level iOS developer skill for building production-grade SwiftUI
  applications using MVVM, URLSession, async/await, Combine, and SwiftData.
  Use this skill whenever the user wants to build iOS UI, SwiftUI views,
  ViewModels, networking layers, data persistence, or any Swift/iOS code —
  even if they just say "build a SwiftUI view for X", "create a screen for",
  "wire up the API on iOS", "add a ViewModel", "persist this with SwiftData",
  "set up push notifications", or "build the iOS app". Always triggers for:
  new feature screens, ViewModel creation, API client layers, Keychain auth,
  SwiftData models, deep linking, push notification handling, accessibility,
  or any SwiftUI/Swift code generation task. Reads the Handoff Contract from
  rest-api-designer when available and scaffolds the full iOS client — typed
  API layer, ViewModels, SwiftUI views, SwiftData models — with no
  re-interviewing. Runs parallel to modern-fullstack-development as a
  second consumer of the same Handoff Contract.
---

# iOS Development

A senior-level skill for building production-grade SwiftUI applications.
MVVM architecture by default. Ships complete, tested, accessible Swift code
— no TODOs, no placeholders, no `// TODO: implement`.

## Pipeline Position

```
Project Brief → API Design (Handoff Contract) → Prisma Schema
                          │
          ┌───────────────┴────────────────┐
          │                                │
          ▼                                ▼
modern-fullstack-development        [THIS SKILL]
(web frontend)                      ios-development
                                          │
                               Swift Package structure
                               URLSession API client
                               ViewModels per resource
                               SwiftUI Views + Previews
                               SwiftData models
                               Keychain auth
                               Push + deep linking
                                          │
                                   iOS Contract
                              (feeds deploy/store skills)
```

Both skills consume the **same** Handoff Contract. Same resources, same auth
pattern, same base URL. The iOS client and web frontend are always in sync.

---

## Step 1: Mode Detection

**First action — always.** Scan context and attached files for a
`## Handoff Contract` section before asking any questions.

### Handoff Mode ← USE THIS WHEN CONTRACT IS PRESENT

When a Handoff Contract exists (produced by rest-api-designer):

1. **Extract from contract:**
   - `project` → app name, bundle ID prefix, target name
   - `resources` → generates Swift models + API client methods per resource
   - `auth` → wires Keychain storage, JWT injection in URLSession
   - `base_url` → sets `APIClient.baseURL`
   - `enums` → generates Swift enums with `Codable` conformance

2. **Scaffold immediately — no questions.** Produce the full structure
   defined in Step 4. Surface assumptions in the iOS Contract at the end.

3. **Stack defaults in Handoff Mode:**
   - Architecture: MVVM (`@Observable` ViewModels, iOS 17+)
   - Networking: URLSession + async/await
   - Reactivity: Combine for multi-publisher chains, async/await for
     single-shot calls
   - Persistence: SwiftData for local models (mirrors API resources)
   - Auth: Keychain via `Security` framework (no third-party deps)
   - Minimum deployment: iOS 17.0
   - Swift: 5.9+

### Standard Mode ← USE WHEN NO CONTRACT IS PRESENT

Collect before writing any code:

| Field | Question | Default |
|---|---|---|
| `min_ios` | Minimum iOS version? | iOS 17.0 |
| `persistence` | SwiftData, Core Data, or none? | SwiftData |
| `auth` | JWT, OAuth, none? | JWT + Keychain |
| `task` | What specifically needs to be built? | **Required** |

Only ask for genuinely missing critical pieces. Default everything else
and note assumptions in the iOS Contract.

---

## Step 2: Pre-Code Plan

Before writing any code, output a brief plan:

```
Building: {what}
Approach: {architecture decision and why}
Files to create/modify:
  - {Path/FileName.swift} — {what it does}
  - {Path/FileName.swift} — {what it does}
Assumptions:
  - {anything inferred the user should know}
```

Proceed immediately for clear tasks. Wait for "go" only if the plan
reveals a non-obvious architectural choice.

---

## Step 3: Code Standards

Non-negotiable in every file produced.

### Swift Style
- Swift 5.9+ syntax throughout
- `@Observable` macro for ViewModels (not `ObservableObject` / `@Published`)
- Explicit access control: `private`, `internal`, `public` — never omit
- `guard` for early exits, not nested `if let`
- avoid/minimize optional chaining; prefer `if-let` and `guard`
- No force unwraps (`!`) — use `guard let`, `if let`, or `??`
- No `try!` or `as!` — handle errors explicitly
- Trailing closures, shorthand argument names only when unambiguous
- File-per-type: one Swift file per struct/class/enum (with rare exceptions
  for small supporting types)
- Mark non-overridable methods `final` where applicable
- `// MARK: -` sections to organize large files:
  ```swift
  // MARK: - Properties
  // MARK: - Lifecycle
  // MARK: - Private Methods
  ```

### Naming Conventions
- Types: `PascalCase` — `UserViewModel`, `PostListView`, `APIClient`
- Properties/methods: `camelCase` — `fetchUsers()`, `isLoading`, `handleError`
- Constants: `camelCase` static lets — `static let baseURL`
- Enums: `PascalCase` type, `camelCase` cases — `enum AuthState { case loggedIn }`
- Files match their primary type name exactly: `UserViewModel.swift`

### MVVM Rules
- **View**: Pure SwiftUI, zero business logic. Reads ViewModel state, sends
  user actions to ViewModel. No direct API calls, no data manipulation.
- **ViewModel**: `@Observable` class. Owns async tasks, error handling,
  loading state. Talks to services/repositories. Never imports SwiftUI.
- **Model**: `Codable` structs. Pure data. No logic beyond computed properties.
- **Service/Repository**: Owns networking and persistence. Called by ViewModel,
  never by View. One service per domain (e.g. `UserService`, `PostService`).

```swift
// ✅ Correct layering
View → ViewModel → Service → APIClient / SwiftData
// ❌ Never
View → APIClient (skip ViewModel)
ViewModel → import SwiftUI (wrong layer)
```

### SOLID in Swift
- **S** — one type, one responsibility. `UserViewModel` handles user list
  state; `UserDetailViewModel` handles single user detail.
- **O** — extend via protocols, not subclassing.
- **D** — ViewModels depend on protocol abstractions, not concrete services.
  Enables testing via mock injection.

```swift
protocol UserServiceProtocol {
    func fetchUsers() async throws -> [User]
}

@Observable
final class UserListViewModel {
    private let service: any UserServiceProtocol  // abstraction, not concrete
    ...
}
```

### Error Handling
- Define typed errors per domain — no raw `Error` or `NSError` surfaces
- Always propagate to the ViewModel; Views only display, never handle
- User-facing errors get localized descriptions

```swift
enum APIError: LocalizedError {
    case unauthorized
    case notFound(id: String)
    case serverError(code: Int)
    case decodingFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Your session has expired. Please sign in again."
        case .notFound(let id): return "Item \(id) could not be found."
        case .serverError(let code): return "Server error (\(code)). Please try again."
        case .decodingFailed: return "Unexpected response from server."
        }
    }
}
```

### Accessibility (Non-negotiable)
Read `references/accessibility-patterns.md` for full guidance. Minimums:
- All interactive elements: `.accessibilityLabel()`, `.accessibilityHint()`
- Images: `.accessibilityLabel()` or `.accessibilityHidden(true)` if decorative
- Dynamic Type: use `.font(.body)` semantic fonts, never fixed sizes
- Minimum tap target: 44×44pt — use `.frame(minWidth: 44, minHeight: 44)`
- VoiceOver grouping: `.accessibilityElement(children: .combine)` for card-style
  views with multiple labels
- Test with: Xcode Accessibility Inspector, VoiceOver on device

---

## Step 4: Scaffold Output

### When in Handoff Mode — full scaffold

Read `references/networking-patterns.md` before generating the API client.
Read `references/view-viewmodel-templates.md` for standard MVVM shapes.

```
{Project}/
├── {Project}App.swift              ← @main, environment setup, deep link router
├── ContentView.swift               ← root navigation container
│
├── Core/
│   ├── Network/
│   │   ├── APIClient.swift         ← URLSession wrapper, auth injection, retry
│   │   ├── APIError.swift          ← typed error enum
│   │   └── Endpoint.swift          ← endpoint builder (path, method, body)
│   ├── Auth/
│   │   ├── AuthService.swift       ← login/logout/refresh logic
│   │   ├── KeychainService.swift   ← token read/write/delete
│   │   └── AuthViewModel.swift     ← @Observable, drives auth state app-wide
│   ├── Push/
│   │   ├── PushNotificationService.swift  ← registration, permission request
│   │   └── NotificationHandler.swift      ← foreground/background routing
│   └── Navigation/
│       ├── AppRouter.swift         ← NavigationPath + deep link parsing
│       └── DeepLinkHandler.swift   ← URL scheme / Universal Links parser
│
├── Features/
│   └── {Resource}/                 ← one folder per resource
│       ├── Models/
│       │   └── {Resource}.swift    ← Codable struct + SwiftData @Model
│       ├── Services/
│       │   └── {Resource}Service.swift   ← API calls + SwiftData queries
│       ├── ViewModels/
│       │   ├── {Resource}ListViewModel.swift
│       │   └── {Resource}DetailViewModel.swift
│       └── Views/
│           ├── {Resource}ListView.swift
│           ├── {Resource}DetailView.swift
│           ├── {Resource}FormView.swift
│           └── {Resource}CardView.swift
│
└── Shared/
    ├── Components/
    │   ├── LoadingView.swift        ← reusable loading state
    │   ├── ErrorView.swift          ← reusable error + retry
    │   └── EmptyStateView.swift     ← reusable empty state
    └── Extensions/
        ├── Date+Formatting.swift
        └── View+Accessibility.swift
```

### When in Standard Mode — task-scoped output

Produce only what the task requires. Follow the same file naming and folder
conventions. Never produce partial files.

### Output rules (always)
- Every file complete — no `// TODO`, no `fatalError("implement")`, no stubs
- All `import` statements explicit and minimal (only what's needed)
- `// MARK: -` sections in any file over ~50 lines
- `PreviewProvider` or `#Preview` macro on every View
- Doc comments (`///`) on all public types, methods, and non-obvious properties

---

## Step 5: Testing (Definition of Done)

Every output includes tests. Non-negotiable.

### Unit Tests (XCTest / Swift Testing)
- Prefer Swift Testing (`@Test`, `#expect`) for new code (Xcode 16+)
- Coverage target: **80% of new lines minimum**
- Test file location: `{Project}Tests/{Feature}/{Type}Tests.swift`
- Always test ViewModels — inject mock services via protocol

```swift
// Example ViewModel test with mock injection
@Test("UserListViewModel loads users on appear")
func testFetchUsersOnAppear() async throws {
    let mockService = MockUserService(users: [.fixture()])
    let viewModel = UserListViewModel(service: mockService)

    await viewModel.fetchUsers()

    #expect(viewModel.users.count == 1)
    #expect(viewModel.isLoading == false)
    #expect(viewModel.error == nil)
}
```

### UI Tests (XCUITest)
- Cover critical flows: auth, primary CRUD action, deep link entry
- File location: `{Project}UITests/{Feature}UITests.swift`
- Use accessibility identifiers set via `.accessibilityIdentifier()` —
  never rely on display text in UI tests

### What doesn't need tests
- SwiftUI `View` bodies (tested via UI tests)
- `PreviewProvider` / `#Preview` blocks
- Simple model structs with no logic

### Test fixtures
Create static fixture factories on models:
```swift
extension User {
    static func fixture(
        id: String = "usr_test",
        name: String = "Test User",
        email: String = "test@example.com"
    ) -> User {
        User(id: id, name: name, email: email)
    }
}
```

---

## Step 6: Commit Message

After every code output, produce a ready-to-use commit message:

```
{type}({scope}): {imperative description}

{body — what and why, not how}
```

Types: `feat`, `fix`, `refactor`, `test`, `chore`, `docs`, `perf`
Scope: feature name or layer (`auth`, `users`, `networking`, `push`)

Examples:
```
feat(users): add UserListView with MVVM and SwiftData caching

Scaffolds the Users feature with UserListViewModel (@Observable),
UserService (URLSession + async/await), SwiftData @Model for offline
cache, and UserListView with Dynamic Type and VoiceOver support.
Unit tests cover ViewModel state transitions via MockUserService.
```

```
feat(auth): implement Keychain JWT storage and refresh flow

Adds KeychainService for secure token storage, AuthService with
token refresh on 401, and AuthViewModel driving app-wide auth state.
Clears Keychain on logout and handles expired refresh tokens.
```

---

## Step 7: iOS Contract

**Always append this when building in Handoff Mode or producing a significant
scaffold.** This is the audit trail and handoff for downstream skills
(app-store-deploy, xcode-config).

```markdown
---
## iOS Contract
<!-- MACHINE-READABLE: consumed by app-store-deploy, project-brief -->

project: {project}
bundle_id: com.{org}.{project-lowercase}
min_ios: 17.0
swift_version: 5.9
architecture: MVVM

api_base: {base_url}
auth: {jwt | oauth | none}
keychain_service: {project}-keychain

features:
  - name: {FeatureName}
    screens: [{ListScreen, DetailScreen, FormScreen}]
    viewmodels: [{ListViewModel, DetailViewModel}]
    service: {FeatureService}
    swiftdata_model: {true | false}
    tested: {true | false}

push_notifications:
  enabled: {true | false}
  categories: [{category_identifier}]

deep_links:
  scheme: {appname}://
  routes:
    - pattern: {/resource/:id}
      destination: {FeatureDetailView}

swiftdata_models:
  - name: {ModelName}
    mirrors_api_resource: {ResourceName}
    offline_capable: {true | false}

coverage:
  unit_tests: {pass | partial | none}
  ui_tests: {pass | partial | none}
  accessibility_checked: {true | false}

not_implemented:
  - {anything skipped and why}

next_steps:
  - {suggested follow-on work}
```

---

## Step 8: Interaction Rules

- **Critique first:** Architectural violation (e.g. network call in View) →
  flag it in one sentence, show the correct layering, then write correct code.
- **Protocol-first for testability:** Any service used by a ViewModel gets a
  protocol. State this when producing new services — don't let it slip.
- **No force unwraps, ever:** If tempted to use `!`, solve the optionality
  properly. State what you did and why.
- **No lectures:** Raise an issue once. Don't repeat it across the response.
- **Complete or nothing:** Never partial files. If scope is too large, propose
  a sequenced plan first — feature by feature.

---

## Reference Files

| File | When to read |
|---|---|
| `references/networking-patterns.md` | Always in Handoff Mode — APIClient, Endpoint builder, auth injection |
| `references/view-viewmodel-templates.md` | When generating Views and ViewModels — standard MVVM shapes |
| `references/accessibility-patterns.md` | When adding any UI — Dynamic Type, VoiceOver, tap targets |

---

## Upstream Skills

This skill is fed by:
- **rest-api-designer** → Handoff Contract defines resources, auth, base URL
- **project-brief** → orchestrates the full pipeline including this skill

## Downstream Skills

This skill feeds:
- **app-store-deploy** (future) → iOS Contract lists bundle ID, capabilities,
  entitlements needed
- **xcode-config** (future) → iOS Contract lists min iOS, Swift version,
  framework dependencies
