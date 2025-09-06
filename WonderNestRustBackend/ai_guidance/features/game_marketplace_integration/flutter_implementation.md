# Flutter Code Structures for Game-Marketplace Integration

## Core Service Layer

### GameContentService Implementation
Handles all marketplace content interactions with proper error handling and caching:

```dart
class GameContentServiceImpl implements GameContentService {
  final ApiService _apiService;
  final CacheManager _cacheManager;
  final ChildProfileService _childProfileService;
  final ParentApprovalService _parentApprovalService;
  
  GameContentServiceImpl({
    required ApiService apiService,
    required CacheManager cacheManager,
    required ChildProfileService childProfileService,
    required ParentApprovalService parentApprovalService,
  }) : _apiService = apiService,
       _cacheManager = cacheManager,
       _childProfileService = childProfileService,
       _parentApprovalService = parentApprovalService;

  @override
  Future<List<ContentPack>> getAvailableContentPacks({
    required String childId,
    required String gameId,
    ContentPackFilter? filter,
  }) async {
    try {
      // Check child permissions and age appropriateness
      final childProfile = await _childProfileService.getChildProfile(childId);
      if (childProfile == null) {
        throw ContentAccessException('Child profile not found');
      }
      
      // Build API request with child-safe filters
      final request = ContentPacksRequest(
        childId: childId,
        gameId: gameId,
        ageRange: AgeRange(
          min: childProfile.age * 12 - 6, // Age in months with tolerance
          max: childProfile.age * 12 + 12,
        ),
        filter: filter,
        includeApprovedOnly: true, // Only show parent-approved content
      );
      
      // Fetch from API with retry logic
      final response = await _apiService.getContentPacks(request);
      
      if (response.isSuccess) {
        final contentPacks = response.data!
            .map((data) => ContentPack.fromJson(data))
            .toList();
            
        // Cache for offline access
        await _cacheContentPackList(childId, gameId, contentPacks);
        
        return contentPacks;
      } else {
        // Fallback to cached content
        return await _getCachedContentPacks(childId, gameId);
      }
      
    } catch (e, stackTrace) {
      Timber.e('Failed to get available content packs: $e', stackTrace: stackTrace);
      
      // Always try cache fallback for child experience continuity
      return await _getCachedContentPacks(childId, gameId);
    }
  }

  @override
  Future<bool> isContentPackAccessible({
    required String childId,
    required String contentPackId,
  }) async {
    try {
      // Check parental approval first
      final hasApproval = await _parentApprovalService.hasApproval(
        childId: childId,
        contentPackId: contentPackId,
      );
      
      if (!hasApproval) return false;
      
      // Check if content is in child's library
      final isInLibrary = await _apiService.isContentInChildLibrary(
        childId: childId,
        contentPackId: contentPackId,
      );
      
      return isInLibrary;
      
    } catch (e) {
      Timber.e('Failed to check content pack accessibility: $e');
      return false; // Fail safe - deny access on error
    }
  }

  @override
  Future<ContentPackAssets> downloadContentPack({
    required String childId,
    required String contentPackId,
    ProgressCallback? onProgress,
  }) async {
    // Verify access permissions
    final hasAccess = await isContentPackAccessible(
      childId: childId,
      contentPackId: contentPackId,
    );
    
    if (!hasAccess) {
      throw ContentAccessException('Content pack access denied');
    }
    
    // Use GameContentCacheManager for actual download
    final assets = await GameContentCacheManager.getContentPack(
      childId: childId,
      contentPackId: contentPackId,
    );
    
    if (assets == null) {
      throw ContentDownloadException('Failed to download content pack');
    }
    
    // Track download for analytics (privacy-compliant)
    await _trackContentDownload(childId, contentPackId);
    
    return assets;
  }
  
  Future<void> _trackContentDownload(String childId, String contentPackId) async {
    final event = AnalyticsEvent(
      type: AnalyticsEventType.contentDownloaded,
      anonymizedChildId: await _anonymizeChildId(childId),
      properties: {
        'content_pack_id': contentPackId,
        'download_timestamp': DateTime.now().toIso8601String(),
      },
    );
    
    await AnalyticsService.trackEvent(event);
  }
}

// Provider setup for dependency injection
final gameContentServiceProvider = Provider<GameContentService>((ref) {
  return GameContentServiceImpl(
    apiService: ref.read(apiServiceProvider),
    cacheManager: ref.read(cacheManagerProvider),
    childProfileService: ref.read(childProfileServiceProvider),
    parentApprovalService: ref.read(parentApprovalServiceProvider),
  );
});

// State management for content discovery
final availableContentProvider = FutureProvider.autoDispose
    .family<List<ContentPack>, ContentRequest>((ref, request) async {
  final service = ref.read(gameContentServiceProvider);
  return service.getAvailableContentPacks(
    childId: request.childId,
    gameId: request.gameId,
    filter: request.filter,
  );
});
```

