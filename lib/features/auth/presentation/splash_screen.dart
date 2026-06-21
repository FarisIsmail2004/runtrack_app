import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../onboarding/presentation/widgets/brand_wordmark.dart';

/// Becomes true once the splash's minimum display window has elapsed. The
/// router's redirect waits on this so the brand mark is shown for a beat before
/// gating decisions move the user on to /login or /home.
final splashReadyProvider = StateProvider<bool>((_) => false);

/// Branded launch screen. It does NOT navigate itself — once its brief delay
/// elapses it flips [splashReadyProvider], and the router redirect (which knows
/// about Supabase config + session) decides the destination.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        ref.read(splashReadyProvider.notifier).state = true;
      }
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF6A00);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_run, color: orange, size: 72.sp),
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
  }
}
