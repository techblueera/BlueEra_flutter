/// Payload carried by a `messageType: "service_enquiry"` chat message.
///
/// Created server-side when a customer submits the Discover self-profession
/// "Enquire" form, then delivered to the provider over the
/// `newServiceEnquiryReceived` socket event and persisted so it also loads in
/// chat history. The provider accepts / declines via the card, which flips
/// [status] (mirrored by the `serviceEnquiryStatusUpdated` event).
///
/// The customer's request is captured as three grouped selections — mirroring
/// the provider's own profile fields ([serviceType] / [typesOfWork] /
/// [servicesOffered]) — plus an optional free-text [note].
///
/// See docs/backend/service-enquiry-api.md for the wire contract.
class ServiceEnquiryModel {
  String? enquiryId;
  String? providerId;
  String? customerId;

  List<String>? serviceType;
  List<String>? typesOfWork;
  List<String>? workCategories;
  List<String>? servicesOffered;

  /// Generic intent options (Installation / Repair / Maintenance / …) — always
  /// offered on the form regardless of the provider's own listed fields.
  List<String>? requestType;

  /// URLs of any photos the customer attached ("show the problem").
  List<String>? photos;

  String? note;

  /// 'pending' | 'accepted' | 'declined'
  String? status;

  ServiceEnquiryModel({
    this.enquiryId,
    this.providerId,
    this.customerId,
    this.serviceType,
    this.typesOfWork,
    this.workCategories,
    this.servicesOffered,
    this.requestType,
    this.photos,
    this.note,
    this.status,
  });

  static List<String>? _stringList(dynamic v) => v is List
      ? List<String>.from(v.map((e) => e.toString()))
      : null;

  factory ServiceEnquiryModel.fromJson(Map<String, dynamic> json) {
    return ServiceEnquiryModel(
      enquiryId: (json['enquiryId'] ?? json['_id'] ?? json['id'])?.toString(),
      providerId: (json['providerId'] ?? json['provider_id'])?.toString(),
      customerId: (json['customerId'] ?? json['customer_id'])?.toString(),
      serviceType: _stringList(json['serviceType']),
      typesOfWork: _stringList(json['typesOfWork']),
      workCategories: _stringList(json['workCategories']),
      servicesOffered:
          _stringList(json['servicesOffered'] ?? json['serviceOffered']),
      requestType: _stringList(json['requestType']),
      photos: _stringList(json['photos']),
      note: json['note']?.toString(),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enquiryId': enquiryId,
      'providerId': providerId,
      'customerId': customerId,
      'serviceType': serviceType,
      'typesOfWork': typesOfWork,
      'workCategories': workCategories,
      'servicesOffered': servicesOffered,
      'requestType': requestType,
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
    for (final group in [
      serviceType,
      typesOfWork,
      workCategories,
      servicesOffered,
      requestType,
    ]) {
      for (final item in group ?? const <String>[]) {
        final key = item.toLowerCase();
        if (seen.add(key)) out.add(item);
      }
    }
    return out;
  }
}
