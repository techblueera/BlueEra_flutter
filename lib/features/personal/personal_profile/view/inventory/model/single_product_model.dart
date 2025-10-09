class SingleProductModel {
  bool? status;
  SingleProductData? data;

  SingleProductModel({this.status, this.data});

  SingleProductModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    data = json['data'] != null ? new SingleProductData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class SingleProductData {
  ExpiryTime? expiryTime;
  String? sId;
  String? name;
  String? type;
  String? symbol;
  String? description;
  String? brand;
  // Options? options;
  List<String>? media;
  String? categoryId;
  String? productWarrenty;
  bool? isReturnable;
  int? returningDay;
  bool? isPublished;
  int? mrpPerUnit;
  List<String>? guideLine;
  List<String>? tags;
  List<AddMoreDetails>? addMoreDetails;
  List<AddProductFeatures>? addProductFeatures;
  String? createdByBusiness;
  bool? addedByAdmin;
  String? approvalStatus;
  String? createdAt;
  String? updatedAt;
  int? iV;

  SingleProductData(
      {this.expiryTime,
        this.sId,
        this.name,
        this.type,
        this.symbol,
        this.description,
        this.brand,
        // this.options,
        this.media,
        this.categoryId,
        this.productWarrenty,
        this.isReturnable,
        this.returningDay,
        this.isPublished,
        this.mrpPerUnit,
        this.guideLine,
        this.tags,
        this.addMoreDetails,
        this.addProductFeatures,
        this.createdByBusiness,
        this.addedByAdmin,
        this.approvalStatus,
        this.createdAt,
        this.updatedAt,
        this.iV});

  SingleProductData.fromJson(Map<String, dynamic> json) {
    expiryTime = json['expiry_time'] != null
        ? new ExpiryTime.fromJson(json['expiry_time'])
        : null;
    sId = json['_id'];
    name = json['name'];
    type = json['type'];
    symbol = json['symbol'];
    description = json['description'];
    brand = json['brand'];
    // options =
    // json['options'] != null ? new Options.fromJson(json['options']) : null;
    media = json['media'].cast<String>();
    categoryId = json['category_id'];
    productWarrenty = json['productWarrenty'];
    isReturnable = json['is_returnable'];
    returningDay = json['returning_day'];
    isPublished = json['is_published'];
    mrpPerUnit = json['mrp_per_unit'];
    guideLine = json['guideLine'].cast<String>();
    tags = json['tags'].cast<String>();
    if (json['addMoreDetails'] != null) {
      addMoreDetails = <AddMoreDetails>[];
      json['addMoreDetails'].forEach((v) {
        addMoreDetails!.add(new AddMoreDetails.fromJson(v));
      });
    }
    if (json['addProductFeatures'] != null) {
      addProductFeatures = <AddProductFeatures>[];
      json['addProductFeatures'].forEach((v) {
        addProductFeatures!.add(new AddProductFeatures.fromJson(v));
      });
    }
    createdByBusiness = json['created_by_business'];
    addedByAdmin = json['addedByAdmin'];
    approvalStatus = json['approval_status'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.expiryTime != null) {
      data['expiry_time'] = this.expiryTime!.toJson();
    }
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['type'] = this.type;
    data['symbol'] = this.symbol;
    data['description'] = this.description;
    data['brand'] = this.brand;
    // if (this.options != null) {
    //   data['options'] = this.options!.toJson();
    // }
    data['media'] = this.media;
    data['category_id'] = this.categoryId;
    data['productWarrenty'] = this.productWarrenty;
    data['is_returnable'] = this.isReturnable;
    data['returning_day'] = this.returningDay;
    data['is_published'] = this.isPublished;
    data['mrp_per_unit'] = this.mrpPerUnit;
    data['guideLine'] = this.guideLine;
    data['tags'] = this.tags;
    if (this.addMoreDetails != null) {
      data['addMoreDetails'] =
          this.addMoreDetails!.map((v) => v.toJson()).toList();
    }
    if (this.addProductFeatures != null) {
      data['addProductFeatures'] =
          this.addProductFeatures!.map((v) => v.toJson()).toList();
    }
    data['created_by_business'] = this.createdByBusiness;
    data['addedByAdmin'] = this.addedByAdmin;
    data['approval_status'] = this.approvalStatus;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class ExpiryTime {
  Null? date;
  Null? month;
  Null? year;
  Null? week;
  bool? lifetime;

  ExpiryTime({this.date, this.month, this.year, this.week, this.lifetime});

  ExpiryTime.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    month = json['month'];
    year = json['year'];
    week = json['week'];
    lifetime = json['lifetime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['date'] = this.date;
    data['month'] = this.month;
    data['year'] = this.year;
    data['week'] = this.week;
    data['lifetime'] = this.lifetime;
    return data;
  }
}

// class Options {
//   List<Color>? color;
//   List<Pattern>? pattern;
//
//   Options({this.color, this.pattern});
//
//   Options.fromJson(Map<String, dynamic> json) {
//     if (json['color'] != null) {
//       color = <Color>[];
//       json['color'].forEach((v) {
//         color!.add(new Color.fromJson(v));
//       });
//     }
//     if (json['pattern'] != null) {
//       pattern = <Pattern>[];
//       json['pattern'].forEach((v) {
//         pattern!.add(new Pattern.fromJson(v));
//       });
//     }
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     if (this.color != null) {
//       data['color'] = this.color!.map((v) => v.toJson()).toList();
//     }
//     if (this.pattern != null) {
//       data['pattern'] = this.pattern!.map((v) => v.toJson()).toList();
//     }
//     return data;
//   }
// }
//
// class Color {
//   String? colorCode;
//   String? colorName;
//
//   Color({this.colorCode, this.colorName});
//
//   Color.fromJson(Map<String, dynamic> json) {
//     colorCode = json['color_code'];
//     colorName = json['color_name'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['color_code'] = this.colorCode;
//     data['color_name'] = this.colorName;
//     return data;
//   }
// }
//
// class Pattern {
//   String? properties;
//
//   Pattern({this.properties});
//
//   Pattern.fromJson(Map<String, dynamic> json) {
//     properties = json['properties'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['properties'] = this.properties;
//     return data;
//   }
// }

class AddMoreDetails {
  String? title;
  String? details;
  String? sId;

  AddMoreDetails({this.title, this.details, this.sId});

  AddMoreDetails.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    details = json['details'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['title'] = this.title;
    data['details'] = this.details;
    data['_id'] = this.sId;
    return data;
  }
}

class AddProductFeatures {
  String? title;
  String? sId;

  AddProductFeatures({this.title, this.sId});

  AddProductFeatures.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['title'] = this.title;
    data['_id'] = this.sId;
    return data;
  }
}