import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/navigation/app_navigator.dart';
import 'core/theme/app_theme.dart';
import 'providers/address_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/order_provider.dart';
import 'providers/wishlist_provider.dart';
import 'views/main_shell.dart';
import 'views/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // Android: dark status bar icons
      statusBarBrightness: Brightness.light, // iOS: dark status bar text & icons
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase purely from native config files (google-services.json & GoogleService-Info.plist)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization note: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  runApp(ShoppingApp(hasSeenOnboarding: hasSeenOnboarding));
}

class ShoppingApp extends StatelessWidget {
  final bool hasSeenOnboarding;

  const ShoppingApp({super.key, this.hasSeenOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: MaterialApp(
        navigatorKey: AppNavigator.navigatorKey,
        title: 'Shopping App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: hasSeenOnboarding ? const MainShell() : const OnboardingScreen(),
      ),
    );
  }
}
