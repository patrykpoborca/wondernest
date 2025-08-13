import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/family_member.dart';
import '../../providers/family_provider.dart';
import '../../widgets/family_member_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_card.dart';

class FamilyOverviewScreen extends ConsumerStatefulWidget {
  const FamilyOverviewScreen({super.key});

  @override
  ConsumerState<FamilyOverviewScreen> createState() =>
      _FamilyOverviewScreenState();
}

class _FamilyOverviewScreenState extends ConsumerState<FamilyOverviewScreen> {
  @override
  Widget build(BuildContext context) {
    final familyAsync = ref.watch(familyProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Family Members'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.gear()),
            onPressed: () {
              // Navigate to family settings
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(familyProvider.notifier).refresh();
        },
        child: familyAsync.when(
          data: (family) => _buildFamilyContent(context, family),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(context, error),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/child-profile/create');
        },
        icon: Icon(PhosphorIcons.plus()),
        label: const Text('Add Child'),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildFamilyContent(BuildContext context, Family family) {
    final theme = Theme.of(context);
    final children = family.children;

    if (children.isEmpty) {
      return EmptyStateWidget(
        title: 'No Children Added',
        subtitle: 'Add your first child to get started with WonderNest',
        icon: PhosphorIcons.baby(),
        onActionPressed: () {
          context.push('/child-profile/create');
        },
        actionLabel: 'Add First Child',
      );
    }

    return CustomScrollView(
      slivers: [
        // Family Summary Card
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.primaryContainer.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.house(),
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      family.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      icon: PhosphorIcons.baby(),
                      label: 'Children',
                      value: '${family.childCount}',
                      theme: theme,
                    ),
                    _buildStatCard(
                      icon: PhosphorIcons.crown(),
                      label: 'Plan',
                      value: family.subscriptionPlan ?? 'Free',
                      theme: theme,
                    ),
                    _buildStatCard(
                      icon: PhosphorIcons.calendar(),
                      label: 'Member Since',
                      value:
                          '${DateTime.now().difference(family.createdAt).inDays} days',
                      theme: theme,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Section Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Children',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Sort or filter options
                  },
                  icon: Icon(PhosphorIcons.funnel()),
                  label: const Text('Filter'),
                ),
              ],
            ),
          ),
        ),

        // Children List
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final child = children[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FamilyMemberCard(
                          member: child,
                          onTap: () {
                            ref.read(familyProvider.notifier).selectChild(child);
                            context.push('/child-profile/${child.id}');
                          },
                          onEdit: () {
                            context.push('/child-profile/${child.id}/edit');
                          },
                          onDelete: () async {
                            final confirmed = await _showDeleteConfirmation(
                              context,
                              child,
                            );
                            if (confirmed) {
                              await ref
                                  .read(familyProvider.notifier)
                                  .removeChild(child.id);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${child.name} removed'),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () {
                                        // Implement undo functionality
                                      },
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: children.length,
            ),
          ),
        ),

        // Parents Section
        if (family.parents.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Parents',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final parent = family.parents[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FamilyMemberCard(
                      member: parent,
                      showActions: false,
                      onTap: () {
                        // Navigate to parent profile
                      },
                    ),
                  );
                },
                childCount: family.parents.length,
              ),
            ),
          ),
        ],

        // Bottom padding for FAB
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return const LoadingCard(
          height: 120,
          showActions: true,
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.warning(),
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load family data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.read(familyProvider.notifier).refresh();
              },
              icon: Icon(PhosphorIcons.arrowClockwise()),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    FamilyMember child,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Remove Child Profile'),
              content: Text(
                'Are you sure you want to remove ${child.name}\'s profile? This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Remove'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}