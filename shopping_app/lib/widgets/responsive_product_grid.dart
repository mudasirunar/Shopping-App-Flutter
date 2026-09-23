import 'package:flutter/material.dart';
import '../models/product.dart';
import 'product_card.dart';

/// Renders products dynamically in a 2-column layout, but automatically expands
/// any single or lone row item across the full width as an enriched wide card.
class ResponsiveProductGrid extends StatelessWidget {
  final List<Product> products;
  final void Function(Product product) onProductTap;
  final EdgeInsetsGeometry padding;
  final bool? showCategory;

  const ResponsiveProductGrid({
    super.key,
    required this.products,
    required this.onProductTap,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 32),
    this.showCategory,
  });

  @override
  Widget build(BuildContext context) {
    final rowCount = (products.length / 2).ceil();

    return SliverPadding(
      padding: padding,
      sliver: SliverList.builder(
        itemCount: rowCount,
        itemBuilder: (context, rowIndex) {
          final firstIndex = rowIndex * 2;
          final secondIndex = firstIndex + 1;
          final hasSecond = secondIndex < products.length;

          final p1 = products[firstIndex];

          if (!hasSecond) {
            // Lone product in row -> automatically expands across full width
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProductCard(
                product: p1,
                onTap: () => onProductTap(p1),
                isWide: true,
                showCategory: showCategory,
              ),
            );
          }

          final p2 = products[secondIndex];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ProductCard(
                    product: p1,
                    onTap: () => onProductTap(p1),
                    isWide: false,
                    showCategory: showCategory,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ProductCard(
                    product: p2,
                    onTap: () => onProductTap(p2),
                    isWide: false,
                    showCategory: showCategory,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
