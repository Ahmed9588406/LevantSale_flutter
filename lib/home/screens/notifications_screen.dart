import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F5F5),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'الإشعارات',
            style: TextStyle(
              color: Color(0xFF2B2B2A),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2B2B2A)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
              decoration: BoxDecoration(
                color: Colors
                    .transparent, // removed filled background so asset displays on screen bg
                // keep rounded corners and a subtle border to retain a "card" look
                border: Border.all(color: const Color(0xFFEDEDED)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Empty notification illustration
                  SizedBox(
                    width: 200,
                    height: 220, // make the image higher/taller
                    child: Image.asset(
                      'icons/CTA buttons Ar.png',
                      fit: BoxFit.contain,
                      // If the image fails to load (missing asset), fall
                      // back to the existing CustomPaint illustration.
                      errorBuilder: (context, error, stackTrace) {
                        return CustomPaint(painter: EmptyNotificationPainter());
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Empty state text
                  const Text(
                    'لا يوجد إشعارات جديدة',
                    style: TextStyle(
                      color: Color(0xFF2B2B2A),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyNotificationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4A574)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw bell body
    final bellPath = Path();
    bellPath.moveTo(center.dx - 30, center.dy - 10);
    bellPath.quadraticBezierTo(
      center.dx - 35,
      center.dy - 35,
      center.dx - 20,
      center.dy - 45,
    );
    bellPath.lineTo(center.dx + 20, center.dy - 45);
    bellPath.quadraticBezierTo(
      center.dx + 35,
      center.dy - 35,
      center.dx + 30,
      center.dy - 10,
    );
    bellPath.lineTo(center.dx - 30, center.dy - 10);
    canvas.drawPath(bellPath, paint);

    // Draw bell bottom
    canvas.drawLine(
      Offset(center.dx - 35, center.dy - 10),
      Offset(center.dx + 35, center.dy - 10),
      paint,
    );

    // Draw bell clapper
    canvas.drawCircle(Offset(center.dx, center.dy - 5), 4, paint);

    // Draw bell top
    canvas.drawLine(
      Offset(center.dx - 5, center.dy - 45),
      Offset(center.dx + 5, center.dy - 45),
      paint,
    );
    canvas.drawCircle(Offset(center.dx, center.dy - 50), 3, paint);

    // Draw notification bubble (left)
    final bubblePath1 = Path();
    bubblePath1.addOval(
      Rect.fromCircle(
        center: Offset(center.dx - 45, center.dy - 25),
        radius: 20,
      ),
    );
    canvas.drawPath(bubblePath1, paint);

    // Draw small circle in bubble
    canvas.drawCircle(
      Offset(center.dx - 45, center.dy - 25),
      3,
      Paint()
        ..color = const Color(0xFFD4A574)
        ..style = PaintingStyle.fill,
    );

    // Draw message bubble (right)
    final messagePath = Path();
    messagePath.moveTo(center.dx + 35, center.dy - 35);
    messagePath.lineTo(center.dx + 55, center.dy - 35);
    messagePath.lineTo(center.dx + 55, center.dy - 20);
    messagePath.lineTo(center.dx + 35, center.dy - 20);
    messagePath.close();
    canvas.drawPath(messagePath, paint);

    // Draw three dots in message bubble
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(center.dx + 40 + (i * 6), center.dy - 27.5),
        2,
        Paint()
          ..color = const Color(0xFFD4A574)
          ..style = PaintingStyle.fill,
      );
    }

    // Draw small plus signs
    final plusPaint = Paint()
      ..color = const Color(0xFFD4A574)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Plus 1
    canvas.drawLine(
      Offset(center.dx + 60, center.dy - 45),
      Offset(center.dx + 68, center.dy - 45),
      plusPaint,
    );
    canvas.drawLine(
      Offset(center.dx + 64, center.dy - 49),
      Offset(center.dx + 64, center.dy - 41),
      plusPaint,
    );

    // Plus 2
    canvas.drawLine(
      Offset(center.dx - 60, center.dy - 10),
      Offset(center.dx - 68, center.dy - 10),
      plusPaint,
    );
    canvas.drawLine(
      Offset(center.dx - 64, center.dy - 14),
      Offset(center.dx - 64, center.dy - 6),
      plusPaint,
    );

    // Draw base line
    canvas.drawLine(
      Offset(center.dx - 40, center.dy + 10),
      Offset(center.dx + 40, center.dy + 10),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
