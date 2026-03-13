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

  const Appointment({
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
}

class ProviderAppointment {
  final String id;
  final String customerName;
  final String serviceName;
  final DateTime startsAt;
  final DateTime endsAt;
  final double price;
  final String status;
  final String? notes;

  const ProviderAppointment({
    required this.id,
    required this.customerName,
    required this.serviceName,
    required this.startsAt,
    required this.endsAt,
    required this.price,
    required this.status,
    this.notes,
  });
}
