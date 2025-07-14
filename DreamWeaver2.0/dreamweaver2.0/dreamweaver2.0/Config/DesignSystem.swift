import SwiftUI

// MARK: - Design System
struct DesignSystem {
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }
    
    // MARK: - Colors (DreamPress.ai Theme)
    struct Colors {
        // Primary Colors - DreamPress.ai Style
        static let primary = Color(red: 0.95, green: 0.35, blue: 0.65) // Pink/Red accent
        static let accent = Color(red: 0.75, green: 0.25, blue: 0.85) // Purple accent
        static let accentDark = Color(red: 0.55, green: 0.15, blue: 0.65) // Darker purple
        static let success = Color(red: 0.2, green: 0.8, blue: 0.4)
        static let warning = Color(red: 1.0, green: 0.8, blue: 0.2)
        static let error = Color(red: 1.0, green: 0.3, blue: 0.3)
        
        // Text Colors
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let textTertiary = Color.white.opacity(0.5)
        static let textOnPrimary = Color.white // Text on primary buttons
        static let textOnSecondary = Color.white.opacity(0.9)
        
        // Surface Colors
        static let surface = Color(red: 0.15, green: 0.15, blue: 0.2)
        static let surfaceSecondary = Color(red: 0.1, green: 0.1, blue: 0.15)
        static let surfaceTertiary = Color(red: 0.05, green: 0.05, blue: 0.1)
        
        // Border Colors
        static let border = Color.white.opacity(0.1)
        static let borderSecondary = Color.white.opacity(0.05)
        
        // Genre Colors
        static let romance = Color(red: 0.9, green: 0.4, blue: 0.6)
        static let fantasy = Color(red: 0.6, green: 0.4, blue: 0.9)
        static let sciFi = Color(red: 0.4, green: 0.6, blue: 0.9)
        static let mystery = Color(red: 0.5, green: 0.5, blue: 0.8)
        static let adventure = Color(red: 0.8, green: 0.6, blue: 0.4)
        static let thriller = Color(red: 0.8, green: 0.4, blue: 0.4)
        static let horror = Color(red: 0.7, green: 0.3, blue: 0.3)
        static let drama = Color(red: 0.6, green: 0.6, blue: 0.6)
        static let comedy = Color(red: 0.9, green: 0.8, blue: 0.4)
        static let historical = Color(red: 0.7, green: 0.6, blue: 0.5)
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title1 = Font.title.weight(.bold)
        static let title2 = Font.title2.weight(.bold)
        static let title3 = Font.title3.weight(.semibold)
        static let headline = Font.headline.weight(.semibold)
        static let subheadline = Font.subheadline.weight(.medium)
        static let body = Font.body
        static let bodyEmphasized = Font.body.weight(.semibold)
        static let callout = Font.callout
        static let caption = Font.caption
        static let caption2 = Font.caption2
        static let footnote = Font.footnote
    }
    
    // MARK: - Gradients - DreamPress.ai Style
    struct Gradients {
        // Main background gradient - Purple to dark
        static let background = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.25, green: 0.15, blue: 0.35), // Purple top
                Color(red: 0.15, green: 0.10, blue: 0.25), // Purple middle
                Color(red: 0.05, green: 0.05, blue: 0.08)  // Dark bottom
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Surface gradient for cards
        static let surface = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.16, green: 0.16, blue: 0.22),
                Color(red: 0.12, green: 0.12, blue: 0.18)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Primary button gradient - Pink/Red
        static let primary = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.98, green: 0.40, blue: 0.60), // Bright pink
                Color(red: 0.92, green: 0.30, blue: 0.70)  // Deeper pink
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Accent gradient - Purple
        static let accent = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.75, green: 0.25, blue: 0.85),
                Color(red: 0.55, green: 0.15, blue: 0.65)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Success gradient
        static let success = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.2, green: 0.8, blue: 0.4),
                Color(red: 0.1, green: 0.6, blue: 0.3)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Card gradient with subtle glow
        static let card = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.18, green: 0.18, blue: 0.24),
                Color(red: 0.14, green: 0.14, blue: 0.20)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let small = ShadowStyle(
            color: Color.black.opacity(0.3),
            radius: 4,
            x: 0,
            y: 2
        )
        
        static let medium = ShadowStyle(
            color: Color.black.opacity(0.4),
            radius: 8,
            x: 0,
            y: 4
        )
        
        static let large = ShadowStyle(
            color: Color.black.opacity(0.5),
            radius: 16,
            x: 0,
            y: 8
        )
        
        static let glow = ShadowStyle(
            color: DesignSystem.Colors.primary.opacity(0.4),
            radius: 12,
            x: 0,
            y: 0
        )
    }
    
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    // MARK: - Animations
    struct Animations {
        static let spring = Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.1)
        static let easeInOut = Animation.easeInOut(duration: 0.3)
        static let easeOut = Animation.easeOut(duration: 0.2)
        static let medium = Animation.easeInOut(duration: 0.4)
        static let smooth = Animation.interpolatingSpring(stiffness: 300, damping: 30)
    }
    
    // MARK: - Layout
    struct Layout {
        static let screenPadding: CGFloat = 20
        static let cardPadding: CGFloat = 16
        static let buttonHeight: CGFloat = 56
        static let smallButtonHeight: CGFloat = 40
        static let iconSize: CGFloat = 24
        static let avatarSize: CGFloat = 40
        static let maxContentWidth: CGFloat = 600
    }
    
    // MARK: - Button Styles
    struct ButtonStyles {
        static let primary = BorderedProminentButtonStyle()
        static let secondary = BorderedButtonStyle()
        static let plain = PlainButtonStyle()
    }
}

// MARK: - View Extensions
extension View {
    func glowEffect(color: Color, radius: CGFloat = 8) -> some View {
        self
            .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: radius * 2, x: 0, y: 0)
    }
    
    func cardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Gradients.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                    )
            )
            .shadow(
                color: DesignSystem.Shadows.medium.color,
                radius: DesignSystem.Shadows.medium.radius,
                x: DesignSystem.Shadows.medium.x,
                y: DesignSystem.Shadows.medium.y
            )
    }
    
    func shimmerEffect() -> some View {
        self
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(45))
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: UUID())
            )
            .clipped()
    }
}

 
 