# View + ViewModel Templates

Standard MVVM shapes for SwiftUI. Use these as the base when generating feature
code. Every template follows the code standards in SKILL.md.

---

## Swift Model + SwiftData (`Features/{Resource}/Models/{Resource}.swift`)

One file per resource. `Codable` for API, `@Model` for SwiftData persistence.

```swift
import Foundation
import SwiftData

// MARK: - API Model (Codable)

struct User: Codable, Identifiable, Hashable {
    let id: String
    let email: String
    let name: String
    let role: UserRole
    let createdAt: Date
    let updatedAt: Date

    // MARK: - Computed

    var initials: String {
        name.split(separator: " ")
            .compactMap { $0.first }
            .map(String.init)
            .joined()
    }
}

// MARK: - Enum

enum UserRole: String, Codable, CaseIterable {
    case user = "USER"
    case admin = "ADMIN"

    var displayName: String {
        switch self {
        case .user: return "User"
        case .admin: return "Admin"
        }
    }
}

// MARK: - Input Models

struct CreateUserInput: Encodable {
    let email: String
    let name: String
    let password: String
    let role: UserRole
}

struct UpdateUserInput: Encodable {
    let name: String?
    let role: UserRole?
}

// MARK: - SwiftData Model

@Model
final class UserModel {
    @Attribute(.unique) var id: String
    var email: String
    var name: String
    var roleRaw: String
    var createdAt: Date
    var updatedAt: Date
    var cachedAt: Date

    init(from user: User) {
        self.id = user.id
        self.email = user.email
        self.name = user.name
        self.roleRaw = user.role.rawValue
        self.createdAt = user.createdAt
        self.updatedAt = user.updatedAt
        self.cachedAt = Date()
    }

    var role: UserRole {
        UserRole(rawValue: roleRaw) ?? .user
    }

    /// Convert back to API model for use in Views
    func toAPIModel() -> User {
        User(
            id: id,
            email: email,
            name: name,
            role: role,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - API Model → SwiftData

extension User {
    func toSwiftDataModel() -> UserModel {
        UserModel(from: self)
    }
}

// MARK: - Test Fixture

extension User {
    static func fixture(
        id: String = "usr_test",
        name: String = "Test User",
        email: String = "test@example.com",
        role: UserRole = .user
    ) -> User {
        User(
            id: id,
            email: email,
            name: name,
            role: role,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
```

---

## List ViewModel (`Features/{Resource}/ViewModels/{Resource}ListViewModel.swift`)

```swift
import Foundation
import Combine

// MARK: - UserListViewModel

@Observable
final class UserListViewModel {

    // MARK: - State

    private(set) var users: [User] = []
    private(set) var isLoading = false
    private(set) var error: APIError?
    private(set) var hasMore = false
    private var cursor: String?

    // MARK: - Dependencies

    private let service: any UserServiceProtocol

    // MARK: - Init

    init(service: any UserServiceProtocol = UserService()) {
        self.service = service
    }

    // MARK: - Actions

    func fetchUsers() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            let response = try await service.fetchUsers(cursor: nil, limit: 20)
            users = response.data
            cursor = response.pagination.cursor
            hasMore = response.pagination.hasMore
        } catch let apiError as APIError {
            error = apiError
        } catch {
            self.error = .serverError(code: -1)
        }

        isLoading = false
    }

    func fetchNextPage() async {
        guard hasMore, !isLoading, let cursor else { return }
        isLoading = true

        do {
            let response = try await service.fetchUsers(cursor: cursor, limit: 20)
            users.append(contentsOf: response.data)
            self.cursor = response.pagination.cursor
            hasMore = response.pagination.hasMore
        } catch let apiError as APIError {
            error = apiError
        } catch {
            self.error = .serverError(code: -1)
        }

        isLoading = false
    }

    func deleteUser(id: String) async {
        do {
            try await service.deleteUser(id: id)
            users.removeAll { $0.id == id }
        } catch let apiError as APIError {
            error = apiError
        }
    }

    func clearError() {
        error = nil
    }
}
```

---

