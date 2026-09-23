import 'package:flutter/material.dart';

/// Manages bottom navigation tab index and cross-screen tab routing.
class NavigationProvider extends ChangeNotifier {
  int _currentTabIndex = 0;
  String? _targetExploreCategory;

  int get currentTabIndex => _currentTabIndex;
  String? get targetExploreCategory => _targetExploreCategory;

  void switchTab(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  void openShop() => switchTab(0);

  void openExplore([String? category]) {
    _targetExploreCategory = category;
    switchTab(1);
  }

  void clearTargetExploreCategory() {
    _targetExploreCategory = null;
  }

  void openCategories() => openExplore();
  void openCart() => switchTab(2);
  void openAccount() => switchTab(3);
}
