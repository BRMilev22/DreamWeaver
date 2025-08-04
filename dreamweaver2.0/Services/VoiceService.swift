import Foundation
import AVFoundation
import Combine
import SwiftUI

class VoiceService: NSObject, ObservableObject {
    static let shared = VoiceService()
    
    // User Preferences (stored settings) - Default to OpenAI for better quality
    @AppStorage("preferredTTSEngine") private var preferredTTSEngine: Int = 0 // 0 = OpenAI (default), 1 = System
    @AppStorage("speechRate") private var speechRate: Double = 0.55
    @AppStorage("speechPitch") private var speechPitch: Double = 1.1
    @AppStorage("speechVolume") private var speechVolume: Double = 0.9
    @AppStorage("preferredOpenAIVoice") private var preferredOpenAIVoice: String = "nova" // Default to nova voice
    
    // OpenAI Configuration 
    private let apiKey = AppConfig.openAIAPIKey
    private let baseURL = "https://api.openai.com/v1/audio/speech"
    
    // Audio Player
    private var audioPlayer: AVAudioPlayer?
    private var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    
    // AVSpeechSynthesizer for proper word-level timing
    private var speechSynthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?
    
    // Public access to check if audio is loaded
    var hasAudio: Bool {
        return audioPlayer != nil
    }
    
    // Published States
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var currentProgress: Double = 0.0
    @Published var totalDuration: Double = 0.0
    @Published var error: String?
    
    // Text Highlighting
    @Published var currentWordIndex: Int = 0
    @Published var highlightedRange: NSRange = NSRange(location: 0, length: 0)
    
    // Callback for external highlighting
    var onWordHighlight: ((Int) -> Void)?
    
    // Timer for text highlighting sync
    private var highlightTimer: Timer?
    private var currentText: String = ""
    private var words: [String] = []
    private var estimatedWordsPerSecond: Double = 2.5 // Adjusted for better sync
    private var startTime: Date?
    private var isHighlightingActive = false
    
    override init() {
        super.init()
        setupAudioSession()
        speechSynthesizer.delegate = self
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Voice Selection
    
    private func getPreferredVoice() -> AVSpeechSynthesisVoice? {
        // Prioritize the most natural-sounding voices available
        let preferredVoiceIdentifiers = [
            // iOS 17+ high-quality voices
            "com.apple.voice.enhanced.en-US.Samantha",
            "com.apple.voice.enhanced.en-US.Alex",
            "com.apple.voice.enhanced.en-US.Nicky",
            "com.apple.voice.enhanced.en-US.Allison",
            
            // iOS 16+ neural voices
            "com.apple.voice.compact.en-US.Samantha",
            "com.apple.voice.compact.en-US.Alex",
            
            // Fallback standard voices
            "com.apple.ttsbundle.Samantha-compact",
            "com.apple.ttsbundle.Alex-compact"
        ]
        
        // Try to find the best available voice
        for identifier in preferredVoiceIdentifiers {
            if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
                print("🎙️ Selected high-quality voice: \(voice.name) (\(identifier))")
                return voice
            }
        }
        
        // If no specific voice found, try to get the best quality voice for English
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        let englishVoices = allVoices.filter { $0.language.hasPrefix("en") }
        
        // Prefer enhanced or premium quality voices
        let highQualityVoice = englishVoices.first { voice in
            voice.quality == .enhanced || voice.quality == .premium
        }
        
        if let voice = highQualityVoice {
            print("🎙️ Selected enhanced voice: \(voice.name) (quality: \(voice.quality.rawValue))")
            return voice
        }
        
        // Fallback to default voice
        let defaultVoice = englishVoices.first { $0.language == "en-US" }
        if let voice = defaultVoice {
            print("🎙️ Using default voice: \(voice.name)")
            return voice
        }
        
        print("⚠️ No suitable voice found, using system default")
        return nil
    }
    
    private func getPreferredOpenAIVoice() -> String {
        // OpenAI voice options with natural characteristics:
        // - nova: Warm, engaging, great for storytelling
        // - shimmer: Soft, friendly, good for narratives
        // - echo: Deep, resonant, good for dramatic content
        // - alloy: Balanced, neutral (fallback)
        // - onyx: Deep masculine voice
        // - fable: British accent, sophisticated
        
        // For storytelling, nova and shimmer are most natural
        // Let's use nova as primary choice for warm, engaging narration
        let selectedVoice = "nova"
        
        print("🎙️ Selected OpenAI voice: \(selectedVoice) for natural storytelling")
        return selectedVoice
    }
    
