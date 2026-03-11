import 'dart:convert';

class HealthCamp {
  String? id;
  int? sqFoot;
  String? title;
  String? description;
  int? price;
  int? discountPrice;
  String? startDate;
  String? endDate;
  String? startTime;
  String? laboratoryId;
  String? userId;
  String? createdAt;
  String? updatedAt;
  int? v;
  List<String>? images;
  // List<String>? testCategories;
  HealthCampLocation? location;
  List<TestDiscount>? testDiscounts;

  HealthCamp({
    this.id,
    this.sqFoot,
    this.title,
    this.description,
    this.price,
    this.discountPrice,
    this.startDate,
    this.endDate,
    this.startTime,
    this.laboratoryId,
    this.userId,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.images,
    // this.testCategories,
    this.location,
    this.testDiscounts,
  });

  factory HealthCamp.fromJson(Map<String, dynamic> json) => HealthCamp(
        id: json["_id"],
        sqFoot: json["sqFoot"],
        title: json["title"],
        description: json["description"],
        price: json["price"],
        discountPrice: json["discountPrice"],
        startDate: json["startDate"],
        endDate: json["endDate"],
        startTime: json["startTime"],
        laboratoryId: json["laboratoryId"],
        userId: json["userId"],
        createdAt: json["createdAt"],
        updatedAt: json["updatedAt"],
        v: json["__v"],
        images: json["images"] != null
            ? List<String>.from(json["images"])
            : null,
        // testCategories: json["testCategories"] != null
        //     ? List<String>.from(json["testCategories"])
        //     : null,
        location: json["location"] != null
            ? HealthCampLocation.fromJson(json["location"])
            : null,
        testDiscounts: json["testDiscounts"] != null
            ? (json["testDiscounts"] as List)
                .map((e) => TestDiscount.fromJson(e))
                .toList()
            : null,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) "_id": id,
        "sqFoot": sqFoot,
        "title": title,
        "description": description,
        "price": price,
        "discountPrice": discountPrice,
        "startDate": startDate,
        "endDate": endDate,
        "startTime": startTime,
        "laboratoryId": laboratoryId,
        if (images != null) "images": images,
        // if (testCategories != null) "testCategories": testCategories,
        if (location != null) "location": location!.toJson(),
        if (testDiscounts != null)
          "testDiscounts":
              testDiscounts!.map((e) => e.toJson()).toList(),
      };
}

class HealthCampLocation {
  String? name;
  String? type;
  List<double>? coordinates;

  HealthCampLocation({this.name, this.type, this.coordinates});

  factory HealthCampLocation.fromJson(Map<String, dynamic> json) =>
      HealthCampLocation(
        name: json["name"],
        type: json["type"],
        coordinates: json["coordinates"] != null
            ? List<double>.from(
                json["coordinates"].map((x) => (x as num).toDouble()))
            : null,
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "type": type ?? "Point",
        "coordinates": coordinates,
      };
}
//
// class TestDiscount {
//   String? test;
//   String? testName;
//   String? discountType;
//   int? discountValue;
//
//   TestDiscount({this.test, this.testName, this.discountType, this.discountValue});
//
//   factory TestDiscount.fromJson(Map<String, dynamic> json) => TestDiscount(
//         test: json["test"],
//         testName: json["testName"],
//         discountType: json["discountType"],
//         discountValue: json["discountValue"],
//       );
//
//   Map<String, dynamic> toJson() => {
//         "test": test,
//         "discountType": discountType ?? "percentage",
//         "discountValue": discountValue ?? 0,
//       };
// }



TestDiscount testDiscountsFromJson(String str) => TestDiscount.fromJson(json.decode(str));
String testDiscountsToJson(TestDiscount data) => json.encode(data.toJson());
class TestDiscount {
  TestDiscount({
    this.test,
    this.discountType,
    this.discountValue,
    this.id,});

