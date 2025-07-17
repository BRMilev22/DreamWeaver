import SwiftUI

struct ModernCreateStoryView: View {
    @EnvironmentObject var supabaseService: SupabaseService
    @StateObject private var mistralService = MistralService()
    @Environment(\.dismiss) private var dismiss
    
    // State for the main story creation interface
    @State private var prompt = ""
    @State private var selectedCategory: StoryCategory = .novel
    @State private var selectedPOV: POVType = .first
    @State private var showInteractiveFlow = false
    @State private var isGenerating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showProfile = false
    @State private var buttonBounceAnimation = false
    @State private var buttonGlowAnimation = false
    
    // Story categories (removed chat, kept only novel and erotica)
    private let categories: [StoryCategory] = [.novel, .erotica]
    
    // Dynamic placeholder text based on selected category
    private var placeholderText: String {
        switch selectedCategory {
        case .novel:
            return "Describe your novel idea... A young detective discovers a hidden conspiracy that threatens to destroy everything she holds dear."
        case .erotica:
            return "Describe your erotic story... Two strangers meet at a masquerade ball and find themselves drawn into a night of passion and mystery."
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient matching DreamPress.ai
            DesignSystem.Gradients.background
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Top navigation bar
                topNavigationBar
                
                // Main content area
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // Top tabs for Novel/Erotica selection
                    topTabsView
                    
                    // Story description section
                    storyDescriptionView
                    
                    Spacer()
                    
                    // Bottom controls - POV and Start Story buttons in horizontal row
                    bottomControlsView
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.top, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.sm) // Reduced bottom padding
            }
        }
        .sheet(isPresented: $showInteractiveFlow) {
            StoryGenerationFlowView(
                initialPrompt: prompt,
                storyParameters: createStoryParameters()
            )
        }
        .sheet(isPresented: $showProfile) {
            ModernProfileView()
                .environmentObject(supabaseService)
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            // Start button animations
            buttonBounceAnimation = true
            buttonGlowAnimation = true
        }
    }
    
    // MARK: - Top Navigation Bar
    private var topNavigationBar: some View {
        HStack {
            Button(action: { showProfile = true }) {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            Text("DreamWeaver")
                .font(DesignSystem.Typography.title2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.top, DesignSystem.Spacing.sm)
    }
    
    // MARK: - Top Tabs (Novel, Erotica with custom images)
    private var topTabsView: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            ForEach(categories, id: \.self) { category in
                Button(action: { selectedCategory = category }) {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        // Use custom PNG images - sized to fit on one line
                        Image(category.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                        
                        Text(category.rawValue)
                            .font(DesignSystem.Typography.title3)
                            .fontWeight(.bold)
                            .foregroundColor(
                                selectedCategory == category ?
                                DesignSystem.Colors.textOnPrimary :
                                DesignSystem.Colors.textSecondary
                            )
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                            .fill(
                                selectedCategory == category ?
                                AnyShapeStyle(DesignSystem.Gradients.surface) :
                                AnyShapeStyle(DesignSystem.Colors.surfaceSecondary)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                                    .stroke(
                                        selectedCategory == category ?
                                        DesignSystem.Colors.border :
                                        DesignSystem.Colors.borderSecondary,
                                        lineWidth: 2
                                    )
                            )
                            .shadow(
                                color: selectedCategory == category ?
                                DesignSystem.Colors.primary.opacity(0.3) :
                                Color.clear,
                                radius: 12,
                                x: 0,
                                y: 4
                            )
                    )
                    .scaleEffect(selectedCategory == category ? 1.08 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedCategory)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
    }
    
    // MARK: - Story Description Section
    private var storyDescriptionView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Briefly describe your story")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.leading)
            
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.surfaceSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .stroke(DesignSystem.Colors.borderSecondary, lineWidth: 1)
                )
                .overlay(
                    TextField("", text: $prompt, prompt: Text(placeholderText).foregroundColor(DesignSystem.Colors.textTertiary), axis: .vertical)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.top, 32)
                        .padding(.bottom, DesignSystem.Spacing.sm)
                        .lineLimit(8...15)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                )
                .clipped()
            .frame(height: 160)
        }
    }
    
    // MARK: - Bottom Controls (POV and Start Story in horizontal row)
    private var bottomControlsView: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // POV Selection Buttons - Horizontal Layout
            HStack(spacing: DesignSystem.Spacing.xs) {
                // 1st POV Button
                Button(action: { selectedPOV = .first }) {
                    HStack(spacing: 4) {
                        Text("👤")
                            .font(.caption)
                        Text("1st")
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(
                        selectedPOV == .first ?
                        DesignSystem.Colors.textOnPrimary :
                        DesignSystem.Colors.textSecondary
                    )
                    .frame(minWidth: 40)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .fill(
                                selectedPOV == .first ?
                                AnyShapeStyle(DesignSystem.Gradients.primary) :
                                AnyShapeStyle(DesignSystem.Colors.surfaceSecondary)
                            )
                            .shadow(
                                color: selectedPOV == .first ?
                                DesignSystem.Colors.primary.opacity(0.3) :
                                Color.clear,
                                radius: 4,
                                x: 0,
                                y: 1
                            )
                    )
                    .scaleEffect(selectedPOV == .first ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedPOV)
                }
                
                // 3rd POV Button
                Button(action: { selectedPOV = .third }) {
                    HStack(spacing: 4) {
                        Text("👥")
                            .font(.caption)
                        Text("3rd")
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(
                        selectedPOV == .third ?
                        DesignSystem.Colors.textOnPrimary :
                        DesignSystem.Colors.textSecondary
                    )
                    .frame(minWidth: 40)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .fill(
                                selectedPOV == .third ?
                                AnyShapeStyle(DesignSystem.Gradients.primary) :
                                AnyShapeStyle(DesignSystem.Colors.surfaceSecondary)
                            )
                            .shadow(
                                color: selectedPOV == .third ?
                                DesignSystem.Colors.primary.opacity(0.3) :
                                Color.clear,
                                radius: 4,
                                x: 0,
                                y: 1
                            )
                    )
                    .scaleEffect(selectedPOV == .third ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedPOV)
                }
            }
            
            Spacer()
            
            // Start Story Button
            Button(action: { showInteractiveFlow = true }) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text("Start my story free")
                        .font(DesignSystem.Typography.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textOnPrimary)
                    
                    Image(systemName: "sparkles")
                        .font(.callout)
                        .foregroundColor(DesignSystem.Colors.textOnPrimary)
                        .rotationEffect(.degrees(buttonBounceAnimation ? 360 : 0))
                }
                .frame(minWidth: 130) // Set minimum width for wider button
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                        .fill(DesignSystem.Gradients.primary)
                        .shadow(
                            color: DesignSystem.Colors.primary.opacity(0.4),
                            radius: 16,
                            x: 0,
                            y: 8
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                                .stroke(
                                    DesignSystem.Colors.primary.opacity(buttonGlowAnimation ? 0.8 : 0.3),
                                    lineWidth: buttonGlowAnimation ? 3 : 1
                                )
                                .blur(radius: buttonGlowAnimation ? 6 : 0)
                        )
                )
                .scaleEffect(isGenerating ? 0.95 : (buttonBounceAnimation ? 1.1 : 1.0))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isGenerating)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: buttonBounceAnimation)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: buttonGlowAnimation)
            }
            .disabled(isGenerating || prompt.isEmpty)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.bottom, DesignSystem.Spacing.xs) // Minimal bottom padding
    }
    
    // MARK: - Helper Functions
    private func createStoryParameters() -> StoryGenerationParameters {
        let genre = mapCategoryToGenre(selectedCategory)
        let pointOfView = mapPOVToPointOfView(selectedPOV)
        
        return StoryGenerationParameters(
            genre: genre,
            mood: .mysterious,
            length: .medium,
            characters: nil,
            setting: nil,
            themes: nil,
            style: .descriptive,
            temperature: 0.7,
            maxTokens: nil,
            pointOfView: pointOfView
        )
    }
    
    private func mapCategoryToGenre(_ category: StoryCategory) -> StoryGenre {
        switch category {
        case .novel:
            return .mystery
        case .erotica:
            return .romance
        }
    }
    
    private func mapPOVToPointOfView(_ pov: POVType) -> PointOfView {
        switch pov {
        case .first:
            return .first
        case .third:
            return .third
        }
    }
}

// MARK: - Supporting Types
enum StoryCategory: String, CaseIterable {
    case novel = "Novel"
    case erotica = "Erotic"
    
    var imageName: String {
        switch self {
        case .novel: return "book"
        case .erotica: return "fire"
        }
    }
}

enum POVType: String, CaseIterable {
    case first = "1st"
    case third = "3rd"
}

// MARK: - Preview
#Preview {
    ModernCreateStoryView()
        .environmentObject(SupabaseService())
} 