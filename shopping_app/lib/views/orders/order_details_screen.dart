import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/cancel_order_dialog.dart';

class OrderDetailsScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final currentOrder = orderProvider.userOrders.firstWhere(
      (o) => o.orderId == order.orderId,
      orElse: () => order,
    );

    final statusLower = currentOrder.status.toLowerCase();
    final isCancelled = currentOrder.isCancelled ||
        statusLower == 'cancelled' ||
        statusLower == 'canceled';
    final isDelivered = statusLower == 'delivered';
    final isCancellable = !isCancelled && !isDelivered;

    int currentStep = 0;
    if (statusLower == 'processing' || statusLower == 'packed') {
      currentStep = 1;
    } else if (statusLower == 'shipped' ||
        statusLower == 'in transit' ||
        statusLower == 'out for delivery') {
      currentStep = 2;
    } else if (statusLower == 'delivered') {
      currentStep = 3;
    }

    final dateFormat = DateFormat('MMMM dd, yyyy · hh:mm a');
    final formattedDate = dateFormat.format(currentOrder.createdAt);

    Color statusBadgeBg;
    Color statusBadgeColor;
    IconData statusIcon;
    String statusDescription;

    if (isCancelled) {
      statusBadgeBg = const Color(0xFFFEF2F2);
      statusBadgeColor = const Color(0xFFDC2626);
      statusIcon = Icons.cancel_outlined;
      statusDescription = currentOrder.cancellationReason != null &&
              currentOrder.cancellationReason!.isNotEmpty
          ? 'Order cancelled. Reason: ${currentOrder.cancellationReason}'
          : 'This order was cancelled and will not be dispatched.';
    } else if (isDelivered) {
      statusBadgeBg = AppTheme.emeraldContainer;
      statusBadgeColor = AppTheme.emeraldSuccess;
      statusIcon = Icons.check_circle_outline_rounded;
      statusDescription = 'Package has been delivered to your doorstep.';
    } else if (statusLower == 'shipped' ||
        statusLower == 'in transit' ||
        statusLower == 'out for delivery') {
      statusBadgeBg = const Color(0xFFCCFBF1);
      statusBadgeColor = const Color(0xFF0D9488);
      statusIcon = Icons.local_shipping_outlined;
      statusDescription = 'Package is dispatched and on the way to you.';
    } else if (statusLower == 'processing' || statusLower == 'packed') {
      statusBadgeBg = const Color(0xFFDBEAFE);
      statusBadgeColor = const Color(0xFF2563EB);
      statusIcon = Icons.inventory_2_outlined;
      statusDescription = 'Order is packed and prepared for courier handover.';
    } else {
      statusBadgeBg = const Color(0xFFFEF3C7);
      statusBadgeColor = const Color(0xFFD97706);
      statusIcon = Icons.access_time_rounded;
      statusDescription = 'Order received. Being confirmed for processing.';
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        titleSpacing: 16,
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Order #${currentOrder.orderId}',
          style: const TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order ${currentOrder.orderId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBadgeBg,
                          borderRadius: BorderRadius.circular(6),
                          border: isCancelled
                              ? Border.all(color: const Color(0xFFFCA5A5), width: 1)
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isCancelled)
                              const Icon(
                                Icons.cancel_rounded,
                                size: 12,
                                color: Color(0xFFDC2626),
                              )
                            else
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusBadgeColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            const SizedBox(width: 5),
                            Text(
                              isCancelled ? 'CANCELLED' : currentOrder.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: statusBadgeColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Placed on $formattedDate',
                    style: const TextStyle(fontSize: 12, color: AppTheme.secondary),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? const Color(0xFFFEE2E2)
                          : AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, size: 18, color: statusBadgeColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            statusDescription,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isCancelled ? const Color(0xFFB91C1C) : AppTheme.secondary,
                              fontWeight: isCancelled ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Vertical Shipment Tracking Timeline Card
            _buildTrackingTimelineCard(context, currentOrder, currentStep, isCancelled),

            const SizedBox(height: 16),

            // Delivery Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.location_on_outlined, size: 18, color: AppTheme.primary),
                      SizedBox(width: 6),
                      Text(
                        'Delivery Address',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    order.deliveryInfo.fullName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mobile: ${order.deliveryInfo.phoneNumber}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.secondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${order.deliveryInfo.streetAddress}, ${order.deliveryInfo.city}, ${order.deliveryInfo.province}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.secondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Payment Mode Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined, size: 20, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Payment Method',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Cash on Delivery · Due on doorstep arrival',
                          style: TextStyle(fontSize: 11, color: AppTheme.secondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Unpaid',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.secondary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Itemized List
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Purchased Items (${order.items.length})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  for (final item in order.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          AppNetworkImage(
                            imageUrl: item.image,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(8),
                            iconSize: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${CurrencyFormatter.formatPaisa(item.unitPricePaisa)} x ${item.quantity}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.secondary),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatPaisa(item.subtotalPaisa),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Summary Breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _row('Subtotal', CurrencyFormatter.formatPaisa(currentOrder.subtotalPaisa)),
                  const SizedBox(height: 6),
                  _row(
                    'Delivery Fee',
                    currentOrder.deliveryPaisa == 0 ? 'Free' : CurrencyFormatter.formatPaisa(currentOrder.deliveryPaisa),
                  ),
                  const SizedBox(height: 6),
                  _row('Estimated Taxes', CurrencyFormatter.formatPaisa(0)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      Text(
                        CurrencyFormatter.formatPaisa(currentOrder.totalPaisa),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Cancel Order Action Button or Cancelled Information Card
            if (isCancellable) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => CancelOrderDialog.show(
                    context: context,
                    order: currentOrder,
                  ),
                  icon: const Icon(
                    Icons.remove_shopping_cart_outlined,
                    color: Color(0xFFDC2626),
                    size: 18,
                  ),
                  label: const Text(
                    'Cancel Order',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                    backgroundColor: const Color(0xFFFEF2F2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ] else if (isCancelled) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Cancelled',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            currentOrder.cancellationReason != null &&
                                    currentOrder.cancellationReason!.isNotEmpty
                                ? 'Feedback: "${currentOrder.cancellationReason}"'
                                : 'This order has been cancelled and will not be dispatched.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF991B1B),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.secondary)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTrackingTimelineCard(
    BuildContext context,
    OrderModel order,
    int currentStep,
    bool isCancelled,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy · hh:mm a');
    final dateOnlyFormat = DateFormat('MMM dd, yyyy');
    final shortDateFormat = DateFormat('MMM dd');

    String stepBadgeText;
    Color stepBadgeBg;
    Color stepBadgeColor;

    if (isCancelled) {
      stepBadgeText = 'CANCELLED';
      stepBadgeBg = const Color(0xFFFEF2F2);
      stepBadgeColor = const Color(0xFFDC2626);
    } else if (currentStep == 3) {
      stepBadgeText = 'All Steps Complete';
      stepBadgeBg = const Color(0xFFD1FAE5);
      stepBadgeColor = const Color(0xFF059669);
    } else {
      stepBadgeText = 'Step ${currentStep + 1} of 4';
      stepBadgeBg = const Color(0xFFEFF6FF);
      stepBadgeColor = const Color(0xFF2563EB);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon, title, and current stage badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.alt_route_rounded, size: 20, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text(
                    'Shipment Tracking',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: stepBadgeBg,
                  borderRadius: BorderRadius.circular(20),
                  border: isCancelled
                      ? Border.all(color: const Color(0xFFFCA5A5), width: 1)
                      : null,
                ),
                child: Text(
                  stepBadgeText,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: stepBadgeColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Vertical timeline list
          if (isCancelled) ...[
            _buildTimelineStep(
              title: 'Order Placed & Confirmed',
              subtitle: 'Order registered and payment verified.',
              timestamp: dateFormat.format(order.createdAt),
              state: _TimelineStepState.completed,
              isLast: false,
              icon: Icons.receipt_long_rounded,
            ),
            _buildTimelineStep(
              title: 'Order Cancelled',
              subtitle: order.cancellationReason != null &&
                      order.cancellationReason!.isNotEmpty
                  ? 'Reason: "${order.cancellationReason}"'
                  : 'Order cancelled upon customer request.',
              timestamp: 'Cancellation finalized',
              state: _TimelineStepState.cancelled,
              isLast: true,
              icon: Icons.cancel_outlined,
            ),
          ] else ...[
            _buildTimelineStep(
              title: 'Order Confirmed & Placed',
              subtitle: 'Order received and payment authorized.',
              timestamp: dateFormat.format(order.createdAt),
              state: currentStep == 0
                  ? _TimelineStepState.current
                  : _TimelineStepState.completed,
              isLast: false,
              icon: Icons.receipt_long_rounded,
            ),
            _buildTimelineStep(
              title: 'Quality Check & Packing',
              subtitle: 'Items picked from inventory, quality inspected, and sealed.',
              timestamp: currentStep > 1
                  ? dateFormat.format(order.createdAt.add(const Duration(hours: 3)))
                  : currentStep == 1
                      ? 'In Progress · Handling at Fulfillment Hub'
                      : 'Next Step · Estimated ~3 hours after placement',
              state: currentStep > 1
                  ? _TimelineStepState.completed
                  : currentStep == 1
                      ? _TimelineStepState.current
                      : _TimelineStepState.next,
              isLast: false,
              icon: Icons.inventory_2_outlined,
            ),
            _buildTimelineStep(
              title: 'Dispatched & In Transit',
              subtitle: 'Courier partner dispatched shipment to local hub.',
              timestamp: currentStep > 2
                  ? dateFormat.format(order.createdAt.add(const Duration(days: 1, hours: 2)))
                  : currentStep == 2
                      ? 'On the Road · Courier assigned & moving'
                      : currentStep == 1
                          ? 'Next Step · Expected dispatch tomorrow'
                          : 'Expected by ${dateOnlyFormat.format(order.createdAt.add(const Duration(days: 1)))}',
              state: currentStep > 2
                  ? _TimelineStepState.completed
                  : currentStep == 2
                      ? _TimelineStepState.current
                      : currentStep == 1
                          ? _TimelineStepState.next
                          : _TimelineStepState.upcoming,
              isLast: false,
              icon: Icons.local_shipping_outlined,
            ),
            _buildTimelineStep(
              title: 'Delivered to Doorstep',
              subtitle: 'Handed over safely to recipient at delivery address.',
              timestamp: currentStep == 3
                  ? dateFormat.format(order.createdAt.add(const Duration(days: 2, hours: 4)))
                  : currentStep == 2
                      ? 'Next Step · Expected delivery by tomorrow'
                      : 'Estimated: ${shortDateFormat.format(order.createdAt.add(const Duration(days: 2)))} – ${dateOnlyFormat.format(order.createdAt.add(const Duration(days: 4)))}',
              state: currentStep == 3
                  ? _TimelineStepState.completed
                  : currentStep == 2
                      ? _TimelineStepState.next
                      : _TimelineStepState.upcoming,
              isLast: true,
              icon: Icons.home_outlined,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required String timestamp,
    required _TimelineStepState state,
    required bool isLast,
    required IconData icon,
  }) {
    Color titleColor;
    Color badgeColor;
    Color badgeBg;
    String badgeLabel;

    switch (state) {
      case _TimelineStepState.completed:
        titleColor = AppTheme.primary;
        badgeColor = const Color(0xFF059669);
        badgeBg = const Color(0xFFD1FAE5);
        badgeLabel = 'COMPLETED';
        break;
      case _TimelineStepState.current:
        titleColor = const Color(0xFF1D4ED8);
        badgeColor = const Color(0xFF2563EB);
        badgeBg = const Color(0xFFDBEAFE);
        badgeLabel = 'WHERE IT IS NOW';
        break;
      case _TimelineStepState.next:
        titleColor = AppTheme.primary;
        badgeColor = const Color(0xFFD97706);
        badgeBg = const Color(0xFFFEF3C7);
        badgeLabel = 'NEXT STEP';
        break;
      case _TimelineStepState.upcoming:
        titleColor = const Color(0xFF94A3B8);
        badgeColor = const Color(0xFF94A3B8);
        badgeBg = const Color(0xFFF1F5F9);
        badgeLabel = 'UPCOMING';
        break;
      case _TimelineStepState.cancelled:
        titleColor = const Color(0xFFDC2626);
        badgeColor = const Color(0xFFDC2626);
        badgeBg = const Color(0xFFFEE2E2);
        badgeLabel = 'CANCELLED';
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Node and connector line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                _buildStepNode(state, icon),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: _connectorColor(state),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right: Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: state == _TimelineStepState.current ||
                                    state == _TimelineStepState.completed
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: titleColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(12),
                          border: state == _TimelineStepState.current
                              ? Border.all(color: const Color(0xFF93C5FD), width: 0.8)
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (state == _TimelineStepState.current) ...[
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              badgeLabel,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: badgeColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Date and time row
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: state == _TimelineStepState.current
                            ? const Color(0xFF2563EB)
                            : state == _TimelineStepState.upcoming
                                ? const Color(0xFF94A3B8)
                                : AppTheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          timestamp,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: state == _TimelineStepState.current
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: state == _TimelineStepState.current
                                ? const Color(0xFF1D4ED8)
                                : state == _TimelineStepState.upcoming
                                    ? const Color(0xFF94A3B8)
                                    : AppTheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: state == _TimelineStepState.upcoming
                          ? const Color(0xFF94A3B8)
                          : state == _TimelineStepState.cancelled
                              ? const Color(0xFF991B1B)
                              : AppTheme.secondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode(_TimelineStepState state, IconData icon) {
    switch (state) {
      case _TimelineStepState.completed:
        return Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFF059669),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.check_rounded, color: Colors.white, size: 16),
          ),
        );
      case _TimelineStepState.current:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF2563EB), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.25),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.my_location_rounded, color: Color(0xFF2563EB), size: 14),
          ),
        );
      case _TimelineStepState.next:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD97706), width: 1.8),
          ),
          child: const Center(
            child: Icon(Icons.arrow_downward_rounded, color: Color(0xFFD97706), size: 14),
          ),
        );
      case _TimelineStepState.upcoming:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFCBD5E1),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      case _TimelineStepState.cancelled:
        return Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFFDC2626),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.close_rounded, color: Colors.white, size: 16),
          ),
        );
    }
  }

  Color _connectorColor(_TimelineStepState state) {
    switch (state) {
      case _TimelineStepState.completed:
        return const Color(0xFF059669);
      case _TimelineStepState.current:
        return const Color(0xFF93C5FD);
      case _TimelineStepState.next:
      case _TimelineStepState.upcoming:
        return const Color(0xFFE2E8F0);
      case _TimelineStepState.cancelled:
        return const Color(0xFFFCA5A5);
    }
  }
}

enum _TimelineStepState {
  completed,
  current,
  next,
  upcoming,
  cancelled,
}

