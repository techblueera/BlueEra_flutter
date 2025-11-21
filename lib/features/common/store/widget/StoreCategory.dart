class StoreFeedCategory {
  final String slugId;
  final String name;
  final String icon;
  final String type;

  StoreFeedCategory({
    required this.slugId,
    required this.name,
    required this.icon,
    required this.type,
  });

  StoreFeedCategory copyWith({
    String? slugId,
    String? name,
    String? icon,
    String? type,
  }) {
    return StoreFeedCategory(
      slugId: slugId ?? this.slugId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      type: type ?? this.type,
    );
  }
}
