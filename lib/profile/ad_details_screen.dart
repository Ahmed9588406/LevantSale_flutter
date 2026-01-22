import 'package:flutter/material.dart';
import 'profile_service.dart';

class AdDetailsScreen extends StatefulWidget {
  final String listingId;
  const AdDetailsScreen({Key? key, required this.listingId}) : super(key: key);

  @override
  State<AdDetailsScreen> createState() => _AdDetailsScreenState();
}

class _AdDetailsScreenState extends State<AdDetailsScreen> {
  Map<String, dynamic>? _listing;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await ProfileService.fetchListingById(widget.listingId);
    if (!mounted) return;
    setState(() {
      _listing = res;
      _loading = false;
      if (res == null) _error = 'فشل تحميل تفاصيل الإعلان';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل الإعلان'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1DAF52)),
              )
            : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _fetch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DAF52),
                      ),
                      child: const Text('حاول مرة أخرى'),
                    ),
                  ],
                ),
              )
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final e = _listing!;
    final title = (e['title'] ?? '').toString();
    final description = (e['description'] ?? '').toString();
    final categoryName = (e['categoryName'] ?? '').toString();
    final price = e['price'];
    final currency = (e['currency'] ?? 'EGP').toString();
    final attrs = (e['attributes'] is List)
        ? (e['attributes'] as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    final imageUrls = (e['imageUrls'] is List)
        ? (e['imageUrls'] as List).cast<String>()
        : <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Images carousel (simple)
          SizedBox(
            height: 220,
            child: PageView.builder(
              itemCount: imageUrls.isEmpty ? 1 : imageUrls.length,
              itemBuilder: (ctx, i) {
                final raw = imageUrls.isEmpty ? '' : imageUrls[i];
                final url = raw.isEmpty
                    ? ''
                    : (raw.startsWith('http')
                          ? raw
                          : raw.startsWith('/uploads')
                          ? '${ProfileService.baseUrl}$raw'
                          : raw);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: url.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.image,
                            color: Colors.grey,
                            size: 64,
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(categoryName, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          if (price != null)
            Text(
              '${price.toString()} $currency',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1DAF52),
              ),
            ),
          const SizedBox(height: 16),
          if (description.isNotEmpty) ...[
            const Text('الوصف', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(description),
            const SizedBox(height: 16),
          ],
          if (attrs.isNotEmpty) ...[
            const Text(
              'الخصائص',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Column(
              children: attrs.map((a) {
                final name = (a['attributeName'] ?? '').toString();
                final vStr = (a['valueString'] ?? '').toString();
                final vNum = a['valueNumber']?.toString() ?? '';
                final vBool = a['valueBoolean'] == null
                    ? ''
                    : ((a['valueBoolean'] as bool) ? 'نعم' : 'لا');
                final value = vStr.isNotEmpty
                    ? vStr
                    : vNum.isNotEmpty
                    ? vNum
                    : vBool;
                return ListTile(
                  dense: true,
                  title: Text(name),
                  trailing: Text(value),
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
