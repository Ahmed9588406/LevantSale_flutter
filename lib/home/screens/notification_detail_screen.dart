import 'package:flutter/material.dart';
import '../../notifications/notifications_service.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
    required this.onMarkRead,
    required this.onDelete,
  });

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) {
        return 'الآن';
      } else if (diff.inHours < 1) {
        return 'منذ ${diff.inMinutes} دقيقة';
      } else if (diff.inDays < 1) {
        return 'منذ ${diff.inHours} ساعة';
      } else if (diff.inDays < 7) {
        return 'منذ ${diff.inDays} يوم';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'تفاصيل الإشعار',
            style: TextStyle(
              color: Color(0xFF2B2B2A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2B2B2A)),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF2B2B2A)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'mark_read' && !notification.read) {
                  onMarkRead();
                  Navigator.pop(context);
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                if (!notification.read)
                  const PopupMenuItem(
                    value: 'mark_read',
                    child: Row(
                      children: [
                        Icon(Icons.done, size: 20, color: Color(0xFF1DAF52)),
                        SizedBox(width: 12),
                        Text('تحديد كمقروء'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Color(0xFFE53935),
                      ),
                      SizedBox(width: 12),
                      Text('حذف'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification image or illustration
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child:
                      notification.imageUrl != null &&
                          notification.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            notification.imageUrl!,
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return SizedBox(
                                width: 200,
                                height: 200,
                                child: CustomPaint(
                                  painter: NotificationIllustrationPainter(),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return SizedBox(
                                width: 200,
                                height: 200,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                        : null,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Color(0xFFD4A574),
                                        ),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : SizedBox(
                          width: 200,
                          height: 200,
                          child: CustomPaint(
                            painter: NotificationIllustrationPainter(),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Content card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: notification.read
                                ? const Color(0xFFE0E0E0)
                                : const Color(0xFF1DAF52).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: notification.read
                                      ? const Color(0xFF9E9E9E)
                                      : const Color(0xFF1DAF52),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                notification.read ? 'مقروء' : 'جديد',
                                style: TextStyle(
                                  color: notification.read
                                      ? const Color(0xFF6B6B6B)
                                      : const Color(0xFF1DAF52),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(notification.createdAt),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Title
                    Text(
                      notification.title.isEmpty ? 'إشعار' : notification.title,
                      style: const TextStyle(
                        color: Color(0xFF2B2B2A),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Divider
                    Container(height: 1, color: const Color(0xFFEDEDED)),

                    const SizedBox(height: 16),

                    // Body
                    Text(
                      notification.body.isEmpty
                          ? 'لا يوجد محتوى للإشعار'
                          : notification.body,
                      style: const TextStyle(
                        color: Color(0xFF6B6B6B),
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (!notification.read)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            onMarkRead();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.done, size: 20),
                          label: const Text('تحديد كمقروء'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1DAF52),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    if (!notification.read) const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 20),
                        label: const Text('حذف'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE53935),
                          side: const BorderSide(
                            color: Color(0xFFE53935),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4A574)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw bell body
    final bellPath = Path();
    bellPath.moveTo(center.dx - 40, center.dy - 10);
    bellPath.quadraticBezierTo(
      center.dx - 45,
      center.dy - 45,
      center.dx - 25,
      center.dy - 55,
    );
    bellPath.lineTo(center.dx + 25, center.dy - 55);
    bellPath.quadraticBezierTo(
      center.dx + 45,
      center.dy - 45,
      center.dx + 40,
      center.dy - 10,
    );
    bellPath.lineTo(center.dx - 40, center.dy - 10);
    canvas.drawPath(bellPath, paint);

    // Draw bell bottom
    canvas.drawLine(
      Offset(center.dx - 45, center.dy - 10),
      Offset(center.dx + 45, center.dy - 10),
      paint,
    );

    // Draw bell clapper
    canvas.drawCircle(Offset(center.dx, center.dy - 5), 5, paint);

    // Draw bell top
    canvas.drawLine(
      Offset(center.dx - 8, center.dy - 55),
      Offset(center.dx + 8, center.dy - 55),
      paint,
    );
    canvas.drawCircle(Offset(center.dx, center.dy - 62), 4, paint);

    // Draw notification waves (left)
    final wavePaint = Paint()
      ..color = const Color(0xFFD4A574)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Left waves
    for (int i = 0; i < 3; i++) {
      final offset = (i + 1) * 12.0;
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(center.dx - 40, center.dy - 35),
          radius: 15 + offset,
        ),
        3.14 * 0.7,
        3.14 * 0.6,
        false,
        wavePaint..strokeWidth = 2.5 - (i * 0.5),
      );
    }

    // Right waves
    for (int i = 0; i < 3; i++) {
      final offset = (i + 1) * 12.0;
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(center.dx + 40, center.dy - 35),
          radius: 15 + offset,
        ),
        -3.14 * 0.3,
        3.14 * 0.6,
        false,
        wavePaint..strokeWidth = 2.5 - (i * 0.5),
      );
    }

    // Draw sparkles
    final sparklePaint = Paint()
      ..color = const Color(0xFFD4A574)
      ..style = PaintingStyle.fill;

    // Sparkle positions
    final sparkles = [
      Offset(center.dx - 60, center.dy - 60),
      Offset(center.dx + 60, center.dy - 60),
      Offset(center.dx - 50, center.dy + 10),
      Offset(center.dx + 50, center.dy + 10),
    ];

    for (final sparkle in sparkles) {
      // Draw star shape
      final starPath = Path();
      for (int i = 0; i < 4; i++) {
        final angle = (i * 3.14 / 2);
        final x = sparkle.dx + 6 * (i % 2 == 0 ? 1 : 0.4) * cos(angle);
        final y = sparkle.dy + 6 * (i % 2 == 0 ? 1 : 0.4) * sin(angle);
        if (i == 0) {
          starPath.moveTo(x, y);
        } else {
          starPath.lineTo(x, y);
        }
      }
      starPath.close();
      canvas.drawPath(starPath, sparklePaint);
    }

    // Draw base shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFFD4A574).withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 20),
        width: 80,
        height: 15,
      ),
      shadowPaint,
    );
  }

  double cos(double angle) => angle == 0 ? 1 : (angle == 3.14 / 2 ? 0 : -1);
  double sin(double angle) => angle == 0 ? 0 : (angle == 3.14 / 2 ? 1 : 0);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
