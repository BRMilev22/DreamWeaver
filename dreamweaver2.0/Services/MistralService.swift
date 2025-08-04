import Foundation
import Combine

class MistralService: ObservableObject {
    private let apiKey: String
    private let baseURL: String
    private let model: String
    private let session: URLSession
    
    init() {
        // Using OpenRouter + DeepSeek for story generation
        self.apiKey = AppConfig.storyGenerationAPIKey
        self.baseURL = AppConfig.storyGenerationBaseURL
        self.model = AppConfig.storyGenerationModel
        self.session = URLSession.shared
        
        print("🔧 Initialized story generation with DeepSeek V3 via OpenRouter")
        print("📝 Model: \(self.model)")
    }
    
    // MARK: - Interactive Story Generation Methods
    
    func generatePlotOptions(
        prompt: String,
        parameters: StoryGenerationParameters
    ) async throws -> [PlotOption] {
        let systemPrompt = """
        You are a skilled creative writer. Generate 3 different plot beginning options for a story.
        Each option should be a compelling opening that sets up the story in a different way.
        
        Story Requirements:
        - Genre: \(parameters.genre.displayName)
        - Mood: \(parameters.mood.displayName)
        - Length: \(parameters.length.displayName)
        
        Return your response as a JSON array with exactly 3 objects, each containing:
        - "title": A compelling title for this plot beginning (max 60 characters)
        - "description": A detailed description of how the story begins (100-200 words)
        - "setting": A brief description of the location/setting (max 50 characters)
        DO NOT include any additional text or explanations, ONLY the JSON array.
        
        Example format:
        [
          {
            "title": "The Mysterious Signal",
            "description": "Dr. Sarah Chen was analyzing radio telescope data when she discovered something extraordinary...",
            "setting": "Remote observatory in the mountains"
          }
        ]
        """
        
        let userPrompt = "Generate 3 different plot beginning options for this story concept: \(prompt)"
        
        let content = try await makeAPICall(systemPrompt: systemPrompt, userPrompt: userPrompt, temperature: 0.8)
        
        // Parse JSON response with better error handling
        do {
            let cleanedContent = extractJSONFromResponse(content)
            guard let data = cleanedContent.data(using: .utf8) else {
                print("❌ Failed to convert to UTF8 data")
                throw MistralError.invalidResponse
            }
            
            let plotOptions = try JSONDecoder().decode([PlotOption].self, from: data)
            print("✅ Successfully parsed \(plotOptions.count) plot options")
            return plotOptions
        } catch {
            // Fallback: generate default plot options if JSON parsing fails
            print("❌ JSON parsing failed, using fallback plot options: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .dataCorrupted(let context):
                    print("❌ Data corrupted: \(context.debugDescription)")
                case .keyNotFound(let key, let context):
                    print("❌ Key not found: \(key), context: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("❌ Type mismatch: \(type), context: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("❌ Value not found: \(type), context: \(context.debugDescription)")
                @unknown default:
                    print("❌ Unknown decoding error")
                }
            }
            
            return [
                PlotOption(
                    title: "The Beginning",
                    description: "Your story begins with an unexpected discovery that changes everything. The protagonist faces a choice that will determine their fate and the fate of others.",
                    setting: "Modern day setting"
                ),
                PlotOption(
                    title: "The Challenge",
                    description: "A mysterious challenge presents itself to the main character. They must overcome obstacles and face their fears to achieve their goal.",
                    setting: "Varied locations"
                ),
                PlotOption(
                    title: "The Mystery",
                    description: "Strange events begin to unfold around the protagonist. They must uncover the truth behind these mysterious occurrences.",
                    setting: "Mysterious location"
                )
            ]
        }
    }
    
