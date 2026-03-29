# Networking Patterns

URLSession + async/await + Combine patterns for iOS. Read this before generating
any API client code in Handoff Mode.

---

## Endpoint Builder (`Core/Network/Endpoint.swift`)

Type-safe endpoint construction. Every API call is defined as an `Endpoint` —
no raw strings scattered through services.

```swift
import Foundation

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - Endpoint

struct Endpoint {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]?
    let body: Encodable?
    let requiresAuth: Bool

    init(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem]? = nil,
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.body = body
        self.requiresAuth = requiresAuth
    }
}

// MARK: - Endpoint Factory Methods (one per resource)

extension Endpoint {
    // Users
    static func listUsers(cursor: String? = nil, limit: Int = 20) -> Endpoint {
        var items: [URLQueryItem] = [URLQueryItem(name: "limit", value: "\(limit)")]
        if let cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
        return Endpoint(path: "/v1/users", queryItems: items)
    }

    static func getUser(id: String) -> Endpoint {
        Endpoint(path: "/v1/users/\(id)")
    }

    static func createUser(body: CreateUserRequest) -> Endpoint {
        Endpoint(path: "/v1/users", method: .post, body: body)
    }

    static func updateUser(id: String, body: UpdateUserRequest) -> Endpoint {
        Endpoint(path: "/v1/users/\(id)", method: .patch, body: body)
    }

    static func deleteUser(id: String) -> Endpoint {
        Endpoint(path: "/v1/users/\(id)", method: .delete)
    }

    // Auth (no auth header required)
    static func login(body: LoginRequest) -> Endpoint {
        Endpoint(path: "/v1/auth/login", method: .post, body: body, requiresAuth: false)
    }

    static func refreshToken(body: RefreshRequest) -> Endpoint {
        Endpoint(path: "/v1/auth/refresh", method: .post, body: body, requiresAuth: false)
    }
}
```

---

## API Client (`Core/Network/APIClient.swift`)

The single URLSession wrapper. Handles auth injection, response decoding,
error mapping, and automatic token refresh on 401.

```swift
import Foundation

// MARK: - APIClient

final class APIClient {

    static let shared = APIClient()

    // MARK: - Configuration

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // Injected to break circular dependency with AuthService
    var tokenProvider: (() -> String?)? = nil
    var tokenRefresher: (() async throws -> Void)? = nil

    private init(
        baseURL: URL = URL(string: ProcessInfo.processInfo.environment["API_BASE_URL"]
            ?? "https://api.yourapp.com")!
    ) {
        self.baseURL = baseURL
        self.session = URLSession.shared
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Request Execution

    /// Executes an endpoint and decodes the response into T.
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let urlRequest = try buildRequest(from: endpoint)
        return try await execute(urlRequest, endpoint: endpoint, retryCount: 0)
    }

    /// Executes an endpoint with no response body (e.g. DELETE → 204).
    func requestVoid(_ endpoint: Endpoint) async throws {
        let urlRequest = try buildRequest(from: endpoint)
        let (_, response) = try await session.data(for: urlRequest)
        try validate(response: response, data: Data())
    }

    // MARK: - Private

    private func buildRequest(from endpoint: Endpoint) throws -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: true
        ) else {
            throw APIError.invalidURL
        }

        components.queryItems = endpoint.queryItems

        guard let url = components.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if endpoint.requiresAuth, let token = tokenProvider?() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = endpoint.body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        return request
    }

    private func execute<T: Decodable>(
        _ request: URLRequest,
        endpoint: Endpoint,
        retryCount: Int
    ) async throws -> T {
        let (data, response) = try await session.data(for: request)

        // Handle 401 — attempt one token refresh then retry
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 401,
           retryCount == 0,
           let refresher = tokenRefresher {
            try await refresher()
            let retryRequest = try buildRequest(from: endpoint)
            return try await execute(retryRequest, endpoint: endpoint, retryCount: 1)
        }

        try validate(response: response, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(underlying: error)
        }
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 409:
            throw APIError.conflict
        case 422:
            throw APIError.validationFailed(data: data)
        case 429:
            throw APIError.rateLimited
        case 500...599:
            throw APIError.serverError(code: httpResponse.statusCode)
        default:
            throw APIError.serverError(code: httpResponse.statusCode)
        }
    }
}

// MARK: - Type-erased Encodable helper

private struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        self.encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
```

