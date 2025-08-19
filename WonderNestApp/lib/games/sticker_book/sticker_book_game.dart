import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/games/game_plugin.dart';
import '../../core/theme/app_colors.dart';
import '../../models/child_profile.dart';
import 'sticker_book_plugin.dart';
import 'models/sticker_models.dart';
import 'widgets/sticker_book_widgets.dart';

/// Main game widget for the Sticker Book game
class StickerBookGame extends ConsumerStatefulWidget {
  final ChildProfile child;
  final GameSession session;
  final StickerBookPlugin plugin;

  const StickerBookGame({
    super.key,
    required this.child,
    required this.session,
    required this.plugin,
  });

  @override
  ConsumerState<StickerBookGame> createState() => _StickerBookGameState();
}

class _StickerBookGameState extends ConsumerState<StickerBookGame> {
  late StickerBookGameState gameState;
  PageController? _pageController;
  int _currentBookIndex = 0;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    // Initialize with sample data - in real app this would load from persistence
    gameState = StickerBookGameState(
      books: _generateSampleBooks(),
      unlockedStickers: {},
      currentBookId: 'animals',
      currentPageId: 'animals_farm',
      score: 0,
      level: 1,
      totalStickersCollected: 0,
    );
    
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kidBackgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildGameContent(),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple[400]!,
            Colors.pink[400]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.plugin.gameName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getCurrentBook()?.title ?? 'Loading...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildScoreWidget(),
        ],
      ),
    );
  }

  Widget _buildScoreWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            '${gameState.score}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameContent() {
    final currentBook = _getCurrentBook();
    if (currentBook == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPageIndex = index;
        });
      },
      itemCount: currentBook.pages.length,
      itemBuilder: (context, index) {
        final page = currentBook.pages[index];
        return _buildStickerPage(page);
      },
    );
  }

  Widget _buildStickerPage(StickerPage page) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          _buildPageHeader(page),
          Expanded(
            child: _buildStickerGrid(page),
          ),
          _buildPageProgress(page),
        ],
      ),
    );
  }

  Widget _buildPageHeader(StickerPage page) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: page.theme.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              page.theme.icon,
              color: page.theme.color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  page.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  page.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickerGrid(StickerPage page) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: page.stickerSlots.length,
      itemBuilder: (context, index) {
        final slot = page.stickerSlots[index];
        return _buildStickerSlot(slot);
      },
    );
  }

  Widget _buildStickerSlot(StickerSlot slot) {
    final isUnlocked = gameState.unlockedStickers.contains(slot.stickerId);
    
    return GestureDetector(
      onTap: isUnlocked ? null : () => _attemptStickerUnlock(slot),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isUnlocked ? Colors.green[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked ? Colors.green : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            if (isUnlocked) ...[
              Center(
                child: StickerWidget(
                  sticker: slot.targetSticker,
                  size: 60,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ] else ...[
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.help_outline,
                      color: Colors.grey[400],
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      slot.hint,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ).animate(target: isUnlocked ? 1 : 0)
       .scale(
         begin: const Offset(0.8, 0.8),
         end: const Offset(1.0, 1.0),
         duration: 300.ms,
       )
       .fadeIn(duration: 300.ms),
    );
  }

  Widget _buildPageProgress(StickerPage page) {
    final totalStickers = page.stickerSlots.length;
    final collectedStickers = page.stickerSlots
        .where((slot) => gameState.unlockedStickers.contains(slot.stickerId))
        .length;
    
    final progress = collectedStickers / totalStickers;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$collectedStickers / $totalStickers',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            page.theme.color,
          ),
        ),
        if (progress == 1.0) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.celebration,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 4),
              const Text(
                'Page Complete!',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBottomControls() {
    final currentBook = _getCurrentBook();
    if (currentBook == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _currentPageIndex > 0 ? _previousPage : null,
            icon: const Icon(Icons.arrow_back_ios),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                currentBook.pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == _currentPageIndex
                        ? AppColors.primaryBlue
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _currentPageIndex < currentBook.pages.length - 1
                ? _nextPage
                : null,
            icon: const Icon(Icons.arrow_forward_ios),
          ),
        ],
      ),
    );
  }

  // Game logic methods

  StickerBook? _getCurrentBook() {
    if (_currentBookIndex < gameState.books.length) {
      return gameState.books[_currentBookIndex];
    }
    return null;
  }

  void _previousPage() {
    if (_currentPageIndex > 0) {
      _pageController?.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    final currentBook = _getCurrentBook();
    if (currentBook != null && _currentPageIndex < currentBook.pages.length - 1) {
      _pageController?.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _attemptStickerUnlock(StickerSlot slot) {
    // Show mini-game dialog for unlocking sticker
    showDialog(
      context: context,
      builder: (context) => StickerMiniGame(
        slot: slot,
        onComplete: (success) {
          if (success) {
            _unlockSticker(slot.stickerId);
          }
        },
      ),
    );
  }

  void _unlockSticker(String stickerId) {
    setState(() {
      gameState = gameState.copyWith(
        unlockedStickers: {...gameState.unlockedStickers, stickerId},
        totalStickersCollected: gameState.totalStickersCollected + 1,
        score: gameState.score + 10,
      );
    });

    // Create sticker collected event
    final event = StickerCollectedEvent(
      gameId: widget.plugin.gameId,
      childId: widget.child.id,
      sessionId: widget.session.sessionId,
      stickerId: stickerId,
      stickerType: 'regular',
    );

    // Handle the event through the plugin
    widget.plugin.handleGameEvent(event);

    _checkPageCompletion();
  }

  void _checkPageCompletion() {
    final currentBook = _getCurrentBook();
    if (currentBook == null) return;

    final currentPage = currentBook.pages[_currentPageIndex];
    final allStickersCollected = currentPage.stickerSlots
        .every((slot) => gameState.unlockedStickers.contains(slot.stickerId));

    if (allStickersCollected) {
      _onPageCompleted(currentPage);
    }
  }

  void _onPageCompleted(StickerPage page) {
    // Create page completed event
    final event = PageCompletedEvent(
      gameId: widget.plugin.gameId,
      childId: widget.child.id,
      sessionId: widget.session.sessionId,
      pageId: page.id,
      stickersOnPage: page.stickerSlots.length,
      completionAccuracy: 1.0, // Perfect completion for now
    );

    widget.plugin.handleGameEvent(event);

    // Show completion celebration
    _showPageCompletionCelebration(page);
  }

  void _showPageCompletionCelebration(StickerPage page) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PageCompletionDialog(
        page: page,
        onContinue: () {
          Navigator.of(context).pop();
          if (_currentPageIndex < (_getCurrentBook()?.pages.length ?? 0) - 1) {
            _nextPage();
          }
        },
      ),
    );
  }

  // Sample data generation
  List<StickerBook> _generateSampleBooks() {
    return [
      StickerBook(
        id: 'animals',
        title: 'Animal Friends',
        description: 'Collect cute animal stickers!',
        theme: StickerTheme(
          color: Colors.green,
          icon: Icons.pets,
          name: 'Animals',
        ),
        pages: [
          StickerPage(
            id: 'animals_farm',
            title: 'Farm Animals',
            description: 'Complete the farm scene',
            theme: StickerTheme(
              color: Colors.green,
              icon: Icons.agriculture,
              name: 'Farm',
            ),
            stickerSlots: [
              StickerSlot(
                id: 'farm_cow',
                stickerId: 'cow',
                position: const Offset(0.2, 0.3),
                hint: 'Says "moo"',
                targetSticker: Sticker(
                  id: 'cow',
                  name: 'Cow',
                  emoji: '🐄',
                  category: 'farm',
                ),
              ),
              StickerSlot(
                id: 'farm_pig',
                stickerId: 'pig',
                position: const Offset(0.5, 0.4),
                hint: 'Pink and round',
                targetSticker: Sticker(
                  id: 'pig',
                  name: 'Pig',
                  emoji: '🐷',
                  category: 'farm',
                ),
              ),
              StickerSlot(
                id: 'farm_chicken',
                stickerId: 'chicken',
                position: const Offset(0.8, 0.2),
                hint: 'Lays eggs',
                targetSticker: Sticker(
                  id: 'chicken',
                  name: 'Chicken',
                  emoji: '🐔',
                  category: 'farm',
                ),
              ),
            ],
          ),
        ],
      ),
    ];
  }
}