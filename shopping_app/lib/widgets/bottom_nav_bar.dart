import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';

/// Single unified bottom navigation bar component.
/// - On iOS: Embeds the real native SwiftUI TabView via iOS Platform View (UiKitView).
/// - On Android: Renders the custom Flutter navigation bar.
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final int cartCount;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.cartCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      return _IOSNativeTabBar(
        currentIndex: currentIndex,
        cartCount: cartCount,
        onTabSelected: onTabSelected,
      );
    }
    return _AndroidBottomBar(
      currentIndex: currentIndex,
      cartCount: cartCount,
      onTap: onTabSelected,
    );
  }
}

// =============================================================================
// iOS Native Tab Bar (SwiftUI Platform View via UiKitView)  -- UNCHANGED
// =============================================================================
class _IOSNativeTabBar extends StatefulWidget {
  final int currentIndex;
  final int cartCount;
  final ValueChanged<int> onTabSelected;

  const _IOSNativeTabBar({
    required this.currentIndex,
    required this.onTabSelected,
    this.cartCount = 0,
  });

  @override
  State<_IOSNativeTabBar> createState() => _IOSNativeTabBarState();
}

class _IOSNativeTabBarState extends State<_IOSNativeTabBar> {
  MethodChannel? _channel;

  @override
  void didUpdateWidget(covariant _IOSNativeTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _channel?.invokeMethod('setTab', {'index': widget.currentIndex});
    }
    if (widget.cartCount != oldWidget.cartCount) {
      _channel?.invokeMethod('updateCartCount', {'count': widget.cartCount});
    }
  }

  void _onPlatformViewCreated(int id) {
    final channel = MethodChannel('shopping_app/native-tab-bar_$id');
    _channel = channel;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'onTabSelected') {
        final index = (call.arguments as Map)['index'] as int;
        widget.onTabSelected(index);
      }
    });
    if (widget.cartCount > 0) {
      channel.invokeMethod('updateCartCount', {'count': widget.cartCount});
    }
    if (widget.currentIndex != 0) {
      channel.invokeMethod('setTab', {'index': widget.currentIndex});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final totalHeight = 49.0 + bottomInset;

    return SizedBox(
      height: totalHeight,
      child: UiKitView(
        viewType: 'shopping_app/native-tab-bar',
        creationParams: {
          'selectedIndex': widget.currentIndex,
          'cartCount': widget.cartCount,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      ),
    );
  }
}

// =============================================================================
// Android Liquid Glass Bottom Bar
// =============================================================================
class _AndroidBottomBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartCount;

  const _AndroidBottomBar({
    required this.currentIndex,
    required this.onTap,
    this.cartCount = 0,
  });

  @override
  State<_AndroidBottomBar> createState() => _AndroidBottomBarState();
}

