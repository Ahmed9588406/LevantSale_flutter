import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';

/// A development utility widget to reset onboarding state
/// Add this button to any screen during development to test onboarding flow
class ResetOnboardingButton extends StatelessWidget {
  const ResetOnboardingButton({Key? key}) : super(key: key);

  Future<void> _resetOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_complete');
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إعادة تعيين الإعداد الأولي'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Navigate to onboarding screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _resetOnboarding(context),
      icon: const Icon(Icons.refresh),
      label: const Text('إعادة تعيين الإعداد الأولي'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }
}
