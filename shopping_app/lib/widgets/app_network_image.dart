import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// AppNetworkImage provides resilient image loading with:
/// - Smooth loading placeholders with zero layout shift
/// - Category-aware branded fallback icon
/// - AUTOMATIC NETWORK RECOVERY: If loading fails (e.g. offline), it periodically
///   retries in the background so that the instant internet connection returns,
///   the image automatically reloads and renders without requiring screen changes.
/// - Tap to retry on error fallback
class AppNetworkImage extends StatefulWidget {
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

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> {
  bool _hasError = false;
  int _retryKey = 0;
  Timer? _retryTimer;

  @override
  void didUpdateWidget(covariant AppNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      _stopRetryTimer();
      _hasError = false;
      _retryKey = 0;
    }
  }

  @override
  void dispose() {
    _stopRetryTimer();
    super.dispose();
  }

  void _stopRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void _scheduleAutoRecovery() {
    if (_retryTimer != null && _retryTimer!.isActive) return;

    _retryTimer = Timer.periodic(const Duration(milliseconds: 3000), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _triggerRetry();
    });
  }

  void _triggerRetry() {
    final cleanUrl = widget.imageUrl.trim();
    if (cleanUrl.isNotEmpty) {
      try {
        NetworkImage(cleanUrl).evict();
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _hasError = false;
        _retryKey++;
      });
    }
  }

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
    final icon = _getCategoryIcon(widget.category);
    final effectiveIconSize = widget.iconSize ??
        ((widget.height != null && widget.height! < 60) ? 20.0 : 36.0);

    return InkWell(
      onTap: isError ? _triggerRetry : null,
      child: Container(
        width: widget.width,
        height: widget.height,
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
              if (isError && widget.height != null && widget.height! >= 120) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 9,
                      height: 9,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppTheme.secondary.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Reconnecting...',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.secondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = widget.imageUrl.trim();
    final isValidUrl = cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://');

    Widget imageContent;

    if (!isValidUrl || _hasError) {
      if (isValidUrl && _hasError) {
        _scheduleAutoRecovery();
      }
      imageContent = _buildFallback(context, isError: true);
    } else {
      imageContent = Image.network(
        cleanUrl,
        key: ValueKey('$cleanUrl-$_retryKey'),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            _stopRetryTimer();
            return child;
          }
          return _buildLoadingPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            _stopRetryTimer();
            return child;
          }
          return _buildLoadingPlaceholder(progress: loadingProgress);
        },
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_hasError) {
              setState(() {
                _hasError = true;
              });
              _scheduleAutoRecovery();
            }
          });
          return _buildFallback(context, isError: true);
        },
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageContent,
      );
    }

    return imageContent;
  }

  Widget _buildLoadingPlaceholder({ImageChunkEvent? progress}) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: AppTheme.surfaceContainerLow,
      child: Center(
        child: SizedBox(
          width: (widget.height != null && widget.height! < 60) ? 16 : 24,
          height: (widget.height != null && widget.height! < 60) ? 16 : 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: (progress != null && progress.expectedTotalBytes != null)
                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                : null,
            color: AppTheme.primaryContainer.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}
