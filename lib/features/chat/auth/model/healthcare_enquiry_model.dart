/// Payload carried by a `messageType: "healthcare_enquiry"` chat message.
///
/// One uniform shape across every healthcare category (Hospitals, Doctors,
/// Labs, Pharmacy, Surgical, any future one). The form on the customer side
/// captures arbitrary, category-defined groups as the generic [selections]
/// map (each key = a section title, value = chosen items) — exactly what the
/// in-chat card iterates to render. A small snapshot of the listing
/// ([listingName] / [listingImage] / [location]) is embedded so the card
/// renders without re-fetching the source listing.
///
/// Delivered to the owner via the `newHealthcareEnquiryReceived` socket event
/// and persisted so it also loads in chat history. The owner accepts /
/// declines via the card, which flips [status] (mirrored by the
/// `healthcareEnquiryStatusUpdated` event).
///
/// See lib/docs/healthcare-enquiry-ui-integration.md §4 for the wire shape.
/// Mirrors [ServiceEnquiryModel] / [PropertyEnquiryModel] but with a generic
/// `selections` map instead of named groups — the doc explicitly settles on a
/// single card shape across all healthcare categories.
class HealthcareEnquiryModel {
  String? enquiryId;

  /// 'HOSPITAL' for the hospital endpoint; otherwise the business's
  /// `category_Of_Business` (e.g. 'DOCTOR', 'LAB', 'PHARMACY', 'SURGICAL').
  /// Drives any category-specific styling on the card.
  String? category;

  /// `Hospital._id` (HOSPITAL category) or `Business._id` (everything else).
  String? listingId;

  String? ownerId;
  String? customerId;

  // Listing snapshot — denormalised so the card has everything it needs.
  String? listingName;
  String? listingImage;
  String? location;

  /// Free-form group → values map. Each key renders as a section title on
  /// the card, the value as its chips. Group labels are app-defined per
  /// category (Departments / Purpose / Timeline for HOSPITAL, Test Types /
  /// Purpose for LAB, etc.) — see lib/docs/healthcare-enquiry-ui-integration.md
  /// §1 "Selection groups are app-defined".
  Map<String, List<String>>? selections;

  /// URLs of any photos the customer attached.
  List<String>? photos;

  String? note;

  /// 'pending' | 'accepted' | 'declined'
  String? status;

  HealthcareEnquiryModel({
    this.enquiryId,
    this.category,
    this.listingId,
    this.ownerId,
    this.customerId,
    this.listingName,
    this.listingImage,
    this.location,
    this.selections,
    this.photos,
    this.note,
    this.status,
  });

  static List<String>? _stringList(dynamic v) => v is List
      ? List<String>.from(v.map((e) => e.toString()))
      : null;

  static Map<String, List<String>>? _selectionsMap(dynamic v) {
    if (v is! Map) return null;
    final out = <String, List<String>>{};
    v.forEach((key, value) {
      if (value is List) {
        final items = value
            .map((e) => e.toString())
            .where((s) => s.trim().isNotEmpty)
            .toList();
        if (items.isNotEmpty) out[key.toString()] = items;
      }
    });
    return out.isEmpty ? null : out;
  }

  factory HealthcareEnquiryModel.fromJson(Map<String, dynamic> json) {
    return HealthcareEnquiryModel(
      enquiryId: (json['enquiryId'] ?? json['_id'] ?? json['id'])?.toString(),
      category: json['category']?.toString(),
      listingId: (json['listingId'] ?? json['listing_id'])?.toString(),
      ownerId: (json['ownerId'] ?? json['owner_id'])?.toString(),
      customerId: (json['customerId'] ?? json['customer_id'])?.toString(),
      listingName: json['listingName']?.toString(),
      listingImage:
          (json['listingImage'] ?? json['listing_image'])?.toString(),
      location: json['location']?.toString(),
      selections: _selectionsMap(json['selections']),
      photos: _stringList(json['photos']),
      note: json['note']?.toString(),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enquiryId': enquiryId,
      'category': category,
      'listingId': listingId,
      'ownerId': ownerId,
      'customerId': customerId,
      'listingName': listingName,
      'listingImage': listingImage,
      'location': location,
      'selections': selections,
      'photos': photos,
      'note': note,
      'status': status,
    };
  }

  /// Flattened, de-duplicated view of every selected item across all groups
  /// — handy for previews / counts.
  List<String> get allSelections {
    final out = <String>[];
    final seen = <String>{};
    for (final group in (selections ?? const <String, List<String>>{}).values) {
      for (final item in group) {
        final key = item.toLowerCase();
        if (seen.add(key)) out.add(item);
      }
    }
    return out;
  }
}
