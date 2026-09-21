import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Reusable branded confirmation modal with centered icon badge, title,
/// descriptive message, and aligned action buttons (Cancel + Primary Action).
class AppConfirmationDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final bool isDestructive;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  const AppConfirmationDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
    required this.onConfirm,
    this.isDestructive = true,
    this.iconColor,
    this.iconBackgroundColor,
  });

  /// Shows the dialog and calls [onConfirm] when the confirm action is pressed.
  static Future<bool?> show({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    required VoidCallback onConfirm,
    bool isDestructive = true,
    Color? iconColor,
    Color? iconBackgroundColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AppConfirmationDialog(
        icon: icon,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: () {
          Navigator.pop(ctx, true);
          onConfirm();
        },
        isDestructive: isDestructive,
        iconColor: iconColor,
        iconBackgroundColor: iconBackgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ??
        (isDestructive ? AppTheme.error : AppTheme.primary);
    final effectiveIconBg = iconBackgroundColor ??
        (isDestructive ? const Color(0xFFFEE2E2) : AppTheme.surfaceContainerLow);

    return Dialog(
      backgroundColor: AppTheme.surfaceContainerLowest,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Centered Icon Badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: effectiveIconBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 26,
                  color: effectiveIconColor,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 8),

            // Message Body
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppTheme.secondary,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 24),

            // Symmetrical, Perfectly Aligned Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      side: BorderSide(
                        color: AppTheme.outlineVariant.withOpacity(0.6),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      cancelLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDestructive ? AppTheme.error : AppTheme.primaryContainer,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: onConfirm,
                    child: Text(
                      confirmLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
