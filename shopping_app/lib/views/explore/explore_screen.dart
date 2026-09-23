import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/responsive_product_grid.dart';
import '../details/product_details_screen.dart';
import '../search/search_screen.dart';

class ExploreScreen extends StatefulWidget {
  final ScrollController? scrollController;
  final VoidCallback? onOpenCart;

  const ExploreScreen({
    super.key,
    this.scrollController,
    this.onOpenCart,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ScrollController _categoryScrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTargetCategory();
    });
  }

  @override
  void dispose() {
    _categoryScrollController.dispose();
    super.dispose();
  }

  void _scrollToCategory(String cat) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _categoryKeys[cat];
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.5, // Centers the selected chip horizontally in the viewport
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _checkTargetCategory() {
    final nav = context.read<NavigationProvider>();
    final targetCat = nav.targetExploreCategory;
    if (targetCat != null && targetCat.isNotEmpty) {
      final catalog = context.read<CatalogProvider>();
      catalog.selectCategory(targetCat);
      nav.clearTargetExploreCategory();
      _scrollToCategory(targetCat);
    } else {
      final catalog = context.read<CatalogProvider>();
      if (catalog.selectedCategory.toLowerCase() != 'all') {
        _scrollToCategory(catalog.selectedCategory);
      }
    }
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
                  ListTile(
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
                  ListTile(
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
                  ListTile(
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
                  ListTile(
                    leading: const Icon(Icons.sort_by_alpha_rounded, color: AppTheme.primary),
                    title: const Text('Name: A to Z'),
                    trailing: catalog.sortOption == ProductSortOption.nameAToZ
                        ? const Icon(Icons.check, color: AppTheme.primary)
                        : null,
                    onTap: () {
                      catalog.setSortOption(ProductSortOption.nameAToZ);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getSortLabel(ProductSortOption option) {
    switch (option) {
      case ProductSortOption.featured:
        return 'Featured';
      case ProductSortOption.priceLowToHigh:
        return 'Price: Low to High';
      case ProductSortOption.priceHighToLow:
        return 'Price: High to Low';
      case ProductSortOption.nameAToZ:
        return 'Name: A to Z';
    }
  }

  void _openSearchScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SearchScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for any new target category arriving from navigation
    final nav = context.watch<NavigationProvider>();
    final target = nav.targetExploreCategory;
    if (target != null && target.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<CatalogProvider>().selectCategory(target);
        context.read<NavigationProvider>().clearTargetExploreCategory();
        _scrollToCategory(target);
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        titleSpacing: 16,
        backgroundColor: AppTheme.surface,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Explore Catalog',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.4,
          ),
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
            controller: widget.scrollController,
            slivers: [
              // Search Launch Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: AppSearchBar.trigger(
                    onTap: () => _openSearchScreen(context),
                    hintText: 'Search in full catalog...',
                  ),
                ),
              ),

              // Horizontal Category Chips Row
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 38,
                  child: ListView.separated(
                    controller: _categoryScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: catalog.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = catalog.categories[index];
                      final isSelected =
                          catalog.selectedCategory.toLowerCase() == cat.toLowerCase();

                      final chipKey = _categoryKeys.putIfAbsent(cat, () => GlobalKey());

                      return InkWell(
                        key: chipKey,
                        onTap: () {
                          catalog.selectCategory(cat);
                          _scrollToCategory(cat);
                        },
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
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryContainer
                                  : AppTheme.outlineVariant.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : AppTheme.onSurface,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Count & Sort Row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${products.length} Products Available',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondary,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => _showSortModal(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.4)),
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
                          const SizedBox(width: 8),
                          // Shape Changing View Toggle Button
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isGridView = !_isGridView;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.4)),
                              ),
                              child: Icon(
                                _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                                size: 18,
                                color: AppTheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Products Grid or Empty State
              if (products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox_outlined, size: 48, color: AppTheme.secondary),
                          const SizedBox(height: 12),
                          const Text(
                            'No products found in this category',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: catalog.resetFilters,
                            child: const Text('Show All Products'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ResponsiveProductGrid(
                  products: products,
                  isWideView: !_isGridView,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                  showCategory: catalog.selectedCategory.trim().toLowerCase() == 'all',
                  onProductTap: (product) {
                    Navigator.of(context).push(
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
}
