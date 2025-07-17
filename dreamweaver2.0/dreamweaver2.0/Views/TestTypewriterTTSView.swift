import SwiftUI

struct TestTypewriterTTSView: View {
    @State private var showTest = false
    
    let sampleText = """
    This is a sample story text that will demonstrate the new typewriter effect with text-to-speech integration. 
    
    The typewriter effect will display the text character by character, and once it starts typing, the text-to-speech will begin reading the story aloud. 
    
    As the story is being read, the words will be highlighted in real-time to show exactly what is being spoken. This creates an immersive reading experience that combines visual and auditory elements.
    
    The implementation has been improved to prevent the typewriter effect from completing too early, ensuring a smooth and consistent experience for users enjoying their generated stories.
    """
    
    var body: some View {
        ZStack {
            DesignSystem.Gradients.background
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Typewriter + TTS Test")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                Button("Start Test") {
                    showTest = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                if showTest {
                    ScrollView {
                        TypewriterTextWithTTS(
                            text: sampleText,
                            font: .body,
                            color: .primary,
                            highlightColor: Color.blue.opacity(0.3),
                            speed: 40.0
                        )
                        .padding()
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    TestTypewriterTTSView()
}