## Detail ViewModel (`Features/{Resource}/ViewModels/{Resource}DetailViewModel.swift`)

```swift
import Foundation

// MARK: - UserDetailViewModel

@Observable
final class UserDetailViewModel {

    // MARK: - State

    private(set) var user: User?
    private(set) var isLoading = false
    private(set) var isSaving = false
    private(set) var error: APIError?

    // MARK: - Dependencies

    private let service: any UserServiceProtocol
    let userID: String

    // MARK: - Init

    init(userID: String, service: any UserServiceProtocol = UserService()) {
        self.userID = userID
        self.service = service
    }

    // MARK: - Actions

    func fetchUser() async {
        isLoading = true
        error = nil

        do {
            user = try await service.fetchUser(id: userID)
        } catch let apiError as APIError {
            error = apiError
        }

        isLoading = false
    }

    func updateUser(name: String, role: UserRole) async -> Bool {
        isSaving = true
        error = nil

        do {
            let input = UpdateUserInput(name: name, role: role)
            user = try await service.updateUser(id: userID, input: input)
            isSaving = false
            return true
        } catch let apiError as APIError {
            error = apiError
            isSaving = false
            return false
        }
    }

    func clearError() {
        error = nil
    }
}
```

---

## List View (`Features/{Resource}/Views/{Resource}ListView.swift`)

```swift
import SwiftUI

// MARK: - UserListView

struct UserListView: View {

    // MARK: - State

    @State private var viewModel = UserListViewModel()
    @State private var showingCreateSheet = false
    @State private var navigationPath = NavigationPath()

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            content
                .navigationTitle("Users")
                .navigationDestination(for: User.self) { user in
                    UserDetailView(userID: user.id)
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingCreateSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add user")
                    }
                }
                .sheet(isPresented: $showingCreateSheet) {
                    UserFormView(mode: .create) { _ in
                        showingCreateSheet = false
                        Task { await viewModel.fetchUsers() }
                    }
                }
        }
        .task { await viewModel.fetchUsers() }
    }

    // MARK: - Content States

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.users.isEmpty {
            loadingView
        } else if let error = viewModel.error, viewModel.users.isEmpty {
            ErrorView(error: error) {
                Task { await viewModel.fetchUsers() }
            }
        } else if viewModel.users.isEmpty {
            EmptyStateView(
                title: "No Users",
                message: "Add your first user to get started.",
                systemImage: "person.3"
            ) {
                showingCreateSheet = true
            }
        } else {
            listView
        }
    }

    private var loadingView: some View {
        List {
            ForEach(0..<6, id: \.self) { _ in
                UserCardView.placeholder
            }
        }
        .accessibilityLabel("Loading users")
    }

    private var listView: some View {
        List {
            ForEach(viewModel.users) { user in
                NavigationLink(value: user) {
                    UserCardView(user: user)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        Task { await viewModel.deleteUser(id: user.id) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            if viewModel.hasMore {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .task { await viewModel.fetchNextPage() }
            }
        }
        .refreshable { await viewModel.fetchUsers() }
        .alert("Error", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
    }
}

// MARK: - Preview

#Preview {
    UserListView()
}
```

---

## Card View (`Features/{Resource}/Views/{Resource}CardView.swift`)

```swift
import SwiftUI

// MARK: - UserCardView

struct UserCardView: View {

    let user: User

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(user.initials)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .accessibilityHidden(true)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Role badge
            Text(user.role.displayName)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(badgeColor.opacity(0.15), in: Capsule())
                .foregroundStyle(badgeColor)
        }
        .padding(.vertical, 4)
        // VoiceOver: treat as one element
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(user.name), \(user.role.displayName)")
        .accessibilityHint("Double tap to view details")
    }

    // MARK: - Helpers

    private var badgeColor: Color {
        user.role == .admin ? .purple : .blue
    }

    // MARK: - Placeholder (loading state)

    static var placeholder: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 120, height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 180, height: 12)
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .redacted(reason: .placeholder)
        .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview {
    List {
        UserCardView(user: .fixture())
        UserCardView(user: .fixture(name: "Admin User", role: .admin))
        UserCardView.placeholder
    }
}
```

