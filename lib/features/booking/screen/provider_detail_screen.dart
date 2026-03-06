import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../app_theme.dart';
import '../../../models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/favorites_service.dart';

class ProviderDetailScreen extends StatefulWidget {
  final ServiceProvider provider;
  const ProviderDetailScreen({super.key, required this.provider});

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  ServiceType? _selectedService;

  @override
  void initState() {
    super.initState();
    FavoritesService.instance.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    FavoritesService.instance.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isFav = FavoritesService.instance.isFavorite(widget.provider.id);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(''),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? AppColors.red : AppColors.muted,
            ),
            onPressed: () {
              FavoritesService.instance.toggleFavorite(widget.provider.id);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Hero banner ──────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _heroBgColor().withValues(alpha: 0.8),
                    _heroBgColor(),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  if (widget.provider.avatarUrl != null &&
                      widget.provider.avatarUrl!.isNotEmpty)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CachedNetworkImage(
                        imageUrl: widget.provider.avatarUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            color: AppColors.sage.withAlpha(128),
                          ),
                        ),
                        errorWidget: (context, url, error) => Text(
                          widget.provider.emoji,
                          style: const TextStyle(fontSize: 52),
                        ),
                      ),
                    )
                  else
                    Text(
                      widget.provider.emoji,
                      style: const TextStyle(fontSize: 52),
                    ),

                  const SizedBox(height: 10),
                  Text(
                    widget.provider.name,
                    style: GoogleFonts.fraunces(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.provider.category} · ⭐ ${widget.provider.rating} (${widget.provider.reviewCount} reviews)',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '📍 ${widget.provider.address}',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.ink2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '🕐 ${widget.provider.hours}',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // ── Section label ────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'SELECT SERVICE',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),

          // ── Service cards ────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList.separated(
              itemCount: widget.provider.services.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final svc = widget.provider.services[i];
                final isSelected = _selectedService?.id == svc.id;
                return _ServiceCard(
                  service: svc,
                  isSelected: isSelected,
                  onTap: () => setState(
                    () => _selectedService = isSelected ? null : svc,
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // ── Sticky bottom CTA ────────────────────────
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedService != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedService!.name,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.ink2,
                      ),
                    ),
                    Text(
                      '\$${_selectedService!.price.toStringAsFixed(0)} · ${_selectedService!.durationMin} min',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.sage,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selectedService == null
                      ? null
                      : () => context.push(
                          '/booking_slot',
                          extra: {
                            'provider': widget.provider,
                            'service': _selectedService!,
                          },
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sage,
                    disabledBackgroundColor: AppColors.line,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _selectedService == null
                        ? 'Select a service to continue'
                        : 'Continue →',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _selectedService == null
                          ? AppColors.muted
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _heroBgColor() {
    switch (widget.provider.category) {
      case 'Hair':
        return const Color(0xFFFEF3EC);
      case 'Massage':
        return AppColors.sageLight;
      case 'Medical':
        return const Color(0xFFF0F4FE);
      case 'Fitness':
        return const Color(0xFFFFF8E6);
      default:
        return AppColors.bg;
    }
  }
}

// ── Service card widget ───────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final ServiceType service;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.sage.withValues(alpha: 0.04)
              : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.sage
                : AppColors.line.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.sage.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // name + price row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    service.name,
                    style: GoogleFonts.fraunces(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '\$${service.price.toStringAsFixed(0)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.sage : AppColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // description
            Text(
              service.description,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // meta chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(
                  icon: Icons.schedule,
                  label: '${service.durationMin} min',
                  color: isSelected ? AppColors.sage : AppColors.muted,
                ),
                _MetaChip(
                  icon: Icons.category_outlined,
                  label: service.category,
                  color: AppColors.muted,
                ),
                if (service.bufferMin > 0)
                  _MetaChip(
                    icon: Icons.coffee_outlined,
                    label: '${service.bufferMin} min buffer',
                    color: AppColors.muted,
                  ),
              ],
            ),

            // selected check
            if (isSelected) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.sage,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Selected',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.sage,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
