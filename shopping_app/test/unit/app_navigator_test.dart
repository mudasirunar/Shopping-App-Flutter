import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shopping_app/core/navigation/app_navigator.dart';
import 'package:shopping_app/core/utils/app_snackbar.dart';
import 'package:shopping_app/providers/cart_provider.dart';
import 'package:shopping_app/providers/navigation_provider.dart';
import 'package:shopping_app/providers/wishlist_provider.dart';
import 'package:shopping_app/views/cart/cart_screen.dart';
import 'package:shopping_app/views/wishlist/wishlist_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppNavigator and SnackBar Action Navigation Tests', () {
    testWidgets('SnackBar action navigates to WishlistScreen even after screen popped backwards', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => NavigationProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => WishlistProvider()),
          ],
          child: MaterialApp(
            navigatorKey: AppNavigator.navigatorKey,
            home: Scaffold(
              body: Builder(
                builder: (firstContext) => ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      firstContext,
                      MaterialPageRoute(
                        builder: (secondContext) => Scaffold(
                          appBar: AppBar(title: const Text('Detail Screen')),
                          body: Center(
                            child: ElevatedButton(
                              onPressed: () {
                                AppSnackBar.show(
                                  secondContext,
                                  message: 'Saved item to Wishlist',
                                  actionLabel: 'View Wishlist',
                                  onAction: () => AppNavigator.openWishlist(),
                                );
                              },
                              child: const Text('Trigger SnackBar'),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Detail Screen'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open detail screen
      await tester.tap(find.text('Open Detail Screen'));
      await tester.pumpAndSettle();
      expect(find.text('Detail Screen'), findsOneWidget);

      // Trigger snackbar on detail screen
      await tester.tap(find.text('Trigger SnackBar'));
      await tester.pump();
      expect(find.text('Saved item to Wishlist'), findsOneWidget);
      expect(find.text('View Wishlist'), findsOneWidget);

      // Pop detail screen back to first screen (Detail Screen is now unmounted)
      AppNavigator.pop();
      await tester.pumpAndSettle();
      expect(find.text('Detail Screen'), findsNothing);
      expect(find.text('Open Detail Screen'), findsOneWidget);
      expect(find.text('View Wishlist'), findsOneWidget);

      // Tap 'View Wishlist' action from the floating snackbar on the previous screen
      await tester.tap(find.text('View Wishlist'));
      await tester.pumpAndSettle();

      // WishlistScreen should have opened successfully
      expect(find.byType(WishlistScreen), findsOneWidget);
    });

    testWidgets('SnackBar action navigates to CartScreen even after screen popped backwards', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => NavigationProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => WishlistProvider()),
          ],
          child: MaterialApp(
            navigatorKey: AppNavigator.navigatorKey,
            home: Scaffold(
              body: Builder(
                builder: (firstContext) => ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      firstContext,
                      MaterialPageRoute(
                        builder: (secondContext) => Scaffold(
                          appBar: AppBar(title: const Text('Product Page')),
                          body: Center(
                            child: ElevatedButton(
                              onPressed: () {
                                AppSnackBar.show(
                                  secondContext,
                                  message: 'Added product to cart',
                                  actionLabel: 'View Cart',
                                  onAction: () => AppNavigator.openCart(),
                                );
                              },
                              child: const Text('Add To Cart'),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Product Page'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open product page
      await tester.tap(find.text('Open Product Page'));
      await tester.pumpAndSettle();
      expect(find.text('Product Page'), findsOneWidget);

      // Add to cart to show snackbar
      await tester.tap(find.text('Add To Cart'));
      await tester.pump();
      expect(find.text('Added product to cart'), findsOneWidget);
      expect(find.text('View Cart'), findsOneWidget);

      // Go back to the initial page
      AppNavigator.pop();
      await tester.pumpAndSettle();
      expect(find.text('Product Page'), findsNothing);
      expect(find.text('Open Product Page'), findsOneWidget);

      // Tap 'View Cart' on the persistent snackbar
      await tester.tap(find.text('View Cart'));
      await tester.pumpAndSettle();

      // CartScreen should have opened successfully
      expect(find.byType(CartScreen), findsOneWidget);
    });
  });
}
