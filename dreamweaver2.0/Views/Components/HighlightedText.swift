import SwiftUI

struct HighlightedText: View {
    let text: String
    let font: Font
    let color: Color
    let highlightColor: Color
    @StateObject private var voiceService = VoiceService.shared
    @State private var showingVoiceSettings = false
    
    init(text: String, font: Font = .body, color: Color = .primary, highlightColor: Color = .yellow.opacity(0.3)) {
        self.text = text
        self.font = font
        self.color = color
        self.highlightColor = highlightColor
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Voice Controls - Redesigned for better UX
            HStack(spacing: 12) {
                if voiceService.isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.blue))
                            .scaleEffect(0.9)
                        Text("Preparing audio...")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    )
                } else {
                    // Play/Pause Button
                    Button(action: {
                        if voiceService.isPlaying {
                            voiceService.pause()
                        } else if voiceService.hasAudio {
                            voiceService.play()
                        } else {
                            voiceService.synthesizeAndPlayWithPerfectSync(text: text)
                        }
                    }) {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(voiceService.isPlaying ? Color.orange.gradient : Color.blue.gradient)
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: voiceService.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .offset(x: voiceService.isPlaying ? 0 : 1)
                            }
                            
                            Text(voiceService.isPlaying ? "Pause Reading" : "Listen")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(voiceService.isPlaying ? .orange : .blue)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke((voiceService.isPlaying ? Color.orange : Color.blue).opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(voiceService.isPlaying ? 1.02 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: voiceService.isPlaying)
                    
                    // Stop Button (only when audio is available)
                    if voiceService.hasAudio {
                        Button(action: {
                            voiceService.stop()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.red.gradient)
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: voiceService.hasAudio)
                    }
                    
                    // Voice Settings Button
                    Button(action: {
                        showingVoiceSettings = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.purple.gradient)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
            .padding(.bottom, 8)
            
            // Error Message
            if let error = voiceService.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.bottom, 8)
            }
            
            // Beautiful Highlighted Text
            HighlightedTextViewSimple(
                text: text,
                font: font,
                color: color,
                highlightColor: highlightColor,
                currentWordIndex: voiceService.currentWordIndex
            )
            .id("highlighted-text-\(voiceService.currentWordIndex)")
        }
        .sheet(isPresented: $showingVoiceSettings) {
            VoiceSettingsView()
        }
    }
}


private struct HighlightedTextViewSimple: View {
    let text: String
    let font: Font
    let color: Color
    let highlightColor: Color
    let currentWordIndex: Int
    
    private var words: [String] {
        text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    }
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            createBeautifulAttributedText()
        }
        .lineSpacing(8)
    }
    
    @ViewBuilder
    private func createBeautifulAttributedText() -> some View {
        // Create natural flowing text using TextRenderer for proper wrapping
        FlowingTextView(
            words: words,
            currentWordIndex: currentWordIndex,
            font: font,
            color: color,
            highlightColor: highlightColor
        )
    }
}

// Custom view for natural text flow with highlighting
private struct FlowingTextView: View {
    let words: [String]
    let currentWordIndex: Int
    let font: Font
    let color: Color
    let highlightColor: Color
    
    var body: some View {
        // Use ViewThatFits with wrapped text approach
        Text(attributedString)
            .lineSpacing(8)
            .multilineTextAlignment(.leading)
    }
    
    private var attributedString: AttributedString {
        var result = AttributedString()
        
        for (index, word) in words.enumerated() {
            let isHighlighted = index == currentWordIndex
            let isLastWord = index == words.count - 1
            
            // Create attributed string for the word
            var wordString = AttributedString(word)
            wordString.font = font
            wordString.foregroundColor = isHighlighted ? .primary : color
            
            if isHighlighted {
                wordString.backgroundColor = Color.blue.opacity(0.25)
                wordString.font = font.weight(.semibold)
            }
            
            result += wordString
            
            // Add space after word (except last word)
            if !isLastWord {
                result += AttributedString(" ")
            }
        }
        
        return result
    }
    
}

// MARK: - Preview
struct HighlightedText_Previews: PreviewProvider {
    static var previews: some View {
        HighlightedText(
            text: "This is a sample text that will be read aloud with highlighting. The words will be highlighted as they are spoken by the AI voice.",
            font: DesignSystem.Typography.body,
            color: DesignSystem.Colors.textPrimary,
            highlightColor: Color.blue.opacity(0.3)
        )
        .padding()
        .background(DesignSystem.Gradients.background)
    }
} 