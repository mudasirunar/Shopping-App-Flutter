import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/responsive_product_grid.dart';
import '../details/product_details_screen.dart';

class CatalogScreen extends StatefulWidget {
  final VoidCallback? onOpenAccount;
  final VoidCallback? onOpenCart;

  const CatalogScreen({
    super.key,
    this.onOpenAccount,
    this.onOpenCart,
  });

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortModal(BuildContext context) {
    final catalog = context.read<CatalogProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'Sort Products',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: const Icon(Icons.star_outline, color: AppTheme.primary),
                      title: const Text('Featured'),
                      trailing: catalog.sortOption == ProductSortOption.featured
                          ? const Icon(Icons.check, color: AppTheme.primary)
                          : null,
                      onTap: () {
                        catalog.setSortOption(ProductSortOption.featured);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: const Icon(Icons.arrow_upward, color: AppTheme.primary),
                      title: const Text('Price: Low to High'),
                      trailing: catalog.sortOption == ProductSortOption.priceLowToHigh
                          ? const Icon(Icons.check, color: AppTheme.primary)
                          : null,
                      onTap: () {
                        catalog.setSortOption(ProductSortOption.priceLowToHigh);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: const Icon(Icons.arrow_downward, color: AppTheme.primary),
                      title: const Text('Price: High to Low'),
                      trailing: catalog.sortOption == ProductSortOption.priceHighToLow
                          ? const Icon(Icons.check, color: AppTheme.primary)
                          : null,
                      onTap: () {
                        catalog.setSortOption(ProductSortOption.priceHighToLow);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        titleSpacing: 16,
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Shopping App',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 19,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<CatalogProvider>(
        builder: (context, catalog, child) {
          if (catalog.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          final products = catalog.filteredProducts;

          return CustomScrollView(
            slivers: [
              // Header Title & Subtitle Block
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Discover Essentials',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Curated everyday items crafted for quality.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search Input Area
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: catalog.setSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Search products',
                        hintStyle: const TextStyle(color: AppTheme.outline, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: AppTheme.secondary, size: 22),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, color: AppTheme.secondary, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  catalog.setSearchQuery('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 13),
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),

              // Horizontal Category Chips Row
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: catalog.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = catalog.categories[index];
                      final isSelected = catalog.selectedCategory.toLowerCase() == cat.toLowerCase();

                      return InkWell(
                        onTap: () => catalog.selectCategory(cat),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryContainer
                                : AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isSelected
                                ? null
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.secondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Count and Sort Row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${products.length} Products',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.secondary,
                        ),
                      ),
                      InkWell(
                        onTap: () => _showSortModal(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Sort: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.secondary,
                                ),
                              ),
                              Text(
                                _getSortLabel(catalog.sortOption),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: AppTheme.secondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Empty Search Result State
              if (products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: AppTheme.surfaceContainerLow,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.search_off,
                              size: 32,
                              color: AppTheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No items match your query',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Try adjusting your search keywords or switching the category.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(160, 40),
                              backgroundColor: AppTheme.primaryContainer,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              catalog.resetFilters();
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Reset Filters'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ResponsiveProductGrid(
                  products: products,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                  onProductTap: (product) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailsScreen(product: product),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  String _getSortLabel(ProductSortOption option) {
    switch (option) {
      case ProductSortOption.priceLowToHigh:
        return 'Price: Low';
      case ProductSortOption.priceHighToLow:
        return 'Price: High';
      case ProductSortOption.featured:
        return 'Featured';
    }
  }
}

