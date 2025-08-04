import SwiftUI

struct ModernReadingView: View {
    @EnvironmentObject var supabaseService: SupabaseService
    @Binding var newlyCreatedStory: Story?
    @State private var selectedTab: ReadingTab = .explore
    @State private var searchText = ""
    @State private var showAdultContent = false
    @State private var stories: [Story] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var selectedStory: Story? = nil
    @State private var buttonBounceAnimation = false
    @State private var buttonGlowAnimation = false
    
    enum ReadingTab {
        case explore
        case myStories
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            DesignSystem.Gradients.background
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Top navigation buttons
                topNavigationButtons
                
                // Search and 18+ section
                searchSection
                
                // Stories content
                storiesContent
                
                // Bottom padding for tab bar
                Spacer()
                    .frame(height: 60)
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.top, DesignSystem.Spacing.sm)
        }
        .onAppear {
            loadStories()
            // Start button animations
            buttonBounceAnimation = true
            buttonGlowAnimation = true
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            loadStories()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(item: $selectedStory) { story in
            ChapterView(story: story, chapters: story.chapters ?? [])
                .environmentObject(supabaseService)
        }
        .onChange(of: newlyCreatedStory) { oldValue, newValue in
            if let story = newValue {
                print("📱 Received newly created story: \(story.title)")
                print("📖 Story has \(story.chapters?.count ?? 0) chapters attached")
                
                // Switch to My Stories tab first
                selectedTab = .myStories
                
                // Since the story now comes with chapters attached, we can open it more quickly
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("🎯 Opening newly created story...")
                    selectedStory = story
                    
                    // Clear the newly created story flag
                    newlyCreatedStory = nil
                }
            }
        }
    }
    
    // MARK: - Top Navigation Buttons
    private var topNavigationButtons: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Explore Button
            Button(action: { selectedTab = .explore }) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text("🌟")
                        .font(.headline)
                    Text("Explore")
                        .font(DesignSystem.Typography.headline)
                        .fontWeight(.bold)
                }
                .foregroundColor(
                    selectedTab == .explore ?
                    DesignSystem.Colors.textOnPrimary :
                    DesignSystem.Colors.textSecondary
                )
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                        .fill(
                            selectedTab == .explore ?
                            AnyShapeStyle(DesignSystem.Gradients.primary) :
                            AnyShapeStyle(DesignSystem.Colors.surfaceSecondary)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                                .stroke(
                                    selectedTab == .explore ?
                                    DesignSystem.Colors.primary :
                                    DesignSystem.Colors.borderSecondary,
                                    lineWidth: selectedTab == .explore ? 2 : 1
                                )
                        )
                        .shadow(
                            color: selectedTab == .explore ?
                            DesignSystem.Colors.primary.opacity(0.3) :
                            Color.clear,
                            radius: 12,
                            x: 0,
                            y: 4
                        )
                )
                .scaleEffect(selectedTab == .explore ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
            }
            
            // My Stories Button
            Button(action: { selectedTab = .myStories }) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text("📚")
                        .font(.headline)
                    Text("My Stories")
                        .font(DesignSystem.Typography.headline)
                        .fontWeight(.bold)
                }
                .foregroundColor(
                    selectedTab == .myStories ?
                    DesignSystem.Colors.textOnPrimary :
                    DesignSystem.Colors.textSecondary
                )
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                        .fill(
                            selectedTab == .myStories ?
                            AnyShapeStyle(DesignSystem.Gradients.primary) :
                            AnyShapeStyle(DesignSystem.Colors.surfaceSecondary)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                                .stroke(
                                    selectedTab == .myStories ?
                                    DesignSystem.Colors.primary :
                                    DesignSystem.Colors.borderSecondary,
                                    lineWidth: selectedTab == .myStories ? 2 : 1
                                )
                        )
                        .shadow(
                            color: selectedTab == .myStories ?
                            DesignSystem.Colors.primary.opacity(0.3) :
                            Color.clear,
                            radius: 12,
                            x: 0,
                            y: 4
                        )
                )
                .scaleEffect(selectedTab == .myStories ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
            }
        }
        .padding(.bottom, DesignSystem.Spacing.lg)
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Search Input
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .font(.system(size: 16))
                
                TextField("Search stories...", text: $searchText)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                    .fill(DesignSystem.Colors.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                            .stroke(DesignSystem.Colors.borderSecondary, lineWidth: 1)
                    )
                    .shadow(
                        color: DesignSystem.Colors.textSecondary.opacity(0.05),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
            
            // 18+ Button
            Button(action: { showAdultContent.toggle() }) {
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.caption)
                    Text("18+")
                        .font(DesignSystem.Typography.subheadline)
                        .fontWeight(.bold)
                }
                .foregroundColor(
                    showAdultContent ?
                    DesignSystem.Colors.textOnPrimary :
                    DesignSystem.Colors.textSecondary
                )
                .frame(width: 60, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                        .fill(
                            showAdultContent ?
                            AnyShapeStyle(DesignSystem.Gradients.accent) :
                            AnyShapeStyle(DesignSystem.Colors.surfaceSecondary)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                                .stroke(
                                    showAdultContent ?
                                    DesignSystem.Colors.accent :
                                    DesignSystem.Colors.borderSecondary,
                                    lineWidth: showAdultContent ? 2 : 1
                                )
                        )
                        .shadow(
                            color: showAdultContent ?
                            DesignSystem.Colors.accent.opacity(0.3) :
                            Color.clear,
                            radius: 8,
                            x: 0,
                            y: 2
                        )
                )
                .scaleEffect(showAdultContent ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showAdultContent)
            }
        }
        .padding(.bottom, DesignSystem.Spacing.sm)
    }
    
    // MARK: - Stories Content
    private var storiesContent: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                if isLoading {
                    loadingView
                } else if filteredStories.isEmpty {
                    emptyStateView
                } else {
                    ForEach(filteredStories) { story in
                        ReadingStoryCardView(story: story) {
                            selectedStory = story
                        }
                    }
                }
            }
            .padding(.top, DesignSystem.Spacing.xs)
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primary))
                .scaleEffect(1.5)
            
            Text("Loading stories...")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.xxl)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "book.closed")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Text(selectedTab == .explore ? "No stories to explore" : "No stories created yet")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(selectedTab == .explore ? "Check back later for new stories" : "Create your first story to see it here")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.xxl)
    }
    
    // MARK: - Computed Properties
    private var filteredStories: [Story] {
        var filtered = stories
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { story in
                story.title.localizedCaseInsensitiveContains(searchText) ||
                story.summary?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Filter by adult content
        if showAdultContent {
            // When 18+ is enabled, show only adult content (romance)
            filtered = filtered.filter { story in
                story.genre == .romance // Assuming romance is adult content
            }
        }
        // When 18+ is disabled (default), show all stories including romance
        
        return filtered
    }
    
    // MARK: - Helper Functions
    private func loadStories() {
        isLoading = true
        errorMessage = nil
        
        Task {
                         do {
                 let allStories: [Story]
                 if selectedTab == .explore {
                     allStories = try await supabaseService.getPublishedStories()
                 } else {
                     guard let currentUser = supabaseService.currentUser else { return }
                     allStories = try await supabaseService.getUserStories(userId: currentUser.userId)
                 }
                
                await MainActor.run {
                    self.stories = allStories
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load stories: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Reading Story Card View
struct ReadingStoryCardView: View {
    let story: Story
    let onTap: () -> Void
    @State private var isPressed = false
    @State private var cardButtonBounceAnimation = false
    @State private var cardButtonGlowAnimation = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Image placeholder
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Colors.surfaceSecondary)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "book.closed")
                            .font(.system(size: 24))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(DesignSystem.Colors.borderSecondary, lineWidth: 1)
                    )
                    .shadow(
                        color: DesignSystem.Colors.textSecondary.opacity(0.1),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
                
                // Content
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    // Title
                    Text(story.title)
                        .font(DesignSystem.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Author
                    Text("by User")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    // Description
                    Text(story.summary ?? "No description available")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    // Read Button
                    HStack {
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text("Read")
                                .font(DesignSystem.Typography.caption)
                                .fontWeight(.bold)
                            Image(systemName: "sparkles")
                                .font(.caption2)
                                .rotationEffect(.degrees(cardButtonBounceAnimation ? 360 : 0))
                        }
                        .foregroundColor(DesignSystem.Colors.textOnPrimary)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                                .fill(DesignSystem.Gradients.primary)
                                .shadow(
                                    color: DesignSystem.Colors.primary.opacity(0.4),
                                    radius: 8,
                                    x: 0,
                                    y: 4
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                                        .stroke(
                                            DesignSystem.Colors.primary.opacity(cardButtonGlowAnimation ? 0.8 : 0.3),
                                            lineWidth: cardButtonGlowAnimation ? 2 : 1
                                        )
                                        .blur(radius: cardButtonGlowAnimation ? 2 : 0)
                                )
                        )
                        .scaleEffect(cardButtonBounceAnimation ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: cardButtonBounceAnimation)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: cardButtonGlowAnimation)
                    }
                }
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                    .fill(DesignSystem.Colors.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                            .stroke(DesignSystem.Colors.borderSecondary, lineWidth: 1)
                    )
                    .shadow(
                        color: DesignSystem.Colors.textSecondary.opacity(0.1),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                onTap()
            }
        }
        .onAppear {
            // Start card button animations
            cardButtonBounceAnimation = true
            cardButtonGlowAnimation = true
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var newlyCreatedStory: Story? = nil
    return ModernReadingView(newlyCreatedStory: $newlyCreatedStory)
        .environmentObject(SupabaseService())
} 