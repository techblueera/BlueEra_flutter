class DetailItem {
  final String title;
  final String details;

  DetailItem({
    required this.title,
    required this.details,
  });

  factory DetailItem.fromJson(Map<String, dynamic> json) {
    return DetailItem(
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

  DetailItem copyWith({
    String? title,
    String? details,
  }) {
    return DetailItem(
      title: title ?? this.title,
      details: details ?? this.details,
    );
  }
}