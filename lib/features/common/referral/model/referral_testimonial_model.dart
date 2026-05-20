class ReferralTestimonial {
  final String id;
  final String name;
  final String role;
  final String company;
  final String profileImage;
  final String quote;
  final String? website;
  final String? videoUrl;

  ReferralTestimonial({
    required this.id,
    required this.name,
    required this.role,
    required this.company,
    required this.profileImage,
    required this.quote,
    this.website,
    this.videoUrl,
  });

  factory ReferralTestimonial.fromJson(Map<String, dynamic> json) {
    return ReferralTestimonial(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      company: json['company'] ?? '',
      profileImage: json['profileImage'] ?? '',
      quote: json['quote'] ?? '',
      website: json['website'],
      videoUrl: json['videoUrl'],
    );
  }
}
