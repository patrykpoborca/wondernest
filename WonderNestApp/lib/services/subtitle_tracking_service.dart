import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class SubtitleTrackingService {
  final List<SubtitleEntry> _capturedSubtitles = [];
  final StreamController<SubtitleEvent> _subtitleController = 
      StreamController<SubtitleEvent>.broadcast();
  
  Timer? _trackingTimer;
  String? _currentVideoId;
  DateTime? _sessionStartTime;
  
  // Word exposure tracking
  final Map<String, WordExposure> _wordExposureMap = {};
  
  // Educational word categories
  final Map<String, List<String>> _educationalCategories = {
    'science': ['atom', 'molecule', 'gravity', 'energy', 'photosynthesis'],
    'math': ['addition', 'subtraction', 'multiplication', 'division', 'equation'],
    'vocabulary': ['magnificent', 'extraordinary', 'fascinating', 'remarkable'],
    'emotions': ['happy', 'sad', 'excited', 'nervous', 'confident'],
  };
  
  Stream<SubtitleEvent> get subtitleStream => _subtitleController.stream;
  
  List<SubtitleEntry> get capturedSubtitles => List.unmodifiable(_capturedSubtitles);
  
  Map<String, WordExposure> get wordExposureMap => Map.unmodifiable(_wordExposureMap);

  // Start tracking subtitles for a YouTube video
  Future<void> startYouTubeTracking({
    required String videoId,
    required String childId,
    YoutubePlayerController? controller,
  }) async {
    _currentVideoId = videoId;
    _sessionStartTime = DateTime.now();
    _capturedSubtitles.clear();
    
    // If controller is provided, listen to caption changes
    if (controller != null) {
      _startYouTubeSubtitleCapture(controller, childId);
    }
    
    // Start periodic tracking
    _trackingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _performTracking();
    });
  }

  void _startYouTubeSubtitleCapture(
    YoutubePlayerController controller,
    String childId,
  ) {
    // Note: YouTube Player Flutter doesn't directly expose captions
    // This is a conceptual implementation
    // In production, you might need to:
    // 1. Use YouTube Data API to fetch caption tracks
    // 2. Sync with video playback time
    // 3. Or use a custom video player with caption support
    
    // Simulated caption tracking
    controller.addListener(() {
      if (controller.value.isPlaying) {
        final position = controller.value.position;
        _checkForSubtitles(position, childId);
      }
    });
  }

  void _checkForSubtitles(Duration position, String childId) {
    // This would integrate with actual subtitle data
    // For now, we'll simulate subtitle detection
    
    final mockSubtitle = SubtitleEntry(
      text: 'This is a sample subtitle text',
      startTime: position,
      endTime: position + const Duration(seconds: 3),
      videoId: _currentVideoId ?? '',
      timestamp: DateTime.now(),
    );
    
    _processSubtitle(mockSubtitle, childId);
  }

  // Process captured subtitle
  void _processSubtitle(SubtitleEntry subtitle, String childId) {
    // Add to captured list
    _capturedSubtitles.add(subtitle);
    
    // Analyze words
    final words = subtitle.text.toLowerCase().split(' ');
    for (final word in words) {
      _trackWordExposure(word, subtitle);
    }
    
    // Check for educational content
    final educationalWords = _findEducationalWords(subtitle.text);
    
    // Create subtitle event
    final event = SubtitleEvent(
      subtitle: subtitle,
      childId: childId,
      educationalWords: educationalWords,
      readingLevel: _calculateReadingLevel(subtitle.text),
      sentiment: _analyzeSentiment(subtitle.text),
    );
    
    _subtitleController.add(event);
  }

  void _trackWordExposure(String word, SubtitleEntry subtitle) {
    final cleanWord = word.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    if (cleanWord.isEmpty) return;
    
    if (_wordExposureMap.containsKey(cleanWord)) {
      _wordExposureMap[cleanWord]!.incrementExposure(subtitle);
    } else {
      _wordExposureMap[cleanWord] = WordExposure(
        word: cleanWord,
        firstSeen: subtitle.timestamp,
        contexts: [subtitle.text],
      );
    }
  }

  List<String> _findEducationalWords(String text) {
    final educationalWords = <String>[];
    final lowercaseText = text.toLowerCase();
    
    for (final category in _educationalCategories.entries) {
      for (final word in category.value) {
        if (lowercaseText.contains(word)) {
          educationalWords.add(word);
        }
      }
    }
    
    return educationalWords;
  }

  // Calculate approximate reading level (Flesch-Kincaid)
  double _calculateReadingLevel(String text) {
    final sentences = text.split(RegExp(r'[.!?]')).where((s) => s.isNotEmpty);
    final words = text.split(' ').where((w) => w.isNotEmpty);
    final syllables = _countSyllables(text);
    
    if (sentences.isEmpty || words.isEmpty) return 0.0;
    
    final avgWordsPerSentence = words.length / sentences.length;
    final avgSyllablesPerWord = syllables / words.length;
    
    // Flesch Reading Ease formula (simplified)
    final readingEase = 206.835 - 
        1.015 * avgWordsPerSentence - 
        84.6 * avgSyllablesPerWord;
    
    // Convert to grade level (0-12)
    return ((100 - readingEase) / 10).clamp(0, 12);
  }

  int _countSyllables(String text) {
    // Simple syllable counting heuristic
    int count = 0;
    final words = text.toLowerCase().split(' ');
    
    for (final word in words) {
      if (word.isEmpty) continue;
      
      // Count vowel groups as syllables
      final vowelGroups = word.split(RegExp(r'[^aeiou]+')).where((v) => v.isNotEmpty);
      count += vowelGroups.length;
      
      // Adjust for silent 'e'
      if (word.endsWith('e') && count > 1) count--;
    }
    
    return count.clamp(words.length, words.length * 4);
  }

  String _analyzeSentiment(String text) {
    final lowercaseText = text.toLowerCase();
    
    // Simple sentiment keywords
    final positiveWords = ['happy', 'good', 'great', 'wonderful', 'amazing', 'love'];
    final negativeWords = ['sad', 'bad', 'terrible', 'hate', 'angry', 'upset'];
    
    int positiveCount = 0;
    int negativeCount = 0;
    
    for (final word in positiveWords) {
      if (lowercaseText.contains(word)) positiveCount++;
    }
    
    for (final word in negativeWords) {
      if (lowercaseText.contains(word)) negativeCount++;
    }
    
    if (positiveCount > negativeCount) return 'positive';
    if (negativeCount > positiveCount) return 'negative';
    return 'neutral';
  }

  void _performTracking() {
    // Periodic tracking tasks
    // This could include checking streaming service APIs,
    // monitoring WebView content, etc.
  }

  // Track subtitles from streaming services
  Future<void> trackStreamingService({
    required String service,
    required String contentId,
    required String childId,
  }) async {
    // Implementation would depend on the streaming service
    // Some services provide APIs for caption data
    // Others might require screen capture or accessibility services
    
    switch (service.toLowerCase()) {
      case 'netflix':
        await _trackNetflixSubtitles(contentId, childId);
        break;
      case 'disney+':
        await _trackDisneyPlusSubtitles(contentId, childId);
        break;
      case 'amazon':
        await _trackPrimeVideoSubtitles(contentId, childId);
        break;
      default:
        debugPrint('Streaming service $service not supported');
    }
  }

  Future<void> _trackNetflixSubtitles(String contentId, String childId) async {
    // Netflix subtitle tracking implementation
    // This would require proper API integration or browser extension
    debugPrint('Netflix subtitle tracking for content: $contentId');
  }

  Future<void> _trackDisneyPlusSubtitles(String contentId, String childId) async {
    // Disney+ subtitle tracking implementation
    debugPrint('Disney+ subtitle tracking for content: $contentId');
  }

  Future<void> _trackPrimeVideoSubtitles(String contentId, String childId) async {
    // Prime Video subtitle tracking implementation
    debugPrint('Prime Video subtitle tracking for content: $contentId');
  }

  // Generate vocabulary report
  VocabularyReport generateVocabularyReport() {
    final uniqueWords = _wordExposureMap.keys.toList();
    final frequentWords = _wordExposureMap.entries
        .where((e) => e.value.exposureCount > 5)
        .map((e) => e.key)
        .toList();
    
    final educationalWordsFound = <String>{};
    for (final category in _educationalCategories.values) {
      educationalWordsFound.addAll(
        category.where((word) => _wordExposureMap.containsKey(word))
      );
    }
    
    return VocabularyReport(
      totalUniqueWords: uniqueWords.length,
      frequentWords: frequentWords,
      educationalWords: educationalWordsFound.toList(),
      averageReadingLevel: _calculateAverageReadingLevel(),
      sessionDuration: _sessionStartTime != null 
          ? DateTime.now().difference(_sessionStartTime!)
          : Duration.zero,
    );
  }

  double _calculateAverageReadingLevel() {
    if (_capturedSubtitles.isEmpty) return 0.0;
    
    double totalLevel = 0;
    for (final subtitle in _capturedSubtitles) {
      totalLevel += _calculateReadingLevel(subtitle.text);
    }
    
    return totalLevel / _capturedSubtitles.length;
  }

  // Stop tracking
  void stopTracking() {
    _trackingTimer?.cancel();
    _currentVideoId = null;
    _sessionStartTime = null;
  }

  void dispose() {
    stopTracking();
    _subtitleController.close();
  }
}

