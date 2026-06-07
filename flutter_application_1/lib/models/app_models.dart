class ServiceCategory {
  final int id;
  final String name;

  ServiceCategory({required this.id, required this.name});

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Service {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int? categoryId;

  Service({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.categoryId,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
      categoryId: json['category_id'],
    );
  }
}

class Booking {
  final int id;
  final int serviceId;
  final int? workerId;
  final String scheduledTime;
  final String address;
  final String status;
  final String? note;

  Booking({
    required this.id,
    required this.serviceId,
    this.workerId,
    required this.scheduledTime,
    required this.address,
    required this.status,
    this.note,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      serviceId: json['service_id'],
      workerId: json['worker_id'],
      scheduledTime: json['scheduled_time'],
      address: json['address'],
      status: json['status'],
      note: json['note'],
    );
  }
}
