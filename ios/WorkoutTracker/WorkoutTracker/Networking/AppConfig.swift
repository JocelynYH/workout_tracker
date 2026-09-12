import Foundation

/// Holds the backend API base URL. Editable from Settings so the app can point
/// at a local dev server, a home server, or a deployed backend without a rebuild.
enum AppConfig {
    private static let key = "apiBaseURL"
    private static let defaultURL = "http://localhost:3000"

    static var apiBaseURL: String {
        get { UserDefaults.standard.string(forKey: key) ?? defaultURL }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}
