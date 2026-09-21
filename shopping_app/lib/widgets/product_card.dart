import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/currency_formatter.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import 'app_network_image.dart';
import '../core/utils/app_snackbar.dart';
import '../core/navigation/app_navigator.dart';

/// Reusable responsive product card used across CatalogScreen and WishlistScreen.
/// Adapts dynamically to available width: renders compact 2-column card when narrow,
/// and an enriched horizontal card with extra details and description when wide.
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final bool? isWide;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    if (isWide != null) {
      return isWide! ? _buildWideCard(context) : _buildCompactCard(context);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 280) {
          return _buildWideCard(context);
        }
        return _buildCompactCard(context);
      },
    );
  }

  /// Compact card layout for 2-column grid rows
  Widget _buildCompactCard(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final inCart = cart.isInCart(product.id);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.outlineVariant.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Canvas
            AspectRatio(
              aspectRatio: 1.15,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AppNetworkImage(
                      imageUrl: product.image,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(12),
                      category: product.category,
                    ),
                  ),
                  if (product.badgeTag != null)
                    _buildBadgeTag(product.badgeTag!),
                  if (product.qualityTag != null)
                    _buildQualityTag(product.qualityTag!),
                  if (product.isOutOfStock)
                    _buildSoldOutBadge()
                  else if (product.isLowStock)
                    _buildLowStockBadge(product.stockCount),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Category & Delivery Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    product.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.secondary,
                      letterSpacing: 0.7,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 11, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 1),
                    Text(
                      '${product.effectiveDeliveryDays}d transit',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 3),

            // Product Name (2-line clamp with fixed height)
            SizedBox(
              height: 34,
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                  height: 1.25,
                  letterSpacing: -0.2,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Star Rating Row
            Row(
              children: [
                ...List.generate(5, (starIdx) {
                  final filled = starIdx < product.displayRating.round();
                  return Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 13.5,
                    color: filled ? const Color(0xFFF59E0B) : AppTheme.secondary.withOpacity(0.3),
                  );
                }),
                const SizedBox(width: 4),
                Text(
                  '(${product.displayRating.round()}/5)',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Price and Action Row (Snug fit with no bottom whitespace)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    CurrencyFormatter.formatPaisa(product.pricePaisa),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildCartActionButton(context, cart, inCart, isWide: false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Wide card layout with extra details when card spans full width
  Widget _buildWideCard(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final inCart = cart.isInCart(product.id);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.outlineVariant.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Image Canvas (Width: 120, Height: 134)
            SizedBox(
              width: 120,
              height: 134,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AppNetworkImage(
                      imageUrl: product.image,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(12),
                      category: product.category,
                    ),
                  ),
                  if (product.badgeTag != null)
                    _buildBadgeTag(product.badgeTag!),
                  if (product.isOutOfStock)
                    _buildSoldOutBadge()
                  else if (product.isLowStock)
                    _buildLowStockBadge(product.stockCount),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Right Content Area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Category, Transit Duration, Quality Tag (Defensively flexed)
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          product.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondary,
                            letterSpacing: 0.7,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('•', style: TextStyle(color: AppTheme.secondary.withOpacity(0.4), fontSize: 10)),
                      const SizedBox(width: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded, size: 11, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 1),
                          Text(
                            '${product.effectiveDeliveryDays}d transit',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      if (product.qualityTag != null) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.qualityTag!,
                              style: const TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Row 2: Product Name
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                      height: 1.25,
                      letterSpacing: -0.2,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Row 3: Rating + Review Count (Flexed to avoid overflow)
                  Row(
                    children: [
                      ...List.generate(5, (starIdx) {
                        final filled = starIdx < product.displayRating.round();
                        return Icon(
                          filled ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 13,
                          color: filled ? const Color(0xFFF59E0B) : AppTheme.secondary.withOpacity(0.3),
                        );
                      }),
                      const SizedBox(width: 4),
                      Text(
                        '(${product.displayRating.round()}/5)',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondary,
                        ),
                      ),
                      if (product.reviews != null && product.reviews!.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '• ${product.reviews!.length} reviews',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.secondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Row 4: Description Preview Snippet
                  if (product.description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.secondary.withOpacity(0.85),
                        height: 1.3,
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Row 5: Price and Action Button (Expanded price to avoid overflow)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          CurrencyFormatter.formatPaisa(product.pricePaisa),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildCartActionButton(context, cart, inCart, isWide: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartActionButton(
    BuildContext context,
    CartProvider cart,
    bool inCart, {
    required bool isWide,
  }) {
    if (product.isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Sold Out',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFFDC2626),
          ),
        ),
      );
    }

    if (inCart) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 12, color: Color(0xFF16A34A)),
            SizedBox(width: 3),
            Text(
              'In Cart',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF16A34A),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () {
        cart.addItem(product);
        AppSnackBar.show(
          context,
          message: 'Added ${product.name} to cart',
          actionLabel: 'View Cart',
          onAction: () => AppNavigator.openCart(),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: isWide ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6) : null,
        width: isWide ? null : 32,
        height: isWide ? null : 32,
        decoration: BoxDecoration(
          color: AppTheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: isWide
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_shopping_cart_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Add',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : const Center(
                child: Icon(Icons.add_rounded, size: 20, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildBadgeTag(String tag) {
    return Positioned(
      top: 6,
      left: 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.72),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF38BDF8),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              tag,
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityTag(String tag) {
    return Positioned(
      top: 6,
      right: 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          tag,
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildSoldOutBadge() {
    return Positioned(
      bottom: 6,
      left: 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 3,
            ),
          ],
        ),
        child: const Text(
          'SOLD OUT',
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildLowStockBadge(int? stockCount) {
    return Positioned(
      bottom: 6,
      left: 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFD97706),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 3,
            ),
          ],
        ),
        child: Text(
          stockCount != null ? 'Only $stockCount left' : 'Limited',
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
