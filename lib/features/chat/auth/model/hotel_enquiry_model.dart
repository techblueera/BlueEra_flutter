/// Payload carried by a `messageType: "hotel_enquiry"` chat message.
///
/// Mirrors the shape settled in `lib/docs/enquiry-flows-ui-integration.md`
/// §2a: a hotel id (`hotel_id` on the request body, denormalised back as
/// `hotelId` on the card), grouped selections (Room Type / Purpose /
/// Amenities / Timeline — keys are app-defined and rendered verbatim by the
/// in-chat card), optional [note] / [photos], and a [status] the owner
/// flips via the `hotelEnquiryStatusUpdated` socket.
///
/// A small listing snapshot ([listingName] / [listingImage] / [priceText] /
/// [location]) is embedded so the in-chat card renders without re-fetching
/// the listing. `priceText` is **display only** — nothing is charged.
class HotelEnquiryModel {
  String? enquiryId;
  String? hotelId;
  String? ownerId;
  String? customerId;

  // Listing snapshot.
  String? listingName;
  String? listingImage;
  String? priceText;
  String? location;

  /// Free-form group → values map (Room Type / Purpose / Amenities /
  /// Timeline). Group labels are app-defined and shipped verbatim — see
  /// §"Notes for the chat card widget" in the integration guide.
  Map<String, List<String>>? selections;

  List<String>? photos;
  String? note;

  /// 'pending' | 'accepted' | 'declined' (no cancel for the enquiry flow).
  String? status;

  HotelEnquiryModel({
    this.enquiryId,
    this.hotelId,
    this.ownerId,
    this.customerId,
    this.listingName,
    this.listingImage,
    this.priceText,
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

  factory HotelEnquiryModel.fromJson(Map<String, dynamic> json) {
    // The hotel endpoint takes named arrays on the request body
    // (`roomType`, `purpose`, `amenities`, `timeline`) but the chat card
    // contract is the generic `selections` map; the backend echoes both
    // shapes so we accept either here and normalise to the map.
    Map<String, List<String>>? selections = _selectionsMap(json['selections']);
    if (selections == null) {
      final fallback = <String, List<String>>{};
      void add(String title, dynamic raw) {
        final items = _stringList(raw);
        if (items != null && items.isNotEmpty) fallback[title] = items;
      }

      add('Room Type', json['roomType']);
      add('Purpose', json['purpose']);
      add('Amenities', json['amenities']);
      add('Timeline', json['timeline']);
      if (fallback.isNotEmpty) selections = fallback;
    }

    return HotelEnquiryModel(
      enquiryId: (json['enquiryId'] ?? json['_id'] ?? json['id'])?.toString(),
      hotelId: (json['hotelId'] ?? json['hotel_id'])?.toString(),
      ownerId: (json['ownerId'] ?? json['owner_id'])?.toString(),
      customerId: (json['customerId'] ?? json['customer_id'])?.toString(),
      listingName: json['listingName']?.toString(),
      listingImage:
          (json['listingImage'] ?? json['listing_image'])?.toString(),
      priceText: (json['priceText'] ?? json['price_text'])?.toString(),
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
      'hotelId': hotelId,
      'ownerId': ownerId,
      'customerId': customerId,
      'listingName': listingName,
      'listingImage': listingImage,
      'priceText': priceText,
      'location': location,
      'selections': selections,
      'photos': photos,
      'note': note,
      'status': status,
    };
  }
}