class _AndroidBottomBarState extends State<_AndroidBottomBar>
    with TickerProviderStateMixin {
  static const _items = [
    _NavItem(
      label: 'Shop',
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront_rounded,
    ),
    _NavItem(
      label: 'Categories',
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
    ),
    _NavItem(
      label: 'Cart',
      icon: Icons.shopping_cart_outlined,
      activeIcon: Icons.shopping_cart_rounded,
      hasBadge: true,
    ),
    _NavItem(
      label: 'Account',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  static const double _barHeight = 66;
  static const double _inset = 6;
  static const double _lensRise = 10; // grows above the bar
  static const double _lensDrop =
      10; // grows below the bar (keep equal to rise for even growth)
  static const _barRadius = BorderRadius.all(Radius.circular(_barHeight / 2));

  // Lower ratio = more bounce.
  static final _settleSpring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 380,
    ratio: 0.68,
  );
  static final _followSpring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 240,
    ratio: 0.82,
  );
  static final _pressSpring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 300,
    ratio: 0.5,
  );

  late final AnimationController _c; // pill position in tab units (0..3)
  late final AnimationController
  _press; // 0 = resting, 1 = held (overshoots = jelly)
  late int _target;
  bool _dragging = false;
  bool _pressed = false;
  int _lastHapticIndex = 0;
  double _dragPos = 0;
  double _itemWidth = 1;

  @override
  void initState() {
    super.initState();
    _target = widget.currentIndex;
    _c = AnimationController.unbounded(
      vsync: this,
      value: widget.currentIndex.toDouble(),
    );
    _press = AnimationController.unbounded(vsync: this, value: 0);
  }

  @override
  void didUpdateWidget(covariant _AndroidBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && widget.currentIndex != _target) {
      _animateTo(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _press.dispose();
    super.dispose();
  }

  void _animateTo(int index, {double velocity = 0}) {
    _target = index;
    _c.animateWith(
      SpringSimulation(_settleSpring, _c.value, index.toDouble(), velocity),
    );
  }

  /// While dragging, the pill chases the finger on a spring (fluid, not stiff).
  void _followTo(double pos) {
    _c.animateWith(SpringSimulation(_followSpring, _c.value, pos, _c.velocity));
  }

  void _setPressed(bool v) {
    if (_pressed == v) return;
    _pressed = v;
    _press.animateWith(
      SpringSimulation(
        _pressSpring,
        _press.value,
        v ? 1.0 : 0.0,
        _press.velocity,
      ),
    );
  }

  double _posFromDx(double dx) => ((dx - _inset) / _itemWidth - 0.5)
      .clamp(0.0, _items.length - 1.0)
      .toDouble();

  void _onItemTap(int index) {
    if (index == widget.currentIndex) {
      HapticFeedback.selectionClick();
      widget.onTap(index); // re-tap: parent scrolls to top
      return;
    }
    HapticFeedback.selectionClick();
    _animateTo(index);
    widget.onTap(index);
  }

  // Finger down on the pill = it grows immediately (like iOS), even before moving.
  void _onPointerDown(PointerDownEvent e) {
    if ((_posFromDx(e.localPosition.dx) - _c.value).abs() < 0.6) {
      _setPressed(true);
    }
  }

  void _onPointerUp(PointerEvent e) {
    if (!_dragging) _setPressed(false);
  }

  void _onDragStart(DragStartDetails d) {
    _dragging = true;
    _dragPos = _posFromDx(d.localPosition.dx);
    _lastHapticIndex = _c.value.round();
    _setPressed(true);
    _followTo(_dragPos);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _dragPos = _posFromDx(d.localPosition.dx);
    _followTo(_dragPos);
    final nearest = _dragPos.round();
    if (nearest != _lastHapticIndex) {
      _lastHapticIndex = nearest;
      HapticFeedback.selectionClick();
    }
  }

  void _onDragEnd(DragEndDetails d) {
    final vel = d.velocity.pixelsPerSecond.dx / _itemWidth;
    final target = (_dragPos + vel * 0.08)
        .round()
        .clamp(0, _items.length - 1)
        .toInt();
    _dragging = false;
    _setPressed(false);
    _animateTo(target, velocity: _c.velocity);
    if (target != widget.currentIndex) widget.onTap(target);
  }

  void _onDragCancel() {
    _dragging = false;
    _setPressed(false);
    _animateTo(widget.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final margin = EdgeInsets.fromLTRB(
      20,
      0,
      20,
      bottomInset > 0 ? bottomInset + 4 : 12,
    );

    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: margin,
        child: SizedBox(
          height: _barHeight,
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerUp,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              onHorizontalDragCancel: _onDragCancel,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _itemWidth =
                      (constraints.maxWidth - _inset * 2) / _items.length;
                  return Stack(
                    clipBehavior:
                        Clip.none, // lets the held pill overflow the bar
                    children: [
                      Positioned.fill(child: _buildGlass()),
                      _buildLens(),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: _inset,
                          ),
                          child: Row(
                            children: List.generate(_items.length, _buildItem),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlass() {
    return CustomPaint(
      painter: const _GlassShadowPainter(_barRadius),
      foregroundPainter: const _GlassBorderPainter(_barRadius),
      child: ClipRRect(
        borderRadius: _barRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLens() {
    return AnimatedBuilder(
      animation: Listenable.merge([_c, _press]),
      builder: (context, _) {
        final p = _press.value.clamp(0.0, 1.3).toDouble();
        final stretch = (_c.velocity.abs() * 0.05).clamp(0.0, 0.4).toDouble();

        final w = (_itemWidth - 4) * (1 + 0.24 * p + stretch);
        final h =
            ((_barHeight - _inset * 2) + (_lensRise + _lensDrop) * p) *
            (1 - stretch * 0.15);

        final cx = _inset + (_c.value + 0.5) * _itemWidth;
        // Grows mostly upward: centre shifts up by (rise - drop) / 2.
        final cy = _barHeight / 2 - (_lensRise - _lensDrop) / 2 * p;

        return Positioned(
          left: cx - w / 2,
          top: cy - h / 2,
          width: w,
          height: h,
          child: IgnorePointer(child: CustomPaint(painter: _LensPainter(p))),
        );
      },
    );
  }

  Widget _buildItem(int index) {
    final item = _items[index];

    return Expanded(
      child: Semantics(
        button: true,
        selected: index == widget.currentIndex,
        label: item.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onItemTap(index),
          child: SizedBox(
            height: _barHeight,
            child: AnimatedBuilder(
              animation: Listenable.merge([_c, _press]),
              builder: (context, _) {
                final t = (1 - (_c.value - index).abs())
                    .clamp(0.0, 1.0)
                    .toDouble();
                final press = _press.value.clamp(0.0, 1.3).toDouble();
                final active = t > 0.5;
                final color = Color.lerp(
                  const Color(0xFF2E3238),
                  AppTheme.primary,
                  t,
                )!;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Transform.scale(
                          scale: 1 + 0.08 * t + 0.10 * t * press,
                          child: Icon(
                            active ? item.activeIcon : item.icon,
                            size: 24,
                            color: color,
                          ),
                        ),
                        if (item.hasBadge && widget.cartCount > 0)
                          Positioned(
                            top: -5,
                            right: -10,
                            child: _Badge(count: widget.cartCount),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: color,
                        letterSpacing: -0.1,
                        height: 1.1,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Pieces
// -----------------------------------------------------------------------------

/// Glass pill: opaque-ish at rest, nearly clear when held. Shadow is drawn
/// only outside the pill so it never shows through the transparent glass.
class _LensPainter extends CustomPainter {
  final double press;
  const _LensPainter(this.press);

  @override
  void paint(Canvas canvas, Size size) {
    final q = press.clamp(0.0, 1.0).toDouble();
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.shortestSide / 2),
    );

    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect.inflate(60)),
      Path()..addRRect(rrect),
    );
    canvas.save();
    canvas.clipPath(outside);
    canvas.drawRRect(
      rrect.shift(Offset(0, 3 + 5 * q)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.05 + 0.07 * q)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 7 + 7 * q),
    );
    canvas.restore();

    // Faint brand tint at rest, fades out when held.
    canvas.drawRRect(
      rrect,
      Paint()..color = AppTheme.primary.withValues(alpha: 0.06 * (1 - q)),
    );

    // Body
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: lerpDouble(0.15, 0.30, q)!),
            Colors.black.withValues(alpha: lerpDouble(0.10, 0.08, q)!),
          ],
        ).createShader(rect),
    );

    // Rim light
    canvas.drawRRect(
      rrect.deflate(0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: lerpDouble(0, 1.0, q)!),
            Colors.white.withValues(alpha: lerpDouble(0, 0.15, q)!),
            Colors.white.withValues(alpha: lerpDouble(0, 0.90, q)!),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _LensPainter old) => old.press != press;
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 1.4),
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

/// Soft shadow drawn ONLY outside the bar so the glass stays clear.
class _GlassShadowPainter extends CustomPainter {
  final BorderRadius radius;
  const _GlassShadowPainter(this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = radius.toRRect(Offset.zero & size);
    final outside = Path.combine(
      PathOperation.difference,
      Path()
        ..addRect(Rect.fromLTWH(-80, -80, size.width + 160, size.height + 160)),
      Path()..addRRect(rrect),
    );
    canvas.save();
    canvas.clipPath(outside);
    canvas.drawRRect(
      rrect.shift(const Offset(0, 8)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlassShadowPainter old) => old.radius != radius;
}

/// Thin edge hairline + gradient highlight, like light catching glass.
class _GlassBorderPainter extends CustomPainter {
  final BorderRadius radius;
  const _GlassBorderPainter(this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = radius.toRRect(rect);

    canvas.drawRRect(
      rrect.deflate(0.4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.black.withValues(alpha: 0.07),
    );

    canvas.drawRRect(
      rrect.deflate(1.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.20),
            Colors.white.withValues(alpha: 0.70),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _GlassBorderPainter old) => old.radius != radius;
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool hasBadge;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.hasBadge = false,
  });
}
