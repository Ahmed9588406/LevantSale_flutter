import 'package:flutter/material.dart';
import 'profile_service.dart';
import 'widgets/profile_ad_card.dart';
import '../category/product_details_screen.dart';
import '../verification/verification_status_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _profile;
  bool _loadingProfile = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _loadingProfile = true;
      _error = null;
    });
    final p = await ProfileService.fetchProfile();
    if (!mounted) return;
    setState(() {
      _profile = p;
      _loadingProfile = false;
      if (p == null) {
        _error = 'فشل تحميل الملف الشخصي';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('حسابي'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF1DAF52),
            labelColor: const Color(0xFF1DAF52),
            unselectedLabelColor: Colors.grey[600],
            tabs: const [
              Tab(text: 'إعلاناتي', icon: Icon(Icons.inventory_2_outlined)),
              Tab(
                text: 'حالة التوثيق',
                icon: Icon(Icons.verified_user_outlined),
              ),
              Tab(text: 'طلبات الترويج', icon: Icon(Icons.lightbulb_outline)),
            ],
          ),
        ),
        body: _loadingProfile
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
                      onPressed: _fetchProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DAF52),
                      ),
                      child: const Text('حاول مرة أخرى'),
                    ),
                  ],
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  AdsTab(profile: _profile!),
                  const VerificationStatusScreen(embedded: true),
                  FeatureRequestsTab(),
                ],
              ),
      ),
    );
  }
}

class AdsTab extends StatefulWidget {
  final Map<String, dynamic> profile;
  const AdsTab({Key? key, required this.profile}) : super(key: key);

  @override
  State<AdsTab> createState() => _AdsTabState();
}

class _AdsTabState extends State<AdsTab> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _listings = [];
  String _filter = 'current';

  @override
  void initState() {
    super.initState();
    _fetchAllAds();
  }

  Future<void> _fetchAllAds() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final statuses = ['PENDING', 'ACTIVE', 'REJECTED', 'EXPIRED', 'INACTIVE'];
      final List<Map<String, dynamic>> all = [];
      for (final s in statuses) {
        final list = await ProfileService.fetchUserListingsByStatus(s);
        all.addAll(list);
      }
      if (!mounted) return;
      setState(() {
        _listings = all;
      });
    } catch (e) {
      setState(() {
        _error = 'فشل تحميل الإعلانات';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _filtered() {
    switch (_filter) {
      case 'current':
        return _listings
            .where(
              (e) => (e['status'] ?? '').toString().toUpperCase() == 'ACTIVE',
            )
            .toList();
      case 'expired':
        return _listings.where((e) {
          final s = (e['status'] ?? '').toString().toUpperCase();
          return s == 'EXPIRED' || s == 'REJECTED' || s == 'INACTIVE';
        }).toList();
      case 'pending':
        return _listings
            .where(
              (e) => (e['status'] ?? '').toString().toUpperCase() == 'PENDING',
            )
            .toList();
      default:
        return _listings;
    }
  }

  Future<void> _deleteListing(String id) async {
    final ok = await ProfileService.deleteListing(id);
    if (ok) {
      await _fetchAllAds();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف الإعلان بنجاح')));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل حذف الإعلان')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1DAF52)),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchAllAds,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DAF52),
              ),
              child: const Text('حاول مرة أخرى'),
            ),
          ],
        ),
      );
    }

    final items = _filtered();

    return Column(
      children: [
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip('الإعلانات الحالية', 'current'),
              _chip('الإعلانات المنتهية', 'expired'),
              _chip('إعلانات تحت الإشراف', 'pending'),
              _chip('الكل', 'all'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('لا توجد إعلانات'))
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final e = items[i];
                    return ProfileAdCard(
                      listing: e,
                      onSellFaster: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateFeatureRequestScreen(
                              initialListingId: (e['id'] ?? '').toString(),
                            ),
                          ),
                        );
                      },
                      onDelete: () async {
                        await _deleteListing((e['id'] ?? '').toString());
                      },
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailsScreen(
                              listingId: (e['id'] ?? '').toString(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: const Color(0xFF1DAF52),
        labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }
}

class VerificationTab extends StatefulWidget {
  const VerificationTab({Key? key}) : super(key: key);

  @override
  State<VerificationTab> createState() => _VerificationTabState();
}

class _VerificationTabState extends State<VerificationTab> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _verification;

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
    final v = await ProfileService.fetchVerificationStatus();
    if (!mounted) return;
    setState(() {
      _verification = v;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1DAF52)),
      );
    }
    if (_error != null) {
      return Center(
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
    }
    if (_verification == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 8),
            const Text('لم يتم تقديم طلب توثيق'),
          ],
        ),
      );
    }
    final status = (_verification!['status'] ?? '').toString();
    final cfg = _statusCfg(status);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(cfg.icon, color: cfg.color),
              const SizedBox(width: 8),
              Text(
                cfg.label,
                style: TextStyle(
                  color: cfg.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('الاسم: ${_verification!['fullName'] ?? ''}'),
          Text('البريد الإلكتروني: ${_verification!['userEmail'] ?? ''}'),
          Text('رقم الهاتف: ${_verification!['phoneNumber'] ?? ''}'),
        ],
      ),
    );
  }

  _VerCfg _statusCfg(String s) {
    switch (s) {
      case 'APPROVED':
        return _VerCfg(
          'موافق عليه',
          const Color(0xFF1DAF52),
          Icons.check_circle_outline,
        );
      case 'REJECTED':
        return _VerCfg('مرفوض', const Color(0xFFD32F2F), Icons.cancel_outlined);
      case 'PENDING':
        return _VerCfg(
          'قيد المراجعة',
          const Color(0xFFF57F17),
          Icons.access_time,
        );
      default:
        return _VerCfg('غير معروف', Colors.grey, Icons.help_outline);
    }
  }
}

