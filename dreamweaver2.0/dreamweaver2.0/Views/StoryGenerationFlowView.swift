import SwiftUI

struct StoryGenerationFlowView: View {
    @EnvironmentObject var supabaseService: SupabaseService
    @StateObject private var mistralService = MistralService()
    @Environment(\.dismiss) private var dismiss
    
    // Story data passed from previous view
    let initialPrompt: String
    let storyParameters: StoryGenerationParameters
    
    // Flow state
    @State private var currentStep: GenerationStep = .plotSelection
    @State private var selectedPlot: PlotOption?
    @State private var storyTitle: String = ""
    @State private var characters: [StoryCharacter] = []
    @State private var finalStory: String = ""
    
    // UI state
    @State private var plotOptions: [PlotOption] = []
    @State private var titleSuggestions: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showingError = false
    @State private var retryAttempt: Int = 0
    
    // Character editing state
    @State private var editingCharacter: StoryCharacter?
    @State private var editingCharacterName: String = ""
    @State private var editingCharacterDescription: String = ""
    @State private var showingCharacterEditor = false
    
    var body: some View {
        ZStack {
            // Background gradient matching DreamPress.ai style
            DesignSystem.Gradients.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top header with close button
                topHeader
                
                // Progress indicator
                progressSection
                
                // Main content area
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Current step content
                        currentStepView
                        
                        // Navigation buttons
                        navigationButtons
                    }
                    .padding(DesignSystem.Spacing.lg)
                    .padding(.bottom, DesignSystem.Spacing.xl)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Loading overlay
            if isLoading {
                modernLoadingOverlay
            }
        }
        .onAppear {
            generatePlotOptions()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .sheet(isPresented: $showingCharacterEditor) {
            modernCharacterEditorSheet
        }
    }
    
    // MARK: - Top Header
    
    private var topHeader: some View {
        HStack {
            // Genre indicator
            HStack(spacing: DesignSystem.Spacing.sm) {
                Text(storyParameters.genre.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(storyParameters.genre.displayName)
                        .font(DesignSystem.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(storyParameters.mood.displayName)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(DesignSystem.Spacing.sm)
                    .background(
                        Circle()
                            .fill(DesignSystem.Colors.surface)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.top, DesignSystem.Spacing.md)
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Step indicator
            HStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(GenerationStep.allCases, id: \.self) { step in
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        // Circle indicator
                        Circle()
                            .fill(step.rawValue <= currentStep.rawValue ? 
                                  DesignSystem.Colors.primary : 
                                  DesignSystem.Colors.surfaceSecondary)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(step == currentStep ? 
                                           DesignSystem.Colors.primary : 
                                           Color.clear, lineWidth: 3)
                                    .frame(width: 32, height: 32)
                                    .scaleEffect(step == currentStep ? 1.0 : 0.8)
                            )
                            .scaleEffect(step == currentStep ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentStep)
                        
                        // Connector line
                        if step != GenerationStep.allCases.last {
                            Rectangle()
                                .fill(step.rawValue < currentStep.rawValue ? 
                                      DesignSystem.Colors.primary : 
                                      DesignSystem.Colors.surfaceSecondary)
                                .frame(height: 3)
                                .frame(maxWidth: .infinity)
                                .animation(.spring(response: 0.3), value: currentStep)
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            
            // Current step title
            Text(currentStep.title)
                .font(DesignSystem.Typography.title3)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .animation(.easeInOut(duration: 0.3), value: currentStep)
        }
        .padding(.vertical, DesignSystem.Spacing.lg)
    }
    
    // MARK: - Current Step View
    
    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep {
        case .plotSelection:
            modernPlotSelectionView
        case .titleInput:
            modernTitleInputView
        case .characterEditing:
            modernCharacterEditingView
        case .storyGeneration:
            modernStoryGenerationView
        }
    }
    
    // MARK: - Modern Plot Selection View
    
    private var modernPlotSelectionView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Header
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("How should your story begin?")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Choose a compelling opening that sets the tone for your \(storyParameters.genre.displayName.lowercased()) story.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, DesignSystem.Spacing.md)
            
            // Plot options
            VStack(spacing: DesignSystem.Spacing.lg) {
                ForEach(plotOptions) { option in
                    ModernPlotOptionCard(
                        option: option,
                        isSelected: selectedPlot?.id == option.id,
                        genre: storyParameters.genre,
                        onSelect: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedPlot = option
                            }
                        }
                    )
                }
            }
            
