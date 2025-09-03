// models/booking_model.dart
class BookingResponse {
  final bool success;
  final int count;
  final List<Booking> data;

  BookingResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    return BookingResponse(
      success: json['success'] ?? false,
      count: json['count'] ?? 0,
      data: List<Booking>.from((json['data'] ?? []).map((x) => Booking.fromJson(x))),
    );
  }
}

class Booking {
  final String id;
  final String status;
  final DateTime bookingTime;
  final CustomerDetails customerDetails;
  final String channelName;
  final String channelUsername;
  final String videoTitle;

  Booking({
    required this.id,
    required this.status,
    required this.bookingTime,
    required this.customerDetails,
    required this.channelName,
    required this.channelUsername,
    required this.videoTitle,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? '',
      status: json['status'] ?? '',
      bookingTime: DateTime.parse(json['bookingTime'] ?? DateTime.now().toIso8601String()),
      customerDetails: CustomerDetails.fromJson(json['customerDetails'] ?? {}),
      channelName: json['channelName'] ?? '',
      channelUsername: json['channelUsername'] ?? '',
      videoTitle: json['videoTitle'] ?? '',
    );
  }
}

class CustomerDetails {
  final String name;
  final String mobileNumber;
  final String email;

  CustomerDetails({
    required this.name,
    required this.mobileNumber,
    required this.email,
  });

  factory CustomerDetails.fromJson(Map<String, dynamic> json) {
    return CustomerDetails(
      name: json['name'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      email: json['email'] ?? '',
    );
  }
}
