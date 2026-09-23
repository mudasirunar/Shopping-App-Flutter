import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/hero_promotional_carousel.dart';
import '../../widgets/home_curated_carousel_section.dart';
import '../../widgets/voucher_wallet_strip.dart';
import '../collection/curated_collection_screen.dart';
import '../details/product_details_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  final ScrollController? scrollController;
  final VoidCallback? onOpenCart;

  const HomeScreen({
    super.key,
    this.scrollController,
    this.onOpenCart,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Flash Sale Countdown Demo (e.g. 4 hours remaining)
  late Duration _countdown;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdown = const Duration(hours: 4, minutes: 28, seconds: 45);

    // Countdown ticker with auto-looping cycle for continuous flash deal rounds
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdown.inSeconds > 1) {
          _countdown = _countdown - const Duration(seconds: 1);
        } else {
          // When it hits 00:00:00, automatically rolls over to the next 4-hour Flash Deal Round
          _countdown = const Duration(hours: 4, minutes: 0, seconds: 0);
        }
      });
    });
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



  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SearchScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final cart = context.watch<CartProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final nav = context.read<NavigationProvider>();

    if (catalog.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.surface,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    final allProducts = catalog.allProducts;

    // 1. Flash Deals: Curated preview of 6 discount products
    final allDealProducts = allProducts.where((p) => p.hasDiscount).toList();
    final dealProducts = allDealProducts.take(6).toList();
    final dealIds = dealProducts.map((p) => p.id).toSet();

    // 2. Top Rated: 4.7★+, prioritize fresh items not already featured in Flash Deals (curated 6 items)
    final allTopRatedProducts = allProducts.where((p) => p.displayRating >= 4.7).toList();
    final topRatedFresh = allProducts
        .where((p) => p.displayRating >= 4.7 && !dealIds.contains(p.id))
        .toList();
    final topRatedProducts = [
      ...topRatedFresh,
      ...allProducts.where((p) => p.displayRating >= 4.7 && dealIds.contains(p.id)),
    ].take(6).toList();
    final topRatedIds = topRatedProducts.map((p) => p.id).toSet();

    // 3. Fast Delivery: 2-3 days transit, prioritize fresh items not already featured above (curated 6 items)
    final allFastDeliveryProducts = allProducts
        .where((p) => p.effectiveDeliveryDays == 2 || p.effectiveDeliveryDays == 3)
        .toList();
    final fastDeliveryFresh = allProducts
        .where((p) =>
            (p.effectiveDeliveryDays == 2 || p.effectiveDeliveryDays == 3) &&
            !dealIds.contains(p.id) &&
            !topRatedIds.contains(p.id))
        .toList();
    final fastDeliveryProducts = [
      ...fastDeliveryFresh,
      ...allProducts.where((p) =>
          (p.effectiveDeliveryDays == 2 || p.effectiveDeliveryDays == 3) &&
          !fastDeliveryFresh.contains(p)),
    ].take(6).toList();

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
            child: Container(
              color: AppTheme.surface.withOpacity(0.65),
            ),
          ),
        ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Shopping App',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 19,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
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
            onPressed: () => widget.onOpenCart != null
                ? widget.onOpenCart!()
                : nav.openCart(),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: AppSearchBar.trigger(
              onTap: () => _openSearch(context),
              hintText: 'Search products, electronics, deals...',
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        controller: widget.scrollController,
        slivers: [
          // Top spacer to push content below the frosted glass AppBar + search bar
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).padding.top + kToolbarHeight + 52,
            ),
          ),

          // 1. Hero Promotional Carousel
          const SliverToBoxAdapter(
            child: HeroPromotionalCarousel(),
          ),

          // 3. Voucher Codes Wallet Strip
          const SliverToBoxAdapter(
            child: VoucherWalletStrip(),
          ),

          // 4. Category Quick Rail
          SliverToBoxAdapter(
            child: _buildCategoryQuickRail(nav),
          ),

          // 5. Flash Deals Section (Countdown & Strike-Through Pricing)
          if (dealProducts.isNotEmpty)
            SliverToBoxAdapter(
              child: HomeCuratedCarouselSection(
                title: 'Flash Deals',
                icon: Icons.flash_on_rounded,
                iconColor: const Color(0xFFDC2626),
                badge: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 12, color: Color(0xFFDC2626)),
                      const SizedBox(width: 3),
                      Text(
                        _formatDuration(_countdown),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
                products: dealProducts,
                totalCollectionCount: allDealProducts.length,
                showOriginalPrice: true,
                badgeTagBuilder: (p) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.effectiveDealTag ?? '-${p.discountPercent}%',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                onViewAll: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CuratedCollectionScreen(
                        collectionType: CuratedCollectionType.flashDeals,
                        initialCountdown: _countdown,
                      ),
                    ),
                  );
                },
              ),
            ),

          // 6. Curated Spotlight Dual Tiles
          SliverToBoxAdapter(
            child: _buildSpotlightTiles(nav),
          ),

          // 7. Top Rated / Editor's Pick Section
          if (topRatedProducts.isNotEmpty)
            SliverToBoxAdapter(
              child: HomeCuratedCarouselSection(
                title: 'Top Rated',
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFF59E0B),
                badge: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 11, color: Color(0xFFD97706)),
                      SizedBox(width: 2),
                      Text(
                        '4.7★+',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
                products: topRatedProducts,
                totalCollectionCount: allTopRatedProducts.length,
                badgeTagBuilder: (p) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 12),
                      const SizedBox(width: 2),
                      Text(
                        '${p.displayRating}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                onViewAll: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CuratedCollectionScreen(
                        collectionType: CuratedCollectionType.topRated,
                      ),
                    ),
                  );
                },
              ),
            ),

          // 8. Fast Delivery Section (2-3 Days Transit)
          if (fastDeliveryProducts.isNotEmpty)
            SliverToBoxAdapter(
              child: HomeCuratedCarouselSection(
                title: 'Fast Delivery',
                icon: Icons.bolt_rounded,
                iconColor: const Color(0xFF059669),
                badge: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 12, color: Color(0xFF059669)),
                      SizedBox(width: 2),
                      Text(
                        '2-3 Days',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
                products: fastDeliveryProducts,
                totalCollectionCount: allFastDeliveryProducts.length,
                badgeTagBuilder: (p) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, color: Colors.white, size: 11),
                      Text(
                        '${p.effectiveDeliveryDays}d',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                onViewAll: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CuratedCollectionScreen(
                        collectionType: CuratedCollectionType.fastDelivery,
                      ),
                    ),
                  );
                },
              ),
            ),

          // 9. "Browse Full Catalog" Invitation Banner
          SliverToBoxAdapter(
            child: _buildFullCatalogInvitation(nav, allProducts),
          ),

          // Bottom padding for navigation bar
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }





  // ---------------------------------------------------------------------------
  // Category Quick Rail
  // ---------------------------------------------------------------------------
  Widget _buildCategoryQuickRail(NavigationProvider nav) {
    final categories = [
      {'name': 'All', 'icon': Icons.apps_rounded, 'color': const Color(0xFF1E293B)},
      {'name': 'Electronics', 'icon': Icons.devices_rounded, 'color': const Color(0xFF0284C7)},
      {'name': 'Fashion', 'icon': Icons.checkroom_rounded, 'color': const Color(0xFFE11D48)},
      {'name': 'Home & Living', 'icon': Icons.chair_rounded, 'color': const Color(0xFFD97706)},
      {'name': 'Beauty & Grooming', 'icon': Icons.spa_rounded, 'color': const Color(0xFFDB2777)},
      {'name': 'Footwear', 'icon': Icons.snowshoeing_rounded, 'color': const Color(0xFF059669)},
      {'name': 'Accessories', 'icon': Icons.watch_rounded, 'color': const Color(0xFF7C3AED)},
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Shop by Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () => nav.openExplore('All'),
                  child: const Text('See All Catalog', style: TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final c = categories[index];
                final name = c['name'] as String;
                final icon = c['icon'] as IconData;
                final color = c['color'] as Color;

                return InkWell(
                  onTap: () => nav.openExplore(name),
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.09),
                          shape: BoxShape.circle,
                          border: Border.all(color: color.withOpacity(0.25), width: 1.2),
                        ),
                        child: Center(
                          child: Icon(icon, color: color, size: 26),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 68,
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }



  // ---------------------------------------------------------------------------
  // Spotlight Dual Tiles
  // ---------------------------------------------------------------------------
  Widget _buildSpotlightTiles(NavigationProvider nav) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => nav.openExplore('Electronics'),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.headphones_rounded, color: Color(0xFF38BDF8), size: 24),
                    SizedBox(height: 10),
                    Text(
                      'Next-Gen Audio',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'ANC & Hi-Res Sound',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => nav.openExplore('Home & Living'),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF831843), Color(0xFF500724)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.coffee_maker_rounded, color: Color(0xFFF472B6), size: 24),
                    SizedBox(height: 10),
                    Text(
                      'Modern Living',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Artisan Essentials',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  // ---------------------------------------------------------------------------
  // Full Catalog Showcase & Master Navigation Gateway
  // ---------------------------------------------------------------------------
  Widget _buildFullCatalogInvitation(NavigationProvider nav, List<Product> products) {
    // Pick 4 diverse products across different categories, favoring fresh items not featured as top deals
    final showcaseProducts = <Product>[];
    final seenCategories = <String>{};

    for (final p in products) {
      if (!seenCategories.contains(p.category) &&
          p.id != 'prod-001' &&
          showcaseProducts.length < 4) {
        showcaseProducts.add(p);
        seenCategories.add(p.category);
      }
    }
    if (showcaseProducts.length < 4 && products.isNotEmpty) {
      for (final p in products) {
        if (!showcaseProducts.contains(p) && showcaseProducts.length < 4) {
          showcaseProducts.add(p);
        }
      }
    }

    final avatarProducts = showcaseProducts.take(3).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1), size: 18),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'More From The Catalog',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.onSurface,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Curated picks from 50+ items across 6 departments',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.secondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => nav.openExplore('All'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View All', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded, size: 13),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 2x2 Showcase Product Grid
          if (showcaseProducts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildShowcaseCard(showcaseProducts[0])),
                  if (showcaseProducts.length > 1) ...[
                    const SizedBox(width: 12),
                    Expanded(child: _buildShowcaseCard(showcaseProducts[1])),
                  ],
                ],
              ),
            ),
          if (showcaseProducts.length > 2) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildShowcaseCard(showcaseProducts[2])),
                  if (showcaseProducts.length > 3) ...[
                    const SizedBox(width: 12),
                    Expanded(child: _buildShowcaseCard(showcaseProducts[3])),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Master "Explore All Collections" Navigation Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: () => nav.openExplore('All'),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E1B4B).withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.35),
                    width: 1.2,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge & Avatar Stack Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.explore_rounded, size: 12, color: Color(0xFFA5B4FC)),
                              SizedBox(width: 5),
                              Text(
                                '50+ PRODUCTS IN CATALOG',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFA5B4FC),
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Overlapping Avatar Stack
                        _buildAvatarStack(avatarProducts),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Title & Description
                    const Text(
                      'Explore Complete Catalog',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Search, sort by price & rating, or jump directly into any department.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withOpacity(0.75),
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Category Quick Filter Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildExploreChip('Electronics', Icons.devices_rounded, nav),
                        _buildExploreChip('Fashion', Icons.checkroom_rounded, nav),
                        _buildExploreChip('Home & Living', Icons.chair_rounded, nav),
                        _buildExploreChip('Beauty & Grooming', Icons.spa_rounded, nav),
                        _buildExploreChip('Footwear', Icons.snowshoeing_rounded, nav),
                        _buildExploreChip('Accessories', Icons.watch_rounded, nav),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Primary Navigation Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => nav.openExplore('All'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F172A),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.explore_rounded, size: 18, color: Color(0xFF4F46E5)),
                            SizedBox(width: 8),
                            Text(
                              'Browse Full 50+ Catalog',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.1,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF0F172A)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowcaseCard(Product p) {
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
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Category Tag and Discount Badge
            AspectRatio(
              aspectRatio: 1.15,
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
                  // Top-Left: Discount Tag (if available) or Category Tag
                  if (p.hasDiscount)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          '-${p.discountPercent}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  // Bottom-Left (or Top-Left if no discount): Category Chip
                  Positioned(
                    top: p.hasDiscount ? null : 6,
                    bottom: p.hasDiscount ? 6 : null,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.72),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Title
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
            const SizedBox(height: 6),
            // Price & Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CurrencyFormatter.formatPaisa(p.pricePaisa),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                    if (p.hasDiscount)
                      Text(
                        CurrencyFormatter.formatPaisa(p.originalPricePaisa!),
                        style: TextStyle(
                          fontSize: 9.5,
                          color: AppTheme.secondary.withOpacity(0.7),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 2),
                    Text(
                      '${p.displayRating}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStack(List<Product> products) {
    final count = products.length.clamp(0, 3);
    const itemSize = 30.0;
    const overlap = 18.0;
    final totalWidth = (count * overlap) + 36.0;

    return SizedBox(
      width: totalWidth,
      height: itemSize,
      child: Stack(
        children: [
          for (int i = 0; i < count; i++)
            Positioned(
              left: i * overlap,
              child: Container(
                width: itemSize,
                height: itemSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: AppNetworkImage(
                    imageUrl: products[i].image,
                    fit: BoxFit.cover,
                    category: products[i].category,
                  ),
                ),
              ),
            ),
          Positioned(
            left: count * overlap,
            child: Container(
              width: itemSize,
              height: itemSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Center(
                child: Text(
                  '+46',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreChip(String category, IconData icon, NavigationProvider nav) {
    return InkWell(
      onTap: () => nav.openExplore(category),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white70),
            const SizedBox(width: 5),
            Text(
              category,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded, size: 8, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}