    func generateTitleSuggestions(
        prompt: String,
        selectedPlot: PlotOption,
        parameters: StoryGenerationParameters
    ) async throws -> [String] {
        let systemPrompt = """
        You are a skilled creative writer. Generate 5 compelling titles for a story based on the plot beginning.
        The titles should be catchy, genre-appropriate, and capture the essence of the story.
        
        Story Requirements:
        - Genre: \(parameters.genre.displayName)
        - Mood: \(parameters.mood.displayName)
        - Plot Beginning: \(selectedPlot.title)
        
        Return your response as a JSON array of strings containing exactly 5 titles.
        Each title should be 2-8 words and capture the story's essence.
        DO NOT include any additional text or explanations, ONLY the JSON array.
        
        Example format:
        ["The Last Signal", "Whispers from Beyond", "The Cosmic Discovery", "Echoes of Tomorrow", "The Silent Universe"]
        """
        
        let userPrompt = """
        Generate 5 title suggestions for this story:
        Original concept: \(prompt)
        Selected plot: \(selectedPlot.description)
        """
        
        let content = try await makeAPICall(systemPrompt: systemPrompt, userPrompt: userPrompt, temperature: 0.7)
        
        // Parse JSON response with better error handling
        do {
            let cleanedContent = extractJSONFromResponse(content)
            guard let data = cleanedContent.data(using: .utf8) else {
                throw MistralError.invalidResponse
            }
            
            let titles = try JSONDecoder().decode([String].self, from: data)
            return titles
        } catch {
            // Fallback: generate default titles if JSON parsing fails
            print("JSON parsing failed, using fallback titles: \(error)")
            return [
                "The \(parameters.genre.displayName) Story",
                "A Tale of \(selectedPlot.setting)",
                "The Journey Begins",
                "Secrets Revealed",
                "The Final Chapter"
            ]
        }
    }
    
    func generateCharacterDescriptions(
        prompt: String,
        selectedPlot: PlotOption,
        parameters: StoryGenerationParameters
    ) async throws -> [StoryCharacter] {
        let systemPrompt = """
        You are a skilled creative writer. Generate 3-5 main characters for the story based on the plot beginning.
        Each character should be well-developed with clear motivations and roles in the story.
        
        Story Requirements:
        - Genre: \(parameters.genre.displayName)
        - Mood: \(parameters.mood.displayName)
        - Plot Beginning: \(selectedPlot.title)
        - Setting: \(selectedPlot.setting)
        
        Return your response as a JSON array with 3-5 character objects, each containing:
        - "name": Character's full name
        - "description": Detailed character description (50-100 words)
        - "role": Their role in the story (protagonist, antagonist, supporting, etc.)
        - "traits": Array of 3-5 key personality traits
        DO NOT include any additional text or explanations, ONLY the JSON array.
        
        Example format:
        [
          {
            "name": "Dr. Sarah Chen",
            "description": "A brilliant astrophysicist in her mid-thirties who discovers the mysterious signal...",
            "role": "protagonist",
            "traits": ["intelligent", "curious", "determined", "skeptical", "brave"]
          }
        ]
        """
        
        let userPrompt = """
        Generate characters for this story:
        Original concept: \(prompt)
        Selected plot: \(selectedPlot.description)
        Setting: \(selectedPlot.setting)
        """
        
        let content = try await makeAPICall(systemPrompt: systemPrompt, userPrompt: userPrompt, temperature: 0.8)
        
        // Parse JSON response with better error handling
        do {
            let cleanedContent = extractJSONFromResponse(content)
            guard let data = cleanedContent.data(using: .utf8) else {
                throw MistralError.invalidResponse
            }
            
            let characters = try JSONDecoder().decode([StoryCharacter].self, from: data)
            return characters
        } catch {
            // Fallback: generate default characters if JSON parsing fails
            print("JSON parsing failed, using fallback characters: \(error)")
            return [
                StoryCharacter(
                    name: "Alex",
                    description: "The main character who drives the story forward with determination and courage.",
                    role: "protagonist",
                    traits: ["brave", "curious", "determined", "resourceful", "empathetic"]
                ),
                StoryCharacter(
                    name: "Morgan",
                    description: "A loyal companion who provides support and wisdom throughout the journey.",
                    role: "supporting",
                    traits: ["loyal", "wise", "supportive", "reliable", "thoughtful"]
                ),
                StoryCharacter(
                    name: "Casey",
                    description: "A complex character who creates challenges and obstacles for the protagonist.",
                    role: "antagonist",
                    traits: ["cunning", "ambitious", "mysterious", "intelligent", "driven"]
                )
            ]
        }
    }
    
