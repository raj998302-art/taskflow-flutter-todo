import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/glass_container.dart';
import '../providers/app_settings_provider.dart';

/// A premium 3-slide onboarding screen shown the first time the app launches.
///
/// Walks the user through Taskflow's headline features — beautiful task
/// organisation, voice reminders that speak to you, and biometric app lock.
/// Each slide pairs a large glassmorphic icon medallion (gradient-tinted with
/// the slide's accent color) with a title and supporting subtitle.
///
/// The user can swipe between slides, tap "Next" to advance, "Skip" (top-right)
/// to jump straight to home, or "Get Started" on the final slide. Both "Skip"
/// and "Get Started" call
/// `ref.read(appSettingsProvider.notifier).markOnboardingSeen()` and then
/// navigate to `context.go('/home')`.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingSlide> _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      icon: Icons.task_alt_rounded,
      color: AppColors.primary,
      title: 'Welcome to Taskflow',
      subtitle:
          'Organise your day with beautiful tasks, categories, priorities, and a stunning dashboard.',
    ),
    _OnboardingSlide(
      icon: Icons.record_voice_over_rounded,
      color: AppColors.accent,
      title: 'Voice Reminders',
      subtitle:
          'Set alarms that speak to you — "Boss, apko sabji lena hai" at exactly 8:05 PM. Never forget again.',
    ),
    _OnboardingSlide(
      icon: Icons.fingerprint_rounded,
      color: AppColors.success,
      title: 'Secure & Yours',
      subtitle:
          'Lock the app with your fingerprint or face. Your data stays private and fully offline.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Marks onboarding as seen and navigates to home.
  Future<void> _finish() async {
    await ref.read(appSettingsProvider.notifier).markOnboardingSeen();
    if (mounted) context.go('/home');
  }

  void _goNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = context.colors;
    final bool isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              scheme.surface,
              AppColors.primary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: <Widget>[
                  // Top bar: floating logo (left) + Skip (right).
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                    child: Row(
                      children: <Widget>[
                        Image.asset(
                          'assets/images/app_logo.png',
                          width: 80,
                          height: 80,
                        )
                            .animate(
                              onPlay: (AnimationController c) =>
                                  c.repeat(reverse: true),
                            )
                            .moveY(begin: -4, end: 4, duration: 2000.ms),
                        const Spacer(),
                        TextButton(
                          onPressed: _finish,
                          child: const Text('Skip'),
                        ),
                      ],
                    ),
                  ),
                  // Slide deck.
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _slides.length,
                      onPageChanged: (int page) =>
                          setState(() => _currentPage = page),
                      itemBuilder: (BuildContext context, int index) {
                        return _OnboardingSlideView(
                          slide: _slides[index],
                          currentPage: _currentPage,
                        );
                      },
                    ),
                  ),
                  // Page indicator dots + primary action button.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                              List<Widget>.generate(_slides.length, (int i) {
                            final bool active = i == _currentPage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              width: active ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.primary
                                    : scheme.outlineVariant,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _goNext,
                            icon: Icon(
                              isLast
                                  ? Icons.rocket_launch_rounded
                                  : Icons.arrow_forward_rounded,
                            ),
                            label: Text(isLast ? 'Get Started' : 'Next'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Immutable description of a single onboarding slide.
class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  /// Glyph rendered inside the gradient medallion.
  final IconData icon;

  /// Accent color used for the medallion gradient, glow, and halo.
  final Color color;

  /// Slide headline (24sp, w800).
  final String title;

  /// Supporting copy (15sp, onSurfaceVariant, centered).
  final String subtitle;
}

/// Renders a single onboarding slide: gradient glassmorphic medallion with
/// the slide icon, a bold title, and a supporting subtitle.
///
/// All three elements fade + slide in via [flutter_animate] whenever
/// [currentPage] changes (i.e. when this slide becomes active), keyed on
/// `currentPage` so the entrance replays on each visit.
class _OnboardingSlideView extends StatelessWidget {
  const _OnboardingSlideView({
    required this.slide,
    required this.currentPage,
  });

  final _OnboardingSlide slide;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = context.textTheme;
    final ColorScheme scheme = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Glassmorphic circular medallion with a gradient background
          // matching the slide's accent color, and a soft colored glow.
          GlassContainer(
            padding: const EdgeInsets.all(8),
            borderRadius: const BorderRadius.all(Radius.circular(96)),
            shadows: <BoxShadow>[
              BoxShadow(
                color: slide.color.withValues(alpha: 0.35),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
            child: Container(
              width: 168,
              height: 168,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: <Color>[
                    slide.color,
                    slide.color.withValues(alpha: 0.55),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(slide.icon, size: 96, color: Colors.white),
              ),
            ),
          )
              .animate(key: ValueKey<String>('icon-$currentPage'))
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.15, end: 0),
          const SizedBox(height: 32),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: text.headlineSmall?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          )
              .animate(key: ValueKey<String>('title-$currentPage'))
              .fadeIn(duration: 400.ms, delay: 80.ms)
              .slideY(begin: 0.15, end: 0),
          const SizedBox(height: 12),
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: text.bodyMedium?.copyWith(
              fontSize: 15,
              color: scheme.onSurfaceVariant,
            ),
          )
              .animate(key: ValueKey<String>('sub-$currentPage'))
              .fadeIn(duration: 400.ms, delay: 160.ms)
              .slideY(begin: 0.15, end: 0),
        ],
      ),
    );
  }
}
