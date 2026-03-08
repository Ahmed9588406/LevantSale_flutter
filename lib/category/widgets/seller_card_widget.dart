import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../messages/chat_screen.dart';
import '../../messages/chat_service.dart';
import '../../messages/models/message_model.dart';
import '../../messages/models/chat_models.dart';
import '../../services/toast_service.dart';
import '../../api/home/home_service.dart';
import '../../api/auth/auth_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SellerCardWidget extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final String? sellerAvatar;
  final String? memberSince;
  final String? sellerPhone;
  final String? listingId;
  final String? listingTitle;
  final String? listingPrice;
  final String? listingCurrency;
  final String? listingImageUrl;

  const SellerCardWidget({
    Key? key,
    required this.sellerId,
    required this.sellerName,
    this.sellerAvatar,
    this.memberSince,
    this.sellerPhone,
    this.listingId,
    this.listingTitle,
    this.listingPrice,
    this.listingCurrency,
    this.listingImageUrl,
  }) : super(key: key);

  @override
  State<SellerCardWidget> createState() => _SellerCardWidgetState();
}

class _SellerCardWidgetState extends State<SellerCardWidget> {
  bool _isVerified = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchSellerVerificationStatus();
  }

  Future<void> _fetchSellerVerificationStatus() async {
    if (widget.sellerId.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    try {
      // Fetch user details from API to get verification status
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final headers = <String, String>{
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'User-Agent': 'PostmanRuntime/7.32.2',
      };

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = token.startsWith('Bearer')
            ? token
            : 'Bearer $token';
      }

      final url = Uri.parse(
        '${AuthConfig.baseUrl}/api/v1/users/${widget.sellerId}',
      );
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _isVerified =
              userData['verified'] == true || userData['isVerified'] == true;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      print('Error fetching seller verification status: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'معلومات البائع',
            style: TextStyle(
              color: Color(0xFF2B2B2A),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          // Seller Info Row
          Row(
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1DAF52), width: 2),
                ),
                child: ClipOval(
                  child:
                      widget.sellerAvatar != null &&
                          widget.sellerAvatar!.isNotEmpty
                      ? Image.network(
                          widget.sellerAvatar!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildAvatarPlaceholder();
                          },
                        )
                      : _buildAvatarPlaceholder(),
                ),
              ),
              const SizedBox(width: 16),

              // Seller Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      widget.sellerName,
                      style: const TextStyle(
                        color: Color(0xFF2B2B2A),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Verified Badge
                    if (_isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F4FD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'بائع موثق',
                              style: TextStyle(
                                color: Color(0xFF007BFF),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Image.asset(
                              'assets/verified.png',
                              width: 16,
                              height: 16,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.verified,
                                  color: Color(0xFF007BFF),
                                  size: 16,
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                    // Member Since
                    if (widget.memberSince != null &&
                        widget.memberSince!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'عضو منذ ${widget.memberSince}',
                        style: const TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              // WhatsApp Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleWhatsApp(context),
                  icon: const Icon(
                    Icons.chat,
                    color: Color(0xFF1DAF52),
                    size: 18,
                  ),
                  label: const Text(
                    'واتساب',
                    style: TextStyle(
                      color: Color(0xFF1DAF52),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8F5E9),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Chat Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleChat(context),
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFFFFB800),
                    size: 18,
                  ),
                  label: const Text(
                    'محادثة',
                    style: TextStyle(
                      color: Color(0xFFFFB800),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF8E1),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Phone Call Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handlePhoneCall(context),
              icon: const Icon(
                Icons.phone_outlined,
                color: Color(0xFFAB47BC),
                size: 18,
              ),
              label: const Text(
                'مكالمة',
                style: TextStyle(
                  color: Color(0xFFAB47BC),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF3E5F5),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Divider
          const Divider(color: Color(0xFFE0E0E0), height: 1),

          const SizedBox(height: 16),

          // Report Button
          TextButton.icon(
            onPressed: () => _handleReport(context),
            icon: const Icon(
              Icons.flag_outlined,
              color: Color(0xFF9E9E9E),
              size: 18,
            ),
            label: const Text(
              'إبلاغ عن هذا الإعلان',
              style: TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: const Color(0xFFE8F5E9),
      child: Center(
        child: Text(
          widget.sellerName.isNotEmpty
              ? widget.sellerName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: Color(0xFF1DAF52),
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _handleWhatsApp(BuildContext context) async {
    String? phone = widget.sellerPhone;

    // If phone is not available, try to fetch it
    if (phone == null || phone.isEmpty) {
      if (widget.listingId != null) {
        try {
          final listing = await HomeService.fetchListingById(widget.listingId!);
          phone = listing.userPhone;
        } catch (e) {
          print('Error fetching phone from listing: $e');
        }
      }
    }

    if (phone == null || phone.isEmpty) {
      AppToast.showError(context, 'رقم الهاتف غير متوفر');
      return;
    }

    // Clean phone number
    String cleanPhone = phone.replaceAll(RegExp(r'[\s\-()]'), '');
    if (cleanPhone.startsWith('00')) {
      cleanPhone = '+${cleanPhone.substring(2)}';
    }
    cleanPhone = cleanPhone.replaceAll('+', '');

    final whatsappUrl = 'https://wa.me/$cleanPhone';

    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          AppToast.showError(context, 'لا يمكن فتح واتساب');
        }
      }
    } catch (e) {
      print('Error launching WhatsApp: $e');
      if (context.mounted) {
        AppToast.showError(context, 'حدث خطأ أثناء فتح واتساب');
      }
    }
  }

  Future<void> _handleChat(BuildContext context) async {
    // Check if user is logged in
    final currentUserId = await ChatService.getCurrentUserId();
    if (currentUserId == null) {
      if (context.mounted) {
        AppToast.showLoginRequired(context);
      }
      return;
    }

    // Check if trying to chat with yourself
    if (widget.sellerId == currentUserId) {
      if (context.mounted) {
        AppToast.showError(context, 'لا يمكنك محادثة نفسك');
      }
      return;
    }

    // Show loading
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1DAF52)),
        ),
      );
    }

    try {
      // Get or create conversation
      final conversationApi = await ChatService.getOrCreateConversation(
        widget.sellerId,
      );

      if (conversationApi == null) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading
          AppToast.showError(context, 'فشل في إنشاء المحادثة');
        }
        return;
      }

      final conversation = ChatConversation.fromApi(conversationApi);

      // Create ad data if available
      ChatAdData? adData;
      if (widget.listingId != null &&
          widget.listingTitle != null &&
          widget.listingPrice != null) {
        adData = ChatAdData(
          id: widget.listingId,
          title: widget.listingTitle,
          price: widget.listingPrice,
          currency: widget.listingCurrency ?? '',
          imageUrl: widget.listingImageUrl,
        );
      }

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChatScreen(conversation: conversation, adData: adData),
          ),
        );
      }
    } catch (e) {
      print('Error opening chat: $e');
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        AppToast.showError(context, 'حدث خطأ أثناء فتح المحادثة');
      }
    }
  }

  Future<void> _handlePhoneCall(BuildContext context) async {
    String? phone = widget.sellerPhone;

    // If phone is not available, try to fetch it
    if (phone == null || phone.isEmpty) {
      if (widget.listingId != null) {
        try {
          final listing = await HomeService.fetchListingById(widget.listingId!);
          phone = listing.userPhone;
        } catch (e) {
          print('Error fetching phone from listing: $e');
        }
      }
    }

    if (phone == null || phone.isEmpty) {
      if (context.mounted) {
        AppToast.showError(context, 'رقم الهاتف غير متوفر');
      }
      return;
    }

    // Show phone in a dialog
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'رقم الهاتف',
                    style: TextStyle(
                      color: Color(0xFF1DAF52),
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    phone!,
                    style: const TextStyle(
                      color: Color(0xFF2B2B2A),
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            final telUrl = 'tel:$phone';
                            try {
                              final uri = Uri.parse(telUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            } catch (e) {
                              print('Error launching phone: $e');
                            }
                          },
                          icon: const Icon(
                            Icons.phone,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            'اتصال',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1DAF52),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFF1DAF52)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'إغلاق',
                            style: TextStyle(
                              color: Color(0xFF1DAF52),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  void _handleReport(BuildContext context) {
    // Show report dialog
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إبلاغ عن هذا الإعلان',
                  style: TextStyle(
                    color: Color(0xFF2B2B2A),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'يرجى اختيار سبب الإبلاغ:',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 14),
                ),
                const SizedBox(height: 16),
                _buildReportOption(dialogContext, 'محتوى غير لائق'),
                _buildReportOption(dialogContext, 'احتيال أو نصب'),
                _buildReportOption(dialogContext, 'معلومات خاطئة'),
                _buildReportOption(dialogContext, 'سبب آخر'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportOption(BuildContext context, String reason) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال البلاغ بنجاح'),
            backgroundColor: Color(0xFF1DAF52),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.flag_outlined, color: Color(0xFF666666), size: 20),
            const SizedBox(width: 12),
            Text(
              reason,
              style: const TextStyle(
                color: Color(0xFF2B2B2A),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
