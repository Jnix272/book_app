import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../app_theme.dart';
import '../../../models/models.dart';
import '../../../core/services/favorites_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<ServiceProvider> _favoriteProviders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    FavoritesService.instance.addListener(_fetchFavorites);
    _fetchFavorites();
  }

  @override
  void dispose() {
    FavoritesService.instance.removeListener(_fetchFavorites);
    super.dispose();
  }

  Future<void> _fetchFavorites() async {
    final favIds = FavoritesService.instance.favoriteIds.toList();

    if (favIds.isEmpty) {
      if (mounted) {
        setState(() {
          _favoriteProviders = [];
          _isLoading = false;
        });
      }
      return;
    }

    final missingIds = favIds
        .where((id) => FavoritesService.instance.getCachedProvider(id) == null)
        .toList();

    if (missingIds.isNotEmpty) {
      try {
        final res = await Supabase.instance.client
            .from('providers')
            .select(
              'provider_id, business_name, average_rating, total_reviews, address, category, emoji, avatar_url, services(service_id, provider_id, service_name, description, price, duration_minutes, buffer_minutes)',
            )
            .inFilter('provider_id', missingIds);

        final fetchedProviders = (res as List)
            .map((p) => ServiceProvider.fromJson(p))
            .toList();
        FavoritesService.instance.cacheProviders(fetchedProviders);
      } catch (e) {
        debugPrint('Failed to fetch missing favorites: $e');
      }
    }

    if (mounted) {
      setState(() {
        _favoriteProviders = favIds
            .map((id) => FavoritesService.instance.getCachedProvider(id))
            .whereType<ServiceProvider>()
            .toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Saved Providers',
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.sage),
            )
          : _favoriteProviders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 60,
                    color: AppColors.muted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: GoogleFonts.fraunces(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Providers you favorite will appear here.',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _favoriteProviders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final p = _favoriteProviders[index];
                return GestureDetector(
                  onTap: () => context.push('/provider', extra: p),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _avatarColor(p.category),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child:
                                p.avatarUrl != null && p.avatarUrl!.isNotEmpty
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
                                    errorWidget: (context, url, error) =>
                                        Center(
                                          child: Text(
                                            p.emoji,
                                            style: const TextStyle(
                                              fontSize: 26,
                                            ),
                                          ),
                                        ),
                                  )
                                : Center(
                                    child: Text(
                                      p.emoji,
                                      style: const TextStyle(fontSize: 26),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '⭐ ${p.rating} · ${p.category}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.favorite,
                              color: AppColors.red,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(
                                context,
                              ).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${p.name} removed'),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: () => FavoritesService.instance
                                        .toggleFavorite(p.id),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
