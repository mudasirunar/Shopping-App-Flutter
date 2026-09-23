import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_snackbar.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';

/// Modal dialog that requests cancellation confirmation along with user feedback.
class CancelOrderDialog extends StatefulWidget {
  final OrderModel order;

  const CancelOrderDialog({super.key, required this.order});

  static Future<bool?> show({
    required BuildContext context,
    required OrderModel order,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => CancelOrderDialog(order: order),
    );
  }

  @override
  State<CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<CancelOrderDialog> {
  static const List<String> _cancellationReasons = [
    'Changed my mind',
    'Ordered by mistake / duplicate',
    'Found a better price elsewhere',
    'Delivery is taking too long',
    'Need to change address / phone',
    'Other reason',
  ];

  String _selectedReason = _cancellationReasons.first;
  final TextEditingController _customReasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (_isSubmitting) return;

    final feedbackReason = _selectedReason == 'Other reason' &&
            _customReasonController.text.trim().isNotEmpty
        ? _customReasonController.text.trim()
        : _selectedReason;

    setState(() {
      _isSubmitting = true;
    });

    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.cancelOrder(
      widget.order.orderId,
      reason: feedbackReason,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
      HapticFeedback.mediumImpact();
      AppSnackBar.show(
        context,
        message: 'Order #${widget.order.orderId} has been cancelled.',
        backgroundColor: const Color(0xFFDC2626),
      );
    } else {
      setState(() {
        _isSubmitting = false;
      });
      AppSnackBar.show(
        context,
        message: 'Unable to cancel this order.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Badge & Title
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFECACA),
                        width: 1.2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.remove_shopping_cart_outlined,
                        color: Color(0xFFDC2626),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cancel Order #${widget.order.orderId}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Please tell us why you wish to cancel',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'Reason for cancellation',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 8),

              // Reasons list
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.outlineVariant.withOpacity(0.4),
                  ),
                ),
                child: Column(
                  children: List.generate(_cancellationReasons.length, (index) {
                    final reason = _cancellationReasons[index];
                    final isSelected = _selectedReason == reason;
                    final isLast = index == _cancellationReasons.length - 1;

                    return InkWell(
                      onTap: _isSubmitting
                          ? null
                          : () {
                              setState(() {
                                _selectedReason = reason;
                              });
                            },
                      borderRadius: BorderRadius.vertical(
                        top: index == 0 ? const Radius.circular(14) : Radius.zero,
                        bottom: isLast ? const Radius.circular(14) : Radius.zero,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: isLast
                              ? null
                              : Border(
                                  bottom: BorderSide(
                                    color: AppTheme.outlineVariant.withOpacity(0.3),
                                    width: 0.8,
                                  ),
                                ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              size: 18,
                              color: isSelected ? const Color(0xFFDC2626) : AppTheme.secondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                reason,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppTheme.primary : AppTheme.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),

              if (_selectedReason == 'Other reason') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _customReasonController,
                  maxLines: 2,
                  maxLength: 120,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Tell us more (optional)...',
                    hintStyle: const TextStyle(fontSize: 12, color: AppTheme.secondary),
                    filled: true,
                    fillColor: AppTheme.surfaceContainerLow,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Actions: Keep Order vs Confirm Cancellation
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.6)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Keep Order',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Cancel Order',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
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
