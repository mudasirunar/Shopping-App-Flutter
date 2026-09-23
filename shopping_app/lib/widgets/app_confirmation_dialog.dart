import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Reusable branded confirmation modal with centered icon badge, title,
/// descriptive message, and aligned action buttons (Cancel + Primary Action).
/// Supports async execution with loading indicator on confirm and disabled cancel.
class AppConfirmationDialog extends StatefulWidget {
  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final FutureOr<void> Function() onConfirm;
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
    required FutureOr<void> Function() onConfirm,
    bool isDestructive = true,
    Color? iconColor,
    Color? iconBackgroundColor,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AppConfirmationDialog(
        icon: icon,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        isDestructive: isDestructive,
        iconColor: iconColor,
        iconBackgroundColor: iconBackgroundColor,
      ),
    );
  }

  @override
  State<AppConfirmationDialog> createState() => _AppConfirmationDialogState();
}

class _AppConfirmationDialogState extends State<AppConfirmationDialog> {
  bool _isLoading = false;

  Future<void> _handleConfirm() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await widget.onConfirm();
      if (mounted) {
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) {
          navigator.pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = widget.iconColor ??
        (widget.isDestructive ? AppTheme.error : AppTheme.primary);
    final effectiveIconBg = widget.iconBackgroundColor ??
        (widget.isDestructive ? const Color(0xFFFEE2E2) : AppTheme.surfaceContainerLow);

    return PopScope(
      canPop: !_isLoading,
      child: Dialog(
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
                    widget.icon,
                    size: 26,
                    color: effectiveIconColor,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                widget.title,
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
                widget.message,
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
                          color: AppTheme.outlineVariant.withOpacity(_isLoading ? 0.3 : 0.6),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: _isLoading ? null : () => Navigator.pop(context, false),
                      child: Text(
                        widget.cancelLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _isLoading
                              ? AppTheme.secondary.withOpacity(0.35)
                              : AppTheme.secondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isDestructive ? AppTheme.error : AppTheme.primaryContainer,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: (widget.isDestructive ? AppTheme.error : AppTheme.primaryContainer).withOpacity(0.7),
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: _isLoading ? null : _handleConfirm,
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              widget.confirmLabel,
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
      ),
    );
  }
}
