import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/sticker_models.dart';

/// Widget for displaying a sticker
class StickerWidget extends StatelessWidget {
  final Sticker sticker;
  final double size;
  final bool isGlowing;
  final VoidCallback? onTap;

  const StickerWidget({
    super.key,
    required this.sticker,
    this.size = 48,
    this.isGlowing = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: sticker.backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(size * 0.2),
          boxShadow: isGlowing
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.6),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: sticker.imagePath != null || sticker.imageUrl != null
              ? _buildImage()
              : _buildEmoji(),
        ),
      ).animate(target: isGlowing ? 1 : 0)
       .scale(
         begin: const Offset(1.0, 1.0),
         end: const Offset(1.1, 1.1),
         duration: 800.ms,
       )
       .then()
       .scale(
         begin: const Offset(1.1, 1.1),
         end: const Offset(1.0, 1.0),
         duration: 800.ms,
       ),
    );
  }

  Widget _buildImage() {
    if (sticker.imagePath != null) {
      return Image.asset(
        sticker.imagePath!,
        width: size * 0.8,
        height: size * 0.8,
        fit: BoxFit.contain,
      );
    } else if (sticker.imageUrl != null) {
      return Image.network(
        sticker.imageUrl!,
        width: size * 0.8,
        height: size * 0.8,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildEmoji(),
      );
    }
    return _buildEmoji();
  }

  Widget _buildEmoji() {
    return Text(
      sticker.emoji,
      style: TextStyle(
        fontSize: size * 0.6,
      ),
    );
  }
}

/// Mini-game dialog for unlocking stickers
class StickerMiniGame extends StatefulWidget {
  final StickerSlot slot;
  final Function(bool success) onComplete;

  const StickerMiniGame({
    super.key,
    required this.slot,
    required this.onComplete,
  });

  @override
  State<StickerMiniGame> createState() => _StickerMiniGameState();
}

class _StickerMiniGameState extends State<StickerMiniGame> {
  String _selectedAnswer = '';
  bool _showResult = false;
  bool _isCorrect = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_showResult) ...[
              _buildQuestion(),
              const SizedBox(height: 20),
              _buildAnswerOptions(),
            ] else ...[
              _buildResult(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    return Column(
      children: [
        Text(
          'Unlock ${widget.slot.targetSticker.name}!',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.slot.hint,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Which emoji matches the hint?',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerOptions() {
    final correctAnswer = widget.slot.targetSticker.emoji;
    final options = [
      correctAnswer,
      _getRandomEmoji(),
      _getRandomEmoji(),
    ]..shuffle();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: options.map((emoji) => _buildOptionButton(emoji)).toList(),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _selectedAnswer.isNotEmpty ? _checkAnswer : null,
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionButton(String emoji) {
    final isSelected = _selectedAnswer == emoji;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAnswer = emoji;
        });
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Column(
      children: [
        Icon(
          _isCorrect ? Icons.celebration : Icons.sentiment_dissatisfied,
          size: 64,
          color: _isCorrect ? Colors.green : Colors.red,
        ),
        const SizedBox(height: 16),
        Text(
          _isCorrect ? 'Correct!' : 'Try again!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _isCorrect ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isCorrect 
              ? 'You unlocked the ${widget.slot.targetSticker.name} sticker!'
              : 'The correct answer was ${widget.slot.targetSticker.emoji}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onComplete(_isCorrect);
          },
          child: Text(_isCorrect ? 'Awesome!' : 'OK'),
        ),
      ],
    ).animate()
     .slideY(begin: 0.5, duration: 300.ms)
     .fadeIn(duration: 300.ms);
  }

  void _checkAnswer() {
    final isCorrect = _selectedAnswer == widget.slot.targetSticker.emoji;
    
    setState(() {
      _isCorrect = isCorrect;
      _showResult = true;
    });
  }

  String _getRandomEmoji() {
    final emojis = ['🐱', '🐶', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯'];
    emojis.remove(widget.slot.targetSticker.emoji);
    emojis.shuffle();
    return emojis.first;
  }
}

/// Page completion celebration dialog
class PageCompletionDialog extends StatelessWidget {
  final StickerPage page;
  final VoidCallback onContinue;

  const PageCompletionDialog({
    super.key,
    required this.page,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber[400]!,
                    Colors.amber[600]!,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '🎉 Page Complete! 🎉',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You completed "${page.title}"!',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+${page.stickerSlots.length * 5} points earned!',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onContinue,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: page.theme.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    ).animate()
     .scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.elasticOut)
     .fadeIn(duration: 300.ms);
  }
}

/// Widget for displaying sticker book progress
class StickerBookProgress extends StatelessWidget {
  final StickerBook book;
  final bool showDetails;

  const StickerBookProgress({
    super.key,
    required this.book,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: book.theme.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    book.theme.icon,
                    color: book.theme.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        book.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (book.isCompleted)
                  Container(
                    padding: const EdgeInsets.all(6),
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
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: book.completionPercentage,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(book.theme.color),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${book.unlockedStickers}/${book.totalStickers}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${(book.completionPercentage * 100).round()}% Complete',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            if (showDetails) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 4,
                children: book.educationalTopics
                    .map((topic) => Chip(
                          label: Text(topic),
                          backgroundColor: book.theme.color.withValues(alpha: 0.1),
                          labelStyle: TextStyle(
                            fontSize: 10,
                            color: book.theme.color,
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget for displaying sticker collection stats
class StickerCollectionStats extends StatelessWidget {
  final StickerBookGameState gameState;

  const StickerCollectionStats({
    super.key,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Collection Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Stickers',
                    gameState.totalStickersCollected.toString(),
                    Icons.auto_awesome,
                    Colors.amber,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Score',
                    gameState.score.toString(),
                    Icons.star,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Level',
                    gameState.level.toString(),
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Books',
                    gameState.books.where((book) => book.isCompleted).length.toString(),
                    Icons.menu_book,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}