import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';

class PesoRayLogo extends StatelessWidget {
  final double size;
  final double pulse;

  const PesoRayLogo({
    super.key,
    this.size = 200,
    this.pulse = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: PesoRayLogoPainter(pulse: pulse),
      ),
    );
  }
}

class PesoRayLogoPainter extends CustomPainter {
  final double pulse;

  PesoRayLogoPainter({this.pulse = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final coinRadius = size.width * 0.28;

    final rayPaint = Paint()
      ..color = const Color(0xFFF9B818)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Draw 16 rays around the coin
    const int rayCount = 16;
    for (int i = 0; i < rayCount; i++) {
      final isLongRay = (i % 2 == 0);
      final angle = (i * 2 * math.pi) / rayCount;

      final rayLength = isLongRay
          ? coinRadius * (1.68 + (pulse - 1.0) * 0.12)
          : coinRadius * 1.32;
      final halfWidth = isLongRay ? 0.12 : 0.08;

      final p1 = Offset(
        center.dx + coinRadius * 0.95 * math.cos(angle - halfWidth),
        center.dy + coinRadius * 0.95 * math.sin(angle - halfWidth),
      );
      final p2 = Offset(
        center.dx + rayLength * math.cos(angle),
        center.dy + rayLength * math.sin(angle),
      );
      final p3 = Offset(
        center.dx + coinRadius * 0.95 * math.cos(angle + halfWidth),
        center.dy + coinRadius * 0.95 * math.sin(angle + halfWidth),
      );

      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();

      canvas.drawPath(path, rayPaint);
    }

    // Outer coin circle
    final outerCoinPaint = Paint()
      ..color = const Color(0xFFEDB220)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(center, coinRadius, outerCoinPaint);

    // Coin border rim
    final rimPaint = Paint()
      ..color = const Color(0xFFD6940C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = coinRadius * 0.06
      ..isAntiAlias = true;
    canvas.drawCircle(center, coinRadius * 0.93, rimPaint);

    // Inner coin surface
    final innerCoinPaint = Paint()
      ..color = const Color(0xFFF6BC26)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(center, coinRadius * 0.88, innerCoinPaint);

    // Peso symbol ₱ in center
    final textPainter = TextPainter(
      text: TextSpan(
        text: '₱',
        style: TextStyle(
          color: const Color(0xFF0C3C2E),
          fontSize: coinRadius * 1.3,
          fontWeight: FontWeight.w900,
          fontFamilyFallback: const ['sans-serif', 'Arial'],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2 - (coinRadius * 0.05),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant PesoRayLogoPainter oldDelegate) =>
      oldDelegate.pulse != pulse;
}