---

## API Error (`Core/Network/APIError.swift`)

```swift
import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case conflict
    case validationFailed(data: Data)
    case rateLimited
    case serverError(code: Int)
    case decodingFailed(underlying: Error)
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request URL."
        case .invalidResponse:
            return "Received an unexpected response."
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .forbidden:
            return "You don't have permission to do that."
        case .notFound:
            return "The requested item could not be found."
        case .conflict:
            return "This item already exists."
        case .validationFailed:
            return "Some fields are invalid. Please check your input."
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .decodingFailed:
            return "Unexpected data from server. Please update the app."
        case .networkUnavailable:
            return "No internet connection. Please check your network."
        }
    }

    /// True if the error is recoverable by the user (retry / sign in again)
    var isRecoverable: Bool {
        switch self {
        case .networkUnavailable, .rateLimited, .serverError: return true
        case .unauthorized: return true  // recoverable via re-auth
        default: return false
        }
    }
}
```

---

## Keychain Auth (`Core/Auth/KeychainService.swift`)

```swift
import Foundation
import Security

// MARK: - KeychainService

final class KeychainService {

    static let shared = KeychainService()

    private let service: String

    private init(service: String = Bundle.main.bundleIdentifier ?? "app-keychain") {
        self.service = service
    }

    // MARK: - Token Operations

    func saveAccessToken(_ token: String) throws {
        try save(token, forKey: "access_token")
    }

    func saveRefreshToken(_ token: String) throws {
        try save(token, forKey: "refresh_token")
    }

    func getAccessToken() -> String? {
        try? get(forKey: "access_token")
    }

    func getRefreshToken() -> String? {
        try? get(forKey: "refresh_token")
    }

    func clearAll() {
        try? delete(forKey: "access_token")
        try? delete(forKey: "refresh_token")
    }

    // MARK: - Generic CRUD

    private func save(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        // Delete existing before saving (update pattern)
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status: status)
        }
    }

    private func get(forKey key: String) throws -> String {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8)
        else {
            throw KeychainError.notFound
        }

        return value
    }

    private func delete(forKey key: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - KeychainError

enum KeychainError: LocalizedError {
    case encodingFailed
    case saveFailed(status: OSStatus)
    case notFound

    var errorDescription: String? {
        switch self {
        case .encodingFailed: return "Failed to encode token data."
        case .saveFailed(let status): return "Keychain save failed: \(status)"
        case .notFound: return "Token not found in Keychain."
        }
    }
}
```

---

## Auth Service (`Core/Auth/AuthService.swift`)

```swift
import Foundation

// MARK: - Protocol (enables mock injection in tests)

protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> AuthTokens
    func logout() async throws
    func refreshTokens() async throws
}

// MARK: - AuthService

final class AuthService: AuthServiceProtocol {

    private let apiClient: APIClient
    private let keychain: KeychainService

    init(apiClient: APIClient = .shared, keychain: KeychainService = .shared) {
        self.apiClient = apiClient
        self.keychain = keychain
    }

    func login(email: String, password: String) async throws -> AuthTokens {
        let body = LoginRequest(email: email, password: password)
        let tokens: AuthTokens = try await apiClient.request(.login(body: body))
        try keychain.saveAccessToken(tokens.accessToken)
        try keychain.saveRefreshToken(tokens.refreshToken)
        return tokens
    }

    func logout() async throws {
        try await apiClient.requestVoid(.logout())
        keychain.clearAll()
    }

    func refreshTokens() async throws {
        guard let refreshToken = keychain.getRefreshToken() else {
            throw APIError.unauthorized
        }
        let body = RefreshRequest(refreshToken: refreshToken)
        let tokens: AuthTokens = try await apiClient.request(.refreshToken(body: body))
        try keychain.saveAccessToken(tokens.accessToken)
        try keychain.saveRefreshToken(tokens.refreshToken)
    }
}

// MARK: - Request/Response Models

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RefreshRequest: Encodable {
    let refreshToken: String
}

struct AuthTokens: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}
```

