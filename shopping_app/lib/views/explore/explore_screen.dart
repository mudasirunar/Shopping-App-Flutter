import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/catalog_interlude_strip.dart';
import '../../widgets/explore_category_banner.dart';
import '../../widgets/explore_spotlight_card.dart';
import '../../widgets/explore_story_rail.dart';
import '../../widgets/product_card.dart';
import '../../widgets/responsive_product_grid.dart';
import '../details/product_details_screen.dart';
import '../search/search_screen.dart';

class ExploreScreen extends StatefulWidget {
  final ScrollController? scrollController;
  final VoidCallback? onOpenCart;

  const ExploreScreen({super.key, this.scrollController, this.onOpenCart});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTargetCategory();
    });
  }

  void _checkTargetCategory() {
    final nav = context.read<NavigationProvider>();
    final targetCat = nav.targetExploreCategory;
    if (targetCat != null && targetCat.isNotEmpty) {
      final catalog = context.read<CatalogProvider>();
      catalog.selectCategory(targetCat);
      nav.clearTargetExploreCategory();
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
                    leading: const Icon(
                      Icons.star_outline,
                      color: AppTheme.primary,
                    ),
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
                    leading: const Icon(
                      Icons.arrow_upward,
                      color: AppTheme.primary,
                    ),
                    title: const Text('Price: Low to High'),
                    trailing:
                        catalog.sortOption == ProductSortOption.priceLowToHigh
                        ? const Icon(Icons.check, color: AppTheme.primary)
                        : null,
                    onTap: () {
                      catalog.setSortOption(ProductSortOption.priceLowToHigh);
                      Navigator.pop(ctx);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.arrow_downward,
                      color: AppTheme.primary,
                    ),
                    title: const Text('Price: High to Low'),
                    trailing:
                        catalog.sortOption == ProductSortOption.priceHighToLow
                        ? const Icon(Icons.check, color: AppTheme.primary)
                        : null,
                    onTap: () {
                      catalog.setSortOption(ProductSortOption.priceHighToLow);
                      Navigator.pop(ctx);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.sort_by_alpha_rounded,
                      color: AppTheme.primary,
                    ),
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
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SearchScreen()));
  }

  void _openProduct(BuildContext context, product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for any new target category arriving from navigation
    final nav = context.watch<NavigationProvider>();
    final cart = context.watch<CartProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final target = nav.targetExploreCategory;
    if (target != null && target.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<CatalogProvider>().selectCategory(target);
        context.read<NavigationProvider>().clearTargetExploreCategory();
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        titleSpacing: 16,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(color: AppTheme.surface.withOpacity(0.65)),
          ),
        ),
        title: const Text(
          'Explore Catalog',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          // Wishlist Shortcut
          IconButton(
            icon: Badge(
              isLabelVisible: wishlist.itemCount > 0,
              backgroundColor: AppTheme.primary,
              label: Text('${wishlist.itemCount}'),
              child: const Icon(
                Icons.favorite_outline_rounded,
                color: AppTheme.onSurface,
                size: 22,
              ),
            ),
            onPressed: () => AppNavigator.openWishlist(),
          ),
          // Cart Shortcut
          IconButton(
            icon: Badge(
              isLabelVisible: cart.totalItemCount > 0,
              backgroundColor: const Color(0xFFFF3B30),
              label: Text('${cart.totalItemCount}'),
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: AppTheme.onSurface,
                size: 22,
              ),
            ),
            onPressed: () => widget.onOpenCart != null
                ? widget.onOpenCart!()
                : AppNavigator.openCart(),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: AppSearchBar.trigger(
              onTap: () => _openSearchScreen(context),
              hintText: 'Search in full catalog...',
            ),
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
          final showCategory =
              catalog.selectedCategory.trim().toLowerCase() == 'all';

          // Split products: spotlight (first), first batch (next 4), remaining
          final spotlightProduct = products.isNotEmpty ? products.first : null;
          final afterSpotlight = products.length > 1
              ? products.sublist(1)
              : <dynamic>[];
          final firstBatch = afterSpotlight.length > 4
              ? afterSpotlight.sublist(0, 4)
              : afterSpotlight;
          final remainingProducts = afterSpotlight.length > 4
              ? afterSpotlight.sublist(4)
              : <dynamic>[];

          final topPadding = MediaQuery.of(context).padding.top;
          final double appBarBottom = topPadding > (kToolbarHeight + 52)
              ? topPadding
              : topPadding + kToolbarHeight + 52;

          return CustomScrollView(
            controller: widget.scrollController,
            slivers: [
              // Top spacer for frosted glass AppBar + search bar
              SliverToBoxAdapter(child: SizedBox(height: appBarBottom + 6)),

              // 1. Story-Style Category Rail
              SliverToBoxAdapter(
                child: ExploreStoryRail(
                  categories: catalog.categories,
                  selectedCategory: catalog.selectedCategory,
                  onCategorySelected: (cat) {
                    catalog.selectCategory(cat);
                  },
                ),
              ),

              // 2. Dynamic Category Editorial Hero Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: ExploreCategoryBanner(
                    selectedCategory: catalog.selectedCategory,
                    productCount: products.length,
                  ),
                ),
              ),

              // 3. Toolbar Row (Sort + Shape Changer)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () => _showSortModal(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.outlineVariant.withOpacity(0.4),
                            ),
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
                            border: Border.all(
                              color: AppTheme.outlineVariant.withOpacity(0.4),
                            ),
                          ),
                          child: Icon(
                            _isGridView
                                ? Icons.view_list_rounded
                                : Icons.grid_view_rounded,
                            size: 18,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Empty State
              if (products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: AppTheme.secondary,
                          ),
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
                ),

              // 4. Editor's Spotlight Pick (Hero Card for #1 product)
              if (spotlightProduct != null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ExploreSpotlightCard(
                      product: spotlightProduct,
                      onTap: () => _openProduct(context, spotlightProduct),
                    ),
                  ),
                ),
              ],

              // 5. First batch of products (up to 4)
              if (firstBatch.isNotEmpty)
                _buildProductBatch(firstBatch, showCategory),

              // 6. Ambient Catalog Interlude / Promo Break
              if (remainingProducts.isNotEmpty)
                const SliverToBoxAdapter(child: CatalogInterludeStrip()),

              // 7. Remaining products
              if (remainingProducts.isNotEmpty)
                ResponsiveProductGrid(
                  products: List.from(remainingProducts),
                  isWideView: !_isGridView,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                  showCategory: showCategory,
                  onProductTap: (product) => _openProduct(context, product),
                ),

              // Bottom padding if no remaining products
              if (remainingProducts.isEmpty && firstBatch.isNotEmpty)
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          );
        },
      ),
    );
  }

  /// Builds a small batch of product cards (used for the first 4 items).
  Widget _buildProductBatch(List products, bool showCategory) {
    if (!_isGridView) {
      // Wide view: each card takes full width
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProductCard(
                product: p,
                onTap: () => _openProduct(context, p),
                isWide: true,
                showCategory: showCategory,
              ),
            );
          },
        ),
      );
    }

    // Grid view: 2 columns with smart last-row expansion
    final rowCount = (products.length / 2).ceil();
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.builder(
        itemCount: rowCount,
        itemBuilder: (context, rowIndex) {
          final firstIndex = rowIndex * 2;
          final secondIndex = firstIndex + 1;
          final hasSecond = secondIndex < products.length;

          final p1 = products[firstIndex];

          if (!hasSecond) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProductCard(
                product: p1,
                onTap: () => _openProduct(context, p1),
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
                    onTap: () => _openProduct(context, p1),
                    isWide: false,
                    showCategory: showCategory,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ProductCard(
                    product: p2,
                    onTap: () => _openProduct(context, p2),
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