## Child-Friendly UI Components

### Animated Content Discovery Cards
Cards that feel magical and engaging for children:

```dart
class MagicalContentCard extends ConsumerStatefulWidget {
  final ContentPack contentPack;
  final VoidCallback? onTap;
  final bool showNewBadge;
  final bool showProgressIndicator;
  
  const MagicalContentCard({
    Key? key,
    required this.contentPack,
    this.onTap,
    this.showNewBadge = false,
    this.showProgressIndicator = false,
  }) : super(key: key);

  @override
  ConsumerState<MagicalContentCard> createState() => _MagicalContentCardState();
}

class _MagicalContentCardState extends ConsumerState<MagicalContentCard>
    with TickerProviderStateMixin {
  
  late AnimationController _hoverController;
  late AnimationController _sparkleController;
  late AnimationController _progressController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _progressAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _hoverController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    
    _sparkleController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _progressController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
    
    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.contentPack.completionProgress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOut,
    ));
    
    if (widget.showProgressIndicator) {
      _progressController.forward();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _sparkleAnimation,
        _progressAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 160,
            height: 200,
            margin: EdgeInsets.only(right: 16),
            child: Stack(
              children: [
                // Main card
                Positioned.fill(
                  child: _buildMainCard(),
                ),
                
                // Sparkle effect for new content
                if (widget.showNewBadge)
                  Positioned.fill(
                    child: _buildSparkleEffect(),
                  ),
                  
                // New badge
                if (widget.showNewBadge)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildNewBadge(),
                  ),
                  
                // Progress indicator
                if (widget.showProgressIndicator)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: _buildProgressIndicator(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMainCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.contentPack.primaryColor.withOpacity(0.9),
            widget.contentPack.secondaryColor.withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: widget.contentPack.primaryColor.withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: widget.onTap,
          onTapDown: (_) => _hoverController.forward(),
          onTapUp: (_) => _hoverController.reverse(),
          onTapCancel: () => _hoverController.reverse(),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Content preview image
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: widget.contentPack.previewImageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.contentPack.previewImageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => 
                                  ShimmerPlaceholder(height: double.infinity),
                              errorWidget: (context, url, error) =>
                                  _buildFallbackImage(),
                            )
                          : _buildFallbackImage(),
                    ),
                  ),
                ),
                
                SizedBox(height: 12),
                
                // Title
                Expanded(
                  flex: 1,
                  child: Text(
                    widget.contentPack.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                SizedBox(height: 4),
                
                // Learning objective with icon
                Row(
                  children: [
                    Icon(
                      widget.contentPack.learningIcon,
                      size: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.contentPack.primaryLearningObjective,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSparkleEffect() {
    return CustomPaint(
      painter: SparklePainter(
        animation: _sparkleAnimation.value,
        color: Colors.yellow,
      ),
    );
  }
  
  Widget _buildNewBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.5),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'NEW!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildProgressIndicator() {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        widthFactor: _progressAnimation.value,
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFallbackImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        widget.contentPack.fallbackIcon,
        size: 40,
        color: Colors.white.withOpacity(0.8),
      ),
    );
  }
  
  @override
  void dispose() {
    _hoverController.dispose();
    _sparkleController.dispose();
    _progressController.dispose();
    super.dispose();
  }
}

// Custom painter for sparkle effects
class SparklePainter extends CustomPainter {
  final double animation;
  final Color color;
  
  SparklePainter({
    required this.animation,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6 * (1.0 - animation))
      ..style = PaintingStyle.fill;
    
    final sparkles = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.7, size.height * 0.7),
      Offset(size.width * 0.3, size.height * 0.8),
    ];
    
    for (int i = 0; i < sparkles.length; i++) {
      final sparkle = sparkles[i];
      final phase = (animation + i * 0.25) % 1.0;
      final sparkleSize = 8 * sin(phase * pi);
      
      if (sparkleSize > 0) {
        _drawSparkle(canvas, sparkle, sparkleSize, paint);
      }
    }
  }
  
  void _drawSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    
    // Create a 4-pointed star
    for (int i = 0; i < 4; i++) {
      final angle = (i * pi / 2);
      final outerPoint = Offset(
        center.dx + cos(angle) * size,
        center.dy + sin(angle) * size,
      );
      final innerAngle = angle + pi / 4;
      final innerPoint = Offset(
        center.dx + cos(innerAngle) * size * 0.4,
        center.dy + sin(innerAngle) * size * 0.4,
      );
      
      if (i == 0) {
        path.moveTo(outerPoint.dx, outerPoint.dy);
      } else {
        path.lineTo(outerPoint.dx, outerPoint.dy);
      }
      path.lineTo(innerPoint.dx, innerPoint.dy);
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant SparklePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
```