class _VerCfg {
  final String label;
  final Color color;
  final IconData icon;
  _VerCfg(this.label, this.color, this.icon);
}

class FeatureRequestsTab extends StatefulWidget {
  const FeatureRequestsTab({Key? key}) : super(key: key);

  @override
  State<FeatureRequestsTab> createState() => _FeatureRequestsTabState();
}

class _FeatureRequestsTabState extends State<FeatureRequestsTab> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _requests = [];

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
    final list = await ProfileService.fetchFeatureRequests();
    if (!mounted) return;
    setState(() {
      _requests = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1DAF52)),
      );
    }
    if (_error != null) {
      return Center(
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
    }
    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 8),
            const Text('لا توجد طلبات ترويج'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateFeatureRequestScreen(),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DAF52),
              ),
              child: const Text('طلب جديد'),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateFeatureRequestScreen(),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DAF52),
              ),
              child: const Text('طلب جديد'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: _requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final r = _requests[i];
              final status = (r['status'] ?? '').toString();
              final cfg = _reqCfg(status);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    r['listingTitle'] ??
                        'إعلان #${(r['listingId'] ?? '').toString()}',
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cfg.bg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              cfg.label,
                              style: TextStyle(color: cfg.fg, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(r['message'] ?? ''),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  _ReqCfg _reqCfg(String s) {
    switch (s) {
      case 'APPROVED':
        return _ReqCfg(
          'موافق عليه',
          const Color(0xFFE8F5E9),
          const Color(0xFF1DAF52),
        );
      case 'REJECTED':
        return _ReqCfg(
          'مرفوض',
          const Color(0xFFFFEBEE),
          const Color(0xFFD32F2F),
        );
      case 'PENDING':
      default:
        return _ReqCfg(
          'قيد المراجعة',
          const Color(0xFFFFF8E1),
          const Color(0xFFF57F17),
        );
    }
  }
}

class _ReqCfg {
  final String label;
  final Color bg;
  final Color fg;
  _ReqCfg(this.label, this.bg, this.fg);
}

class CreateFeatureRequestScreen extends StatefulWidget {
  final String? initialListingId;
  const CreateFeatureRequestScreen({Key? key, this.initialListingId})
    : super(key: key);

  @override
  State<CreateFeatureRequestScreen> createState() =>
      _CreateFeatureRequestScreenState();
}

class _CreateFeatureRequestScreenState
    extends State<CreateFeatureRequestScreen> {
  bool _loading = false;
  bool _submitting = false;
  List<Map<String, dynamic>> _userListings = [];
  String? _listingId;
  int _durationWeeks = 2;
  final TextEditingController _contactCtrl = TextEditingController();
  final TextEditingController _messageCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      final pending = await ProfileService.fetchUserListingsByStatus('PENDING');
      final active = await ProfileService.fetchUserListingsByStatus('ACTIVE');
      final all = [...pending, ...active];
      if (!mounted) return;
      setState(() {
        _userListings = all;
        _listingId =
            widget.initialListingId ??
            (all.isNotEmpty ? (all.first['id'] ?? '').toString() : null);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_listingId == null ||
        _contactCtrl.text.trim().isEmpty ||
        _messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى ملء جميع الحقول')));
      return;
    }
    setState(() => _submitting = true);
    final ok = await ProfileService.createFeatureRequest(
      listingId: _listingId!,
      durationWeeks: _durationWeeks,
      contactDetails: _contactCtrl.text.trim(),
      message: _messageCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلب الترويج بنجاح')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل إرسال طلب الترويج')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('طلب ترويج'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1DAF52)),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('اختر الإعلان'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _listingId,
                      items: [
                        ..._userListings.map(
                          (e) => DropdownMenuItem<String>(
                            value: (e['id'] ?? '').toString(),
                            child: Text(
                              (e['title'] ?? '').toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _listingId = v),
                    ),
                    const SizedBox(height: 16),
                    const Text('مدة الترويج (بالأسابيع)'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _durationWeeks,
                      items: const [1, 2, 3, 4]
                          .map(
                            (w) => DropdownMenuItem<int>(
                              value: w,
                              child: Text('$w'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _durationWeeks = v ?? 2),
                    ),
                    const SizedBox(height: 16),
                    const Text('رقم الاتصال'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _contactCtrl,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    const Text('رسالة إضافية'),
                    const SizedBox(height: 8),
                    TextField(controller: _messageCtrl, maxLines: 4),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1DAF52),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('إرسال الطلب'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
