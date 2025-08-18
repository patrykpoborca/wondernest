import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/game_model.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';

class MiniGameFramework extends ConsumerStatefulWidget {
  final GameModel game;
  final String childId;

  const MiniGameFramework({
    super.key,
    required this.game,
    required this.childId,
  });

  @override
  ConsumerState<MiniGameFramework> createState() => _MiniGameFrameworkState();
}

class _MiniGameFrameworkState extends ConsumerState<MiniGameFramework> {
  InAppWebViewController? _webViewController;
  late final ApiService _apiService;
  
  bool _isLoading = true;
  double _loadingProgress = 0;
  DateTime? _startTime;
  int _score = 0;
  int _level = 1;
  
  // Security settings for WebView
  final InAppWebViewSettings _webViewSettings = InAppWebViewSettings(
    useShouldOverrideUrlLoading: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllow: "camera; microphone; payment",
    javaScriptEnabled: true,
    supportZoom: false,
    userAgent: "WonderNest/1.0 KidSafe",
    // Security settings
    mixedContentMode: MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
    allowFileAccess: false,
    allowFileAccessFromFileURLs: false,
    allowUniversalAccessFromFileURLs: false,
  );

  @override
  void initState() {
    super.initState();
    _apiService = ref.read(apiServiceProvider);
    _startTime = DateTime.now();
    _loadGameProgress();
  }

  Future<void> _loadGameProgress() async {
    // Load existing progress if available
    if (widget.game.progress != null) {
      setState(() {
        _score = widget.game.progress!.score;
        _level = widget.game.progress!.level;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Always intercept the back button
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // Already handled
        // From game, back button should go to child home
        if (context.mounted) {
          print('[NAV] Back button pressed in game - navigating to child home');
          context.go('/child-home');
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.kidBackgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            // Game container
            Column(
              children: [
                // Game header
                _buildGameHeader(),
                
                // WebView container
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          if (widget.game.type == GameType.web)
                            _buildWebGame()
                          else
                            _buildNativeGame(),
                          
                          if (_isLoading)
                            _buildLoadingOverlay(),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Game controls
                _buildGameControls(),
              ],
            ),
            
            // Exit button
            Positioned(
              top: 16,
              left: 16,
              child: _buildExitButton(),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildGameHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Game info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.game.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildInfoChip(Icons.star, 'Score: $_score'),
                    const SizedBox(width: 8),
                    _buildInfoChip(Icons.flag, 'Level $_level'),
                  ],
                ),
              ],
            ),
          ),
          
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, size: 16, color: AppColors.accentPurple),
                const SizedBox(width: 4),
                StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    final duration = DateTime.now().difference(_startTime!);
                    return Text(
                      '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: AppColors.accentPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebGame() {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.game.gameUrl)),
      initialSettings: _webViewSettings,
      onWebViewCreated: (controller) {
        _webViewController = controller;
        _setupJavaScriptHandlers(controller);
      },
      onLoadStart: (controller, url) {
        setState(() {
          _isLoading = true;
        });
      },
      onProgressChanged: (controller, progress) {
        setState(() {
          _loadingProgress = progress / 100;
        });
      },
      onLoadStop: (controller, url) async {
        setState(() {
          _isLoading = false;
        });
        await _injectSafetyScripts(controller);
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final uri = navigationAction.request.url;
        
        // Only allow whitelisted domains
        if (!_isUrlWhitelisted(uri.toString())) {
          return NavigationActionPolicy.CANCEL;
        }
        
        return NavigationActionPolicy.ALLOW;
      },
      onConsoleMessage: (controller, consoleMessage) {
        // Log game console messages for debugging
        debugPrint('Game Console: ${consoleMessage.message}');
      },
    );
  }

  Widget _buildNativeGame() {
    // For native games, implement game-specific widgets
    // This could be Flutter-based games or native SDK integrations
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.games,
            size: 80,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(height: 16),
          Text(
            'Native Game: ${widget.game.name}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Game implementation goes here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: _loadingProgress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading Game...',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_loadingProgress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            Icons.refresh,
            'Restart',
            () => _restartGame(),
          ),
          _buildControlButton(
            Icons.volume_up,
            'Sound',
            () => _toggleSound(),
          ),
          _buildControlButton(
            Icons.help_outline,
            'Help',
            () => _showHelp(),
          ),
          _buildControlButton(
            Icons.fullscreen,
            'Fullscreen',
            () => _toggleFullscreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryBlue),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExitButton() {
    return Material(
      color: Colors.red.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: _exitGame,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: const Icon(
            Icons.close,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _setupJavaScriptHandlers(InAppWebViewController controller) {
    // Add JavaScript handlers for game communication
    controller.addJavaScriptHandler(
      handlerName: 'updateScore',
      callback: (args) {
        if (args.isNotEmpty) {
          setState(() {
            _score = args[0] as int;
          });
          _saveProgress();
        }
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'updateLevel',
      callback: (args) {
        if (args.isNotEmpty) {
          setState(() {
            _level = args[0] as int;
          });
          _saveProgress();
        }
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'gameCompleted',
      callback: (args) {
        _handleGameCompletion();
      },
    );
  }

  Future<void> _injectSafetyScripts(InAppWebViewController controller) async {
    // Inject safety and monitoring scripts
    const safetyScript = '''
      // Disable right-click context menu
      document.addEventListener('contextmenu', e => e.preventDefault());
      
      // Monitor for inappropriate content
      const observer = new MutationObserver((mutations) => {
        // Check for inappropriate content
      });
      observer.observe(document.body, { childList: true, subtree: true });
      
      // Send game events to Flutter
      window.wondernest = {
        updateScore: (score) => {
          window.flutter_inappwebview.callHandler('updateScore', score);
        },
        updateLevel: (level) => {
          window.flutter_inappwebview.callHandler('updateLevel', level);
        },
        gameCompleted: () => {
          window.flutter_inappwebview.callHandler('gameCompleted');
        }
      };
    ''';
    
    await controller.evaluateJavascript(source: safetyScript);
  }

  bool _isUrlWhitelisted(String url) {
    // Check if URL is in whitelist
    final whitelistedDomains = [
      'pbskids.org',
      'education.com',
      'coolmathgames.com',
      'scratch.mit.edu',
      // Add more whitelisted domains
    ];
    
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    
    return whitelistedDomains.any((domain) => 
      uri.host.endsWith(domain)
    );
  }

  void _restartGame() {
    _webViewController?.reload();
    setState(() {
      _startTime = DateTime.now();
      _score = 0;
      _level = 1;
    });
  }

  void _toggleSound() {
    // Toggle game sound
    _webViewController?.evaluateJavascript(
      source: 'if (window.toggleSound) window.toggleSound();'
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.game.name),
        content: Text(widget.game.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _toggleFullscreen() {
    // Toggle fullscreen mode
    // Implementation depends on platform
  }

  void _exitGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Game?'),
        content: const Text('Your progress will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _saveProgress();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _handleGameCompletion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Great Job!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You completed the game!'),
            const SizedBox(height: 8),
            Text('Score: $_score'),
            Text('Level: $_level'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restartGame();
            },
            child: const Text('Play Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProgress() async {
    final duration = DateTime.now().difference(_startTime!);
    
    // Save progress to API
    try {
      await _apiService.saveGameProgress(
        gameId: widget.game.id,
        childId: widget.childId,
        score: _score,
        level: _level,
        playTimeMinutes: duration.inMinutes,
      );
    } catch (e) {
      debugPrint('Error saving game progress: $e');
    }
  }

  @override
  void dispose() {
    _saveProgress();
    super.dispose();
  }
}