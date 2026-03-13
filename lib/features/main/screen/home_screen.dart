
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app_theme.dart';
import '../../../domain/models/models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/customer_providers.dart';

import '../widgets/provider_card.dart';

// Ambient radial gradient background
class _AmbientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    void drawRadial(Offset center, double radius, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    drawRadial(Offset(size.width * 0.2, size.height * 0.1),
        size.width * 0.7, const Color(0xFF7820C8).withValues(alpha: 0.18));
    drawRadial(Offset(size.width * 0.8, size.height * 0.9),
        size.width * 0.6, const Color(0xFFC8501A).withValues(alpha: 0.12));
    drawRadial(Offset(size.width * 0.6, size.height * 0.4),
        size.width * 0.5, const Color(0xFF1E8050).withValues(alpha: 0.08));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Old _ProviderCard removed

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> allCategories = [
    'All',
    'Hair',
    'Massage',
    'Dental',
    'Fitness',
  ];


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
    // 1. Auth bindings
    final authState = ref.watch(authProvider);
    final String firstName = authState is AuthAuthenticated 
      ? authState.fullName.split(' ').first 
      : 'User';
    final String initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';

    // 2. Data bindings
    final feedAsync = ref.watch(homeFeedProvider);
    final bool _isLoading = feedAsync.isLoading;
    final List<ServiceProvider> _allProviders = feedAsync.valueOrNull ?? [];
    
    // 3. Derived local state
    final List<ServiceProvider> _filteredProviders = _selectedCategory == 'All'
        ? List.of(_allProviders)
        : _allProviders.where((p) => p.category == _selectedCategory).toList();

    final List<Map<String, dynamic>> _allServices = [
      for (final provider in _allProviders)
        for (final svc in provider.services)
          {'service': svc, 'provider': provider},
    ];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _AmbientPainter()),
          ),
          CustomScrollView(
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
                      initial,
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
                          text: 'Good morning, $firstName ',
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
                    AnimatedProviderCard(index: i, provider: _filteredProviders[i]),
              ),
            ),
          ],
        ),
      ],
      ),
    );
  }
}
