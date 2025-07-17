import Foundation

// MARK: - Chapter Model
struct Chapter: Codable, Identifiable, Equatable {
    let id: UUID
    let storyId: UUID
    let chapterNumber: Int
    let title: String?
    let content: String
    let wordsCount: Int
    let readingTime: Int // in minutes
    let generationPrompt: String?
    let contextFromPreviousChapters: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case storyId = "story_id"
        case chapterNumber = "chapter_number"
        case title
        case content
        case wordsCount = "words_count"
        case readingTime = "reading_time"
        case generationPrompt = "generation_prompt"
        case contextFromPreviousChapters = "context_from_previous_chapters"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: UUID = UUID(), storyId: UUID, chapterNumber: Int, title: String? = nil, content: String, wordsCount: Int = 0, readingTime: Int = 0, generationPrompt: String? = nil, contextFromPreviousChapters: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.storyId = storyId
        self.chapterNumber = chapterNumber
        self.title = title
        self.content = content
        self.wordsCount = wordsCount
        self.readingTime = readingTime
        self.generationPrompt = generationPrompt
        self.contextFromPreviousChapters = contextFromPreviousChapters
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Updated Story Model (without single content field)
struct Story: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    let title: String
    let summary: String?
    let genre: StoryGenre
    let mood: StoryMood
    let isPublished: Bool
    let isPremium: Bool
    let likesCount: Int
    let viewsCount: Int
    let totalWordsCount: Int // Total words across all chapters
    let totalReadingTime: Int // Total reading time across all chapters
    let chaptersCount: Int // Number of chapters
    let createdAt: Date
    let updatedAt: Date
    let publishedAt: Date?
    
    // Metadata for generation
    let generationPrompt: String?
    let generationParameters: StoryGenerationParameters?
    
    // Chapters (loaded separately for performance)
    var chapters: [Chapter]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case summary
        case genre
        case mood
        case isPublished = "is_published"
        case isPremium = "is_premium"
        case likesCount = "likes_count"
        case viewsCount = "views_count"
        case totalWordsCount = "total_words_count"
        case totalReadingTime = "total_reading_time"
        case chaptersCount = "chapters_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case publishedAt = "published_at"
        case generationPrompt = "generation_prompt"
        case generationParameters = "generation_parameters"
        case chapters
    }
    
    init(id: UUID = UUID(), userId: UUID, title: String, summary: String? = nil, genre: StoryGenre, mood: StoryMood, isPublished: Bool = false, isPremium: Bool = false, likesCount: Int = 0, viewsCount: Int = 0, totalWordsCount: Int = 0, totalReadingTime: Int = 0, chaptersCount: Int = 0, createdAt: Date = Date(), updatedAt: Date = Date(), publishedAt: Date? = nil, generationPrompt: String? = nil, generationParameters: StoryGenerationParameters? = nil, chapters: [Chapter]? = nil) {
        self.id = id
        self.userId = userId
        self.title = title
        self.summary = summary
        self.genre = genre
        self.mood = mood
        self.isPublished = isPublished
        self.isPremium = isPremium
        self.likesCount = likesCount
        self.viewsCount = viewsCount
        self.totalWordsCount = totalWordsCount
        self.totalReadingTime = totalReadingTime
        self.chaptersCount = chaptersCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.publishedAt = publishedAt
        self.generationPrompt = generationPrompt
        self.generationParameters = generationParameters
        self.chapters = chapters
    }
    
    // Custom decoder to handle missing fields from old stories
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields that should always be present
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        title = try container.decode(String.self, forKey: .title)
        
        // Handle genre with fallback
        if let genreString = try? container.decode(String.self, forKey: .genre),
           let genreValue = StoryGenre(rawValue: genreString) {
            genre = genreValue
        } else {
            genre = .fantasy // Default fallback
        }
        
        // Handle mood with fallback
        if let moodString = try? container.decode(String.self, forKey: .mood),
           let moodValue = StoryMood(rawValue: moodString) {
            mood = moodValue
        } else {
            mood = .mysterious // Default fallback
        }
        
        // Optional fields
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        
        // Fields with defaults for backward compatibility
        isPublished = try container.decodeIfPresent(Bool.self, forKey: .isPublished) ?? false
        isPremium = try container.decodeIfPresent(Bool.self, forKey: .isPremium) ?? false
        likesCount = try container.decodeIfPresent(Int.self, forKey: .likesCount) ?? 0
        viewsCount = try container.decodeIfPresent(Int.self, forKey: .viewsCount) ?? 0
        totalWordsCount = try container.decodeIfPresent(Int.self, forKey: .totalWordsCount) ?? 0
        totalReadingTime = try container.decodeIfPresent(Int.self, forKey: .totalReadingTime) ?? 0
        chaptersCount = try container.decodeIfPresent(Int.self, forKey: .chaptersCount) ?? 0
        
        // Date fields with defaults
        if let createdAtString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            createdAt = formatter.date(from: createdAtString) ?? Date()
        } else {
            createdAt = Date()
        }
        
        if let updatedAtString = try? container.decode(String.self, forKey: .updatedAt) {
            let formatter = ISO8601DateFormatter()
            updatedAt = formatter.date(from: updatedAtString) ?? Date()
        } else {
            updatedAt = Date()
        }
        
        if let publishedAtString = try? container.decodeIfPresent(String.self, forKey: .publishedAt) {
            let formatter = ISO8601DateFormatter()
            publishedAt = formatter.date(from: publishedAtString)
        } else {
            publishedAt = nil
        }
        
        // Optional metadata
        generationPrompt = try container.decodeIfPresent(String.self, forKey: .generationPrompt)
        generationParameters = try container.decodeIfPresent(StoryGenerationParameters.self, forKey: .generationParameters)
        chapters = try container.decodeIfPresent([Chapter].self, forKey: .chapters)
    }
}

