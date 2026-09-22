import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/address_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/catalog_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/wishlist_provider.dart';
import 'account/account_screen.dart';
import 'cart/cart_screen.dart';
import 'catalog/catalog_screen.dart';
import '../widgets/bottom_nav_bar.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final ScrollController _catalogScrollController = ScrollController();
  final ScrollController _cartScrollController = ScrollController();
  final ScrollController _accountScrollController = ScrollController();

  @override
  void dispose() {
    _catalogScrollController.dispose();
    _cartScrollController.dispose();
    _accountScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (widget.initialIndex != 0) {
          context.read<NavigationProvider>().switchTab(widget.initialIndex);
        }
        final auth = context.read<AuthProvider>();
        context.read<CartProvider>().setUserId(auth.currentUser?.uid);
        context.read<AddressProvider>().setUserId(auth.currentUser?.uid);
        context.read<WishlistProvider>().setUserId(auth.currentUser?.uid);
      }
    });
  }

  void _scrollToTop(int index) {
    ScrollController? controller;
    if (index == 0) controller = _catalogScrollController;
    if (index == 2) controller = _cartScrollController;
    if (index == 3) controller = _accountScrollController;

    if (controller != null && controller.hasClients) {
      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onTabTapped(int index) {
    if (index == 1) {
      // Categories tab -> open category quick selector bottom sheet
      _showCategoriesSheet(context);
      return;
    }
    final nav = context.read<NavigationProvider>();
    if (nav.currentTabIndex == index) {
      // Re-click same selected tab -> smoothly scroll to top
      _scrollToTop(index);
      return;
    }
    nav.switchTab(index);
  }

  void _showCategoriesSheet(BuildContext context) {
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
                    'Explore Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                for (final cat in catalog.categories)
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: Icon(
                        _getCategoryIcon(cat),
                        color: catalog.selectedCategory.toLowerCase() == cat.toLowerCase()
                            ? AppTheme.primary
                            : AppTheme.secondary,
                      ),
                      title: Text(
                        cat,
                        style: TextStyle(
                          fontWeight: catalog.selectedCategory.toLowerCase() == cat.toLowerCase()
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: catalog.selectedCategory.toLowerCase() == cat.toLowerCase()
                              ? AppTheme.primary
                              : AppTheme.onSurface,
                        ),
                      ),
                      trailing: catalog.selectedCategory.toLowerCase() == cat.toLowerCase()
                          ? const Icon(Icons.check, color: AppTheme.primary)
                          : null,
                      onTap: () {
                        catalog.selectCategory(cat);
                        Navigator.pop(ctx);
                        context.read<NavigationProvider>().openShop();
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

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'electronics':
        return Icons.devices_outlined;
      case 'fashion':
        return Icons.checkroom_outlined;
      case 'home & living':
        return Icons.chair_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final currentIndex = nav.currentTabIndex;
    final cart = context.watch<CartProvider>();
    final cartCount = cart.totalItemCount;


    final pages = [
      CatalogScreen(
        scrollController: _catalogScrollController,
        onOpenAccount: () => nav.openAccount(),
        onOpenCart: () => nav.openCart(),
      ),
      const SizedBox.shrink(), // Index 1 is handled via Categories Modal
      CartScreen(
        scrollController: _cartScrollController,
        onExplore: () => nav.openShop(),
      ),
      AccountScreen(
        scrollController: _accountScrollController,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        cartCount: cartCount,
        onTabSelected: _onTabTapped,
      ),
    );
  }
}
