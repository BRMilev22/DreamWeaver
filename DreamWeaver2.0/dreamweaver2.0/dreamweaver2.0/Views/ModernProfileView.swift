import SwiftUI

struct ModernProfileView: View {
    @EnvironmentObject var supabaseService: SupabaseService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Header with dismiss button
                VStack(spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Profile")
                                .font(DesignSystem.Typography.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Text("Manage your account and preferences")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        // Dismiss button
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
                .padding(.top, DesignSystem.Spacing.xl)
                
                // User Info Card
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Avatar
                    Circle()
                        .fill(DesignSystem.Gradients.primary)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(String(supabaseService.currentUser?.email.first?.uppercased() ?? "U"))
                                .font(DesignSystem.Typography.title1)
                                .fontWeight(.bold)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        )
                        .glowEffect(color: DesignSystem.Colors.primary)
                    
                    // User Details
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Text(supabaseService.currentUser?.displayName ?? supabaseService.currentUser?.username ?? "User")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text(supabaseService.currentUser?.email ?? "")
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                .padding(DesignSystem.Spacing.xl)
                .background(DesignSystem.Gradients.surface)
                .cornerRadius(DesignSystem.CornerRadius.xl)
                .shadow(
                    color: DesignSystem.Shadows.medium.color,
                    radius: DesignSystem.Shadows.medium.radius,
                    x: DesignSystem.Shadows.medium.x,
                    y: DesignSystem.Shadows.medium.y
                )
                
                // Sign Out Button
                Button(action: {
                    Task {
                        try? await supabaseService.signOut()
                    }
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(DesignSystem.Gradients.accent)
                    .cornerRadius(DesignSystem.CornerRadius.lg)
                    .shadow(
                        color: DesignSystem.Colors.accent.opacity(0.3),
                        radius: 10,
                        x: 0,
                        y: 5
                    )
                }
                
                Spacer()
                
                // Bottom padding for tab bar
                Spacer()
                    .frame(height: 100)
            }
            .padding(.horizontal, DesignSystem.Layout.screenPadding)
        }
        .background(DesignSystem.Gradients.background.ignoresSafeArea())
    }
}

#Preview {
    ModernProfileView()
        .environmentObject(SupabaseService())
} 