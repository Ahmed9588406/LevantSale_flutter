import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Show bottom sheet to choose between camera and gallery
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    final File? selectedImage = await showModalBottomSheet<File?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اختر مصدر الصورة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1DAF52).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Color(0xFF1DAF52),
                ),
              ),
              title: const Text(
                'التقاط صورة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () async {
                final image = await pickImageFromCamera(context);
                if (context.mounted) {
                  Navigator.pop(context, image);
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1DAF52).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF1DAF52),
                ),
              ),
              title: const Text(
                'اختيار من المعرض',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () async {
                final image = await pickImageFromGallery(context);
                if (context.mounted) {
                  Navigator.pop(context, image);
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    return selectedImage;
  }

  /// Request camera permission
  static Future<bool> _requestCameraPermission(BuildContext context) async {
    var status = await Permission.camera.status;
    
    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      status = await Permission.camera.request();
      if (status.isGranted) {
        return true;
      }
    }

    if (status.isPermanentlyDenied) {
      _showPermissionDialog(
        context,
        'إذن الكاميرا مطلوب',
        'يرجى منح إذن الكاميرا من إعدادات التطبيق لالتقاط الصور.',
      );
      return false;
    }

    return false;
  }

  /// Request storage/photos permission
  static Future<bool> _requestStoragePermission(BuildContext context) async {
    PermissionStatus status;

    // For Android 13+ (API 33+), use photos permission
    if (Platform.isAndroid) {
      status = await Permission.photos.status;
      if (!status.isGranted) {
        status = await Permission.photos.request();
      }
      
      // Fallback to storage for older Android versions
      if (!status.isGranted) {
        status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
      }
    } else {
      // iOS uses photos permission
      status = await Permission.photos.status;
      if (!status.isGranted) {
        status = await Permission.photos.request();
      }
    }

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      _showPermissionDialog(
        context,
        'إذن الوصول للصور مطلوب',
        'يرجى منح إذن الوصول للصور من إعدادات التطبيق لاختيار الصور.',
      );
      return false;
    }

    return false;
  }

  /// Show permission dialog with option to open settings
  static void _showPermissionDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF757575),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: Color(0xFF757575)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text(
              'فتح الإعدادات',
              style: TextStyle(
                color: Color(0xFF1DAF52),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pick image from camera
  static Future<File?> pickImageFromCamera(BuildContext context) async {
    try {
      // Request camera permission
      final hasPermission = await _requestCameraPermission(context);
      if (!hasPermission) {
        return null;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      _showErrorSnackBar(
        context,
        'فشل في فتح الكاميرا. تأكد من منح الأذونات اللازمة.',
      );
      return null;
    }
  }

  /// Pick image from gallery
  static Future<File?> pickImageFromGallery(BuildContext context) async {
    try {
      // Request storage/photos permission
      final hasPermission = await _requestStoragePermission(context);
      if (!hasPermission) {
        return null;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      _showErrorSnackBar(
        context,
        'فشل في فتح المعرض. تأكد من منح الأذونات اللازمة.',
      );
      return null;
    }
  }

  /// Show error message
  static void _showErrorSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}