### Achievement-Based Content Unlock Celebration
Celebrates content unlocks through educational achievements:

```dart
class ContentUnlockCelebration extends ConsumerStatefulWidget {
  final ContentPack unlockedContent;
  final Achievement triggeringAchievement;
  final VoidCallback onComplete;
  
  const ContentUnlockCelebration({
    Key? key,
    required this.unlockedContent,
    required this.triggeringAchievement,
    required this.onComplete,
  }) : super(key: key);

  @override
  ConsumerState<ContentUnlockCelebration> createState() => 
      _ContentUnlockCelebrationState();
}

class _ContentUnlockCelebrationState 
    extends ConsumerState<ContentUnlockCelebration>
    with TickerProviderStateMixin {
    
  late AnimationController _mainController;
  late AnimationController _confettiController;
  late AnimationController _bounceController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _confettiController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _setupAnimations();
    _startCelebration();
  }
  
  void _setupAnimations() {
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Interval(0.2, 0.8, curve: Curves.easeIn),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Interval(0.4, 1.0, curve: Curves.easeOut),
    ));
    
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticInOut,
    ));
  }
  
  void _startCelebration() async {
    // Start confetti immediately
    _confettiController.forward();
    
    // Main animation sequence
    await _mainController.forward();
    
    // Bounce animation for emphasis
    await _bounceController.forward();
    await _bounceController.reverse();
    
    // Wait a moment for child to appreciate
    await Future.delayed(Duration(seconds: 2));
    
    // Complete callback
    widget.onComplete();
  }
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.8),
      child: Stack(
        children: [
          // Confetti background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) => CustomPaint(
                painter: ConfettiPainter(
                  animation: _confettiController.value,
                ),
              ),
            ),
          ),
          
          // Main celebration content
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _scaleAnimation,
                _fadeAnimation,
                _slideAnimation,
                _bounceAnimation,
              ]),
              builder: (context, child) => Transform.scale(
                scale: _scaleAnimation.value * _bounceAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildCelebrationContent(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCelebrationContent() {
    return Container(
      width: 300,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Achievement celebration
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: widget.triggeringAchievement.color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.triggeringAchievement.icon,
              size: 40,
              color: Colors.white,
            ),
          ),
          
          SizedBox(height: 16),
          
          // Achievement title
          Text(
            'Achievement Unlocked!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.triggeringAchievement.color,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 8),
          
          Text(
            widget.triggeringAchievement.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 16),
          
          // Divider
          Container(
            height: 1,
            margin: EdgeInsets.symmetric(horizontal: 20),
            color: Colors.grey[300],
          ),
          
          SizedBox(height: 16),
          
          // New content unlock message
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber,
                size: 24,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You\'ve unlocked something special!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Content preview
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  widget.unlockedContent.primaryColor,
                  widget.unlockedContent.secondaryColor,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Background pattern
                Positioned.fill(
                  child: CustomPaint(
                    painter: PatternPainter(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                
                // Content info
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.unlockedContent.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Icon(
                            widget.unlockedContent.learningIcon,
                            size: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.unlockedContent.primaryLearningObjective,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to content or close celebration
                widget.onComplete();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.unlockedContent.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Explore Now!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _mainController.dispose();
    _confettiController.dispose();
    _bounceController.dispose();
    super.dispose();
  }
}

// Confetti painter for celebration background
class ConfettiPainter extends CustomPainter {
  final double animation;
  static final Random _random = Random();
  static List<ConfettiParticle>? _particles;
  
  ConfettiPainter({required this.animation});
  
  @override
  void paint(Canvas canvas, Size size) {
    // Initialize particles on first paint
    _particles ??= List.generate(50, (index) => ConfettiParticle(
      x: _random.nextDouble() * size.width,
      y: -50.0,
      color: _getRandomColor(),
      size: _random.nextDouble() * 6 + 4,
      velocity: _random.nextDouble() * 3 + 2,
      rotation: _random.nextDouble() * 2 * pi,
      rotationSpeed: (_random.nextDouble() - 0.5) * 10,
    ));
    
    for (final particle in _particles!) {
      _drawParticle(canvas, particle, size);
    }
  }
  
  void _drawParticle(Canvas canvas, ConfettiParticle particle, Size size) {
    final paint = Paint()
      ..color = particle.color
      ..style = PaintingStyle.fill;
    
    final currentY = particle.y + (animation * size.height * 1.2);
    final currentRotation = particle.rotation + (animation * particle.rotationSpeed);
    
    canvas.save();
    canvas.translate(particle.x, currentY);
    canvas.rotate(currentRotation);
    
    // Draw confetti shape (rectangle)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.6,
        ),
        Radius.circular(1),
      ),
      paint,
    );
    
    canvas.restore();
  }
  
  Color _getRandomColor() {
    final colors = [
      Colors.red[400]!,
      Colors.blue[400]!,
      Colors.green[400]!,
      Colors.yellow[400]!,
      Colors.purple[400]!,
      Colors.orange[400]!,
    ];
    return colors[_random.nextInt(colors.length)];
  }
  
  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class ConfettiParticle {
  final double x;
  final double y;
  final Color color;
  final double size;
  final double velocity;
  final double rotation;
  final double rotationSpeed;
  
  ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.velocity,
    required this.rotation,
    required this.rotationSpeed,
  });
}
```

