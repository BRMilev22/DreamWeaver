import Foundation

struct AppConfig {
    // MARK: - API Keys
    static let mistralAPIKey = "vDz1BTqxFsLCDZyFU4WcrJZaSJPsmlJa"
    
    // MARK: - Supabase Configuration
    static let supabaseURL = "https://enwlwefyqahsnemroivs.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVud2x3ZWZ5cWFoc25lbXJvaXZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIzMjgwODgsImV4cCI6MjA2NzkwNDA4OH0.AxH-IFLs2dorWNvTPmsnjJfDWutjaYTlTyA9zZG_Ux0"
    
    // MARK: - Mistral API Configuration
    static let mistralBaseURL = "https://api.mistral.ai/v1"
    static let mistralModel = "mistral-small-latest"
    
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
    static let defaultMaxTokens = 2000
    static let generationTimeoutSeconds = 60.0
    
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