# DreamWeaver iOS App

A powerful story generation app for iOS that uses AI to create compelling narratives. Built with SwiftUI, Supabase, and Mistral AI.

## Features

✨ **AI Story Generation** - Create stories using advanced AI with customizable parameters
📚 **Story Management** - Save, edit, and organize your stories
🔍 **Discover Stories** - Browse and discover stories from other users
👤 **User Profiles** - Manage your profile and view your story statistics
🎨 **Modern UI/UX** - Beautiful, intuitive interface with smooth animations
🔐 **Authentication** - Secure user authentication with Supabase
📱 **Native iOS** - Built with SwiftUI for optimal performance

## Prerequisites

- iOS 16.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later
- Supabase account
- Mistral AI account (already configured)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <your-repository-url>
cd dreamweaver2.0
```

### 2. Supabase Setup

1. Go to [Supabase](https://supabase.com) and create a new project
2. Once your project is created, go to **Settings** → **API**
3. Copy the following values:
   - **Project URL** (e.g., `https://your-project-id.supabase.co`)
   - **Anon Key** (public key)

### 3. Database Schema Setup

1. Go to your Supabase dashboard
2. Navigate to **SQL Editor**
3. Create a new query and paste the following SQL:

```sql
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
```

4. Execute the query to create the database schema

### 4. Configure App Settings

1. Open `dreamweaver2.0/dreamweaver2.0/Config/AppConfig.swift`
2. Update the Supabase configuration:

```swift
// Replace with your actual Supabase credentials
static let supabaseURL = "https://your-project-id.supabase.co"
static let supabaseAnonKey = "your-anon-key-here"
```

### 5. Add Supabase Dependencies

1. Open the project in Xcode
2. Go to **File** → **Add Package Dependencies**
3. Add the following URL: `https://github.com/supabase/supabase-swift.git`
4. Choose version `2.0.0` or later
5. Add the `Supabase` product to your target

### 6. Build and Run

1. Select your target device (iOS Simulator or physical device)
2. Press **Cmd+R** to build and run the app
3. The app should launch and show the authentication screen

## Usage

### Creating Your First Story

1. **Sign Up** - Create a new account or sign in with existing credentials
2. **Navigate to Create** - Tap the "Create" tab at the bottom
3. **Enter Prompt** - Describe your story idea in the prompt field
4. **Select Parameters** - Choose genre, mood, and story length
5. **Advanced Settings** (Optional) - Set writing style, characters, setting, etc.
6. **Generate** - Tap "Generate Story" to create your story
7. **Edit & Save** - Review the generated story and save it

### Discovering Stories

1. **Browse** - Use the "Discover" tab to explore published stories
2. **Search** - Use the search bar to find specific stories
3. **Filter** - Filter by genre using the category chips
4. **Read** - Tap on any story card to read it

### Managing Your Stories

1. **My Stories** - View all your created stories in the "My Stories" tab
2. **Edit** - Tap "Edit" on any story to modify it
3. **Publish** - Toggle the publish status to share stories publicly
4. **Delete** - Remove stories you no longer want

## Architecture

The app follows a clean architecture pattern:

- **Models** - Data structures for User, Story, and related entities
- **Views** - SwiftUI views for the user interface
- **Services** - Business logic and API communication
- **Config** - App configuration and settings

## API Integration

### Mistral AI

The app uses Mistral AI's large language model for story generation:
- **Model**: `mistral-large-latest`
- **API**: REST API with JSON requests
- **Configuration**: Customizable temperature, max tokens, and prompts

### Supabase

Database and authentication powered by Supabase:
- **Authentication**: Email/password with user profiles
- **Database**: PostgreSQL with Row Level Security
- **Real-time**: Support for real-time updates (future feature)

## Security

- **Row Level Security** - Database-level security policies
- **API Key Protection** - Secure API key management
- **Authentication** - Supabase Auth for user management
- **Data Validation** - Input validation and sanitization

## Customization

### Themes and Styling

- Modify `AppConfig.swift` for app-wide settings
- Update colors in `Assets.xcassets`
- Customize UI components in individual view files

### Story Generation

- Adjust prompts in `MistralService.swift`
- Modify generation parameters in `StoryGenerationParameters`
- Add new genres or moods in the respective enum types

## Troubleshooting

### Common Issues

1. **Build Errors**
   - Make sure all dependencies are properly added
   - Check that your iOS deployment target is 16.0 or later

2. **Authentication Issues**
   - Verify Supabase URL and keys are correct
   - Check that your Supabase project is active

3. **Story Generation Fails**
   - Ensure Mistral API key is valid
   - Check network connectivity

### Getting Help

- Check the iOS simulator console for error messages
- Verify your Supabase project settings
- Review the database schema in Supabase dashboard

## License

This project is licensed under the MIT License.

## Acknowledgments

- **Supabase** - Backend as a Service
- **Mistral AI** - AI-powered story generation
- **SwiftUI** - Modern iOS UI framework

---

Built with ❤️ for storytellers and AI enthusiasts. 