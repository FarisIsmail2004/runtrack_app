import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Runs once before the entire test suite (flutter_test picks this file up
/// automatically). Production code wraps the app in [ScreenUtilInit]; widget
/// tests pump screens directly without it, so the `.sp`/`.w`/`.r` extensions
/// would otherwise throw "You must use ScreenUtil.init first".
///
/// We configure a fixed device size that matches the design baseline, giving
/// an identity scale factor (1.0). Sizes therefore resolve to their literal
/// values, keeping existing layout/golden expectations stable.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  const designSize = Size(390, 844);
  ScreenUtil.configure(
    data: const MediaQueryData(size: designSize),
    designSize: designSize,
    minTextAdapt: true,
    splitScreenMode: false,
  );
  await testMain();
}
