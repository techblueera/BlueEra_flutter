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
  List<String>? testCategories;

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
    this.testCategories,
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
        testCategories: json["testCategories"] != null
            ? List<String>.from(json["testCategories"])
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
        if (testCategories != null) "testCategories": testCategories,
      };
}
