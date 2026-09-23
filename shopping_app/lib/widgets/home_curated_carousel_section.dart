import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/currency_formatter.dart';
import '../models/product.dart';
import '../views/details/product_details_screen.dart';
import 'app_network_image.dart';

/// Reusable horizontal curated carousel section for the Home screen.
/// Standardizes Section Header (Icon + Title + Chip/Badge + "View All" action),
/// product preview cards with snug vertical spacing, and a trailing "View All (X items) →" card.
class HomeCuratedCarouselSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget? badge;
  final List<Product> products;
  final int totalCollectionCount;
  final VoidCallback onViewAll;
  final Widget Function(Product)? badgeTagBuilder;
  final bool showOriginalPrice;
  final double topPadding;

  const HomeCuratedCarouselSection({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    this.badge,
    required this.products,
    required this.totalCollectionCount,
    required this.onViewAll,
    this.badgeTagBuilder,
    this.showOriginalPrice = false,
    this.topPadding = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    final carouselHeight = showOriginalPrice ? 214.0 : 202.0;

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Standardized Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: iconColor, size: 22),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        badge!,
                      ],
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Horizontal Product Cards Carousel
          SizedBox(
            height: carouselHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index < products.length) {
                  return _buildProductCard(context, products[index]);
                }
                return _buildTrailingViewAllCard(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Snug Preview Product Card
  // ---------------------------------------------------------------------------
  Widget _buildProductCard(BuildContext context, Product p) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: p),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 154,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image with Context Highlight Tag
            AspectRatio(
              aspectRatio: 1.15,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AppNetworkImage(
                      imageUrl: p.image,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(10),
                      category: p.category,
                    ),
                  ),
                  if (badgeTagBuilder != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: badgeTagBuilder!(p),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 7),

            // Product Name (2 Lines Max)
            SizedBox(
              height: 32,
              child: Text(
                p.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                  height: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 5),

            // Pricing
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CurrencyFormatter.formatPaisa(p.pricePaisa),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
                if (showOriginalPrice && p.hasDiscount)
                  Text(
                    CurrencyFormatter.formatPaisa(p.originalPricePaisa!),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.secondary.withOpacity(0.7),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Trailing "View All (X items) →" Card
  // ---------------------------------------------------------------------------
  Widget _buildTrailingViewAllCard(BuildContext context) {
    return InkWell(
      onTap: onViewAll,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 124,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: iconColor.withOpacity(0.25), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: iconColor.withOpacity(0.35)),
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: iconColor,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'View All',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '$totalCollectionCount items',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
