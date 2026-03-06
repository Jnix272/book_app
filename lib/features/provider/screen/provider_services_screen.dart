import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app_theme.dart';
import '../../../models/models.dart';
import '../../../core/services/provider_session.dart';
import 'add_edit_service_screen.dart';

class ProviderServicesScreen extends StatefulWidget {
  const ProviderServicesScreen({super.key});

  @override
  State<ProviderServicesScreen> createState() => _ProviderServicesScreenState();
}

class _ProviderServicesScreenState extends State<ProviderServicesScreen> {
  late Future<List<ServiceItem>> _servicesFuture;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  void _loadServices() {
    setState(() {
      _servicesFuture = _fetchServices();
    });
  }

  Future<List<ServiceItem>> _fetchServices() async {
    // BUG FIX: services.provider_id references providers.provider_id,
    // NOT auth uid. Use ProviderSession to get the correct UUID.
    final providerId = await ProviderSession.instance.providerId;
    if (providerId == null) return [];

    final response = await Supabase.instance.client
        .from('services')
        .select()
        .eq('provider_id', providerId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ServiceItem.fromJson(json))
        .toList();
  }

  Future<void> _deleteService(ServiceItem service) async {
    // Check for upcoming appointments before deleting.
    // Deleting a service that has future bookings orphans those appointments
    // (they show "Unknown Service" to customers).
    try {
      final upcoming = await Supabase.instance.client
          .from('appointments')
          .select('appointment_id')
          .eq('service_id', service.id)
          .gte('appointment_datetime', DateTime.now().toUtc().toIso8601String())
          .neq('status', 'cancelled')
          .limit(1);

      if (!mounted) return;

      if ((upcoming as List).isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${service.name} has upcoming bookings and cannot be deleted. '
              'Cancel those appointments first.',
            ),
            backgroundColor: AppColors.amber,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await Supabase.instance.client
          .from('services')
          .delete()
          .eq('service_id', service.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${service.name} deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadServices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'My Services',
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        shape: const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      body: FutureBuilder<List<ServiceItem>>(
        future: _servicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.sage),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.red,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Error loading services',
                    style: GoogleFonts.dmSans(color: AppColors.red),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loadServices,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final services = snapshot.data ?? [];

          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.spa_outlined,
                    size: 64,
                    color: AppColors.line,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No services yet',
                    style: GoogleFonts.fraunces(
                      fontSize: 20,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first service',
                    style: GoogleFonts.dmSans(color: AppColors.muted),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadServices(),
            color: AppColors.sage,
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: services.length,
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final service = services[index];
                return _ServiceCard(
                  service: service,
                  onEdit: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditServiceScreen(service: service),
                      ),
                    );
                    if (result == true) _loadServices();
                  },
                  onDelete: () => _showDeleteConfirm(context, service),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.sage,
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddEditServiceScreen()),
          );
          if (result == true) _loadServices();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'New Service',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, ServiceItem service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete ${service.name}?',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.w500),
        ),
        content: Text(
          'This will remove the service permanently and cannot be undone.',
          style: GoogleFonts.dmSans(color: AppColors.muted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteService(service);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.dmSans(
                color: AppColors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Service card ──────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final ServiceItem service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServiceCard({
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    service.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${service.price.toStringAsFixed(0)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.sage,
                  ),
                ),
              ],
            ),
            if (service.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                service.description,
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 14,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${service.durationMin} min',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: AppColors.ink2,
                      ),
                      onPressed: onEdit,
                      tooltip: 'Edit',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: AppColors.red,
                      ),
                      onPressed: onDelete,
                      tooltip: 'Delete',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
