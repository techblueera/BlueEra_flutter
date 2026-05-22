import 'medical_product_model.dart';

class SnapSearchResultModel {
  bool? success;
  String? message;
  SnapSearchData? data;

  SnapSearchResultModel({this.success, this.message, this.data});

  SnapSearchResultModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? SnapSearchData.fromJson(json['data']) : null;
  }
}

class SnapSearchData {
  int? totalDetected;
  int? foundCount;
  int? missingCount;
  List<FoundProduct>? foundProducts;
  List<MissingProduct>? missingProducts;

  SnapSearchData({
    this.totalDetected,
    this.foundCount,
    this.missingCount,
    this.foundProducts,
    this.missingProducts,
  });

  SnapSearchData.fromJson(Map<String, dynamic> json) {
    totalDetected = json['totalDetected'];
    foundCount = json['foundCount'];
    missingCount = json['missingCount'];
    if (json['foundProducts'] != null) {
      foundProducts = <FoundProduct>[];
      json['foundProducts'].forEach((v) {
        foundProducts!.add(FoundProduct.fromJson(v));
      });
    }
    if (json['missingProducts'] != null) {
      missingProducts = <MissingProduct>[];
      json['missingProducts'].forEach((v) {
        missingProducts!.add(MissingProduct.fromJson(v));
      });
    }
  }
}

class FoundProduct {
  String? aiIdentifiedAs;
  MedicalProductData? productDetails;

  FoundProduct({this.aiIdentifiedAs, this.productDetails});

  FoundProduct.fromJson(Map<String, dynamic> json) {
    aiIdentifiedAs = json['aiIdentifiedAs'];
    productDetails = json['productDetails'] != null
        ? MedicalProductData.fromJson(json['productDetails'])
        : null;
  }
}

class MissingProduct {
  String? name;
  String? genericName;
  String? brand;
  String? searchKeywords;
  String? unit;
  num? approxPrice;
  String? productForm;
  String? strength;
  bool? isPrescriptionRequired;

  MissingProduct({
    this.name,
    this.genericName,
    this.brand,
    this.searchKeywords,
    this.unit,
    this.approxPrice,
    this.productForm,
    this.strength,
    this.isPrescriptionRequired,
  });

  MissingProduct.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    genericName = json['generic_name'];
    brand = json['brand'];
    searchKeywords = json['searchKeywords'];
    unit = json['unit'];
    approxPrice = json['approxPrice'];
    productForm = json['product_form'];
    strength = json['strength'];
    isPrescriptionRequired = json['is_prescription_required'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['name'] = name;
    data['generic_name'] = genericName;
    data['brand'] = brand;
    data['searchKeywords'] = searchKeywords;
    data['unit'] = unit;
    data['approxPrice'] = approxPrice;
    data['product_form'] = productForm;
    data['strength'] = strength;
    data['is_prescription_required'] = isPrescriptionRequired;
    return data;
  }
}