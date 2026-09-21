import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// AppNetworkImage provides resilient image loading with smooth placeholders,
/// category-aware branded error fallbacks, and zero layout shift.
class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? category;
  final double? iconSize;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.category,
    this.iconSize,
  });

  IconData _getCategoryIcon(String? category) {
    if (category == null) return Icons.shopping_bag_outlined;
    final catLower = category.toLowerCase();
    if (catLower.contains('electron')) return Icons.devices_outlined;
    if (catLower.contains('fashion') || catLower.contains('cloth')) return Icons.checkroom_outlined;
    if (catLower.contains('home')) return Icons.cottage_outlined;
    if (catLower.contains('foot') || catLower.contains('shoe')) return Icons.snowshoeing_outlined;
    if (catLower.contains('accessor')) return Icons.watch_outlined;
    if (catLower.contains('beauty') || catLower.contains('groom')) return Icons.spa_outlined;
    return Icons.shopping_bag_outlined;
  }

  Widget _buildFallback(BuildContext context, {bool isError = false}) {
    final icon = _getCategoryIcon(category);
    final effectiveIconSize = iconSize ?? ((height != null && height! < 60) ? 20.0 : 36.0);

    return Container(
      width: width,
      height: height,
      color: AppTheme.surfaceContainerLow,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: effectiveIconSize,
              color: AppTheme.secondary.withOpacity(0.6),
            ),
            if (isError && height != null && height! >= 120) ...[
              const SizedBox(height: 8),
              Text(
                category ?? 'Product Image',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.secondary.withOpacity(0.7),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isValidUrl = imageUrl.trim().startsWith('http://') || imageUrl.trim().startsWith('https://');

    Widget imageContent;

    if (!isValidUrl) {
      imageContent = _buildFallback(context, isError: true);
    } else {
      imageContent = Image.network(
        imageUrl.trim(),
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: AppTheme.surfaceContainerLow,
            child: Center(
              child: SizedBox(
                width: (height != null && height! < 60) ? 16 : 24,
                height: (height != null && height! < 60) ? 16 : 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  color: AppTheme.primaryContainer.withOpacity(0.5),
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildFallback(context, isError: true);
        },
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageContent,
      );
    }

    return imageContent;
  }
}
