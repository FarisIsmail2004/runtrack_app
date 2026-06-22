// test/shared/widgets/section_header_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';
import 'package:runtrack_app/shared/widgets/page_dots.dart';
import 'package:runtrack_app/shared/widgets/section_header.dart';

void main() {
  testWidgets('SectionHeader renders title + trailing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: SectionHeader(title: 'THIS WEEK', trailing: 'Apr 28 – May 4'),
        ),
      ),
    );
    expect(find.text('THIS WEEK'), findsOneWidget);
    expect(find.text('Apr 28 – May 4'), findsOneWidget);
  });

  testWidgets('PageDots renders one dot per page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: PageDots(count: 4, index: 0)),
      ),
    );
    expect(find.byType(AnimatedContainer), findsNWidgets(4));
  });
}