    func generateFinalStory(
        prompt: String,
        selectedPlot: PlotOption,
        storyTitle: String,
        characters: [StoryCharacter],
        parameters: StoryGenerationParameters
    ) async throws -> String {
        let systemPrompt = createSystemPrompt(for: parameters)
        let userPrompt = createFinalStoryPrompt(
            prompt: prompt,
            selectedPlot: selectedPlot,
            storyTitle: storyTitle,
            characters: characters,
            parameters: parameters
        )
        
        return try await makeAPICall(systemPrompt: systemPrompt, userPrompt: userPrompt, temperature: parameters.temperature ?? 0.7)
    }
    
    // MARK: - Legacy Method (for backwards compatibility)
    
    func generateStory(
        prompt: String,
        parameters: StoryGenerationParameters
    ) async throws -> String {
        let systemPrompt = createSystemPrompt(for: parameters)
        let userPrompt = createUserPrompt(prompt: prompt, parameters: parameters)
        
        return try await makeAPICall(systemPrompt: systemPrompt, userPrompt: userPrompt, temperature: parameters.temperature ?? 0.7)
    }
    
    // MARK: - Chapter Generation Methods
    
    func generateFirstChapter(
        prompt: String,
        selectedPlot: PlotOption,
        storyTitle: String,
        characters: [StoryCharacter],
        parameters: StoryGenerationParameters
    ) async throws -> String {
        let systemPrompt = """
        You are a skilled creative writer. You are writing the FIRST CHAPTER of a story.
        This chapter should be approximately 1000-1300 words and serve as a compelling opening.
        
        Story Requirements:
        - Genre: \(parameters.genre.displayName)
        - Mood: \(parameters.mood.displayName)
        - Point of View: \(parameters.pointOfView.displayName)
        - Writing Style: \(parameters.style?.displayName ?? "Descriptive")
        
        Chapter 1 Guidelines:
        - Establish the main character(s) and setting
        - Create an engaging hook in the first few paragraphs
        - Introduce the central conflict or mystery
        - End with a compelling reason for readers to continue
        - Target 1000-1300 words
        - Include vivid descriptions and compelling dialogue
        - Leave room for story development in future chapters
        
        Write only the story content, no titles or chapter headers.
        """
        
        let characterDescriptions = characters.map { "\($0.name): \($0.description)" }.joined(separator: "\n")
        
        let userPrompt = """
        Write Chapter 1 of a story with these elements:
        
        Title: "\(storyTitle)"
        
        Plot Beginning: \(selectedPlot.description)
        Setting: \(selectedPlot.setting)
        
        Characters:
        \(characterDescriptions)
        
        Original Concept: \(prompt)
        
        Create an engaging first chapter that establishes the world, characters, and central conflict while leaving room for the story to develop in subsequent chapters.
        """
        
        return try await makeAPICall(systemPrompt: systemPrompt, userPrompt: userPrompt, temperature: parameters.temperature ?? 0.7)
    }
    
    func generateChapterSuggestions(
        context: String,
        storyParameters: StoryGenerationParameters
    ) async throws -> [String] {
        let systemPrompt = "You are a skilled creative writer who generates brief, engaging story continuation ideas."
        
        let userPrompt = """
        Based on the current story context, generate exactly 3 brief, engaging continuation ideas (each 8-12 words).
        
        Story Genre: \(storyParameters.genre)
        Story Mood: \(storyParameters.mood)
        Point of View: \(storyParameters.pointOfView)
        
        Current Context:
        \(context)
        
        Generate 3 different directions the story could go next. Each should be:
        - Brief (8-12 words)
        - Engaging and specific to this story
        - Different from each other
        - Appropriate for the genre and mood
        
        Return only the 3 suggestions, one per line, no numbering or extra text.
        """
        
        let response = try await makeAPICall(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.8
        )
        
        let suggestionsArray = response
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(3)
        
        return Array(suggestionsArray)
    }
    
