import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Centralized SnackBar manager that guarantees snappy, non-blocking user feedback.
/// Immediately clears any queued or animating snackbars so new actions feel instant.
class AppSnackBar {
  /// Shows a floating SnackBar.
  /// If [actionLabel] and [onAction] are provided, the SnackBar stays visible
  /// for [effectiveDuration] (default 3.2s) to allow comfortable interaction without gesture collisions.
  /// Otherwise, standard feedback dismisses quickly (default 1.6s).
  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
    Color? backgroundColor,
    Color? actionTextColor,
    bool isError = false,
  }) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    // Instantly terminate any currently visible or queued snackbars
    messenger.clearSnackBars();

    final effectiveDuration = duration ??
        (actionLabel != null && onAction != null
            ? const Duration(milliseconds: 3200)
            : const Duration(milliseconds: 1600));

    final effectiveBg = backgroundColor ?? (isError ? AppTheme.error : AppTheme.primary);

    messenger.showSnackBar(
      SnackBar(
        persist: false,
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        duration: effectiveDuration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: effectiveBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: actionTextColor ?? const Color(0xFF38BDF8),
                onPressed: () {
                  try {
                    onAction();
                  } catch (e) {
                    debugPrint('AppSnackBar onAction error: $e');
                  }
                },
              )
            : null,
      ),
    );
  }
}