    private func preprocessTextForNaturalSpeech(_ text: String) -> String {
        var processedText = text
        
        // Only add spaces where they don't already exist to avoid double-spacing
        processedText = processedText.replacingOccurrences(of: "\\.(\\S)", with: ". $1", options: .regularExpression)
        processedText = processedText.replacingOccurrences(of: ",(\\S)", with: ", $1", options: .regularExpression)
        processedText = processedText.replacingOccurrences(of: "!(\\S)", with: "! $1", options: .regularExpression)
        processedText = processedText.replacingOccurrences(of: "\\?(\\S)", with: "? $1", options: .regularExpression)
        processedText = processedText.replacingOccurrences(of: ";(\\S)", with: "; $1", options: .regularExpression)
        processedText = processedText.replacingOccurrences(of: ":(\\S)", with: ": $1", options: .regularExpression)
        
        // Clean up any double spaces
        processedText = processedText.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
        processedText = processedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return processedText
    }
    
    /// Calibrate the word timing based on actual playback (for debugging)
    func calibrateWordTiming() {
        guard let audioPlayer = audioPlayer, isPlaying else { return }
        
        let currentTime = audioPlayer.currentTime
        let currentProgress = currentTime / audioPlayer.duration
        let estimatedWordsByProgress = Int(currentProgress * Double(words.count))
        let estimatedWordsByTime = Int(currentTime * estimatedWordsPerSecond)
        
        print("🔧 CALIBRATION:")
        print("   Current time: \(String(format: "%.2f", currentTime))s")
        print("   Progress: \(String(format: "%.1f", currentProgress * 100))%")
        print("   Current word index: \(currentWordIndex)")
        print("   Estimated by progress: \(estimatedWordsByProgress)")
        print("   Estimated by time: \(estimatedWordsByTime)")
        print("   Words per second: \(String(format: "%.2f", estimatedWordsPerSecond))")
        
        if currentWordIndex < words.count {
            print("   Current word: '\(words[currentWordIndex])'")
        }
    }
    
    // MARK: - Advanced Speech Synchronization
    
    // MARK: - Punctuation-Aware Word Highlighting
    // 
    // This implementation solves the sync issue where OpenAI TTS highlighting
    // would skip punctuation marks (commas, periods, etc.) and get out of sync.
    // 
    // The problem: Simple linear progress (wordIndex = progress * wordCount) 
    // doesn't account for punctuation pauses that take time but don't advance words.
    //
    // The solution: Weight-based timing model that assigns time costs to:
    // - Word length (longer words = more time)  
    // - Following punctuation (periods = 0.8s, commas = 0.4s, etc.)
    //
    // Result: Highlighting stays synchronized with spoken audio, including
    // natural pauses at punctuation marks.
    
    private var speechPatternAnalyzer = SpeechPatternAnalyzer()
    
    private class SpeechPatternAnalyzer {
        private var wordTimings: [(wordIndex: Int, timestamp: Double)] = []
        private var lastCalibrationTime: Double = 0
        
        func recordWordTiming(wordIndex: Int, timestamp: Double) {
            wordTimings.append((wordIndex: wordIndex, timestamp: timestamp))
            
            // Keep only recent timings for analysis
            if wordTimings.count > 20 {
                wordTimings.removeFirst(5)
            }
        }
        
        func predictCurrentWord(currentTime: Double, totalWords: Int, estimatedWPS: Double) -> Int {
            guard !wordTimings.isEmpty else {
                // No data yet, use conservative estimation
                return min(Int(currentTime * estimatedWPS * 0.75), totalWords - 1)
            }
            
            // Analyze recent speech patterns
            let recentTimings = wordTimings.suffix(5)
            
            if recentTimings.count >= 2 {
                // Calculate actual words per second from recent data
                let timeSpan = recentTimings.last!.timestamp - recentTimings.first!.timestamp
                let wordSpan = recentTimings.last!.wordIndex - recentTimings.first!.wordIndex
                
                if timeSpan > 0.5 && wordSpan > 0 {
                    let actualWPS = Double(wordSpan) / timeSpan
                    let blendedWPS = actualWPS * 0.6 + estimatedWPS * 0.4
                    
                    // Predict based on blended rate
                    let basePrediction = recentTimings.last!.wordIndex
                    let timeSinceLastUpdate = currentTime - recentTimings.last!.timestamp
                    let predictedWordIndex = basePrediction + Int(timeSinceLastUpdate * blendedWPS)
                    
                    return min(max(0, predictedWordIndex), totalWords - 1)
                }
            }
            
            // Fallback to simple calculation
            return min(Int(currentTime * estimatedWPS * 0.8), totalWords - 1)
        }
        
        func reset() {
            wordTimings.removeAll()
            lastCalibrationTime = 0
        }
    }
    
