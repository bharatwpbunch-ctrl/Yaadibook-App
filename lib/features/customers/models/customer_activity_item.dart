/// Classification of customer timeline activities.
enum CustomerActivityType {
  created,
  updated,
  call,
  whatsapp,
  archived,
  restored,
  service,
  maintenance,
  amc,
  reminder,
}

/// Chronological event item displayed in the Customer Details activity timeline.
class CustomerActivityItem {
  final String id;
  final CustomerActivityType type;
  final String title;
  final String? description;
  final DateTime timestamp;

  const CustomerActivityItem({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.timestamp,
  });

  String? get subtitle => description;
}
