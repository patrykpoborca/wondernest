import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.family_restroom,
      title: 'Welcome to Your Family\'s Learning Hub',
      subtitle: 'Create magical educational experiences tailored for your children',
      description: 'WonderNest adapts to each child\'s learning style and interests, creating personalized educational journeys.',
    ),
    OnboardingPage(
      icon: Icons.child_care,
      title: 'Safe & Secure Environment',
      subtitle: 'COPPA compliant platform designed for children',
      description: 'Your family\'s privacy and your children\'s safety are our top priorities. All content is age-appropriate and educational.',
    ),
    OnboardingPage(
      icon: Icons.analytics,
      title: 'Track Learning Progress',
      subtitle: 'Monitor development and celebrate milestones',
      description: 'Get insights into your child\'s learning journey with detailed analytics and progress tracking.',
    ),
    OnboardingPage(
      icon: Icons.auto_awesome,
      title: 'AI-Powered Learning',
      subtitle: 'Intelligent content recommendations',
      description: 'Our AI creates personalized learning paths that adapt to your child\'s pace and interests.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    // Save onboarding completion flag
    const secureStorage = FlutterSecureStorage();
    await secureStorage.write(key: 'onboarding_completed', value: 'true');
    
    // Navigate to parent dashboard
    if (mounted) {
      context.go('/parent-dashboard');
    }
  }
  
  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.welcomeGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'WonderNest',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: _skipOnboarding,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            page.icon,
                            size: 120,
                            color: Colors.white,
                          ).animate().fadeIn(duration: 800.ms).scale(),
                          
                          const SizedBox(height: 48),
                          
                          Text(
                            page.title,
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(delay: 300.ms, duration: 800.ms),
                          
                          const SizedBox(height: 16),
                          
                          Text(
                            page.subtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(delay: 500.ms, duration: 800.ms),
                          
                          const SizedBox(height: 24),
                          
                          Text(
                            page.description,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(delay: 700.ms, duration: 800.ms),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index 
                                ? Colors.white 
                                : Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ).animate().scale(duration: 200.ms),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryBlue,
                          elevation: 8,
                          shadowColor: Colors.black26,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
  });
}