    // MARK: - Content-Aware TTS Enhancement
    
    private func optimizeSettingsForContent(_ text: String) -> (rate: Float, pitch: Float) {
        let lowercaseText = text.lowercased()
        var adjustedRate = Float(speechRate)
        var adjustedPitch = Float(speechPitch)
        
        // Detect content type and adjust accordingly
        if lowercaseText.contains("dialogue") || text.contains("\"") {
            // For dialogue, use slightly faster rate and normal pitch
            adjustedRate *= 1.1
            adjustedPitch = 1.0
        } else if lowercaseText.contains("dramatic") || lowercaseText.contains("tension") || lowercaseText.contains("suddenly") {
            // For dramatic content, use slower rate and slightly lower pitch
            adjustedRate *= 0.9
            adjustedPitch *= 0.95
        } else if lowercaseText.contains("romantic") || lowercaseText.contains("gentle") || lowercaseText.contains("softly") {
            // For romantic content, use softer pitch and moderate rate
            adjustedRate *= 0.95
            adjustedPitch *= 1.05
        }
        
        // Ensure values stay within reasonable bounds
        adjustedRate = max(0.3, min(0.8, adjustedRate))
        adjustedPitch = max(0.8, min(1.4, adjustedPitch))
        
        return (rate: adjustedRate, pitch: adjustedPitch)
    }
    
    // MARK: - Public Access Methods
    
    /// Get the current words array used by the voice service for highlighting
    var currentWords: [String] {
        return words
    }
    
    /// Get the current text being used by the voice service
    var currentProcessedText: String {
        return currentText
    }
    
    // MARK: - Public Methods
    
