import SwiftUI

struct ModernTabView: View {
    @StateObject private var supabaseService = SupabaseService()
    @State private var selectedTab = 0
    @State private var newlyCreatedStory: Story? = nil
    
    var body: some View {
        Group {
            if supabaseService.isAuthenticated {
                ZStack {
                    // Background gradient matching DreamPress.ai
                    DesignSystem.Gradients.background
                        .ignoresSafeArea(.all)
                    
                    VStack(spacing: 0) {
                        // Content
                        TabView(selection: $selectedTab) {
                            // Story Tab - Main story creation interface
                            ModernCreateStoryView()
                                .tag(0)
                            
                            // Reading Tab - Stories list
                            ModernReadingView(newlyCreatedStory: $newlyCreatedStory)
                                .tag(1)
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .environmentObject(supabaseService)
                        
                        // Custom Tab Bar with shorter height
                        modernTabBar
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToNewStory"))) { notification in
                    if let story = notification.object as? Story {
                        newlyCreatedStory = story
                        selectedTab = 1 // Navigate to Reading tab
                    }
                }
            } else {
                ModernAuthenticationView()
                    .environmentObject(supabaseService)
            }
        }
    }
    
    private var modernTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabItems.enumerated()), id: \.offset) { index, item in
                tabButton(for: index, item: item)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(tabBarBackground)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.bottom, DesignSystem.Spacing.sm)
    }
    
    private var tabBarBackground: some View {
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
            .fill(DesignSystem.Colors.surfaceSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                    .stroke(DesignSystem.Colors.borderSecondary, lineWidth: 1)
            )
            .shadow(
                color: DesignSystem.Colors.primary.opacity(0.1),
                radius: 12,
                x: 0,
                y: -4
            )
    }
    
    private func tabButton(for index: Int, item: TabItem) -> some View {
        Button(action: {
            selectedTab = index
        }) {
            VStack(spacing: DesignSystem.Spacing.xs) {
                tabButtonIcon(for: index, item: item)
                    .scaleEffect(selectedTab == index ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                
                tabButtonText(for: index, item: item)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private func tabButtonIcon(for index: Int, item: TabItem) -> some View {
        ZStack {
            Circle()
                .fill(selectedTab == index ? 
                     AnyShapeStyle(DesignSystem.Gradients.primary) : 
                     AnyShapeStyle(DesignSystem.Colors.surfaceSecondary))
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(selectedTab == index ? 
                               DesignSystem.Colors.primary : 
                               DesignSystem.Colors.borderSecondary, lineWidth: 2)
                )
                .shadow(
                    color: selectedTab == index ? 
                    DesignSystem.Colors.primary.opacity(0.3) : 
                    Color.clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
            
            Image(systemName: item.icon)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(selectedTab == index ? 
                               DesignSystem.Colors.textOnPrimary : 
                               DesignSystem.Colors.textSecondary)
        }
    }
    
    private func tabButtonText(for index: Int, item: TabItem) -> some View {
        Text(item.title)
            .font(DesignSystem.Typography.caption2)
            .fontWeight(.medium)
            .foregroundColor(selectedTab == index ? 
                           DesignSystem.Colors.textPrimary : 
                           DesignSystem.Colors.textSecondary)
    }
    
    // Updated tabs to match client sketch: Story and Reading
    let tabItems = [
        TabItem(icon: "square.and.pencil", selectedIcon: "square.and.pencil", title: "Story"),
        TabItem(icon: "book", selectedIcon: "book.fill", title: "Reading")
    ]
}

struct TabItem {
    let icon: String
    let selectedIcon: String
    let title: String
}

struct Enhanced3DButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ModernTabView()
} 