// lib/features/onboarding/presentation/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../application/onboarding_providers.dart';
import 'widgets/brand_wordmark.dart';
import 'widgets/onboarding_page.dart';
import 'package:runtrack_app/shared/charts/route_sparkline.dart';
import 'package:runtrack_app/shared/charts/weekly_bar_chart.dart';
import 'package:runtrack_app/shared/widgets/app_buttons.dart';
import 'package:runtrack_app/shared/widgets/page_dots.dart';
import 'package:runtrack_app/shared/widgets/stat_grid.dart';

// Sample route points for the Tour·Map slide — a plausible running route shape.
const _sampleRoute = [
  SparkPoint(lat: 51.500, lng: -0.124),
  SparkPoint(lat: 51.502, lng: -0.124),
  SparkPoint(lat: 51.502, lng: -0.120),
  SparkPoint(lat: 51.505, lng: -0.120),
  SparkPoint(lat: 51.505, lng: -0.115),
  SparkPoint(lat: 51.507, lng: -0.115),
  SparkPoint(lat: 51.507, lng: -0.111),
  SparkPoint(lat: 51.504, lng: -0.111),
  SparkPoint(lat: 51.503, lng: -0.108),
];

// Sample weekly distances (km) for the Tour·Progress slide.
const _weekValues = [3.2, 5.1, 4.0, 6.3, 4.8, 7.0, 5.5];

/// First-launch onboarding carousel. Layout: page dots and persistent CTAs stay
/// fixed; only the middle slide content swaps as the user swipes.
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main column ───────────────────────────────────────────────
            Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    children: const [
                      _WelcomePage(),
                      OnboardingPage(
                        heading: 'Every run,\nmapped & saved',
                        illustration: _RouteSlide(),
                        caption:
                            'GPS traces your route in real time\n— all your runs in one place.',
                      ),
                      OnboardingPage(
                        heading: 'Live stats that\nkeep you going',
                        illustration: _StatsSlide(),
                        caption:
                            'Time, distance and pace update\nevery second while you run.',
                      ),
                      OnboardingPage(
                        heading: 'Review & improve\nevery run',
                        illustration: _ProgressSlide(),
                        caption:
                            'Spot trends, beat your best,\nstay on track for your goals.',
                      ),
                    ],
                  ),
                ),

                // ── Bottom dock ──────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
                  child: Column(
                    children: [
                      PageDots(count: _pageCount, index: _page),
                      SizedBox(height: 24.h),
                      PrimaryButton(
                        label: 'Create Account',
                        onPressed: () => _leave('/signup'),
                      ),
                      SizedBox(height: 12.h),
                      SecondaryButton(
                        label: 'Log In',
                        onPressed: () => _leave('/login'),
                      ),
                      SizedBox(height: 16.h),
                      Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: cs.onSurface.withValues(alpha: 0.35),
                          ),
                          children: [
                            const TextSpan(
                              text: 'By continuing, you agree to our ',
                            ),
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(color: cs.primary),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(color: cs.primary),
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

            // ── Skip button ───────────────────────────────────────────────
            // Last child so it paints — and hit-tests — above the PageView,
            // which would otherwise swallow taps in the top-right corner.
            Positioned(
              top: 8.h,
              right: 16.w,
              child: TextButton(
                onPressed: () => _leave('/login'),
                child: Text(
                  'Skip',
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page 1: brand hero ────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72.w,
                  height: 72.w,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 40.sp,
                  ),
                ),
                SizedBox(height: 20.h),
                const BrandWordmark(),
                SizedBox(height: 16.h),
                Text(
                  'Track every run.\nImprove every day.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Page 2: Tour·Map — RouteSparkline ─────────────────────────────────────────

class _RouteSlide extends StatelessWidget {
  const _RouteSlide();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240.w,
      height: 240.w,
      child: const RouteSparkline(
        points: _sampleRoute,
        showGrid: true,
        startMarker: true,
        endMarker: true,
      ),
    );
  }
}

// ── Page 3: Tour·Stats — StatRow card ─────────────────────────────────────────

class _StatsSlide extends StatelessWidget {
  const _StatsSlide();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 260.w,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('00:24:37', style: Theme.of(context).textTheme.displayMedium),
          Text(
            'ELAPSED TIME',
            style: TextStyle(
              fontSize: 10.sp,
              letterSpacing: 1,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
          SizedBox(height: 12.h),
          StatRow(
            items: const [
              StatItem(value: '4.21', unit: 'km', label: 'Dist'),
              StatItem(value: '5:48', unit: '/km', label: 'Pace', accent: true),
              StatItem(value: '5:42', unit: '/km', label: 'Avg'),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Page 4: Tour·Progress — WeeklyBarChart ────────────────────────────────────

class _ProgressSlide extends StatelessWidget {
  const _ProgressSlide();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 260.w,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'THIS WEEK',
            style: TextStyle(
              fontSize: 11.sp,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 12.h),
          WeeklyBarChart(values: _weekValues, height: 100),
        ],
      ),
    );
  }
}
