import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../../providers/app_mode_provider.dart';
import '../../models/child_profile.dart';
import '../../models/game_model.dart';
import '../../core/theme/app_colors.dart';
import '../../services/audio_processing_service.dart';
import '../../services/subtitle_tracking_service.dart';

class EnhancedChildHome extends ConsumerStatefulWidget {
  const EnhancedChildHome({super.key});

  @override
  ConsumerState<EnhancedChildHome> createState() => _EnhancedChildHomeState();
}

class _EnhancedChildHomeState extends ConsumerState<EnhancedChildHome>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _floatController;
  
  final AudioProcessingService _audioService = AudioProcessingService();
  final SubtitleTrackingService _subtitleService = SubtitleTrackingService();
  
  bool _isListening = false;
  String? _lastCommand;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _initializeServices();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _floatController.dispose();
    _audioService.dispose();
    _subtitleService.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    // Initialize audio monitoring for safety
    await _audioService.initialize();
    
    // Listen for voice commands
    _audioService.transcriptionStream.listen((transcription) {
      _handleVoiceCommand(transcription);
    });
  }

  void _handleVoiceCommand(String command) {
    final lowercaseCommand = command.toLowerCase();
    
    setState(() {
      _lastCommand = command;
    });
    
    // Simple voice commands for kids
    if (lowercaseCommand.contains('play game')) {
      _navigateToGames();
    } else if (lowercaseCommand.contains('watch video')) {
      _navigateToVideos();
    } else if (lowercaseCommand.contains('story time')) {
      _navigateToStories();
    } else if (lowercaseCommand.contains('mom') || lowercaseCommand.contains('dad')) {
      _showParentModePrompt();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appMode = ref.watch(appModeProvider);
    final activeChild = appMode.activeChild;
    
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top bar with avatar and parent mode button
                _buildTopBar(activeChild),
                
                // Welcome message
                _buildWelcomeMessage(activeChild),
                
                // Main content area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Activity cards
                        _buildActivityGrid(),
                        
                        const SizedBox(height: 24),
                        
                        // Recently played
                        _buildRecentlyPlayed(),
                        
                        const SizedBox(height: 24),
                        
                        // Daily challenge
                        _buildDailyChallenge(),
                      ],
                    ),
                  ),
                ),
                
                // Voice assistant button
                _buildVoiceAssistant(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.kidModeBackground,
            AppColors.kidModeAccent.withOpacity(0.3),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Floating bubbles
          ...List.generate(5, (index) {
            return Positioned(
              left: 50.0 + (index * 80),
              top: 100.0 + (index * 60),
              child: AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0,
                      20 * _floatController.value,
                    ),
                    child: Container(
                      width: 60 + (index * 10).toDouble(),
                      height: 60 + (index * 10).toDouble(),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopBar(ChildProfile? child) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Child avatar
          Hero(
            tag: 'child_avatar',
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  child?.name[0] ?? 'K',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ).animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut)
              .shimmer(duration: 2.seconds, delay: 1.second),
          ),
          
          // Parent mode button (subtle)
          GestureDetector(
            onTap: _showParentModePrompt,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.supervisor_account,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Parents',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage(ChildProfile? child) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;
    
    if (hour < 12) {
      greeting = 'Good Morning';
      greetingIcon = Icons.wb_sunny;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.cloud;
    } else {
      greeting = 'Good Evening';
      greetingIcon = Icons.nights_stay;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                greetingIcon,
                color: Colors.yellow[700],
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                '$greeting, ${child?.name ?? 'Friend'}!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ).animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: -0.2, end: 0),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'What would you like to do today?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ).animate()
            .fadeIn(duration: 800.ms, delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildActivityGrid() {
    final activities = [
      _ActivityCard(
        title: 'Games',
        icon: Icons.games,
        color: Colors.purple,
        onTap: _navigateToGames,
      ),
      _ActivityCard(
        title: 'Videos',
        icon: Icons.play_circle_filled,
        color: Colors.red,
        onTap: _navigateToVideos,
      ),
      _ActivityCard(
        title: 'Stories',
        icon: Icons.book,
        color: Colors.blue,
        onTap: _navigateToStories,
      ),
      _ActivityCard(
        title: 'Learn',
        icon: Icons.school,
        color: Colors.green,
        onTap: _navigateToLearning,
      ),
      _ActivityCard(
        title: 'Art',
        icon: Icons.palette,
        color: Colors.orange,
        onTap: _navigateToArt,
      ),
      _ActivityCard(
        title: 'Music',
        icon: Icons.music_note,
        color: Colors.pink,
        onTap: _navigateToMusic,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        return activities[index]
            .animate()
            .fadeIn(duration: 500.ms, delay: Duration(milliseconds: index * 100))
            .scale(begin: const Offset(0.8, 0.8));
      },
    );
  }

  Widget _buildRecentlyPlayed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Continue Playing',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.games,
                      size: 40,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Game ${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ).animate()
                .fadeIn(duration: 500.ms, delay: Duration(milliseconds: 300 + index * 100))
                .slideX(begin: 0.2);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailyChallenge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.yellow[600]!,
            Colors.orange[600]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Challenge',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete 3 math problems!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward,
            color: Colors.white.withOpacity(0.8),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 600.ms, delay: 800.ms)
      .shimmer(duration: 2.seconds, delay: 2.seconds);
  }

  Widget _buildVoiceAssistant() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTapDown: (_) => _startListening(),
        onTapUp: (_) => _stopListening(),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: _isListening
                  ? [Colors.red[400]!, Colors.red[600]!]
                  : [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            ),
            boxShadow: [
              BoxShadow(
                color: (_isListening ? Colors.red : AppColors.primary)
                    .withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: _isListening ? 5 : 0,
              ),
            ],
          ),
          child: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            color: Colors.white,
            size: 40,
          ),
        ),
      ).animate(
        onPlay: (controller) => controller.repeat(),
      ).scale(
        duration: 1.seconds,
        begin: const Offset(1, 1),
        end: Offset(_isListening ? 1.1 : 1, _isListening ? 1.1 : 1),
      ),
    );
  }

  void _startListening() async {
    final hasPermission = await _audioService.checkAudioPermission();
    if (!hasPermission.hasAllPermissions) {
      await _audioService.requestAudioPermissions();
    }
    
    setState(() {
      _isListening = true;
    });
    
    await _audioService.startRecording(
      childId: ref.read(appModeProvider).activeChild?.id ?? '',
      continuousMonitoring: false,
    );
  }

  void _stopListening() {
    setState(() {
      _isListening = false;
    });
    
    _audioService.stopRecording();
  }

  void _showParentModePrompt() {
    context.go('/pin-entry?redirect=/parent-controls');
  }

  void _navigateToGames() {
    // Navigate to games section
    context.push('/game', extra: {
      'id': 'game_1',
      'name': 'Math Adventure',
      'description': 'Fun math learning game',
      'gameUrl': 'https://www.coolmathgames.com',
      'childId': ref.read(appModeProvider).activeChild?.id ?? '',
    });
  }

  void _navigateToVideos() {
    // Navigate to videos section
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Videos section coming soon!')),
    );
  }

  void _navigateToStories() {
    // Navigate to stories section
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stories section coming soon!')),
    );
  }

  void _navigateToLearning() {
    // Navigate to learning section
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Learning section coming soon!')),
    );
  }

  void _navigateToArt() {
    // Navigate to art section
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Art section coming soon!')),
    );
  }

  void _navigateToMusic() {
    // Navigate to music section
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Music section coming soon!')),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}