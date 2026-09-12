import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var baseURL = AppConfig.apiBaseURL

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    if let user = authManager.currentUser {
                        LabeledContent("Name", value: user.displayName?.isEmpty == false ? user.displayName! : "—")
                        LabeledContent("Email", value: user.email)
                    }
                    Button("Log Out", role: .destructive) {
                        authManager.logout()
                    }
                }

                Section {
                    TextField("http://192.168.1.10:3000", text: $baseURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: baseURL) { _, newValue in
                            AppConfig.apiBaseURL = newValue
                        }
                } header: {
                    Text("Server address")
                } footer: {
                    Text("Point this at wherever the Workout Tracker backend is running. On the Simulator, localhost works. On a real device, use your computer's local network IP instead of localhost.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView().environmentObject(AuthManager())
}