// Data models
class SubtitleEntry {
  final String text;
  final Duration startTime;
  final Duration endTime;
  final String videoId;
  final DateTime timestamp;

  SubtitleEntry({
    required this.text,
    required this.startTime,
    required this.endTime,
    required this.videoId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'startTime': startTime.inSeconds,
    'endTime': endTime.inSeconds,
    'videoId': videoId,
    'timestamp': timestamp.toIso8601String(),
  };
}

class SubtitleEvent {
  final SubtitleEntry subtitle;
  final String childId;
  final List<String> educationalWords;
  final double readingLevel;
  final String sentiment;

  SubtitleEvent({
    required this.subtitle,
    required this.childId,
    required this.educationalWords,
    required this.readingLevel,
    required this.sentiment,
  });
}

class WordExposure {
  final String word;
  final DateTime firstSeen;
  final List<String> contexts;
  int exposureCount = 1;

  WordExposure({
    required this.word,
    required this.firstSeen,
    required this.contexts,
  });

  void incrementExposure(SubtitleEntry subtitle) {
    exposureCount++;
    if (!contexts.contains(subtitle.text)) {
      contexts.add(subtitle.text);
    }
  }
}

class VocabularyReport {
  final int totalUniqueWords;
  final List<String> frequentWords;
  final List<String> educationalWords;
  final double averageReadingLevel;
  final Duration sessionDuration;

  VocabularyReport({
    required this.totalUniqueWords,
    required this.frequentWords,
    required this.educationalWords,
    required this.averageReadingLevel,
    required this.sessionDuration,
  });

  Map<String, dynamic> toJson() => {
    'totalUniqueWords': totalUniqueWords,
    'frequentWords': frequentWords,
    'educationalWords': educationalWords,
    'averageReadingLevel': averageReadingLevel,
    'sessionDurationMinutes': sessionDuration.inMinutes,
  };
}