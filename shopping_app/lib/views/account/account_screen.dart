import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../address/addresses_screen.dart';
import '../auth/sign_in_screen.dart';
import '../orders/order_history_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out? Your session will end.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.secondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                context.read<CartProvider>().setUserId('guest');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Successfully signed out.'),
                    backgroundColor: AppTheme.primary,
                  ),
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

    final displayName = user?.displayName ?? (isGuest ? 'Guest Shopper' : 'Registered Member');
    final email = user?.email ?? (isGuest ? 'Browsing in Guest Mode' : '');

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
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // User Header Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.primaryContainer,
                    child: Text(
                      isGuest ? 'G' : (displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isGuest) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, size: 16, color: AppTheme.primary),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.secondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isGuest) ...[
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignInScreen(showGuestOption: false),
                                ),
                              );
                            },
                            child: const Text(
                              'Sign in to save orders & cart →',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
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
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
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
                  ),
                  const Divider(height: 1),
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: const Icon(Icons.location_on_outlined, color: AppTheme.primary),
                      title: const Text('Saved Addresses', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Manage up to 3 delivery and billing addresses', style: TextStyle(fontSize: 12, color: AppTheme.secondary)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.secondary),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddressesScreen()),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: const Icon(Icons.local_shipping_outlined, color: AppTheme.primary),
                      title: const Text('Delivery Policy', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Free delivery over PKR 5,000 · Flat PKR 200 below', style: TextStyle(fontSize: 12, color: AppTheme.secondary)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.secondary),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'Shopping App',
                          applicationVersion: '1.0.0',
                          children: const [
                            Text('Standard Delivery: Flat PKR 200 within Pakistan.\n\nFree Delivery: Orders PKR 5,000 and above qualify for 100% free delivery.\n\nPayment: Cash on Delivery (COD) supported nationwide.'),
                          ],
                        );
                      },
                    ),
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
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: const Icon(Icons.login, color: AppTheme.primary),
                        title: const Text('Sign In or Register', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text('Log in with your account to save cart across devices', style: TextStyle(fontSize: 12, color: AppTheme.secondary)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.secondary),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignInScreen(showGuestOption: false),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: const Icon(Icons.logout, color: AppTheme.error),
                        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.error)),
                        subtitle: const Text('Securely disconnect your current session', style: TextStyle(fontSize: 12, color: AppTheme.secondary)),
                        onTap: () => _confirmSignOut(context),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // App Footer
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Shopping App',
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
