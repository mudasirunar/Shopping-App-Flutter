import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../auth/sign_in_screen.dart';
import '../orders/order_history_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out?',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary),
        ),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.secondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              minimumSize: const Size(90, 36),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                context.read<CartProvider>().setUserId('guest');
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isGuest = user == null;

    final displayName = isGuest
        ? 'Guest Shopper'
        : (user.displayName != null && user.displayName!.isNotEmpty)
            ? user.displayName!
            : 'Valued Customer';
    final displayEmail = isGuest ? 'Browsing as Guest' : (user.email ?? '');

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        titleSpacing: 16,
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 0,
        title: const Text(
          'My Account',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          children: [
            // User Header Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'G',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayEmail,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Menu Section
            Material(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              elevation: 0,
              shadowColor: Colors.black.withOpacity(0.02),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined, color: AppTheme.primary),
                    title: const Text('Order History', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('View and track your Cash on Delivery orders', style: TextStyle(fontSize: 12, color: AppTheme.secondary)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.secondary),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.local_shipping_outlined, color: AppTheme.primary),
                    title: const Text('Delivery Policy', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Free delivery over PKR 5,000 · Flat PKR 200 below', style: TextStyle(fontSize: 12, color: AppTheme.secondary)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.secondary),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Shoply Mobile',
                        applicationVersion: '1.0.0',
                        children: const [
                          Text('Standard Delivery: Flat PKR 200 within Pakistan.\n\nFree Delivery: Orders PKR 5,000 and above qualify for 100% free delivery.\n\nPayment: Cash on Delivery (COD) supported nationwide.'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Auth Action Card
            Material(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              elevation: 0,
              shadowColor: Colors.black.withOpacity(0.02),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  if (isGuest)
                    ListTile(
                      leading: const Icon(Icons.login, color: AppTheme.primary),
                      title: const Text('Sign In or Register', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Log in with your account to save cart across devices', style: TextStyle(fontSize: 12, color: AppTheme.secondary)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.secondary),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignInScreen()),
                        );
                      },
                    )
                  else
                    ListTile(
                      leading: const Icon(Icons.logout, color: AppTheme.error),
                      title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.error)),
                      subtitle: const Text('Securely disconnect your current session', style: TextStyle(fontSize: 12, color: AppTheme.secondary)),
                      onTap: () => _confirmSignOut(context),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // App Footer
            const Text(
              'Shoply Mobile E-Commerce',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.secondary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 11, color: AppTheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
