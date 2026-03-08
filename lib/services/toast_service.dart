import 'package:flutter/material.dart';

/// Beautiful toast notifications for the app
class AppToast {
  /// Show a success toast with green styling
  static void showSuccess(BuildContext context, String message) {
    _showToast(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: const Color(0xFF1DAF52),
      iconColor: Colors.white,
      textColor: Colors.white,
    );
  }

  /// Show an error toast with red styling
  static void showError(BuildContext context, String message) {
    _showToast(
      context,
      message: message,
      icon: Icons.error_rounded,
      backgroundColor: const Color(0xFFE53935),
      iconColor: Colors.white,
      textColor: Colors.white,
    );
  }

  /// Show a warning toast with orange styling
  static void showWarning(BuildContext context, String message) {
    _showToast(
      context,
      message: message,
      icon: Icons.warning_rounded,
      backgroundColor: const Color(0xFFFFA726),
      iconColor: Colors.white,
      textColor: Colors.white,
    );
  }

  /// Show an info toast with blue styling
  static void showInfo(BuildContext context, String message) {
    _showToast(
      context,
      message: message,
      icon: Icons.info_rounded,
      backgroundColor: const Color(0xFF2196F3),
      iconColor: Colors.white,
      textColor: Colors.white,
    );
  }

  /// Show a favorite added toast with heart animation
  static void showFavoriteAdded(BuildContext context) {
    _showToast(
      context,
      message: 'تمت الإضافة إلى المفضلة',
      icon: Icons.favorite_rounded,
      backgroundColor: const Color(0xFFE91E63),
      iconColor: Colors.white,
      textColor: Colors.white,
    );
  }

  /// Show a favorite removed toast
  static void showFavoriteRemoved(BuildContext context) {
    _showToast(
      context,
      message: 'تمت الإزالة من المفضلة',
      icon: Icons.favorite_border_rounded,
      backgroundColor: const Color(0xFF757575),
      iconColor: Colors.white,
      textColor: Colors.white,
    );
  }

  /// Show login required toast
  static void showLoginRequired(BuildContext context) {
    _showToast(
      context,
      message: 'يجب تسجيل الدخول أولاً',
      icon: Icons.login_rounded,
      backgroundColor: const Color(0xFFFFA726),
      iconColor: Colors.white,
      textColor: Colors.white,
    );
  }

  /// Internal method to show the toast
  static void _showToast(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required Color textColor,
  }) {
    // Remove any existing snackbars
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final snackBar = SnackBar(
      content: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            // Animated icon container
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            // Message text
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: const Duration(seconds: 3),
      dismissDirection: DismissDirection.horizontal,
      elevation: 8,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

/// A beautiful animated heart button for favorites
class FavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onPressed;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showBackground;
  final Color? backgroundColor;

  const FavoriteButton({
    Key? key,
    required this.isFavorite,
    required this.onPressed,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
    this.showBackground = false,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite && widget.isFavorite) {
      _controller.forward(from: 0);
    }
  }

  void _handleTap() {
    if (!widget.isFavorite) {
      _controller.forward(from: 0);
    }
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? const Color(0xFFE91E63);
    final inactiveColor = widget.inactiveColor ?? Colors.white;

    Widget iconWidget = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            widget.isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: widget.isFavorite ? activeColor : inactiveColor,
            size: widget.size,
          ),
        );
      },
    );

    if (widget.showBackground) {
      iconWidget = Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: iconWidget,
      );
    }

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: iconWidget,
    );
  }
}

/// Loading overlay for favorite operations
class FavoriteLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const FavoriteLoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFE91E63),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