// MARK: - Story Generation Parameters
struct StoryGenerationParameters: Codable, Equatable {
    let genre: StoryGenre
    let mood: StoryMood
    let length: StoryLength
    let characters: [String]?
    let setting: String?
    let themes: [String]?
    let style: WritingStyle?
    let temperature: Double? // AI creativity level
    let maxTokens: Int?
    let pointOfView: PointOfView
    
    enum CodingKeys: String, CodingKey {
        case genre
        case mood
        case length
        case characters
        case setting
        case themes
        case style
        case temperature
        case maxTokens = "max_tokens"
        case pointOfView = "point_of_view"
    }
    
    // Standard initializer
    init(genre: StoryGenre, mood: StoryMood, length: StoryLength, characters: [String]? = nil, setting: String? = nil, themes: [String]? = nil, style: WritingStyle? = nil, temperature: Double? = nil, maxTokens: Int? = nil, pointOfView: PointOfView) {
        self.genre = genre
        self.mood = mood
        self.length = length
        self.characters = characters
        self.setting = setting
        self.themes = themes
        self.style = style
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.pointOfView = pointOfView
    }
    
    // Custom decoder to handle missing point_of_view field from older stories
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields with fallbacks for backward compatibility
        if let genreString = try? container.decode(String.self, forKey: .genre),
           let genreValue = StoryGenre(rawValue: genreString) {
            genre = genreValue
        } else {
            genre = .fantasy // Default fallback
        }
        
        if let moodString = try? container.decode(String.self, forKey: .mood),
           let moodValue = StoryMood(rawValue: moodString) {
            mood = moodValue
        } else {
            mood = .mysterious // Default fallback
        }
        
        if let lengthString = try? container.decode(String.self, forKey: .length),
           let lengthValue = StoryLength(rawValue: lengthString) {
            length = lengthValue
        } else {
            length = .medium // Default fallback
        }
        
        // Optional fields
        characters = try container.decodeIfPresent([String].self, forKey: .characters)
        setting = try container.decodeIfPresent(String.self, forKey: .setting)
        themes = try container.decodeIfPresent([String].self, forKey: .themes)
        
        if let styleString = try? container.decodeIfPresent(String.self, forKey: .style),
           let styleValue = WritingStyle(rawValue: styleString) {
            style = styleValue
        } else {
            style = nil
        }
        
        temperature = try container.decodeIfPresent(Double.self, forKey: .temperature)
        maxTokens = try container.decodeIfPresent(Int.self, forKey: .maxTokens)
        
        // Handle missing point_of_view field with default
        if let pointOfViewString = try? container.decodeIfPresent(String.self, forKey: .pointOfView),
           let pointOfViewValue = PointOfView(rawValue: pointOfViewString) {
            pointOfView = pointOfViewValue
        } else {
            pointOfView = .third // Default to third person for older stories
        }
    }
}

// MARK: - Point of View
enum PointOfView: String, Codable, CaseIterable {
    case first = "first"
    case third = "third"
    
