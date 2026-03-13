import 'package:flutter/material.dart';
import '../../domain/models/appointment.dart';

class AppointmentDto {
  static Appointment fromJson(Map<String, dynamic> json) {
    try {
      final provName =
          json['providers']?['business_name'] as String? ?? 'Unknown Provider';
      final srvcName =
          json['services']?['service_name'] as String? ?? 'Unknown Service';
      final srvcPrice =
          double.tryParse(json['services']?['price']?.toString() ?? '0') ?? 0.0;
      final dateTime = DateTime.parse(json['appointment_datetime'] as String);
      final duration = json['services']?['duration_minutes'] as int? ??
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
        endsAt: dateTime
            .add(Duration(minutes: duration <= 0 ? 30 : duration))
            .toLocal(),
        price: srvcPrice < 0 ? 0.0 : srvcPrice,
        durationMin: duration <= 0 ? 30 : duration,
        bufferMin: bufferMin.clamp(0, 1440),
        status: uiStatus,
        reference: '#BK-${refStr.toUpperCase()}',
      );
    } catch (e) {
      debugPrint('Error parsing Appointment: $e\nJSON: $json');
      rethrow;
    }
  }
}

class ProviderAppointmentDto {
  static ProviderAppointment fromJson(Map<String, dynamic> json) {
    try {
      final fName = json['users']?['first_name'] as String? ?? 'Unknown';
      final lName = json['users']?['last_name'] as String? ?? 'Customer';
      final srvcName =
          json['services']?['service_name'] as String? ?? 'Service';
      final srvcPrice =
          double.tryParse(json['services']?['price']?.toString() ?? '0') ?? 0.0;
      final dateTime = DateTime.parse(json['appointment_datetime'] as String);
      final duration = json['duration_minutes'] as int? ??
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
        notes: json['notes'] as String?,
      );
    } catch (e) {
      debugPrint('Error parsing ProviderAppointment: $e\nJSON: $json');
      rethrow;
    }
  }
}
