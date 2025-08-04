import Foundation
import Supabase
import Auth
import PostgREST
import Combine

class SupabaseService: ObservableObject {
    private let client: SupabaseClient
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: AppConfig.supabaseURL)!,
            supabaseKey: AppConfig.supabaseAnonKey
        )
        
        // Listen for auth state changes
        Task {
            await checkAuthState()
        }
    }
    
    // MARK: - Authentication
    
    @MainActor
    func checkAuthState() async {
        do {
            let user = try await client.auth.user()
            
            // Ensure profile exists for authenticated user
            await ensureProfileExists(for: user)
            
            self.currentUser = convertAuthUser(user)
            self.isAuthenticated = true
        } catch {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    func signUp(email: String, password: String, username: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let authResponse = try await client.auth.signUp(
            email: email,
            password: password
        )
        
        // Only create profile if user is confirmed (no email confirmation required)
        // or if we have a valid session
        if authResponse.session != nil {
            try await createUserProfile(userId: authResponse.user.id, email: email, username: username)
        }
        // If email confirmation is required, we'll create the profile later when user confirms
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let session = try await client.auth.signIn(email: email, password: password)
        
        // Check if profile exists, create if not
        await ensureProfileExists(for: session.user)
        
        await MainActor.run {
            self.currentUser = convertAuthUser(session.user)
            self.isAuthenticated = true
        }
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
        
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    // MARK: - User Profile Management
    
    private func ensureProfileExists(for user: Auth.User) async {
        do {
            // Check if profile exists
            let _: [User] = try await client
                .from("profiles")
                .select()
                .eq("user_id", value: user.id.uuidString)
                .execute()
                .value
            
            // If we get here, profile exists, no need to create
        } catch {
            // Profile doesn't exist, create it
            do {
                let username = user.userMetadata["username"]?.stringValue ?? user.email?.components(separatedBy: "@").first ?? "User"
                try await createUserProfile(userId: user.id, email: user.email ?? "", username: username)
            } catch {
                print("Failed to create profile: \(error)")
            }
        }
    }
    
    private func createUserProfile(userId: UUID, email: String, username: String) async throws {
        let profile = User(
            id: UUID(),
            userId: userId,
            email: email,
            username: username,
            displayName: username,
            bio: nil,
            avatarUrl: nil,
            isPublic: true,
            storiesCount: 0,
            followersCount: 0,
            followingCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await client
            .from("profiles")
            .insert(profile)
            .execute()
    }
    
    func getUserProfile(userId: UUID) async throws -> User {
        let response: [User] = try await client
            .from("profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        guard let profile = response.first else {
            throw NSError(domain: "SupabaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Profile not found"])
        }
        
        return profile
    }
    
    func updateUserProfile(_ profile: User) async throws {
        try await client
            .from("profiles")
            .update(profile)
            .eq("user_id", value: profile.userId.uuidString)
            .execute()
    }
    
    // MARK: - Data Migration
    
    func migrateOldStoriesToChapterStructure() async throws {
        // Get all stories that might need migration (stories with chapters_count = 0)
        let response: [Story] = try await client
            .from("stories")
            .select()
            .execute()
            .value
        
        for story in response {
            // Check if story has chapters_count = 0 or null, indicating old structure
            let chaptersCount = story.chaptersCount
            
            if chaptersCount == 0 {
                // Check if there are any existing chapters for this story
                let existingChapters = try await getChapters(for: story.id)
                
                if existingChapters.isEmpty {
                    // Create a placeholder chapter for stories that were created with old structure
                    // but the content was lost during schema migration
                    await createPlaceholderChapter(storyId: story.id, storyTitle: story.title)
                }
            }
        }
    }
    
    private func createPlaceholderChapter(storyId: UUID, storyTitle: String) async {
        do {
            // Create a placeholder chapter for stories that lost their content during migration
            let placeholderContent = """
            This story was created before the chapter system was implemented. 
            The original content may have been lost during the migration to the new system.
            
            You can edit this story to add new content or generate new chapters using AI.
            """
            
            let wordCount = placeholderContent.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
            let readingTime = max(1, wordCount / 200) // Assume 200 words per minute
            
            // Create the first chapter with placeholder content
            let chapter = Chapter(
                storyId: storyId,
                chapterNumber: 1,
                title: "Chapter 1",
                content: placeholderContent,
                wordsCount: wordCount,
                readingTime: readingTime
            )
            
            // Insert the chapter
            try await client
                .from("chapters")
                .insert(chapter)
                .execute()
            
            // Update story stats
            try await client
                .from("stories")
                .update([
                    "total_words_count": wordCount,
                    "total_reading_time": readingTime,
                    "chapters_count": 1
                ])
                .eq("id", value: storyId.uuidString)
                .execute()
            
            print("Created placeholder chapter for story \(storyId)")
        } catch {
            print("Failed to create placeholder chapter for story \(storyId): \(error)")
        }
    }
    
    // MARK: - Story Management
    
    func createStory(_ story: Story) async throws -> Story {
        let response: [Story] = try await client
            .from("stories")
            .insert(story)
            .select()
            .execute()
            .value
        
        guard let createdStory = response.first else {
            throw NSError(domain: "SupabaseService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create story"])
        }
        
        return createdStory
    }
    
    func updateStory(_ story: Story) async throws {
        try await client
            .from("stories")
            .update(story)
            .eq("id", value: story.id.uuidString)
            .execute()
    }
    
    func deleteStory(id: UUID) async throws {
        try await client
            .from("stories")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    func getUserStories(userId: UUID, limit: Int = 20, offset: Int = 0) async throws -> [Story] {
        print("🔍 DEBUG: Starting getUserStories for userId: \(userId)")
        
        do {
            let response: [Story] = try await client
                .from("stories")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .limit(limit)
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value
            
            print("✅ Successfully loaded \(response.count) stories from database")
            return await processStoriesWithChapters(response)
            
        } catch {
            print("❌ Error in getUserStories: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error details: \(error.localizedDescription)")
            
            // Try to provide more helpful error information
            if let decodingError = error as? DecodingError {
                print("❌ This is a DecodingError - issue with parsing Story model")
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("❌ Missing key: \(key) in context: \(context)")
                case .typeMismatch(let type, let context):
                    print("❌ Type mismatch for type: \(type) in context: \(context)")
                case .valueNotFound(let type, let context):
                    print("❌ Value not found for type: \(type) in context: \(context)")
                case .dataCorrupted(let context):
                    print("❌ Data corrupted in context: \(context)")
                @unknown default:
                    print("❌ Unknown decoding error")
                }
            }
            
            throw error
        }
    }
    
    private func processStoriesWithChapters(_ stories: [Story]) async -> [Story] {
        // Fetch chapters for each story and handle migration if needed
        var storiesWithChapters: [Story] = []
        for var story in stories {
            do {
                let chapters = try await getChapters(for: story.id)
                
                // If no chapters exist and chapters_count is 0, try migration
                if chapters.isEmpty && story.chaptersCount == 0 {
                    await createPlaceholderChapter(storyId: story.id, storyTitle: story.title)
                    // Fetch chapters again after migration
                    let newChapters = try await getChapters(for: story.id)
                    story.chapters = newChapters
                } else {
                    story.chapters = chapters
                }
                
                storiesWithChapters.append(story)
            } catch {
                print("Failed to fetch chapters for story \(story.id): \(error)")
                // Still include the story even if chapters fail to load
                storiesWithChapters.append(story)
            }
        }
        
        return storiesWithChapters
    }
    

    
    func getPublishedStories(limit: Int = 20, offset: Int = 0) async throws -> [Story] {
        let response: [Story] = try await client
            .from("stories")
            .select()
            .eq("is_published", value: true)
            .order("created_at", ascending: false)
            .limit(limit)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        // Fetch chapters for each story
        var storiesWithChapters: [Story] = []
        for var story in response {
            do {
                let chapters = try await getChapters(for: story.id)
                story.chapters = chapters
                storiesWithChapters.append(story)
            } catch {
                print("Failed to fetch chapters for story \(story.id): \(error)")
                // Still include the story even if chapters fail to load
                storiesWithChapters.append(story)
            }
        }
        
        return storiesWithChapters
    }
    
    func getStoriesByGenre(_ genre: StoryGenre, limit: Int = 20, offset: Int = 0) async throws -> [Story] {
        let response: [Story] = try await client
            .from("stories")
            .select()
            .eq("is_published", value: true)
            .eq("genre", value: genre.rawValue)
            .order("created_at", ascending: false)
            .limit(limit)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        // Fetch chapters for each story
        var storiesWithChapters: [Story] = []
        for var story in response {
            do {
                let chapters = try await getChapters(for: story.id)
                story.chapters = chapters
                storiesWithChapters.append(story)
            } catch {
                print("Failed to fetch chapters for story \(story.id): \(error)")
                // Still include the story even if chapters fail to load
                storiesWithChapters.append(story)
            }
        }
        
        return storiesWithChapters
    }
    
    func searchStories(query: String, limit: Int = 20) async throws -> [Story] {
        let response: [Story] = try await client
            .from("stories")
            .select()
            .eq("is_published", value: true)
            .textSearch("title", query: query)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        // Fetch chapters for each story
        var storiesWithChapters: [Story] = []
        for var story in response {
            do {
                let chapters = try await getChapters(for: story.id)
                story.chapters = chapters
                storiesWithChapters.append(story)
            } catch {
                print("Failed to fetch chapters for story \(story.id): \(error)")
                // Still include the story even if chapters fail to load
                storiesWithChapters.append(story)
            }
        }
        
        return storiesWithChapters
    }
    
    // MARK: - Chapter Management
    
    func createChapter(_ chapter: Chapter) async throws -> Chapter {
        let response: [Chapter] = try await client
            .from("chapters")
            .insert(chapter)
            .select()
            .execute()
            .value
        
        guard let createdChapter = response.first else {
            throw NSError(domain: "SupabaseService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create chapter"])
        }
        
        // Update story's chapter count and total stats
        try await updateStoryStats(storyId: chapter.storyId)
        
        return createdChapter
    }
    
    func getChapters(for storyId: UUID) async throws -> [Chapter] {
        let response: [Chapter] = try await client
            .from("chapters")
            .select()
            .eq("story_id", value: storyId.uuidString)
            .order("chapter_number", ascending: true)
            .execute()
            .value
        
        return response
    }
    
    func getChapter(storyId: UUID, chapterNumber: Int) async throws -> Chapter? {
        let response: [Chapter] = try await client
            .from("chapters")
            .select()
            .eq("story_id", value: storyId.uuidString)
            .eq("chapter_number", value: chapterNumber)
            .execute()
            .value
        
        return response.first
    }
    
    func updateChapter(_ chapter: Chapter) async throws {
        try await client
            .from("chapters")
            .update(chapter)
            .eq("id", value: chapter.id.uuidString)
            .execute()
        
        // Update story stats after chapter update
        try await updateStoryStats(storyId: chapter.storyId)
    }
    
    func deleteChapter(id: UUID, storyId: UUID) async throws {
        try await client
            .from("chapters")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
        
        // Update story stats after chapter deletion
        try await updateStoryStats(storyId: storyId)
    }
    
    func getStoryWithChapters(storyId: UUID) async throws -> Story {
        // Get story
        let storyResponse: [Story] = try await client
            .from("stories")
            .select()
            .eq("id", value: storyId.uuidString)
            .execute()
            .value
        
        guard var story = storyResponse.first else {
            throw NSError(domain: "SupabaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Story not found"])
        }
        
        // Get chapters
        let chapters = try await getChapters(for: storyId)
        story.chapters = chapters
        
        return story
    }
    
    private func updateStoryStats(storyId: UUID) async throws {
        // Get all chapters for this story
        let chapters = try await getChapters(for: storyId)
        
        let totalWords = chapters.reduce(0) { $0 + $1.wordsCount }
        let totalReadingTime = chapters.reduce(0) { $0 + $1.readingTime }
        let chaptersCount = chapters.count
        
        // Update story with new stats
        try await client
            .from("stories")
            .update([
                "total_words_count": totalWords,
                "total_reading_time": totalReadingTime,
                "chapters_count": chaptersCount
            ])
            .eq("id", value: storyId.uuidString)
            .execute()
    }
    
    // MARK: - Helper Methods
    
    private func convertAuthUser(_ authUser: Auth.User) -> User {
        return User(
            id: UUID(), // Generate new UUID for profile record
            userId: authUser.id, // Reference to auth.users.id
            email: authUser.email ?? "",
            username: authUser.userMetadata["username"]?.stringValue,
            displayName: authUser.userMetadata["display_name"]?.stringValue,
            bio: nil,
            avatarUrl: authUser.userMetadata["avatar_url"]?.stringValue,
            isPublic: true,
            storiesCount: 0,
            followersCount: 0,
            followingCount: 0,
            createdAt: authUser.createdAt,
            updatedAt: authUser.updatedAt ?? Date()
        )
    }
}

