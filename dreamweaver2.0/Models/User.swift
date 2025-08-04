import Foundation

// MARK: - User Model (matches database profile table)
struct User: Codable, Identifiable {
    let id: UUID
    let userId: UUID // References auth.users.id
    let email: String
    let username: String?
    let displayName: String?
    let bio: String?
    let avatarUrl: String?
    let isPublic: Bool
    let storiesCount: Int
    let followersCount: Int
    let followingCount: Int
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case email
        case username
        case displayName = "display_name"
        case bio
        case avatarUrl = "avatar_url"
        case isPublic = "is_public"
        case storiesCount = "stories_count"
        case followersCount = "followers_count"
        case followingCount = "following_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: UUID = UUID(), userId: UUID, email: String, username: String? = nil, displayName: String? = nil, bio: String? = nil, avatarUrl: String? = nil, isPublic: Bool = true, storiesCount: Int = 0, followersCount: Int = 0, followingCount: Int = 0, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.email = email
        self.username = username
        self.displayName = displayName
        self.bio = bio
        self.avatarUrl = avatarUrl
        self.isPublic = isPublic
        self.storiesCount = storiesCount
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
} 