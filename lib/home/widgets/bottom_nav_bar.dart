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
                child: _buildNavItemWithMenu(
                  icon: const Icon(Icons.person_outline),
                  label: 'حسابي',
                  index: 4,
                  onMainTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                  menuItems: [
                    _MenuItem(
                      icon: Icons.verified_user_outlined,
                      label: 'توثيق',
                      onTap: () async {
                        final status = await ProfileService.fetchVerificationStatus();
                        if (!context.mounted) return;
                        if (status == null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VerificationStepOneScreen(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VerificationStatusScreen(),
                            ),
                          );
                        }
                      },
                    ),
                  ],
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

          // Centered Add Button
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

  Widget _buildNavItemWithMenu({
    Widget? icon,
    String? iconPath,
    IconData? fallbackIcon,
    required String label,
    required int index,
    required VoidCallback onMainTap,
    required List<_MenuItem> menuItems,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? const Color(0xFF1DAF52) : const Color(0xFF9E9E9E);

    return Builder(
      builder: (itemContext) {
        return InkWell(
          onTap: () async {
            final RenderBox button = itemContext.findRenderObject() as RenderBox;
            final RenderBox overlay = Overlay.of(itemContext).context.findRenderObject() as RenderBox;
            final Offset positionOffset = button.localToGlobal(Offset.zero, ancestor: overlay);

            // FIX: We increase the 'bottom' value to ensure the menu anchor is ABOVE the bar
            // and the top of the menu is allowed to grow towards the top of the screen.
            final RelativeRect position = RelativeRect.fromLTRB(
              positionOffset.dx, 
              positionOffset.dy - 110, // Approximate height of the menu upward
              overlay.size.width - positionOffset.dx - button.size.width,
              overlay.size.height - positionOffset.dy + 10, // Forces the menu UP
            );

            final int? selectedValue = await showMenu<int>(
              context: itemContext,
              position: position,
              elevation: 8,
              useRootNavigator: true, // Crucial so it isn't clipped by the nav bar container
              constraints: const BoxConstraints(minWidth: 150),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              items: [
                PopupMenuItem<int>(
                  value: -1,
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, color: Color(0xFF1DAF52)),
                        const SizedBox(width: 12),
                        const Text('حسابي', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                ...menuItems.asMap().entries.map((entry) {
                  return PopupMenuItem<int>(
                    value: entry.key,
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Row(
                        children: [
                          Icon(entry.value.icon, color: Colors.grey[600], size: 22),
                          const SizedBox(width: 12),
                          Text(entry.value.label, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );

            if (selectedValue == -1) {
              onMainTap();
            } else if (selectedValue != null) {
              menuItems[selectedValue].onTap();
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconTheme(
                    data: IconThemeData(color: color, size: 24),
                    child: icon ?? (iconPath != null 
                        ? SvgPicture.asset(iconPath, colorFilter: ColorFilter.mode(color, BlendMode.srcIn)) 
                        : Icon(fallbackIcon ?? Icons.image_outlined)),
                  ),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Icon(Icons.arrow_drop_up, size: 18, color: color),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }
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
    final color = isSelected ? const Color(0xFF1DAF52) : const Color(0xFF9E9E9E);

    return InkWell(
      onTap: onCustomTap ?? () => onTap(index),
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconTheme(
            data: IconThemeData(color: color, size: 24),
            child: icon ?? (iconPath != null 
                ? SvgPicture.asset(iconPath, colorFilter: ColorFilter.mode(color, BlendMode.srcIn)) 
                : Icon(fallbackIcon ?? Icons.image_outlined)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _MenuItem({required this.icon, required this.label, required this.onTap});
}