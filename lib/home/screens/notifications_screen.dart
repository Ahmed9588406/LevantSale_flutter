import 'package:flutter/material.dart';
import '../../notifications/notifications_service.dart';
import 'notification_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  List<NotificationItem> _items = [];
  Map<String, List<NotificationItem>> _groupedNotifications = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await NotificationsService.initialize();
      final items = await NotificationsService.fetchNotifications();
      if (mounted) {
        setState(() {
          _items = items;
          _groupedNotifications = _groupNotifications(items);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _items = [];
          _groupedNotifications = {};
          _loading = false;
        });
      }
    }
  }

  Map<String, List<NotificationItem>> _groupNotifications(
    List<NotificationItem> items,
  ) {
    final Map<String, List<NotificationItem>> grouped = {
      'جديد': [],
      'أمس': [],
      'سابقاً': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var item in items) {
      try {
        final date = DateTime.parse(item.createdAt);
        final itemDate = DateTime(date.year, date.month, date.day);

        if (itemDate.isAtSameMomentAs(today)) {
          grouped['جديد']!.add(item);
        } else if (itemDate.isAtSameMomentAs(yesterday)) {
          grouped['أمس']!.add(item);
        } else {
          grouped['سابقاً']!.add(item);
        }
      } catch (e) {
        grouped['سابقاً']!.add(item);
      }
    }

    // Remove empty groups
    grouped.removeWhere((key, value) => value.isEmpty);
    return grouped;
  }

  Future<void> _markAllRead() async {
    final confirmed = await _showConfirmDialog(
      'تحديد الكل كمقروء',
      'هل تريد تحديد جميع الإشعارات كمقروءة؟',
    );

    if (confirmed != true) return;

    final ok = await NotificationsService.markAllRead();
    if (ok && mounted) {
      setState(() {
        _items = _items
            .map(
              (e) => NotificationItem(
                id: e.id,
                title: e.title,
                body: e.body,
                createdAt: e.createdAt,
                read: true,
                imageUrl: e.imageUrl,
              ),
            )
            .toList();
        _groupedNotifications = _groupNotifications(_items);
      });
      _showSnackBar('تم تحديد جميع الإشعارات كمقروءة', isSuccess: true);
    } else if (mounted) {
      _showSnackBar('فشل تحديد الإشعارات كمقروءة', isSuccess: false);
    }
  }

  Future<void> _deleteAll() async {
    final confirmed = await _showConfirmDialog(
      'حذف جميع الإشعارات',
      'هل أنت متأكد من حذف جميع الإشعارات؟ لا يمكن التراجع عن هذا الإجراء.',
    );

    if (confirmed != true) return;

    final ok = await NotificationsService.deleteAll();
    if (ok && mounted) {
      setState(() {
        _items = [];
        _groupedNotifications = {};
      });
      _showSnackBar('تم حذف جميع الإشعارات', isSuccess: true);
    } else if (mounted) {
      _showSnackBar('فشل حذف الإشعارات', isSuccess: false);
    }
  }

  Future<void> _markRead(String id) async {
    final ok = await NotificationsService.markRead(id);
    if (ok && mounted) {
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
                      imageUrl: e.imageUrl,
                    )
                  : e,
            )
            .toList();
        _groupedNotifications = _groupNotifications(_items);
      });
    }
  }

  Future<void> _deleteOne(String id) async {
    final confirmed = await _showConfirmDialog(
      'حذف الإشعار',
      'هل أنت متأكد من حذف هذا الإشعار؟',
    );

    if (confirmed != true) return;

    final ok = await NotificationsService.deleteById(id);
    if (ok && mounted) {
      setState(() {
        _items.removeWhere((e) => e.id == id);
        _groupedNotifications = _groupNotifications(_items);
      });
      _showSnackBar('تم حذف الإشعار', isSuccess: true);
    } else if (mounted) {
      _showSnackBar('فشل حذف الإشعار', isSuccess: false);
    }
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
        backgroundColor: isSuccess
            ? const Color(0xFF1DAF52)
            : const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B2B2A),
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: Color(0xFF6B6B6B)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4A574),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('تأكيد', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'الإشعارات',
            style: TextStyle(
              color: Color(0xFF2B2B2A),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2B2B2A)),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_items.isNotEmpty)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Color(0xFF2B2B2A)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'mark_all') {
                    _markAllRead();
                  } else if (value == 'delete_all') {
                    _deleteAll();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'mark_all',
                    child: Row(
                      children: [
                        Icon(
                          Icons.done_all,
                          size: 20,
                          color: Color(0xFF1DAF52),
                        ),
                        SizedBox(width: 12),
                        Text('تحديد الكل كمقروء'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete_all',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Color(0xFFE53935),
                        ),
                        SizedBox(width: 12),
                        Text('حذف الكل'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4A574)),
                ),
              )
            : _items.isEmpty
            ? _buildEmpty()
            : RefreshIndicator(
                onRefresh: _load,
                color: const Color(0xFFD4A574),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _groupedNotifications.length,
                  itemBuilder: (context, index) {
                    final section = _groupedNotifications.keys.elementAt(index);
                    final notifications = _groupedNotifications[section]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: const Color(0xFFF5F5F5),
                          child: Text(
                            section,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2B2B2A),
                            ),
                          ),
                        ),

                        // Notifications in this section
                        ...notifications.map(
                          (notification) =>
                              _buildNotificationCard(notification),
                        ),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return InkWell(
      onTap: () {
        // Navigate to detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NotificationDetailScreen(
              notification: notification,
              onMarkRead: () => _markRead(notification.id),
              onDelete: () {
                _deleteOne(notification.id);
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unread indicator (far left in RTL)
            if (!notification.read)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 6, left: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF0066CC),
                  shape: BoxShape.circle,
                ),
              ),

            // Notification content (on the left in RTL)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    notification.title.isEmpty ? 'إشعار' : notification.title,
                    style: TextStyle(
                      color: const Color(0xFF2B2B2A),
                      fontSize: 16,
                      fontWeight: notification.read
                          ? FontWeight.w600
                          : FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Body
                  if (notification.body.isNotEmpty)
                    Text(
                      notification.body,
                      style: const TextStyle(
                        color: Color(0xFF6B6B6B),
                        fontSize: 14,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Notification image (on the right in RTL)
            Container(
              width: 100,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  notification.imageUrl != null &&
                      notification.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        notification.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildDefaultNotificationIcon(),
                      ),
                    )
                  : _buildDefaultNotificationIcon(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultNotificationIcon() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          Icons.notifications_outlined,
          size: 40,
          color: Colors.pink[200],
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
            color: Colors.white,
            border: Border.all(color: const Color(0xFFEDEDED)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 200,
                height: 220,
                child: CustomPaint(painter: EmptyNotificationPainter()),
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
              const SizedBox(height: 8),
              Text(
                'سيتم عرض الإشعارات الجديدة هنا',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
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
