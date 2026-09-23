import 'package:flutter/material.dart';

/// Data model for each category's editorial banner content.
class _BannerContent {
  final String headline;
  final String subtitle;
  final String perkLabel;
  final IconData perkIcon;
  final List<Color> gradientColors;

  const _BannerContent({
    required this.headline,
    required this.subtitle,
    required this.perkLabel,
    required this.perkIcon,
    required this.gradientColors,
  });
}

/// A dynamic editorial hero banner that adapts its gradient, headline,
/// subtitle, and perk badge whenever the user switches categories.
/// Uses AnimatedSwitcher for smooth cross-fade transitions.
class ExploreCategoryBanner extends StatelessWidget {
  final String selectedCategory;
  final int productCount;

  const ExploreCategoryBanner({
    super.key,
    required this.selectedCategory,
    required this.productCount,
  });

  static const Map<String, _BannerContent> _banners = {
    'All': _BannerContent(
      headline: 'Full 2026 Collection',
      subtitle: 'Curated Pieces across 6 Departments',
      perkLabel: 'Curated Selection',
      perkIcon: Icons.diamond_outlined,
      gradientColors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    ),
    'Electronics': _BannerContent(
      headline: 'Next-Gen Tech & Audio',
      subtitle: 'Smart Living, Wearables & Precision Audio',
      perkLabel: '1-Year Warranty',
      perkIcon: Icons.verified_outlined,
      gradientColors: [Color(0xFF1E1B4B), Color(0xFF1D4ED8)],
    ),
    'Fashion': _BannerContent(
      headline: 'Contemporary Apparel',
      subtitle: 'Seasonal Staples & Everyday Essentials',
      perkLabel: 'Breathable Fabrics',
      perkIcon: Icons.eco_outlined,
      gradientColors: [Color(0xFF831843), Color(0xFFBE123C)],
    ),
    'Home & Living': _BannerContent(
      headline: 'Artisan Living & Decor',
      subtitle: 'Curated Interior Pieces & Daily Essentials',
      perkLabel: 'Eco-Friendly Craft',
      perkIcon: Icons.nature_outlined,
      gradientColors: [Color(0xFF78350F), Color(0xFFB45309)],
    ),
    'Beauty & Grooming': _BannerContent(
      headline: 'Organic Wellness & Grooming',
      subtitle: 'Premium Skincare, Fragrances & Daily Care',
      perkLabel: 'Dermatologist Tested',
      perkIcon: Icons.spa_outlined,
      gradientColors: [Color(0xFF064E3B), Color(0xFF047857)],
    ),
    'Footwear': _BannerContent(
      headline: 'Engineered Footwear',
      subtitle: 'Performance, Comfort & Street-Ready Styles',
      perkLabel: 'Ultra-Cushion Sole',
      perkIcon: Icons.favorite_outline_rounded,
      gradientColors: [Color(0xFF134E4A), Color(0xFF0F766E)],
    ),
    'Accessories': _BannerContent(
      headline: 'Curated Timepieces & Accessories',
      subtitle: 'Signature Watches, Belts & Leather Goods',
      perkLabel: 'Handcrafted Finish',
      perkIcon: Icons.auto_awesome_outlined,
      gradientColors: [Color(0xFF4C1D95), Color(0xFF6D28D9)],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final banner = _banners[selectedCategory] ?? _banners['All']!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: Container(
          key: ValueKey(selectedCategory),
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: banner.gradientColors,
            ),
            boxShadow: [
              BoxShadow(
                color: banner.gradientColors.last.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Headline
              Text(
                banner.headline,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              // Subtitle
              Text(
                banner.subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              // Bottom row: Product count + Perk badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Product count pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$productCount Products',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Perk badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          banner.perkIcon,
                          size: 13,
                          color: Colors.white.withOpacity(0.85),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          banner.perkLabel,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
