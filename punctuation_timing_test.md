# Punctuation-Aware TTS Timing Fix

## Problem Description
The OpenAI TTS word highlighting was getting out of sync because it only counted words but ignored punctuation marks (commas, periods, etc.) that create pauses in speech but don't advance the word index.

## Solution Implemented

### 1. **Punctuation-Aware Timing Model**
- Created a `TimingSegment` structure that assigns weights to each word based on:
  - Word length (longer words take more time)
  - Following punctuation (periods = 0.8s pause, commas = 0.4s pause, etc.)

### 2. **Enhanced Word Index Calculation**
- Instead of simple linear progress: `wordIndex = progress * wordCount`
- Now uses weighted calculation that accounts for punctuation pauses
- More accurate sync between audio progress and highlighted word

### 3. **Improved Text Analysis**
- Better punctuation density analysis
- Enhanced words-per-second calculation that includes "effective units" (words + punctuation pauses)
- Content-aware timing adjustments

## Key Changes Made

### VoiceService.swift Updates:

1. **New Timing Model Methods:**
   ```swift
   calculatePunctuationAwareTimingModel() -> [TimingSegment]
   getPunctuationWeightAfterWord(wordIndex: Int) -> Double
   calculateWordIndexFromProgress(progress: Double, timingModel: [TimingSegment]) -> Int
   ```

2. **Enhanced startHighlightTimer():**
   - Pre-calculates timing model for the entire text
   - Uses punctuation-aware word index calculation
   - Faster timer interval (0.08s vs 0.1s) for smoother highlighting

3. **Improved playAudio() WPS Calculation:**
   - Accounts for "effective units" (words + weighted punctuation)
   - More accurate duration-based timing estimation

## Punctuation Weights:
- Period (.) = 0.8 seconds pause
- Exclamation (!) = 0.7 seconds pause  
- Question (?) = 0.7 seconds pause
- Comma (,) = 0.4 seconds pause
- Semicolon (;) = 0.5 seconds pause
- Colon (:) = 0.3 seconds pause
- Em/En dash (—/–) = 0.4 seconds pause

## Testing
You can test the new timing model by calling:
```swift
VoiceService.shared.testPunctuationTiming(with: "Hello, world! This is a test. How does it work?")
```

## Expected Results
- **Before:** Highlighting would progressively drift out of sync, especially with punctuation-heavy text
- **After:** Highlighting should stay synchronized with the spoken word, accounting for natural pauses at punctuation marks

The fix maintains perfect synchronization for system TTS (via AVSpeechSynthesizer delegate) while dramatically improving OpenAI TTS synchronization through this punctuation-aware timing model.
