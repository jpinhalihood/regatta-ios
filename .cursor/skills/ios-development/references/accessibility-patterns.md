# Accessibility Patterns

SwiftUI accessibility for iOS. WCAG 2.2 AA compliance applied to native
SwiftUI context: Dynamic Type, VoiceOver, and minimum tap targets.
Read this before generating any View code.

---

## Dynamic Type (Non-negotiable)

Never use fixed font sizes. Always use semantic text styles.

```swift
// ✅ Correct — scales with user's text size preference
Text(user.name)
    .font(.body)               // scales

Text(user.email)
    .font(.subheadline)        // scales

// ❌ Wrong — ignores accessibility settings
Text(user.name)
    .font(.system(size: 16))  // fixed, doesn't scale
```

### Text Style Reference

| Style | Use for | Base size |
|---|---|---|
| `.largeTitle` | Page/screen titles | 34pt |
| `.title` | Section headers | 28pt |
| `.title2` | Sub-headers | 22pt |
| `.title3` | Card titles | 20pt |
| `.headline` | Emphasized body | 17pt bold |
| `.body` | Default body text | 17pt |
| `.callout` | Secondary body | 16pt |
| `.subheadline` | Supporting text | 15pt |
| `.footnote` | Captions, metadata | 13pt |
| `.caption` | Smallest labels | 12pt |

### Layouts that must adapt
When text can grow, avoid fixed-height containers:

```swift
// ✅ Flexible — adapts to text size
VStack(alignment: .leading) {
    Text(title).font(.headline)
    Text(subtitle).font(.subheadline)
}

// ❌ Fixed height clips large text
VStack(alignment: .leading) {
    Text(title).font(.headline)
    Text(subtitle).font(.subheadline)
}
.frame(height: 60) // clips at large text sizes
```

---

## VoiceOver Labels

### Basic label + hint
```swift
Button {
    handleDelete(user.id)
} label: {
    Image(systemName: "trash")
}
.accessibilityLabel("Delete \(user.name)")
.accessibilityHint("Permanently removes this user")
```

### Grouping card-style views
```swift
// Without grouping: VoiceOver reads each child separately
// With grouping: reads as one element with a composed label

HStack {
    Text(user.name).font(.headline)
    Text(user.email).font(.subheadline)
    Text(user.role.displayName).font(.caption)
}
.accessibilityElement(children: .combine)
// VoiceOver now reads: "John Smith, john@example.com, Admin"
```

### Custom combined label
```swift
HStack {
    Image(systemName: "envelope")
    Text(user.email)
}
.accessibilityElement(children: .ignore)
.accessibilityLabel("Email: \(user.email)")
```

### Decorative images
```swift
Image(systemName: "star.fill")
    .foregroundStyle(.yellow)
    .accessibilityHidden(true)  // purely decorative
```

### Sorting and ordering
```swift
// When visual order differs from reading order
VStack {
    badgeView          // visually at top
    nameView           // name should be read first
}
.accessibilitySortPriority(1)  // on nameView to read first
```

---

## Minimum Tap Targets (44×44pt)

All interactive elements must meet the 44×44pt minimum.

```swift
// ✅ Explicit minimum target
Button {
    handleAction()
} label: {
    Image(systemName: "plus")
        .frame(minWidth: 44, minHeight: 44)
}

// ✅ Content inset approach for icon-only buttons
Button {
    handleAction()
} label: {
    Image(systemName: "plus")
}
.contentShape(Rectangle())
.frame(minWidth: 44, minHeight: 44)

// ❌ Too small — icon renders at ~20×20pt
Button {
    handleAction()
} label: {
    Image(systemName: "plus")
}
```

### Toolbar buttons
Toolbar items automatically meet tap targets. No extra work needed:
```swift
ToolbarItem(placement: .primaryAction) {
    Button("Save") { handleSave() }  // automatically 44pt
}
```

---

## Focus Management

### Sheets and modals
When presenting a sheet, VoiceOver focus automatically moves to the new
content. On dismiss, restore focus to the triggering element:

