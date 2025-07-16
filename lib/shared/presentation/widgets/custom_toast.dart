import 'package:flutter/material.dart';

class CustomToast {
  static void show(
    BuildContext context, {
    required String message,
    required bool isSuccess,
    Duration duration = const Duration(seconds: 3),
  }) {
    final Color kPrimary = Color(0xFFFF6B9D);
    final Color kSecondary = Color(0xFFFF8E9B);
    final Color kTertiary = Color(0xFFFFA8A8);

    OverlayEntry? overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: AnimatedSnackbar(
            message: message,
            isSuccess: isSuccess,
            kPrimary: kPrimary,
            kSecondary: kSecondary,
            kTertiary: kTertiary,
            onDismiss: () {
              // overlayEntry?.remove();
            },
          ),
        ),
      ),
    );

    OverlayState? overlayState = Navigator.of(context, rootNavigator: true).overlay;
    if (overlayState != null) {
      overlayState.insert(overlayEntry);
    }

    
    Future.delayed(duration, () {
      overlayEntry?.remove();
    });
  }
}
class AnimatedSnackbar extends StatefulWidget {
  final String message;
  final bool isSuccess;
  final Color kPrimary;
  final Color kSecondary;
  final Color kTertiary;
  final VoidCallback onDismiss;

  const AnimatedSnackbar({
    super.key,
    required this.message,
    required this.isSuccess,
    required this.kPrimary,
    required this.kSecondary,
    required this.kTertiary,
    required this.onDismiss,
  });

  @override
  State<AnimatedSnackbar> createState() => _AnimatedSnackbarState();
}

class _AnimatedSnackbarState extends State<AnimatedSnackbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          constraints: BoxConstraints(maxWidth: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isSuccess
                  ? [widget.kTertiary, widget.kSecondary]
                  : [widget.kPrimary, Color(0xFFFF5252)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: widget.kPrimary.withAlpha((0.3 * 255).toInt()),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                   
                    color: Colors.white.withAlpha((0.2 * 255).toInt()),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    widget.isSuccess ? Icons.check_circle : Icons.error,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Flexible(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      color: Colors.white.withAlpha((0.8 * 255).toInt()),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}