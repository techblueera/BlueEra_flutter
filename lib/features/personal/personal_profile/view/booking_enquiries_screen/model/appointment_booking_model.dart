class CustomerDetails {
  final String name;
  final String mobileNumber;
  final String email;

  CustomerDetails({
    required this.name,
    required this.mobileNumber,
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mobileNumber': mobileNumber,
      'email': email,
    };
  }
}
