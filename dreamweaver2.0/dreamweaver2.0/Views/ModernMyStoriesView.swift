import SwiftUI

struct ModernMyStoriesView: View {
    @EnvironmentObject var supabaseService: SupabaseService
    @State private var stories: [Story] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var selectedStory: Story? = nil
    @State private var showStoryDetail = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("My Stories")
                                    .font(DesignSystem.Typography.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Text("\(stories.count) \(stories.count == 1 ? "story" : "stories")")
                                    .font(DesignSystem.Typography.subheadline)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                Task {
                                    await loadStories()
                                }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 20))
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                            .disabled(isLoading)
                        }
                    }
                    .padding(.top, DesignSystem.Spacing.lg)
                    
                    if isLoading {
                        loadingView()
                    } else if stories.isEmpty {
                        emptyStateView()
                    } else {
                        storiesGridView()
                    }
                    
                    // Bottom padding for tab bar
                    Spacer()
                        .frame(height: 100)
                }
                .padding(.horizontal, DesignSystem.Layout.screenPadding)
            }
            .background(DesignSystem.Gradients.background.ignoresSafeArea())
            .refreshable {
                await loadStories()
            }
            .onAppear {
                if stories.isEmpty {
                    Task {
                        await loadStories()
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(item: $selectedStory) { story in
                StoryDetailView(story: story)
            }
        }
    }
    
    @ViewBuilder
    private func loadingView() -> some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primary))
                .scaleEffect(1.5)
            
            Text("Loading your stories...")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.xxl)
    }
    
    @ViewBuilder
    private func emptyStateView() -> some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            VStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "book.closed")
                    .font(.system(size: 60))
                    .foregroundColor(DesignSystem.Colors.primary)
                    .glowEffect(color: DesignSystem.Colors.primary)
                
                Text("No Stories Yet")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Create your first story using AI and start building your personal collection")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
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
        }
    }
    
    @ViewBuilder
    private func storiesGridView() -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
            GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
        ], spacing: DesignSystem.Spacing.md) {
            ForEach(stories) { story in
                StoryCardView(story: story) {
                    selectedStory = story
                }
            }
        }
    }
    
    private func loadStories() async {
        guard let currentUser = supabaseService.currentUser else { 
            return 
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let userStories = try await supabaseService.getUserStories(userId: currentUser.userId)
            
            await MainActor.run {
                self.stories = userStories
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

// MARK: - Story Card View
struct StoryCardView: View {
    let story: Story
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                // Header with genre
                HStack {
                    Text(story.genre.emoji)
                        .font(.system(size: 24))
                    
                    Spacer()
                    
                    if story.isPublished {
                        Image(systemName: "globe")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.Colors.success)
                    } else {
                        Image(systemName: "lock")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                // Title
                Text(story.title)
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Genre and mood
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(story.genre.displayName)
                        .font(DesignSystem.Typography.caption)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(genreColor(for: story.genre).opacity(0.2))
                        .foregroundColor(genreColor(for: story.genre))
                        .cornerRadius(DesignSystem.CornerRadius.sm)
                    
                    Text(story.mood.displayName)
                        .font(DesignSystem.Typography.caption)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(DesignSystem.Colors.textSecondary.opacity(0.1))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .cornerRadius(DesignSystem.CornerRadius.sm)
                }
                
                Spacer()
                
                // Stats
                HStack {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 12))
                        Text("\(story.totalWordsCount) words")
                            .font(DesignSystem.Typography.caption2)
                    }
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Spacer()
                    
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text("\(story.totalReadingTime) min")
                            .font(DesignSystem.Typography.caption2)
                    }
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                // Creation date
                Text(formatDate(story.createdAt))
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Gradients.surface)
            .cornerRadius(DesignSystem.CornerRadius.lg)
            .shadow(
                color: DesignSystem.Shadows.small.color,
                radius: DesignSystem.Shadows.small.radius,
                x: DesignSystem.Shadows.small.x,
                y: DesignSystem.Shadows.small.y
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func genreColor(for genre: StoryGenre) -> Color {
        switch genre {
        case .romance: return DesignSystem.Colors.romance
        case .fantasy: return DesignSystem.Colors.fantasy
        case .sciFi: return DesignSystem.Colors.sciFi
        case .mystery: return DesignSystem.Colors.mystery
        case .adventure: return DesignSystem.Colors.adventure
        case .thriller: return DesignSystem.Colors.thriller
        case .horror: return DesignSystem.Colors.horror
        case .drama: return DesignSystem.Colors.drama
        case .comedy: return DesignSystem.Colors.comedy
        case .historical: return DesignSystem.Colors.historical
        case .contemporary: return DesignSystem.Colors.primary
        case .paranormal: return DesignSystem.Colors.accent
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Story Detail View
struct StoryDetailView: View {
    let story: Story
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    headerView
                    contentView
                    bottomSpacing
                }
                .padding(.horizontal, DesignSystem.Layout.screenPadding)
            }
            .background(DesignSystem.Gradients.background.ignoresSafeArea())
            .navigationTitle("Story Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ActivityViewController(activityItems: [story.title, shareableStoryContent])
            }
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            genreAndStatusView
            titleView
            statsView
            dateView
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Gradients.surface)
        .cornerRadius(DesignSystem.CornerRadius.xl)
    }
    
    private var genreAndStatusView: some View {
        HStack {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Text(story.genre.emoji)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(story.genre.displayName)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(genreColor(for: story.genre))
                    
                    Text(story.mood.displayName)
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            statusView
        }
    }
    
    private var statusView: some View {
        VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
            if story.isPublished {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "globe")
                        .font(.system(size: 14))
                    Text("Published")
                        .font(DesignSystem.Typography.caption)
                }
                .foregroundColor(DesignSystem.Colors.success)
            } else {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "lock")
                        .font(.system(size: 14))
                    Text("Private")
                        .font(DesignSystem.Typography.caption)
                }
                .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }
    
    private var titleView: some View {
        Text(story.title)
            .font(DesignSystem.Typography.title1)
            .fontWeight(.bold)
            .foregroundColor(DesignSystem.Colors.textPrimary)
            .lineLimit(nil)
    }
    
    private var statsView: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "doc.text")
                    .font(.system(size: 14))
                Text("\(story.totalWordsCount) words")
                    .font(DesignSystem.Typography.subheadline)
            }
            .foregroundColor(DesignSystem.Colors.textSecondary)
            
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                Text("\(story.totalReadingTime) min read")
                    .font(DesignSystem.Typography.subheadline)
            }
            .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Spacer()
        }
    }
    
    private var dateView: some View {
        Text("Created \(formatDate(story.createdAt))")
            .font(DesignSystem.Typography.caption)
            .foregroundColor(DesignSystem.Colors.textTertiary)
    }
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Use the new ChapterView component
            ChapterView(story: story) { chapterNumber in
                // TODO: Implement continue generation functionality
                print("Continue generation for chapter \(chapterNumber)")
            }
        }
    }
    
    private var bottomSpacing: some View {
        Spacer()
            .frame(height: 50)
    }
    
    private var shareableStoryContent: String {
        // Create a shareable version of the story content with all chapters
        let chapters = story.chapters ?? []
        if chapters.isEmpty {
            return "This story is still being written..."
        }
        
        return chapters
            .sorted(by: { $0.chapterNumber < $1.chapterNumber })
            .map { chapter in
                let chapterTitle = chapter.title?.isEmpty == false ? chapter.title! : "Chapter \(chapter.chapterNumber)"
                return "\(chapterTitle)\n\n\(chapter.content)"
            }
            .joined(separator: "\n\n---\n\n")
    }
    

    
    private func genreColor(for genre: StoryGenre) -> Color {
        switch genre {
        case .romance: return DesignSystem.Colors.romance
        case .fantasy: return DesignSystem.Colors.fantasy
        case .sciFi: return DesignSystem.Colors.sciFi
        case .mystery: return DesignSystem.Colors.mystery
        case .adventure: return DesignSystem.Colors.adventure
        case .thriller: return DesignSystem.Colors.thriller
        case .horror: return DesignSystem.Colors.horror
        case .drama: return DesignSystem.Colors.drama
        case .comedy: return DesignSystem.Colors.comedy
        case .historical: return DesignSystem.Colors.historical
        case .contemporary: return DesignSystem.Colors.primary
        case .paranormal: return DesignSystem.Colors.accent
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Share Sheet
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ModernMyStoriesView()
        .environmentObject(SupabaseService())
} 