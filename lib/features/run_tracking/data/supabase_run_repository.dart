import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:runtrack_app/features/run_tracking/data/remote_run_repository.dart';
import 'package:runtrack_app/features/run_tracking/domain/run.dart';
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart';

/// Supabase-backed [RemoteRunRepository]. Row Level Security on the `runs` and
/// `run_points` tables enforces that a user can only write their own rows, so
/// `user_id` is always set to the signed-in user here.
class SupabaseRunRepository implements RemoteRunRepository {
  SupabaseRunRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> pushRun(
    Run run,
    List<RunPoint> points, {
    required String userId,
  }) async {
    // Upsert the run row — idempotent on the uuid primary key, so a retry after
    // a partial failure (or a duplicate trigger) never duplicates the run.
    await _client.from('runs').upsert({
      'id': run.id,
      'user_id': userId,
      'started_at': run.startedAt.toUtc().toIso8601String(),
      'ended_at': run.endedAt?.toUtc().toIso8601String(),
      'distance_m': run.distanceM,
      'duration_s': run.durationS,
      'avg_pace_s_per_km': run.avgPaceSPerKm,
      'calories_est': run.caloriesEst,
      'synced': true,
    });

    // Points are immutable once a run is finished, so replace wholesale:
    // clear any rows from a previous partial push, then bulk insert. Simpler
    // and cheaper than per-row upsert (run_points has no natural key here).
    await _client.from('run_points').delete().eq('run_id', run.id);
    if (points.isNotEmpty) {
      await _client.from('run_points').insert([
        for (final p in points)
          {
            'run_id': run.id,
            'lat': p.lat,
            'lng': p.lng,
            'elevation': p.elevation,
            'speed': p.speed,
            'accuracy': p.accuracy,
            'recorded_at': p.timestamp.toUtc().toIso8601String(),
          },
      ]);
    }
  }

  @override
  Future<List<(Run, List<RunPoint>)>> fetchRuns(String userId) async {
    final runRows = await _client
        .from('runs')
        .select()
        .eq('user_id', userId)
        .order('started_at');
    if (runRows.isEmpty) return const [];

    // Pull every point for these runs in one round-trip, then group by run_id.
    final runIds = [for (final r in runRows) r['id'] as String];
    final pointRows = await _client
        .from('run_points')
        .select()
        .inFilter('run_id', runIds)
        .order('recorded_at');

    final pointsByRun = <String, List<RunPoint>>{};
    for (final p in pointRows) {
      (pointsByRun[p['run_id'] as String] ??= []).add(
        RunPoint(
          lat: (p['lat'] as num).toDouble(),
          lng: (p['lng'] as num).toDouble(),
          elevation: (p['elevation'] as num?)?.toDouble(),
          timestamp: DateTime.parse(p['recorded_at'] as String),
          speed: (p['speed'] as num?)?.toDouble(),
          accuracy: (p['accuracy'] as num?)?.toDouble(),
        ),
      );
    }

    return [
      for (final r in runRows)
        (
          Run(
            id: r['id'] as String,
            startedAt: DateTime.parse(r['started_at'] as String),
            endedAt: r['ended_at'] == null
                ? null
                : DateTime.parse(r['ended_at'] as String),
            distanceM: (r['distance_m'] as num?)?.toDouble() ?? 0,
            durationS: (r['duration_s'] as num?)?.toInt() ?? 0,
            avgPaceSPerKm: (r['avg_pace_s_per_km'] as num?)?.toDouble() ?? 0,
            caloriesEst: (r['calories_est'] as num?)?.toDouble() ?? 0,
            synced: true,
          ),
          pointsByRun[r['id'] as String] ?? const [],
        ),
    ];
  }
}
