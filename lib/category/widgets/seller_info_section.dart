import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/auth/auth_config.dart';

class SellerInfoSection extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final String? sellerAvatar;
  final String? memberSince;

  const SellerInfoSection({
    super.key,
    required this.sellerId,
    required this.sellerName,
    this.sellerAvatar,
    this.memberSince,
  });

  @override
  State<SellerInfoSection> createState() => _SellerInfoSectionState();
}

class _SellerInfoSectionState extends State<SellerInfoSection> {
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
        if (mounted) {
          setState(() {
            _isVerified =
                userData['verified'] == true ||
                userData['isVerified'] == true ||
                userData['verificationStatus'] == 'APPROVED';
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          
          const SizedBox(height: 16),

          // Seller Info Row
          Row(
            children: [
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1DAF52), width: 3),
                ),
                child: ClipOval(
                  child:
                      widget.sellerAvatar != null &&
                          widget.sellerAvatar!.isNotEmpty
                      ? Image.network(
                          widget.sellerAvatar!,
                          width: 80,
                          height: 80,
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
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Verified Badge
                    if (_isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F4FD),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/done.png',
                              width: 18,
                              height: 18,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.verified,
                                  color: Color(0xFF007BFF),
                                  size: 18,
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'مستخدم موثق',
                              style: TextStyle(
                                color: Color(0xFF007BFF),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Member Since
                    if (widget.memberSince != null &&
                        widget.memberSince!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Member since ${widget.memberSince}',
                        style: const TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // See Profile Link
                    
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: const Color(0xFFE8F5E9),
      child: Center(
        child: Text(
          widget.sellerName.isNotEmpty
              ? widget.sellerName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: Color(0xFF1DAF52),
            fontSize: 36,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
