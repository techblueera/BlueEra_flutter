/// Descriptor for a single Quick Info field returned by
/// `GET /schools/:id/quick-info` (and `/schools/options?category=`).
///
/// Six Siksha categories share one storage collection but each renders a
/// different set of fields. The backend owns the mapping and streams
/// these descriptors down so the UI can build the form/display without
/// hardcoding per-category widgets. See
/// lib/docs/SCHOOL_QUICK_INFO_UI_INTEGRATION.md.
class QuickInfoField {
  /// The `quickInfo` property this field writes to. Send back under this
  /// exact key.
  final String key;

  /// The input heading, e.g. "Board".
  final String label;

  /// One of `stringArray` (chip-multi), `string` (text/single-select), or
  /// `number`. Unknown types fall back to `string` at the render layer.
  final String type;

  /// Helper text placed under the heading.
  final String? placeholder;

  /// Suggestion pool for the input. **Never a closed set** — the user may
  /// always type a custom value.
  final List<String> suggestions;

  const QuickInfoField({
    required this.key,
    required this.label,
    required this.type,
    this.placeholder,
    this.suggestions = const [],
  });

  factory QuickInfoField.fromJson(dynamic json) {
    if (json is! Map) {
      return const QuickInfoField(key: '', label: '', type: 'string');
    }
    final rawSuggestions = json['suggestions'];
    return QuickInfoField(
      key: (json['key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      type: (json['type'] ?? 'string').toString(),
      placeholder: json['placeholder']?.toString(),
      suggestions: rawSuggestions is List
          ? rawSuggestions.map((e) => e.toString()).toList(growable: false)
          : const [],
    );
  }
}

/// Canonical per-category field whitelist from the integration doc §2.
///
/// The backend is the source of truth for descriptors, but when its
/// response drifts (e.g. `category: null` → doc says "every field is
/// returned"), or when we simply want to guarantee a School listing
/// never renders College inputs, we filter what the API sent down to
/// this list. Keys are matched loosely against the category string so
/// aliases like "College" resolve to "College/University".
const Map<String, List<String>> kQuickInfoFieldsByCategory = {
  'School Education': [
    'classRange',
    'studentTeacherRatio',
    'board',
    'mediumOfInstruction',
    'numberOfStudents',
  ],
  'Coaching/Institute': [
    'classRange',
    'studentTeacherRatio',
    'board',
    'mediumOfInstruction',
    'numberOfStudents',
  ],
  'College/University': [
    'classRange',
    'studentTeacherRatio',
    'coursesOffered',
    'affiliatedUniversity',
    'streams',
    'numberOfStudents',
  ],
  'Sports & Hobby': [
    'sportsOffered',
    'sportsFacilities',
    'achievements',
    'numberOfStudents',
  ],
  'Professional Learn': [
    'skillPrograms',
    'industryPartnerships',
    'certifications',
    'numberOfStudents',
  ],
  'Skill Training': [
    'skillPrograms',
    'industryPartnerships',
    'certifications',
    'numberOfStudents',
  ],
};

/// Match a raw category string to a whitelist key. Casing, spacing and
/// punctuation are ignored so `"college"` → `"College/University"` and
/// `"skill-training"` → `"Skill Training"`.
///
/// Returns `null` when the category doesn't map to any known entry —
/// callers should fall back to trusting the backend descriptors as-is.
String? resolveQuickInfoCategoryKey(String? raw) {
  if (raw == null) return null;
  final norm = _normalise(raw);
  if (norm.isEmpty) return null;
  for (final key in kQuickInfoFieldsByCategory.keys) {
    if (_normalise(key) == norm) return key;
  }
  // Common aliases seen in the API.
  const aliases = {
    'college': 'College/University',
    'coaching': 'Coaching/Institute',
    'sports': 'Sports & Hobby',
    'professional': 'Professional Learn',
    'skill': 'Skill Training',
    'school': 'School Education',
  };
  final aliased = aliases[norm];
  if (aliased != null) return aliased;
  return null;
}

String _normalise(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
