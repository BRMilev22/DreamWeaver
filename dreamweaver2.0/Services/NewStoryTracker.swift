import Foundation

class NewStoryTracker: ObservableObject {
    static let shared = NewStoryTracker()
    
    @Published private var newlyGeneratedStoryIds: Set<UUID> = []
    
    private init() {}
    
    func markAsNewlyGenerated(_ storyId: UUID) {
        newlyGeneratedStoryIds.insert(storyId)
    }
    
    func isNewlyGenerated(_ storyId: UUID) -> Bool {
        return newlyGeneratedStoryIds.contains(storyId)
    }
    
    func markAsViewed(_ storyId: UUID) {
        newlyGeneratedStoryIds.remove(storyId)
    }
    
    func clearAll() {
        newlyGeneratedStoryIds.removeAll()
    }
} 