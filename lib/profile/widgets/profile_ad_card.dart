import 'package:flutter/material.dart';
import '../profile_service.dart';

class ProfileAdCard extends StatefulWidget {
  final Map<String, dynamic> listing;
  final VoidCallback? onDelete;
  final VoidCallback? onSellFaster;
  final VoidCallback? onTap;

  const ProfileAdCard({
    Key? key,
    required this.listing,
    this.onDelete,
    this.onSellFaster,
    this.onTap,
  }) : super(key: key);

  @override
  State<ProfileAdCard> createState() => _ProfileAdCardState();
}

class _ProfileAdCardState extends State<ProfileAdCard> {
  int _currentImageIndex = 0;

  List<String> get _imagesRaw {
    final imgs = widget.listing['imageUrls'];
    if (imgs is List) {
      return imgs.map((e) => e.toString()).toList();
    }
    return [];
  }

  List<String> get _images {
    final base = ProfileService.baseUrl;
    final list = _imagesRaw;
    return list.map((img) {
      if (img.isEmpty) return img;
      if (img.startsWith('http')) return img;
      if (img.startsWith('/uploads')) return '$base$img';
      return img.startsWith('/') ? '$base$img' : '$base/$img';
    }).toList();
  }

  String get _status =>
      (widget.listing['status'] ?? '').toString().toUpperCase();

  Color get _statusBg {
    switch (_status) {
      case 'ACTIVE':
        return const Color(0xFFE8F5E9);
      case 'PENDING':
        return const Color(0xFFFFF8E1);
      case 'EXPIRED':
      case 'REJECTED':
      case 'INACTIVE':
        return const Color(0xFFFFEBEE);
      default:
        return Colors.grey[200]!;
    }
  }

  Color get _statusFg {
    switch (_status) {
      case 'ACTIVE':
        return const Color(0xFF1DAF52);
      case 'PENDING':
        return const Color(0xFFF57F17);
      case 'EXPIRED':
      case 'REJECTED':
      case 'INACTIVE':
        return const Color(0xFFD32F2F);
      default:
        return Colors.grey[700]!;
    }
  }

  String get _statusLabel {
    switch (_status) {
      case 'ACTIVE':
        return 'نشط';
      case 'PENDING':
        return 'في إنتظار الرد';
      case 'EXPIRED':
        return 'منتهي';
      case 'REJECTED':
        return 'مرفوض';
      case 'INACTIVE':
        return 'غير نشط';
      default:
        return _status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.listing['title'] ?? '').toString();
    final categoryName = (widget.listing['categoryName'] ?? '').toString();
    final price = widget.listing['price'];
    final currency = (widget.listing['currency'] ?? 'EGP').toString();
    final expiryDate = DateTime.tryParse(
      (widget.listing['expiryDate'] ?? '').toString(),
    );
    final dateRange = (expiryDate != null)
        ? 'ينتهي في يوم ${_fmt(expiryDate)}'
        : '';
    final views =
        int.tryParse((widget.listing['viewCount'] ?? '0').toString()) ?? 0;
    final calls =
        int.tryParse((widget.listing['leadCount'] ?? '0').toString()) ?? 0;
    final imgs = _images;

    return InkWell(
      onTap: widget.onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imgs.isEmpty
                            ? const Center(
                                child: Icon(Icons.image, color: Colors.grey),
                              )
                            : Image.network(
                                imgs[_currentImageIndex],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.image_not_supported),
                                ),
                              ),
                      ),
                    ),
                    if (imgs.length > 1)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _navBtn(Icons.chevron_left, () {
                          setState(() {
                            _currentImageIndex =
                                (_currentImageIndex - 1 + imgs.length) %
                                imgs.length;
                          });
                        }),
                      ),
                    if (imgs.length > 1)
                      Align(
                        alignment: Alignment.centerRight,
                        child: _navBtn(Icons.chevron_right, () {
                          setState(() {
                            _currentImageIndex =
                                (_currentImageIndex + 1) % imgs.length;
                          });
                        }),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _statusLabel,
                            style: TextStyle(color: _statusFg, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        text: 'في ',
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                        children: [
                          TextSpan(
                            text: categoryName,
                            style: const TextStyle(
                              color: Color(0xFF1DAF52),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (dateRange.isNotEmpty)
                      Text(
                        dateRange,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.visibility,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${views.toString()} مشاهدات',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${calls.toString()} عميل محتمل',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (price != null)
                      Text(
                        '${price.toString()} $currency',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    _buildActions(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildActions() {
    switch (_status) {
      case 'ACTIVE':
      case 'PENDING':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onTap,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFBDBDBD)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  'تم البيع',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: widget.onSellFaster,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DAF52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                child: const Text('إعادة نشر', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        );
      case 'EXPIRED':
      case 'REJECTED':
      case 'INACTIVE':
      default:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onTap,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFBDBDBD)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  'تم البيع',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: widget.onSellFaster,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DAF52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                child: const Text('إعادة نشر', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        );
    }
  }

  String _fmt(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}
