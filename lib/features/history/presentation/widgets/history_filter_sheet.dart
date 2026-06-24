import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:runtrack_app/core/utils/pace_format.dart';
import 'package:runtrack_app/core/utils/unit_system.dart';
import 'package:runtrack_app/features/history/application/history_filter.dart';
import 'package:runtrack_app/features/profile/application/profile_providers.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';

/// Opens the History sort + filter sheet.
Future<void> showHistoryFilterSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => const _HistoryFilterSheet(),
    );

class _HistoryFilterSheet extends ConsumerStatefulWidget {
  const _HistoryFilterSheet();

  @override
  ConsumerState<_HistoryFilterSheet> createState() =>
      _HistoryFilterSheetState();
}

class _HistoryFilterSheetState extends ConsumerState<_HistoryFilterSheet> {
  late RunSortField _sortField;
  late bool _descending;
  final _minDist = TextEditingController();
  final _maxDist = TextEditingController();
  final _minDur = TextEditingController();
  final _maxDur = TextEditingController();

  @override
  void initState() {
    super.initState();
    final filter = ref.read(historyFilterProvider);
    final unit = ref.read(unitProvider);
    _sortField = filter.sortField;
    _descending = filter.descending;
    _minDist.text = _metersToInput(filter.minDistanceM, unit);
    _maxDist.text = _metersToInput(filter.maxDistanceM, unit);
    _minDur.text = _secondsToInput(filter.minDurationS);
    _maxDur.text = _secondsToInput(filter.maxDurationS);
  }

  @override
  void dispose() {
    _minDist.dispose();
    _maxDist.dispose();
    _minDur.dispose();
    _maxDur.dispose();
    super.dispose();
  }

  static String _metersToInput(double? meters, UnitSystem unit) {
    if (meters == null) return '';
    final value = unit == UnitSystem.mi
        ? meters / metersPerMile
        : meters / 1000.0;
    // Trim a trailing ".0" so re-opening shows clean numbers.
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toString();
  }

  static String _secondsToInput(int? seconds) =>
      seconds == null ? '' : (seconds ~/ 60).toString();

  double? _inputToMeters(String text, UnitSystem unit) {
    final v = double.tryParse(text.trim());
    if (v == null) return null;
    return unit == UnitSystem.mi ? v * metersPerMile : v * 1000.0;
  }

  int? _inputToSeconds(String text) {
    final v = double.tryParse(text.trim());
    if (v == null) return null;
    return (v * 60).round();
  }

  void _apply() {
    final unit = ref.read(unitProvider);
    ref.read(historyFilterProvider.notifier).state = HistoryFilter(
      sortField: _sortField,
      descending: _descending,
      minDistanceM: _inputToMeters(_minDist.text, unit),
      maxDistanceM: _inputToMeters(_maxDist.text, unit),
      minDurationS: _inputToSeconds(_minDur.text),
      maxDurationS: _inputToSeconds(_maxDur.text),
    );
    Navigator.pop(context);
  }

  void _reset() {
    ref.read(historyFilterProvider.notifier).state = const HistoryFilter();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appColors = AppColors.of(context);
    final unit = ref.watch(unitProvider);
    final distLabel = distanceUnitLabel(unit);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24.w,
          12.h,
          24.w,
          16.h + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: appColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            Text(
              'Sort & filter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 16.h),

            // ── Sort by ──────────────────────────────────────────────────
            _Label('SORT BY'),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final f in RunSortField.values)
                  ChoiceChip(
                    label: Text(f.label),
                    selected: _sortField == f,
                    onSelected: (_) => setState(() => _sortField = f),
                  ),
              ],
            ),
            SizedBox(height: 16.h),

            // ── Order ────────────────────────────────────────────────────
            _Label('ORDER'),
            SizedBox(height: 8.h),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text(_descLabel(_sortField)),
                  icon: const Icon(Icons.arrow_downward, size: 16),
                ),
                ButtonSegment(
                  value: false,
                  label: Text(_ascLabel(_sortField)),
                  icon: const Icon(Icons.arrow_upward, size: 16),
                ),
              ],
              selected: {_descending},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _descending = s.first),
            ),
            SizedBox(height: 20.h),

            // ── Distance range ───────────────────────────────────────────
            _Label('DISTANCE ($distLabel)'),
            SizedBox(height: 8.h),
            _RangeRow(minController: _minDist, maxController: _maxDist),
            SizedBox(height: 16.h),

            // ── Duration range ───────────────────────────────────────────
            _Label('DURATION (min)'),
            SizedBox(height: 8.h),
            _RangeRow(minController: _minDur, maxController: _maxDur),
            SizedBox(height: 24.h),

            // ── Actions ──────────────────────────────────────────────────
            Row(
              children: [
                TextButton(
                  onPressed: _reset,
                  child: Text(
                    'RESET',
                    style: TextStyle(color: appColors.textMuted),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(backgroundColor: cs.primary),
                  child: const Text('APPLY'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _descLabel(RunSortField f) => switch (f) {
    RunSortField.date => 'Newest',
    RunSortField.distance => 'Longest',
    RunSortField.duration => 'Longest',
    RunSortField.pace => 'Slowest',
  };

  static String _ascLabel(RunSortField f) => switch (f) {
    RunSortField.date => 'Oldest',
    RunSortField.distance => 'Shortest',
    RunSortField.duration => 'Shortest',
    RunSortField.pace => 'Fastest',
  };
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: AppColors.of(context).textMuted,
      ),
    );
  }
}

class _RangeRow extends StatelessWidget {
  const _RangeRow({required this.minController, required this.maxController});

  final TextEditingController minController;
  final TextEditingController maxController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _NumberField(controller: minController, hint: 'Min'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            '–',
            style: TextStyle(color: AppColors.of(context).textMuted),
          ),
        ),
        Expanded(
          child: _NumberField(controller: maxController, hint: 'Max'),
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appColors = AppColors.of(context);
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      style: TextStyle(color: cs.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: appColors.textMuted),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: appColors.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: appColors.surfaceBorder),
        ),
      ),
    );
  }
}
