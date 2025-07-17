import SwiftUI
import AVFoundation

struct VoiceSettingsView: View {
    @StateObject private var voiceService = VoiceService.shared
    @AppStorage("preferredTTSEngine") private var preferredTTSEngine: Int = 0 // 0 = OpenAI, 1 = System
    @AppStorage("speechRate") private var speechRate: Double = 0.55
    @AppStorage("speechPitch") private var speechPitch: Double = 1.1
    @AppStorage("speechVolume") private var speechVolume: Double = 0.9
    @AppStorage("preferredOpenAIVoice") private var preferredOpenAIVoice: String = "nova"
    
    @State private var isTestingVoice = false
    @Environment(\.dismiss) private var dismiss
    
    private let testText = "This is a preview of how your selected voice will sound when reading your stories. The voice settings can be adjusted to match your preferences."
    
    private let openAIVoices = [
        ("nova", "Nova - Warm & Engaging", "Perfect for storytelling with a warm, friendly tone"),
        ("shimmer", "Shimmer - Soft & Gentle", "Ideal for romantic and gentle narratives"),
        ("echo", "Echo - Deep & Resonant", "Great for dramatic and adventurous stories"),
        ("fable", "Fable - British & Sophisticated", "Elegant British accent, perfect for literary works"),
        ("alloy", "Alloy - Balanced & Neutral", "Clear and balanced, good for any content"),
        ("onyx", "Onyx - Deep & Masculine", "Strong masculine voice for bold narratives")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                // TTS Engine Selection
                Section {
                    Picker("Voice Engine", selection: $preferredTTSEngine) {
                        Text("OpenAI (High Quality)").tag(0)
                        Text("iOS System (Fast)").tag(1)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Text-to-Speech Engine")
                } footer: {
                    Text("OpenAI provides more natural voices but requires internet. iOS System works offline and is faster.")
                }
                
                // OpenAI Voice Selection (only show if OpenAI is selected)
                if preferredTTSEngine == 0 {
                    Section {
                        ForEach(openAIVoices, id: \.0) { voice in
                            VoiceOptionRow(
                                voiceKey: voice.0,
                                voiceName: voice.1,
                                voiceDescription: voice.2,
                                isSelected: preferredOpenAIVoice == voice.0
                            ) {
                                preferredOpenAIVoice = voice.0
                            }
                        }
                    } header: {
                        Text("OpenAI Voice Selection")
                    } footer: {
                        Text("Each voice has unique characteristics suited for different types of stories.")
                    }
                }
                
                // Voice Settings
                Section {
                    VStack(spacing: 16) {
                        // Speech Rate
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Speaking Speed")
                                Spacer()
                                Text("\(Int(speechRate * 200))%")
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $speechRate, in: 0.3...0.8, step: 0.05)
                                .accentColor(.blue)
                        }
                        
                        // Speech Pitch (only for system voice)
                        if preferredTTSEngine == 1 {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Voice Pitch")
                                    Spacer()
                                    Text("\(Int(speechPitch * 100))%")
                                        .foregroundColor(.secondary)
                                }
                                Slider(value: $speechPitch, in: 0.8...1.4, step: 0.1)
                                    .accentColor(.blue)
                            }
                        }
                        
                        // Volume
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Volume")
                                Spacer()
                                Text("\(Int(speechVolume * 100))%")
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $speechVolume, in: 0.5...1.0, step: 0.05)
                                .accentColor(.blue)
                        }
                    }
                } header: {
                    Text("Voice Settings")
                } footer: {
                    Text("Adjust these settings to create the perfect listening experience for your stories.")
                }
                
                // Test Voice Button
                Section {
                    Button(action: testVoice) {
                        HStack {
                            Image(systemName: isTestingVoice ? "stop.fill" : "play.fill")
                            Text(isTestingVoice ? "Stop Test" : "Test Voice")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(isTestingVoice ? .red : .blue)
                    }
                    .disabled(voiceService.isLoading)
                } footer: {
                    Text("Test how your voice settings will sound when reading stories.")
                }
            }
            .navigationTitle("Voice Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onDisappear {
            // Stop any test audio when leaving
            voiceService.stop()
        }
    }
    
    private func testVoice() {
        if isTestingVoice {
            voiceService.stop()
            isTestingVoice = false
        } else {
            isTestingVoice = true
            
            // Apply current settings and test
            if preferredTTSEngine == 0 {
                // Test OpenAI voice
                voiceService.synthesizeAndPlay(text: testText)
            } else {
                // Test system voice with current settings
                voiceService.synthesizeAndPlayWithSpeechSynthesizer(text: testText)
            }
        }
    }
}

struct VoiceOptionRow: View {
    let voiceKey: String
    let voiceName: String
    let voiceDescription: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(voiceName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(voiceDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VoiceSettingsView()
}
