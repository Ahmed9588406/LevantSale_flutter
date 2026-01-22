import 'package:flutter/material.dart';
import 'dart:io';
import 'image_picker_helper.dart';

/// Simple test screen to verify image picker is working
/// Use this if images still don't appear in the main screens
class DebugImageTestScreen extends StatefulWidget {
  const DebugImageTestScreen({Key? key}) : super(key: key);

  @override
  State<DebugImageTestScreen> createState() => _DebugImageTestScreenState();
}

class _DebugImageTestScreenState extends State<DebugImageTestScreen> {
  File? _testImage;

  Future<void> _pickTestImage() async {
    print('DEBUG: Starting image picker...');
    final image = await ImagePickerHelper.showImageSourceDialog(context);
    
    if (image != null) {
      print('DEBUG: Image selected: ${image.path}');
      print('DEBUG: Image exists: ${image.existsSync()}');
      print('DEBUG: Image size: ${image.lengthSync()} bytes');
      
      setState(() {
        _testImage = image;
      });
      
      print('DEBUG: State updated, _testImage is ${_testImage != null ? "not null" : "null"}');
    } else {
      print('DEBUG: No image selected');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building widget, _testImage is ${_testImage != null ? "not null" : "null"}');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Picker Test'),
        backgroundColor: const Color(0xFF1DAF52),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image display area
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _testImage != null 
                      ? const Color(0xFF1DAF52) 
                      : Colors.grey,
                  width: 2,
                ),
              ),
              child: _testImage == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No image selected',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _testImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('DEBUG: Error loading image: $error');
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error,
                                size: 80,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error: $error',
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
            ),
            
            const SizedBox(height: 32),
            
            // Pick image button
            ElevatedButton.icon(
              onPressed: _pickTestImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Pick Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DAF52),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Debug info
            if (_testImage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Path: ${_testImage!.path}'),
                    Text('Exists: ${_testImage!.existsSync()}'),
                    Text('Size: ${_testImage!.lengthSync()} bytes'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
