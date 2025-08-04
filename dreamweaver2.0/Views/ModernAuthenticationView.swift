import SwiftUI

struct ModernAuthenticationView: View {
    @EnvironmentObject var supabaseService: SupabaseService
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            // Background gradient
            DesignSystem.Gradients.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // Header Section
                    headerSection
                    
                    // Auth Form
                    authFormSection
                    
                    // Auth Button
                    authButton
                    
                    // Toggle Auth Mode
                    toggleAuthMode
                    
                    Spacer()
                }
                .padding(.horizontal, DesignSystem.Layout.screenPadding)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // App Logo
            ZStack {
                Circle()
                    .fill(DesignSystem.Gradients.primary)
                    .frame(width: 100, height: 100)
                    .glowEffect(color: DesignSystem.Colors.primary)
                
                Image(systemName: "book.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            // App Name and Tagline
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("DreamWeaver")
                    .font(DesignSystem.Typography.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Where stories come alive with AI")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, DesignSystem.Spacing.xxxl)
    }
    
    private var authFormSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Email Field
            ModernTextField(
                title: "Email",
                text: $email,
                placeholder: "Enter your email",
                keyboardType: .emailAddress
            )
            
            // Username Field (Sign Up Only)
            if isSignUp {
                ModernTextField(
                    title: "Username",
                    text: $username,
                    placeholder: "Choose a username"
                )
            }
            
            // Password Field
            ModernSecureField(
                title: "Password",
                text: $password,
                placeholder: "Enter your password"
            )
            
            // Confirm Password Field (Sign Up Only)
            if isSignUp {
                ModernSecureField(
                    title: "Confirm Password",
                    text: $confirmPassword,
                    placeholder: "Confirm your password"
                )
            }
        }
        .padding(.vertical, DesignSystem.Spacing.lg)
    }
    
    private var authButton: some View {
        Button(action: {
            performAuth()
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.textPrimary))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: isSignUp ? "person.badge.plus" : "person.badge.key")
                        .font(.title3)
                }
                
                Text(isSignUp ? "Create Account" : "Sign In")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(DesignSystem.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(DesignSystem.Gradients.primary)
            .cornerRadius(DesignSystem.CornerRadius.lg)
            .shadow(
                color: DesignSystem.Colors.primary.opacity(0.4),
                radius: 15,
                x: 0,
                y: 8
            )
        }
        .disabled(isLoading || !isFormValid)
        .opacity(isFormValid ? 1.0 : 0.6)
        .animation(DesignSystem.Animations.medium, value: isFormValid)
    }
    
    private var toggleAuthMode: some View {
        Button(action: {
            withAnimation(DesignSystem.Animations.spring) {
                isSignUp.toggle()
                clearForm()
            }
        }) {
            HStack {
                Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text(isSignUp ? "Sign In" : "Sign Up")
                    .foregroundColor(DesignSystem.Colors.primary)
                    .fontWeight(.semibold)
            }
            .font(DesignSystem.Typography.callout)
        }
        .padding(.top, DesignSystem.Spacing.md)
    }
    
    private var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty && !password.isEmpty && !username.isEmpty && 
                   password == confirmPassword && password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    private func performAuth() {
        isLoading = true
        
        Task {
            do {
                if isSignUp {
                    try await supabaseService.signUp(email: email, password: password, username: username)
                } else {
                    try await supabaseService.signIn(email: email, password: password)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func clearForm() {
        email = ""
        password = ""
        username = ""
        confirmPassword = ""
    }
}

// MARK: - Modern Text Field
struct ModernTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(title)
                .font(DesignSystem.Typography.callout)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            TextField(placeholder, text: $text)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Gradients.surface)
                .cornerRadius(DesignSystem.CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Modern Secure Field
struct ModernSecureField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(title)
                .font(DesignSystem.Typography.callout)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            SecureField(placeholder, text: $text)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Gradients.surface)
                .cornerRadius(DesignSystem.CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

#Preview {
    ModernAuthenticationView()
        .environmentObject(SupabaseService())
} 