import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/currency_formatter.dart';
import '../models/order.dart';
import '../views/orders/order_details_screen.dart';
import 'app_network_image.dart';

/// Reusable horizontal swipeable carousel displaying active in-flight orders.
/// Shows a single card when 1 order is active, or a swipeable PageView with
/// pagination indicators and counters when multiple shipments exist simultaneously.
class ActiveOrdersCarousel extends StatefulWidget {
  final List<OrderModel> orders;

  const ActiveOrdersCarousel({
    super.key,
    required this.orders,
  });

  @override
  State<ActiveOrdersCarousel> createState() => _ActiveOrdersCarouselState();
}

class _ActiveOrdersCarouselState extends State<ActiveOrdersCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.orders.isEmpty) return const SizedBox.shrink();

    if (widget.orders.length == 1) {
      return _buildTrackerCard(context, widget.orders.first);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppTheme.emeraldSuccess,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ACTIVE SHIPMENTS (${widget.orders.length})',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.secondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.outlineVariant.withOpacity(0.4),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '${_currentIndex + 1} of ${widget.orders.length}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 174,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.orders.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: _buildTrackerCard(context, widget.orders[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.orders.length, (index) {
              final isSelected = index == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isSelected ? 16 : 6,
                height: 5,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.outlineVariant.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackerCard(BuildContext context, OrderModel order) {
    final statusLower = order.status.toLowerCase();
    final isCancelled = statusLower == 'cancelled';

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

    Color badgeColor;
    Color badgeBg;
    IconData badgeIcon;
    String badgeLabel;

    if (isCancelled) {
      badgeColor = const Color(0xFFDC2626);
      badgeBg = const Color(0xFFFEE2E2);
      badgeIcon = Icons.cancel_outlined;
      badgeLabel = 'CANCELLED';
    } else if (currentStep == 3) {
      badgeColor = const Color(0xFF059669);
      badgeBg = const Color(0xFFD1FAE5);
      badgeIcon = Icons.check_circle_rounded;
      badgeLabel = 'DELIVERED';
    } else if (currentStep == 2) {
      badgeColor = const Color(0xFF0D9488);
      badgeBg = const Color(0xFFCCFBF1);
      badgeIcon = Icons.local_shipping_rounded;
      badgeLabel = 'ON THE WAY';
    } else if (currentStep == 1) {
      badgeColor = const Color(0xFF2563EB);
      badgeBg = const Color(0xFFDBEAFE);
      badgeIcon = Icons.inventory_2_rounded;
      badgeLabel = 'PREPARING';
    } else {
      badgeColor = const Color(0xFFD97706);
      badgeBg = const Color(0xFFFEF3C7);
      badgeIcon = Icons.access_time_filled_rounded;
      badgeLabel = 'ORDER PLACED';
    }

    final firstItem = order.items.isNotEmpty ? order.items.first : null;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.outlineVariant.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Status Pill + Order ID + Chevron
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 12, color: badgeColor),
                          const SizedBox(width: 5),
                          Text(
                            badgeLabel,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: badgeColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '#${order.orderId}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppTheme.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Item Thumbnail + Summary
                Row(
                  children: [
                    if (firstItem != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.outlineVariant.withOpacity(0.3),
                              width: 0.8,
                            ),
                          ),
                          child: AppNetworkImage(
                            imageUrl: firstItem.image,
                            width: 46,
                            height: 46,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          size: 20,
                          color: AppTheme.secondary,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            firstItem?.name ?? 'Order Items',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'} · ${CurrencyFormatter.formatPaisa(order.totalPaisa)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Stepper Timeline or Cancelled notice
                if (isCancelled)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                        SizedBox(width: 6),
                        Text(
                          'This order was cancelled and will not be dispatched.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _buildOrderStepProgress(currentStep),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderStepProgress(int currentStep) {
    const steps = ['Placed', 'Packed', 'Shipped', 'Delivered'];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final lineIndex = index ~/ 2;
          final isCompleted = lineIndex < currentStep;
          return Expanded(
            child: Container(
              height: 2.5,
              color: isCompleted
                  ? const Color(0xFF059669)
                  : AppTheme.outlineVariant.withOpacity(0.5),
            ),
          );
        } else {
          // Step dot + label
          final stepIndex = index ~/ 2;
          final isDone = stepIndex < currentStep;
          final isCurrent = stepIndex == currentStep;

          Color dotColor;
          Widget innerWidget;

          if (isDone) {
            dotColor = const Color(0xFF059669);
            innerWidget = const Icon(Icons.check_rounded, size: 11, color: Colors.white);
          } else if (isCurrent) {
            dotColor = const Color(0xFF059669);
            innerWidget = Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            );
          } else {
            dotColor = AppTheme.outlineVariant.withOpacity(0.6);
            innerWidget = const SizedBox();
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
                child: Center(child: innerWidget),
              ),
              const SizedBox(height: 4),
              Text(
                steps[stepIndex],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent || isDone ? FontWeight.w700 : FontWeight.w500,
                  color: isCurrent || isDone ? AppTheme.onSurface : AppTheme.secondary,
                ),
              ),
            ],
          );
        }
      }),
    );
  }
}
