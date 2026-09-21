import 'package:flutter/material.dart';

/// Manages bottom navigation tab index and cross-screen tab routing.
class NavigationProvider extends ChangeNotifier {
  int _currentTabIndex = 0;

  int get currentTabIndex => _currentTabIndex;

  void switchTab(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  void openShop() => switchTab(0);
  void openCategories() => switchTab(1);
  void openCart() => switchTab(2);
  void openAccount() => switchTab(3);
}
