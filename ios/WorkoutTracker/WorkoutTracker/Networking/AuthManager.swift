import Foundation

@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var currentUser: User?
    @Published private(set) var isCheckingSession = true
    @Published var errorMessage: String?

    init() {
        Task { await restoreSession() }
    }

    var isSignedIn: Bool { currentUser != nil }

    func restoreSession() async {
        defer { isCheckingSession = false }
        guard KeychainStore.loadToken() != nil else { return }
        do {
            let response = try await APIClient.shared.me()
            currentUser = response.user
        } catch {
            KeychainStore.deleteToken()
        }
    }

    func register(email: String, password: String, displayName: String) async {
        errorMessage = nil
        do {
            let response = try await APIClient.shared.register(
                email: email, password: password,
                displayName: displayName.isEmpty ? nil : displayName
            )
            KeychainStore.saveToken(response.token)
            currentUser = response.user
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func login(email: String, password: String) async {
        errorMessage = nil
        do {
            let response = try await APIClient.shared.login(email: email, password: password)
            KeychainStore.saveToken(response.token)
            currentUser = response.user
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() {
        KeychainStore.deleteToken()
        currentUser = nil
    }
}
