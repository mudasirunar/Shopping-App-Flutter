import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/app_snackbar.dart';
import '../providers/navigation_provider.dart';

/// A standalone hero promotional carousel featuring auto-sliding cards,
/// seamless infinite forward looping, floating transparent cutouts,
/// and rounded glowing colored shadows.
class HeroPromotionalCarousel extends StatefulWidget {
  const HeroPromotionalCarousel({super.key});

  @override
  State<HeroPromotionalCarousel> createState() => _HeroPromotionalCarouselState();
}

class _HeroPromotionalCarouselState extends State<HeroPromotionalCarousel> {
  static const int _initialBannerPage = 3000;
  late final PageController _bannerController;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _bannerController = PageController(initialPage: _initialBannerPage);

    // Auto-advance banner every 4.5 seconds in a seamless forward loop
    _bannerTimer = Timer.periodic(const Duration(milliseconds: 4500), (timer) {
      if (!mounted) return;
      if (_bannerController.hasClients) {
        _bannerController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _copyVoucher(String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    AppSnackBar.show(
      context,
      message: 'Voucher code "$code" copied to clipboard!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.read<NavigationProvider>();

    final banners = [
      _PromoBannerData(
        badge: 'Today’s Offer',
        title: 'Up to 35% Off\nCurated Collection',
        subtitle: 'Handpicked electronics, living & premium apparel',
        gradientColors: [const Color(0xFF0F172A), const Color(0xFF1E293B)],
        accentColor: const Color(0xFFF59E0B),
        imageUrl: 'assets/banners/banner_headphones.png',
        onTap: () => nav.openExplore('Electronics'),
      ),
      _PromoBannerData(
        badge: 'Exclusive Voucher',
        title: 'Flat 20% Discount\nCode: FESTIVAL20',
        subtitle: 'Apply at checkout on all orders above Rs. 5,000',
        gradientColors: [const Color(0xFF064E3B), const Color(0xFF047857)],
        accentColor: const Color(0xFF34D399),
        imageUrl: 'assets/banners/banner_sneaker.png',
        onTap: () {
          _copyVoucher('FESTIVAL20');
          nav.openExplore('Fashion');
        },
      ),
      _PromoBannerData(
        badge: 'New Season Drop',
        title: 'Modern Everyday\nLifestyle Essentials',
        subtitle: 'Designed for durability, aesthetics and everyday ease',
        gradientColors: [const Color(0xFF701A75), const Color(0xFF4C0519)],
        accentColor: const Color(0xFFF472B6),
        imageUrl: 'assets/banners/banner_living.png',
        onTap: () => nav.openExplore('Home & Living'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FIXED Heading: "Promotions" (stays completely static on swipe)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Promotions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Carousel of promotional cards in seamless infinite loop
        SizedBox(
          height: 140,
          child: PageView.builder(
            clipBehavior: Clip.none,
            controller: _bannerController,
            onPageChanged: (i) {
              setState(() {
                _currentBannerIndex = (i % banners.length + banners.length) % banners.length;
              });
            },
            itemBuilder: (context, index) {
              final b = banners[(index % banners.length + banners.length) % banners.length];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Main Gradient Card (Entire card is clickable with smooth rounded glowing shadow)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: LinearGradient(
                            colors: b.gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: b.gradientColors.first.withOpacity(0.38),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                          child: InkWell(
                            onTap: b.onTap,
                            borderRadius: BorderRadius.circular(22),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top: Badge Chip (restored chip container style)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: b.accentColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: b.accentColor.withOpacity(0.6)),
                                    ),
                                    child: Text(
                                      b.badge,
                                      style: TextStyle(
                                        color: b.accentColor,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Main Bold Title & Multi-line Description below chip
                                  Padding(
                                    padding: const EdgeInsets.only(right: 96),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          b.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.w800,
                                            height: 1.15,
                                            letterSpacing: -0.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          b.subtitle,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.85),
                                            fontSize: 11,
                                            height: 1.22,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Floating Overlapping Transparent Cutout Image at Top Right
                    // top: -36 places top part of the image beside the fixed Promotions text
                    Positioned(
                      top: -36,
                      right: 2,
                      child: GestureDetector(
                        onTap: b.onTap,
                        child: SizedBox(
                          width: 136,
                          height: 136,
                          child: Image.asset(
                            b.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (i) {
            final active = i == _currentBannerIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 5,
              decoration: BoxDecoration(
                color: active ? AppTheme.primary : AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PromoBannerData {
  final String badge;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final Color accentColor;
  final String imageUrl;
  final VoidCallback onTap;

  _PromoBannerData({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.accentColor,
    required this.imageUrl,
    required this.onTap,
  });
}
