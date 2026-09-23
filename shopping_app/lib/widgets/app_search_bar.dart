import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

enum _AppSearchBarMode { trigger, field }

/// A unified, highly-polished 24dp pill-shaped search bar used across the app.
///
/// Provides two constructors:
/// - [AppSearchBar.trigger]: A read-only tap trigger that launches the search screen.
/// - [AppSearchBar.field]: An interactive input field with clear action and focus support.
class AppSearchBar extends StatefulWidget {
  final _AppSearchBarMode _mode;
  final String hintText;
  final double height;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  // Field specific
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;

  /// Creates a read-only trigger search bar that runs [onTap] when pressed.
  const AppSearchBar.trigger({
    super.key,
    required this.onTap,
    this.hintText = 'Search products, electronics, deals...',
    this.height = 48,
    this.margin,
  })  : _mode = _AppSearchBarMode.trigger,
        controller = null,
        focusNode = null,
        autofocus = false,
        onChanged = null,
        onSubmitted = null,
        onClear = null;

  /// Creates an interactive search input field with auto-clearing and callbacks.
  const AppSearchBar.field({
    super.key,
    required this.controller,
    this.focusNode,
    this.autofocus = false,
    this.hintText = 'Search products, tags, categories...',
    this.height = 48,
    this.margin,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  })  : _mode = _AppSearchBarMode.field,
        onTap = null;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  @override
  void initState() {
    super.initState();
    if (widget._mode == _AppSearchBarMode.field && widget.controller != null) {
      widget.controller!.addListener(_handleTextChange);
    }
  }

  @override
  void didUpdateWidget(covariant AppSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleTextChange);
      widget.controller?.addListener(_handleTextChange);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleTextChange);
    super.dispose();
  }

  void _handleTextChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(24));

    if (widget._mode == _AppSearchBarMode.trigger) {
      return Container(
        height: widget.height,
        margin: widget.margin,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: borderRadius,
          border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppTheme.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.hintText,
                      style: const TextStyle(
                        color: AppTheme.secondary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final hasText = widget.controller?.text.isNotEmpty ?? false;

    return Container(
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        textInputAction: TextInputAction.search,
        textAlignVertical: TextAlignVertical.center,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        style: const TextStyle(fontSize: 14, color: AppTheme.onSurface),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppTheme.surfaceContainerLowest,
          hintText: widget.hintText,
          hintStyle: const TextStyle(fontSize: 13.5, color: AppTheme.secondary),
          prefixIcon: const Icon(Icons.search_rounded, size: 22, color: AppTheme.primary),
          suffixIcon: hasText
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.secondary),
                  onPressed: () {
                    widget.controller?.clear();
                    widget.onClear?.call();
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.6)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.8), width: 1.2),
          ),
        ),
      ),
    );
  }
}
