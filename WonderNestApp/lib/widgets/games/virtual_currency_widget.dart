import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/games/achievement_system.dart';
import '../../core/theme/app_colors.dart';

/// Widget for displaying virtual currency balance
class VirtualCurrencyWidget extends ConsumerWidget {
  final String childId;
  final bool showFullStats;
  final VoidCallback? onTap;

  const VirtualCurrencyWidget({
    super.key,
    required this.childId,
    this.showFullStats = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(childCurrencyBalanceProvider(childId));

    return balance.when(
      data: (amount) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber[400]!,
                Colors.amber[600]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                amount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (showFullStats) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 12,
                ),
              ],
            ],
          ),
        ),
      ),
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

/// Currency animation for gains/losses
class CurrencyAnimation extends StatefulWidget {
  final int amount;
  final String reason;
  final VoidCallback? onComplete;

  const CurrencyAnimation({
    super.key,
    required this.amount,
    required this.reason,
    this.onComplete,
  });

  @override
  State<CurrencyAnimation> createState() => _CurrencyAnimationState();
}

class _CurrencyAnimationState extends State<CurrencyAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: -100.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0),
    ));

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.amount > 0 ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (widget.amount > 0 ? Colors.green : Colors.red)
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.amount > 0 ? Icons.add : Icons.remove,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.amount.abs().toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Full currency stats and transaction history
class CurrencyStatsWidget extends ConsumerWidget {
  final String childId;

  const CurrencyStatsWidget({
    super.key,
    required this.childId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(currencyStatsProvider(childId));

    return stats.when(
      data: (currencyStats) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCard(currencyStats),
          const SizedBox(height: 16),
          _buildTransactionHistory(currencyStats),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading currency stats: $error'),
      ),
    );
  }

  Widget _buildStatsCard(CurrencyStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Virtual Currency Stats',
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
                    'Current Balance',
                    stats.currentBalance.toString(),
                    Icons.account_balance_wallet,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Earned',
                    stats.totalEarned.toString(),
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Spent',
                    stats.totalSpent.toString(),
                    Icons.trending_down,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Transactions',
                    stats.transactionCount.toString(),
                    Icons.history,
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTransactionHistory(CurrencyStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (stats.transactionCount == 0)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No transactions yet.\nStart playing games to earn currency!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              const Text(
                'Transaction history will be displayed here.',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget for spending currency
class CurrencySpendingWidget extends StatefulWidget {
  final String childId;
  final int cost;
  final String itemName;
  final VoidCallback? onPurchase;

  const CurrencySpendingWidget({
    super.key,
    required this.childId,
    required this.cost,
    required this.itemName,
    this.onPurchase,
  });

  @override
  State<CurrencySpendingWidget> createState() => _CurrencySpendingWidgetState();
}

class _CurrencySpendingWidgetState extends State<CurrencySpendingWidget> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final balance = ref.watch(childCurrencyBalanceProvider(widget.childId));

        return balance.when(
          data: (amount) {
            final canAfford = amount >= widget.cost;
            
            return ElevatedButton.icon(
              onPressed: canAfford && !_isProcessing ? _handlePurchase : null,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.star),
              label: Text('${widget.cost} Stars'),
              style: ElevatedButton.styleFrom(
                backgroundColor: canAfford ? Colors.amber : Colors.grey,
                foregroundColor: Colors.white,
              ),
            );
          },
          loading: () => const ElevatedButton(
            onPressed: null,
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => const ElevatedButton(
            onPressed: null,
            child: Text('Error'),
          ),
        );
      },
    );
  }

  Future<void> _handlePurchase() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // This would integrate with the currency manager
      // For now, just simulate the purchase
      await Future.delayed(const Duration(seconds: 1));
      
      widget.onPurchase?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchased ${widget.itemName}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}