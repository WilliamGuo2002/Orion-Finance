import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var firebaseController: FirebaseController
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    @State private var showForgotPassword = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var logoAppeared = false
    @State private var titleAppeared = false
    @State private var formAppeared = false
    @FocusState private var focusedField: LoginField?

    private enum LoginField { case email, password }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 40)

                    // Animated branding
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [AppTheme.accent.opacity(0.1), AppTheme.accent.opacity(0.0)],
                                    center: .center, startRadius: 10, endRadius: 60
                                )
                            )
                            .frame(width: 100, height: 100)
                            .scaleEffect(logoAppeared ? 1 : 0.5)
                            .opacity(logoAppeared ? 1 : 0)

                        Image(systemName: "sparkle")
                            .font(.system(size: 36, weight: .light))
                            .foregroundColor(AppTheme.accent)
                            .scaleEffect(logoAppeared ? 1 : 0.3)
                            .opacity(logoAppeared ? 1 : 0)
                            .shadow(color: AppTheme.accent.opacity(0.4), radius: 12)
                    }

                    // App title
                    Text("Orion Finance")
                        .font(AppTheme.serifTitle(32))
                        .foregroundColor(AppTheme.primaryText)
                        .opacity(titleAppeared ? 1 : 0)
                        .offset(y: titleAppeared ? 0 : 10)

                    Text(L("Your investment companion"))
                        .font(AppTheme.caption(14))
                        .foregroundColor(AppTheme.secondaryText)
                        .opacity(titleAppeared ? 1 : 0)

                    // Login card
                    VStack(spacing: 16) {
                        // Email field with focus border
                        TextField(L("Email"), text: $email)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($focusedField, equals: .email)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(focusedField == .email ? AppTheme.accent : Color.clear, lineWidth: 1.5)
                            )

                        // Password field with focus border
                        SecureField(L("Password"), text: $password)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .password)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(focusedField == .password ? AppTheme.accent : Color.clear, lineWidth: 1.5)
                            )

                        if !errorMessage.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12))
                                Text(errorMessage)
                                    .font(.caption)
                            }
                            .foregroundColor(AppTheme.warning)
                            .multilineTextAlignment(.center)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Login button
                        Button(action: login) {
                            Group {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(L("Log In"))
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

                        // Forgot password
                        Button(L("Forgot Password?")) {
                            showForgotPassword = true
                        }
                        .font(.footnote)
                        .foregroundColor(AppTheme.secondaryText)
                    }
                    .padding(24)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
                    .padding(.horizontal, 32)
                    .opacity(formAppeared ? 1 : 0)
                    .offset(y: formAppeared ? 0 : 20)

                    // Divider
                    HStack {
                        Rectangle().fill(AppTheme.border).frame(height: 1)
                        Text(L("or")).font(.footnote).foregroundColor(AppTheme.secondaryText)
                        Rectangle().fill(AppTheme.border).frame(height: 1)
                    }
                    .padding(.horizontal, 32)

                    // Third-party login buttons
                    VStack(spacing: 12) {
                        // Google Sign-In
                        GoogleSignInButton()

                        // Apple Sign-In
                        SignInWithAppleButton(.signIn) { request in
                            let (_, hashedNonce) = firebaseController.prepareAppleSignIn()
                            request.requestedScopes = [.email, .fullName]
                            request.nonce = hashedNonce
                        } onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                Task {
                                    do {
                                        try await firebaseController.signInWithApple(authorization: authorization)
                                    } catch {
                                        errorMessage = error.localizedDescription
                                    }
                                }
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                            }
                        }
                        .frame(height: 50)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 32)

                    // Create account
                    Button(action: { showRegister = true }) {
                        HStack(spacing: 4) {
                            Text(L("Don't have an account?"))
                                .foregroundColor(AppTheme.secondaryText)
                            Text(L("Sign Up"))
                                .foregroundColor(AppTheme.accent)
                                .fontWeight(.semibold)
                        }
                        .font(.footnote)
                    }

                    // Beta skip button
                    Button(L("Skip Login (Beta)")) {
                        firebaseController.isLoggedIn = true
                    }
                    .font(.footnote)
                    .foregroundColor(AppTheme.secondaryText.opacity(0.5))

                    Spacer().frame(height: 40)
                }
            }
        }
        .sheet(isPresented: $showRegister) {
            RegisterView().environmentObject(firebaseController)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) { logoAppeared = true }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) { titleAppeared = true }
            withAnimation(.easeOut(duration: 0.6).delay(0.6)) { formAppeared = true }
        }
    }

    private func login() {
        guard !email.isEmpty, !password.isEmpty else {
            Haptic.warning()
            withAnimation(.easeInOut(duration: 0.3)) {
                errorMessage = L("Email and password are required")
            }
            return
        }
        Haptic.tap()
        isLoading = true
        errorMessage = ""
        Task {
            do {
                try await firebaseController.signIn(email: email, password: password)
            } catch {
                await MainActor.run {
                    Haptic.error()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        errorMessage = L("Authentication failed.")
                    }
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Google Sign-In Button
struct GoogleSignInButton: View {
    @EnvironmentObject var firebaseController: FirebaseController
    @State private var errorMessage = ""

    var body: some View {
        Button(action: signInWithGoogle) {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 18, weight: .medium))
                Text(L("Continue with Google"))
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.cardBackground)
            .foregroundColor(AppTheme.primaryText)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
        }
    }

    private func signInWithGoogle() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else { return }
        Task {
            do {
                try await firebaseController.signInWithGoogle(presenting: rootVC)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Forgot Password View
struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isSent = false
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "envelope.badge")
                        .font(.system(size: 48))
                        .foregroundColor(AppTheme.accent)

                    if isSent {
                        Text(L("Reset link sent!"))
                            .font(AppTheme.serifHeadline(20))
                            .foregroundColor(AppTheme.primaryText)
                        Text("Check your inbox at \(email)\nand follow the link to reset your password.")
                            .font(.body)
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                        Button(L("Done")) { dismiss() }
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppTheme.accent)
                            .cornerRadius(10)
                    } else {
                        Text(L("Forgot Password"))
                            .font(AppTheme.serifHeadline(20))
                            .foregroundColor(AppTheme.primaryText)
                        Text("Enter your email and we'll send you a link to reset your password.")
                            .font(.body)
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)

                        TextField(L("Email"), text: $email)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(AppTheme.warning)
                                .font(.caption)
                        }

                        Button(action: sendReset) {
                            Group {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(L("Send Reset Link"))
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
                }
                .padding(28)
                .background(AppTheme.cardBackground)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border, lineWidth: 1))
                .padding(.horizontal, 32)

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

    private func sendReset() {
        guard !email.isEmpty else {
            errorMessage = L("Please enter your email")
            return
        }
        isLoading = true
        errorMessage = ""
        Task {
            do {
                try await FirebaseController.shared.sendPasswordReset(email: email)
                await MainActor.run {
                    isSent = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
