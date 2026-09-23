import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/app_confirmation_dialog.dart';
import '../../widgets/responsive_product_grid.dart';
import '../details/product_details_screen.dart';
import '../../core/utils/app_snackbar.dart';

enum WishlistSortOption {
  recentlyAdded,
  priceLowToHigh,
  priceHighToLow,
  nameAToZ,
}

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _isGridView = true;
  WishlistSortOption _sortOption = WishlistSortOption.recentlyAdded;

  void _confirmClear(BuildContext context) {
    AppConfirmationDialog.show(
      context: context,
      icon: Icons.delete_sweep_outlined,
      title: 'Clear Wishlist?',
      message: 'Are you sure you want to remove all saved products from your wishlist?',
      confirmLabel: 'Clear All',
      isDestructive: true,
      onConfirm: () {
        context.read<WishlistProvider>().clearWishlist();
        AppSnackBar.show(
          context,
          message: 'Wishlist cleared',
        );
      },
    );
  }

  String _getSortLabel(WishlistSortOption option) {
    switch (option) {
      case WishlistSortOption.recentlyAdded:
        return 'Recently Added';
      case WishlistSortOption.priceLowToHigh:
        return 'Price: Low to High';
      case WishlistSortOption.priceHighToLow:
        return 'Price: High to Low';
      case WishlistSortOption.nameAToZ:
        return 'Name: A to Z';
    }
  }

  List<Product> _getSortedItems(List<Product> raw) {
    final list = List<Product>.from(raw);
    switch (_sortOption) {
      case WishlistSortOption.recentlyAdded:
        return list;
      case WishlistSortOption.priceLowToHigh:
        list.sort((a, b) => a.pricePaisa.compareTo(b.pricePaisa));
        return list;
      case WishlistSortOption.priceHighToLow:
        list.sort((a, b) => b.pricePaisa.compareTo(a.pricePaisa));
        return list;
      case WishlistSortOption.nameAToZ:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return list;
    }
  }

  void _showSortModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Sort Wishlist',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
                const Divider(),
                _buildSortTile(ctx, 'Recently Added', WishlistSortOption.recentlyAdded, Icons.access_time_rounded),
                _buildSortTile(ctx, 'Price: Low to High', WishlistSortOption.priceLowToHigh, Icons.arrow_upward_rounded),
                _buildSortTile(ctx, 'Price: High to Low', WishlistSortOption.priceHighToLow, Icons.arrow_downward_rounded),
                _buildSortTile(ctx, 'Name: A to Z', WishlistSortOption.nameAToZ, Icons.sort_by_alpha_rounded),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortTile(BuildContext ctx, String label, WishlistSortOption option, IconData icon) {
    final isSelected = _sortOption == option;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.secondary, size: 20),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppTheme.primary : AppTheme.onSurface,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_rounded, color: AppTheme.primary) : null,
      onTap: () {
        setState(() {
          _sortOption = option;
        });
        Navigator.pop(ctx);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final items = wishlist.items;
    final sortedItems = _getSortedItems(items);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Wishlist',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.secondary),
              tooltip: 'Clear Wishlist',
              onPressed: () => _confirmClear(context),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.favorite_border_rounded,
                          size: 38,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Your Wishlist is Empty',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Explore our collection and tap the heart icon on any product to save it here for later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.secondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryContainer,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        context.read<NavigationProvider>().openShop();
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Icons.storefront_outlined, size: 18),
                      label: const Text(
                        'Explore Catalog',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                // Count & Toolbar Row (Sort + Shape Changer)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${sortedItems.length} ${sortedItems.length == 1 ? 'Product Saved' : 'Products Saved'}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.secondary,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Sort Button
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
                                      _getSortLabel(_sortOption),
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
                ResponsiveProductGrid(
                  products: sortedItems,
                  isWideView: !_isGridView,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  showCategory: true,
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
            ),
    );
  }
}
