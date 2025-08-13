import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/kid_activity_card.dart';

class ChildHome extends StatelessWidget {
  const ChildHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: GoogleFonts.comicNeue().fontFamily,
        useMaterial3: true,
      ),
      child: Scaffold(
        backgroundColor: AppColors.kidBackgroundLight,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          '🐻',
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi Emma!',
                              style: GoogleFonts.comicNeue(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Ready to learn and play?',
                              style: GoogleFonts.comicNeue(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: AppColors.warningOrange,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '125',
                              style: GoogleFonts.comicNeue(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.kidSafeBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.3),
                
                const SizedBox(height: 24),
                
                Text(
                  '🎮 Fun Activities',
                  style: GoogleFonts.comicNeue(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.3),
                
                const SizedBox(height: 16),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                  children: [
                    KidActivityCard(
                      title: 'ABC Learning',
                      subtitle: 'Learn your letters!',
                      emoji: '🔤',
                      color: AppColors.kidSafeBlue,
                      progress: 0.6,
                      onTap: () {
                        // Navigate to ABC learning
                      },
                    ).animate().fadeIn(delay: 300.ms).scale(),
                    
                    KidActivityCard(
                      title: 'Number Fun',
                      subtitle: 'Count with me!',
                      emoji: '🔢',
                      color: AppColors.accentGreen,
                      progress: 0.4,
                      onTap: () {
                        // Navigate to numbers
                      },
                    ).animate().fadeIn(delay: 400.ms).scale(),
                    
                    KidActivityCard(
                      title: 'Story Time',
                      subtitle: 'Amazing tales!',
                      emoji: '📚',
                      color: AppColors.accentPurple,
                      progress: 0.8,
                      onTap: () {
                        // Navigate to stories
                      },
                    ).animate().fadeIn(delay: 500.ms).scale(),
                    
                    KidActivityCard(
                      title: 'Animal Friends',
                      subtitle: 'Meet cute animals!',
                      emoji: '🐼',
                      color: AppColors.warningOrange,
                      progress: 0.3,
                      onTap: () {
                        // Navigate to animals
                      },
                    ).animate().fadeIn(delay: 600.ms).scale(),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  '🏆 Your Achievements',
                  style: GoogleFonts.comicNeue(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.3),
                
                const SizedBox(height: 16),
                
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: AppColors.successGreen,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Great Job Today!',
                              style: GoogleFonts.comicNeue(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'You completed 3 activities and learned 5 new words!',
                              style: GoogleFonts.comicNeue(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '🌟',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),
                
                const SizedBox(height: 24),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accentPurple, AppColors.kidSafeBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '👨‍👩‍👧‍👦',
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ask a grown-up to help!',
                        style: GoogleFonts.comicNeue(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Get help or switch back to parent mode',
                        style: GoogleFonts.comicNeue(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}