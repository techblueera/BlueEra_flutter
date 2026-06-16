class AutomotiveDetailItem {
  final String title;
  final String details;

  AutomotiveDetailItem({
    required this.title,
    required this.details,
  });

  factory AutomotiveDetailItem.fromJson(Map<String, dynamic> json) {
    return AutomotiveDetailItem(
      title: json['title'] ?? '',
      details: json['details'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'details': details,
    };
  }

  AutomotiveDetailItem copyWith({
    String? title,
    String? details,
  }) {
    return AutomotiveDetailItem(
      title: title ?? this.title,
      details: details ?? this.details,
    );
  }
}