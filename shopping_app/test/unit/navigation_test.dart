import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_app/providers/navigation_provider.dart';

void main() {
  group('NavigationProvider Tests', () {
    test('Initial tab index defaults to 0 (Shop)', () {
      final nav = NavigationProvider();
      expect(nav.currentTabIndex, 0);
    });

    test('switchTab updates index and notifies listeners', () {
      final nav = NavigationProvider();
      int notified = 0;
      nav.addListener(() => notified++);

      nav.switchTab(2);
      expect(nav.currentTabIndex, 2);
      expect(notified, 1);

      // Switching to same tab should not notify
      nav.switchTab(2);
      expect(notified, 1);
    });

    test('Helper methods switch to corresponding tabs', () {
      final nav = NavigationProvider();

      nav.openCart();
      expect(nav.currentTabIndex, 2);

      nav.openAccount();
      expect(nav.currentTabIndex, 3);

      nav.openCategories();
      expect(nav.currentTabIndex, 1);

      nav.openShop();
      expect(nav.currentTabIndex, 0);
    });
  });
}
