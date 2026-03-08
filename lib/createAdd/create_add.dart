/// Create Ad Module - Backend Integration
///
/// This module provides complete backend integration for creating and editing ads.
/// It mirrors the web app's postAd functionality.
///
/// Usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => const CreateAdScreen()),
/// );
/// ```
///
/// For editing an existing ad:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => CreateAdScreen(editingId: 'listing-id'),
///   ),
/// );
/// ```

export 'ad_form_model.dart';
export 'create_ad_screen.dart';
export 'create_ad_service.dart';
export 'step1_basic_info.dart';
export 'step2_location_condition.dart';
export 'step3_attributes.dart';

// Legacy exports are removed to avoid 'main' conflicts
// Use the new step widgets instead:
// - Step1BasicInfo (replaces step1.dart / CarSellForm)
// - Step2LocationCondition (replaces step2.dart / CarSellStep2)
// - Step3Attributes (replaces step3.dart / CarSellStep3)
