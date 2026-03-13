import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/models/models.dart';
import '../../../core/services/favorites_service.dart';

// ─── Theme ──────────────────────────────────────────────────────────────────

class CategoryTheme {
  final List<Color> bannerGradient;
  final Color accent;
  final Color light;
  final Color bannerBlob;
  const CategoryTheme({
    required this.bannerGradient,
    required this.accent,
    required this.light,
    required this.bannerBlob,
  });
}

const categoryThemes = <String, CategoryTheme>{
  'Hair': CategoryTheme(
    bannerGradient: [Color(0xFFFFF4ED), Color(0xFFFED7AA)],
    accent: Color(0xFFC2410C),
    light: Color(0xFFFED7AA),
    bannerBlob: Color(0xFF7C2D12),
  ),
  'Massage': CategoryTheme(
    bannerGradient: [Color(0xFFF0FDF4), Color(0xFFBBF7D0)],
    accent: Color(0xFF166534),
    light: Color(0xFFBBF7D0),
    bannerBlob: Color(0xFF14532D),
  ),
  'Skincare': CategoryTheme(
    bannerGradient: [Color(0xFFF5F3FF), Color(0xFFDDD6FE)],
    accent: Color(0xFF6D28D9),
    light: Color(0xFFDDD6FE),
    bannerBlob: Color(0xFF4C1D95),
  ),
  'Fitness': CategoryTheme(
    bannerGradient: [Color(0xFFFFF1F2), Color(0xFFFECDD3)],
    accent: Color(0xFFBE123C),
    light: Color(0xFFFECDD3),
    bannerBlob: Color(0xFF881337),
  ),
  'Dental': CategoryTheme(
    bannerGradient: [Color(0xFFF0F9FF), Color(0xFFBAE6FD)],
    accent: Color(0xFF0369A1),
    light: Color(0xFFBAE6FD),
    bannerBlob: Color(0xFF0C4A6E),
  ),
};

const CategoryTheme defaultTheme = CategoryTheme(
  bannerGradient: [Color(0xFFF8FAFC), Color(0xFFCBD5E1)],
  accent: Color(0xFF475569),
  light: Color(0xFFCBD5E1),
  bannerBlob: Color(0xFF1E293B),
);

CategoryTheme themeFor(String category) =>
    categoryThemes[category] ?? defaultTheme;

// ─── Animated Card Wrapper ────────────────────────────────────────────────────

class AnimatedProviderCard extends StatefulWidget {
  final int index;
  final ServiceProvider provider;
  const AnimatedProviderCard({
    super.key,
    required this.index,
    required this.provider,
  });

  @override
  State<AnimatedProviderCard> createState() => _AnimatedProviderCardState();
}

class _AnimatedProviderCardState extends State<AnimatedProviderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 90), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: SlideTransition(
      position: _slide,
      child: ModernProviderCard(provider: widget.provider),
    ),
  );
}

// ─── Provider Card ────────────────────────────────────────────────────────────

class ModernProviderCard extends StatefulWidget {
  final ServiceProvider provider;
  const ModernProviderCard({super.key, required this.provider});

  @override
  State<ModernProviderCard> createState() => _ModernProviderCardState();
}

