import 'service_item.dart';

class ServiceProvider {
  final String id;
  final String name;
  final String category;
  final String emoji;
  final double rating;
  final int reviewCount;
  final String distance;
  final String address;
  final String hours;
  final String description;
  final String? avatarUrl;
  final bool isVerified;
  final bool isAvailableToday;
  final List<ServiceItem> services;

  const ServiceProvider({
    required this.id,
    required this.name,
    required this.category,
    required this.emoji,
    required this.rating,
    required this.reviewCount,
    required this.distance,
    required this.address,
    required this.hours,
    required this.description,
    this.avatarUrl,
    this.isVerified = false,
    this.isAvailableToday = false,
    required this.services,
  });
}
