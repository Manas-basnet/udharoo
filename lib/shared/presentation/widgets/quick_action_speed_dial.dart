import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/presentation/pages/transaction_form_screen.dart';

class QuickActionSpeedDial extends StatefulWidget {
  const QuickActionSpeedDial({super.key});

  @override
  State<QuickActionSpeedDial> createState() => _QuickActionSpeedDialState();
}

class _QuickActionSpeedDialState extends State<QuickActionSpeedDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
    });
    
    if (_isOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _createTransaction(TransactionType type) {
    _toggle(); // Close the dial
    context.go(
      Routes.transactionForm,
      extra: TransactionFormExtra(
        initialTransactionType: type,
      ),
    );
  }

  void _scanQR() {
    _toggle(); // Close the dial
    context.push(Routes.qrScanner);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop
        if (_isOpen)
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),

        // Speed dial buttons
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Scan QR button
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _animation.value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - _animation.value) * 50),
                    child: Opacity(
                      opacity: _animation.value,
                      child: _buildSpeedDialChild(
                        icon: Icons.qr_code_scanner,
                        label: 'Scan QR',
                        backgroundColor: Colors.blue,
                        onTap: _scanQR,
                        theme: theme,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // I gave money button
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _animation.value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - _animation.value) * 100),
                    child: Opacity(
                      opacity: _animation.value,
                      child: _buildSpeedDialChild(
                        icon: Icons.trending_up,
                        label: 'I gave money',
                        backgroundColor: Colors.green,
                        onTap: () => _createTransaction(TransactionType.lent),
                        theme: theme,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // I received money button
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _animation.value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - _animation.value) * 150),
                    child: Opacity(
                      opacity: _animation.value,
                      child: _buildSpeedDialChild(
                        icon: Icons.trending_down,
                        label: 'I received money',
                        backgroundColor: Colors.orange,
                        onTap: () => _createTransaction(TransactionType.borrowed),
                        theme: theme,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Main FAB
            FloatingActionButton(
              onPressed: _toggle,
              backgroundColor: theme.colorScheme.primary,
              child: AnimatedRotation(
                turns: _isOpen ? 0.125 : 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  _isOpen ? Icons.close : Icons.add,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpeedDialChild({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Button
        Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}