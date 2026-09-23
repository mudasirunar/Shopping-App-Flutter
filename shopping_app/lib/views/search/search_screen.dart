import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/product_card.dart';
import '../details/product_details_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const String _recentSearchesKey = 'recent_search_queries_v1';
  static const List<String> _popularSuggestions = [
    'Wireless Headphones',
    'Gooseneck Kettle',
    'Smart Watch',
    'Leather',
    'Sneakers',
    'Ceramic Vase',
    'Backpack',
    'Aroma Diffuser',
    'Sunglasses',
    'Mechanical Keyboard',
  ];

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _recentSearches = [];
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _controller.text = widget.initialQuery!.trim();
      _currentQuery = widget.initialQuery!.trim();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_recentSearchesKey) ?? [];
      if (mounted) {
        setState(() {
          _recentSearches = list;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveSearchQuery(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> list = List.from(_recentSearches);
      list.removeWhere((item) => item.toLowerCase() == clean.toLowerCase());
      list.insert(0, clean);
      if (list.length > 8) {
        list = list.sublist(0, 8);
      }
      await prefs.setStringList(_recentSearchesKey, list);
      if (mounted) {
        setState(() {
          _recentSearches = list;
        });
      }
    } catch (_) {}
  }

  Future<void> _removeRecentSearch(String item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> list = List.from(_recentSearches);
      list.removeWhere((i) => i.toLowerCase() == item.toLowerCase());
      await prefs.setStringList(_recentSearchesKey, list);
      if (mounted) {
        setState(() {
          _recentSearches = list;
        });
      }
    } catch (_) {}
  }

  Future<void> _clearAllRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSearchesKey);
      if (mounted) {
        setState(() {
          _recentSearches = [];
        });
      }
    } catch (_) {}
  }

  void _onSearchSubmitted(String query) {
    _saveSearchQuery(query);
  }

  void _applySuggestion(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    setState(() {
      _currentQuery = text;
    });
    _saveSearchQuery(text);
  }

  int _calculateRelevanceScore(Product p, String query, List<String> tokens) {
    final name = p.name.toLowerCase();
    final desc = p.description.toLowerCase();
    final cat = p.category.toLowerCase();
    final badge = (p.badgeTag ?? '').toLowerCase();
    final quality = (p.qualityTag ?? '').toLowerCase();
    final deal = (p.dealTag ?? '').toLowerCase();
    final specs = p.safeSpecifications.values.join(' ').toLowerCase();

    int score = 0;

    // 1. Direct and prefix matches on product title (Highest Weight)
    if (name == query) {
      score += 10000;
    } else if (name.startsWith(query)) {
      score += 7000;
    } else if (name.contains(query)) {
      score += 4500;
    }

    // 2. Token occurrences in title
    int tokensInTitle = 0;
    for (final token in tokens) {
      if (name.contains(token)) {
        tokensInTitle++;
        // If token starts at a word boundary (e.g. "Pro Wireless" matches "wireless")
        if (RegExp(r'(^|\s)' + RegExp.escape(token)).hasMatch(name)) {
          score += 1200;
        } else {
          score += 700;
        }
      }
    }
    // Extra bonus if every query token appears inside the product title
    if (tokensInTitle == tokens.length) {
      score += 3000;
    }

    // 3. Category match
    if (cat == query) {
      score += 2000;
    } else if (cat.contains(query)) {
      score += 1000;
    }
    for (final token in tokens) {
      if (cat.contains(token)) score += 400;
    }

    // 4. Badges, Deal tags, and Quality tags
    for (final token in tokens) {
      if (deal.contains(token) || badge.contains(token) || quality.contains(token)) {
        score += 250;
      }
    }

    // 5. Description & Specifications (Lower Priority)
    if (desc.contains(query)) {
      score += 200;
    }
    for (final token in tokens) {
      if (desc.contains(token)) score += 60;
      if (specs.contains(token)) score += 30;
    }

    return score;
  }

  List<Product> _matchProducts(List<Product> allProducts, String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return [];

    final tokens = query.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    // 1. Filter: product must contain all tokens across its search metadata
    final matched = allProducts.where((p) {
      final name = p.name.toLowerCase();
      final desc = p.description.toLowerCase();
      final cat = p.category.toLowerCase();
      final badge = (p.badgeTag ?? '').toLowerCase();
      final quality = (p.qualityTag ?? '').toLowerCase();
      final deal = (p.dealTag ?? '').toLowerCase();
      final specsValues = p.safeSpecifications.values.join(' ').toLowerCase();

      final fullBlob = '$name $desc $cat $badge $quality $deal $specsValues';
      return tokens.every((token) => fullBlob.contains(token));
    }).toList();

    // 2. Sort by query relevance (title matches first), then alphabetical A-Z
    matched.sort((a, b) {
      final scoreA = _calculateRelevanceScore(a, query, tokens);
      final scoreB = _calculateRelevanceScore(b, query, tokens);

      if (scoreA != scoreB) {
        return scoreB.compareTo(scoreA); // Highest score first
      }

      // Tie-breaker: Alphabetical order (A to Z) by product name
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return matched;
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final allProducts = catalog.allProducts;
    final searchResults = _matchProducts(allProducts, _currentQuery);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          height: 42,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: widget.initialQuery == null || widget.initialQuery!.isEmpty,
            textInputAction: TextInputAction.search,
            onChanged: (val) {
              setState(() {
                _currentQuery = val;
              });
            },
            onSubmitted: _onSearchSubmitted,
            style: const TextStyle(fontSize: 14, color: AppTheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Search products, tags, categories...',
              hintStyle: const TextStyle(fontSize: 13.5, color: AppTheme.secondary),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.secondary),
              suffixIcon: _currentQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.secondary),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _currentQuery = '';
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: _currentQuery.trim().isEmpty
          ? _buildSuggestionsAndHistory()
          : _buildSearchResults(searchResults),
    );
  }

  Widget _buildSuggestionsAndHistory() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches Block
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_rounded, size: 18, color: AppTheme.secondary),
                    SizedBox(width: 6),
                    Text(
                      'Recent Searches',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _clearAllRecentSearches,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppTheme.secondary,
                  ),
                  child: const Text(
                    'Clear All',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((item) {
                return InkWell(
                  onTap: () => _applySuggestion(item),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeRecentSearch(item),
                          child: const Icon(Icons.close_rounded, size: 14, color: AppTheme.secondary),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1, color: AppTheme.outlineVariant),
            const SizedBox(height: 20),
          ],

          // Popular & Trending Searches
          const Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 18, color: AppTheme.primary),
              SizedBox(width: 6),
              Text(
                'Trending Searches',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularSuggestions.map((tag) {
              return ActionChip(
                backgroundColor: AppTheme.surfaceContainerLowest,
                side: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                avatar: const Icon(Icons.search, size: 14, color: AppTheme.secondary),
                label: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onSurface,
                  ),
                ),
                onPressed: () => _applySuggestion(tag),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // Search Hint Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.tips_and_updates_outlined, size: 20, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Search Tips',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Search by product name, features (e.g. "wireless", "noise cancelling"), or categories like Fashion & Electronics.',
                        style: TextStyle(fontSize: 11.5, color: AppTheme.secondary, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<Product> results) {
    if (results.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_off_rounded, size: 36, color: AppTheme.secondary),
              ),
              const SizedBox(height: 18),
              Text(
                'No results for "$_currentQuery"',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Try checking your spelling, using broader terms, or explore popular categories below.',
                style: TextStyle(fontSize: 13, color: AppTheme.secondary, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  'Electronics',
                  'Fashion',
                  'Home & Living',
                  'Headphones',
                ].map((sug) {
                  return ActionChip(
                    backgroundColor: AppTheme.surfaceContainerLowest,
                    side: const BorderSide(color: AppTheme.outlineVariant),
                    label: Text(sug, style: const TextStyle(fontSize: 12, color: AppTheme.primary)),
                    onPressed: () => _applySuggestion(sug),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results count header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${results.length} ${results.length == 1 ? 'Product' : 'Products'} found',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.secondary),
              ),
              Text(
                'Matching "$_currentQuery"',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.secondary),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final product = results[index];
              return ProductCard(
                product: product,
                isWide: false,
                showCategory: true,
                onTap: () {
                  _saveSearchQuery(_currentQuery);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductDetailsScreen(product: product),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