## State Management Architecture

### Riverpod Providers for Content Management
Comprehensive state management for content discovery and access:

```dart
// Core content providers
final childContentLibraryProvider = FutureProvider.autoDispose
    .family<ChildLibrary, String>((ref, childId) async {
  final service = ref.read(gameContentServiceProvider);
  return service.getChildLibrary(childId);
});

final contentPackDetailsProvider = FutureProvider.autoDispose
    .family<ContentPackDetails?, String>((ref, contentPackId) async {
  final service = ref.read(gameContentServiceProvider);
  return service.getContentPackDetails(contentPackId);
});

final contentDownloadProgressProvider = StreamProvider.autoDispose
    .family<DownloadProgress, String>((ref, contentPackId) {
  return GameContentCacheManager.getDownloadProgressStream(contentPackId);
});

// Content discovery state
class ContentDiscoveryNotifier extends StateNotifier<ContentDiscoveryState> {
  final GameContentService _contentService;
  final ChildProfileService _childProfileService;
  
  ContentDiscoveryNotifier({
    required GameContentService contentService,
    required ChildProfileService childProfileService,
  }) : _contentService = contentService,
       _childProfileService = childProfileService,
       super(ContentDiscoveryState.initial());
  
  Future<void> loadContentForChild({
    required String childId,
    required String gameId,
    ContentPackFilter? filter,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );
    
    try {
      final childProfile = await _childProfileService.getChildProfile(childId);
      if (childProfile == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Child profile not found',
        );
        return;
      }
      
      final contentPacks = await _contentService.getAvailableContentPacks(
        childId: childId,
        gameId: gameId,
        filter: filter,
      );
      
      // Categorize content
      final newContent = contentPacks.where((c) => c.isNew).toList();
      final availableContent = contentPacks.where((c) => !c.isNew).toList();
      
      state = state.copyWith(
        isLoading: false,
        childProfile: childProfile,
        newContent: newContent,
        availableContent: availableContent,
        lastUpdated: DateTime.now(),
      );
      
    } catch (e, stackTrace) {
      Timber.e('Failed to load content for child: $e', stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  Future<void> requestContentAccess({
    required String contentPackId,
    required ContentAccessContext context,
  }) async {
    if (state.childProfile == null) return;
    
    try {
      final approvalStatus = await ParentApprovalSystem.requestContentApproval(
        childId: state.childProfile!.id,
        contentPackId: contentPackId,
        context: context,
      );
      
      // Update UI based on approval status
      switch (approvalStatus) {
        case ApprovalStatus.approved:
          // Content immediately available
          await _refreshContentList();
          break;
        case ApprovalStatus.pending:
          // Show pending state
          state = state.copyWith(
            pendingApprovals: [...state.pendingApprovals, contentPackId],
          );
          break;
        case ApprovalStatus.denied:
          // Show denied state (shouldn't happen from child request)
          break;
      }
      
    } catch (e) {
      Timber.e('Failed to request content access: $e');
    }
  }
  
  Future<void> downloadContent(String contentPackId) async {
    if (state.childProfile == null) return;
    
    try {
      state = state.copyWith(
        downloadingContent: [...state.downloadingContent, contentPackId],
      );
      
      final assets = await _contentService.downloadContentPack(
        childId: state.childProfile!.id,
        contentPackId: contentPackId,
      );
      
      state = state.copyWith(
        downloadingContent: state.downloadingContent
            .where((id) => id != contentPackId)
            .toList(),
        downloadedContent: [...state.downloadedContent, contentPackId],
      );
      
    } catch (e) {
      Timber.e('Failed to download content: $e');
      state = state.copyWith(
        downloadingContent: state.downloadingContent
            .where((id) => id != contentPackId)
            .toList(),
        error: 'Failed to download content',
      );
    }
  }
  
  Future<void> _refreshContentList() async {
    if (state.childProfile == null) return;
    
    await loadContentForChild(
      childId: state.childProfile!.id,
      gameId: state.currentGameId,
      filter: state.currentFilter,
    );
  }
}

// Provider for content discovery
final contentDiscoveryProvider = StateNotifierProvider
    .autoDispose<ContentDiscoveryNotifier, ContentDiscoveryState>((ref) {
  return ContentDiscoveryNotifier(
    contentService: ref.read(gameContentServiceProvider),
    childProfileService: ref.read(childProfileServiceProvider),
  );
});

// Content discovery state class
@freezed
class ContentDiscoveryState with _$ContentDiscoveryState {
  const factory ContentDiscoveryState({
    @Default(false) bool isLoading,
    @Default([]) List<ContentPack> newContent,
    @Default([]) List<ContentPack> availableContent,
    @Default([]) List<String> pendingApprovals,
    @Default([]) List<String> downloadingContent,
    @Default([]) List<String> downloadedContent,
    ChildProfile? childProfile,
    String? currentGameId,
    ContentPackFilter? currentFilter,
    DateTime? lastUpdated,
    String? error,
  }) = _ContentDiscoveryState;
  
  factory ContentDiscoveryState.initial() = _ContentDiscoveryState;
}
```

This comprehensive Flutter implementation provides:

1. **Robust Service Layer**: Handles all API interactions with proper error handling and caching
2. **Child-Friendly UI Components**: Engaging, animated interfaces that feel magical rather than commercial
3. **Achievement-Based Celebrations**: Content unlocks feel like natural game progression
4. **Comprehensive State Management**: Proper Riverpod architecture for scalable state handling
5. **COPPA-Compliant Design**: All interactions respect child privacy and require parental oversight

The implementation focuses on creating seamless, educational experiences that enhance gameplay while maintaining the highest standards of child safety and privacy protection.