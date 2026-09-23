import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A floating top notification banner overlay featuring animations,
/// solid border, subtle shadow, and customized messaging for login,
/// registration, and logout states.
class TopWelcomeBanner extends StatefulWidget {
  final String? name;
  final bool isNewUser;
  final bool isLogout;
  final String? customTitle;
  final String? customSubtitle;
  final VoidCallback onDismissed;

  const TopWelcomeBanner({
    super.key,
    this.name,
    this.isNewUser = false,
    this.isLogout = false,
    this.customTitle,
    this.customSubtitle,
    required this.onDismissed,
  });

  /// Displays the top welcome banner overlay on top of the current screen.
  static void show(
    BuildContext context, {
    required String name,
    required bool isNewUser,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => TopWelcomeBanner(
        name: name,
        isNewUser: isNewUser,
        isLogout: false,
        onDismissed: () {
          if (entry.mounted) {
            entry.remove();
          }
        },
      ),
    );

    overlay.insert(entry);
  }

  /// Displays the top logout banner overlay when a user logs out.
  static void showLogout(
    BuildContext context, {
    String title = 'Signed Out Successfully',
    String subtitle = 'You are now browsing in guest mode.',
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => TopWelcomeBanner(
        isLogout: true,
        customTitle: title,
        customSubtitle: subtitle,
        onDismissed: () {
          if (entry.mounted) {
            entry.remove();
          }
        },
      ),
    );

    overlay.insert(entry);
  }

  @override
  State<TopWelcomeBanner> createState() => _TopWelcomeBannerState();
}

class _TopWelcomeBannerState extends State<TopWelcomeBanner>
    with TickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  late final AnimationController _waveController;
  late final Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();

    // Slide and fade entrance/exit animation
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      reverseDuration: const Duration(milliseconds: 350),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideController,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Waving hand oscillating rotation (-14° to +14°)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _waveAnimation = Tween<double>(begin: -0.25, end: 0.25).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    // Start entrance and wave loop
    _slideController.forward();
    if (!widget.isLogout) {
      _waveController.repeat(reverse: true);
    }

    // Auto-dismiss after 3.6 seconds
    Future.delayed(const Duration(milliseconds: 3600), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    _waveController.stop();
    await _slideController.reverse();
    if (mounted) {
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  String _getFirstName(String rawName) {
    final trimmed = rawName.trim();
    if (trimmed.isEmpty) return '';
    // Split by whitespace or delimiters (e.g., from email handles like john.doe)
    final parts = trimmed.split(RegExp(r'[\s._\-]+'));
    if (parts.isNotEmpty && parts.first.isNotEmpty) {
      final first = parts.first;
      return first[0].toUpperCase() + first.substring(1);
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final String title;
    final String subtitle;

    if (widget.isLogout) {
      title = widget.customTitle ?? 'Signed Out Successfully';
      subtitle = widget.customSubtitle ?? 'You are now browsing in guest mode.';
    } else {
      final firstName = _getFirstName(widget.name ?? '');
      final displayName = firstName.isNotEmpty
          ? firstName
          : (widget.isNewUser ? 'Friend' : 'Member');

      title = widget.isNewUser
          ? 'Welcome to Shopping App, $displayName!'
          : 'Welcome back, $displayName!';

      subtitle = widget.isNewUser
          ? 'Your journey starts here. Happy shopping! 🎉'
          : "Great to see you again. Explore today's picks! ✨";
    }

    final borderColor = widget.isLogout
        ? const Color(0xFF64748B)
        : AppTheme.primary;

    final shadowColor = widget.isLogout
        ? const Color(0xFF475569).withOpacity(0.14)
        : AppTheme.primary.withOpacity(0.12);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: true,
        bottom: false,
        child: ClipRect(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: _dismiss,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: borderColor,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (widget.isLogout)
                            // Logout icon badge
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                  width: 1.0,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.logout_rounded,
                                  color: Color(0xFF475569),
                                  size: 22,
                                ),
                              ),
                            )
                          else
                            // Waving hand icon with oscillating animation
                            AnimatedBuilder(
                              animation: _waveAnimation,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _waveAnimation.value,
                                  origin: const Offset(14, 20),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.primary.withOpacity(0.20),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '👋',
                                        style: TextStyle(fontSize: 22),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          const SizedBox(width: 14),

                          // Text Message Block
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: widget.isLogout
                                        ? const Color(0xFF1E293B)
                                        : AppTheme.primary,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                    height: 1.25,
                                  ),
                                  softWrap: true,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  subtitle,
                                  style: const TextStyle(
                                    color: AppTheme.secondary,
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.1,
                                    height: 1.3,
                                  ),
                                  softWrap: true,
                                ),
                              ],
                            ),
                          ),

                          // Dismiss icon
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppTheme.secondary.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
