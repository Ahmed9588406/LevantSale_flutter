import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../myAds/my_ads_screen.dart';
import '../../createAdd/step1.dart';
import '../../messages/messages_list_screen.dart';
import '../../profile/profile_screen.dart';
import '../../verification/verification_status_screen.dart';
import '../../verification/verification_step_one_screen.dart';
import '../../profile/profile_service.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  // Context-aware SVG loader: check asset existence and show fallback icon if missing.
  static Future<bool> _assetExists(
    BuildContext context,
    String assetPath,
  ) async {
    try {
      await DefaultAssetBundle.of(context).load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Widget _svgIcon(
    BuildContext context,
    String assetPath, {
    required Color color,
    double width = 26,
    double height = 26,
    IconData fallback = Icons.image_outlined,
  }) {
    // Use FutureBuilder to avoid throwing when asset file is missing.
    return FutureBuilder<bool>(
      future: _assetExists(context, assetPath),
      builder: (ctx, snapshot) {
        final icon = Icon(fallback, size: width, color: color);
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            width: width,
            height: height,
            child: Center(child: icon),
          );
        }
        if (snapshot.hasData && snapshot.data == true) {
          return SvgPicture.asset(
            assetPath,
            width: width,
            height: height,
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            placeholderBuilder: (context) => icon,
          );
        }
        return icon;
      },
    );
  }

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
                  icon: const Icon(Icons.verified_user_outlined),
                  label: 'توثيق',
                  index: 5,
                  onCustomTap: () {
                    () async {
                      final status =
                          await ProfileService.fetchVerificationStatus();
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
                    }();
                  },
                ),
              ),
              Flexible(
                child: _buildNavItem(
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
              const SizedBox(width: 60), // Space for center FAB
              Flexible(
                child: _buildNavItem(
                  icon: _svgIcon(
                    context,
                    'icons/message.svg',
                    color: currentIndex == 1
                        ? const Color(0xFF1DAF52)
                        : const Color(0xFF9E9E9E),
                    width: 22,
                    height: 22,
                    fallback: Icons.chat_bubble_outline,
                  ),
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
                  icon: _svgIcon(
                    context,
                    'icons/home.svg',
                    color: currentIndex == 0
                        ? const Color(0xFF1DAF52)
                        : const Color(0xFF9E9E9E),
                    width: 22,
                    height: 22,
                    fallback: Icons.home_outlined,
                  ),
                  label: 'الرئيسية',
                  index: 0,
                ),
              ),
            ],
          ),

          // Centered Floating Action Button with Glow
          Positioned(
            top: -28,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CarSellForm()),
                );
              },
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    // Outer glow - lightest
                    BoxShadow(
                      color: const Color(0xFF1DAF52).withOpacity(0.15),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                    // Middle glow
                    BoxShadow(
                      color: const Color(0xFF1DAF52).withOpacity(0.25),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                    // Inner glow - strongest
                    BoxShadow(
                      color: const Color(0xFF1DAF52).withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF5FB57C), Color(0xFF1DAF52)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 34),
                ),
              ),
            ),
          ),

          // Icon below FAB (uses icons/add.svg)
          Positioned(
            bottom: 6,
            child: SizedBox(
              width: 30,
              height: 30,
              child: _svgIcon(
                context,
                'icons/add.svg',
                color: currentIndex == 2
                    ? const Color(0xFF1DAF52)
                    : const Color(0xFF757575),
                width: 30,
                height: 30,
                fallback: Icons.add,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required Widget icon,
    required String label,
    required int index,
    VoidCallback? onCustomTap,
  }) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: onCustomTap ?? () => onTap(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use IconTheme so both Icon widgets and SvgPicture respect size/color
            IconTheme(
              data: IconThemeData(
                color: isSelected
                    ? const Color(0xFF1DAF52)
                    : const Color(0xFF9E9E9E),
                size: 22,
              ),
              child: icon,
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
  const ExampleScreen({Key? key}) : super(key: key);

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
