import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Outline illustrations for the vehicle choices in the load form.
class VehicleTypeIcon extends StatelessWidget {
  const VehicleTypeIcon({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: const Size(42, 27),
      painter: _VehiclePainter(type),
    ),
  );
}

class _VehiclePainter extends CustomPainter {
  const _VehiclePainter(this.type);
  final String type;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 40);
    final line = Paint()
      ..color = AppColors.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void segment(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), line);
    void box(double l, double t, double r, double b, [double radius = 1]) =>
        canvas.drawRRect(
          RRect.fromLTRBR(l, t, r, b, Radius.circular(radius)),
          line,
        );
    void wheel(double x) {
      canvas.drawCircle(Offset(x, 31), 4, line);
      canvas.drawCircle(Offset(x, 31), 1, Paint()..color = AppColors.navy);
    }

    if (type == 'Trailer') {
      box(3, 13, 61, 20, 1.5);
      segment(4, 24, 60, 24);
      segment(9, 20, 9, 24);
      segment(54, 20, 54, 24);
      for (final x in [13.0, 22.0, 45.0, 54.0]) {
        wheel(x);
      }
      canvas.restore();
      return;
    }

    final cab = Path()
      ..moveTo(3, 28)
      ..lineTo(3, 17)
      ..lineTo(8, 9)
      ..lineTo(19, 9)
      ..lineTo(19, 28)
      ..moveTo(3, 28)
      ..lineTo(7, 28)
      ..moveTo(15, 28)
      ..lineTo(46, 28)
      ..moveTo(54, 28)
      ..lineTo(61, 28);
    canvas.drawPath(cab, line);
    canvas.drawPath(
      Path()
        ..moveTo(7, 17)
        ..lineTo(10, 12)
        ..lineTo(16, 12)
        ..lineTo(16, 17)
        ..close(),
      line,
    );
    segment(15, 21, 17, 21);

    switch (type) {
      case 'Open':
        segment(21, 17, 60, 17);
        segment(21, 23, 60, 23);
        segment(21, 13, 21, 27);
        segment(60, 13, 60, 27);
        break;
      case 'Closed':
        box(21, 8, 60, 27, 2);
        break;
      case 'Container':
        box(21, 8, 60, 27, 1);
        for (final x in [27.0, 34.0, 41.0, 48.0, 55.0]) {
          segment(x, 11, x, 24);
        }
        break;
      case 'Tipper':
        canvas.drawPath(
          Path()
            ..moveTo(21, 13)
            ..lineTo(60, 10)
            ..lineTo(55, 24)
            ..lineTo(25, 24)
            ..close(),
          line,
        );
        segment(25, 27, 56, 27);
        break;
      case 'Tanker':
        box(21, 10, 60, 24, 7);
        segment(27, 24, 27, 27);
        segment(54, 24, 54, 27);
        segment(34, 7, 43, 7);
        break;
    }
    wheel(11);
    wheel(50);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _VehiclePainter oldDelegate) =>
      oldDelegate.type != type;
}
