/// Payload carried by a `messageType: "education_enquiry"` chat message.
///
/// Mirrors the shape settled in `lib/docs/enquiry-flows-ui-integration.md`
/// §3: a listing id (`listing_id` on the request body, denormalised back
/// as `listingId` on the card), grouped selections (Courses / Admission
/// For / Requirements / Timeline — keys are app-defined and rendered
/// verbatim by the in-chat card), optional [note] / [photos], and a
/// [status] the owner flips via the `educationEnquiryStatusUpdated` socket.
///
/// A small listing snapshot ([listingName] / [listingImage] / [location])
/// is embedded so the in-chat card renders without re-fetching the school.
class EducationEnquiryModel {
  String? enquiryId;
  String? listingId;
  String? ownerId;
  String? customerId;

  // Listing snapshot.
  String? listingName;
  String? listingImage;
  String? location;

  /// Free-form group → values map (Courses / Admission For / Requirements
  /// / Timeline). Group labels are app-defined and shipped verbatim.
  Map<String, List<String>>? selections;

  List<String>? photos;
  String? note;

  /// 'pending' | 'accepted' | 'declined' (no cancel).
  String? status;

  EducationEnquiryModel({
    this.enquiryId,
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

  factory EducationEnquiryModel.fromJson(Map<String, dynamic> json) {
    // The education endpoint accepts named arrays on the request body
    // (`courses`, `admissionFor`, `requirements`, `timeline`); the chat
    // card contract is the generic `selections` map. Accept either shape
    // and normalise to the map.
    Map<String, List<String>>? selections = _selectionsMap(json['selections']);
    if (selections == null) {
      final fallback = <String, List<String>>{};
      void add(String title, dynamic raw) {
        final items = _stringList(raw);
        if (items != null && items.isNotEmpty) fallback[title] = items;
      }

      add('Courses', json['courses']);
      add('Admission For', json['admissionFor']);
      add('Requirements', json['requirements']);
      add('Timeline', json['timeline']);
      if (fallback.isNotEmpty) selections = fallback;
    }

    return EducationEnquiryModel(
      enquiryId: (json['enquiryId'] ?? json['_id'] ?? json['id'])?.toString(),
      listingId: (json['listingId'] ?? json['listing_id'])?.toString(),
      ownerId: (json['ownerId'] ?? json['owner_id'])?.toString(),
      customerId: (json['customerId'] ?? json['customer_id'])?.toString(),
      listingName: json['listingName']?.toString(),
      listingImage:
          (json['listingImage'] ?? json['listing_image'])?.toString(),
      location: json['location']?.toString(),
      selections: selections,
      photos: _stringList(json['photos']),
      note: json['note']?.toString(),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enquiryId': enquiryId,
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
}