    func generateNextChapter(
        parameters: ChapterGenerationParameters
    ) async throws -> String {
        let systemPrompt = """
        You are a skilled creative writer continuing an existing story. You are writing Chapter \(parameters.chapterNumber) of this story.
        This chapter should be approximately 1000-1300 words and continue the narrative seamlessly.
        
        Story Requirements:
        - Genre: \(parameters.originalStoryParameters.genre.displayName)
        - Mood: \(parameters.originalStoryParameters.mood.displayName)
        - Point of View: \(parameters.originalStoryParameters.pointOfView.displayName)
        - Writing Style: \(parameters.originalStoryParameters.style?.displayName ?? "Descriptive")
        
        Chapter \(parameters.chapterNumber) Guidelines:
        - Continue the story naturally from previous chapters
        - Maintain consistency with established characters and plot
        - Advance the main storyline while addressing the user's new direction
        - Target 1000-1300 words
        - Include compelling dialogue and vivid descriptions
        - End with a hook or transition that sets up future chapters
        - Stay true to the genre and mood established in earlier chapters
        
        Write only the story content, no titles or chapter headers.
        """
        
        let userPrompt = """
        Continue the story with Chapter \(parameters.chapterNumber) based on:
        
        PREVIOUS CHAPTERS CONTEXT:
        \(parameters.previousChaptersContext)
        
        USER'S DIRECTION FOR THIS CHAPTER:
        \(parameters.userPrompt)
        
        Write Chapter \(parameters.chapterNumber) that continues the story naturally while incorporating the user's direction. Maintain consistency with the established characters, setting, and plot while advancing the narrative.
        """
        
        return try await makeAPICall(systemPrompt: systemPrompt, userPrompt: userPrompt, temperature: parameters.originalStoryParameters.temperature ?? 0.7)
    }
    
    func createContextFromChapters(_ chapters: [Chapter]) -> String {
        var context = ""
        
        for chapter in chapters.sorted(by: { $0.chapterNumber < $1.chapterNumber }) {
            context += "Chapter \(chapter.chapterNumber):\n"
            
            // Use only the first 400 words of each chapter to keep context manageable
            let words = chapter.content.components(separatedBy: .whitespaces)
            let truncatedContent = words.prefix(400).joined(separator: " ")
            
            context += truncatedContent
            if words.count > 400 {
                context += "..."
            }
            context += "\n\n"
        }
        
        return context
    }
    
    // MARK: - Private Helper Methods
    
    private func createSystemPrompt(for parameters: StoryGenerationParameters) -> String {
        var prompt = """
        You are a skilled creative writer specializing in crafting engaging stories. 
        Your task is to write a compelling story based on the user's requirements.
        
        Story Requirements:
        - Genre: \(parameters.genre.displayName)
        - Mood: \(parameters.mood.displayName)
        - Length: \(parameters.length.displayName)
        """
        
        if let style = parameters.style {
            prompt += "\n- Writing Style: \(style.displayName)"
        }
        
        if let setting = parameters.setting {
            prompt += "\n- Setting: \(setting)"
        }
        
        if let characters = parameters.characters, !characters.isEmpty {
            prompt += "\n- Characters: \(characters.joined(separator: ", "))"
        }
        
        if let themes = parameters.themes, !themes.isEmpty {
            prompt += "\n- Themes: \(themes.joined(separator: ", "))"
        }
        
        prompt += """
        
        Guidelines:
        - Create an engaging story that fits the specified genre and mood
        - Ensure the story is appropriate for the target length
        - Use vivid descriptions and compelling dialogue
        - Create memorable characters with clear motivations
        - Build tension and resolution appropriate to the genre
        - Make the story emotionally resonant and satisfying
        - Avoid explicit content unless specifically requested
        """
        
        return prompt
    }
    
    private func createUserPrompt(prompt: String, parameters: StoryGenerationParameters) -> String {
        var userPrompt = "Please write a story based on this prompt: \(prompt)"
        
        let chapterRange = parameters.length.chapterRange
        userPrompt += "\n\nTarget length: \(chapterRange.lowerBound) to \(chapterRange.upperBound) chapters. Each chapter should be approximately 1000-1300 words."
        
        return userPrompt
    }
    
    private func createFinalStoryPrompt(
        prompt: String,
        selectedPlot: PlotOption,
        storyTitle: String,
        characters: [StoryCharacter],
        parameters: StoryGenerationParameters
    ) -> String {
        var userPrompt = """
        Write a complete story with the following specifications:
        
        Title: \(storyTitle)
        Original Concept: \(prompt)
        Plot Beginning: \(selectedPlot.description)
        Setting: \(selectedPlot.setting)
        
        Characters:
        """
        
        for character in characters {
            userPrompt += "\n- \(character.name): \(character.description)"
        }
        
        let chapterRange = parameters.length.chapterRange
        userPrompt += "\n\nTarget length: \(chapterRange.lowerBound) to \(chapterRange.upperBound) chapters. Each chapter should be approximately 1000-1300 words."
        userPrompt += "\n\nPlease write the complete story incorporating all these elements."
        
        return userPrompt
    }
    
