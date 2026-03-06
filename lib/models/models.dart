import 'package:flutter/material.dart';

class ServiceItem {
  final String id;
  final String providerId;
  final String name;
  final String description;
  final double price;
  final int durationMin;
  final int bufferMin;
  // The services table has no category column — this is populated from the
  // provider's category when the service list is loaded alongside the provider.
  final String category;

  ServiceItem({
    required this.id,
    required this.providerId,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMin,
    required this.bufferMin,
    this.category = '',
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['service_id'] as String,
      providerId: json['provider_id'] as String,
      name: json['service_name'] as String,
      description: json['description'] as String? ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      durationMin: json['duration_minutes'] as int? ?? 30,
      bufferMin: json['buffer_minutes'] as int? ?? 0,
      category: '', // populated by ServiceProvider.fromJson if needed
    );
  }
}

// Aliasing ServiceItem to ServiceType for compatibility with UI screens
typedef ServiceType = ServiceItem;

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
  final String? avatarUrl;
  final List<ServiceItem> services;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.category,
    required this.emoji,
    required this.rating,
    required this.reviewCount,
    required this.distance,
    required this.address,
    required this.hours,
    this.avatarUrl,
    required this.services,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    final rawServices = json['services'] as List<dynamic>? ?? [];
    return ServiceProvider(
      id: json['provider_id'] as String,
      name: json['business_name'] as String,
      // Use actual DB columns — not hardcoded placeholders
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
      avatarUrl: json['avatar_url'] as String?,
      services: rawServices
          .map((s) => ServiceItem.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Appointment {
  final String id;
  final String providerName;
  final String providerId;
  final String serviceName;
  final String serviceId;
  final DateTime startsAt;
  final DateTime endsAt;
  final double price;
  final int durationMin;
  final int bufferMin;
  final String status;
  final String reference;

  Appointment({
    required this.id,
    required this.providerName,
    required this.providerId,
    required this.serviceName,
    required this.serviceId,
    required this.startsAt,
    required this.endsAt,
    required this.price,
    required this.durationMin,
    required this.bufferMin,
    required this.status,
    required this.reference,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    try {
      final provName =
          json['providers']?['business_name'] as String? ?? 'Unknown Provider';
      final srvcName =
          json['services']?['service_name'] as String? ?? 'Unknown Service';
      final srvcPrice =
          double.tryParse(json['services']?['price']?.toString() ?? '0') ?? 0.0;
      final dateTime = DateTime.parse(json['appointment_datetime'] as String);
      final duration =
          json['services']?['duration_minutes'] as int? ??
          json['duration_minutes'] as int? ??
          30;
      final bufferMin = json['services']?['buffer_minutes'] as int? ?? 0;

      final dbStatus = json['status'] as String? ?? 'pending';
      final uiStatus = switch (dbStatus) {
        'confirmed' => 'Confirmed',
        'cancelled' => 'Cancelled',
        'rescheduled' => 'Confirmed',
        'completed' => 'Completed',
        'no_show' => 'No Show',
        _ => 'Pending',
      };

      final rawId = json['appointment_id'].toString();
      final refStr = rawId.length >= 4 ? rawId.substring(0, 4) : rawId;

      return Appointment(
        id: json['appointment_id'] as String,
        providerName: provName,
        providerId: json['provider_id'] as String? ?? '',
        serviceName: srvcName,
        serviceId: json['service_id'] as String? ?? '',
        startsAt: dateTime.toLocal(),
        endsAt: dateTime.add(Duration(minutes: duration)).toLocal(),
        price: srvcPrice,
        durationMin: duration,
        bufferMin: bufferMin,
        status: uiStatus,
        reference: '#BK-${refStr.toUpperCase()}',
      );
    } catch (e) {
      debugPrint('Error parsing Appointment: $e\nJSON: $json');
      rethrow;
    }
  }
}

final List<Appointment> sampleUpcomingAppointments = [];
final List<Appointment> samplePastAppointments = [];

class ProviderAppointment {
  final String id;
  final String customerName;
  final String serviceName;
  final DateTime startsAt;
  final DateTime endsAt;
  final double price;
  final String status;
  final String? notes;

  ProviderAppointment({
    required this.id,
    required this.customerName,
    required this.serviceName,
    required this.startsAt,
    required this.endsAt,
    required this.price,
    required this.status,
    this.notes,
  });

  factory ProviderAppointment.fromJson(Map<String, dynamic> json) {
    try {
      // New schema: users join returns first_name + last_name (not full_name)
      final fName = json['users']?['first_name'] as String? ?? 'Unknown';
      final lName = json['users']?['last_name'] as String? ?? 'Customer';
      final srvcName =
          json['services']?['service_name'] as String? ?? 'Service';
      final srvcPrice =
          double.tryParse(json['services']?['price']?.toString() ?? '0') ?? 0.0;
      final dateTime = DateTime.parse(json['appointment_datetime'] as String);
      final duration =
          json['duration_minutes'] as int? ??
          json['services']?['duration_minutes'] as int? ??
          30;

      final dbStatus = json['status'] as String? ?? 'pending';
      final uiStatus = switch (dbStatus) {
        'confirmed' => 'Confirmed',
        'cancelled' => 'Cancelled',
        'rescheduled' => 'Confirmed',
        'completed' => 'Completed',
        'no_show' => 'No Show',
        _ => 'Pending',
      };

      return ProviderAppointment(
        id: json['appointment_id'] as String,
        customerName: '$fName $lName'.trim(),
        serviceName: srvcName,
        startsAt: dateTime.toLocal(),
        endsAt: dateTime.add(Duration(minutes: duration)).toLocal(),
        price: srvcPrice,
        status: uiStatus,
        notes:
            json['notes']
                as String?, // new schema: 'notes' not 'customer_notes'
      );
    } catch (e) {
      debugPrint('Error parsing ProviderAppointment: $e\nJSON: $json');
      rethrow;
    }
  }
}

final List<ProviderAppointment> sampleProviderAppointments = [];

// ── Schedule models ────────────────────────────────────────────────────────────

enum DayOfWeek {
  monday('Mon', 'Monday', 1),
  tuesday('Tue', 'Tuesday', 2),
  wednesday('Wed', 'Wednesday', 3),
  thursday('Thu', 'Thursday', 4),
  friday('Fri', 'Friday', 5),
  saturday('Sat', 'Saturday', 6),
  sunday('Sun', 'Sunday', 0); // Sunday = 0 in PostgreSQL DOW

  final String label;
  final String fullLabel;

  /// The value stored in `provider_schedules.day_of_week` (PostgreSQL DOW).
  final int dbIndex;

  const DayOfWeek(this.label, this.fullLabel, this.dbIndex);

  static DayOfWeek fromDbIndex(int index) =>
      DayOfWeek.values.firstWhere((d) => d.dbIndex == index);
}

class WorkingHours {
  DayOfWeek day;
  bool isOpen;
  TimeOfDay startTime;
  TimeOfDay endTime;

  WorkingHours({
    required this.day,
    required this.isOpen,
    required this.startTime,
    required this.endTime,
  });
}

final sampleWorkingHours = [
  WorkingHours(
    day: DayOfWeek.monday,
    isOpen: true,
    startTime: const TimeOfDay(hour: 9, minute: 0),
    endTime: const TimeOfDay(hour: 17, minute: 0),
  ),
  WorkingHours(
    day: DayOfWeek.tuesday,
    isOpen: true,
    startTime: const TimeOfDay(hour: 9, minute: 0),
    endTime: const TimeOfDay(hour: 17, minute: 0),
  ),
  WorkingHours(
    day: DayOfWeek.wednesday,
    isOpen: true,
    startTime: const TimeOfDay(hour: 9, minute: 0),
    endTime: const TimeOfDay(hour: 17, minute: 0),
  ),
  WorkingHours(
    day: DayOfWeek.thursday,
    isOpen: true,
    startTime: const TimeOfDay(hour: 9, minute: 0),
    endTime: const TimeOfDay(hour: 17, minute: 0),
  ),
  WorkingHours(
    day: DayOfWeek.friday,
    isOpen: true,
    startTime: const TimeOfDay(hour: 9, minute: 0),
    endTime: const TimeOfDay(hour: 17, minute: 0),
  ),
  WorkingHours(
    day: DayOfWeek.saturday,
    isOpen: false,
    startTime: const TimeOfDay(hour: 10, minute: 0),
    endTime: const TimeOfDay(hour: 15, minute: 0),
  ),
  WorkingHours(
    day: DayOfWeek.sunday,
    isOpen: false,
    startTime: const TimeOfDay(hour: 10, minute: 0),
    endTime: const TimeOfDay(hour: 15, minute: 0),
  ),
];
