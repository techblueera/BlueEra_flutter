/// Payload carried by a `messageType: "business_enquiry"` chat message.
///
/// One uniform shape across every "other" business category
/// (LOANS_SECTOR / INSURANCE / CAPITAL_MARKET / BANKING / DATA / …). The
/// customer-side form captures arbitrary, category-defined groups as the
/// generic [selections] map (each key = a section title, value = chosen
/// items) — the in-chat card iterates it verbatim. A small snapshot of the
/// listing ([listingName] / [listingImage] / [location]) is embedded so
/// the card renders without re-fetching the source listing.
///
/// Delivered to the owner via the `newBusinessEnquiryReceived` socket
/// event and persisted so it also loads in chat history. The owner
/// accepts / declines via the card, which flips [status] (mirrored by the
/// `businessEnquiryStatusUpdated` event).
///
/// See lib/docs/other-enquiry-ui-integration.md §5 for the wire shape.
/// Mirrors [HealthcareEnquiryModel] — same generic-selections structure,
/// different owning service (`be_other_service` vs `be_user_service`) and
/// card type.
class BusinessEnquiryModel {
  String? enquiryId;

  /// Server-side category snapshot copied from the source BusinessProfile
  /// (e.g. 'LOANS_SECTOR', 'INSURANCE', 'CAPITAL_MARKET', 'BANKING',
  /// 'DATA'). Drives any category-specific styling on the card.
  String? category;

  /// `BusinessProfile._id` of the listing being enquired about.
  String? listingId;

  String? ownerId;
  String? customerId;

  // Listing snapshot — denormalised so the card has everything it needs.
  String? listingName;
  String? listingImage;
  String? location;

  /// Free-form group → values map. Each key renders as a section title on
  /// the card, the value as its chips. Group labels are app-defined per
  /// category (Services / Purpose for LOANS_SECTOR, Policy Type / Purpose
  /// for INSURANCE, etc.) — see lib/docs/other-enquiry-ui-integration.md
  /// §2 "selections is an open group→values map".
  Map<String, List<String>>? selections;

  /// URLs of any photos the customer attached (max 5, pre-uploaded via
  /// `/upload/init` presign — see §1).
  List<String>? photos;

  String? note;

  /// 'pending' | 'accepted' | 'declined'
  String? status;

  BusinessEnquiryModel({
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

  factory BusinessEnquiryModel.fromJson(Map<String, dynamic> json) {
    return BusinessEnquiryModel(
      enquiryId: (json['enquiryId'] ?? json['_id'] ?? json['id'])?.toString(),
      category: json['category']?.toString(),
      listingId: (json['listingId'] ??
              json['listing_id'] ??
              json['businessId'] ??
              json['business_id'])
          ?.toString(),
      ownerId: (json['ownerId'] ?? json['owner_id'])?.toString(),
      customerId: (json['customerId'] ?? json['customer_id'])?.toString(),
      listingName:
          (json['listingName'] ?? json['listing_name'])?.toString(),
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
