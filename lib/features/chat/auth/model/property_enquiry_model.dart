/// Payload carried by a `messageType: "property_enquiry"` chat message.
///
/// Created server-side when a customer submits the rental Discover "Enquire"
/// form on a property listing card, then delivered to the owner over the
/// `newPropertyEnquiryReceived` socket event and persisted so it also loads in
/// chat history. The owner accepts / declines via the card, which flips
/// [status] (mirrored by the `propertyEnquiryStatusUpdated` event).
///
/// The customer's request is captured as grouped selections — [purpose],
/// [requirements], [intendedUse], [timeline] — plus an optional free-text
/// [note] and [photos]. A small snapshot of the property ([propertyName] /
/// [propertyImage] / [priceText] / [location]) is embedded so the in-chat
/// card renders without re-fetching the listing.
///
/// See docs/backend/property-enquiry-flutter-integration.md for the wire
/// contract. Mirrors [ServiceEnquiryModel].
class PropertyEnquiryModel {
  String? enquiryId;
  String? propertyId;
  String? ownerId;
  String? customerId;

  // Property snapshot (so the card header renders standalone in chat).
  String? propertyName;
  String? propertyImage;
  String? priceText;
  String? location;

  // Grouped selections.
  List<String>? purpose;
  List<String>? requirements;
  List<String>? intendedUse;
  List<String>? timeline;

  /// URLs of any photos the customer attached.
  List<String>? photos;

  String? note;

  /// 'pending' | 'accepted' | 'declined'
  String? status;

  PropertyEnquiryModel({
    this.enquiryId,
    this.propertyId,
    this.ownerId,
    this.customerId,
    this.propertyName,
    this.propertyImage,
    this.priceText,
    this.location,
    this.purpose,
    this.requirements,
    this.intendedUse,
    this.timeline,
    this.photos,
    this.note,
    this.status,
  });

  static List<String>? _stringList(dynamic v) =>
      v is List ? List<String>.from(v.map((e) => e.toString())) : null;

  factory PropertyEnquiryModel.fromJson(Map<String, dynamic> json) {
    return PropertyEnquiryModel(
      enquiryId: (json['enquiryId'] ?? json['_id'] ?? json['id'])?.toString(),
      propertyId: (json['propertyId'] ?? json['property_id'])?.toString(),
      ownerId: (json['ownerId'] ?? json['owner_id'])?.toString(),
      customerId: (json['customerId'] ?? json['customer_id'])?.toString(),
      propertyName: json['propertyName']?.toString(),
      propertyImage:
          (json['propertyImage'] ?? json['property_image'])?.toString(),
      priceText: (json['priceText'] ?? json['price_text'])?.toString(),
      location: json['location']?.toString(),
      purpose: _stringList(json['purpose']),
      requirements: _stringList(json['requirements']),
      intendedUse: _stringList(json['intendedUse']),
      timeline: _stringList(json['timeline']),
      photos: _stringList(json['photos']),
      note: json['note']?.toString(),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enquiryId': enquiryId,
      'propertyId': propertyId,
      'ownerId': ownerId,
      'customerId': customerId,
      'propertyName': propertyName,
      'propertyImage': propertyImage,
      'priceText': priceText,
      'location': location,
      'purpose': purpose,
      'requirements': requirements,
      'intendedUse': intendedUse,
      'timeline': timeline,
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
    for (final group in [purpose, requirements, intendedUse, timeline]) {
      for (final item in group ?? const <String>[]) {
        final key = item.toLowerCase();
        if (seen.add(key)) out.add(item);
      }
    }
    return out;
  }
}
