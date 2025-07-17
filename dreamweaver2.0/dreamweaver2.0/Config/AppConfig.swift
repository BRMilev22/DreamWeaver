import Foundation

// MARK: - Enums
enum TTSEngine {
    case openAI
    case system
}

struct AppConfig {
    // MARK: - API Keys
    static let mistralAPIKey = "vDz1BTqxFsLCDZyFU4WcrJZaSJPsmlJa" // Legacy - keeping for fallback
    static let openAIAPIKey = "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"
    static let openRouterAPIKey = "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"
    
    // MARK: - Supabase Configuration
    static let supabaseURL = "https://enwlwefyqahsnemroivs.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVud2x3ZWZ5cWFoc25lbXJvaXZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIzMjgwODgsImV4cCI6MjA2NzkwNDA4OH0.AxH-IFLs2dorWNvTPmsnjJfDWutjaYTlTyA9zZG_Ux0"
    
    // MARK: - Story Generation API Configuration (OpenRouter + DeepSeek)
    static let storyGenerationBaseURL = "https://openrouter.ai/api/v1"
    static let storyGenerationModel = "deepseek/deepseek-chat-v3-0324"
    static let storyGenerationAPIKey = openRouterAPIKey
    
    // MARK: - Legacy Mistral Configuration (Fallback)
    static let mistralBaseURL = "https://api.mistral.ai/v1" 
    static let mistralModel = "mistral-small-latest"
    
    // MARK: - TTS Configuration
    static let preferredTTSEngine: TTSEngine = .openAI // Use OpenAI for high quality
    static let openAITTSModel = "tts-1-hd" // High quality model
    static let preferredOpenAIVoice = "nova" // Warm, engaging voice for storytelling
    static let speechRate: Float = 0.55 // Natural speaking rate
    static let speechPitch: Float = 1.1 // Slightly warmer pitch
    static let speechVolume: Float = 0.9 // Comfortable volume level
    
    // MARK: - App Configuration
    static let appName = "DreamWeaver"
    static let appVersion = "1.0.0"
    static let maxStoriesPerUser = 100
    static let maxStoryLength = 10000
    static let defaultStoryLength = StoryLength.medium
    static let defaultGenre = StoryGenre.romance
    static let defaultMood = StoryMood.lighthearted
    
    // MARK: - Generation Settings
    static let defaultTemperature = 0.7
    static let defaultMaxTokens = 8000  // DeepSeek V3 can handle much longer outputs
    static let generationTimeoutSeconds = 120.0  // Longer timeout for complex stories
    
    // MARK: - UI Configuration
    static let primaryColor = "AccentColor"
    static let animationDuration = 0.3
    static let cornerRadius = 12.0
    
    // MARK: - Validation
    static func validateConfiguration() -> Bool {
        guard supabaseURL != "https://your-project-id.supabase.co" else {
            print("⚠️ Please update Supabase URL in AppConfig.swift")
            return false
        }
        
        guard supabaseAnonKey != "your-anon-key-here" else {
            print("⚠️ Please update Supabase anon key in AppConfig.swift")
            return false
        }
        
        guard !mistralAPIKey.isEmpty else {
            print("⚠️ Mistral API key is empty")
            return false
        }
        
        guard openAIAPIKey != "YOUR_OPENAI_API_KEY_HERE" && !openAIAPIKey.isEmpty else {
            print("⚠️ Please update OpenAI API key in AppConfig.swift")
            return false
        }
        
        guard !openRouterAPIKey.isEmpty && openRouterAPIKey.hasPrefix("sk-or-") else {
            print("⚠️ Please update OpenRouter API key in AppConfig.swift")
            return false
        }
        
        return true
    }
}

// MARK: - Environment Configuration
extension AppConfig {
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var isProduction: Bool {
        return !isDebug
    }
}