import 'package:flutter/material.dart';

enum ShipperNavIconType { home, shipments, analytics, account }

/// A small, consistent set of hand-drawn vector icons for the shipper tabs.
class ShipperNavIcon extends StatelessWidget {
  const ShipperNavIcon({
    required this.type,
    required this.color,
    required this.selected,
    super.key,
  });

  final ShipperNavIconType type;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(27),
      painter: _ShipperNavIconPainter(
        type: type,
        color: color,
        selected: selected,
      ),
    );
  }
}

class _ShipperNavIconPainter extends CustomPainter {
  const _ShipperNavIconPainter({
    required this.type,
    required this.color,
    required this.selected,
  });

  final ShipperNavIconType type;
  final Color color;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 2.05 : 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (type) {
      case ShipperNavIconType.home:
        _drawHome(canvas, stroke, fill);
      case ShipperNavIconType.shipments:
        _drawShipments(canvas, stroke, fill);
      case ShipperNavIconType.analytics:
        _drawAnalytics(canvas, stroke, fill);
      case ShipperNavIconType.account:
        _drawAccount(canvas, stroke, fill);
    }

    canvas.restore();
  }

  void _drawHome(Canvas canvas, Paint stroke, Paint fill) {
    final roof = Path()
      ..moveTo(3.5, 10.5)
      ..lineTo(12, 3.5)
      ..lineTo(20.5, 10.5);
    canvas.drawPath(roof, stroke);

    final house = Path()
      ..moveTo(5.5, 9.5)
      ..lineTo(5.5, 19.5)
      ..quadraticBezierTo(5.5, 20.5, 6.5, 20.5)
      ..lineTo(17.5, 20.5)
      ..quadraticBezierTo(18.5, 20.5, 18.5, 19.5)
      ..lineTo(18.5, 9.5);
    canvas.drawPath(house, stroke);
    final door = RRect.fromRectAndRadius(
      const Rect.fromLTWH(10, 14, 4, 6.5),
      const Radius.circular(1.6),
    );
    canvas.drawRRect(door, selected ? fill : stroke);
  }

  void _drawShipments(Canvas canvas, Paint stroke, Paint fill) {
    final truck = Path()
      ..moveTo(2.5, 7)
      ..quadraticBezierTo(2.5, 6, 3.5, 6)
      ..lineTo(14.5, 6)
      ..quadraticBezierTo(15.5, 6, 15.5, 7)
      ..lineTo(15.5, 10)
      ..lineTo(19, 10)
      ..lineTo(22, 13.5)
      ..lineTo(22, 18)
      ..quadraticBezierTo(22, 19, 21, 19)
      ..lineTo(3.5, 19)
      ..quadraticBezierTo(2.5, 19, 2.5, 18)
      ..close();
    canvas.drawPath(truck, stroke);
    canvas.drawLine(const Offset(15.5, 13), const Offset(21.2, 13), stroke);

    final parcel = Path()
      ..moveTo(5.5, 8.5)
      ..lineTo(9, 7.5)
      ..lineTo(12.5, 8.5)
      ..lineTo(9, 10)
      ..close();
    if (selected) {
      canvas.drawPath(parcel, fill);
      canvas.drawLine(const Offset(9, 10), const Offset(9, 13), stroke);
    } else {
      canvas.drawPath(parcel, stroke);
      canvas.drawLine(const Offset(9, 10), const Offset(9, 13), stroke);
    }

    canvas.drawCircle(const Offset(7, 19), 1.7, fill);
    canvas.drawCircle(const Offset(7, 19), 1.7, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(18, 19), 1.7, fill);
    canvas.drawCircle(const Offset(18, 19), 1.7, Paint()..color = Colors.white);
  }

  void _drawAnalytics(Canvas canvas, Paint stroke, Paint fill) {
    final baseline = Paint()
      ..color = color.withValues(alpha: .45)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(3.5, 20), const Offset(21, 20), baseline);

    final bars = <RRect>[
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(5, 13, 3, 7),
        const Radius.circular(1.5),
      ),
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10.5, 9, 3, 11),
        const Radius.circular(1.5),
      ),
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(16, 4, 3, 16),
        const Radius.circular(1.5),
      ),
    ];
    for (var index = 0; index < bars.length; index++) {
      canvas.drawRRect(bars[index], fill);
      if (!selected && index == 2) {
        canvas.drawRRect(
          bars[index],
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }
  }

  void _drawAccount(Canvas canvas, Paint stroke, Paint fill) {
    canvas.drawCircle(const Offset(12, 7.5), 3.7, stroke);

    final shoulders = Path()
      ..moveTo(4, 20)
      ..lineTo(4, 18.5)
      ..cubicTo(4, 15, 7.3, 13.5, 12, 13.5)
      ..cubicTo(16.7, 13.5, 20, 15, 20, 18.5)
      ..lineTo(20, 20)
      ..close();
    if (selected) {
      canvas.drawPath(shoulders, fill);
    } else {
      canvas.drawPath(shoulders, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _ShipperNavIconPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.color != color ||
        oldDelegate.selected != selected;
  }
}
