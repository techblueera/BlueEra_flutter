import 'package:BlueEra/features/me/laboratory/model/lab_test_models.dart';

/// Bundle of existing [PathologyTest]s sold as a package with its own
/// MRP + customer price. See lib/docs/LABORATORY_INTEGRATION.md §1.
///
/// The `tests` field is polymorphic on the wire:
///  - list endpoint (`GET /packages/laboratory/:labId`) returns raw ids
///  - detail endpoint (`GET /packages/:id`) returns populated
///    [PathologyTest] objects
/// [testIds] and [tests] surface both — whichever is present.
class LabPackage {
  String? id;
  String? name;
  String? description;
  String? imageUrl;
  int? packageMrp;
  int? customerPrice;

  /// One of the 26 backend preset values (see
  /// FLUTTER_CATALOGUE_INTEGRATION.md PART 3B §`packageType` vs `name`).
  /// Drives the icon switch and the `/packages/me?packageType=...` filter
  /// — distinct from [name], which is the lab's own display title.
  /// Optional; may be null on legacy rows created before this field
  /// existed.
  String? packageType;

  /// "Male" | "Female" | "All" (default "All"). See doc §1 create body.
  String? gender;

  /// Populated [PathologyTest] objects when the detail endpoint returned
  /// them; null otherwise.
  List<PathologyTest>? tests;

  /// The raw id list — always present, whether or not the endpoint
  /// populated [tests].
  List<String> testIds;

  String? userId;
  String? laboratoryId;
  String? createdAt;
  String? updatedAt;

  LabPackage({
    this.id,
    this.name,
    this.description,
    this.imageUrl,
    this.packageMrp,
    this.customerPrice,
    this.packageType,
    this.gender,
    this.tests,
    List<String>? testIds,
    this.userId,
    this.laboratoryId,
    this.createdAt,
    this.updatedAt,
  }) : testIds = testIds ?? const [];

  factory LabPackage.fromJson(Map<String, dynamic> json) {
    final rawTests = json['tests'];
    List<PathologyTest>? populated;
    List<String> ids = const [];
    if (rawTests is List) {
      if (rawTests.isNotEmpty && rawTests.first is Map<String, dynamic>) {
        populated = rawTests
            .whereType<Map<String, dynamic>>()
            .map(PathologyTest.fromJson)
            .toList();
        ids = populated
            .map((t) => (t.id ?? '').trim())
            .where((s) => s.isNotEmpty)
            .toList();
      } else {
        ids = rawTests.map((e) => e?.toString() ?? '').toList();
      }
    }
    return LabPackage(
      id: json['_id']?.toString(),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      packageMrp: _asInt(json['packageMrp']),
      customerPrice: _asInt(json['customerPrice']),
      packageType: json['packageType']?.toString(),
      gender: json['gender']?.toString(),
      tests: populated,
      testIds: ids,
      userId: json['userId']?.toString(),
      laboratoryId: json['laboratoryId']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  /// Wire-shape for POST /packages and PUT /packages/:id.
  /// `userId` / `laboratoryId` are derived server-side (doc §Notes) — never
  /// send them from the client.
  Map<String, dynamic> toCreateJson() => {
        'name': name,
        if ((description ?? '').isNotEmpty) 'description': description,
        if ((imageUrl ?? '').isNotEmpty) 'imageUrl': imageUrl,
        'tests': testIds,
        if (packageMrp != null) 'packageMrp': packageMrp,
        if (customerPrice != null) 'customerPrice': customerPrice,
        if ((packageType ?? '').isNotEmpty) 'packageType': packageType,
        'gender': gender ?? 'All',
      };

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}
