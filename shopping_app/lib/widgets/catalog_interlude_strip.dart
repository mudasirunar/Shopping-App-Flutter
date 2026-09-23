import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// An ambient promotional/trust interlude strip inserted in the product feed.
/// Features a 1-tap coupon copy strip with clipboard feedback and animated badge,
/// plus a verified trust guarantee row.
class CatalogInterludeStrip extends StatefulWidget {
  const CatalogInterludeStrip({super.key});

  @override
  State<CatalogInterludeStrip> createState() => _CatalogInterludeStripState();
}

class _CatalogInterludeStripState extends State<CatalogInterludeStrip> {
  bool _copied = false;

  void _copyCode() async {
    await Clipboard.setData(const ClipboardData(text: 'FREESHIP'));
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: _copied ? null : _copyCode,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _copied
                      ? [const Color(0xFF059669), const Color(0xFF047857)]
                      : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (_copied
                            ? const Color(0xFF059669)
                            : const Color(0xFF1E293B))
                        .withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _copied ? Icons.check_rounded : Icons.local_shipping_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Copy text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _copied
                              ? 'FREESHIP Copied ✓'
                              : 'Free Insured Air Courier',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _copied
                              ? 'Paste at checkout to apply'
                              : 'Orders over Rs. 3,000 • Code: FREESHIP',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tap to copy indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(_copied ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _copied ? 'Done' : 'Tap to Copy',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
          ),
        ),
      ),
    );
  }
}
