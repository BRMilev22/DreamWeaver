import SwiftUI
import AVFoundation

struct TypewriterTextWithTTS: View {
    let text: String
    let font: Font
    let color: Color
    let highlightColor: Color
    let speed: Double // Characters per second
    
    @State private var displayedText = ""
    @State private var currentIndex = 0
    @State private var isTypewriterComplete = false
    @State private var typewriterTimer: Timer?
    @State private var currentHighlightedWordIndex = 0
    
    @StateObject private var voiceService = VoiceService.shared
    @State private var hasStartedTTS = false
    @State private var words: [String] = []
    @State private var isHighlightingActive = false
    @State private var showingVoiceSettings = false
    
    init(text: String, font: Font = .body, color: Color = .primary, highlightColor: Color = .yellow.opacity(0.3), speed: Double = 50.0) {
        self.text = text
        self.font = font
        self.color = color
        self.highlightColor = highlightColor
        self.speed = speed
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Voice Controls (only show when typewriter is complete)
            if isTypewriterComplete {
                voiceControlsView
            }
            
            // Main text display
            HStack(alignment: .top) {
                Group {
                    if isTypewriterComplete {
                        // Show highlighted text with TTS synchronization
                        highlightedTextView
                    } else {
                        // Show typewriter effect
                        typewriterView
                    }
                }
                .lineSpacing(6)
                .multilineTextAlignment(.leading)
                
                Spacer()
            }
        }
        .onAppear {
            setupText()
            startTypewriting()
            // Set up the voice service callback for highlighting
            voiceService.onWordHighlight = { wordIndex in
                print("📢 Voice service callback: word \(wordIndex)")
                if isTypewriterComplete {
                    currentHighlightedWordIndex = wordIndex
                    isHighlightingActive = wordIndex < words.count
                    print("✅ Updated highlighting: index \(wordIndex), active: \(isHighlightingActive)")
                }
            }
        }
        .onDisappear {
            stopAllTimers()
            voiceService.stop()
            voiceService.onWordHighlight = nil
        }
        .onChange(of: voiceService.isPlaying) { _, isPlaying in
            print("🎵 Voice playing state changed: \(isPlaying)")
            if !isPlaying {
                isHighlightingActive = false
                currentHighlightedWordIndex = 0
            } else if isTypewriterComplete {
                // Voice started playing and typewriter is complete - OpenAI TTS handles highlighting
                print("🎯 OpenAI TTS timer will handle highlighting sync")
                isHighlightingActive = true
            }
        }
        .onChange(of: voiceService.currentWordIndex) { _, wordIndex in
            print("🔍 Word index changed: \(wordIndex), isComplete: \(isTypewriterComplete), isPlaying: \(voiceService.isPlaying)")
            if isTypewriterComplete && voiceService.isPlaying {
                currentHighlightedWordIndex = wordIndex
                isHighlightingActive = true
                print("🎯 Highlighting word \(wordIndex): \(wordIndex < words.count ? words[wordIndex] : "N/A")")
            }
        }
        .sheet(isPresented: $showingVoiceSettings) {
            VoiceSettingsView()
        }
    }
    
    // MARK: - Voice Controls
    private var voiceControlsView: some View {
        HStack(spacing: 16) {
            if voiceService.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Preparing voice...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Button(action: {
                    if voiceService.isPlaying {
                        voiceService.pause()
                    } else if voiceService.hasAudio {
                        voiceService.play()
                    } else {
                        voiceService.synthesizeAndPlay(text: text)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: voiceService.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                        Text(voiceService.isPlaying ? "Pause" : "Play")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.blue)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                if voiceService.hasAudio {
                    Button(action: {
                        voiceService.stop()
                        currentHighlightedWordIndex = 0
                        isHighlightingActive = false
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "stop.fill")
                                .font(.title3)
                            Text("Stop")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.red)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Voice Settings Button
                Button(action: {
                    showingVoiceSettings = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title3)
                        Text("Voice")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.purple)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Typewriter View
    private var typewriterView: some View {
        HStack {
            Text(displayedText)
                .font(font)
                .foregroundColor(color)
            
            // Animated cursor
            if !isTypewriterComplete {
                Text("|")
                    .font(font)
                    .foregroundColor(color.opacity(0.7))
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isTypewriterComplete)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Highlighted Text View
    private var highlightedTextView: some View {
        VStack(alignment: .leading, spacing: 0) {
            createHighlightedText()
        }
    }
    
    @ViewBuilder
    private func createHighlightedText() -> some View {
        // Split text into lines for better rendering
        let lines = splitIntoLines(words: words)
        
        ForEach(lines.indices, id: \.self) { lineIndex in
            HStack(alignment: .top, spacing: 0) {
                ForEach(lines[lineIndex].indices, id: \.self) { wordIndex in
                    let globalWordIndex = getGlobalWordIndex(lineIndex: lineIndex, wordIndex: wordIndex, lines: lines)
                    let word = lines[lineIndex][wordIndex]
                    let isHighlighted = globalWordIndex == currentHighlightedWordIndex && isHighlightingActive
                    
                    Group {
                        Text(word)
                            .font(font)
                            .foregroundColor(color)
                            .background(
                                isHighlighted ? highlightColor : Color.clear
                            )
                            .cornerRadius(4)
                            .animation(.easeInOut(duration: 0.2), value: isHighlighted)
                        
                        // Add space after each word except the last one in the line
                        if wordIndex < lines[lineIndex].count - 1 {
                            Text(" ")
                                .font(font)
                        }
                    }
                }
                Spacer()
            }
        }
    }
    
    // MARK: - Helper Methods
    private func setupText() {
        words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        displayedText = ""
        currentIndex = 0
        isTypewriterComplete = false
        hasStartedTTS = false
        currentHighlightedWordIndex = 0
        isHighlightingActive = false
    }
    
    private func startTypewriting() {
        stopAllTimers()
        
        // Start TTS immediately after a short delay
        if !hasStartedTTS {
            hasStartedTTS = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("🎤 Starting TTS from TypewriterTextWithTTS")
                voiceService.synthesizeAndPlay(text: text)
            }
        }
        
        // Calculate interval for smooth character-by-character animation
        let interval = 1.0 / speed
        
        typewriterTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            DispatchQueue.main.async {
                guard currentIndex < text.count else {
                    timer.invalidate()
                    completeTypewriter()
                    return
                }
                
                let character = text[text.index(text.startIndex, offsetBy: currentIndex)]
                displayedText.append(character)
                currentIndex += 1
            }
        }
    }
    
    private func completeTypewriter() {
        print("📝 Typewriter completed, transitioning to highlighted text")
        isTypewriterComplete = true
        displayedText = text
        
        // If voice is already playing, start highlighting immediately
        if voiceService.isPlaying {
            print("🎤 Voice is playing, OpenAI TTS timer will handle highlighting")
            isHighlightingActive = true
        }
    }
    
    
    private func stopAllTimers() {
        typewriterTimer?.invalidate()
        typewriterTimer = nil
    }
    
    private func splitIntoLines(words: [String]) -> [[String]] {
        var lines: [[String]] = []
        var currentLine: [String] = []
        let maxWordsPerLine = 10 // Increased for better text flow
        
        for word in words {
            currentLine.append(word)
            if currentLine.count >= maxWordsPerLine {
                lines.append(currentLine)
                currentLine = []
            }
        }
        
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }
        
        return lines
    }
    
    private func getGlobalWordIndex(lineIndex: Int, wordIndex: Int, lines: [[String]]) -> Int {
        var globalIndex = 0
        
        // Add words from all previous lines
        for i in 0..<lineIndex {
            globalIndex += lines[i].count
        }
        
        // Add words from current line up to current word
        globalIndex += wordIndex
        
        return globalIndex
    }
}

// MARK: - Preview
#Preview {
    TypewriterTextWithTTS(
        text: "This is a sample text that will be animated with a typewriter effect and then read aloud with text highlighting. The words will be highlighted as they are spoken by the AI voice, creating an immersive reading experience.",
        font: .body,
        color: .primary,
        highlightColor: Color.blue.opacity(0.3),
        speed: 50.0
    )
    .padding()
}