import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/quick_action_button.dart';

class ParentDashboard extends ConsumerWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good morning,',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          user?['firstName'] ?? 'Parent',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryBlue,
                    child: Text(
                      (user?['firstName']?[0] ?? 'P').toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn().slideX(begin: 0.3),
              
              const SizedBox(height: 32),
              
              Text(
                'Family Overview',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ).animate().fadeIn(delay: 200.ms),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: DashboardCard(
                      title: 'Active Children',
                      value: '2',
                      subtitle: 'Emma & Liam',
                      icon: Icons.child_care,
                      color: AppColors.kidSafeBlue,
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DashboardCard(
                      title: 'Today\'s Learning',
                      value: '45m',
                      subtitle: 'Total time',
                      icon: Icons.timer,
                      color: AppColors.accentGreen,
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: DashboardCard(
                      title: 'New Words',
                      value: '12',
                      subtitle: 'This week',
                      icon: Icons.abc,
                      color: AppColors.warningOrange,
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DashboardCard(
                      title: 'Achievements',
                      value: '3',
                      subtitle: 'Unlocked today',
                      icon: Icons.emoji_events,
                      color: AppColors.successGreen,
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Quick Actions',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ).animate().fadeIn(delay: 700.ms),
              
              const SizedBox(height: 16),
              
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  QuickActionButton(
                    title: 'Add Child',
                    subtitle: 'Create new profile',
                    icon: Icons.person_add,
                    color: AppColors.primaryBlue,
                    onTap: () {
                      // Navigate to add child screen
                    },
                  ).animate().fadeIn(delay: 800.ms).scale(),
                  
                  QuickActionButton(
                    title: 'View Analytics',
                    subtitle: 'Learning insights',
                    icon: Icons.analytics,
                    color: AppColors.accentPurple,
                    onTap: () {
                      // Navigate to analytics screen
                    },
                  ).animate().fadeIn(delay: 900.ms).scale(),
                  
                  QuickActionButton(
                    title: 'Content Library',
                    subtitle: 'Browse activities',
                    icon: Icons.library_books,
                    color: AppColors.accentGreen,
                    onTap: () {
                      // Navigate to content library
                    },
                  ).animate().fadeIn(delay: 1000.ms).scale(),
                  
                  QuickActionButton(
                    title: 'Settings',
                    subtitle: 'Manage account',
                    icon: Icons.settings,
                    color: AppColors.textSecondary,
                    onTap: () {
                      // Navigate to settings
                    },
                  ).animate().fadeIn(delay: 1100.ms).scale(),
                ],
              ),
              
              const SizedBox(height: 32),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.kidGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.kidSafeBlue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.child_friendly,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Switch to Kid Mode',
                            style: GoogleFonts.comicNeue(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Let your children explore safely',
                            style: GoogleFonts.comicNeue(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to child mode
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.kidSafeBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Switch',
                        style: GoogleFonts.comicNeue(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.3),
            ],
          ),
        ),
      ),
    );
  }
}