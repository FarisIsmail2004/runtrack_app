// lib/shared/widgets/run_control_bar.dart
import 'package:flutter/material.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';

/// Unified run-control bar: lock toggle (left) · play/pause (center) · stop (right).
///
/// When [locked] is true, the play/pause and stop controls are disabled and
/// dimmed via [withValues(alpha:)], but the bar geometry is unchanged — same
/// sizes and positions; only opacity changes.  The lock toggle is always active
/// so the user can unlock.
///
/// ValueKeys for reliable test targeting:
///   - `'run-lock'`      → lock toggle button
///   - `'run-playpause'` → center play/pause button
///   - `'run-stop'`      → stop button
class RunControlBar extends StatelessWidget {
  const RunControlBar({
    super.key,
    required this.paused,
    required this.locked,
    required this.onLockToggle,
    required this.onPlayPause,
    required this.onStop,
  });

  final bool paused;
  final bool locked;
  final VoidCallback onLockToggle;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;

  static const double _sideButtonSize = 48.0;
  static const double _centerButtonSize = 72.0;
  static const double _dimAlpha = 0.35;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final destructive = AppColors.of(context).destructive;

    // Dimming factor applied to disabled controls when locked.
    final double controlAlpha = locked ? _dimAlpha : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Lock toggle (always enabled) ──────────────────────────────
          SizedBox(
            width: _sideButtonSize,
            height: _sideButtonSize,
            child: IconButton(
              key: const ValueKey('run-lock'),
              onPressed: onLockToggle,
              icon: Icon(
                locked ? Icons.lock : Icons.lock_open,
                color: cs.onSurface,
              ),
            ),
          ),

          // ── Play / Pause (center, large, accent, disabled when locked) ─
          SizedBox(
            width: _centerButtonSize,
            height: _centerButtonSize,
            child: Opacity(
              opacity: controlAlpha,
              child: FilledButton(
                key: const ValueKey('run-playpause'),
                onPressed: locked ? null : onPlayPause,
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                ),
                child: Icon(paused ? Icons.play_arrow : Icons.pause, size: 32),
              ),
            ),
          ),

          // ── Stop (right, destructive, disabled when locked) ────────────
          SizedBox(
            width: _sideButtonSize,
            height: _sideButtonSize,
            child: Opacity(
              opacity: controlAlpha,
              child: IconButton(
                key: const ValueKey('run-stop'),
                onPressed: locked ? null : onStop,
                icon: Icon(Icons.stop_circle_outlined, color: destructive),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
