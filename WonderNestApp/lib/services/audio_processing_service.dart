import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class AudioProcessingService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final SpeechToText _speechToText = SpeechToText();
  
  StreamController<AudioAnalysisResult>? _analysisController;
  StreamController<String>? _transcriptionController;
  Timer? _recordingTimer;
  
  bool _isRecording = false;
  bool _isInitialized = false;
  List<String> _keywordList = [];
  List<String> _inappropriateWords = [];
  
  // Privacy-first: No raw audio is stored or transmitted
  static const bool storeRawAudio = false;
  static const int maxRecordingDurationSeconds = 30;
  
  Stream<AudioAnalysisResult> get analysisStream =>
      _analysisController?.stream ?? const Stream.empty();
      
  Stream<String> get transcriptionStream =>
      _transcriptionController?.stream ?? const Stream.empty();
  
  bool get isRecording => _isRecording;

  Future<bool> initialize() async {
    try {
      // Check and request microphone permission
      final status = await Permission.microphone.status;
      if (!status.isGranted) {
        final result = await Permission.microphone.request();
        if (!result.isGranted) {
          return false;
        }
      }
      
      // Initialize speech recognition
      _isInitialized = await _speechToText.initialize(
        onError: (error) => _handleError(error.errorMsg),
        onStatus: (status) => _handleStatus(status),
      );
      
      // Initialize stream controllers
      _analysisController = StreamController<AudioAnalysisResult>.broadcast();
      _transcriptionController = StreamController<String>.broadcast();
      
      // Load keyword lists
      await _loadKeywordLists();
      
      return _isInitialized;
    } catch (e) {
      debugPrint('Error initializing audio service: $e');
      return false;
    }
  }

  Future<void> _loadKeywordLists() async {
    // In production, load these from secure storage or API
    _keywordList = [
      'help', 'stop', 'hurt', 'scared', 'emergency',
      'mom', 'dad', 'parent', 'adult',
    ];
    
    _inappropriateWords = [
      // Load inappropriate word list for content filtering
      // This should be age-appropriate and customizable by parents
    ];
  }

  Future<void> startRecording({
    required String childId,
    bool continuousMonitoring = false,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_isRecording) return;
    
    try {
      // Check if recording is possible
      if (await _audioRecorder.hasPermission()) {
        _isRecording = true;
        
        // Start speech recognition for transcription
        await _startSpeechRecognition();
        
        // Start recording with privacy-first settings
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 64000, // Lower bitrate for privacy
            sampleRate: 16000, // Sufficient for speech
            numChannels: 1, // Mono audio
          ),
          path: await _getTempAudioPath(),
        );
        
        // Set maximum recording duration for privacy
        _recordingTimer = Timer(
          Duration(seconds: maxRecordingDurationSeconds),
          () => stopRecording(),
        );
        
        // Start continuous analysis if requested
        if (continuousMonitoring) {
          _startContinuousAnalysis();
        }
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      _isRecording = false;
    }
  }

  Future<void> _startSpeechRecognition() async {
    await _speechToText.listen(
      onResult: (result) {
        if (result.hasConfidenceRating && result.confidence > 0.5) {
          final text = result.recognizedWords;
          
          // Stream transcription
          _transcriptionController?.add(text);
          
          // Analyze for keywords
          _analyzeTranscription(text);
        }
      },
      listenFor: Duration(seconds: maxRecordingDurationSeconds),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      onDevice: true, // Use on-device recognition for privacy
      listenMode: ListenMode.confirmation,
    );
  }

  void _analyzeTranscription(String text) {
    final lowercaseText = text.toLowerCase();
    final detectedKeywords = <String>[];
    final detectedInappropriate = <String>[];
    
    // Check for keywords
    for (final keyword in _keywordList) {
      if (lowercaseText.contains(keyword)) {
        detectedKeywords.add(keyword);
      }
    }
    
    // Check for inappropriate content
    for (final word in _inappropriateWords) {
      if (lowercaseText.contains(word)) {
        detectedInappropriate.add(word);
      }
    }
    
    // Create analysis result
    final result = AudioAnalysisResult(
      timestamp: DateTime.now(),
      transcribedText: text,
      detectedKeywords: detectedKeywords,
      inappropriateContent: detectedInappropriate,
      sentimentScore: _calculateSentiment(text),
      volumeLevel: 0.0, // Would be calculated from audio amplitude
      requiresAttention: detectedKeywords.isNotEmpty || 
                         detectedInappropriate.isNotEmpty,
    );
    
    _analysisController?.add(result);
  }

  double _calculateSentiment(String text) {
    // Simple sentiment analysis
    // In production, use a proper NLP model
    final positiveWords = ['happy', 'good', 'great', 'fun', 'love', 'like'];
    final negativeWords = ['sad', 'bad', 'hurt', 'angry', 'hate', 'scared'];
    
    int positiveCount = 0;
    int negativeCount = 0;
    
    final words = text.toLowerCase().split(' ');
    for (final word in words) {
      if (positiveWords.contains(word)) positiveCount++;
      if (negativeWords.contains(word)) negativeCount++;
    }
    
    if (positiveCount + negativeCount == 0) return 0.5;
    
    return positiveCount / (positiveCount + negativeCount);
  }

  void _startContinuousAnalysis() {
    // Implement continuous background analysis
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      
      // Perform periodic analysis tasks
      _performBackgroundAnalysis();
    });
  }

  void _performBackgroundAnalysis() {
    // Background analysis logic
    // This could include:
    // - Volume level monitoring
    // - Background noise detection
    // - Speech pattern analysis
    // All processed on-device for privacy
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;
    
    try {
      _isRecording = false;
      _recordingTimer?.cancel();
      
      // Stop speech recognition
      await _speechToText.stop();
      
      // Stop audio recording
      final path = await _audioRecorder.stop();
      
      if (path != null && !storeRawAudio) {
        // Delete the audio file immediately for privacy
        await _deleteAudioFile(path);
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<String> _getTempAudioPath() async {
    final directory = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${directory.path}/temp_audio_$timestamp.m4a';
  }

  Future<void> _deleteAudioFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting audio file: $e');
    }
  }

  void _handleError(String error) {
    debugPrint('Speech recognition error: $error');
    _analysisController?.addError(error);
  }

  void _handleStatus(String status) {
    debugPrint('Speech recognition status: $status');
  }

  Future<AudioPermissionStatus> checkAudioPermission() async {
    final micStatus = await Permission.microphone.status;
    final speechStatus = await Permission.speech.status;
    
    return AudioPermissionStatus(
      hasMicrophonePermission: micStatus.isGranted,
      hasSpeechPermission: speechStatus.isGranted,
      isPermanentlyDenied: micStatus.isPermanentlyDenied || 
                           speechStatus.isPermanentlyDenied,
    );
  }

  Future<bool> requestAudioPermissions() async {
    final micResult = await Permission.microphone.request();
    final speechResult = await Permission.speech.request();
    
    return micResult.isGranted && speechResult.isGranted;
  }

  void dispose() {
    _recordingTimer?.cancel();
    _analysisController?.close();
    _transcriptionController?.close();
    if (_isRecording) {
      stopRecording();
    }
  }
}

class AudioAnalysisResult {
  final DateTime timestamp;
  final String transcribedText;
  final List<String> detectedKeywords;
  final List<String> inappropriateContent;
  final double sentimentScore;
  final double volumeLevel;
  final bool requiresAttention;

  AudioAnalysisResult({
    required this.timestamp,
    required this.transcribedText,
    required this.detectedKeywords,
    required this.inappropriateContent,
    required this.sentimentScore,
    required this.volumeLevel,
    required this.requiresAttention,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'transcribedText': transcribedText,
    'detectedKeywords': detectedKeywords,
    'inappropriateContent': inappropriateContent,
    'sentimentScore': sentimentScore,
    'volumeLevel': volumeLevel,
    'requiresAttention': requiresAttention,
  };
}

class AudioPermissionStatus {
  final bool hasMicrophonePermission;
  final bool hasSpeechPermission;
  final bool isPermanentlyDenied;

  AudioPermissionStatus({
    required this.hasMicrophonePermission,
    required this.hasSpeechPermission,
    required this.isPermanentlyDenied,
  });

  bool get hasAllPermissions => 
      hasMicrophonePermission && hasSpeechPermission;
}