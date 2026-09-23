import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/app_network_image.dart';
import '../details/product_details_screen.dart';
import '../search/search_screen.dart';

/// The 3 distinct curated collection types
enum CuratedCollectionType {
  flashDeals,
  topRated,
  fastDelivery,
}

enum CuratedSortOption {
  featured,
  highlightPriority, // Highest Discount / Highest Rated / Fastest Delivery
  priceLowToHigh,
  priceHighToLow,
  nameAToZ,
}

class CuratedCollectionScreen extends StatefulWidget {
  final CuratedCollectionType collectionType;
  final Duration? initialCountdown;

  const CuratedCollectionScreen({
    super.key,
    required this.collectionType,
    this.initialCountdown,
  });

  @override
  State<CuratedCollectionScreen> createState() => _CuratedCollectionScreenState();
}

class _CuratedCollectionScreenState extends State<CuratedCollectionScreen> {
  String _selectedCategory = 'All';
  CuratedSortOption _sortOption = CuratedSortOption.highlightPriority;
  bool _isGridView = true;

  // Flash Deals Countdown Timer
  late Duration _countdown;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdown = widget.initialCountdown ?? const Duration(hours: 4, minutes: 28, seconds: 45);

    if (widget.collectionType == CuratedCollectionType.flashDeals) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          if (_countdown.inSeconds > 1) {
            _countdown = _countdown - const Duration(seconds: 1);
          } else {
            _countdown = const Duration(hours: 6);
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  // Configuration helpers for the 3 collections
  String get _title {
    switch (widget.collectionType) {
      case CuratedCollectionType.flashDeals:
        return 'Flash Deals';
      case CuratedCollectionType.topRated:
        return 'Top Rated Collection';
      case CuratedCollectionType.fastDelivery:
        return 'Fast Delivery';
    }
  }

  String get _subtitle {
    switch (widget.collectionType) {
      case CuratedCollectionType.flashDeals:
        return 'Limited-time special prices with up to 35% discount';
      case CuratedCollectionType.topRated:
        return 'Customer favorites rated 4.7★ and above with verified reviews';
      case CuratedCollectionType.fastDelivery:
        return 'Express courier items guaranteed to arrive in 2–3 business days';
    }
  }

  Color get _accentColor {
    switch (widget.collectionType) {
      case CuratedCollectionType.flashDeals:
        return const Color(0xFFDC2626);
      case CuratedCollectionType.topRated:
        return const Color(0xFFD97706);
      case CuratedCollectionType.fastDelivery:
        return const Color(0xFF059669);
    }
  }

  IconData get _icon {
    switch (widget.collectionType) {
      case CuratedCollectionType.flashDeals:
        return Icons.flash_on_rounded;
      case CuratedCollectionType.topRated:
        return Icons.star_rounded;
      case CuratedCollectionType.fastDelivery:
        return Icons.bolt_rounded;
    }
  }

  String get _highlightSortLabel {
    switch (widget.collectionType) {
      case CuratedCollectionType.flashDeals:
        return 'Biggest Discount (%)';
      case CuratedCollectionType.topRated:
        return 'Highest Rated (★)';
      case CuratedCollectionType.fastDelivery:
        return 'Fastest Delivery';
    }
  }

  // Filter products by collection type
  List<Product> _getCollectionProducts(List<Product> all) {
    switch (widget.collectionType) {
      case CuratedCollectionType.flashDeals:
        return all.where((p) => p.hasDiscount).toList();
      case CuratedCollectionType.topRated:
        return all.where((p) => p.displayRating >= 4.7).toList();
      case CuratedCollectionType.fastDelivery:
        return all
            .where((p) => p.effectiveDeliveryDays == 2 || p.effectiveDeliveryDays == 3)
            .toList();
    }
  }

  List<Product> _applyFiltersAndSort(List<Product> collectionItems) {
    // 1. Category Filter
    List<Product> filtered = collectionItems;
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((p) => p.category.trim().toLowerCase() == _selectedCategory.trim().toLowerCase())
          .toList();
    }

    // 2. Sorting
    final list = List<Product>.from(filtered);
    switch (_sortOption) {
      case CuratedSortOption.highlightPriority:
        if (widget.collectionType == CuratedCollectionType.flashDeals) {
          list.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
        } else if (widget.collectionType == CuratedCollectionType.topRated) {
          list.sort((a, b) => b.displayRating.compareTo(a.displayRating));
        } else {
          list.sort((a, b) => a.effectiveDeliveryDays.compareTo(b.effectiveDeliveryDays));
        }
        break;
      case CuratedSortOption.featured:
        // Keep catalog order
        break;
      case CuratedSortOption.priceLowToHigh:
        list.sort((a, b) => a.pricePaisa.compareTo(b.pricePaisa));
        break;
      case CuratedSortOption.priceHighToLow:
        list.sort((a, b) => b.pricePaisa.compareTo(a.pricePaisa));
        break;
      case CuratedSortOption.nameAToZ:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }
    return list;
  }

