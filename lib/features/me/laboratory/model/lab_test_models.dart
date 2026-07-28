
class TestCategory {
  String? id;
  String? name;
  String? userId;
  String? laboratoryId;
  String? description;
  String? iconUrl;

  TestCategory({
    this.id,
    this.name,
    this.userId,
    this.laboratoryId,
    this.description,
    this.iconUrl,
  });

  factory TestCategory.fromJson(Map<String, dynamic> json) => TestCategory(
        id: json["_id"],
        name: json["name"],
        userId: json["userId"],
        laboratoryId: json["laboratoryId"],
        description: json["description"],
        iconUrl: json["iconUrl"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "name": name,
        "userId": userId,
        "laboratoryId": laboratoryId,
        "description": description,
        "iconUrl": iconUrl,
      };
}

class TestParameter {
  String? id;
  String? name;
  String? userId;
  String? laboratoryId;
  String? description;

  TestParameter({
    this.id,
    this.name,
    this.userId,
    this.laboratoryId,
    this.description,
  });

  factory TestParameter.fromJson(Map<String, dynamic> json) => TestParameter(
        id: json["_id"],
        name: json["name"],
        userId: json["userId"],
        laboratoryId: json["laboratoryId"],
        description: json["description"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "name": name,
        "userId": userId,
        "laboratoryId": laboratoryId,
        "description": description,
      };
}

class PathologyTest {
  String? id;
  String? testName;
  String? userId;
  String? laboratoryId;
  dynamic testCategory; // Can be String (ID) or TestCategory object
  String? description;
  List<dynamic>? testParameters; // Can be List<String> (IDs) or List<TestParameter> objects
  String? specimen;
  String? specimenCollectionMethod;
  int? estimatedReportHours;
  String? gender;
  String? beforeTestGuidance;
  String? postTestGuidance;
  String? testMethod;
  String? organSystemTested;
  bool? applicableForChild;
  bool? prescriptionRequired;
  int? testFees;
  int? customerPrice;
  // Legacy: the previous screen's route-collection string (e.g. 'pathology',
  // 'Radiology'). Kept to drive local list refetches; no longer sent as
  // `groupCategory` — that is now an explicit form field.
  String? collection;
  // Backend enum — one of the 6 values in `LabTestController.groupCategoryList`.
  String? groupCategory;
  String? packageType;
  // Backend-stamped provenance: `"manual"` when created via
  // `POST /pathology-tests`, `"catalog"` when created via
  // `POST /test-catalog/select`. Read-only — never sent on create/update.
  // Used by the catalog screen's tab to isolate manual entries.
  String? source;
  // Source-catalog id (present only when `source == "catalog"`). Used by
  // the catalog list to overlay this lab's price/hours/method overrides
  // onto the `TestCatalogItem` (whose `suggested*` fields are the
  // catalog defaults, not the lab's saved values). Read-only.
  String? catalogTestId;

  PathologyTest({
    this.id,
    this.testName,
    this.userId,
    this.laboratoryId,
    this.testCategory,
    this.description,
    this.testParameters,
    this.specimen,
    this.specimenCollectionMethod,
    this.estimatedReportHours,
    this.gender,
    this.beforeTestGuidance,
    this.postTestGuidance,
    this.testMethod,
    this.organSystemTested,
    this.applicableForChild,
    this.prescriptionRequired,
    this.testFees,
    this.customerPrice,
    this.collection,
    this.groupCategory,
    this.packageType,
    this.source,
    this.catalogTestId,
  });

  factory PathologyTest.fromJson(Map<String, dynamic> json) => PathologyTest(
        id: json["_id"],
        testName: json["testName"],
        userId: json["userId"],
        laboratoryId: json["laboratoryId"],
        testCategory: json["testCategory"] is Map<String, dynamic>
            ? TestCategory.fromJson(json["testCategory"])
            : json["testCategory"],
        description: json["description"],
        testParameters: json["testParameters"] != null
            ? (json["testParameters"] as List).map((x) {
                if (x is Map<String, dynamic>) {
                  return TestParameter.fromJson(x);
                }
                return x;
              }).toList()
            : null,
        specimen: json["specimen"],
        specimenCollectionMethod: json["specimenCollectionMethod"],
        estimatedReportHours: json["estimatedReportHours"],
        gender: json["gender"],
        beforeTestGuidance: json["beforeTestGuidance"],
        postTestGuidance: json["postTestGuidance"],
        testMethod: json["testMethod"],
        organSystemTested: json["organSystemTested"],
        applicableForChild: json["applicableForChild"],
        prescriptionRequired: json["prescriptionRequired"],
        testFees: json["testFees"],
        customerPrice: json["customerPrice"],
        collection: json["groupCategory"] ?? json["collection"],
        groupCategory: json["groupCategory"],
        packageType: json["packageType"],
        source: json["source"],
        catalogTestId: json["catalogTestId"]?.toString(),
      );

