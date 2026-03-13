import '../../domain/models/service_provider.dart';
import 'service_item_dto.dart';

class ServiceProviderDto {
  static ServiceProvider fromJson(Map<String, dynamic> json) {
    final rawServices = json['services'] as List<dynamic>? ?? [];

    bool isOpenToday = false;
    if (json.containsKey('provider_schedules') && json['provider_schedules'] != null) {
      final schedules = json['provider_schedules'] as List<dynamic>? ?? [];
      final todayIndex = DateTime.now().weekday; // 1-7 (Mon-Sun)
      final dbToday = todayIndex == 7 ? 0 : todayIndex; // 0-6 (Sun-Sat)
      
      final todaySchedule = schedules.firstWhere(
        (s) => s['day_of_week'] == dbToday,
        orElse: () => null,
      );
      
      if (todaySchedule != null) {
        isOpenToday = todaySchedule['is_open'] == true;
      }
    }

    return ServiceProvider(
      id: json['provider_id'] as String,
      name: json['business_name'] as String,
      category: json['category'] as String? ?? 'Other',
      emoji: json['emoji'] as String? ?? '✦',
      rating: double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0.0,
      reviewCount: json['total_reviews'] as int? ?? 0,
      distance: '', // Not stored — would need geo query
      address: [
        json['address'],
        json['city'],
        json['state'],
      ].where((v) => v != null && (v as String).isNotEmpty).join(', '),
      hours: '', // Fetched separately from provider_schedules
      description: json['bio'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      isVerified: json['is_approved'] == true,
      isAvailableToday: isOpenToday,
      services: rawServices
          .map((s) => ServiceItemDto.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