    func synthesizeAndPlayWithSpeechSynthesizer(text: String) {
        print("🎤 VoiceService.synthesizeAndPlayWithSpeechSynthesizer() called")
        print("📝 Text length: \(text.count)")
        
        guard !text.isEmpty else { 
            print("❌ Text is empty, returning")
            return 
        }
        
        // Preprocess text for more natural speech
        let processedText = preprocessTextForNaturalSpeech(text)
        print("✨ Text preprocessed for natural speech")
        
        // Stop any current speech
        speechSynthesizer.stopSpeaking(at: .immediate)
        
        // Prepare text and words
        currentText = processedText
        words = processedText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        currentWordIndex = 0
        
        print("📊 Word count: \(words.count)")
        
        // Create utterance with more natural voice settings
        currentUtterance = AVSpeechUtterance(string: processedText)
        
        // Use the highest quality voice available
        if let preferredVoice = getPreferredVoice() {
            currentUtterance?.voice = preferredVoice
        } else {
            currentUtterance?.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        // Optimize voice settings based on content
        let optimizedSettings = optimizeSettingsForContent(text)
        
        // Optimize for natural speech using user preferences and content optimization
        currentUtterance?.rate = optimizedSettings.rate // Content-aware rate
        currentUtterance?.pitchMultiplier = optimizedSettings.pitch // Content-aware pitch
        currentUtterance?.volume = Float(speechVolume) // User's preferred volume
        
        // Add natural pauses and intonation
        currentUtterance?.preUtteranceDelay = 0.1
        currentUtterance?.postUtteranceDelay = 0.2
        
        // Update state
        DispatchQueue.main.async {
            self.isLoading = false
            self.isPlaying = true
            self.error = nil
        }
        
        // Start speaking
        if let utterance = currentUtterance {
            speechSynthesizer.speak(utterance)
            print("✅ Started AVSpeechSynthesizer with proper word-level timing")
        }
    }
    
    func synthesizeAndPlay(text: String) {
        print("🎤 VoiceService.synthesizeAndPlay() called")
        print("📝 Original text length: \(text.count)")
        
        guard !text.isEmpty else { 
            print("❌ Text is empty, returning")
            return 
        }
        
        // Optimize for European users - shorter text for faster synthesis
        let limitedText = String(text.prefix(2000)) // Reduced for faster European response
        
        // Preprocess text for more natural speech (for TTS only)
        let processedText = preprocessTextForNaturalSpeech(limitedText)
        print("✨ Text preprocessed for natural speech")
        
        print("✂️ Limited text length: \(processedText.count)")
        print("💰 Estimated cost: $\(String(format: "%.4f", Double(processedText.count) * 0.000015))")
        print("📄 Text preview: \(String(processedText.prefix(100)))...")
        
        // CRITICAL: Use original text for word counting to maintain UI sync
        currentText = limitedText  // Keep original for UI highlighting
        words = limitedText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        currentWordIndex = 0
        
        print("📊 Word count: \(words.count)")
        print("🔄 Setting isLoading = true")
        isLoading = true
        error = nil
        
        Task {
            print("🚀 Starting async synthesis task")
            do {
                print("📞 Calling OpenAI TTS API...")
                let audioData = try await synthesizeSpeech(text: processedText)
                print("✅ Audio data received: \(audioData.count) bytes")
                await MainActor.run {
                    print("🎵 Switching to main thread for audio setup")
                    self.playAudio(data: audioData)
                }
            } catch {
                print("❌ Synthesis failed with error: \(error)")
                await MainActor.run {
                    self.isLoading = false
                    self.error = "Failed to synthesize speech: \(error.localizedDescription)"
                    print("💥 Error set: \(self.error ?? "unknown")")
                }
            }
        }
    }
    
    func synthesizeAndPlaySmart(text: String) {
        print("🧠 Smart TTS selection based on user preference: \(preferredTTSEngine == 0 ? "OpenAI" : "System")")
        print("🎙️ Using voice: \(preferredOpenAIVoice) (OpenAI) or Enhanced System Voice")
        
        if preferredTTSEngine == 0 {
            // Use OpenAI for highest quality (default)
            print("🌟 Using OpenAI TTS with voice: \(preferredOpenAIVoice)")
            synthesizeAndPlay(text: text)
        } else {
            // Use iOS native with enhanced settings
            print("📱 Using Enhanced System TTS")
            synthesizeAndPlayWithSpeechSynthesizer(text: text)
        }
    }
    
    /// Use this method when you need word-level highlighting synchronization with OpenAI TTS
    func synthesizeAndPlayWithPerfectSync(text: String) {
        print("🎯 Using OpenAI TTS with improved sync")
        synthesizeAndPlay(text: text)
    }
    
    func play() {
        print("▶️ VoiceService.play() called")
        
        // Handle AVSpeechSynthesizer (regular or hybrid timing)
        if speechSynthesizer.isPaused {
            speechSynthesizer.continueSpeaking()
            isPlaying = true
            print("✅ Resumed AVSpeechSynthesizer")
            return
        }
        
        // Handle AVAudioPlayer (OpenAI audio or hybrid mode)
        guard let player = audioPlayer else { 
            print("❌ No audio player available")
            return 
        }
        
        print("🎵 Starting audio playback")
        player.play()
        isPlaying = true
        print("✅ isPlaying set to true")
        
        // Check if we're in hybrid mode
        let timingAdjustmentFactor = UserDefaults.standard.double(forKey: "TimingAdjustmentFactor")
        if timingAdjustmentFactor > 0 {
            // Hybrid mode: OpenAI audio is playing, AVSpeechSynthesizer provides timing
            print("🎯 Hybrid mode: OpenAI audio playing with AVSpeechSynthesizer timing")
            // AVSpeechSynthesizer should already be running silently for timing
        } else {
            // Regular OpenAI mode: use timer-based highlighting
            print("🎵 Regular OpenAI mode: using timer-based highlighting")
            startHighlightTimer()
        }
        
        print("⏰ Playback system started")
    }
    
    func pause() {
        // Handle AVSpeechSynthesizer
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.pauseSpeaking(at: .immediate)
        }
        
        // Handle AVAudioPlayer
        audioPlayer?.pause()
        
        isPlaying = false
        stopHighlightTimer()
    }
    
    func stop() {
        // Handle AVSpeechSynthesizer
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        // Handle AVAudioPlayer
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        audioPlayer = nil
        
        isPlaying = false
        currentProgress = 0.0
        currentWordIndex = 0
        stopHighlightTimer()
    }
    
    // MARK: - Private Methods
    
    private func synthesizeSpeech(text: String) async throws -> Data {
        print("🌐 VoiceService.synthesizeSpeech() called")
        print("🔗 URL: \(baseURL)")
        
        guard let url = URL(string: baseURL) else {
            throw VoiceServiceError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30.0 // 30 second timeout for European users
        print("🔑 API key set: Bearer \(String(apiKey.prefix(10)))...")
        
        let requestBody: [String: Any] = [
            "model": AppConfig.openAITTSModel, // Use configured high-quality model
            "input": text,
            "voice": preferredOpenAIVoice, // Use user's preferred voice
            "response_format": "mp3",
            "speed": 1.0 // Natural speed for better comprehension
        ]
        
        print("📝 Request body: \(requestBody)")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        print("📡 Making HTTP request...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        print("📨 Received response: \(data.count) bytes")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw VoiceServiceError.invalidResponse
        }
        
        print("📊 HTTP Status Code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ API Error: Status code \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Error response: \(responseString)")
            }
            throw VoiceServiceError.apiError(httpResponse.statusCode)
        }
        
