/// One ready-made question from `GET chat-service/support/questions`.
///
/// The backend always sends both languages, so the widget picks per app locale
/// rather than re-fetching when the user switches language. See
/// lib/docs/HELP_WIDGET_FLUTTER_GUIDE.md §1.1.
class HelpQuestion {
  const HelpQuestion({required this.id, required this.en, required this.hi});

  /// Server id (`h1`, `h2`, …). The last item is always `other`, which opens
  /// the free-text field instead of sending.
  final String id;
  final String en;
  final String hi;

  /// True for the trailing "Other inquiry" row.
  bool get isOther => id == 'other';

  factory HelpQuestion.fromJson(Map<dynamic, dynamic> json) {
    final en = (json['en'] ?? '').toString();
    return HelpQuestion(
      id: (json['id'] ?? '').toString(),
      en: en,
      // Fall back to English rather than rendering an empty row if a
      // translation is ever missing.
      hi: (json['hi'] ?? '').toString().isEmpty ? en : json['hi'].toString(),
    );
  }

  /// The text to show — and to send — for [languageCode] ('hi' or anything
  /// else, which reads as English).
  String label(String languageCode) => languageCode == 'hi' ? hi : en;
}

/// The whole `GET /support/questions` reply.
class HelpQuestionsResult {
  const HelpQuestionsResult({
    required this.questions,
    this.existingConversationId,
  });

  final List<HelpQuestion> questions;

  /// Set when the user already has a support thread — the bubble then skips
  /// the question panel and opens that conversation directly.
  final String? existingConversationId;

  factory HelpQuestionsResult.fromJson(Map<dynamic, dynamic> json) {
    final raw = json['questions'];
    final existing = (json['existing_conversation_id'] ?? '').toString();
    return HelpQuestionsResult(
      questions: raw is List
          ? raw
              .whereType<Map>()
              .map(HelpQuestion.fromJson)
              .where((q) => q.en.isNotEmpty)
              .toList()
          : const [],
      existingConversationId: existing.isEmpty ? null : existing,
    );
  }
}