class _ModernProviderCardState extends State<ModernProviderCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late bool _saved;

  @override
  void initState() {
    super.initState();
    _saved = FavoritesService.instance.isFavorite(widget.provider.id);
    FavoritesService.instance.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    FavoritesService.instance.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    final updated = FavoritesService.instance.isFavorite(widget.provider.id);
    if (updated != _saved && mounted) {
      setState(() => _saved = updated);
    }
  }

  double get _minPrice {
    if (widget.provider.services.isEmpty) return 0.0;
    return widget.provider.services.map((s) => s.price).reduce(math.min);
  }

  @override
  Widget build(BuildContext context) {
    final theme = themeFor(widget.provider.category);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => context.push('/provider', extra: widget.provider),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.045), // For dark mode
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _pressed ? 0.25 : 0.45),
                blurRadius: _pressed ? 8 : 32,
                spreadRadius: _pressed ? 0 : -4,
                offset: Offset(0, _pressed ? 2 : 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _Banner(
                provider: widget.provider,
                theme: theme,
                saved: _saved,
                onSave: () {
                  FavoritesService.instance.toggleFavorite(widget.provider.id);
                },
              ),
              _Body(
                provider: widget.provider,
                theme: theme,
                minPrice: _minPrice,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Banner ──────────────────────────────────────────────────────────────────

class _Banner extends StatefulWidget {
  final ServiceProvider provider;
  final CategoryTheme theme;
  final bool saved;
  final VoidCallback onSave;

  const _Banner({
    required this.provider,
    required this.theme,
    required this.saved,
    required this.onSave,
  });

  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> with SingleTickerProviderStateMixin {
  late AnimationController _emojiCtrl;
  late Animation<double> _emojiScale;
  late Animation<double> _emojiAngle;

  @override
  void initState() {
    super.initState();
    _emojiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _emojiScale = Tween(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _emojiCtrl, curve: Curves.easeOut));
    _emojiAngle = Tween(
      begin: 0.0,
      end: -0.07,
    ).animate(CurvedAnimation(parent: _emojiCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _emojiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine verification/availability manually if missing from model
    final bool isVerified =
        widget.provider.isVerified; // Pulled from is_approved
    final bool isAvailableToday =
        widget.provider.isAvailableToday; // Pulled from provider_schedules

    return MouseRegion(
      onEnter: (_) {
        _emojiCtrl.forward();
      },
      onExit: (_) {
        _emojiCtrl.reverse();
      },
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.theme.bannerGradient,
          ),
        ),
        child: Stack(
          children: [
            // Blob circles
            Positioned(
              right: -30,
              top: -30,
              child: _BlobCircle(
                size: 130,
                color: widget.theme.bannerBlob.withValues(alpha: 0.25),
              ),
            ),
            Positioned(
              left: 20,
              bottom: -30,
              child: _BlobCircle(
                size: 80,
                color: widget.theme.bannerBlob.withValues(alpha: 0.15),
              ),
            ),

            // Noise texture overlay
            Positioned.fill(
              child: Opacity(
                opacity: 0.07,
                child: CustomPaint(painter: _NoisePainter()),
              ),
            ),

            // Emoji (centered) or Avatar
            Center(
              child: AnimatedBuilder(
                animation: _emojiCtrl,
                builder: (context, child) => Transform.rotate(
                  angle: _emojiAngle.value,
                  child: Transform.scale(
                    scale: _emojiScale.value,
                    child: Text(
                      widget.provider.emoji,
                      style: const TextStyle(fontSize: 58, height: 1),
                    ),
                  ),
                ),
              ),
            ),

            // Verified badge
            if (isVerified)
              Positioned(
                top: 13,
                left: 13,
                child: _Badge(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderColor: Colors.white.withValues(alpha: 0.2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 9,
                          color: Color(0xFF0F0E11),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Verified',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Availability badge
            Positioned(
              top: 13,
              right: 13,
              child: _Badge(
                color: isAvailableToday
                    ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.08),
                borderColor: isAvailableToday
                    ? const Color(0xFF4ADE80).withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isAvailableToday
                            ? const Color(0xFF4ADE80)
                            : Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                        boxShadow: isAvailableToday
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4ADE80,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ]
                            : <BoxShadow>[],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isAvailableToday ? 'Open today' : 'Unavailable',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isAvailableToday
                            ? const Color(0xFF86EFAC)
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Save button
            Positioned(
              bottom: 13,
              right: 13,
              child: GestureDetector(
                onTap: widget.onSave,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: widget.saved
                        ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.saved
                          ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: AnimatedScale(
                    scale: widget.saved ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.elasticOut,
                    child: Icon(
                      widget.saved ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: widget.saved
                          ? const Color(0xFFEF4444)
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card Body ───────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final ServiceProvider provider;
  final CategoryTheme theme;
  final double minPrice;
  const _Body({
    required this.provider,
    required this.theme,
    required this.minPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + Rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  provider.name,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF8F6F1),
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _RatingPill(
                rating: provider.rating,
                reviewCount: provider.reviewCount,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Meta row
          Row(
            children: [
              _CategoryChip(category: provider.category, theme: theme),
              const SizedBox(width: 7),
              Text(
                '·',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.15),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 7),
              Icon(
                Icons.place_outlined,
                size: 12,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  provider.address.isEmpty
                      ? 'Unknown Location'
                      : provider.address,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.38),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Services horizontal scroll
          if (provider.services.isNotEmpty) ...[
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: provider.services.length,
                separatorBuilder: (context, index) => const SizedBox(width: 7),
                itemBuilder: (context, i) =>
                    _ServiceChip(service: provider.services[i]),
              ),
            ),
            const SizedBox(height: 16),
            Divider(
              color: Colors.white.withValues(alpha: 0.07),
              thickness: 1,
              height: 1,
            ),
            const SizedBox(height: 16),
          ],

          // Bottom row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Starting from',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${minPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF8F6F1),
                      height: 1,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              _BookButton(provider: provider, theme: theme),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

final _kBlur = ImageFilter.blur(sigmaX: 12, sigmaY: 12);

class _Badge extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final Widget child;
  const _Badge({
    required this.color,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: _kBlur,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: child,
      ),
    ),
  );
}

class _BlobCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _BlobCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _RatingPill extends StatelessWidget {
  final double rating;
  final int reviewCount;
  const _RatingPill({required this.rating, required this.reviewCount});

  @override
  Widget build(BuildContext context) {
    if (reviewCount == 0 && rating == 0.0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(
          'New',
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      );
    }

    final label = reviewCount > 999
        ? '(${(reviewCount / 1000).toStringAsFixed(1)}k)'
        : '($reviewCount)';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StarRow(rating: rating),
          const SizedBox(width: 5),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFCD34D),
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: const Color(0xFFFCD34D).withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final double rating;
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      5,
      (i) => Icon(
        Icons.star_rounded,
        size: 12,
        color: (i + 1) <= rating.round()
            ? const Color(0xFFFCD34D)
            : Colors.white.withValues(alpha: 0.15),
      ),
    ),
  );
}

class _CategoryChip extends StatelessWidget {
  final String category;
  final CategoryTheme theme;
  const _CategoryChip({required this.category, required this.theme});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: theme.light.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: theme.light.withValues(alpha: 0.3)),
    ),
    child: Text(
      category.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: theme.light,
        letterSpacing: 0.8,
      ),
    ),
  );
}

class _ServiceChip extends StatefulWidget {
  final ServiceItem service;
  const _ServiceChip({required this.service});

  @override
  State<_ServiceChip> createState() => _ServiceChipState();
}

class _ServiceChipState extends State<_ServiceChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: _hovered
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: _hovered
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.service.name,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(width: 5),
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '\$${widget.service.price.toStringAsFixed(0)}',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF8F6F1),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${widget.service.durationMin}m',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    ),
  );
}

class _BookButton extends StatefulWidget {
  final ServiceProvider provider;
  final CategoryTheme theme;
  const _BookButton({required this.provider, required this.theme});

  @override
  State<_BookButton> createState() => _BookButtonState();
}

class _BookButtonState extends State<_BookButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isAvailable =
        widget.provider.isAvailableToday; // Use real availability
    return GestureDetector(
      onTapDown: isAvailable ? (_) => setState(() => _pressed = true) : null,
      onTapUp: isAvailable ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: isAvailable ? () => setState(() => _pressed = false) : null,
      onTap: isAvailable
          ? () => context.push('/provider', extra: widget.provider)
          : null,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          decoration: BoxDecoration(
            color: isAvailable
                ? widget.theme.accent
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: isAvailable
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: isAvailable && !_pressed
                ? [
                    BoxShadow(
                      color: widget.theme.accent.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: -4,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : <BoxShadow>[],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isAvailable ? 'Book now' : 'Unavailable',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: isAvailable
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.25),
                ),
              ),
              if (isAvailable) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Noise Painter (grain texture) ───────────────────────────────────────────

class _NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..color = Colors.black;
    for (var i = 0; i < 3000; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      paint.color = (rng.nextBool() ? Colors.white : Colors.black).withValues(
        alpha: rng.nextDouble() * 0.6,
      );
      canvas.drawCircle(Offset(x, y), 0.4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
