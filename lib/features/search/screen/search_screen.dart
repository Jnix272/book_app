import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app_theme.dart';
import '../../../domain/models/models.dart';
import '../../../providers/repository_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/favorites_service.dart';

// ── Filter state ──────────────────────────────────────────────
class _SearchFilters {
  String category;
  double minRating;
  double maxPrice;
  String sortBy;

  _SearchFilters({
    this.category = 'All',
    this.minRating = 0,
    this.maxPrice = double.infinity,
    this.sortBy = 'rating',
  });
}

class SearchScreen extends ConsumerStatefulWidget {
  final String initialQuery;
  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchController;
  late _SearchFilters _filters;

  List<ServiceProvider> _results = [];
  bool _isLoading = false;
  String? _error;

  // Debounce
  DateTime? _lastSearch;

  static const List<String> _categories = [
    'All',
    'Hair',
    'Massage',
    'Dental',
    'Fitness',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _filters = _SearchFilters();
    _runSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final query = _searchController.text.trim();
    final now = DateTime.now();
    _lastSearch = now;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Simple debounce - 400ms
    await Future.delayed(const Duration(milliseconds: 400));
    if (_lastSearch != now) return; // superseded

    try {
      final providers = await ref.read(providerRepositoryProvider).searchProviders(
        query: query,
        category: _filters.category,
        minRating: _filters.minRating,
        maxPrice: _filters.maxPrice,
        sortBy: _filters.sortBy,
      );

      if (mounted) {
        setState(() {
          _results = providers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load results. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        leading: const BackButton(),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search providers, services…',
            hintStyle: GoogleFonts.dmSans(color: AppColors.muted, fontSize: 15),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _runSearch();
                    },
                  )
                : null,
          ),
          onChanged: (_) => _runSearch(),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _runSearch(),
        ),
        shape: const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filter Row ───────────────────────────────────
          _FilterRow(
            filters: _filters,
            categories: _categories,
            onChanged: (updated) {
              setState(() => _filters = updated);
              _runSearch();
            },
          ),

          // ── Results ──────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.sage),
                  )
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: GoogleFonts.dmSans(color: AppColors.muted),
                    ),
                  )
                : _results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔍', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text(
                          'No providers found',
                          style: GoogleFonts.dmSans(
                            color: AppColors.muted,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try adjusting your filters',
                          style: GoogleFonts.dmSans(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Text(
                          '${_results.length} result${_results.length == 1 ? '' : 's'}',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                          itemCount: _results.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) =>
                              _SearchProviderCard(provider: _results[i]),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Row Widget ─────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final _SearchFilters filters;
  final List<String> categories;
  final ValueChanged<_SearchFilters> onChanged;

  const _FilterRow({
    required this.filters,
    required this.categories,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Category chips
          ...categories.map((cat) {
            final selected = filters.category == cat;
            return GestureDetector(
              onTap: () {
                final updated = _SearchFilters(
                  category: cat,
                  minRating: filters.minRating,
                  maxPrice: filters.maxPrice,
                  sortBy: filters.sortBy,
                );
                onChanged(updated);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.sage : AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.sage : AppColors.line,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  cat,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : AppColors.ink2,
                  ),
                ),
              ),
            );
          }),

          const SizedBox(width: 4),
          // Rating filter
          _FilterButton(
            label: filters.minRating > 0
                ? '⭐ ${filters.minRating.toStringAsFixed(0)}+'
                : 'Rating',
            active: filters.minRating > 0,
            onTap: () => _showRatingPicker(context),
          ),
          const SizedBox(width: 8),
          // Price filter
          _FilterButton(
            label: filters.maxPrice == double.infinity
                ? 'Price'
                : filters.maxPrice == 0
                ? 'Free'
                : 'Under \$${filters.maxPrice.toStringAsFixed(0)}',
            active: filters.maxPrice != double.infinity,
            onTap: () => _showPricePicker(context),
          ),
          const SizedBox(width: 8),
          // Sort
          _FilterButton(
            label: filters.sortBy == 'rating' ? 'Top Rated' : 'Most Reviewed',
            active: false,
            onTap: () {
              final updated = _SearchFilters(
                category: filters.category,
                minRating: filters.minRating,
                maxPrice: filters.maxPrice,
                sortBy: filters.sortBy == 'rating' ? 'reviews' : 'rating',
              );
              onChanged(updated);
            },
          ),
        ],
      ),
    );
  }

  void _showRatingPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Minimum Rating',
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [0, 3, 4, 5].map((r) {
                  final selected = filters.minRating == r.toDouble();
                  return GestureDetector(
                    onTap: () {
                      final updated = _SearchFilters(
                        category: filters.category,
                        minRating: r.toDouble(),
                        maxPrice: filters.maxPrice,
                        sortBy: filters.sortBy,
                      );
                      onChanged(updated);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.sage : AppColors.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? AppColors.sage : AppColors.line,
                        ),
                      ),
                      child: Text(
                        r == 0 ? 'Any' : '⭐ $r+',
                        style: GoogleFonts.dmSans(
                          color: selected ? Colors.white : AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPricePicker(BuildContext context) {
    final options = [
      ('Any Price', double.infinity),
      ('Free', 0.0),
      ('Under \$50', 50.0),
      ('Under \$100', 100.0),
      ('Under \$200', 200.0),
    ];

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Max Price',
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...options.map(((String, double) opt) {
                final selected = filters.maxPrice == opt.$2;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    opt.$1,
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                  ),
                  trailing: selected
                      ? const Icon(Icons.check_circle, color: AppColors.sage)
                      : null,
                  onTap: () {
                    final updated = _SearchFilters(
                      category: filters.category,
                      minRating: filters.minRating,
                      maxPrice: opt.$2,
                      sortBy: filters.sortBy,
                    );
                    onChanged(updated);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.amberLight : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.amber : AppColors.line,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active ? AppColors.amber : AppColors.ink2,
          ),
        ),
      ),
    );
  }
}

// ── Provider Card ─────────────────────────────────────────────

Color _avatarColor(String category) {
  switch (category) {
    case 'Hair':
      return AppColors.sageLight;
    case 'Massage':
      return AppColors.amberLight;
    case 'Dental':
      return AppColors.bg;
    case 'Fitness':
      return AppColors.redLight;
    default:
      return AppColors.line;
  }
}

class _SearchProviderCard extends StatefulWidget {
  final ServiceProvider provider;
  const _SearchProviderCard({required this.provider});

  @override
  State<_SearchProviderCard> createState() => _SearchProviderCardState();
}

class _SearchProviderCardState extends State<_SearchProviderCard> {
  @override
  void initState() {
    super.initState();
    FavoritesService.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    FavoritesService.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isFav = FavoritesService.instance.isFavorite(widget.provider.id);
    final p = widget.provider;

    return GestureDetector(
      onTap: () => context.push('/provider', extra: p),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _avatarColor(p.category),
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: p.avatarUrl != null && p.avatarUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: p.avatarUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.sage.withAlpha(128),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Text(
                            p.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          p.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '⭐ ${p.rating} · ${p.category}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                    if (p.services.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'From \$${p.services.map((s) => s.price).reduce((a, b) => a < b ? a : b).toStringAsFixed(0)}',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.sage,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? AppColors.red : AppColors.muted,
                  size: 22,
                ),
                onPressed: () => FavoritesService.instance.toggleFavorite(p.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
