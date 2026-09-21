import 'package:flutter/material.dart';
import '../../views/cart/cart_screen.dart';
import '../../views/wishlist/wishlist_screen.dart';

/// Centralized navigation service providing reliable, lifecycle-independent navigation.
/// Guarantees that global UI elements (such as SnackBars) can navigate properly even
/// if the originating screen was popped, pushed ahead, or unmounted.
class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext? get currentContext => navigatorKey.currentContext;
  static NavigatorState? get state => navigatorKey.currentState;

  /// Pushes a widget screen onto the root navigator.
  static Future<T?>? push<T>(Widget screen, {String? routeName}) {
    final navState = navigatorKey.currentState;
    if (navState == null) return null;

    return navState.push<T>(
      MaterialPageRoute(
        settings: routeName != null ? RouteSettings(name: routeName) : null,
        builder: (_) => screen,
      ),
    );
  }

  /// Navigates to the Cart screen safely from any location in the app.
  /// - If already viewing CartScreen, avoids creating a redundant route.
  /// - Otherwise, pushes CartScreen with route tracking and back navigation.
  static void openCart() {
    final navState = navigatorKey.currentState;
    if (navState == null) return;

    bool isCurrentRouteCart = false;
    navState.popUntil((route) {
      if (route.settings.name == 'CartScreen') {
        isCurrentRouteCart = true;
      }
      return true; // Inspect top route and stop immediately without popping
    });

    if (isCurrentRouteCart) return;

    navState.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'CartScreen'),
        builder: (_) => const CartScreen(),
      ),
    );
  }

  /// Navigates to the Wishlist screen safely from any location in the app.
  /// - If already viewing WishlistScreen, avoids creating a redundant route.
  /// - Otherwise, pushes WishlistScreen with route tracking.
  static void openWishlist() {
    final navState = navigatorKey.currentState;
    if (navState == null) return;

    bool isCurrentRouteWishlist = false;
    navState.popUntil((route) {
      if (route.settings.name == 'WishlistScreen') {
        isCurrentRouteWishlist = true;
      }
      return true; // Inspect top route and stop immediately without popping
    });

    if (isCurrentRouteWishlist) return;

    navState.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'WishlistScreen'),
        builder: (_) => const WishlistScreen(),
      ),
    );
  }

  /// Safely pops the current screen if canPop is true.
  static void pop<T>([T? result]) {
    if (navigatorKey.currentState?.canPop() ?? false) {
      navigatorKey.currentState?.pop<T>(result);
    }
  }
}
