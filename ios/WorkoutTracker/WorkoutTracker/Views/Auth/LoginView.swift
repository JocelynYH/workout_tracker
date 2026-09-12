import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
                    .padding(.top, 40)

                Text("Workout Tracker")
                    .font(.largeTitle.bold())

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal)

                if let error = authManager.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    Task {
                        isSubmitting = true
                        await authManager.login(email: email, password: password)
                        isSubmitting = false
                    }
                } label: {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text("Log In").frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(email.isEmpty || password.isEmpty || isSubmitting)
                .padding(.horizontal)

                Button("Create an account") {
                    showRegister = true
                }
                .font(.footnote)

                Spacer()
            }
            .sheet(isPresented: $showRegister) {
                RegisterView()
            }
        }
    }
}

#Preview {
    LoginView().environmentObject(AuthManager())
}
