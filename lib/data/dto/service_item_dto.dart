import '../../domain/models/service_item.dart';

class ServiceItemDto {
  static ServiceItem fromJson(Map<String, dynamic> json) {
    final duration = json['duration_minutes'] as int? ?? 30;
    final price = double.tryParse(json['price'].toString()) ?? 0.0;

    return ServiceItem(
      id: json['service_id'] as String,
      providerId: json['provider_id'] as String,
      name: json['service_name'] as String,
      description: json['description'] as String? ?? '',
      price: price < 0 ? 0.0 : price,
      durationMin: duration <= 0 ? 30 : duration,
      bufferMin: (json['buffer_minutes'] as int? ?? 0).clamp(0, 1440),
      category: '', // populated by ServiceProviderDto if needed
    );
  }
}
