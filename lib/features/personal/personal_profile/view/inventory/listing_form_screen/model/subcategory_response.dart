class CategoryNode {
  final String id;
  final String name;
  final String? parent;
  final List<CategoryNode> subcategories;

  CategoryNode({
    required this.id,
    required this.name,
    required this.parent,
    required this.subcategories,
  });

  factory CategoryNode.fromJson(Map<String, dynamic> json) {
    return CategoryNode(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      parent: json['parent']?.toString(),
      subcategories: (json['subcategories'] is List)
          ? (json['subcategories'] as List)
              .map((e) => CategoryNode.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList()
          : <CategoryNode>[],
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'parent': parent,
        'subcategories': subcategories.map((e) => e.toJson()).toList(),
      };
}

List<CategoryNode> categoryNodeListFromJson(dynamic json) {
  if (json is List) {
    return json
        .map((e) => CategoryNode.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }
  return <CategoryNode>[];
}

CategoryNode categoryNodeFromJson(dynamic json) {
  if (json is Map) {
    return CategoryNode.fromJson(
        Map<String, dynamic>.from(json));
  }
  // Fallback empty node if response isn't an object
  return CategoryNode(id: '', name: '', parent: null, subcategories: const []);
}

// Normalize API to always return children list (handles object-with-children or list)
List<CategoryNode> childrenFromApi(dynamic json) {
  if (json is Map && (json).containsKey('subcategories')) {
    final node = categoryNodeFromJson(json);
    return node.subcategories;
  }
  if (json is List) {
    return categoryNodeListFromJson(json);
  }
  return <CategoryNode>[];
}
