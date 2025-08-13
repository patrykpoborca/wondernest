import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/family_provider.dart';
import '../../providers/app_mode_provider.dart';
import '../../models/family_member.dart' as fm;
import '../../models/child_profile.dart';

class ChildSelectionScreen extends ConsumerWidget {
  const ChildSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsyncValue = ref.watch(familyProvider);

    return Scaffold(
      backgroundColor: AppColors.kidBackgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Choose Your Profile',
          style: GoogleFonts.comicNeue(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: familyAsyncValue.when(
          data: (family) => _buildChildSelection(context, ref, family),
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.kidSafeBlue),
            ),
          ),
          error: (error, stackTrace) => _buildErrorState(context, ref),
        ),
      ),
    );
  }

  Widget _buildChildSelection(BuildContext context, WidgetRef ref, fm.Family family) {
    final children = family.children;

    if (children.isEmpty) {
      return _buildNoChildrenState(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.kidGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.kidSafeBlue.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '🎮',
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 12),
                Text(
                  'Who wants to play today?',
                  style: GoogleFonts.comicNeue(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Pick your profile to start your adventure!',
                  style: GoogleFonts.comicNeue(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.3),
          
          const SizedBox(height: 32),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: children.length == 1 ? 1 : 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.85,
            ),
            itemCount: children.length,
            itemBuilder: (context, index) {
              final child = children[index];
              return _buildChildCard(context, ref, child, index);
            },
          ),
          
          const SizedBox(height: 32),
          
          Container(
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: AppColors.accentPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ask a grown-up if you need help choosing your profile!',
                    style: GoogleFonts.comicNeue(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, WidgetRef ref, fm.FamilyMember child, int index) {
    // Generate a colorful avatar color based on child's name
    final colors = [
      AppColors.kidSafeBlue,
      AppColors.accentGreen,
      AppColors.accentPurple,
      AppColors.warningOrange,
    ];
    final cardColor = colors[index % colors.length];
    
    // Generate fun emojis for avatars
    final avatars = ['🐻', '🦄', '🐼', '🦋', '🌟', '🐸', '🦊', '🐨'];
    final avatar = child.avatarUrl ?? avatars[index % avatars.length];

    return GestureDetector(
      onTap: () => _selectChild(context, ref, child),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cardColor.withValues(alpha: 0.8),
                    cardColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cardColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  avatar,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              child.name,
              style: GoogleFonts.comicNeue(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (child.age != null) ...[
              const SizedBox(height: 4),
              Text(
                child.displayAge,
                style: GoogleFonts.comicNeue(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Play!',
                style: GoogleFonts.comicNeue(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: (300 + index * 100).ms).scale(),
    );
  }

  Widget _buildNoChildrenState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '👨‍👩‍👧‍👦',
              style: const TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 24),
            Text(
              'No Child Profiles Yet',
              style: GoogleFonts.comicNeue(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Ask a grown-up to create your profile first!',
              style: GoogleFonts.comicNeue(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kidSafeBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Go Back',
                style: GoogleFonts.comicNeue(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '😕',
              style: const TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.comicNeue(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Let\'s try again!',
              style: GoogleFonts.comicNeue(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ref.refresh(familyProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kidSafeBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.comicNeue(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectChild(BuildContext context, WidgetRef ref, fm.FamilyMember child) {
    // Convert FamilyMember to ChildProfile for compatibility
    final childProfile = ChildProfile(
      id: child.id,
      name: child.name,
      age: child.age ?? 5,
      avatarUrl: child.avatarUrl,
      birthDate: DateTime.now().subtract(Duration(days: (child.age ?? 5) * 365)),
      gender: 'not_specified',
      interests: child.interests,
      contentSettings: ContentSettings(
        maxAgeRating: _getAgeRating(child.age ?? 5),
        blockedCategories: [],
        allowedDomains: [],
        subtitlesEnabled: true,
        audioMonitoringEnabled: true,
        educationalContentOnly: false,
      ),
      timeRestrictions: TimeRestrictions(
        weekdayLimits: {},
        weekendLimits: {},
        dailyScreenTimeMinutes: 60,
        bedtimeEnabled: false,
      ),
      createdAt: child.createdAt,
      updatedAt: DateTime.now(),
    );

    // Set the active child in app mode provider
    ref.read(appModeProvider.notifier).setActiveChild(childProfile);
    
    // Switch to kid mode and navigate to child home
    ref.read(appModeProvider.notifier).switchToKidMode();
    context.go('/child-home');
  }

  int _getAgeRating(int age) {
    if (age <= 2) return 0;
    if (age <= 4) return 3;
    if (age <= 6) return 6;
    if (age <= 8) return 8;
    return 12;
  }
}