  void _showSortSheet(BuildContext context) {
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Sort $_title',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
                const Divider(),
                _buildSortTile(ctx, 'Highlight: $_highlightSortLabel', CuratedSortOption.highlightPriority, _icon),
                _buildSortTile(ctx, 'Featured', CuratedSortOption.featured, Icons.auto_awesome_rounded),
                _buildSortTile(ctx, 'Price: Low to High', CuratedSortOption.priceLowToHigh, Icons.arrow_upward_rounded),
                _buildSortTile(ctx, 'Price: High to Low', CuratedSortOption.priceHighToLow, Icons.arrow_downward_rounded),
                _buildSortTile(ctx, 'Name: A to Z', CuratedSortOption.nameAToZ, Icons.sort_by_alpha_rounded),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortTile(BuildContext ctx, String label, CuratedSortOption option, IconData icon) {
    final isSelected = _sortOption == option;
    return ListTile(
      leading: Icon(icon, color: isSelected ? _accentColor : AppTheme.secondary, size: 20),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? _accentColor : AppTheme.onSurface,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check_rounded, color: _accentColor) : null,
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
    final catalog = context.watch<CatalogProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final cart = context.watch<CartProvider>();

    if (catalog.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          backgroundColor: AppTheme.surface,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    final collectionItems = _getCollectionProducts(catalog.allProducts);

    // Extract categories represented within this collection
    final categoriesSet = <String>{};
    for (final p in collectionItems) {
      if (p.category.trim().isNotEmpty) {
        categoriesSet.add(p.category.trim());
      }
    }
    final availableCategories = ['All', ...(categoriesSet.toList()..sort())];

    final displayProducts = _applyFiltersAndSort(collectionItems);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: AppTheme.surface,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _title,
          style: const TextStyle(
            color: AppTheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          // Search Trigger
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppTheme.onSurface, size: 22),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          // Wishlist Shortcut
          IconButton(
            icon: Badge(
              isLabelVisible: wishlist.itemCount > 0,
              backgroundColor: AppTheme.primary,
              label: Text('${wishlist.itemCount}'),
              child: const Icon(Icons.favorite_outline_rounded, color: AppTheme.onSurface, size: 22),
            ),
            onPressed: () => AppNavigator.openWishlist(),
          ),
          // Cart Shortcut
          IconButton(
            icon: Badge(
              isLabelVisible: cart.totalItemCount > 0,
              backgroundColor: const Color(0xFFFF3B30),
              label: Text('${cart.totalItemCount}'),
              child: const Icon(Icons.shopping_cart_outlined, color: AppTheme.onSurface, size: 22),
            ),
            onPressed: () => AppNavigator.openCart(),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Dynamic Hero Collection Banner
          SliverToBoxAdapter(
            child: _buildHeroBanner(collectionItems.length),
          ),

          // 2. In-Collection Category Filter Chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 8),
              child: SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: availableCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = availableCategories[index];
                    final isSelected = _selectedCategory.toLowerCase() == cat.toLowerCase();

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? _accentColor : AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? _accentColor
                                : AppTheme.outlineVariant.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12.5,
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
          ),

          // 3. Toolbar: Results Count, Sort Button, and Grid/List View Toggle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Row(
                children: [
                  Text(
                    '${displayProducts.length} ${displayProducts.length == 1 ? "item" : "items"} available',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondary.withOpacity(0.9),
                    ),
                  ),
                  const Spacer(),
                  // Sort Trigger
                  InkWell(
                    onTap: () => _showSortSheet(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sort_rounded, size: 15, color: _accentColor),
                          const SizedBox(width: 4),
                          const Text(
                            'Sort',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Grid / List View Toggle
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isGridView = !_isGridView;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(5.5),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.6)),
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
            ),
          ),

          // 4. Products Presentation (Grid vs Wide Curated Cards)
          if (displayProducts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined, size: 48, color: AppTheme.secondary.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      Text(
                        'No products found in "$_selectedCategory"',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategory = 'All';
                          });
                        },
                        child: const Text('Reset category filter'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_isGridView)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = displayProducts[index];
                    return _buildGridCard(product);
                  },
                  childCount: displayProducts.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = displayProducts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildWideCard(product),
                    );
                  },
                  childCount: displayProducts.length,
                ),
              ),
            ),

          // Bottom Spacing for comfort
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dynamic Hero Banner
  // ---------------------------------------------------------------------------
  Widget _buildHeroBanner(int totalCount) {
    switch (widget.collectionType) {
      case CuratedCollectionType.flashDeals:
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF991B1B), Color(0xFFDC2626), Color(0xFFB45309)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDC2626).withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, size: 14, color: Colors.amberAccent),
                        const SizedBox(width: 4),
                        Text(
                          '$totalCount Deals Live',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Live Timer Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 13, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          _formatDuration(_countdown),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Exclusive Flash Deals',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        );

      case CuratedCollectionType.topRated:
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF334155), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD97706).withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 14, color: Color(0xFFF59E0B)),
                        SizedBox(width: 4),
                        Text(
                          '4.7+ Rating Guaranteed',
                          style: TextStyle(
                            color: Color(0xFFFDE68A),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 3),
                        Text(
                          '$totalCount Curated Picks',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Top Rated Customer Favorites',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        );

      case CuratedCollectionType.fastDelivery:
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF065F46), Color(0xFF059669), Color(0xFF0D9488)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flight_takeoff_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Insured Air Express',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, size: 14, color: Colors.amberAccent),
                        const SizedBox(width: 2),
                        Text(
                          '$totalCount In-Stock Items',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Fast Track Courier Dispatch',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Context-Aware Grid Card (High Visual Relevance)
  // ---------------------------------------------------------------------------
  Widget _buildGridCard(Product p) {
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
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.55)),
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
          children: [
            // Image with Contextual Badge
            Expanded(
              flex: 11,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AppNetworkImage(
                      imageUrl: p.image,
                      fit: BoxFit.cover,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      category: p.category,
                    ),
                  ),
                  // Differentiator Pill at Top-Left
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _buildContextBadge(p),
                  ),
                ],
              ),
            ),

            // Card Body (Metadata & Pricing)
            Expanded(
              flex: 8,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product Title
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                        height: 1.25,
                      ),
                    ),

                    // Contextual Supporting Row (Category or Specs)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.category.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: AppTheme.secondary.withOpacity(0.8),
                            ),
                          ),
                        ),
                        if (widget.collectionType == CuratedCollectionType.topRated) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 2),
                          Text(
                            '${p.displayRating}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Pricing Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 5,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              CurrencyFormatter.formatPaisa(p.pricePaisa),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: widget.collectionType == CuratedCollectionType.flashDeals
                                    ? const Color(0xFFDC2626)
                                    : AppTheme.primary,
                              ),
                            ),
                            if (p.hasDiscount)
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
                        // Savings text for Flash Deals
                        if (widget.collectionType == CuratedCollectionType.flashDeals && p.hasDiscount)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Save ${CurrencyFormatter.formatPaisa(p.originalPricePaisa! - p.pricePaisa)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Context-Aware Wide Card (Rich List View)
  // ---------------------------------------------------------------------------
  Widget _buildWideCard(Product p) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: p),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.55)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail with Highlight Badge
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AppNetworkImage(
                      imageUrl: p.image,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(12),
                      category: p.category,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: _buildContextBadge(p, isCompact: true),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // Information Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Rating Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.outlineVariant.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          p.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: AppTheme.secondary.withOpacity(0.9),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 2),
                      Text(
                        '${p.displayRating}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  // Title
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Price Row with Savings or Delivery Details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 2,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  CurrencyFormatter.formatPaisa(p.pricePaisa),
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: widget.collectionType == CuratedCollectionType.flashDeals
                                        ? const Color(0xFFDC2626)
                                        : AppTheme.primary,
                                  ),
                                ),
                                if (p.hasDiscount)
                                  Text(
                                    CurrencyFormatter.formatPaisa(p.originalPricePaisa!),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.secondary.withOpacity(0.7),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                              ],
                            ),
                            if (widget.collectionType == CuratedCollectionType.flashDeals && p.hasDiscount)
                              Text(
                                'Save ${CurrencyFormatter.formatPaisa(p.originalPricePaisa! - p.pricePaisa)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF059669),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Delivery Transit Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_shipping_outlined, size: 11, color: Color(0xFF059669)),
                            const SizedBox(width: 3),
                            Text(
                              '${p.effectiveDeliveryDays}d transit',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  // Helper to build the contextual image badge
  Widget _buildContextBadge(Product p, {bool isCompact = false}) {
    switch (widget.collectionType) {
      case CuratedCollectionType.flashDeals:
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 5 : 6,
            vertical: isCompact ? 2 : 2.5,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            p.effectiveDealTag ?? '-${p.discountPercent}%',
            style: TextStyle(
              fontSize: isCompact ? 8.5 : 9.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        );

      case CuratedCollectionType.topRated:
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 5 : 6,
            vertical: isCompact ? 2 : 2.5,
          ),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, color: const Color(0xFFF59E0B), size: isCompact ? 11 : 12),
              const SizedBox(width: 2),
              Text(
                '${p.displayRating}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isCompact ? 8.5 : 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );

      case CuratedCollectionType.fastDelivery:
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 5 : 6,
            vertical: isCompact ? 2 : 2.5,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF059669),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, color: Colors.white, size: isCompact ? 10 : 12),
              const SizedBox(width: 1),
              Text(
                '${p.effectiveDeliveryDays} Days',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isCompact ? 8.5 : 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
    }
  }
}
