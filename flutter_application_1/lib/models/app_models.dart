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
  final int categoryId;

  Service({required this.id, required this.name, this.description, required this.price, required this.categoryId});

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      categoryId: json['category_id'],
    );
  }
}

class Booking {
  final int id;
  final int serviceId;
  final String scheduledTime;
  final String address;
  final String status;

  Booking({required this.id, required this.serviceId, required this.scheduledTime, required this.address, required this.status});

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      serviceId: json['service_id'],
      scheduledTime: json['scheduled_time'],
      address: json['address'],
      status: json['status'],
    );
  }
}
