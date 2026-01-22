import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onClose;

  const SuccessDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 42),
      child: Container(
        width: 291,
        height: 196,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
                height: 1.3,
              ),
            ),

            const SizedBox(height: 24),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF757575),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            // Success Icon with background decoration
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer light green circle
                  Positioned(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1DAF52).withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Middle light green circle
                  Positioned(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1DAF52).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Inner light green circle
                  Positioned(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1DAF52).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Main success icon
                  Positioned(
                    child: SvgPicture.asset(
                      'icons/Done.svg',
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                      placeholderBuilder: (context) => Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF1DAF52),
                            width: 3,
                          ),
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 24,
                          color: Color(0xFF1DAF52),
                        ),
                      ),
                    ),
                  ),
                  // Top right sparkle
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildSparkle(12),
                  ),
                  // Bottom left sparkle
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: _buildSparkle(12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSparkle(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vertical line
          Container(
            width: 2,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFF1DAF52),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          // Horizontal line
          Container(
            width: size,
            height: 2,
            decoration: BoxDecoration(
              color: const Color(0xFF1DAF52),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  /// Show success dialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onClose,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessDialog(
        title: title,
        message: message,
        onClose: onClose ?? () => Navigator.of(context).pop(),
      ),
    );

    // Auto close after 2.5 seconds
    await Future.delayed(const Duration(milliseconds: 2500));
    if (context.mounted) {
      Navigator.of(context).pop();
      if (onClose != null) {
        onClose();
      }
    }
  }
}
