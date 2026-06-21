// lib/features/onboarding/presentation/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../application/onboarding_providers.dart';
import 'widgets/bar_chart_illustration.dart';
import 'widgets/brand_wordmark.dart';
import 'widgets/onboarding_page.dart';
import 'widgets/page_dots.dart';
import 'widgets/route_illustration.dart';
import 'widgets/stats_card_illustration.dart';

/// First-launch onboarding carousel. Option A layout: the page dots and the
/// Create Account / Log In CTA block stay fixed; only the middle page content
/// swaps as the user swipes through the 4 pages.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pageCount = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _leave(String route) async {
    await ref.read(onboardingControllerProvider).markSeen();
    if (mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: const [
                  _WelcomePage(),
                  OnboardingPage(
                    heading: 'ALL YOUR RUNS.\nALL IN ONE PLACE.',
                    illustration: RouteIllustration(),
                    caption: 'Track your runs with accurate stats and maps.',
                  ),
                  OnboardingPage(
                    heading: 'LIVE STATS THAT\nKEEP YOU GOING.',
                    illustration: StatsCardIllustration(),
                    caption: 'See real-time stats while you run.',
                  ),
                  OnboardingPage(
                    heading: 'REVIEW. IMPROVE.\nKEEP MOVING.',
                    illustration: BarChartIllustration(),
                    caption:
                        'Analyze your performance and track your progress.',
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
              child: Column(
                children: [
                  PageDots(count: _pageCount, activeIndex: _page),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => _leave('/signup'),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: OutlinedButton(
                      onPressed: () => _leave('/login'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFF6A00)),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(fontSize: 11.sp, color: Colors.white38),
                      children: const [
                        TextSpan(text: 'By continuing, you agree to our '),
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(color: Color(0xFFFF6A00)),
                        ),
                        TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(color: Color(0xFFFF6A00)),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page 1: brand hero — running icon, wordmark, tagline.
class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_run,
                  color: const Color(0xFFFF6A00),
                  size: 72.sp,
                ),
                SizedBox(height: 16.h),
                const BrandWordmark(),
                SizedBox(height: 16.h),
                Text(
                  'Track every run.\nImprove every day.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.sp, color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
