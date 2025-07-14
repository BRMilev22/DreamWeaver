import SwiftUI

// MARK: - Chapter Generation Modal
struct ChapterGenerationModal: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var mistralService = MistralService()
    @EnvironmentObject var supabaseService: SupabaseService
    
    let story: Story
    let chapters: [Chapter]
    let suggestion: String
    let onChapterSaved: (Chapter) -> Void
    
    @State private var isGenerating = false
    @State private var generatedContent: String?
    @State private var generationError: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Gradients.background
                    .ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.xl) {
                    if isGenerating {
                        generationLoadingView
                    } else if let content = generatedContent {
                        generatedChapterPreviewView(content: content)
                    } else {
                        initialView
                    }
                }
                .padding(DesignSystem.Spacing.lg)
            }
            .navigationTitle("Generate Chapter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            startGeneration()
        }
        .alert("Generation Error", isPresented: $showingError) {
            Button("Retry") {
                startGeneration()
            }
            Button("Cancel") {
                dismiss()
            }
        } message: {
            Text(generationError ?? "Unknown error occurred")
        }
    }
    
    private var initialView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            VStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Text("Generating Chapter \(chapters.count + 1)")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Based on: \"\(suggestion)\"")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.md)
            }
            
            Button("Start Generation") {
                startGeneration()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(DesignSystem.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .fill(DesignSystem.Gradients.card)
                .shadow(color: DesignSystem.Colors.primary.opacity(0.2), radius: 15, x: 0, y: 8)
        )
    }
    
    private var generationLoadingView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Animated progress indicator
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [DesignSystem.Colors.primary, DesignSystem.Colors.accent]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isGenerating)
            }
            
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("✨ Weaving your story...")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Text("Creating Chapter \(chapters.count + 1) with your chosen direction")
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                
                Text("\"\(suggestion)\"")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .italic()
            }
            
            // Progress dots
            HStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isGenerating ? 1.0 : 0.5)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(Double(index) * 0.2), value: isGenerating)
                }
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .fill(DesignSystem.Gradients.card)
                .shadow(color: DesignSystem.Colors.primary.opacity(0.2), radius: 15, x: 0, y: 8)
        )
    }
    
    private func generatedChapterPreviewView(content: String) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Header
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Chapter \(chapters.count + 1) Preview")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Text("Review your generated chapter")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            // Content Preview
            ScrollView {
                Text(content)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineSpacing(6)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxHeight: 300)
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(DesignSystem.Colors.textTertiary.opacity(0.2), lineWidth: 1)
                    )
            )
            
            // Action buttons
            HStack(spacing: DesignSystem.Spacing.md) {
                Button(action: {
                    regenerateChapter()
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                        Text("Generate Another")
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .fill(DesignSystem.Colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                    .stroke(DesignSystem.Colors.textTertiary.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    saveChapter(content: content)
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .medium))
                        Text("Save Chapter")
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [DesignSystem.Colors.primary, DesignSystem.Colors.accentDark]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .fill(DesignSystem.Gradients.card)
                .shadow(color: DesignSystem.Colors.primary.opacity(0.2), radius: 15, x: 0, y: 8)
        )
    }
    
    private func startGeneration() {
        isGenerating = true
        generatedContent = nil
        generationError = nil
        
        Task {
            await generateChapter()
        }
    }
    
    private func regenerateChapter() {
        generatedContent = nil
        startGeneration()
    }
    
    @MainActor
    private func generateChapter() async {
        do {
            let nextChapterNumber = (chapters.map { $0.chapterNumber }.max() ?? 0) + 1
            let context = mistralService.createContextFromChapters(chapters)
            
            let prompt = "Based on the suggestion: \"\(suggestion)\", continue the story naturally, advancing the plot and developing the characters further."
            
            guard let storyParameters = story.generationParameters else {
                throw NSError(domain: "ChapterGenerationModal", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Story generation parameters not found"
                ])
            }
            
            let parameters = ChapterGenerationParameters(
                storyId: story.id,
                chapterNumber: nextChapterNumber,
                userPrompt: prompt,
                previousChaptersContext: context,
                originalStoryParameters: storyParameters,
                targetWordCount: 1200
            )
            
            let newChapterContent = try await mistralService.generateNextChapter(parameters: parameters)
            
            generatedContent = newChapterContent
            isGenerating = false
            
        } catch {
            generationError = error.localizedDescription
            showingError = true
            isGenerating = false
        }
    }
    
    private func saveChapter(content: String) {
        Task {
            await saveChapterToDatabase(content: content)
        }
    }
    
    @MainActor
    private func saveChapterToDatabase(content: String) async {
        do {
            let nextChapterNumber = (chapters.map { $0.chapterNumber }.max() ?? 0) + 1
            let context = mistralService.createContextFromChapters(chapters)
            
            let wordCount = content.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .count
            let readingTime = max(1, wordCount / 200)
            
            let newChapter = Chapter(
                storyId: story.id,
                chapterNumber: nextChapterNumber,
                title: "Chapter \(nextChapterNumber)",
                content: content,
                wordsCount: wordCount,
                readingTime: readingTime,
                generationPrompt: suggestion,
                contextFromPreviousChapters: context
            )
            
            let savedChapter = try await supabaseService.createChapter(newChapter)
            
            onChapterSaved(savedChapter)
            dismiss()
            
        } catch {
            generationError = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.callout)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [DesignSystem.Colors.primary, DesignSystem.Colors.accentDark]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(DesignSystem.CornerRadius.md)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Chapter View Component
struct ChapterView: View {
    @EnvironmentObject var supabaseService: SupabaseService
    @StateObject private var mistralService = MistralService()
    @State private var chapters: [Chapter]
    @State private var sortedChapters: [Chapter]
    @State private var currentChapterIndex: Int = 0
    @State private var isChapterExpanded: Bool = false
    @State private var isGeneratingChapter = false
    @State private var generationError: String?
    @State private var showingGenerationError = false
    @State private var customChapterIdea = ""
    @State private var selectedSuggestion: String?
    
    let story: Story
    let onContinueGeneration: ((Int) -> Void)?
    
    // Dynamic chapter continuation suggestions
    @State private var suggestions: [String] = []
    @State private var isLoadingSuggestions = false
    @State private var suggestionsGenerationInProgress = false
    @State private var suggestionsTask: Task<Void, Never>?
    @State private var chapterGenerationTask: Task<Void, Never>?
    
    // New chapter generation flow states
    @State private var selectedSuggestionForGeneration: String?
    @State private var showingGenerationModal = false
    
    init(story: Story, onContinueGeneration: ((Int) -> Void)? = nil) {
        self.story = story
        self.onContinueGeneration = onContinueGeneration
        let chapters = story.chapters ?? []
        self._chapters = State(initialValue: chapters)
        self._sortedChapters = State(initialValue: chapters.sorted(by: { $0.chapterNumber < $1.chapterNumber }))
    }
    
    var currentChapter: Chapter? {
        guard currentChapterIndex < sortedChapters.count else { return nil }
        return sortedChapters[currentChapterIndex]
    }
    
    var isLastChapter: Bool {
        return currentChapterIndex == sortedChapters.count - 1
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Story Title Card
                storyTitleCard
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                
                // Current Chapter Card
                chapterCard
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                
                // Show continuation options only for the last chapter
                if isLastChapter {
                    // How should the story continue text
                    continuePromptText
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                    
                    // Suggested Chapter Continuations
                    suggestedContinuationsSection
                    
                    // Generate Chapter Button (shows after suggestion selection)
                    if selectedSuggestionForGeneration != nil {
                        generateChapterButton
                            .padding(.horizontal, DesignSystem.Spacing.sm)
                    }
                    
                    // Or separator
                    orSeparator
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                    
                    // Custom Idea Input
                    customIdeaSection
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                }
                
                // Bottom Navigation Buttons
                bottomNavigationButtons
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                
                // Bottom spacing
                Spacer()
                    .frame(height: 100)
            }
            .padding(.top, DesignSystem.Spacing.xl)
        }
        .background(Color.clear)
        .sheet(isPresented: $showingGenerationModal) {
            if let suggestion = selectedSuggestionForGeneration {
                ChapterGenerationModal(
                    story: story,
                    chapters: chapters,
                    suggestion: suggestion,
                    onChapterSaved: { newChapter in
                        handleNewChapterSaved(newChapter)
                    }
                )
                .environmentObject(supabaseService)
            }
        }
        .alert("Generation Error", isPresented: $showingGenerationError) {
            Button("OK") { }
        } message: {
            Text(generationError ?? "Unknown error occurred")
        }
    }
    
    private func handleNewChapterSaved(_ newChapter: Chapter) {
        chapters.append(newChapter)
        sortedChapters = chapters.sorted(by: { $0.chapterNumber < $1.chapterNumber })
        
        // Navigate to the new chapter
        withAnimation(.spring()) {
            currentChapterIndex = sortedChapters.count - 1
            isChapterExpanded = true
        }
        
        // Reset generation states
        selectedSuggestionForGeneration = nil
        selectedSuggestion = nil
        suggestions = []
        
        onContinueGeneration?(newChapter.chapterNumber)
    }
    
    // MARK: - Story Title Card
    private var storyTitleCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(story.title)
                .font(DesignSystem.Typography.title1)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("by: You")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .fill(DesignSystem.Gradients.card)
                .shadow(color: DesignSystem.Colors.primary.opacity(0.2), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Chapter Card
    private var chapterCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Chapter Header
            HStack {
                Text("CHAPTER \(currentChapter?.chapterNumber ?? 1)")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Spacer()
                
                Button(action: {
                    isChapterExpanded.toggle()
                }) {
                    Image(systemName: isChapterExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            
            // Chapter Content (expandable)
            if isChapterExpanded {
                Text(currentChapter?.content ?? "Chapter content not available")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineSpacing(6)
                    .multilineTextAlignment(.leading)
                
                // Chapter stats
                HStack {
                    Text("\(currentChapter?.wordsCount ?? 0) words")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(currentChapter?.readingTime ?? 0) min read")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding(.top, DesignSystem.Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .fill(DesignSystem.Gradients.card)
                .shadow(color: DesignSystem.Colors.primary.opacity(0.2), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Continue Prompt Text
    private var continuePromptText: some View {
        Text("How should the story continue?")
            .font(DesignSystem.Typography.title2)
            .fontWeight(.semibold)
            .foregroundColor(DesignSystem.Colors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(DesignSystem.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                    .fill(DesignSystem.Gradients.card)
                    .shadow(color: DesignSystem.Colors.primary.opacity(0.2), radius: 15, x: 0, y: 8)
            )
    }
    
    // MARK: - Suggested Continuations Section
    private var suggestedContinuationsSection: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    if isLoadingSuggestions {
                        // Show loading cards while generating suggestions
                        ForEach(0..<3, id: \.self) { _ in
                            loadingSuggestionCard()
                        }
                        .padding(.horizontal, max(DesignSystem.Spacing.sm, (geometry.size.width - 320) / 2))
                    } else if suggestions.isEmpty {
                        // Show placeholder if no suggestions generated yet
                        ForEach(0..<3, id: \.self) { _ in
                            placeholderSuggestionCard()
                        }
                        .padding(.horizontal, max(DesignSystem.Spacing.sm, (geometry.size.width - 320) / 2))
                    } else {
                        // Show actual suggestions
                        ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                            suggestionCard(suggestion: suggestion, index: index)
                        }
                        .padding(.horizontal, max(DesignSystem.Spacing.sm, (geometry.size.width - 320) / 2))
                    }
                }
            }
        }
        .frame(height: 140)
        .onAppear {
            if isLastChapter && suggestions.isEmpty && !suggestionsGenerationInProgress {
                suggestionsTask?.cancel()
                suggestionsTask = Task {
                    await generateContextualSuggestions()
                }
            }
        }
        .onDisappear {
            // Cancel any ongoing tasks to prevent memory leaks
            suggestionsTask?.cancel()
            chapterGenerationTask?.cancel()
            
            // Reset new chapter generation states
            selectedSuggestionForGeneration = nil
            showingGenerationModal = false
        }
    }
    
    private func suggestionCard(suggestion: String, index: Int) -> some View {
        Button(action: {
            selectedSuggestion = suggestion
            selectedSuggestionForGeneration = suggestion
        }) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(suggestion)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                Image(systemName: "arrow.right.circle")
                    .font(.system(size: 20))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            .frame(width: 320)
            .frame(minHeight: 120)
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Gradients.card)
                    .shadow(color: DesignSystem.Colors.primary.opacity(0.2), radius: 15, x: 0, y: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(
                                selectedSuggestionForGeneration == suggestion ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary.opacity(0.3),
                                lineWidth: selectedSuggestionForGeneration == suggestion ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(selectedSuggestionForGeneration == suggestion ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: selectedSuggestionForGeneration)
    }
    
    private func loadingSuggestionCard() -> some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primary))
                .scaleEffect(0.8)
            
            Text("Generating ideas...")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 320)
        .frame(minHeight: 120)
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Gradients.card)
                .shadow(color: DesignSystem.Colors.primary.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
    
    private func placeholderSuggestionCard() -> some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "lightbulb")
                .font(.system(size: 24))
                .foregroundColor(DesignSystem.Colors.textTertiary)
            
            Text("Tap to generate ideas")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 320)
        .frame(minHeight: 120)
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Gradients.card.opacity(0.5))
                .shadow(color: DesignSystem.Colors.primary.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .onTapGesture {
            suggestionsTask?.cancel()
            suggestionsTask = Task {
                await generateContextualSuggestions()
            }
        }
    }
    
    // MARK: - Or Separator
    private var orSeparator: some View {
        HStack {
            Rectangle()
                .fill(DesignSystem.Colors.textTertiary.opacity(0.3))
                .frame(height: 1)
            
            Text("or")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .padding(.horizontal, DesignSystem.Spacing.md)
            
            Rectangle()
                .fill(DesignSystem.Colors.textTertiary.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.vertical, DesignSystem.Spacing.lg)
    }
    
    // MARK: - Custom Idea Section
    private var customIdeaSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            TextEditor(text: $customChapterIdea)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .background(DesignSystem.Colors.surface)
                .cornerRadius(DesignSystem.CornerRadius.md)
                .frame(minHeight: 100)
            
            Button(action: {
                selectedSuggestionForGeneration = customChapterIdea
                showingGenerationModal = true
                customChapterIdea = ""
            }) {
                Text("Generate with Custom Idea")
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [DesignSystem.Colors.primary, DesignSystem.Colors.accentDark]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(DesignSystem.CornerRadius.lg)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(customChapterIdea.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(customChapterIdea.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .fill(DesignSystem.Gradients.card)
                .shadow(color: DesignSystem.Colors.primary.opacity(0.2), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Bottom Navigation Buttons
    private var bottomNavigationButtons: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Post Button
            Button(action: {
                // TODO: Implement post functionality
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Post")
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .fill(DesignSystem.Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                                .stroke(DesignSystem.Colors.textTertiary.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Heart Button
            Button(action: {
                // TODO: Implement voice functionality
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "heart")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Voice")
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .fill(DesignSystem.Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                                .stroke(DesignSystem.Colors.textTertiary.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Next Chapter Button
            Button(action: {
                navigateToNextChapter()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Next Chapter")
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [DesignSystem.Colors.primary, DesignSystem.Colors.accentDark]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(DesignSystem.CornerRadius.lg)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isLastChapter)
            .opacity(isLastChapter ? 0.6 : 1.0)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .fill(DesignSystem.Gradients.card)
                .shadow(color: DesignSystem.Colors.primary.opacity(0.2), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Generate Chapter Button
    private var generateChapterButton: some View {
        Button(action: {
            showingGenerationModal = true
        }) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 18, weight: .medium))
                
                Text("Generate Chapter")
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.bold)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [DesignSystem.Colors.primary, DesignSystem.Colors.accentDark]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(DesignSystem.CornerRadius.lg)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(0.98)
        .animation(.spring(response: 0.3), value: selectedSuggestionForGeneration)
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .fill(DesignSystem.Gradients.card)
                .shadow(color: DesignSystem.Colors.primary.opacity(0.2), radius: 15, x: 0, y: 8)
        )
    }
    

    

    
    // MARK: - Generation Loading View (Legacy)
    private var generationLoadingView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primary))
                .scaleEffect(1.2)
            
            Text("Generating next chapter...")
                .font(DesignSystem.Typography.body)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .fill(DesignSystem.Gradients.card)
                .shadow(color: DesignSystem.Colors.primary.opacity(0.2), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Generation Functions
    
    private func navigateToNextChapter() {
        if currentChapterIndex < sortedChapters.count - 1 {
            // Cancel any ongoing tasks before navigation
            suggestionsTask?.cancel()
            chapterGenerationTask?.cancel()
            
            withAnimation(.spring()) {
                currentChapterIndex += 1
                isChapterExpanded = false
                
                // Clear suggestions when navigating
                suggestions = []
                selectedSuggestion = nil
                suggestionsGenerationInProgress = false
                
                // Reset new chapter generation states
                selectedSuggestionForGeneration = nil
                showingGenerationModal = false
            }
            
            // Suggestions will be generated by onAppear when the view updates
        }
    }
    
    // MARK: - Suggestion Generation
    
    @MainActor
    private func generateContextualSuggestions() async {
        guard isLastChapter && suggestions.isEmpty && !isLoadingSuggestions && !isGeneratingChapter && !suggestionsGenerationInProgress else { return }
        
        suggestionsGenerationInProgress = true
        isLoadingSuggestions = true
        
        defer {
            isLoadingSuggestions = false
            suggestionsGenerationInProgress = false
        }
        
        // Check for task cancellation
        guard !Task.isCancelled else {
            print("Suggestions generation task was cancelled")
            return
        }
        
        do {
            let context = mistralService.createContextFromChapters(sortedChapters)
            
            guard let storyParameters = story.generationParameters else {
                print("Story generation parameters not found")
                return
            }
            
            // Check for cancellation again before making API call
            guard !Task.isCancelled else {
                print("Suggestions generation task was cancelled before API call")
                return
            }
            
            let suggestionsArray = try await mistralService.generateChapterSuggestions(
                context: context,
                storyParameters: storyParameters
            )
            
            // Check for cancellation before updating state
            guard !Task.isCancelled else {
                print("Suggestions generation task was cancelled after API call")
                return
            }
            
            suggestions = suggestionsArray
            
            // Fallback if we didn't get 3 suggestions
            if suggestions.count < 3 {
                suggestions = [
                    "A mysterious character reveals a crucial secret",
                    "An unexpected challenge threatens the protagonist", 
                    "A surprising discovery changes everything"
                ]
            }
            
        } catch {
            // Only log error if task wasn't cancelled
            if !Task.isCancelled {
                print("Error generating suggestions: \(error)")
                suggestions = [
                    "A mysterious character reveals a crucial secret",
                    "An unexpected challenge threatens the protagonist",
                    "A surprising discovery changes everything"
                ]
            }
        }
    }
    
    @MainActor
    private func generateNextChapter(customIdea: String?) async {
        isGeneratingChapter = true
        generationError = nil
        selectedSuggestion = nil
        
        // Check for task cancellation at the start
        guard !Task.isCancelled else {
            print("Chapter generation task was cancelled")
            isGeneratingChapter = false
            return
        }
        
        do {
            let nextChapterNumber = (chapters.map { $0.chapterNumber }.max() ?? 0) + 1
            let context = mistralService.createContextFromChapters(chapters)
            
            let prompt = customIdea ?? "Continue the story naturally, advancing the plot and developing the characters further."
            
            guard let storyParameters = story.generationParameters else {
                throw NSError(domain: "ChapterView", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Story generation parameters not found"
                ])
            }
            
            let parameters = ChapterGenerationParameters(
                storyId: story.id,
                chapterNumber: nextChapterNumber,
                userPrompt: prompt,
                previousChaptersContext: context,
                originalStoryParameters: storyParameters,
                targetWordCount: 1200
            )
            
            let newChapterContent = try await mistralService.generateNextChapter(parameters: parameters)
            
            // Check for cancellation after API call
            guard !Task.isCancelled else {
                print("Chapter generation task was cancelled after API call")
                isGeneratingChapter = false
                return
            }
            
            let wordCount = newChapterContent.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .count
            let readingTime = max(1, wordCount / 200)
            
            let newChapter = Chapter(
                storyId: story.id,
                chapterNumber: nextChapterNumber,
                title: "Chapter \(nextChapterNumber)",
                content: newChapterContent,
                wordsCount: wordCount,
                readingTime: readingTime,
                generationPrompt: prompt,
                contextFromPreviousChapters: context
            )
            
            let savedChapter = try await supabaseService.createChapter(newChapter)
            
            // Check for cancellation before updating state
            guard !Task.isCancelled else {
                print("Chapter generation task was cancelled before state update")
                isGeneratingChapter = false
                return
            }
            
            chapters.append(savedChapter)
            sortedChapters = chapters.sorted(by: { $0.chapterNumber < $1.chapterNumber })
            
            // Navigate to the new chapter
            withAnimation(.spring()) {
                currentChapterIndex = sortedChapters.count - 1
                isChapterExpanded = true
            }
            
            onContinueGeneration?(nextChapterNumber)
            
            // Clear suggestions so they get regenerated with new context
            suggestions = []
            selectedSuggestion = nil
            
        } catch {
            // Only show error if task wasn't cancelled
            if !Task.isCancelled {
                generationError = error.localizedDescription
                showingGenerationError = true
            } else {
                print("Chapter generation task was cancelled")
            }
        }
        
        isGeneratingChapter = false
    }
    

    

}

// MARK: - Chapter Card View
struct ChapterCardView: View {
    let chapter: Chapter
    let isExpanded: Bool
    let isLastChapter: Bool
    let isGenerating: Bool
    let onToggle: () -> Void
    let onContinueGeneration: ((Int) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Chapter Header
            chapterHeader
            
            // Chapter Content (expandable)
            if isExpanded {
                chapterContent
                
                // Continue Generation Button (only for last chapter)
                if isLastChapter && onContinueGeneration != nil {
                    continueGenerationButton
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .fill(DesignSystem.Gradients.card)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                        .stroke(
                            isExpanded ? DesignSystem.Colors.primary.opacity(0.3) : DesignSystem.Colors.surfaceSecondary.opacity(0.3),
                            lineWidth: isExpanded ? 2 : 1
                        )
                )
                .shadow(
                    color: isExpanded ? DesignSystem.Colors.primary.opacity(0.1) : Color.black.opacity(0.05),
                    radius: isExpanded ? 15 : 8,
                    x: 0,
                    y: isExpanded ? 8 : 4
                )
        )
        .scaleEffect(isExpanded ? 1.02 : 1.0)
        .animation(DesignSystem.Animations.spring, value: isExpanded)
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }
    
    // MARK: - Chapter Header
    private var chapterHeader: some View {
        Button(action: onToggle) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Chapter number badge
                ZStack {
                    Circle()
                        .fill(DesignSystem.Gradients.accent)
                        .frame(width: 36, height: 36)
                        .glowEffect(color: DesignSystem.Colors.primary, radius: isExpanded ? 5 : 2)
                    
                    Text("\(chapter.chapterNumber)")
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    // Chapter Title
                    HStack {
                        Text("Chapter \(chapter.chapterNumber)")
                            .font(DesignSystem.Typography.headline)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if let title = chapter.title, !title.isEmpty {
                            Text("•")
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .font(DesignSystem.Typography.caption)
                            Text(title)
                                .font(DesignSystem.Typography.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    
                    // Chapter Stats
                    HStack(spacing: DesignSystem.Spacing.md) {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "doc.richtext")
                                .font(.system(size: 12, weight: .medium))
                            Text("\(chapter.wordsCount) words")
                                .font(DesignSystem.Typography.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12, weight: .medium))
                            Text("\(chapter.readingTime) min")
                                .font(DesignSystem.Typography.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                }
                
                Spacer()
                
                // Expand/Collapse Icon
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.surface)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .animation(DesignSystem.Animations.spring, value: isExpanded)
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Chapter Content
    private var chapterContent: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Gradient divider
            Rectangle()
                .fill(DesignSystem.Gradients.primary)
                .frame(height: 2)
                .cornerRadius(1)
                .padding(.horizontal, DesignSystem.Spacing.lg)
            
            // Chapter Text
            Text(chapter.content)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineSpacing(8)
                .lineLimit(nil)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.bottom, DesignSystem.Spacing.lg)
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.95)),
            removal: .opacity.combined(with: .move(edge: .top))
        ))
    }
    
    // MARK: - Continue Generation Button
    private var continueGenerationButton: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Gradient divider
            Rectangle()
                .fill(DesignSystem.Gradients.primary)
                .frame(height: 2)
                .cornerRadius(1)
                .padding(.horizontal, DesignSystem.Spacing.lg)
            
            Button(action: {
                onContinueGeneration?(chapter.chapterNumber + 1)
            }) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                    }
                    
                    Text(isGenerating ? "Generating..." : "Continue Story")
                        .font(DesignSystem.Typography.callout)
                        .fontWeight(.bold)
                    
                    if !isGenerating {
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(DesignSystem.Gradients.primary)
                .cornerRadius(DesignSystem.CornerRadius.lg)
                .glowEffect(color: DesignSystem.Colors.accent, radius: 8)
            }
            .disabled(isGenerating)
            .scaleEffect(isGenerating ? 0.95 : 0.98)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.lg)
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .bottom)).combined(with: .scale(scale: 0.9)),
            removal: .opacity.combined(with: .move(edge: .bottom))
        ))
    }
}

