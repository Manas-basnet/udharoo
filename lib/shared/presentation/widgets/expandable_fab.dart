import 'package:flutter/material.dart';
import 'dart:math' as math;

class FABAction {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const FABAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });
}

class ExpandableFAB extends StatefulWidget {
  final List<FABAction> actions;
  final ValueChanged<bool>? onExpandedChanged;

  const ExpandableFAB({
    super.key,
    required this.actions,
    this.onExpandedChanged,
  });

  @override
  State<ExpandableFAB> createState() => ExpandableFABState();
}

class ExpandableFABState extends State<ExpandableFAB>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.75,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    widget.onExpandedChanged?.call(_isExpanded);

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void close() {
    if (_isExpanded) {
      _toggle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 160,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ..._buildActionButtons(),
          Positioned(
            bottom: 0,
            left: 120,
            child: _buildMainFAB(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    final actions = <Widget>[];
    final distance = 85.0;
    final centerX = 126.0;
    final centerY = 30.0;

    for (int i = 0; i < widget.actions.length; i++) {
      final angle = math.pi - (i * math.pi / (widget.actions.length - 1));

      final targetX = centerX + (distance * math.cos(angle));
      final targetY = centerY + (distance * math.sin(angle));

      actions.add(
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            final currentX = centerX + ((targetX - centerX) * _expandAnimation.value);
            final currentY = centerY + ((targetY - centerY) * _expandAnimation.value);

            return Positioned(
              bottom: currentY,
              left: currentX,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Transform.scale(
                  scale: _expandAnimation.value,
                  child: Opacity(
                    opacity: _expandAnimation.value,
                    child: ActionButton(
                      action: widget.actions[i],
                      onPressed: () {
                        widget.actions[i].onPressed();
                        _toggle();
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return actions;
  }

  Widget _buildMainFAB() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _rotateAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotateAnimation.value * 2 * math.pi,
          child: Material(
            elevation: 8,
            shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  _isExpanded ? Icons.close : Icons.add,
                  color: colorScheme.onPrimary,
                  size: 28,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ActionButton extends StatelessWidget {
  final FABAction action;
  final VoidCallback onPressed;

  const ActionButton({
    super.key,
    required this.action,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Tooltip(
      message: action.tooltip,
      child: Material(
        elevation: 4,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            width: 48,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                action.icon,
                color: colorScheme.primary,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
