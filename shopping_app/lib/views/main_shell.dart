import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/address_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/catalog_provider.dart';
import 'account/account_screen.dart';
import 'cart/cart_screen.dart';
import 'catalog/catalog_screen.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final auth = context.read<AuthProvider>();
        context.read<CartProvider>().setUserId(auth.currentUser?.uid);
        context.read<AddressProvider>().setUserId(auth.currentUser?.uid);
      }
    });
  }

  void _onTabTapped(int index) {
    if (index == 1) {
      // Categories tab -> open category quick selector bottom sheet
      _showCategoriesSheet(context);
      return;
    }
    setState(() => _currentIndex = index);
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
                        setState(() => _currentIndex = 0); // Jump to Shop catalog
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
    final cart = context.watch<CartProvider>();
    final cartCount = cart.totalItemCount;

    final pages = [
      CatalogScreen(
        onOpenAccount: () => setState(() => _currentIndex = 3),
        onOpenCart: () => setState(() => _currentIndex = 2),
      ),
      const SizedBox.shrink(), // Index 1 is handled via Categories Modal
      CartScreen(
        onExplore: () => setState(() => _currentIndex = 0),
      ),
      const AccountScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.surfaceContainerLowest,
          selectedItemColor: AppTheme.primaryContainer,
          unselectedItemColor: AppTheme.secondary,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'Shop',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.category_outlined),
              activeIcon: Icon(Icons.category),
              label: 'Categories',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: cartCount > 0,
                backgroundColor: AppTheme.tertiary,
                textColor: Colors.white,
                label: Text(
                  '$cartCount',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: cartCount > 0,
                backgroundColor: AppTheme.tertiary,
                textColor: Colors.white,
                label: Text(
                  '$cartCount',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                child: const Icon(Icons.shopping_bag),
              ),
              label: 'Cart',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