  Map<String, dynamic> toJson() {
    // `groupCategory` is required by the backend and must be one of the 6
    // enum values. Falls back to `collection` only for older call-sites that
    // haven't been migrated yet — those will 400 if `collection` isn't a
    // valid enum, which is the correct signal to migrate them.
    final data = <String, dynamic>{
      "testName": testName,
      "testCategory": testCategory is TestCategory ? (testCategory as TestCategory).id : testCategory,
      "description": description,
      "testParameters": testParameters?.map((x) {
        if (x is TestParameter) return x.id;
        return x;
      }).toList(),
      "specimen": specimen,
      "specimenCollectionMethod": specimenCollectionMethod,
      "estimatedReportHours": estimatedReportHours,
      "gender": gender,
      "beforeTestGuidance": beforeTestGuidance,
      "postTestGuidance": postTestGuidance,
      "testMethod": testMethod,
      "organSystemTested": organSystemTested,
      "applicableForChild": applicableForChild,
      "prescriptionRequired": prescriptionRequired,
      "testFees": testFees,
      "customerPrice": customerPrice,
      "groupCategory": groupCategory ?? collection,
      "packageType": packageType,
    };
    if (id != null) data["_id"] = id;
    if (userId != null) data["userId"] = userId;
    if (laboratoryId != null) data["laboratoryId"] = laboratoryId;
    return data;
  }
}

class TestCatalogItem {
  String? id;
  String? testName;
  String? packageType;
  String? description;
  int? estimatedReportHours;
  String? gender;
  String? groupCategory;
  String? organSystemTested;
  String? postTestGuidance;
  bool? prescriptionRequired;
  String? specimen;
  String? specimenCollectionMethod;
  int? suggestedCustomerPrice;
  int? suggestedTestFees;
  String? testCategory;
  String? testMethod;
  List<String>? testParameters;

  /// Backend flag on the catalog response — `true` when the current lab
  /// has already saved this catalog test. Drives the "Added" affordance on
  /// the catalog card (green border + badge).
  bool? alreadyAdded;

  TestCatalogItem({
    this.id,
    this.testName,
    this.packageType,
    this.description,
    this.estimatedReportHours,
    this.gender,
    this.groupCategory,
    this.organSystemTested,
    this.postTestGuidance,
    this.prescriptionRequired,
    this.specimen,
    this.specimenCollectionMethod,
    this.suggestedCustomerPrice,
    this.suggestedTestFees,
    this.testCategory,
    this.testMethod,
    this.testParameters,
    this.alreadyAdded,
  });

  factory TestCatalogItem.fromJson(Map<String, dynamic> json) => TestCatalogItem(
        id: json["_id"],
        testName: json["testName"],
        packageType: json["packageType"],
        description: json["description"],
        estimatedReportHours: json["estimatedReportHours"],
        gender: json["gender"],
        groupCategory: json["groupCategory"],
        organSystemTested: json["organSystemTested"],
        postTestGuidance: json["postTestGuidance"],
        prescriptionRequired: json["prescriptionRequired"],
        specimen: json["specimen"],
        specimenCollectionMethod: json["specimenCollectionMethod"],
        suggestedCustomerPrice: json["suggestedCustomerPrice"],
        suggestedTestFees: json["suggestedTestFees"],
        testCategory: json["testCategory"],
        testMethod: json["testMethod"],
        testParameters: json["testParameters"] != null
            ? List<String>.from(json["testParameters"].map((x) => x.toString()))
            : null,
        alreadyAdded: json["alreadyAdded"] is bool
            ? json["alreadyAdded"] as bool
            : null,
      );
}
