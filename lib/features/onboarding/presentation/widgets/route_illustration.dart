import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Stylised map: a faint street grid with an orange route polyline and two end
/// dots, evoking a tracked run. Drawn in-code so no map tiles/assets are needed.
class RouteIllustration extends StatelessWidget {
  const RouteIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240.w,
      height: 240.w,
      child: CustomPaint(painter: _RoutePainter()),
    );
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const orange = Color(0xFFFF6A00);
    final grid = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1;
    const step = 32.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final route = Paint()
      ..color = orange
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.25, size.height * 0.78)
      ..lineTo(size.width * 0.25, size.height * 0.5)
      ..lineTo(size.width * 0.5, size.height * 0.5)
      ..lineTo(size.width * 0.5, size.height * 0.25)
      ..lineTo(size.width * 0.78, size.height * 0.25);
    canvas.drawPath(path, route);

    final dot = Paint()..color = orange;
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.78), 7, dot);
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.25),
      7,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