    private func createRequest(
        systemPrompt: String,
        userPrompt: String,
        temperature: Double
    ) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw MistralError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // OpenRouter-specific headers for tracking and optimization
        request.setValue("DreamWeaver/2.0", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("DreamWeaver", forHTTPHeaderField: "X-Title")
        
        let requestBody = MistralRequest(
            model: model,
            messages: [
                MistralMessage(role: "system", content: systemPrompt),
                MistralMessage(role: "user", content: userPrompt)
            ],
            temperature: temperature,
            maxTokens: AppConfig.defaultMaxTokens
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        request.timeoutInterval = AppConfig.generationTimeoutSeconds
        
        print("🌐 Making request to OpenRouter DeepSeek API")
        print("📋 Model: \(model)")
        print("🌡️ Temperature: \(temperature)")
        
        return request
    }
    
    private func extractJSONFromResponse(_ content: String) -> String {
        print("🔍 Raw AI response: \(content.prefix(200))...")
        
        // First, clean up the content by removing markdown code blocks
        var cleanedContent = content
        
        // Remove markdown code blocks (```json and ```)
        cleanedContent = cleanedContent.replacingOccurrences(of: "```json", with: "")
        cleanedContent = cleanedContent.replacingOccurrences(of: "```", with: "")
        
        // Remove any leading backticks that might cause parsing issues
        cleanedContent = cleanedContent.replacingOccurrences(of: "`", with: "")
        
        // Remove any leading/trailing whitespace and newlines
        cleanedContent = cleanedContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("🧹 Cleaned content: \(cleanedContent.prefix(200))...")
        
        // Find the first [ or { character and extract JSON properly
        let startChars: [Character] = ["[", "{"]
        
        var startIndex: String.Index?
        var endIndex: String.Index?
        var bracketCount = 0
        var currentChar: Character?
        
        // Find the start of JSON
        for (index, char) in cleanedContent.enumerated() {
            if startChars.contains(char) {
                startIndex = cleanedContent.index(cleanedContent.startIndex, offsetBy: index)
                currentChar = char
                bracketCount = 1
                break
            }
        }
        
        // Find the matching end bracket
        if let start = startIndex, let startChar = currentChar {
            let matchingEndChar: Character = startChar == "[" ? "]" : "}"
            let searchStart = cleanedContent.index(after: start)
            
            for (index, char) in cleanedContent[searchStart...].enumerated() {
                let actualIndex = cleanedContent.index(searchStart, offsetBy: index)
                
                if char == startChar {
                    bracketCount += 1
                } else if char == matchingEndChar {
                    bracketCount -= 1
                    if bracketCount == 0 {
                        endIndex = cleanedContent.index(after: actualIndex)
                        break
                    }
                }
            }
        }
        
        if let start = startIndex, let end = endIndex {
            let extractedJSON = String(cleanedContent[start..<end])
            print("✅ Extracted JSON: \(extractedJSON.prefix(200))...")
            return extractedJSON
        }
        
        // If we can't extract JSON properly, try to find it with regex as fallback
        let jsonPattern = #"[\[\{].*[\]\}]"#
        if let regex = try? NSRegularExpression(pattern: jsonPattern, options: [.dotMatchesLineSeparators]),
           let match = regex.firstMatch(in: cleanedContent, options: [], range: NSRange(location: 0, length: cleanedContent.count)) {
            let matchedString = String(cleanedContent[Range(match.range, in: cleanedContent)!])
            print("📝 Regex extracted JSON: \(matchedString.prefix(200))...")
            return matchedString
        }
        
        print("⚠️ No valid JSON found, returning cleaned content")
        return cleanedContent
    }
    
    // MARK: - Enhanced API Call Method
    private func makeAPICall(
        systemPrompt: String,
        userPrompt: String,
        temperature: Double
    ) async throws -> String {
        return try await makeAPICallWithRetry(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: temperature,
            retryCount: 0
        )
    }

    private func makeAPICallWithRetry(
        systemPrompt: String,
        userPrompt: String,
        temperature: Double,
        retryCount: Int
    ) async throws -> String {
        do {
            let request = try createRequest(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt,
                temperature: temperature
            )
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MistralError.invalidResponse
            }
            
            // Handle different HTTP status codes
            switch httpResponse.statusCode {
            case 200:
                break // Success, continue processing
            case 429:
                // Rate limit exceeded - retry with longer delay
                if retryCount < RetryConfig.maxRetries {
                    let delay = RetryConfig.rateLimitDelay * Double(retryCount + 1)
                    print("Rate limit exceeded. Retrying in \(delay) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    return try await makeAPICallWithRetry(
                        systemPrompt: systemPrompt,
                        userPrompt: userPrompt,
                        temperature: temperature,
                        retryCount: retryCount + 1
                    )
                }
                throw MistralError.rateLimitExceeded
            case 401:
                throw MistralError.authenticationError
            case 500...599:
                // Server error - retry with exponential backoff
                if retryCount < RetryConfig.maxRetries {
                    let delay = min(RetryConfig.baseDelay * pow(2.0, Double(retryCount)), RetryConfig.maxDelay)
                    print("Server error. Retrying in \(delay) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    return try await makeAPICallWithRetry(
                        systemPrompt: systemPrompt,
                        userPrompt: userPrompt,
                        temperature: temperature,
                        retryCount: retryCount + 1
                    )
                }
                throw MistralError.serverError
            default:
                throw MistralError.apiError(httpResponse.statusCode)
            }
            
            let mistralResponse = try JSONDecoder().decode(MistralResponse.self, from: data)
            
            guard let content = mistralResponse.choices.first?.message.content else {
                throw MistralError.noContent
            }
            
            return content
            
        } catch {
            // If it's already a MistralError, just rethrow it
            if error is MistralError {
                throw error
            }
            
            // For network errors, retry with exponential backoff
            if retryCount < RetryConfig.maxRetries {
                let delay = min(RetryConfig.baseDelay * pow(2.0, Double(retryCount)), RetryConfig.maxDelay)
                print("Network error. Retrying in \(delay) seconds...")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await makeAPICallWithRetry(
                    systemPrompt: systemPrompt,
                    userPrompt: userPrompt,
                    temperature: temperature,
                    retryCount: retryCount + 1
                )
            }
            
            throw MistralError.networkError(error)
        }
    }
}

