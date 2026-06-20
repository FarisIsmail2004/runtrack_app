import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';

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
  });

  final List<RunPoint> points;
  final bool followLatest;
  final bool fitBounds;
  final bool showTiles;

  @override
  State<RunMap> createState() => _RunMapState();
}

class _RunMapState extends State<RunMap> {
  final MapController _controller = MapController();
  bool _mapReady = false;

  LatLng? get _latest => widget.points.isEmpty
      ? null
      : LatLng(widget.points.last.lat, widget.points.last.lng);

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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.points
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
