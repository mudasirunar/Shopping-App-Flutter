import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/app_snackbar.dart';

/// A standalone promotional voucher strip featuring 5 exclusive coupon codes,
/// smooth continuous auto-sliding ticker motion, instant freeze-on-touch interaction,
/// and responsive 1-tap clipboard copying with animated checkmark feedback.
class VoucherWalletStrip extends StatefulWidget {
  const VoucherWalletStrip({super.key});

  @override
  State<VoucherWalletStrip> createState() => _VoucherWalletStripState();
}

class _VoucherWalletStripState extends State<VoucherWalletStrip>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final Ticker _ticker;

  // Ambient drifting speed in pixels per second (~26 px/s for readable elegance)
  static const double _kScrollSpeed = 26.0;
  Duration? _lastFrameTime;
  bool _isPointerDown = false;
  bool _isScrolling = false;

  // Visual copied tick feedback with auto-reset timer
  String? _copiedCode;
  Timer? _copiedResetTimer;

  static const List<Map<String, dynamic>> _vouchers = [
    {
      'code': 'FESTIVAL20',
      'label': '20% OFF Orders over Rs. 5,000',
      'color': Color(0xFF047857),
    },
    {
      'code': 'FREESHIP',
      'label': 'Free Insured Air Courier',
      'color': Color(0xFF1D4ED8),
    },
    {
      'code': 'SAVE15',
      'label': 'Flat 15% OFF Audio & Tech',
      'color': Color(0xFFB45309),
    },
    {
      'code': 'MEGA30',
      'label': 'Flat 30% OFF Summer & Living',
      'color': Color(0xFF7C3AED),
    },
    {
      'code': 'FIRST10',
      'label': 'Extra 10% OFF Your First Order',
      'color': Color(0xFFE11D48),
    },
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ticker.start();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _copiedResetTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!mounted || !_scrollController.hasClients) {
      _lastFrameTime = elapsed;
      return;
    }

    // Freeze motion immediately while user touches or drags the strip
    if (_isPointerDown || _isScrolling) {
      _lastFrameTime = elapsed;
      return;
    }

    if (_lastFrameTime != null) {
      final dt = (elapsed - _lastFrameTime!).inMicroseconds / 1000000.0;
      if (dt > 0 && dt < 0.1) {
        final currentOffset = _scrollController.offset;
        final newOffset = currentOffset + (_kScrollSpeed * dt);
        _scrollController.jumpTo(newOffset);
      }
    }
    _lastFrameTime = elapsed;
  }

  void _copyVoucher(String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    AppSnackBar.show(
      context,
      message: 'Voucher code "$code" copied to clipboard!',
    );

    setState(() {
      _copiedCode = code;
    });

    _copiedResetTimer?.cancel();
    _copiedResetTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _copiedCode = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Heading
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.confirmation_number_outlined, size: 18, color: AppTheme.primary),
                SizedBox(width: 6),
                Text(
                  'Exclusive Promo Codes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Continuous Ambient Drifting Voucher Strip with Instant Touch-Freeze
          SizedBox(
            height: 56,
            child: Listener(
              onPointerDown: (_) {
                _isPointerDown = true;
              },
              onPointerUp: (_) {
                _isPointerDown = false;
                _lastFrameTime = null;
              },
              onPointerCancel: (_) {
                _isPointerDown = false;
                _lastFrameTime = null;
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification) {
                    _isScrolling = true;
                  } else if (notification is ScrollEndNotification) {
                    _isScrolling = false;
                    _lastFrameTime = null;
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final v = _vouchers[index % _vouchers.length];
                    final code = v['code'] as String;
                    final label = v['label'] as String;
                    final col = v['color'] as Color;
                    final isCopied = _copiedCode == code;

                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        onTap: () => _copyVoucher(code),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCopied
                                  ? const Color(0xFF059669)
                                  : col.withOpacity(0.35),
                              width: isCopied ? 1.4 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isCopied
                                    ? const Color(0xFF059669).withOpacity(0.12)
                                    : Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Voucher Code Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: col.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  code,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: col,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Promo Description
                              Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Dynamic Action Indicator: Copy Icon or Animated "COPIED ✓" Badge
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, anim) => ScaleTransition(
                                  scale: anim,
                                  child: child,
                                ),
                                child: isCopied
                                    ? Container(
                                        key: const ValueKey('copied'),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF059669).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_rounded,
                                              size: 13,
                                              color: Color(0xFF059669),
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              'COPIED',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF059669),
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Icon(
                                        key: const ValueKey('copy'),
                                        Icons.copy_rounded,
                                        size: 14,
                                        color: col,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
