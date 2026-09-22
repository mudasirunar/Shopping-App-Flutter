import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../widgets/app_confirmation_dialog.dart';
import '../../widgets/app_network_image.dart';
import '../checkout/checkout_screen.dart';
import '../details/product_details_screen.dart';
import '../../core/utils/app_snackbar.dart';
import '../../models/product.dart';

class CartScreen extends StatelessWidget {
  final VoidCallback? onExplore;
  final ScrollController? scrollController;

  const CartScreen({
    super.key,
    this.onExplore,
    this.scrollController,
  });

  void _confirmClearCart(BuildContext context) {
    AppConfirmationDialog.show(
      context: context,
      icon: Icons.remove_shopping_cart_outlined,
      title: 'Clear Cart?',
      message: 'Are you sure you want to remove all items from your cart?',
      confirmLabel: 'Clear All',
      isDestructive: true,
      onConfirm: () {
        context.read<CartProvider>().clearCart();
        AppSnackBar.show(
          context,
          message: 'Cart cleared',
        );
      },
    );
  }

  Future<bool> _confirmRemove(BuildContext context, Product product) async {
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      icon: Icons.delete_outline_rounded,
      title: 'Remove Item?',
      message: 'Are you sure you want to remove "${product.name}" from your cart?',
      confirmLabel: 'Remove',
      isDestructive: true,
      onConfirm: () {},
    );
    return confirmed ?? false;
  }

  void _removeProduct(BuildContext context, Product product) {
    context.read<CartProvider>().removeItem(product.id);
    AppSnackBar.show(
      context,
      message: 'Removed ${product.name} from cart',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primary, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        titleSpacing: Navigator.canPop(context) ? 0 : 16,
        backgroundColor: AppTheme.surface,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Your Cart',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 19,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${cart.totalItemCount} ${cart.totalItemCount == 1 ? 'item' : 'items'})',
              style: const TextStyle(
                color: AppTheme.secondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClearCart(context),
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: cart.isEmpty
          ? _EmptyCartView(onExplore: onExplore)
          : SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Free Delivery Progress Banner (only shown while working towards the PKR 5,000 threshold)
                  if (!cart.isFreeDeliveryUnlocked) ...[
                    _DeliveryBanner(cart: cart),
                    const SizedBox(height: 16),
                  ],

                  // Cart Items List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Dismissible(
                        key: ValueKey('cart_item_${item.product.id}'),
                        direction: DismissDirection.endToStart,
                        background: const _SwipeDeleteBackground(),
                        confirmDismiss: (_) => _confirmRemove(context, item.product),
                        onDismissed: (_) => _removeProduct(context, item.product),
                        child: _CartItemCard(
                          item: item,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Order Summary Card
                  _OrderSummaryCard(cart: cart),

                  const SizedBox(height: 16),

                  // Proceed to Checkout Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryContainer,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CheckoutScreen(),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Proceed to Checkout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DeliveryBanner extends StatelessWidget {
  final CartProvider cart;

  const _DeliveryBanner({required this.cart});

  @override
  Widget build(BuildContext context) {
    if (cart.isFreeDeliveryUnlocked) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.surfaceContainerHigh,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Free Delivery Target',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      'Add ${CurrencyFormatter.formatPaisa(cart.amountNeededForFreeDeliveryPaisa)} more for Free Delivery',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: cart.freeDeliveryProgress,
              backgroundColor: AppTheme.surfaceContainerHighest,
              color: AppTheme.primary,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;

  const _CartItemCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final product = item.product;

    return Material(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(
                product: product,
                showCartAction: false,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.surfaceContainerHigh.withOpacity(0.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Thumbnail
          AppNetworkImage(
            imageUrl: product.image,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(10),
            category: product.category,
            iconSize: 24,
          ),

          const SizedBox(width: 12),

          // Details & Controls
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          Text(
                            product.category,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.outlineVariant.withOpacity(0.5),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_shipping_outlined,
                            size: 12,
                            color: AppTheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.effectiveDeliveryDays == 1
                                ? '1 Day'
                                : '${product.effectiveDeliveryDays} Days',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Stepper and line total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Stepper
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 14),
                            onPressed: () {
                              final wasLastUnit = item.quantity <= 1;
                              cart.updateQuantity(product.id, item.quantity - 1);
                              if (wasLastUnit) {
                                AppSnackBar.show(
                                  context,
                                  message: 'Removed ${product.name} from cart',
                                );
                              }
                            },
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            constraints: const BoxConstraints(),
                            color: AppTheme.onSurface,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 14),
                            onPressed: () => cart.updateQuantity(product.id, item.quantity + 1),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    // Price info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.formatPaisa(item.subtotalPaisa),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          '${CurrencyFormatter.formatPaisa(product.pricePaisa)} each',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final CartProvider cart;

  const _OrderSummaryCard({required this.cart});

  @override
  Widget build(BuildContext context) {
    final isFreeDelivery = cart.isFreeDeliveryUnlocked;
    final totalProducts = cart.items.length;
    final totalUnits = cart.totalItemCount;

    final deliveryDaysList = cart.items.map((i) => i.product.effectiveDeliveryDays).toList();
    final minDeliveryDays = deliveryDaysList.isEmpty ? 3 : deliveryDaysList.reduce((a, b) => a < b ? a : b);
    final maxDeliveryDays = deliveryDaysList.isEmpty ? 3 : deliveryDaysList.reduce((a, b) => a > b ? a : b);
    final deliveryEstimate = minDeliveryDays == maxDeliveryDays
        ? '$maxDeliveryDays Days'
        : '$minDeliveryDays-$maxDeliveryDays Days';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
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
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$totalProducts ${totalProducts == 1 ? 'Product' : 'Products'} ($totalUnits ${totalUnits == 1 ? 'item' : 'items'})',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Products Count & Quantity Breakdown
          _summaryRow(
            'Products Count',
            '$totalProducts ${totalProducts == 1 ? 'product' : 'products'}',
          ),
          const SizedBox(height: 8),

          _summaryRow(
            'Total Quantity',
            '$totalUnits ${totalUnits == 1 ? 'unit' : 'units'}',
          ),
          const SizedBox(height: 8),

          _summaryRow('Subtotal', CurrencyFormatter.formatPaisa(cart.subtotalPaisa)),
          const SizedBox(height: 8),

          // Delivery row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('Delivery Fee', style: TextStyle(fontSize: 13, color: AppTheme.secondary)),
                  SizedBox(width: 6),
                  Text(
                    'Standard',
                    style: TextStyle(fontSize: 10, color: AppTheme.secondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (isFreeDelivery)
                Row(
                  children: [
                    Text(
                      CurrencyFormatter.formatPaisa(20000), // PKR 200.00
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.outline,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'FREE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.emeraldSuccess,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  CurrencyFormatter.formatPaisa(cart.deliveryFeePaisa),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
            ],
          ),

          // If free delivery unlocked, show savings row
          if (isFreeDelivery) ...[
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delivery Savings',
                  style: TextStyle(fontSize: 13, color: AppTheme.emeraldSuccess, fontWeight: FontWeight.w600),
                ),
                Text(
                  '-PKR 200.00',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.emeraldSuccess),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),
          _summaryRow('Estimated Taxes', 'PKR 0.00 (Included)'),

          // Payment & Shipping Quick Info
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.payments_outlined, size: 14, color: AppTheme.secondary),
                    SizedBox(width: 5),
                    Text(
                      'Cash on Delivery',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.secondary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined, size: 14, color: AppTheme.secondary),
                    const SizedBox(width: 5),
                    Text(
                      'Est. $deliveryEstimate',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.secondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  Text(
                    'Including all duties & delivery',
                    style: TextStyle(fontSize: 11, color: AppTheme.secondary),
                  ),
                ],
              ),
              Text(
                CurrencyFormatter.formatPaisa(cart.totalPaisa),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          if (isFreeDelivery) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.emeraldContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.emeraldSuccess.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 14, color: AppTheme.emeraldSuccess),
                  SizedBox(width: 6),
                  Text(
                    'You unlocked Free Delivery (Saved PKR 200.00)',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.emeraldSuccess,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.secondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  final VoidCallback? onExplore;

  const _EmptyCartView({this.onExplore});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 36,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Looks like you have not added anything yet. Explore our curated catalog to start shopping.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.secondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryContainer,
                foregroundColor: Colors.white,
                minimumSize: const Size(180, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (onExplore != null) {
                  onExplore!();
                } else {
                  context.read<NavigationProvider>().openShop();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              child: const Text(
                'Explore Products',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeDeleteBackground extends StatelessWidget {
  const _SwipeDeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.error,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Remove',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          SizedBox(width: 8),
          Icon(
            Icons.delete_outline_rounded,
            color: Colors.white,
            size: 22,
          ),
        ],
      ),
    );
  }
}
