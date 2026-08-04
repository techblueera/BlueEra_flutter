/// Models for `GET user-service/business/description-suggestions` — the
/// ready-written business descriptions offered per category / subcategory.
/// See docs/FLUTTER_BUSINESS_DESCRIPTION_SUGGESTIONS_GUIDE.md
///
/// Every stored description carries a `{business_name}` placeholder. The
/// backend fills it when `business_name` is sent with the request; the
/// [withBusinessName] / [filledWith] helpers fill it client-side otherwise
/// (and are a safe no-op once the token is gone).
class DescriptionSuggestion {
  final List<String> lines;
  final String text;

  const DescriptionSuggestion({required this.lines, required this.text});

  factory DescriptionSuggestion.fromJson(Map<String, dynamic> json) =>
      DescriptionSuggestion(
        lines: (json['lines'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        text: json['text']?.toString() ?? '',
      );

  /// One flowing paragraph — what the description field stores.
  String get asParagraph => text;

  String get asLineBroken => lines.join('\n');

  String get asSpacedParagraphs => lines.join('\n\n');

  /// The paragraph trimmed to the whole sentences that fit inside [limit] —
  /// the description field caps at 400 characters and a suggestion can be
  /// longer. Falls back to a cut at the last word boundary when even the
  /// first sentence overflows.
  String fittedTo(int limit) {
    if (text.length <= limit) return text;

    final kept = <String>[];
    for (final line in lines) {
      final candidate = [...kept, line].join(' ');
      if (candidate.length > limit) break;
      kept.add(line);
    }
    if (kept.isNotEmpty) return kept.join(' ');

    final cut = text.substring(0, limit);
    final lastSpace = cut.lastIndexOf(' ');
    return (lastSpace > 0 ? cut.substring(0, lastSpace) : cut).trimRight();
  }

  /// Client-side placeholder fill. An empty [businessName] keeps the token
  /// rather than leaving a hole in the sentence.
  DescriptionSuggestion withBusinessName(String businessName,
      {String placeholder = '{business_name}'}) {
    final clean = businessName.trim();
    if (clean.isEmpty) return this;
    return DescriptionSuggestion(
      lines: lines.map((l) => l.replaceAll(placeholder, clean)).toList(),
      text: text.replaceAll(placeholder, clean),
    );
  }
}

class DescriptionCategoryRef {
  final String? id;
  final String name;
  final String? tagId;
  final String? type;

  const DescriptionCategoryRef({this.id, required this.name, this.tagId, this.type});

  factory DescriptionCategoryRef.fromJson(Map<String, dynamic> json) =>
      DescriptionCategoryRef(
        id: json['id']?.toString(),
        name: json['name']?.toString() ?? '',
        tagId: json['tag_id']?.toString(),
        type: json['type']?.toString(),
      );
}

class DescriptionSubCategoryRef {
  final String? id;

  /// Subcategories have no `tag_id` — the model has none.
  final String name;

  const DescriptionSubCategoryRef({this.id, required this.name});

  factory DescriptionSubCategoryRef.fromJson(Map<String, dynamic> json) =>
      DescriptionSubCategoryRef(
        id: json['id']?.toString(),
        name: json['name']?.toString() ?? '',
      );
}

/// The same suggestions as [DescriptionSuggestionResponse.suggestions], split
/// per subcategory. Only useful for section headers when the user has not
/// picked a subcategory yet.
class DescriptionGroup {
  final DescriptionSubCategoryRef? subCategory;
  final int count;
  final List<DescriptionSuggestion> suggestions;

  const DescriptionGroup({
    this.subCategory,
    required this.count,
    required this.suggestions,
  });

  factory DescriptionGroup.fromJson(Map<String, dynamic> json) =>
      DescriptionGroup(
        subCategory: json['sub_category'] == null
            ? null
            : DescriptionSubCategoryRef.fromJson(
                Map<String, dynamic>.from(json['sub_category'] as Map)),
        count: (json['count'] as num?)?.toInt() ?? 0,
        suggestions: (json['suggestions'] as List? ?? const [])
            .map((e) =>
                DescriptionSuggestion.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class DescriptionSuggestionResponse {
  final DescriptionCategoryRef? category;
  final DescriptionSubCategoryRef? subCategory;
  final bool hasSubCategories;
  final String? businessName;
  final String placeholder;
  final bool placeholderReplaced;
  final int total;
  final List<DescriptionSuggestion> suggestions;
  final List<DescriptionGroup> groups;

  const DescriptionSuggestionResponse({
    this.category,
    this.subCategory,
    required this.hasSubCategories,
    this.businessName,
    required this.placeholder,
    required this.placeholderReplaced,
    required this.total,
    required this.suggestions,
    required this.groups,
  });

  /// [json] is the full envelope — `{success, message, data: {...}}`.
  factory DescriptionSuggestionResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : <String, dynamic>{};

    return DescriptionSuggestionResponse(
      category: data['category'] is Map
          ? DescriptionCategoryRef.fromJson(
              Map<String, dynamic>.from(data['category'] as Map))
          : null,
      subCategory: data['sub_category'] is Map
          ? DescriptionSubCategoryRef.fromJson(
              Map<String, dynamic>.from(data['sub_category'] as Map))
          : null,
      hasSubCategories: data['has_sub_categories'] == true,
      businessName: data['business_name']?.toString(),
      placeholder: data['placeholder']?.toString() ?? '{business_name}',
      placeholderReplaced: data['placeholder_replaced'] == true,
      total: (data['total'] as num?)?.toInt() ?? 0,
      suggestions: (data['suggestions'] as List? ?? const [])
          .map((e) =>
              DescriptionSuggestion.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      groups: (data['groups'] as List? ?? const [])
          .map((e) => DescriptionGroup.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  /// Fill `{business_name}` locally. No-op when the backend already did it or
  /// when the name is empty.
  DescriptionSuggestionResponse filledWith(String businessName) {
    if (placeholderReplaced || businessName.trim().isEmpty) return this;
    return DescriptionSuggestionResponse(
      category: category,
      subCategory: subCategory,
      hasSubCategories: hasSubCategories,
      businessName: businessName.trim(),
      placeholder: placeholder,
      placeholderReplaced: true,
      total: total,
      suggestions: suggestions
          .map((s) => s.withBusinessName(businessName, placeholder: placeholder))
          .toList(),
      groups: groups
          .map((g) => DescriptionGroup(
                subCategory: g.subCategory,
                count: g.count,
                suggestions: g.suggestions
                    .map((s) =>
                        s.withBusinessName(businessName, placeholder: placeholder))
                    .toList(),
              ))
          .toList(),
    );
  }
}
