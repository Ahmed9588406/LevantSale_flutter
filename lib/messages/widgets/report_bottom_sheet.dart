import 'package:flutter/material.dart';
import '../chat_service.dart';

class ReportBottomSheet extends StatefulWidget {
  final String userName;
  final String? userId;
  final String? listingId;

  const ReportBottomSheet({
    Key? key,
    required this.userName,
    this.userId,
    this.listingId,
  }) : super(key: key);

  @override
  State<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<ReportBottomSheet> {
  String? selectedReason;
  final TextEditingController _commentController = TextEditingController();
  bool blockUser = false;

  final List<String> reportReasons = [
    'الاحتيال',
    'صورة الحساب الشخصي غير مناسبة',
    'هذا المستخدم يهددني',
    'هذا المستخدم يسيء لي',
    'تعليق',
    'تعليق',
    'تعليق',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'تقرير المستخدم',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Report reasons
                  ...reportReasons.map((reason) => _buildReasonOption(reason)),

                  const SizedBox(height: 20),

                  // Comment field
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _commentController,
                      maxLines: 4,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        hintText: 'تعليق',
                        hintStyle: TextStyle(
                          color: Color(0xFFBDBDBD),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Block user checkbox
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        blockUser = !blockUser;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'أريد حظر المستخدم',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: blockUser
                                ? const Color(0xFFD4A017)
                                : Colors.white,
                            border: Border.all(
                              color: blockUser
                                  ? const Color(0xFFD4A017)
                                  : const Color(0xFFE0E0E0),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: blockUser
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit button
                  ElevatedButton(
                    onPressed: _submitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A017),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'إرسال شكوى',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonOption(String reason) {
    final isSelected = selectedReason == reason;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedReason = reason;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              reason,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(width: 12),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFE0E0E0),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  bool _submitting = false;

  Future<void> _submitReport() async {
    if (selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار سبب التقرير'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.userId == null) {
      Navigator.pop(context);
      return;
    }

    setState(() => _submitting = true);

    try {
      final success = await ChatService.reportUser(
        userId: widget.userId!,
        reason: selectedReason!,
        comment: _commentController.text.isNotEmpty
            ? _commentController.text
            : null,
        listingId: widget.listingId,
        blockUser: blockUser,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'تم إرسال التقرير بنجاح' : 'فشل إرسال التقرير',
            ),
            backgroundColor: success ? const Color(0xFF4CAF50) : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