---

## Resource Service Pattern (`Features/{Resource}/Services/{Resource}Service.swift`)

Generate one of these per resource in the Handoff Contract.

```swift
import Foundation
import SwiftData

// MARK: - Protocol

protocol UserServiceProtocol {
    func fetchUsers(cursor: String?, limit: Int) async throws -> PaginatedResponse<User>
    func fetchUser(id: String) async throws -> User
    func createUser(_ input: CreateUserInput) async throws -> User
    func updateUser(id: String, input: UpdateUserInput) async throws -> User
    func deleteUser(id: String) async throws
}

// MARK: - UserService

final class UserService: UserServiceProtocol {

    private let apiClient: APIClient
    private let modelContext: ModelContext?

    init(apiClient: APIClient = .shared, modelContext: ModelContext? = nil) {
        self.apiClient = apiClient
        self.modelContext = modelContext
    }

    func fetchUsers(cursor: String? = nil, limit: Int = 20) async throws -> PaginatedResponse<User> {
        let response: PaginatedResponse<User> = try await apiClient.request(
            .listUsers(cursor: cursor, limit: limit)
        )
        // Cache to SwiftData if context available
        if let context = modelContext {
            response.data.forEach { context.insert($0.toSwiftDataModel()) }
            try? context.save()
        }
        return response
    }

    func fetchUser(id: String) async throws -> User {
        try await apiClient.request(.getUser(id: id))
    }

    func createUser(_ input: CreateUserInput) async throws -> User {
        try await apiClient.request(.createUser(body: input))
    }

    func updateUser(id: String, input: UpdateUserInput) async throws -> User {
        try await apiClient.request(.updateUser(id: id, body: input))
    }

    func deleteUser(id: String) async throws {
        try await apiClient.requestVoid(.deleteUser(id: id))
    }
}

// MARK: - Paginated Response

struct PaginatedResponse<T: Decodable>: Decodable {
    let data: [T]
    let pagination: Pagination

    struct Pagination: Decodable {
        let cursor: String?
        let hasMore: Bool
        let total: Int?
    }
}
```

---

## Combine Usage Pattern

Use Combine only when coordinating **multiple publishers** or adapting legacy
callback APIs. Prefer `async/await` for single-shot network calls.

```swift
// ✅ Good Combine use — multiple source coordination
func observeConnectivityAndRefresh() -> AnyPublisher<[User], Never> {
    Publishers.CombineLatest(
        NetworkMonitor.shared.$isConnected,
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
    )
    .filter { isConnected, _ in isConnected }
    .flatMap { [weak self] _ -> AnyPublisher<[User], Never> in
        guard let self else { return Just([]).eraseToAnyPublisher() }
        return Future { promise in
            Task {
                let users = (try? await self.service.fetchUsers(cursor: nil, limit: 20))?.data ?? []
                promise(.success(users))
            }
        }.eraseToAnyPublisher()
    }
    .eraseToAnyPublisher()
}

// ❌ Unnecessary Combine — use async/await instead
func fetchUsersPublisher() -> AnyPublisher<[User], Error> { ... }
```

---

## Generating API Client from Handoff Contract

For each resource in the Handoff Contract:

1. Create `Features/{Resource}/Models/{Resource}.swift` — `Codable` struct with
   fields mapped from contract types:
   - `String` → `String`
   - `Int`, `Float` → `Int`, `Double`
   - `Boolean` → `Bool`
   - `DateTime` → `Date` (decoded via `.iso8601` strategy)
   - `Json` → `[String: AnyCodable]` or a typed struct if shape is known
   - Enum values → `enum {Name}: String, Codable, CaseIterable`
   - Optional fields (`constraints: [optional]`) → `Type?`

2. Add static `Endpoint` factory methods to `Endpoint.swift` for the resource

3. Create `Features/{Resource}/Services/{Resource}Service.swift` with protocol
   + concrete implementation

4. Wire `SwiftData @Model` if `database_hint` is present (see view-viewmodel-templates.md)
