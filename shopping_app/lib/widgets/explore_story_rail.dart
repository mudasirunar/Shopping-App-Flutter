import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';

/// Data model for each category story bubble.
class _StoryCategoryData {
  final String label;
  final IconData icon;
  /// Vibrant accent color used for icon tint and label when active.
  final Color accentColor;
  /// Soft pastel background for the inner circle when active.
  final Color activeBgColor;
  /// Gradient ring colors when active [start, end].
  final List<Color> ringGradient;

  const _StoryCategoryData({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.activeBgColor,
    required this.ringGradient,
  });
}

/// Instagram-style horizontal category story rail with circular icon bubbles,
/// subtle gradient ring on active, indicator dot, and auto-centering on tap.
/// Designed for light-mode UI with soft pastel fills.
class ExploreStoryRail extends StatefulWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const ExploreStoryRail({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  State<ExploreStoryRail> createState() => _ExploreStoryRailState();
}

class _ExploreStoryRailState extends State<ExploreStoryRail> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = {};

  // Light-mode friendly palette: soft pastels + vibrant accents
  static const Map<String, _StoryCategoryData> _categoryData = {
    'All': _StoryCategoryData(
      label: 'All',
      icon: Icons.apps_rounded,
      accentColor: Color(0xFF334E68),
      activeBgColor: Color(0xFFE2E8F0),
      ringGradient: [Color(0xFF64748B), Color(0xFF334E68)],
    ),
    'Electronics': _StoryCategoryData(
      label: 'Electronics',
      icon: Icons.devices_rounded,
      accentColor: Color(0xFF2563EB),
      activeBgColor: Color(0xFFDBEAFE),
      ringGradient: [Color(0xFF60A5FA), Color(0xFF2563EB)],
    ),
    'Fashion': _StoryCategoryData(
      label: 'Fashion',
      icon: Icons.checkroom_rounded,
      accentColor: Color(0xFFE11D48),
      activeBgColor: Color(0xFFFFE4E6),
      ringGradient: [Color(0xFFFB7185), Color(0xFFE11D48)],
    ),
    'Home & Living': _StoryCategoryData(
      label: 'Home & Living',
      icon: Icons.chair_rounded,
      accentColor: Color(0xFFD97706),
      activeBgColor: Color(0xFFFEF3C7),
      ringGradient: [Color(0xFFFBBF24), Color(0xFFD97706)],
    ),
    'Beauty & Grooming': _StoryCategoryData(
      label: 'Beauty',
      icon: Icons.spa_rounded,
      accentColor: Color(0xFF059669),
      activeBgColor: Color(0xFFD1FAE5),
      ringGradient: [Color(0xFF6EE7B7), Color(0xFF059669)],
    ),
    'Footwear': _StoryCategoryData(
      label: 'Footwear',
      icon: Icons.snowshoeing_rounded,
      accentColor: Color(0xFF0D9488),
      activeBgColor: Color(0xFFCCFBF1),
      ringGradient: [Color(0xFF5EEAD4), Color(0xFF0D9488)],
    ),
    'Accessories': _StoryCategoryData(
      label: 'Accessories',
      icon: Icons.watch_rounded,
      accentColor: Color(0xFF7C3AED),
      activeBgColor: Color(0xFFEDE9FE),
      ringGradient: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
    ),
  };

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onTap(String cat) {
    HapticFeedback.selectionClick();
    widget.onCategorySelected(cat);
    _scrollToItem(cat);
  }

  void _scrollToItem(String cat) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _itemKeys[cat];
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant ExploreStoryRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _scrollToItem(widget.selectedCategory);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cat = widget.categories[index];
          final isActive =
              widget.selectedCategory.toLowerCase() == cat.toLowerCase();
          final data = _categoryData[cat] ??
              const _StoryCategoryData(
                label: 'Other',
                icon: Icons.category_rounded,
                accentColor: Color(0xFF64748B),
                activeBgColor: Color(0xFFF1F5F9),
                ringGradient: [Color(0xFF94A3B8), Color(0xFF64748B)],
              );

          final itemKey = _itemKeys.putIfAbsent(cat, () => GlobalKey());

          return GestureDetector(
            key: itemKey,
            onTap: () => _onTap(cat),
            child: SizedBox(
              width: 68,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Outer ring container
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isActive
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: data.ringGradient,
                            )
                          : null,
                      border: !isActive
                          ? Border.all(
                              color: AppTheme.outlineVariant.withOpacity(0.5),
                              width: 1.5,
                            )
                          : null,
                    ),
                    padding: EdgeInsets.all(isActive ? 2.5 : 0),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? data.activeBgColor
                            : AppTheme.surfaceContainerLow,
                      ),
                      child: Center(
                        child: Icon(
                          data.icon,
                          size: 22,
                          color: isActive
                              ? data.accentColor
                              : AppTheme.secondary.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Label
                  Text(
                    data.label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? data.accentColor : AppTheme.secondary,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  // Active indicator dot
                  if (isActive)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: data.accentColor,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