            // Regenerate button
            if !plotOptions.isEmpty {
                Button(action: generatePlotOptions) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                        Text("Generate New Options")
                            .font(DesignSystem.Typography.bodyEmphasized)
                    }
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(DesignSystem.Colors.surface)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                }
                .padding(.top, DesignSystem.Spacing.md)
            }
        }
    }
    
    // MARK: - Modern Title Input View
    
    private var modernTitleInputView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Header
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Give your story a title")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("A great title captures the essence of your story and draws readers in.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, DesignSystem.Spacing.md)
            
            // Title input with modern styling
            VStack(spacing: DesignSystem.Spacing.lg) {
                ZStack {
                    // Background card
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                        .fill(DesignSystem.Colors.surface)
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                                .stroke(storyTitle.isEmpty ? 
                                       DesignSystem.Colors.surfaceSecondary : 
                                       DesignSystem.Colors.primary, lineWidth: 2)
                        )
                    
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        // Title input
                        TextEditor(text: $storyTitle)
                            .font(DesignSystem.Typography.title1)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(DesignSystem.Spacing.lg)
                            .background(Color.clear)
                            .scrollContentBackground(.hidden)
                            .colorScheme(.dark)
                            .frame(minHeight: 80)
                        
                        // Placeholder when empty
                        if storyTitle.isEmpty {
                            Text("Enter your story title...")
                                .font(DesignSystem.Typography.title1)
                                .fontWeight(.bold)
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                                .multilineTextAlignment(.center)
                                .allowsHitTesting(false)
                                .padding(DesignSystem.Spacing.lg)
                        }
                    }
                }
                .frame(minHeight: 120)
                
                // Title suggestions
                if !titleSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Suggestions:")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .fontWeight(.medium)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.sm) {
                            ForEach(titleSuggestions, id: \.self) { suggestion in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        storyTitle = suggestion
                                    }
                                }) {
                                    Text(suggestion)
                                        .font(DesignSystem.Typography.bodyEmphasized)
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, DesignSystem.Spacing.md)
                                        .padding(.vertical, DesignSystem.Spacing.sm)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                                .fill(DesignSystem.Colors.surface)
                                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                        )
                                }
                            }
                        }
                    }
                }
                
                // Regenerate suggestions button
                Button(action: generateTitleSuggestions) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "arrow.clockwise")
                        Text("Generate New Titles")
                    }
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(DesignSystem.Colors.surface)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                }
            }
        }
    }
    
    // MARK: - Modern Character Editing View
    
    private var modernCharacterEditingView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Header
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Meet your characters")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("These characters will bring your story to life. Edit them to match your vision.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, DesignSystem.Spacing.md)
            
            // Characters list
            VStack(spacing: DesignSystem.Spacing.lg) {
                ForEach(characters) { character in
                    ModernCharacterCard(
                        character: character,
                        onEdit: {
                            editingCharacter = character
                            editingCharacterName = character.name
                            editingCharacterDescription = character.description
                            showingCharacterEditor = true
                        },
                        onDelete: {
                            withAnimation(.spring(response: 0.3)) {
                                characters.removeAll { $0.id == character.id }
                            }
                        }
                    )
                }
                
                // Action buttons
                HStack(spacing: DesignSystem.Spacing.md) {
                    // Add character button
                    Button(action: addNewCharacter) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "plus")
                                .font(.title3)
                            Text("Add Character")
                                .font(DesignSystem.Typography.bodyEmphasized)
                        }
                        .foregroundColor(DesignSystem.Colors.primary)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                                .stroke(DesignSystem.Colors.primary, lineWidth: 2)
                        )
                    }
                    
                    // Regenerate all button
                    Button(action: regenerateCharacters) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                            Text("Regenerate All")
                                .font(DesignSystem.Typography.bodyEmphasized)
                        }
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                                .fill(DesignSystem.Colors.surface)
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Modern Story Generation View
    
    private var modernStoryGenerationView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Header with title
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("🎉 Your Story is Ready!")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(storyTitle)
                    .font(DesignSystem.Typography.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(DesignSystem.Colors.primary.opacity(0.1))
                    )
            }
            .padding(.bottom, DesignSystem.Spacing.md)
            
            // Saving state - no story content shown
            VStack(spacing: DesignSystem.Spacing.lg) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primary))
                    .scaleEffect(1.5)
                
                Text("Saving your story...")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Your story will open automatically in the reading view with a typewriter effect!")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.xxl)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                    .fill(DesignSystem.Colors.surface)
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
            )
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            // Back button
            if currentStep != .plotSelection {
                Button(action: goBack) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                        Text("Back")
                            .font(DesignSystem.Typography.bodyEmphasized)
                    }
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(DesignSystem.Colors.surface)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                }
            }
            
            Spacer()
            
            // Continue button
            if currentStep != .storyGeneration {
                Button(action: goNext) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Text("Continue")
                            .font(DesignSystem.Typography.bodyEmphasized)
                        Image(systemName: "chevron.right")
                            .font(.title3)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(canContinue ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
                            .shadow(color: canContinue ? DesignSystem.Colors.primary.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                    )
                }
                .disabled(!canContinue)
                .scaleEffect(canContinue ? 1.0 : 0.95)
                .animation(.spring(response: 0.3), value: canContinue)
            } else {
                Button(action: { dismiss() }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "checkmark")
                            .font(.title3)
                        Text("Done")
                            .font(DesignSystem.Typography.bodyEmphasized)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(DesignSystem.Gradients.primary)
                            .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 12, x: 0, y: 6)
                    )
                }
            }
        }
        .padding(.top, DesignSystem.Spacing.lg)
    }
    
    // MARK: - Modern Loading Overlay
    
    private var modernLoadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Animated progress indicator
                ZStack {
                    Circle()
                        .stroke(DesignSystem.Colors.primary.opacity(0.2), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(DesignSystem.Colors.primary, lineWidth: 4)
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isLoading)
                }
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text("Creating your story...")
                        .font(DesignSystem.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(loadingMessage)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    if retryAttempt > 0 {
                        Text("Retry attempt \(retryAttempt)/3")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.accent)
                            .padding(.top, DesignSystem.Spacing.xs)
                    }
                }
            }
            .padding(DesignSystem.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                    .fill(DesignSystem.Colors.surface)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
        }
    }
    
    // MARK: - Modern Character Editor Sheet
    
    private var modernCharacterEditorSheet: some View {
        NavigationView {
            ZStack {
                DesignSystem.Gradients.background
                    .ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Character name input
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Character Name")
                            .font(DesignSystem.Typography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        TextField("Enter character name", text: $editingCharacterName)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .padding(DesignSystem.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                                    .fill(DesignSystem.Colors.surface)
                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                    }
                    
                    // Character description input
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Character Description")
                            .font(DesignSystem.Typography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        TextEditor(text: $editingCharacterDescription)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .padding(DesignSystem.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                                    .fill(DesignSystem.Colors.surface)
                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                            .frame(minHeight: 200)
                            .scrollContentBackground(.hidden)
                            .colorScheme(.dark)
                    }
                    
                    Spacer()
                }
                .padding(DesignSystem.Spacing.lg)
            }
            .navigationTitle("Edit Character")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingCharacterEditor = false
                    }
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCharacterEdit()
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var canContinue: Bool {
        switch currentStep {
        case .plotSelection:
            return selectedPlot != nil
        case .titleInput:
            return !storyTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .characterEditing:
            return !characters.isEmpty
        case .storyGeneration:
            return true
        }
    }
    
    private var loadingMessage: String {
        switch currentStep {
        case .plotSelection:
            return "AI is crafting unique plot options for your \(storyParameters.genre.displayName.lowercased()) story..."
        case .titleInput:
            return "Generating catchy titles that capture your story's essence..."
        case .characterEditing:
            return "Bringing your characters to life with detailed descriptions..."
        case .storyGeneration:
            return "Weaving your story together with masterful storytelling..."
        }
    }
    
    // MARK: - Actions
    
    private func generatePlotOptions() {
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
                retryAttempt = 0
            }
            
            do {
                let options = try await mistralService.generatePlotOptions(
                    prompt: initialPrompt,
                    parameters: storyParameters
                )
                
                await MainActor.run {
                    plotOptions = options
                    isLoading = false
                    retryAttempt = 0
                }
            } catch {
                await MainActor.run {
                    // Don't show error dialog for rate limiting - retry happens silently
                    let errorMsg = error.localizedDescription
                    if errorMsg.contains("Rate limit") || errorMsg.contains("Too many requests") || errorMsg.contains("server error") {
                        // For rate limits and server errors, the retry happens automatically
                        // Don't show error dialog, just stay in loading state
                        print("API temporarily unavailable, retrying automatically...")
                        return
                    }
                    
                    // Only show error dialog for permanent errors
                    errorMessage = errorMsg
                    showingError = true
                    isLoading = false
                    retryAttempt = 0
                }
            }
        }
    }
    
    private func generateTitleSuggestions() {
        guard let plot = selectedPlot else { return }
        
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
                retryAttempt = 0
            }
            
            do {
                let suggestions = try await mistralService.generateTitleSuggestions(
                    prompt: initialPrompt,
                    selectedPlot: plot,
                    parameters: storyParameters
                )
                
                await MainActor.run {
                    titleSuggestions = suggestions
                    if storyTitle.isEmpty && !suggestions.isEmpty {
                        storyTitle = suggestions[0]
                    }
                    isLoading = false
                    retryAttempt = 0
                }
            } catch {
                await MainActor.run {
                    // Don't show error dialog for rate limiting - retry happens silently
                    let errorMsg = error.localizedDescription
                    if errorMsg.contains("Rate limit") || errorMsg.contains("Too many requests") || errorMsg.contains("server error") {
                        // For rate limits and server errors, the retry happens automatically
                        // Don't show error dialog, just stay in loading state
                        print("API temporarily unavailable, retrying automatically...")
                        return
                    }
                    
                    // Only show error dialog for permanent errors
                    errorMessage = errorMsg
                    showingError = true
                    isLoading = false
                    retryAttempt = 0
                }
            }
        }
    }
    
    private func generateCharacters() {
        guard let plot = selectedPlot else { return }
        
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
                retryAttempt = 0
            }
            
            do {
                let generatedCharacters = try await mistralService.generateCharacterDescriptions(
                    prompt: initialPrompt,
                    selectedPlot: plot,
                    parameters: storyParameters
                )
                
                await MainActor.run {
                    characters = generatedCharacters
                    isLoading = false
                    retryAttempt = 0
                }
            } catch {
                await MainActor.run {
                    // Don't show error dialog for rate limiting - retry happens silently
                    let errorMsg = error.localizedDescription
                    if errorMsg.contains("Rate limit") || errorMsg.contains("Too many requests") || errorMsg.contains("server error") {
                        // For rate limits and server errors, the retry happens automatically
                        // Don't show error dialog, just stay in loading state
                        print("API temporarily unavailable, retrying automatically...")
                        return
                    }
                    
                    // Only show error dialog for permanent errors
                    errorMessage = errorMsg
                    showingError = true
                    isLoading = false
                    retryAttempt = 0
                }
            }
        }
    }
    
    private func regenerateCharacters() {
        generateCharacters()
    }
    
    private func addNewCharacter() {
        let newCharacter = StoryCharacter(
            name: "New Character",
            description: "Add a description for this character...",
            role: "supporting",
            traits: []
        )
        withAnimation(.spring(response: 0.3)) {
            characters.append(newCharacter)
        }
    }
    
    private func saveCharacterEdit() {
        if let index = characters.firstIndex(where: { $0.id == editingCharacter?.id }) {
            characters[index] = StoryCharacter(
                name: editingCharacterName,
                description: editingCharacterDescription,
                role: characters[index].role,
                traits: characters[index].traits
            )
        }
        showingCharacterEditor = false
    }
    
    private func generateFinalStory() {
        guard let plot = selectedPlot else { return }
        
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
                retryAttempt = 0
            }
            
            do {
                // Generate Chapter 1 instead of full story
                let chapterContent = try await mistralService.generateFirstChapter(
                    prompt: initialPrompt,
                    selectedPlot: plot,
                    storyTitle: storyTitle,
                    characters: characters,
                    parameters: storyParameters
                )
                
                await MainActor.run {
                    finalStory = chapterContent
                    // Don't set isLoading = false here to prevent UI from showing content
                    retryAttempt = 0
                }
                
                // Auto-save the story immediately without showing content
                await autoSaveStoryAndNavigate()
            } catch {
                await MainActor.run {
                    // Don't show error dialog for rate limiting - retry happens silently
                    let errorMsg = error.localizedDescription
                    if errorMsg.contains("Rate limit") || errorMsg.contains("Too many requests") || errorMsg.contains("server error") {
                        // For rate limits and server errors, the retry happens automatically
                        // Don't show error dialog, just stay in loading state
                        print("API temporarily unavailable, retrying automatically...")
                        return
                    }
                    
                    // Only show error dialog for permanent errors
                    errorMessage = errorMsg
                    showingError = true
                    isLoading = false
                    retryAttempt = 0
                }
            }
        }
    }
    
    private func regenerateStory() {
        generateFinalStory()
    }
    
    private func saveStory() {
        guard let plot = selectedPlot else { return }
        
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            do {
                guard let currentUser = supabaseService.currentUser else {
                    throw NSError(domain: "StoryGenerationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                }
                
                let wordsCount = finalStory.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
                let readingTime = max(1, wordsCount / 200) // Assume 200 words per minute
                
                // Create story without content field (new chapter-based structure)
                let story = Story(
                    id: UUID(),
                    userId: currentUser.userId,
                    title: storyTitle,
                    summary: String(finalStory.prefix(200)) + (finalStory.count > 200 ? "..." : ""),
                    genre: storyParameters.genre,
                    mood: storyParameters.mood,
                    isPublished: false,
                    isPremium: false,
                    likesCount: 0,
                    viewsCount: 0,
                    totalWordsCount: wordsCount,
                    totalReadingTime: readingTime,
                    chaptersCount: 1,
                    createdAt: Date(),
                    updatedAt: Date(),
                    publishedAt: nil,
                    generationPrompt: initialPrompt,
                    generationParameters: storyParameters
                )
                
                let createdStory = try await supabaseService.createStory(story)
                
                // Create Chapter 1
                let chapter1 = Chapter(
                    storyId: createdStory.id,
                    chapterNumber: 1,
                    title: "Chapter 1",
                    content: finalStory,
                    wordsCount: wordsCount,
                    readingTime: readingTime,
                    generationPrompt: initialPrompt
                )
                
                _ = try await supabaseService.createChapter(chapter1)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func autoSaveStoryAndNavigate() async {
        guard let plot = selectedPlot else { return }
        
        do {
            print("🔄 Starting auto-save process...")
            
            guard let currentUser = supabaseService.currentUser else {
                throw NSError(domain: "StoryGenerationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            let wordsCount = finalStory.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
            let readingTime = max(1, wordsCount / 200) // Assume 200 words per minute
            
            print("📊 Story stats: \(wordsCount) words, \(readingTime) min read")
            
            // Create story without content field (new chapter-based structure)
            let story = Story(
                id: UUID(),
                userId: currentUser.userId,
                title: storyTitle,
                summary: String(finalStory.prefix(200)) + (finalStory.count > 200 ? "..." : ""),
                genre: storyParameters.genre,
                mood: storyParameters.mood,
                isPublished: false,
                isPremium: false,
                likesCount: 0,
                viewsCount: 0,
                totalWordsCount: wordsCount,
                totalReadingTime: readingTime,
                chaptersCount: 1,
                createdAt: Date(),
                updatedAt: Date(),
                publishedAt: nil,
                generationPrompt: initialPrompt,
                generationParameters: storyParameters
            )
            
            print("📝 Creating story in database...")
            let createdStory = try await supabaseService.createStory(story)
            print("✅ Story created with ID: \(createdStory.id)")
            
            // Create Chapter 1
            let chapter1 = Chapter(
                storyId: createdStory.id,
                chapterNumber: 1,
                title: "Chapter 1",
                content: finalStory,
                wordsCount: wordsCount,
                readingTime: readingTime,
                generationPrompt: initialPrompt
            )
            
            print("📖 Creating chapter in database...")
            let createdChapter = try await supabaseService.createChapter(chapter1)
            print("✅ Chapter created with ID: \(createdChapter.id)")
            
            // Create a story object with chapters attached for navigation
            var storyWithChapters = createdStory
            storyWithChapters.chapters = [createdChapter]
            
            // Mark story as newly generated for typewriter effect
            NewStoryTracker.shared.markAsNewlyGenerated(createdStory.id)
            print("🏷️ Marked story as newly generated")
            
            await MainActor.run {
                print("🧭 Posting navigation notification...")
                // Post notification to navigate to reading screen with chapters attached
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToNewStory"),
                    object: storyWithChapters
                )
                
                dismiss()
            }
        } catch {
            print("❌ Auto-save failed: \(error)")
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
                isLoading = false
            }
        }
    }
    
    private func goBack() {
        withAnimation(.spring(response: 0.3)) {
            switch currentStep {
            case .plotSelection:
                break
            case .titleInput:
                currentStep = .plotSelection
            case .characterEditing:
                currentStep = .titleInput
            case .storyGeneration:
                currentStep = .characterEditing
            }
        }
    }
    
    private func goNext() {
        withAnimation(.spring(response: 0.3)) {
            switch currentStep {
            case .plotSelection:
                currentStep = .titleInput
                generateTitleSuggestions()
            case .titleInput:
                currentStep = .characterEditing
                generateCharacters()
            case .characterEditing:
                currentStep = .storyGeneration
                generateFinalStory()
            case .storyGeneration:
                break
            }
        }
    }
}

// MARK: - Generation Step Enum

enum GenerationStep: Int, CaseIterable {
    case plotSelection = 0
    case titleInput = 1
    case characterEditing = 2
    case storyGeneration = 3
    
    var title: String {
        switch self {
        case .plotSelection: return "Choose Your Plot"
        case .titleInput: return "Create Your Title"
        case .characterEditing: return "Design Characters"
        case .storyGeneration: return "Your Story"
        }
    }
}

// MARK: - Modern Supporting Views

struct ModernPlotOptionCard: View {
    let option: PlotOption
    let isSelected: Bool
    let genre: StoryGenre
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text(option.title)
                            .font(DesignSystem.Typography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textPrimary)
                        
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "location")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            Text(option.setting)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.surfaceSecondary)
                            .frame(width: 32, height: 32)
                        
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                }
                
                Text(option.description)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
            }
            .padding(DesignSystem.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                    .fill(isSelected ? DesignSystem.Colors.primary.opacity(0.1) : DesignSystem.Colors.surface)
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                    .stroke(isSelected ? DesignSystem.Colors.primary : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModernCharacterCard: View {
    let character: StoryCharacter
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(character.name)
                        .font(DesignSystem.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(character.role.capitalized)
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.primary)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                .fill(DesignSystem.Colors.primary.opacity(0.1))
                        )
                }
                
                Spacer()
                
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.title3)
                            .foregroundColor(DesignSystem.Colors.primary)
                            .padding(DesignSystem.Spacing.xs)
                            .background(
                                Circle()
                                    .fill(DesignSystem.Colors.primary.opacity(0.1))
                            )
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.title3)
                            .foregroundColor(DesignSystem.Colors.accent)
                            .padding(DesignSystem.Spacing.xs)
                            .background(
                                Circle()
                                    .fill(DesignSystem.Colors.accent.opacity(0.1))
                            )
                    }
                }
            }
            
            Text(character.description)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
            
            if !character.traits.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.xs) {
                    ForEach(character.traits.prefix(6), id: \.self) { trait in
                        Text(trait)
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .padding(.horizontal, DesignSystem.Spacing.sm)
                            .padding(.vertical, DesignSystem.Spacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                    .fill(DesignSystem.Colors.surfaceSecondary)
                            )
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .fill(DesignSystem.Colors.surface)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
    }
} 