// MARK: - Preview
#Preview {
    let sampleChapters = [
        Chapter(
            id: UUID(),
            storyId: UUID(),
            chapterNumber: 1,
            title: "The Beginning",
            content: "Once upon a time, in a land far away, there lived a young adventurer named Alex. The morning sun cast long shadows across the village square as Alex prepared for the journey that would change everything. The ancient map, passed down through generations, finally revealed its secrets.\n\nThe cobblestones felt cool beneath Alex's feet as dawn broke over the horizon. Birds chirped their morning songs, unaware of the epic adventure that was about to unfold. With a deep breath and a heart full of courage, Alex stepped forward into destiny.",
            wordsCount: 85,
            readingTime: 3,
            generationPrompt: "Start an adventure story",
            contextFromPreviousChapters: nil,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Chapter(
            id: UUID(),
            storyId: UUID(),
            chapterNumber: 2,
            title: "Into the Unknown",
            content: "The forest was darker than Alex had imagined. Every step forward seemed to echo with the whispers of ancient spirits. The path, marked by strange symbols carved into tree trunks, led deeper into the unknown. Alex's heart pounded with both fear and excitement.\n\nMystical creatures watched from the shadows, their eyes glowing like emeralds in the dim light. The ancient map trembled in Alex's hands, as if responding to some unseen magical force that permeated the very air.",
            wordsCount: 72,
            readingTime: 2,
            generationPrompt: "Continue the adventure",
            contextFromPreviousChapters: "Alex is starting a journey with an ancient map",
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
    
    let sampleStory = Story(
        id: UUID(),
        userId: UUID(),
        title: "The Ancient Map",
        summary: "A young adventurer discovers an ancient map that leads to a mysterious quest.",
        genre: .adventure,
        mood: .mysterious,
        isPublished: false,
        isPremium: false,
        likesCount: 0,
        viewsCount: 0,
        totalWordsCount: 157,
        totalReadingTime: 5,
        chaptersCount: 2,
        createdAt: Date(),
        updatedAt: Date(),
        publishedAt: nil,
        generationPrompt: "Create an adventure story",
        generationParameters: nil,
        chapters: sampleChapters
    )
    
    ZStack {
        DesignSystem.Gradients.background
            .ignoresSafeArea()
        
        ChapterView(story: sampleStory) { chapterNumber in
            print("Continue generation for chapter \(chapterNumber)")
        }
    }
} 