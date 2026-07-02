/// One selection group returned by
/// `GET other-service/predefined-enquiry/{category}`. Ordered array of
/// these makes up the sheet body — the title is used **verbatim** as the
/// key when building `selections` on the eventual `POST /other-enquiries`
/// call, so the chat card renders the same section header on both sides.
///
/// [multiSelect] governs chip behaviour:
///   • `true`  → toggle chips (0..n selectable) — e.g. "Services".
///   • `false` → radio chips (0..1 selectable — selecting a chip
///                 deselects the group's previous one) — e.g.
///                 "Loan Amount" ranges.
///
/// See `lib/docs/predefined-enquiry-ui-integration.md` §1 for the wire
/// shape and §2 for the rendering rules.
class PredefinedEnquiryGroup {
  final String title;
  final List<String> options;
  final bool multiSelect;

  const PredefinedEnquiryGroup({
    required this.title,
    required this.options,
    required this.multiSelect,
  });

  /// Tolerant parser — the backend contract says `multiSelect` is a bool
  /// but we default to `true` if missing so unknown / future group
  /// definitions render as toggle chips rather than accidentally locking
  /// users into a single choice.
  factory PredefinedEnquiryGroup.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = rawOptions is List
        ? rawOptions
            .map((e) => e.toString())
            .where((s) => s.trim().isNotEmpty)
            .toList()
        : const <String>[];
    return PredefinedEnquiryGroup(
      title: (json['title'] ?? '').toString(),
      options: options,
      multiSelect: json['multiSelect'] != false,
    );
  }
}
