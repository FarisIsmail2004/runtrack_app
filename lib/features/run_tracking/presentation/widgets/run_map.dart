import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';

import '../../../../shared/theme/app_motion.dart';
import '../../domain/run_point.dart';

/// Map with the live route polyline.
///
/// [showTiles] exists so widget tests can render the polyline without any
/// network tile fetches.
///
/// [fitBounds] pans/zooms to fit all points when the map is ready and
/// whenever the point list changes. Ignored when [points] has fewer than 2
/// entries. Has no effect when [followLatest] is also true.
class RunMap extends StatefulWidget {
  const RunMap({
    super.key,
    required this.points,
    this.followLatest = true,
    this.fitBounds = false,
    this.showTiles = true,
    this.animateDraw = false,
  });

  final List<RunPoint> points;
  final bool followLatest;
  final bool fitBounds;
  final bool showTiles;

  /// When true, the route polyline draws itself from start to finish once on
  /// first show (the post-run summary reveal). Honors reduced motion.
  final bool animateDraw;

  @override
  State<RunMap> createState() => _RunMapState();
}

class _RunMapState extends State<RunMap> with SingleTickerProviderStateMixin {
  final MapController _controller = MapController();
  bool _mapReady = false;

  /// Drives the draw-on reveal; null when [RunMap.animateDraw] is false.
  AnimationController? _draw;
  bool _drawStarted = false;

  /// Points to render right now — the full list, or a growing prefix mid-reveal.
  List<RunPoint> get _visiblePoints {
    final draw = _draw;
    if (draw == null) return widget.points;
    final n = widget.points.length;
    final count = (n * draw.value).ceil().clamp(0, n);
    return widget.points.sublist(0, count);
  }

  LatLng? get _latest {
    final pts = _visiblePoints;
    return pts.isEmpty ? null : LatLng(pts.last.lat, pts.last.lng);
  }

  @override
  void initState() {
    super.initState();
    if (widget.animateDraw) {
      _draw = AnimationController(vsync: this, duration: AppMotion.reveal);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final draw = _draw;
    if (draw == null || _drawStarted) return;
    _drawStarted = true;
    draw.duration = AppMotion.duration(context, AppMotion.reveal);
    draw.forward();
  }

  void _applyFitBounds() {
    if (!_mapReady || widget.points.length < 2) return;
    final lats = widget.points.map((p) => p.lat);
    final lngs = widget.points.map((p) => p.lng);
    final bounds = LatLngBounds(
      LatLng(
        lats.reduce((a, b) => a < b ? a : b),
        lngs.reduce((a, b) => a < b ? a : b),
      ),
      LatLng(
        lats.reduce((a, b) => a > b ? a : b),
        lngs.reduce((a, b) => a > b ? a : b),
      ),
    );
    _controller.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
    );
  }

  @override
  void didUpdateWidget(RunMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showTiles != oldWidget.showTiles) {
      _mapReady = false;
    }
    final latest = _latest;
    if (_mapReady &&
        widget.followLatest &&
        latest != null &&
        widget.points.length != oldWidget.points.length) {
      _controller.move(latest, 16);
    } else if (widget.fitBounds &&
        widget.points.length != oldWidget.points.length) {
      _applyFitBounds();
    }
  }

  @override
  void dispose() {
    _draw?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draw = _draw;
    if (draw == null) return _buildMap(context);
    return AnimatedBuilder(
      animation: draw,
      builder: (context, _) => _buildMap(context),
    );
  }

  Widget _buildMap(BuildContext context) {
    final route = _visiblePoints
        .map((p) => LatLng(p.lat, p.lng))
        .toList(growable: false);

    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: _latest ?? const LatLng(0, 0),
        initialZoom: 16,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onMapReady: () {
          _mapReady = true;
          if (widget.fitBounds) _applyFitBounds();
        },
      ),
      children: [
        if (widget.showTiles)
          // Subtle darken so the dark UI doesn't clash with bright OSM tiles
          // while roads stay readable.
          ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.55, 0, 0, 0, 0, //
              0, 0.55, 0, 0, 0, //
              0, 0, 0.55, 0, 0, //
              0, 0, 0, 1, 0, //
            ]),
            child: TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.runtrack_app',
            ),
          ),
        if (route.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: route,
                strokeWidth: 4,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        if (_latest != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _latest!,
                width: 18.r,
                height: 18.r,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
