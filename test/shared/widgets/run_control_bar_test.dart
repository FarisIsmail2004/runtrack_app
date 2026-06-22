// test/shared/widgets/run_control_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';
import 'package:runtrack_app/shared/widgets/run_control_bar.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.dark,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('RunControlBar', () {
    testWidgets('paused:false shows Icons.pause; taps fire correct callbacks', (
      tester,
    ) async {
      var playPauseFired = false;
      var stopFired = false;
      var lockFired = false;

      await tester.pumpWidget(
        _wrap(
          RunControlBar(
            paused: false,
            locked: false,
            onLockToggle: () => lockFired = true,
            onPlayPause: () => playPauseFired = true,
            onStop: () => stopFired = true,
          ),
        ),
      );

      // Center button shows pause icon when running
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);

      // Tap play/pause by key
      await tester.tap(find.byKey(const ValueKey('run-playpause')));
      expect(playPauseFired, isTrue);

      // Tap stop by key
      await tester.tap(find.byKey(const ValueKey('run-stop')));
      expect(stopFired, isTrue);

      // Tap lock by key
      await tester.tap(find.byKey(const ValueKey('run-lock')));
      expect(lockFired, isTrue);
    });

    testWidgets('paused:true shows Icons.play_arrow', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RunControlBar(
            paused: true,
            locked: false,
            onLockToggle: () {},
            onPlayPause: () {},
            onStop: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets(
      'locked:true disables stop/play-pause but lock toggle still fires',
      (tester) async {
        var playPauseFired = false;
        var stopFired = false;
        var lockFired = false;

        await tester.pumpWidget(
          _wrap(
            RunControlBar(
              paused: false,
              locked: true,
              onLockToggle: () => lockFired = true,
              onPlayPause: () => playPauseFired = true,
              onStop: () => stopFired = true,
            ),
          ),
        );

        // Tapping stop must NOT fire callback when locked
        await tester.tap(find.byKey(const ValueKey('run-stop')));
        expect(stopFired, isFalse);

        // Tapping play/pause must NOT fire callback when locked
        await tester.tap(find.byKey(const ValueKey('run-playpause')));
        expect(playPauseFired, isFalse);

        // Lock toggle must ALWAYS fire
        await tester.tap(find.byKey(const ValueKey('run-lock')));
        expect(lockFired, isTrue);
      },
    );

    testWidgets('locked:true keeps lock icon as Icons.lock', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RunControlBar(
            paused: false,
            locked: true,
            onLockToggle: () {},
            onPlayPause: () {},
            onStop: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.byIcon(Icons.lock_open), findsNothing);
    });

    testWidgets('locked:false shows Icons.lock_open', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RunControlBar(
            paused: false,
            locked: false,
            onLockToggle: () {},
            onPlayPause: () {},
            onStop: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.lock_open), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsNothing);
    });
  });
}
