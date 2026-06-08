class ServiceCategory {
  final int id;
  final String name;
  final String? description;

  ServiceCategory({required this.id, required this.name, this.description});

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
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
  final int customerId;
  final int serviceId;
  final int? workerId;
  final String scheduledTime;
  final String address;
  final String status;
  final String? note;
  final String? beforeImage;
  final String? afterImage;

  Booking({
    required this.id,
    required this.customerId,
    required this.serviceId,
    this.workerId,
    required this.scheduledTime,
    required this.address,
    required this.status,
    this.note,
    this.beforeImage,
    this.afterImage,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      customerId: json['customer_id'] ?? 0,
      serviceId: json['service_id'],
      workerId: json['worker_id'],
      scheduledTime: json['scheduled_time'],
      address: json['address'],
      status: json['status'],
      note: json['note'],
      beforeImage: json['before_image'],
      afterImage: json['after_image'],
    );
  }
}

class Favorite {
  final int id;
  final int customerId;
  final int serviceId;

  Favorite({
    required this.id,
    required this.customerId,
    required this.serviceId,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'],
      customerId: json['customer_id'],
      serviceId: json['service_id'],
    );
  }
}

class SavedAddress {
  final int id;
  final int customerId;
  final String label;
  final String addressText;
  final double? latitude;
  final double? longitude;

  SavedAddress({
    required this.id,
    required this.customerId,
    required this.label,
    required this.addressText,
    this.latitude,
    this.longitude,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'],
      customerId: json['customer_id'],
      label: json['label'] ?? '',
      addressText: json['address_text'] ?? '',
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
    );
  }
}

class ChatMessage {
  final int id;
  final int bookingId;
  final int senderId;
  final String messageText;
  final String createdAt;

  ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.messageText,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      bookingId: json['booking_id'],
      senderId: json['sender_id'],
      messageText: json['message_text'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class UserNotification {
  final int id;
  final int userId;
  final String title;
  final String message;
  final bool isRead;
  final String createdAt;

  UserNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class WalletTransaction {
  final int id;
  final int workerId;
  final int? bookingId;
  final double amount;
  final String type;
  final String? description;
  final String createdAt;

  WalletTransaction({
    required this.id,
    required this.workerId,
    this.bookingId,
    required this.amount,
    required this.type,
    this.description,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'],
      workerId: json['worker_id'],
      bookingId: json['booking_id'],
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : 0.0,
      type: json['type'] ?? '',
      description: json['description'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

class WorkerCalendar {
  final int id;
  final int workerId;
  final String date;
  final bool isOff;
  final String? note;

  WorkerCalendar({
    required this.id,
    required this.workerId,
    required this.date,
    required this.isOff,
    this.note,
  });

  factory WorkerCalendar.fromJson(Map<String, dynamic> json) {
    return WorkerCalendar(
      id: json['id'],
      workerId: json['worker_id'],
      date: json['date'] ?? '',
      isOff: json['is_off'] ?? false,
      note: json['note'],
    );
  }
}
