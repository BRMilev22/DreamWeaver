import SwiftUI

struct TypewriterText: View {
    let text: String
    let font: Font
    let color: Color
    let speed: Double // Characters per second
    @State private var displayedText = ""
    @State private var currentIndex = 0
    @State private var isComplete = false
    @State private var timer: Timer?
    @State private var startTime: Date?
    
    init(text: String, font: Font = .body, color: Color = .primary, speed: Double = 50.0) {
        self.text = text
        self.font = font
        self.color = color
        self.speed = speed
    }
    
    var body: some View {
        HStack {
            Text(displayedText)
                .font(font)
                .foregroundColor(color)
                .lineSpacing(6)
                .multilineTextAlignment(.leading)
            
            // Animated cursor for visual appeal
            if !isComplete {
                Text("|")
                    .font(font)
                    .foregroundColor(color.opacity(0.7))
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isComplete)
            }
            
            Spacer()
        }
        .onAppear {
            startTypewriting()
        }
        .onDisappear {
            stopTypewriting()
        }
    }
    
    private func startTypewriting() {
        displayedText = ""
        currentIndex = 0
        isComplete = false
        startTime = Date()
        
        // Calculate interval for smooth character-by-character animation
        let interval = 1.0 / speed
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            // Double-check we haven't exceeded text length
            guard currentIndex < text.count else {
                timer.invalidate()
                DispatchQueue.main.async {
                    isComplete = true
                }
                return
            }
            
            // Use main thread for UI updates
            DispatchQueue.main.async {
                let character = text[text.index(text.startIndex, offsetBy: currentIndex)]
                displayedText.append(character)
                currentIndex += 1
                
                // Final check if we've reached the end
                if currentIndex >= text.count {
                    timer.invalidate()
                    isComplete = true
                }
            }
        }
    }
    
    private func stopTypewriting() {
        timer?.invalidate()
        timer = nil
        startTime = nil
    }
}

// Preview for testing
#Preview {
    VStack {
        TypewriterText(
            text: "This is a sample text that will be animated with a typewriter effect. It should display character by character to create the illusion of live typing!",
            font: .body,
            color: .primary,
            speed: 50.0
        )
        .padding()
    }
} 