---

## Form View (`Features/{Resource}/Views/{Resource}FormView.swift`)

```swift
import SwiftUI

// MARK: - FormMode

enum FormMode {
    case create
    case edit(User)

    var title: String {
        switch self {
        case .create: return "New User"
        case .edit: return "Edit User"
        }
    }

    var submitLabel: String {
        switch self {
        case .create: return "Create"
        case .edit: return "Save"
        }
    }
}

// MARK: - UserFormView

struct UserFormView: View {

    // MARK: - Config

    let mode: FormMode
    let onComplete: (User) -> Void

    // MARK: - State

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var role = UserRole.user
    @State private var isSaving = false
    @State private var error: APIError?
    @Environment(\.dismiss) private var dismiss

    private let service: any UserServiceProtocol

    // MARK: - Init

    init(
        mode: FormMode,
        service: any UserServiceProtocol = UserService(),
        onComplete: @escaping (User) -> Void
    ) {
        self.mode = mode
        self.service = service
        self.onComplete = onComplete
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    LabeledContent("Name") {
                        TextField("Full name", text: $name)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Full name")
                    }

                    LabeledContent("Email") {
                        TextField("Email address", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Email address")
                    }

                    if case .create = mode {
                        LabeledContent("Password") {
                            SecureField("Password", text: $password)
                                .textContentType(.newPassword)
                                .multilineTextAlignment(.trailing)
                                .accessibilityLabel("Password")
                        }
                    }
                }

                Section("Role") {
                    Picker("Role", selection: $role) {
                        ForEach(UserRole.allCases, id: \.self) { role in
                            Text(role.displayName).tag(role)
                        }
                    }
                }

                if let error {
                    Section {
                        Text(error.localizedDescription)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                    .accessibilityLabel("Error: \(error.localizedDescription)")
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.submitLabel) {
                        Task { await handleSubmit() }
                    }
                    .disabled(isSaving || !isValid)
                }
            }
            .disabled(isSaving)
            .overlay {
                if isSaving {
                    ProgressView()
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .onAppear(perform: populateForEdit)
    }

    // MARK: - Validation

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@") &&
        (mode is FormMode ? true : password.count >= 8)
    }

    // MARK: - Actions

    private func populateForEdit() {
        guard case .edit(let user) = mode else { return }
        name = user.name
        email = user.email
        role = user.role
    }

    private func handleSubmit() async {
        isSaving = true
        error = nil

        do {
            let result: User
            switch mode {
            case .create:
                let input = CreateUserInput(email: email, name: name, password: password, role: role)
                result = try await service.createUser(input)
            case .edit(let user):
                let input = UpdateUserInput(name: name, role: role)
                result = try await service.updateUser(id: user.id, input: input)
            }
            onComplete(result)
        } catch let apiError as APIError {
            error = apiError
        } catch {
            self.error = .serverError(code: -1)
        }

        isSaving = false
    }
}

// MARK: - Preview

#Preview("Create") {
    UserFormView(mode: .create) { _ in }
}

#Preview("Edit") {
    UserFormView(mode: .edit(.fixture())) { _ in }
}
```

---

## Shared Components

### `Shared/Components/ErrorView.swift`
```swift
import SwiftUI

struct ErrorView: View {
    let error: Error
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Something went wrong", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Try Again", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .accessibilityElement(children: .combine)
    }
}
```

### `Shared/Components/EmptyStateView.swift`
```swift
import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let action: (() -> Void)?

    init(title: String, message: String, systemImage: String, action: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            if let action {
                Button("Get Started", action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}
```

---

## Adapting Templates to Other Resources

1. Replace `User` / `user` / `users` throughout with the resource name
2. Replace fields (`name`, `email`, `role`) with fields from the Handoff Contract
3. Map Handoff Contract field types to Swift types (see networking-patterns.md)
4. Adjust `initials` / display computed properties to match meaningful fields
5. Adjust `badgeColor` logic for enum fields in the card view
6. Update `isValid` in the form view to match required fields
7. Add `@Relationship` to SwiftData model if the resource has relations in the contract
