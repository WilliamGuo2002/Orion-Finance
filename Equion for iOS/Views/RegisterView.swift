import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var firebaseController: FirebaseController
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                VStack(spacing: 16) {
                    Text("Create Account")
                        .font(AppTheme.serifHeadline(22))
                        .foregroundColor(AppTheme.primaryText)

                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(AppTheme.warning)
                            .font(.caption)
                    }

                    Button(action: register) {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Register")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(.white)
                    }
                    .background(AppTheme.accent)
                    .cornerRadius(10)
                    .disabled(isLoading)
                }
                .padding(24)
                .background(AppTheme.cardBackground)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border, lineWidth: 1))
                .padding(.horizontal, 40)

                Spacer()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(AppTheme.primaryText)
                    }
                }
            }
        }
    }

    private func register() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            return
        }
        isLoading = true
        errorMessage = ""

        Task {
            do {
                try await firebaseController.register(email: email, password: password)
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run {
                    errorMessage = "Registration failed: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}
