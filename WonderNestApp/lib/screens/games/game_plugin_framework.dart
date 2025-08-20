import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/games/game_plugin.dart';
import '../../core/games/game_initialization.dart';
import '../../providers/game_provider.dart';
import '../../providers/app_mode_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/timber_wrapper.dart';

/// Framework for running game plugins
class GamePluginFramework extends ConsumerStatefulWidget {
  final String gameId;
  final String childId;
  final String childName;

  const GamePluginFramework({
    super.key,
    required this.gameId,
    required this.childId,
    required this.childName,
  });

  @override
  ConsumerState<GamePluginFramework> createState() => _GamePluginFrameworkState();
}

class _GamePluginFrameworkState extends ConsumerState<GamePluginFramework> {
  String? sessionId;
  GamePlugin? gamePlugin;
  GameSession? gameSession;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    try {
      Timber.d('[GAME] Initializing game plugin: ${widget.gameId}');
      
      // Ensure game system is initialized before accessing registry
      await ref.read(gameInitializationProvider.future);
      
      // Get the game plugin from initialized registry
      final registry = await ref.read(initializedGameRegistryProvider.future);
      gamePlugin = registry.getGame(widget.gameId);
      
      if (gamePlugin == null) {
        setState(() {
          error = 'Game "${widget.gameId}" not found';
          isLoading = false;
        });
        return;
      }

      // Check if game is appropriate for child
      final activeChild = ref.read(activeChildProvider);
      if (activeChild != null && !gamePlugin!.isAppropriateForChild(activeChild)) {
        setState(() {
          error = 'This game is not appropriate for ${widget.childName}\'s age';
          isLoading = false;
        });
        return;
      }

      // Create a new game session
      sessionId = const Uuid().v4();
      gameSession = GameSession(
        sessionId: sessionId!,
        gameId: widget.gameId,
        childId: widget.childId,
        startTime: DateTime.now(),
      );

      Timber.d('[GAME] Game plugin initialized successfully');
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      Timber.e('[ERROR] Failed to initialize game: $e');
      setState(() {
        error = 'Failed to start game: $e';
        isLoading = false;
      });
    }
  }

  Future<bool> _onWillPop() async {
    // Show exit confirmation dialog
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Exit Game?'),
        content: const Text('Are you sure you want to exit the game? Your progress will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Playing'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warningOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit Game'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      await _endGameSession();
      if (mounted) {
        context.go('/child-home');
      }
    }

    return false; // Prevent automatic pop
  }

  Future<void> _endGameSession() async {
    if (sessionId != null) {
      try {
        // Get the session notifier and end the session
        final sessionParams = GameSessionParams(
          sessionId: sessionId!,
          gameId: widget.gameId,
          childId: widget.childId,
        );
        
        final sessionNotifier = ref.read(gameSessionProvider(sessionParams).notifier);
        await sessionNotifier.endSession(saveProgress: true);
        
        Timber.d('[GAME] Game session ended successfully');
      } catch (e) {
        Timber.e('[ERROR] Failed to end game session: $e');
      }
    }
  }

  @override
  void dispose() {
    // End session when disposing (if not already ended)
    _endGameSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.kidBackgroundLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.kidSafeBlue),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading ${gamePlugin?.gameName ?? 'game'}...',
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error state
    if (error != null) {
      return Scaffold(
        backgroundColor: AppColors.kidBackgroundLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.warningOrange,
              ),
              const SizedBox(height: 20),
              Text(
                'Oops!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => context.go('/child-home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kidSafeBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text('Go Back to Toy Box'),
              ),
            ],
          ),
        ),
      );
    }

    // Show the actual game
    if (gamePlugin != null && gameSession != null && sessionId != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          await _onWillPop();
        },
        child: Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                // Game content
                Consumer(
                  builder: (context, ref, child) {
                    final activeChild = ref.watch(activeChildProvider);
                    if (activeChild == null) {
                      return const Center(
                        child: Text('No active child found'),
                      );
                    }

                    // Create the game widget using the plugin
                    return gamePlugin!.createGameWidget(
                      child: activeChild,
                      session: gameSession!,
                      ref: ref,
                    );
                  },
                ),
                
                // Exit button overlay
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: IconButton(
                      onPressed: _onWillPop,
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Fallback state
    return Scaffold(
      backgroundColor: AppColors.kidBackgroundLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.games,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 20),
            const Text(
              'Game not available',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/child-home'),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}