    var displayName: String {
        switch self {
        case .first: return "1st"
        case .third: return "3rd"
        }
    }
}

// MARK: - Chapter Generation Parameters
struct ChapterGenerationParameters: Codable {
    let storyId: UUID
    let chapterNumber: Int
    let userPrompt: String
    let previousChaptersContext: String
    let originalStoryParameters: StoryGenerationParameters
    let targetWordCount: Int // 1000-1300 words per chapter as noted in sketch
    
    enum CodingKeys: String, CodingKey {
        case storyId = "story_id"
        case chapterNumber = "chapter_number"
        case userPrompt = "user_prompt"
        case previousChaptersContext = "previous_chapters_context"
        case originalStoryParameters = "original_story_parameters"
        case targetWordCount = "target_word_count"
    }
}

enum StoryGenre: String, Codable, CaseIterable {
    case romance = "romance"
    case fantasy = "fantasy"
    case mystery = "mystery"
    case sciFi = "sci_fi"
    case horror = "horror"
    case thriller = "thriller"
    case adventure = "adventure"
    case drama = "drama"
    case comedy = "comedy"
    case historical = "historical"
    case contemporary = "contemporary"
    case paranormal = "paranormal"
    
    var displayName: String {
        switch self {
        case .romance: return "Romance"
        case .fantasy: return "Fantasy"
        case .mystery: return "Mystery"
        case .sciFi: return "Sci-Fi"
        case .horror: return "Horror"
        case .thriller: return "Thriller"
        case .adventure: return "Adventure"
        case .drama: return "Drama"
        case .comedy: return "Comedy"
        case .historical: return "Historical"
        case .contemporary: return "Contemporary"
        case .paranormal: return "Paranormal"
        }
    }
    
    var emoji: String {
        switch self {
        case .romance: return "💕"
        case .fantasy: return "🐉"
        case .mystery: return "🔍"
        case .sciFi: return "🚀"
        case .horror: return "👻"
        case .thriller: return "😱"
        case .adventure: return "🗡️"
        case .drama: return "🎭"
        case .comedy: return "😂"
        case .historical: return "🏛️"
        case .contemporary: return "🌆"
        case .paranormal: return "🔮"
        }
    }
}

enum StoryMood: String, Codable, CaseIterable {
    case lighthearted = "lighthearted"
    case serious = "serious"
    case mysterious = "mysterious"
    case romantic = "romantic"
    case dark = "dark"
    case humorous = "humorous"
    case intense = "intense"
    case melancholic = "melancholic"
    case uplifting = "uplifting"
    case suspenseful = "suspenseful"
    
    var displayName: String {
        switch self {
        case .lighthearted: return "Lighthearted"
        case .serious: return "Serious"
        case .mysterious: return "Mysterious"
        case .romantic: return "Romantic"
        case .dark: return "Dark"
        case .humorous: return "Humorous"
        case .intense: return "Intense"
        case .melancholic: return "Melancholic"
        case .uplifting: return "Uplifting"
        case .suspenseful: return "Suspenseful"
        }
    }
}

enum StoryLength: String, Codable, CaseIterable {
    case short = "short"        // 1-2 chapters
    case medium = "medium"      // 3-5 chapters
    case long = "long"          // 6-10 chapters
    case novella = "novella"    // 10+ chapters
    
    var displayName: String {
        switch self {
        case .short: return "Short (1-2 chapters)"
        case .medium: return "Medium (3-5 chapters)"
        case .long: return "Long (6-10 chapters)"
        case .novella: return "Novella (10+ chapters)"
        }
    }
    
    var chapterRange: ClosedRange<Int> {
        switch self {
        case .short: return 1...2
        case .medium: return 3...5
        case .long: return 6...10
        case .novella: return 10...20
        }
    }
}

enum WritingStyle: String, Codable, CaseIterable {
    case descriptive = "descriptive"
    case dialogue_heavy = "dialogue_heavy"
    case action_packed = "action_packed"
    case introspective = "introspective"
    case poetic = "poetic"
    case minimalist = "minimalist"
    case verbose = "verbose"
    
    var displayName: String {
        switch self {
        case .descriptive: return "Descriptive"
        case .dialogue_heavy: return "Dialogue Heavy"
        case .action_packed: return "Action Packed"
        case .introspective: return "Introspective"
        case .poetic: return "Poetic"
        case .minimalist: return "Minimalist"
        case .verbose: return "Verbose"
        }
    }
} 