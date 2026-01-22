import 'package:flutter/material.dart';
import '../../notifications/notifications_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  List<NotificationItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await NotificationsService.initialize();
      final items = await NotificationsService.fetchNotifications();
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _items = [];
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    final ok = await NotificationsService.markAllRead();
    if (ok) {
      setState(() {
        _items = _items
            .map(
              (e) => NotificationItem(
                id: e.id,
                title: e.title,
                body: e.body,
                createdAt: e.createdAt,
                read: true,
              ),
            )
            .toList();
      });
    }
  }

  Future<void> _deleteAll() async {
    final ok = await NotificationsService.deleteAll();
    if (ok) {
      setState(() {
        _items = [];
      });
    }
  }

  Future<void> _markRead(String id) async {
    // Optional: backend mark read if available
    try {
      await NotificationsService.markAllRead();
    } catch (_) {}
    setState(() {
      _items = _items
          .map(
            (e) => e.id == id
                ? NotificationItem(
                    id: e.id,
                    title: e.title,
                    body: e.body,
                    createdAt: e.createdAt,
                    read: true,
                  )
                : e,
          )
          .toList();
    });
  }

  Future<void> _deleteOne(String id) async {
    final ok = await NotificationsService.deleteById(id);
    if (ok) {
      setState(() {
        _items.removeWhere((e) => e.id == id);
      });
    }
  }

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
          actions: [
            IconButton(
              icon: const Icon(
                Icons.mark_email_read_outlined,
                color: Color(0xFF2B2B2A),
              ),
              onPressed: _items.isEmpty ? null : _markAllRead,
              tooltip: 'تحديد الكل كمقروء',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFF2B2B2A)),
              onPressed: _items.isEmpty ? null : _deleteAll,
              tooltip: 'حذف الكل',
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
            ? _buildEmpty()
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final n = _items[index];
                    return Dismissible(
                      key: ValueKey(n.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        color: const Color(0xFFE53935),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteOne(n.id),
                      child: InkWell(
                        onTap: () => _markRead(n.id),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEDEDED)),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: BoxDecoration(
                                  color: n.read
                                      ? Colors.transparent
                                      : const Color(0xFF1DAF52),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n.title.isEmpty ? 'إشعار' : n.title,
                                      style: const TextStyle(
                                        color: Color(0xFF2B2B2A),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (n.body.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        n.body,
                                        style: const TextStyle(
                                          color: Color(0xFF6B6B6B),
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Text(
                                      n.createdAt,
                                      style: const TextStyle(
                                        color: Color(0xFF9E9E9E),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: const Color(0xFFEDEDED)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 200,
                height: 220,
                child: Image.asset(
                  'icons/CTA buttons Ar.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return CustomPaint(painter: EmptyNotificationPainter());
                  },
                ),
              ),
              const SizedBox(height: 24),
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
