class TopLevelCategory {
  final String id;
  final String name;

  TopLevelCategory({
    required this.id,
    required this.name,
  });

  factory TopLevelCategory.fromJson(Map<String, dynamic> json) {
    return TopLevelCategory(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
      };
}

List<TopLevelCategory> topLevelCategoryListFromJson(dynamic json) {
  if (json is List) {
    return json
        .map((e) => TopLevelCategory.fromJson(
            (e as Map).map((key, value) => MapEntry(key.toString(), value))))
        .toList();
  }
  return <TopLevelCategory>[];
}