// MARK: - New Models for Interactive Flow

struct PlotOption: Codable, Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let setting: String
    
    enum CodingKeys: String, CodingKey {
        case title, description, setting
    }
}

struct StoryCharacter: Codable, Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let role: String
    let traits: [String]
    
    enum CodingKeys: String, CodingKey {
        case name, description, role, traits
    }
}

// MARK: - Request/Response Models
struct MistralRequest: Codable {
    let model: String
    let messages: [MistralMessage]
    let temperature: Double
    let maxTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
    }
}

struct MistralMessage: Codable {
    let role: String
    let content: String
}

struct MistralResponse: Codable {
    let choices: [MistralChoice]
    let usage: MistralUsage?
}

struct MistralChoice: Codable {
    let message: MistralMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case message
        case finishReason = "finish_reason"
    }
}

struct MistralUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - Errors
enum MistralError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(Int)
    case noContent
    case networkError(Error)
    case rateLimitExceeded
    case serverError
    case authenticationError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid API response"
        case .apiError(let code):
            switch code {
            case 429:
                return "Rate limit exceeded. Please wait a moment and try again."
            case 401:
                return "Authentication failed. Please check your API key."
            case 500...599:
                return "Server error. Please try again later."
            default:
                return "API error with code: \(code)"
            }
        case .noContent:
            return "No content received from API"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "Too many requests. Please wait a moment before trying again."
        case .serverError:
            return "Server is temporarily unavailable. Please try again in a few minutes."
        case .authenticationError:
            return "Authentication failed. Please check your API configuration."
        }
    }
}

// MARK: - Retry Configuration
private struct RetryConfig {
    static let maxRetries = 3
    static let baseDelay: TimeInterval = 2.0
    static let maxDelay: TimeInterval = 30.0
    static let rateLimitDelay: TimeInterval = 10.0
} 