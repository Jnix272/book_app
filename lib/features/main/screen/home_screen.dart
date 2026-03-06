import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app_theme.dart';
import '../../../models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/favorites_service.dart';

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

class _ProviderCard extends StatefulWidget {
  final ServiceProvider provider;
  const _ProviderCard({required this.provider});

  @override
  State<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<_ProviderCard> {
  // Track previous favorite state to avoid spurious rebuilds.
  // When the listener fires, only call setState if THIS card's status changed.
  late bool _isFav;

  @override
  void initState() {
    super.initState();
    _isFav = FavoritesService.instance.isFavorite(widget.provider.id);
    FavoritesService.instance.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    FavoritesService.instance.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    final updated = FavoritesService.instance.isFavorite(widget.provider.id);
    // Only rebuild if THIS provider's status actually changed
    if (updated != _isFav && mounted) {
      setState(() => _isFav = updated);
    }
  }

  // Pre-compute min price once per build instead of calling reduce every frame.
  double? get _minPrice {
    if (widget.provider.services.isEmpty) return null;
    double min = widget.provider.services.first.price;
    for (final s in widget.provider.services) {
      if (s.price < min) min = s.price;
    }
    return min;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => context.push('/provider', extra: widget.provider),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _avatarColor(widget.provider.category),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip
                      .antiAlias, // Important for CachedNetworkImage corners
                  child:
                      widget.provider.avatarUrl != null &&
                          widget.provider.avatarUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.provider.avatarUrl!,
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
                              widget.provider.emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            widget.provider.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                ),
                const SizedBox(width: 14),

                // info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.provider.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '⭐ ${widget.provider.rating} · ${widget.provider.category} · ${widget.provider.distance}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: widget.provider.services
                            .take(3)
                            .map(
                              (s) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.bg,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.line),
                                ),
                                child: Text(
                                  s.name,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: AppColors.ink2,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // price + availability
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isFav ? Icons.favorite : Icons.favorite_border,
                        color: _isFav ? AppColors.red : AppColors.muted,
                        size: 22,
                      ),
                      onPressed: () {
                        FavoritesService.instance.toggleFavorite(
                          widget.provider.id,
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(height: 8),
                    if (_minPrice != null)
                      Text(
                        'From \$${_minPrice!.toStringAsFixed(0)}',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Available today',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.sage,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> allCategories = [
    'All',
    'Hair',
    'Massage',
    'Dental',
    'Fitness',
  ];
  List<ServiceProvider> _allProviders = [];

  // Memoized derived lists — updated only when source data changes
  List<ServiceProvider> _filteredProviders = [];
  List<Map<String, dynamic>> _allServices = [];

  bool _isLoading = true;
  String _firstName = 'User';
  String _initial = 'U';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  /// Recomputes both memoized lists. Call after any change to
  /// `_allProviders` or `_selectedCategory`.
  void _recompute() {
    _filteredProviders = _selectedCategory == 'All'
        ? List.of(_allProviders)
        : _allProviders.where((p) => p.category == _selectedCategory).toList();

    _allServices = [
      for (final provider in _allProviders)
        for (final svc in provider.services)
          {'service': svc, 'provider': provider},
    ];
  }

  Future<void> _fetchData() async {
    dev.Timeline.startSync('HomeScreen._fetchData');
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        dev.Timeline.startSync('HomeScreen.fetchUserName');
        try {
          final userData = await Supabase.instance.client
              .from('users')
              .select('first_name')
              .eq('user_id', user.id)
              .maybeSingle();
          if (mounted) {
            setState(() {
              _firstName =
                  (userData?['first_name'] as String?) ??
                  (user.userMetadata?['first_name'] as String?) ??
                  'User';
              _initial = _firstName.isNotEmpty
                  ? _firstName[0].toUpperCase()
                  : 'U';
            });
          }
        } finally {
          dev.Timeline.finishSync();
        }
      }

      dev.Timeline.startSync('HomeScreen.fetchProviders');
      late final List rawProviders;
      try {
        rawProviders = await Supabase.instance.client
            .from('providers')
            .select(
              'provider_id, business_name, average_rating, total_reviews, address, category, emoji, avatar_url, services(service_id, provider_id, service_name, description, price, duration_minutes, buffer_minutes)',
            );
      } finally {
        dev.Timeline.finishSync();
      }

      dev.Timeline.startSync('HomeScreen.parseProviders');
      late final List<ServiceProvider> providers;
      try {
        providers = rawProviders
            .map((p) => ServiceProvider.fromJson(p as Map<String, dynamic>))
            .toList();
      } finally {
        dev.Timeline.finishSync();
      }

      if (mounted) {
        setState(() {
          _allProviders = providers;
          _recompute();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load providers: $e')));
      }
    } finally {
      dev.Timeline.finishSync(); // HomeScreen._fetchData
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _categoryEmoji(String cat) {
    switch (cat) {
      case 'Hair':
        return '✂️';
      case 'Massage':
        return '💆‍♀️';
      case 'Dental':
        return '🦷';
      case 'Fitness':
        return '💪';
      case 'All':
        return '✨';
      default:
        return '📍';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.white,
            surfaceTintColor: Colors.transparent,
            title: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Book',
                    style: GoogleFonts.fraunces(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sage,
                    ),
                  ),
                  TextSpan(
                    text: 'it',
                    style: GoogleFonts.fraunces(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amber,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.sage,
                    child: Text(
                      _initial,
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            shape: const Border(bottom: BorderSide(color: AppColors.line)),
          ),

          // ── Greeting ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Good morning, $_firstName ',
                          style: GoogleFonts.fraunces(
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ink,
                          ),
                        ),
                        TextSpan(
                          text: '✦',
                          style: GoogleFonts.fraunces(
                            fontSize: 24,
                            color: AppColors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'What would you like to book today?',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 20),

                  // ── Search bar (tap to open SearchScreen) ────────
                  GestureDetector(
                    onTap: () => context.push('/search'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            color: AppColors.muted,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Search providers, services…',
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Category pills ───────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: allCategories.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = allCategories[i];
                  final selected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedCategory = cat;
                      _recompute();
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
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
                        _categoryEmoji(cat) + (cat == 'All' ? '' : ' ') + cat,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: selected ? Colors.white : AppColors.ink2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Popular Services carousel ─────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 8, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SectionLabel('Popular Services'),
                  TextButton(
                    onPressed: () => context.push('/search'),
                    child: Text(
                      'See all',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.sage,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 130,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.sage),
                    )
                  : _allServices.isEmpty
                  ? Center(
                      child: Text(
                        'No services yet',
                        style: GoogleFonts.dmSans(color: AppColors.muted),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _allServices.length,
                      separatorBuilder: (_, x) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final svc = _allServices[i]['service'] as ServiceItem;
                        final prov =
                            _allServices[i]['provider'] as ServiceProvider;
                        return GestureDetector(
                          onTap: () => context.push('/provider', extra: prov),
                          child: RepaintBoundary(
                            child: Container(
                              width: 160,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    svc.name,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Text(
                                    prov.name,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      color: AppColors.muted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '\$${svc.price.toStringAsFixed(0)}',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.sage,
                                        ),
                                      ),
                                      Text(
                                        '${svc.durationMin} min',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 11,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
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

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Section label: Providers ──────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionLabel(
                _selectedCategory == 'All'
                    ? 'Featured Providers'
                    : _selectedCategory,
              ),
            ),
          ),

          // ── Provider list ────────────────────────────
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.sage),
              ),
            )
          else if (_filteredProviders.isEmpty)
            SliverFillRemaining(
              child: Center(
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
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList.separated(
                itemCount: _filteredProviders.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, i) =>
                    _ProviderCard(provider: _filteredProviders[i]),
              ),
            ),
        ],
      ),
    );
  }
}
