class ServiceItem {
  final String id;
  final String providerId;
  final String name;
  final String description;
  final double price;
  final int durationMin;
  final int bufferMin;
  final String category;

  const ServiceItem({
    required this.id,
    required this.providerId,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMin,
    required this.bufferMin,
    this.category = '',
  });
}

// Aliasing ServiceItem to ServiceType for compatibility with UI screens
typedef ServiceType = ServiceItem;
