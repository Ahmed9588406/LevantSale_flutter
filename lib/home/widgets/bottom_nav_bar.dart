import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../myAds/my_ads_screen.dart';
import '../../createAdd/create_ad_screen.dart';
import '../../messages/messages_list_screen.dart';
import '../../profile/profile_screen.dart';
import '../../verification/verification_status_screen.dart';
import '../../verification/verification_step_one_screen.dart';
import '../../profile/profile_service.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Bottom Nav Items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: _buildNavItem(
                  context: context,
                  icon: const Icon(Icons.verified_user_outlined),
                  label: 'توثيق',
                  index: 5,
                  onCustomTap: () async {
                    final status =
                        await ProfileService.fetchVerificationStatus();
                    if (!context.mounted) return;
                    if (status == null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const VerificationStepOneScreen(),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const VerificationStatusScreen(),
                        ),
                      );
                    }
                  },
                ),
              ),
              Flexible(
                child: _buildNavItem(
                  context: context,
                  icon: const Icon(Icons.person_outline),
                  label: 'حسابي',
                  index: 4,
                  onCustomTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
              ),
              Flexible(
                child: _buildNavItem(
                  context: context,
                  icon: const Icon(Icons.view_headline),
                  label: 'إعلاناتي',
                  index: 3,
                  onCustomTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyAdsScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 70), // Space for center FAB
              Flexible(
                child: _buildNavItem(
                  context: context,
                  iconPath: 'icons/message.svg',
                  fallbackIcon: Icons.chat_bubble_outline,
                  label: 'رسائل',
                  index: 1,
                  onCustomTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MessagesListScreen(),
                      ),
                    );
                  },
                ),
              ),
              Flexible(
                child: _buildNavItem(
                  context: context,
                  iconPath: 'icons/home.svg',
                  fallbackIcon: Icons.home_outlined,
                  label: 'الرئيسية',
                  index: 0,
                ),
              ),
            ],
          ),

          // Centered Add Button - Larger SVG Icon
          Positioned(
            top: -35,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateAdScreen(),
                  ),
                );
              },
              child: SizedBox(
                width: 100,
                height: 100,
                child: SvgPicture.asset(
                  'icons/add.svg',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                  placeholderBuilder: (context) => const Icon(
                    Icons.add_circle,
                    size: 100,
                    color: Color(0xFF1DAF52),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    Widget? icon,
    String? iconPath,
    IconData? fallbackIcon,
    required String label,
    required int index,
    VoidCallback? onCustomTap,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected
        ? const Color(0xFF1DAF52)
        : const Color(0xFF9E9E9E);

    Widget displayIcon;
    if (icon != null) {
      displayIcon = icon;
    } else if (iconPath != null) {
      displayIcon = SvgPicture.asset(
        iconPath,
        width: 22,
        height: 22,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        placeholderBuilder: (context) =>
            Icon(fallbackIcon ?? Icons.image_outlined, size: 22, color: color),
      );
    } else {
      displayIcon = Icon(
        fallbackIcon ?? Icons.image_outlined,
        size: 22,
        color: color,
      );
    }

    return InkWell(
      onTap: onCustomTap ?? () => onTap(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: IconThemeData(color: color, size: 22),
              child: displayIcon,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF1DAF52)
                    : const Color(0xFF757575),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Example usage in a Scaffold:
class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Current Index: $_currentIndex')),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