// MARK: - Database Schema Creation
extension SupabaseService {
    static func createDatabaseSchema() -> String {
        return """
        -- Enable UUID extension
        CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
        
        -- Create profiles table
        CREATE TABLE IF NOT EXISTS profiles (
            id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            email TEXT NOT NULL,
            username TEXT UNIQUE,
            display_name TEXT,
            bio TEXT,
            avatar_url TEXT,
            is_public BOOLEAN DEFAULT true,
            stories_count INTEGER DEFAULT 0,
            followers_count INTEGER DEFAULT 0,
            following_count INTEGER DEFAULT 0,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
        );
        
        -- Create stories table
        CREATE TABLE IF NOT EXISTS stories (
            id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            summary TEXT,
            genre TEXT NOT NULL,
            mood TEXT NOT NULL,
            is_published BOOLEAN DEFAULT false,
            is_premium BOOLEAN DEFAULT false,
            likes_count INTEGER DEFAULT 0,
            views_count INTEGER DEFAULT 0,
            words_count INTEGER DEFAULT 0,
            reading_time INTEGER DEFAULT 0,
            generation_prompt TEXT,
            generation_parameters JSONB,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
            published_at TIMESTAMP WITH TIME ZONE
        );
        
        -- Create indexes
        CREATE INDEX IF NOT EXISTS idx_stories_user_id ON stories(user_id);
        CREATE INDEX IF NOT EXISTS idx_stories_published ON stories(is_published);
        CREATE INDEX IF NOT EXISTS idx_stories_genre ON stories(genre);
        CREATE INDEX IF NOT EXISTS idx_stories_created_at ON stories(created_at);
        CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
        CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);
        
        -- Enable Row Level Security
        ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
        ALTER TABLE stories ENABLE ROW LEVEL SECURITY;
        
        -- Create policies
        CREATE POLICY "Public profiles are viewable by everyone" ON profiles FOR SELECT USING (is_public = true);
        CREATE POLICY "Users can view their own profile" ON profiles FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "Users can update their own profile" ON profiles FOR UPDATE USING (auth.uid() = user_id);
        CREATE POLICY "Users can insert their own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = user_id);
        
        CREATE POLICY "Published stories are viewable by everyone" ON stories FOR SELECT USING (is_published = true);
        CREATE POLICY "Users can view their own stories" ON stories FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "Users can insert their own stories" ON stories FOR INSERT WITH CHECK (auth.uid() = user_id);
        CREATE POLICY "Users can update their own stories" ON stories FOR UPDATE USING (auth.uid() = user_id);
        CREATE POLICY "Users can delete their own stories" ON stories FOR DELETE USING (auth.uid() = user_id);
        
        -- Create functions for updated_at
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.updated_at = timezone('utc'::text, now());
            RETURN NEW;
        END;
        $$ language 'plpgsql';
        
        -- Create triggers
        CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
        CREATE TRIGGER update_stories_updated_at BEFORE UPDATE ON stories FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
        """
    }
} 
