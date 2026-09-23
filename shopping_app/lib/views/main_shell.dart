import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/address_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/wishlist_provider.dart';
import 'account/account_screen.dart';
import 'cart/cart_screen.dart';
import 'explore/explore_screen.dart';
import 'home/home_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/top_welcome_banner.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  final String? welcomeUserName;
  final bool isNewUser;

  const MainShell({
    super.key,
    this.initialIndex = 0,
    this.welcomeUserName,
    this.isNewUser = false,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final ScrollController _homeScrollController = ScrollController();
  final ScrollController _exploreScrollController = ScrollController();
  final ScrollController _cartScrollController = ScrollController();
  final ScrollController _accountScrollController = ScrollController();

  @override
  void dispose() {
    _homeScrollController.dispose();
    _exploreScrollController.dispose();
    _cartScrollController.dispose();
    _accountScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NavigationProvider>().switchTab(widget.initialIndex);
        final auth = context.read<AuthProvider>();
        context.read<CartProvider>().setUserId(auth.currentUser?.uid);
        context.read<AddressProvider>().setUserId(auth.currentUser?.uid);
        context.read<WishlistProvider>().setUserId(auth.currentUser?.uid);

        if (widget.welcomeUserName != null && widget.welcomeUserName!.trim().isNotEmpty) {
          TopWelcomeBanner.show(
            context,
            name: widget.welcomeUserName!,
            isNewUser: widget.isNewUser,
          );
        }
      }
    });
  }

  void _scrollToTop(int index) {
    ScrollController? controller;
    if (index == 0) controller = _homeScrollController;
    if (index == 1) controller = _exploreScrollController;
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
    final nav = context.read<NavigationProvider>();
    if (nav.currentTabIndex == index) {
      // Re-click same selected tab -> smoothly scroll to top
      _scrollToTop(index);
      return;
    }
    nav.switchTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final currentIndex = nav.currentTabIndex;
    final cart = context.watch<CartProvider>();
    final cartCount = cart.totalItemCount;

    final pages = [
      HomeScreen(
        scrollController: _homeScrollController,
        onOpenCart: () => nav.openCart(),
      ),
      ExploreScreen(
        scrollController: _exploreScrollController,
        onOpenCart: () => nav.openCart(),
      ),
      CartScreen(
        scrollController: _cartScrollController,
        onExplore: () => nav.openExplore(),
      ),
      AccountScreen(
        scrollController: _accountScrollController,
      ),
    ];

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
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
