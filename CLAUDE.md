# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DreamWeaver 2.0 is a native iOS storytelling app built with SwiftUI that uses AI to generate compelling narratives. The app integrates with Supabase for backend services and multiple AI providers (primarily DeepSeek via OpenRouter) for story generation.

## Development Commands

### Build and Run
- Open `dreamweaver2.0/dreamweaver2.0.xcodeproj` in Xcode
- Select target device (iOS Simulator or physical device)
- Press `Cmd+R` to build and run
- Minimum deployment target: iOS 18.5

### Testing
- Unit tests: `Cmd+U` in Xcode (target: dreamweaver2.0Tests)
- UI tests: Available through dreamweaver2.0UITests target
- No automated test scripts found - tests are run through Xcode

### Dependencies
- Supabase Swift SDK (v2.0.0+) - managed through Swift Package Manager
- No other external dependencies or build tools required

## Architecture Overview

### Core Structure
- **App Entry Point**: `dreamweaver2_0App.swift` → `ModernTabView` (main navigation)
- **Data Layer**: Supabase integration with PostgreSQL backend
- **AI Integration**: DeepSeek V3 model via OpenRouter API (with Mistral fallback)
- **Story System**: Chapter-based stories with interactive generation flow

### Key Components

#### Models (`Models/`)
- `Story.swift`: Core story model with chapter system
- `User.swift`: User profile and authentication
- Support for both single-content stories (legacy) and chapter-based stories

#### Services (`Services/`)
- `SupabaseService.swift`: Database operations, authentication, story/chapter management
- `MistralService.swift`: AI story generation (actually uses DeepSeek via OpenRouter)
- `VoiceService.swift`: Voice/audio features
- `NewStoryTracker.swift`: Story creation tracking

#### Views (`Views/`)
- `ModernCreateStoryView.swift`: Main story creation interface
- `StoryGenerationFlowView.swift`: Interactive story generation wizard
- `ModernReadingView.swift`: Story reading interface with chapter navigation
- `ModernMyStoriesView.swift`: User's story library
- `ModernAuthenticationView.swift`: Login/signup flows

#### Configuration (`Config/`)
- `AppConfig.swift`: API keys, Supabase config, generation settings
- `DesignSystem.swift`: UI design tokens and styling

### Story Generation Flow
1. User enters prompt in `ModernCreateStoryView`
2. `StoryGenerationFlowView` handles interactive story creation:
   - Plot options generation
   - Title suggestions
   - Character creation
   - Chapter-by-chapter generation
3. Stories stored in Supabase with chapter structure
4. Supports both complete story generation and incremental chapter writing

### Database Schema
- **profiles**: User profiles linked to auth.users
- **stories**: Story metadata with chapter counts and totals
- **chapters**: Individual story chapters with content and metadata
- Row Level Security (RLS) policies for data access control

## API Configuration

### AI Services
- **Primary**: DeepSeek V3 via OpenRouter (`AppConfig.storyGenerationModel`)
- **Fallback**: Mistral AI direct API
- **Authentication**: API keys stored in `AppConfig.swift`

### Supabase Setup
- **URL**: Configure in `AppConfig.supabaseURL`
- **Key**: Configure in `AppConfig.supabaseAnonKey`
- **Schema**: Available in `SupabaseService.createDatabaseSchema()`

## Important Notes

### Security
- API keys are currently hardcoded in `AppConfig.swift` - should be moved to environment variables in production
- All database operations use RLS policies
- User authentication required for story creation/editing

### Data Migration
- App handles migration from old single-content stories to chapter-based system
- `SupabaseService.migrateOldStoriesToChapterStructure()` handles legacy data

### Story Generation
- Target: 1000-1300 words per chapter
- Supports multiple genres, moods, and writing styles
- Interactive flow with plot options, character creation, and title suggestions
- Retry logic and error handling for AI API calls

## Common Development Patterns

### Adding New Story Features
1. Update models in `Models/Story.swift` if schema changes needed
2. Add database operations in `SupabaseService.swift`
3. Update UI components in relevant View files
4. Test with both new and legacy stories

### AI Integration
- All AI calls go through `MistralService.swift` (despite name, uses DeepSeek)
- Structured prompts with system/user message format
- JSON response parsing with fallback handling
- Retry logic for rate limiting and errors

### UI Development
- Use `DesignSystem.swift` for consistent styling
- SwiftUI with modern iOS patterns
- Tab-based navigation via `ModernTabView`
- Sheet presentations for modal flows