        print("✅ Synthesis successful, returning \(data.count) bytes")
        return data
    }
    
    private func playAudio(data: Data) {
        print("🎵 VoiceService.playAudio() called with \(data.count) bytes")
        do {
            print("🔧 Creating AVAudioPlayer from data...")
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            print("🎧 Audio player created successfully")
            
            print("⚙️ Preparing audio for playback...")
            audioPlayer?.prepareToPlay()
            
            totalDuration = audioPlayer?.duration ?? 0.0
            print("⏱️ Audio duration: \(totalDuration) seconds")
            
            // Calculate more accurate words per second based on actual text and audio
            if totalDuration > 0 && !words.isEmpty {
                // Analyze text characteristics for better estimation
                let textComplexity = analyzeTextComplexity(currentText)
                
                // Count actual linguistic units (words + punctuation pauses)
                let punctuationMarkers = currentText.filter { ".,!?;:—–".contains($0) }.count
                let effectiveUnits = Double(words.count) + (Double(punctuationMarkers) * 0.4) // Punctuation adds 40% of a word's time
                
                // Calculate based on effective units rather than just words
                let rawWordsPerSecond = effectiveUnits / totalDuration
                
                // Apply OpenAI TTS specific calibration - they tend to speak slower than estimated
                let openAICalibration = 0.85 // 15% slower than raw calculation
                estimatedWordsPerSecond = rawWordsPerSecond * openAICalibration
                
                // Apply reasonable bounds but allow for punctuation influence
                estimatedWordsPerSecond = max(1.5, min(2.8, estimatedWordsPerSecond))
                
                print("📊 Enhanced WPS calculation:")
                print("   Words: \(words.count), Punctuation: \(punctuationMarkers)")
                print("   Effective units: \(String(format: "%.1f", effectiveUnits))")
                print("   Duration: \(String(format: "%.2f", totalDuration))s")
                print("   Raw WPS: \(String(format: "%.2f", rawWordsPerSecond))")
                print("   Final WPS (calibrated): \(String(format: "%.2f", estimatedWordsPerSecond))")
            } else {
                // Fallback to conservative rate
                estimatedWordsPerSecond = 1.8
            }
            
            // Initialize speech pattern analyzer
            speechPatternAnalyzer.reset()
            
            print("✅ Setting isLoading = false")
            isLoading = false
            print("🎬 Calling play() method...")
            play()
            
        } catch {
            print("❌ Failed to create audio player: \(error)")
            isLoading = false
            self.error = "Failed to play audio: \(error.localizedDescription)"
            print("💥 Error set in playAudio: \(self.error ?? "unknown")")
        }
    }
    
    private func startHighlightTimer() {
        stopHighlightTimer()
        
        guard !words.isEmpty, let player = audioPlayer, player.duration > 0 else { 
            print("❌ Cannot start highlight timer: words.isEmpty=\(!words.isEmpty), audioPlayer=\(audioPlayer != nil), duration=\(audioPlayer?.duration ?? 0)")
            return 
        }
        
        isHighlightingActive = true
        startTime = Date()
        speechPatternAnalyzer.reset() // Reset analyzer for new audio
        
        // Pre-calculate timing model for better synchronization
        let timingModel = calculatePunctuationAwareTimingModel()
        
        // Reset to start
        DispatchQueue.main.async {
            self.currentWordIndex = 0
            print("🔄 MAIN THREAD: Reset currentWordIndex to 0, VoiceService instance: \(ObjectIdentifier(self))")
        }
        
        print("🎯 Starting PUNCTUATION-AWARE highlight timer: \(words.count) words, audio duration: \(player.duration)s")
        print("📊 Timing model: \(timingModel.count) segments, total weight: \(timingModel.map(\.weight).reduce(0, +))")
        
        // Use slower timer interval for better OpenAI TTS sync 
        highlightTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            DispatchQueue.main.async {
                guard self.isHighlightingActive && self.isPlaying, let audioPlayer = self.audioPlayer else {
                    timer.invalidate()
                    return
                }
                
                let currentTime = audioPlayer.currentTime
                let totalDuration = audioPlayer.duration
                let progress = currentTime / totalDuration
                
                // Calculate target word using punctuation-aware timing
                let targetWordIndex = self.calculateWordIndexFromProgress(progress, timingModel: timingModel)
                let boundedIndex = min(max(0, targetWordIndex), self.words.count - 1)
                
                // Only update if we've moved to a different word
                if boundedIndex != self.currentWordIndex {
                    self.currentWordIndex = boundedIndex
                    
                    if self.currentWordIndex < self.words.count {
                        print("🎵 PUNCT-AWARE SYNC: \(String(format: "%.1f", progress * 100))% -> word \(self.currentWordIndex): '\(self.words[self.currentWordIndex])'")
                        self.updateHighlightedRange()
                        self.onWordHighlight?(self.currentWordIndex)
                    }
                }
                
                // Check if audio finished
                if currentTime >= totalDuration - 0.1 {
                    print("✅ Audio completed, stopping highlight")
                    timer.invalidate()
                    self.isHighlightingActive = false
                    self.currentWordIndex = 0
                    self.onWordHighlight?(0)
                }
            }
        }
    }
    
    private func stopHighlightTimer() {
        highlightTimer?.invalidate()
        highlightTimer = nil
        isHighlightingActive = false
        startTime = nil
    }
    
    private func updateHighlightedRange() {
        guard currentWordIndex < words.count else { return }
        
        let wordsUpToCurrent = Array(words.prefix(currentWordIndex + 1))
        let textUpToCurrent = wordsUpToCurrent.joined(separator: " ")
        
        // Find the current word's range in the full text
        let currentWord = words[currentWordIndex]
        let startIndex = currentText.range(of: textUpToCurrent)?.lowerBound ?? currentText.startIndex
        let endIndex = currentText.range(of: currentWord, range: startIndex..<currentText.endIndex)?.upperBound ?? currentText.endIndex
        
        let nsRange = NSRange(startIndex..<endIndex, in: currentText)
        highlightedRange = NSRange(location: nsRange.location, length: currentWord.count)
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension VoiceService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        // Handle both regular AVSpeechSynthesizer and hybrid timing
        guard let text = currentUtterance?.speechString else { return }
        
        // Extract the current word being spoken
        let nsString = text as NSString
        let currentWord = nsString.substring(with: characterRange)
        
        // Find the word index based on character position
        let beforeRange = NSRange(location: 0, length: characterRange.location)
        let textBeforeCurrentWord = nsString.substring(with: beforeRange)
        let wordsBeforeCurrent = textBeforeCurrentWord.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let wordIndex = wordsBeforeCurrent.count
        
        DispatchQueue.main.async {
            // Check if we're in hybrid mode (OpenAI audio + AVSpeechSynthesizer timing)
            if let audioPlayer = self.audioPlayer, self.totalDuration > 0 {
                // Hybrid mode: Use AVSpeechSynthesizer timing but play OpenAI audio
                self.handleHybridWordTiming(wordIndex: wordIndex, currentWord: currentWord)
            } else {
                // Regular AVSpeechSynthesizer mode
                self.currentWordIndex = wordIndex
                print("🎯 PERFECT SYNC: word \(wordIndex): '\(currentWord)' at character range \(characterRange.location)-\(characterRange.location + characterRange.length)")
                self.onWordHighlight?(wordIndex)
            }
        }
    }
    
    // Handle word timing in hybrid mode
    private func handleHybridWordTiming(wordIndex: Int, currentWord: String) {
        // Apply timing adjustment if available
        let timingAdjustmentFactor = UserDefaults.standard.double(forKey: "TimingAdjustmentFactor")
        
        if timingAdjustmentFactor > 0 {
            // Calculate the adjusted timing for OpenAI audio
            let adjustedDelay = 0.1 * timingAdjustmentFactor // Small delay to sync better
            
            DispatchQueue.main.asyncAfter(deadline: .now() + adjustedDelay) {
                self.currentWordIndex = wordIndex
                print("🎯 HYBRID PERFECT SYNC: word \(wordIndex): '\(currentWord)' (adjusted timing)")
                self.onWordHighlight?(wordIndex)
            }
        } else {
            // No adjustment factor, use direct timing
            self.currentWordIndex = wordIndex
            print("🎯 HYBRID SYNC: word \(wordIndex): '\(currentWord)' (direct timing)")
            self.onWordHighlight?(wordIndex)
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = true
            self.currentWordIndex = 0
            print("🎤 AVSpeechSynthesizer started")
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentProgress = 0.0
            self.currentWordIndex = 0
            print("✅ AVSpeechSynthesizer finished")
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = false
            print("⏸️ AVSpeechSynthesizer paused")
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = true
            print("▶️ AVSpeechSynthesizer continued")
        }
    }
    
    // MARK: - Text Analysis Helper
    
    private func analyzeTextComplexity(_ text: String) -> (speedMultiplier: Double, pauseDuration: Double) {
        let lowercaseText = text.lowercased()
        
        // Base multipliers
        var speedMultiplier = 1.0
        var pauseDuration = 0.35 // Base pause duration in seconds
        
        // Analyze dialogue (usually faster)
        let dialogueMarkers = text.filter { $0 == "\"" }.count
        if dialogueMarkers > 0 {
            speedMultiplier *= 1.08 // 8% faster for dialogue
            pauseDuration *= 0.85 // Shorter pauses in dialogue
        }
        
        // Analyze punctuation density (affects pacing significantly)
        let totalPunctuation = text.filter { ".,!?;:—–".contains($0) }.count
        let wordsInText = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let punctuationDensity = wordsInText.isEmpty ? 0 : Double(totalPunctuation) / Double(wordsInText.count)
        
        if punctuationDensity > 0.15 { // High punctuation density
            speedMultiplier *= 0.92 // Slower for heavily punctuated text
            pauseDuration *= 1.15 // Longer pauses
        }
        
        // Analyze complex words (slower speech)
        let longWords = wordsInText.filter { $0.count > 8 }.count
        let complexityRatio = wordsInText.isEmpty ? 0 : Double(longWords) / Double(wordsInText.count)
        
        if complexityRatio > 0.2 {
            speedMultiplier *= 0.88 // 12% slower for complex text
        }
        
        // Analyze emotional content (affects pace)
        let dramaticWords = ["suddenly", "dramatic", "intense", "shocking", "amazing", "incredible"]
        let romanticWords = ["gentle", "softly", "whisper", "tender", "loving", "beautiful"]
        
        let hasDramatic = dramaticWords.contains { lowercaseText.contains($0) }
        let hasRomantic = romanticWords.contains { lowercaseText.contains($0) }
        
        if hasDramatic {
            speedMultiplier *= 0.93 // Slower for dramatic content
            pauseDuration *= 1.25 // Longer pauses for drama
        } else if hasRomantic {
            speedMultiplier *= 0.90 // Slower for romantic content
            pauseDuration *= 1.15 // Slightly longer pauses
        }
        
        // Constrain values
        speedMultiplier = max(0.75, min(1.25, speedMultiplier))
        pauseDuration = max(0.25, min(0.6, pauseDuration))
        
        return (speedMultiplier: speedMultiplier, pauseDuration: pauseDuration)
    }
    
    // MARK: - Punctuation-Aware Timing Model
    
    private struct TimingSegment {
        let wordIndex: Int
        let weight: Double // Time weight for this word + following punctuation
        let cumulativeWeight: Double // Running total of weights
    }
    
    private func calculatePunctuationAwareTimingModel() -> [TimingSegment] {
        var segments: [TimingSegment] = []
        var cumulativeWeight: Double = 0.0
        
        for (index, word) in words.enumerated() {
            // Base weight for the word - adjusted for OpenAI's natural speaking pace
            let baseWordWeight = max(0.45, Double(word.count) * 0.12) // Minimum 0.45s per word for OpenAI voice
            
            // Adjust for word complexity (longer words take more time in OpenAI speech)
            let complexityMultiplier = word.count > 7 ? 1.2 : 1.0
            let wordWeight = baseWordWeight * complexityMultiplier
            
            // Add weight for punctuation after this word
            let punctuationWeight = getPunctuationWeightAfterWord(wordIndex: index)
            
            let totalWeight = wordWeight + punctuationWeight
            cumulativeWeight += totalWeight
            
            segments.append(TimingSegment(
                wordIndex: index,
                weight: totalWeight,
                cumulativeWeight: cumulativeWeight
            ))
        }
        
        return segments
    }
    
    private func getPunctuationWeightAfterWord(wordIndex: Int) -> Double {
        guard wordIndex < words.count else { return 0.0 }
        
        let word = words[wordIndex]
        let wordEndInText = findWordEndInText(word: word, wordIndex: wordIndex)
        
        // Check what punctuation follows this word in the original text
        let followingChar = getCharacterAfter(position: wordEndInText)
        
        // OpenAI TTS specific pause timings - they tend to have longer pauses
        switch followingChar {
        case ".": return 0.9  // Period = longer pause
        case "!": return 0.8  // Exclamation
        case "?": return 0.8  // Question
        case ",": return 0.5  // Comma = shorter pause
        case ";": return 0.6  // Semicolon
        case ":": return 0.4  // Colon
        case "—", "–": return 0.5  // Em/En dash
        default: return 0.15  // Small natural pause between words
        }
    }
    
    private func findWordEndInText(word: String, wordIndex: Int) -> String.Index {
        // Find where this word ends in the original text
        let wordsUpToThis = Array(words.prefix(wordIndex + 1))
        let textUpToThisWord = wordsUpToThis.joined(separator: " ")
        
        if let range = currentText.range(of: textUpToThisWord) {
            return range.upperBound
        }
        
        return currentText.startIndex
    }
    
    private func getCharacterAfter(position: String.Index) -> Character? {
        let nextIndex = currentText.index(position, offsetBy: 1, limitedBy: currentText.endIndex)
        guard let nextIndex = nextIndex, nextIndex < currentText.endIndex else { return nil }
        return currentText[nextIndex]
    }
    
    private func calculateWordIndexFromProgress(_ progress: Double, timingModel: [TimingSegment]) -> Int {
        guard !timingModel.isEmpty else { return 0 }
        
        let totalWeight = timingModel.last?.cumulativeWeight ?? 1.0
        let targetWeight = progress * totalWeight
        
        // Find the word index that corresponds to this cumulative weight
        for segment in timingModel {
            if segment.cumulativeWeight >= targetWeight {
                return segment.wordIndex
            }
        }
        
        return timingModel.count - 1
    }
    
    // MARK: - Debug Helper Methods
    
    func debugHighlightSync() {
        guard let audioPlayer = audioPlayer, isPlaying else {
            print("🔍 DEBUG: No active audio playback")
            return
        }
        
        let currentTime = audioPlayer.currentTime
        let progress = currentTime / audioPlayer.duration
        let timingModel = calculatePunctuationAwareTimingModel()
        let predictedIndex = calculateWordIndexFromProgress(progress, timingModel: timingModel)
        
        print("🔍 HIGHLIGHT SYNC DEBUG:")
        print("   Current time: \(String(format: "%.2f", currentTime))s")
        print("   Progress: \(String(format: "%.1f", progress * 100))%")
        print("   Current word index: \(currentWordIndex)")
        print("   Predicted index: \(predictedIndex)")
        print("   Total words: \(words.count)")
        
        if currentWordIndex < words.count {
            print("   Current word: '\(words[currentWordIndex])'")
        }
        if predictedIndex < words.count {
            print("   Predicted word: '\(words[predictedIndex])'")
        }
        
        // Show timing model weights around current position
        let start = max(0, currentWordIndex - 2)
        let end = min(words.count, currentWordIndex + 3)
        print("   Timing weights around current position:")
        for i in start..<end {
            if i < timingModel.count {
                let segment = timingModel[i]
                let marker = i == currentWordIndex ? "👉" : "  "
                print("     \(marker) [\(i)] '\(words[i])' weight: \(String(format: "%.2f", segment.weight))")
            }
        }
    }
    
    // MARK: - Testing & Validation
    
    func testPunctuationTiming(with sampleText: String) {
        print("🧪 TESTING PUNCTUATION-AWARE TIMING")
        print("📝 Sample text: \(sampleText)")
        
        let originalText = currentText
        let originalWords = words
        
        // Temporarily set the sample text
        currentText = sampleText
        words = sampleText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        let timingModel = calculatePunctuationAwareTimingModel()
        
        print("📊 Timing model analysis:")
        print("   Total words: \(words.count)")
        print("   Total weight: \(String(format: "%.2f", timingModel.last?.cumulativeWeight ?? 0))")
        
        for (index, segment) in timingModel.enumerated() {
            let word = words[index]
            let punctWeight = getPunctuationWeightAfterWord(wordIndex: index)
            let wordWeight = segment.weight - punctWeight
            
            print("   [\(index)] '\(word)' = \(String(format: "%.2f", wordWeight)) + punct(\(String(format: "%.2f", punctWeight))) = \(String(format: "%.2f", segment.weight))")
        }
        
        // Test at different progress points
        let testProgressPoints = [0.0, 0.25, 0.5, 0.75, 1.0]
        print("\n🎯 Progress simulation:")
        for progress in testProgressPoints {
            let wordIndex = calculateWordIndexFromProgress(progress, timingModel: timingModel)
            print("   \(String(format: "%.0f", progress * 100))% -> word \(wordIndex): '\(wordIndex < words.count ? words[wordIndex] : "END")'")
        }
        
        // Restore original values
        currentText = originalText
        words = originalWords
        
        print("✅ Test completed\n")
    }
}

// MARK: - AVAudioPlayerDelegate

extension VoiceService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentProgress = 0.0
            self.currentWordIndex = 0
            self.stopHighlightTimer()
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.error = "Audio playback error: \(error?.localizedDescription ?? "Unknown error")"
        }
    }
}

// MARK: - Error Types

enum VoiceServiceError: Error {
    case invalidResponse
    case apiError(Int)
    case noAudioData
    
    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let code):
            return "API error with status code: \(code)"
        case .noAudioData:
            return "No audio data received"
        }
    }
}

// MARK: - String Extension for Regex
extension String {
    func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
            return results.map {
                String(self[Range($0.range, in: self)!])
            }
        } catch let error {
            print("Invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}