import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Your info") {
                    TextField("Name", text: $displayName)
                        .textContentType(.name)
                    TextField("Email", text: $email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password (min 8 characters)", text: $password)
                        .textContentType(.newPassword)
                }

                if let error = authManager.errorMessage {
                    Text(error).foregroundStyle(.red)
                }
            }
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Button("Sign Up") {
                            Task {
                                isSubmitting = true
                                await authManager.register(
                                    email: email, password: password, displayName: displayName
                                )
                                isSubmitting = false
                                if authManager.isSignedIn { dismiss() }
                            }
                        }
                        .disabled(email.isEmpty || password.count < 8)
                    }
                }
            }
        }
    }
}

#Preview {
    RegisterView().environmentObject(AuthManager())
}
