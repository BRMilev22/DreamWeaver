-- DreamWeaver Database Schema
-- Run this in your Supabase SQL Editor

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
    summary TEXT,
    genre TEXT NOT NULL,
    mood TEXT NOT NULL,
    is_published BOOLEAN DEFAULT false,
    is_premium BOOLEAN DEFAULT false,
    likes_count INTEGER DEFAULT 0,
    views_count INTEGER DEFAULT 0,
    total_words_count INTEGER DEFAULT 0,
    total_reading_time INTEGER DEFAULT 0,
    chapters_count INTEGER DEFAULT 0,
    generation_prompt TEXT,
    generation_parameters JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    published_at TIMESTAMP WITH TIME ZONE
);

-- Create chapters table
CREATE TABLE IF NOT EXISTS chapters (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    story_id UUID REFERENCES stories(id) ON DELETE CASCADE NOT NULL,
    chapter_number INTEGER NOT NULL,
    title TEXT,
    content TEXT NOT NULL,
    words_count INTEGER DEFAULT 0,
    reading_time INTEGER DEFAULT 0,
    generation_prompt TEXT,
    context_from_previous_chapters TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(story_id, chapter_number)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_stories_user_id ON stories(user_id);
CREATE INDEX IF NOT EXISTS idx_stories_published ON stories(is_published);
CREATE INDEX IF NOT EXISTS idx_stories_genre ON stories(genre);
CREATE INDEX IF NOT EXISTS idx_stories_created_at ON stories(created_at);
CREATE INDEX IF NOT EXISTS idx_chapters_story_id ON chapters(story_id);
CREATE INDEX IF NOT EXISTS idx_chapters_story_chapter ON chapters(story_id, chapter_number);
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE chapters ENABLE ROW LEVEL SECURITY;

-- Create security policies for profiles
CREATE POLICY "Public profiles are viewable by everyone" ON profiles FOR SELECT USING (is_public = true);
CREATE POLICY "Users can view their own profile" ON profiles FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update their own profile" ON profiles FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create security policies for stories
CREATE POLICY "Published stories are viewable by everyone" ON stories FOR SELECT USING (is_published = true);
CREATE POLICY "Users can view their own stories" ON stories FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own stories" ON stories FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own stories" ON stories FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own stories" ON stories FOR DELETE USING (auth.uid() = user_id);

-- Create security policies for chapters
CREATE POLICY "Chapters of published stories are viewable by everyone" ON chapters FOR SELECT USING (
    EXISTS (SELECT 1 FROM stories WHERE stories.id = chapters.story_id AND stories.is_published = true)
);
CREATE POLICY "Users can view chapters of their own stories" ON chapters FOR SELECT USING (
    EXISTS (SELECT 1 FROM stories WHERE stories.id = chapters.story_id AND stories.user_id = auth.uid())
);
CREATE POLICY "Users can insert chapters to their own stories" ON chapters FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM stories WHERE stories.id = chapters.story_id AND stories.user_id = auth.uid())
);
CREATE POLICY "Users can update chapters of their own stories" ON chapters FOR UPDATE USING (
    EXISTS (SELECT 1 FROM stories WHERE stories.id = chapters.story_id AND stories.user_id = auth.uid())
);
CREATE POLICY "Users can delete chapters of their own stories" ON chapters FOR DELETE USING (
    EXISTS (SELECT 1 FROM stories WHERE stories.id = chapters.story_id AND stories.user_id = auth.uid())
);

-- Create function to automatically update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_stories_updated_at BEFORE UPDATE ON stories FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_chapters_updated_at BEFORE UPDATE ON chapters FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column(); 