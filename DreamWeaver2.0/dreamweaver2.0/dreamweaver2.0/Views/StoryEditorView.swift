import SwiftUI

struct StoryEditorView: View {
    @EnvironmentObject var supabaseService: SupabaseService
    @Environment(\.dismiss) private var dismiss
    
    @Binding var title: String
    @Binding var content: String
    let genre: StoryGenre
    let mood: StoryMood
    let parameters: StoryGenerationParameters
    
    @State private var summary = ""
    @State private var isPublished = false
    @State private var isSaving = false
    @State private var showingDiscardAlert = false
    @State private var hasUnsavedChanges = false
    
    // For existing story editing
    @State private var existingStory: Story?
    
    init(title: Binding<String>, content: Binding<String>, genre: StoryGenre, mood: StoryMood, parameters: StoryGenerationParameters) {
        self._title = title
        self._content = content
        self.genre = genre
        self.mood = mood
        self.parameters = parameters
    }
    
    init(story: Story) {
        self._title = .constant(story.title)
        // Get content from first chapter or empty string if no chapters
        let firstChapterContent = story.chapters?.first?.content ?? ""
        self._content = .constant(firstChapterContent)
        self.genre = story.genre
        self.mood = story.mood
        self.parameters = story.generationParameters ?? StoryGenerationParameters(
            genre: story.genre,
            mood: story.mood,
            length: .medium,
            characters: nil,
            setting: nil,
            themes: nil,
            style: nil,
            temperature: nil,
            maxTokens: nil,
            pointOfView: .third
        )
        self._existingStory = State(initialValue: story)
        self._summary = State(initialValue: story.summary ?? "")
        self._isPublished = State(initialValue: story.isPublished)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Story Metadata
                    metadataSection
                    
                    // Title Editor
                    titleEditor
                    
                    // Summary Editor
                    summaryEditor
                    
                    // Content Editor
                    contentEditor
                    
                    // Publishing Options
                    publishingOptions
                }
                .padding(.horizontal)
            }
            .navigationTitle("Edit Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if hasUnsavedChanges {
                            showingDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveStory) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .scaleEffect(0.8)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSaving || title.isEmpty || content.isEmpty)
                }
            }
            .alert("Discard Changes", isPresented: $showingDiscardAlert) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to discard your changes?")
            }
        }
        .onAppear {
            // Track changes for unsaved changes detection
            markChangeTracking()
        }
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Story Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                // Genre badge
                HStack(spacing: 4) {
                    Text(genre.emoji)
                        .font(.subheadline)
                    
                    Text(genre.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(16)
                
                // Mood badge
                Text(mood.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .cornerRadius(16)
                
                Spacer()
                
                // Word count
                Text("\(wordCount) words")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var titleEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .font(.headline)
                .fontWeight(.semibold)
            
            TextField("Enter story title...", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.title3)
                .fontWeight(.semibold)
                .onChange(of: title) { _, _ in
                    hasUnsavedChanges = true
                }
        }
    }
    
    private var summaryEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary (Optional)")
                .font(.headline)
                .fontWeight(.semibold)
            
            TextField("Brief description of your story...", text: $summary, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...5)
                .onChange(of: summary) { _, _ in
                    hasUnsavedChanges = true
                }
            
            Text("Help readers discover your story with a compelling summary")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var contentEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Story Content")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(readingTime) min read")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            TextEditor(text: $content)
                .frame(minHeight: 300)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .font(.body)
                .lineSpacing(4)
                .onChange(of: content) { _, _ in
                    hasUnsavedChanges = true
                }
        }
    }
    
    private var publishingOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Publishing")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Publish Story")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Make your story visible to other users")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isPublished)
                        .labelsHidden()
                        .onChange(of: isPublished) { _, _ in
                            hasUnsavedChanges = true
                        }
                }
                
                if isPublished {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("When you publish:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Other users can discover and read your story")
                            Text("• Your story will appear in genre categories")
                            Text("• Readers can like and share your story")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppConfig.cornerRadius)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    private var wordCount: Int {
        content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
    
    private var readingTime: Int {
        max(1, wordCount / 200) // Assume 200 words per minute
    }
    
    private func saveStory() {
        Task {
            await performSave()
        }
    }
    
    @MainActor
    private func performSave() async {
        isSaving = true
        defer { isSaving = false }
        
        do {
            let storyToSave: Story
            
            if let existing = existingStory {
                // Update existing story
                storyToSave = Story(
                    id: existing.id,
                    userId: existing.userId,
                    title: title,
                    summary: summary.isEmpty ? nil : summary,
                    genre: genre,
                    mood: mood,
                    isPublished: isPublished,
                    isPremium: existing.isPremium,
                    likesCount: existing.likesCount,
                    viewsCount: existing.viewsCount,
                    totalWordsCount: wordCount,
                    totalReadingTime: readingTime,
                    chaptersCount: existing.chaptersCount,
                    createdAt: existing.createdAt,
                    updatedAt: Date(),
                    publishedAt: isPublished ? (existing.publishedAt ?? Date()) : nil,
                    generationPrompt: existing.generationPrompt,
                    generationParameters: parameters,
                    chapters: existing.chapters
                )
                
                try await supabaseService.updateStory(storyToSave)
                
                // Update the first chapter content if it exists
                if let firstChapter = existing.chapters?.first {
                    let updatedChapter = Chapter(
                        id: firstChapter.id,
                        storyId: existing.id,
                        chapterNumber: firstChapter.chapterNumber,
                        title: firstChapter.title,
                        content: content,
                        wordsCount: wordCount,
                        readingTime: readingTime,
                        generationPrompt: firstChapter.generationPrompt,
                        contextFromPreviousChapters: firstChapter.contextFromPreviousChapters,
                        createdAt: firstChapter.createdAt,
                        updatedAt: Date()
                    )
                    try await supabaseService.updateChapter(updatedChapter)
                }
            } else {
                // Create new story
                guard let userId = supabaseService.currentUser?.userId else { return }
                
                storyToSave = Story(
                    id: UUID(),
                    userId: userId,
                    title: title,
                    summary: summary.isEmpty ? nil : summary,
                    genre: genre,
                    mood: mood,
                    isPublished: isPublished,
                    isPremium: false,
                    likesCount: 0,
                    viewsCount: 0,
                    totalWordsCount: wordCount,
                    totalReadingTime: readingTime,
                    chaptersCount: 1,
                    createdAt: Date(),
                    updatedAt: Date(),
                    publishedAt: isPublished ? Date() : nil,
                    generationPrompt: nil,
                    generationParameters: parameters
                )
                
                let newStory = try await supabaseService.createStory(storyToSave)
                
                // Create the first chapter
                let firstChapter = Chapter(
                    storyId: newStory.id,
                    chapterNumber: 1,
                    title: "Chapter 1",
                    content: content,
                    wordsCount: wordCount,
                    readingTime: readingTime,
                    generationPrompt: nil,
                    contextFromPreviousChapters: nil
                )
                
                try await supabaseService.createChapter(firstChapter)
            }
            
            hasUnsavedChanges = false
            dismiss()
            
        } catch {
            print("Error saving story: \(error)")
        }
    }
    
    private func markChangeTracking() {
        // Initial state is considered saved
        hasUnsavedChanges = false
    }
}

#Preview {
    StoryEditorView(
        title: .constant("Sample Story"),
        content: .constant("Once upon a time..."),
        genre: .fantasy,
        mood: .mysterious,
        parameters: StoryGenerationParameters(
            genre: .fantasy,
            mood: .mysterious,
            length: .medium,
            characters: nil,
            setting: nil,
            themes: nil,
            style: nil,
            temperature: nil,
            maxTokens: nil,
            pointOfView: .third
        )
    )
    .environmentObject(SupabaseService())
} 