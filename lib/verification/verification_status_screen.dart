import 'package:flutter/material.dart';
import '../profile/profile_service.dart';
import 'verification_step_one_screen.dart';

class VerificationStatusScreen extends StatefulWidget {
  final bool embedded;
  const VerificationStatusScreen({Key? key, this.embedded = false})
    : super(key: key);
  @override
  State<VerificationStatusScreen> createState() =>
      _VerificationStatusScreenState();
}

class _VerificationStatusScreenState extends State<VerificationStatusScreen> {
  Map<String, dynamic>? _data;
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
    try {
      final res = await ProfileService.fetchVerificationStatus();
      setState(() {
        _data = res;
      });
    } catch (_) {
      setState(() => _error = 'تعذر تحميل حالة التوثيق');
    } finally {
      setState(() => _loading = false);
    }
  }

  String _resolveUrl(String? url) {
    final u = url ?? '';
    if (u.isEmpty) return '';
    if (u.startsWith('http')) return u;
    if (u.startsWith('/')) return '${ProfileService.baseUrl}$u';
    return u;
  }

  Map<String, dynamic> _statusConfig(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'APPROVED':
        return {
          'label': 'موافق عليه',
          'bg': const Color(0xFFE8F5E9),
          'fg': const Color(0xFF1DAF52),
          'border': const Color(0xFFC8E6C9),
        };
      case 'REJECTED':
        return {
          'label': 'مرفوض',
          'bg': const Color(0xFFFFEBEE),
          'fg': const Color(0xFFD32F2F),
          'border': const Color(0xFFEF9A9A),
        };
      case 'PENDING':
        return {
          'label': 'قيد المراجعة',
          'bg': const Color(0xFFFFF8E1),
          'fg': const Color(0xFFF57F17),
          'border': const Color(0xFFFFE082),
        };
      default:
        return {
          'label': 'غير معروف',
          'bg': const Color(0xFFF5F5F5),
          'fg': const Color(0xFF616161),
          'border': const Color(0xFFE0E0E0),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = _loading
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFF1DAF52)),
          )
        : _error != null
        ? _buildError()
        : (_data == null ? _buildEmpty() : _buildContent());

    if (widget.embedded) {
      return Directionality(textDirection: TextDirection.rtl, child: body);
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('حالة التوثيق'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: body,
      ),
    );
  }

  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
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
  );

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: Color(0xFF9E9E9E),
            size: 72,
          ),
          const SizedBox(height: 12),
          const Text(
            'لم يتم تقديم طلب توثيق',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'لم تقم بتقديم طلب توثيق حسابك بعد. قم بتوثيق حسابك للحصول على مزايا إضافية.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF757575)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VerificationStepOneScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1DAF52),
            ),
            child: const Text('ابدأ عملية التوثيق'),
          ),
        ],
      ),
    ),
  );

  Widget _buildContent() {
    final d = _data!;
    final cfg = _statusConfig(d['status']?.toString());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user, color: Color(0xFF1DAF52)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'حالة التوثيق',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'معلومات طلب التوثيق الخاص بك',
                        style: TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cfg['bg'] as Color,
                    border: Border.all(color: cfg['border'] as Color),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    cfg['label'] as String,
                    style: TextStyle(
                      color: cfg['fg'] as Color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section('المعلومات الشخصية', [
            _infoTile('الاسم الكامل', d['fullName']?.toString() ?? ''),
            _infoTile('البريد الإلكتروني', d['userEmail']?.toString() ?? ''),
            _infoTile('رقم الهاتف', d['phoneNumber']?.toString() ?? ''),
            _infoTile(
              'الجنس',
              (d['gender']?.toString() == 'MALE') ? 'ذكر' : 'أنثى',
            ),
          ]),
          if ((d['aboutYou']?.toString().isNotEmpty ?? false)) ...[
            const SizedBox(height: 16),
            _section('نبذة عنك', [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(d['aboutYou'].toString()),
              ),
            ]),
          ],
          const SizedBox(height: 16),
          _section('المستندات المرفوعة', [
            _docTile(
              'البطاقة الشخصية (الأمام)',
              _resolveUrl(d['nationalIdFrontUrl']?.toString()),
            ),
            _docTile(
              'البطاقة الشخصية (الخلف)',
              _resolveUrl(d['nationalIdBackUrl']?.toString()),
            ),
            _docTile('صورة الوجه', _resolveUrl(d['facePhotoUrl']?.toString())),
          ]),
          if ((d['status']?.toString() == 'REJECTED') &&
              (d['rejectionReason'] != null)) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                border: Border.all(color: const Color(0xFFEF9A9A)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'سبب الرفض',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB71C1C),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'تفاصيل الرفض متاحة في حسابك',
                    style: TextStyle(color: Color(0xFFD32F2F)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _section('التسلسل الزمني', [
            _timelineRow('تم التقديم في', d['submittedAt']?.toString()),
            if (d['reviewedAt'] != null)
              _timelineRow('تمت المراجعة في', d['reviewedAt']?.toString()),
            if (d['reviewedByName'] != null)
              _timelineRow(
                'تمت المراجعة بواسطة',
                d['reviewedByName']?.toString(),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE0E0E0)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );

  Widget _infoTile(String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF424242))),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: const TextStyle(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  Widget _docTile(String label, String url) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE0E0E0)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF616161), fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: url.isEmpty
              ? const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    color: Color(0xFF9E9E9E),
                  ),
                )
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Center(child: Icon(Icons.image_not_supported)),
                ),
        ),
      ],
    ),
  );

  Widget _timelineRow(String label, String? value) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        const Icon(Icons.circle, size: 8, color: Color(0xFF1DAF52)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: ${value ?? '-'}',
            style: const TextStyle(color: Color(0xFF616161)),
          ),
        ),
      ],
    ),
  );
}