  TestDiscount.fromJson(dynamic json) {
    if (json['test'] is Map<String, dynamic>) {
      test = Test.fromJson(json['test']);
    } else if (json['test'] is String) {
      test = Test(id: json['test']);
    }
    discountType = json['discountType'];
    discountValue = json['discountValue'];
    id = json['_id'];
  }
  Test? test;
  String? discountType;
  int? discountValue;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (test != null) {
      map['test'] = test?.id;
    }
    map['discountType'] = discountType ?? "percentage";
    map['discountValue'] = discountValue ?? 0;
    return map;
  }

}

Test testFromJson(String str) => Test.fromJson(json.decode(str));
String testToJson(Test data) => json.encode(data.toJson());
class Test {
  Test({
    this.source,
    this.catalogTestId,
    this.id,
    this.testName,
    this.laboratoryId,
    this.v,
    this.applicableForChild,
    this.beforeTestGuidance,
    this.createdAt,
    this.customerPrice,
    this.description,
    this.estimatedReportHours,
    this.gender,
    this.groupCategory,
    this.organSystemTested,
    this.packageType,
    this.postTestGuidance,
    this.prescriptionRequired,
    this.specimen,
    this.specimenCollectionMethod,
    this.testCategory,
    this.testFees,
    this.testMethod,
    this.testParameters,
    this.updatedAt,
    this.userId,});

  Test.fromJson(dynamic json) {
    source = json['source'];
    catalogTestId = json['catalogTestId'];
    id = json['_id'];
    testName = json['testName'];
    laboratoryId = json['laboratoryId'];
    v = json['__v'];
    applicableForChild = json['applicableForChild'];
    beforeTestGuidance = json['beforeTestGuidance'];
    createdAt = json['createdAt'];
    customerPrice = json['customerPrice'];
    description = json['description'];
    estimatedReportHours = json['estimatedReportHours'];
    gender = json['gender'];
    groupCategory = json['groupCategory'];
    organSystemTested = json['organSystemTested'];
    packageType = json['packageType'];
    postTestGuidance = json['postTestGuidance'];
    prescriptionRequired = json['prescriptionRequired'];
    specimen = json['specimen'];
    specimenCollectionMethod = json['specimenCollectionMethod'];
    testCategory = json['testCategory'];
    testFees = json['testFees'];
    testMethod = json['testMethod'];
    testParameters = json['testParameters'] != null ? json['testParameters'].cast<String>() : [];
    updatedAt = json['updatedAt'];
    userId = json['userId'];
  }
  String? source;
  dynamic catalogTestId;
  String? id;
  String? testName;
  String? laboratoryId;
  int? v;
  bool? applicableForChild;
  String? beforeTestGuidance;
  String? createdAt;
  int? customerPrice;
  String? description;
  int? estimatedReportHours;
  String? gender;
  String? groupCategory;
  String? organSystemTested;
  String? packageType;
  String? postTestGuidance;
  bool? prescriptionRequired;
  String? specimen;
  String? specimenCollectionMethod;
  String? testCategory;
  int? testFees;
  String? testMethod;
  List<String>? testParameters;
  String? updatedAt;
  String? userId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['source'] = source;
    map['catalogTestId'] = catalogTestId;
    map['_id'] = id;
    map['testName'] = testName;
    map['laboratoryId'] = laboratoryId;
    map['__v'] = v;
    map['applicableForChild'] = applicableForChild;
    map['beforeTestGuidance'] = beforeTestGuidance;
    map['createdAt'] = createdAt;
    map['customerPrice'] = customerPrice;
    map['description'] = description;
    map['estimatedReportHours'] = estimatedReportHours;
    map['gender'] = gender;
    map['groupCategory'] = groupCategory;
    map['organSystemTested'] = organSystemTested;
    map['packageType'] = packageType;
    map['postTestGuidance'] = postTestGuidance;
    map['prescriptionRequired'] = prescriptionRequired;
    map['specimen'] = specimen;
    map['specimenCollectionMethod'] = specimenCollectionMethod;
    map['testCategory'] = testCategory;
    map['testFees'] = testFees;
    map['testMethod'] = testMethod;
    map['testParameters'] = testParameters;
    map['updatedAt'] = updatedAt;
    map['userId'] = userId;
    return map;
  }

}