```swift
@State private var showingSheet = false
@AccessibilityFocusState private var isTriggerFocused: Bool

Button("Open Settings") {
    showingSheet = true
}
.accessibilityFocused($isTriggerFocused)
.sheet(isPresented: $showingSheet, onDismiss: {
    isTriggerFocused = true  // restore focus on dismiss
}) {
    SettingsView()
}
```

### Initial focus in forms
```swift
@AccessibilityFocusState private var isNameFocused: Bool

TextField("Name", text: $name)
    .accessibilityFocused($isNameFocused)
    .onAppear {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isNameFocused = true  // focus first field on appear
        }
    }
```

---

## Error and Status Announcements

When state changes happen (success, error, loading complete), announce
them to VoiceOver:

```swift
// Announce errors
.onChange(of: viewModel.error) { _, error in
    if let error {
        UIAccessibility.post(
            notification: .announcement,
            argument: "Error: \(error.localizedDescription)"
        )
    }
}

// Announce success
func handleSaveComplete() {
    UIAccessibility.post(
        notification: .announcement,
        argument: "User saved successfully"
    )
}
```

---

## Form Accessibility

```swift
Form {
    Section("Personal Details") {
        // LabeledContent auto-associates label with value for VoiceOver
        LabeledContent("Name") {
            TextField("Full name", text: $name)
                .accessibilityLabel("Full name field")
        }

        // Pickers auto-announce selection
        Picker("Role", selection: $role) {
            ForEach(UserRole.allCases, id: \.self) { role in
                Text(role.displayName).tag(role)
            }
        }
    }

    // Validation errors inline with field
    if nameError != nil {
        Text("Name is required")
            .foregroundStyle(.red)
            .font(.footnote)
            .accessibilityLabel("Error: Name is required")
    }
}
```

---

## Lists and Pagination

```swift
List {
    ForEach(users) { user in
        UserCardView(user: user)
            // Each row should have a distinct label for quick navigation
            .accessibilityLabel("\(user.name), \(user.role.displayName)")
    }

    // Loading indicator at end of list
    if viewModel.hasMore {
        ProgressView("Loading more users")
            .accessibilityLabel("Loading more users")
    }
}
// Pull to refresh
.refreshable {
    await viewModel.fetchUsers()
}
// Announce when list updates
.accessibilityLabel("Users list, \(viewModel.users.count) items")
```

---

## Push Notifications + Accessibility

When handling push notification actions, ensure the resulting navigation
is accessible:

```swift
// After navigating from a push notification, announce the destination
.onOpenURL { url in
    handleDeepLink(url)
    UIAccessibility.post(
        notification: .screenChanged,
        argument: "Navigated to \(destinationName)"
    )
}
```

---

## Accessibility Identifiers for UI Tests

Set identifiers on key interactive elements for XCUITest targeting.
Never rely on display text in UI tests — it breaks with localization.

```swift
Button("Add User") {
    showingCreateSheet = true
}
.accessibilityIdentifier("add_user_button")

TextField("Email", text: $email)
    .accessibilityIdentifier("email_field")

// In XCUITest:
// app.buttons["add_user_button"].tap()
// app.textFields["email_field"].typeText("test@example.com")
```

---

## Quick Audit Checklist

Before finalizing any View, verify:

- [ ] All text uses semantic font styles (no fixed sizes)
- [ ] All interactive elements have `.accessibilityLabel()`
- [ ] All buttons/tappables are minimum 44×44pt
- [ ] Decorative images have `.accessibilityHidden(true)`
- [ ] Card-style HStacks use `.accessibilityElement(children: .combine)`
- [ ] Forms use `LabeledContent` or explicit label association
- [ ] Error states announce via `UIAccessibility.post`
- [ ] Loading states have `.accessibilityLabel("Loading...")`
- [ ] Key interactive elements have `.accessibilityIdentifier()` for UI tests
- [ ] Modal dismiss restores focus to trigger element
