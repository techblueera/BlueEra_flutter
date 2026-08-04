/// Models for `GET user-service/individual-professions/bio-suggestions` — the
/// ready-written bios offered per profession / designation.
/// See docs/FLUTTER_INDIVIDUAL_BIO_SUGGESTIONS_GUIDE.md
class BioSuggestion {
  final List<String> lines;
  final String text;

  const BioSuggestion({required this.lines, required this.text});

  factory BioSuggestion.fromJson(Map<String, dynamic> json) => BioSuggestion(
        lines: (json['lines'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        text: json['text']?.toString() ?? '',
      );

  /// One flowing paragraph — what the bio field stores.
  String get asParagraph => text;

  String get asLineBroken => lines.join('\n');

  String get asSpacedParagraphs => lines.join('\n\n');

  /// The paragraph trimmed to the whole sentences that fit inside [limit] —
  /// the bio field caps at 900 characters. Falls back to a cut at the last
  /// word boundary when even the first sentence overflows.
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
}

class ProfessionRef {
  final String? id;
  final String name;
  final String? tagId;
  final String? profileType;

  const ProfessionRef({this.id, required this.name, this.tagId, this.profileType});

  factory ProfessionRef.fromJson(Map<String, dynamic> json) => ProfessionRef(
        id: json['id']?.toString(),
        name: json['name']?.toString() ?? '',
        tagId: json['tag_id']?.toString(),
        profileType: json['profile_type']?.toString(),
      );
}

/// A designation — an entry embedded in the profession document
/// (`subcategories_filedName`), not a row in a separate collection.
class BioSubcategoryRef {
  final String? id;
  final String name;
  final String? tagId;

  const BioSubcategoryRef({this.id, required this.name, this.tagId});

  factory BioSubcategoryRef.fromJson(Map<String, dynamic> json) =>
      BioSubcategoryRef(
        id: json['id']?.toString(),
        name: json['name']?.toString() ?? '',
        tagId: json['tag_id']?.toString(),
      );
}

/// The same suggestions as [BioSuggestionResponse.suggestions], split per
/// designation. Only useful for section headers when no designation is set.
class BioSuggestionGroup {
  final BioSubcategoryRef? subcategory;
  final int count;
  final List<BioSuggestion> suggestions;

  const BioSuggestionGroup({
    this.subcategory,
    required this.count,
    required this.suggestions,
  });

  factory BioSuggestionGroup.fromJson(Map<String, dynamic> json) =>
      BioSuggestionGroup(
        subcategory: json['subcategory'] is Map
            ? BioSubcategoryRef.fromJson(
                Map<String, dynamic>.from(json['subcategory'] as Map))
            : null,
        count: (json['count'] as num?)?.toInt() ?? 0,
        suggestions: (json['suggestions'] as List? ?? const [])
            .map((e) => BioSuggestion.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class BioSuggestionResponse {
  final ProfessionRef? profession;
  final BioSubcategoryRef? subcategory;
  final bool hasSubcategories;
  final int total;
  final List<BioSuggestion> suggestions;
  final List<BioSuggestionGroup> groups;

  /// Only present on a 404 for an unknown designation: the designations that
  /// *do* have content, so the caller can retry or fall back.
  final List<BioSubcategoryRef> availableSubcategories;

  const BioSuggestionResponse({
    this.profession,
    this.subcategory,
    required this.hasSubcategories,
    required this.total,
    required this.suggestions,
    required this.groups,
    this.availableSubcategories = const [],
  });

  /// [json] is the full envelope — `{success, message, data: {...}}`.
  factory BioSuggestionResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : <String, dynamic>{};

    return BioSuggestionResponse(
      profession: data['profession'] is Map
          ? ProfessionRef.fromJson(
              Map<String, dynamic>.from(data['profession'] as Map))
          : null,
      subcategory: data['subcategory'] is Map
          ? BioSubcategoryRef.fromJson(
              Map<String, dynamic>.from(data['subcategory'] as Map))
          : null,
      hasSubcategories: data['has_subcategories'] == true,
      total: (data['total'] as num?)?.toInt() ?? 0,
      suggestions: (data['suggestions'] as List? ?? const [])
          .map((e) => BioSuggestion.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      groups: (data['groups'] as List? ?? const [])
          .map((e) =>
              BioSuggestionGroup.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      availableSubcategories: (data['available_subcategories'] as List? ??
              const [])
          .map((e) =>
              BioSubcategoryRef.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
