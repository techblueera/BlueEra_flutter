
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
  String? testMethod;
  bool? applicableForChild;
  bool? prescriptionRequired;
  int? testFees;
  int? customerPrice;
  String? collection;

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
    this.testMethod,
    this.applicableForChild,
    this.prescriptionRequired,
    this.testFees,
    this.customerPrice,
    this.collection,
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
        testMethod: json["testMethod"],
        applicableForChild: json["applicableForChild"],
        prescriptionRequired: json["prescriptionRequired"],
        testFees: json["testFees"],
        customerPrice: json["customerPrice"],
        collection: json["collection"],
      );

  Map<String, dynamic> toJson() {
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
      "testMethod": testMethod,
      "applicableForChild": applicableForChild,
      "prescriptionRequired": prescriptionRequired,
      "testFees": testFees,
      "customerPrice": customerPrice,
      "collection": collection,
    };
    if (id != null) data["_id"] = id;
    if (userId != null) data["userId"] = userId;
    if (laboratoryId != null) data["laboratoryId"] = laboratoryId;
    return data;
  }
}
