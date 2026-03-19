class MissingProductRequestResponse {
  String? message;
  MissingProductRequestData? data;

  MissingProductRequestResponse({this.message, this.data});

  MissingProductRequestResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    data = json['data'] != null
        ? MissingProductRequestData.fromJson(json['data'])
        : null;
  }
}

class MissingProductBulkResponse {
  String? message;
  List<MissingProductRequestData>? data;

  MissingProductBulkResponse({this.message, this.data});

  MissingProductBulkResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if (json['data'] != null) {
      data = <MissingProductRequestData>[];
      json['data'].forEach((v) {
        data!.add(MissingProductRequestData.fromJson(v));
      });
    }
  }
}

class MissingProductRequestData {
  String? sId;
  String? name;
  String? brand;
  String? searchKeywords;
  String? unit;
  num? approxPrice;
  String? businessId;
  String? productImage;
  String? cityName;
  String? pincode;
  String? status;
  String? adminNote;
  String? createdAt;
  String? updatedAt;

  MissingProductRequestData({
    this.sId,
    this.name,
    this.brand,
    this.searchKeywords,
    this.unit,
    this.approxPrice,
    this.businessId,
    this.productImage,
    this.cityName,
    this.pincode,
    this.status,
    this.adminNote,
    this.createdAt,
    this.updatedAt,
  });

  MissingProductRequestData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    brand = json['brand'];
    searchKeywords = json['searchKeywords'];
    unit = json['unit'];
    approxPrice = json['approxPrice'];
    businessId = json['businessId'];
    productImage = json['productImage'];
    cityName = json['cityName'];
    pincode = json['pincode'];
    status = json['status'];
    adminNote = json['adminNote'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['_id'] = sId;
    data['name'] = name;
    data['brand'] = brand;
    data['searchKeywords'] = searchKeywords;
    data['unit'] = unit;
    data['approxPrice'] = approxPrice;
    data['businessId'] = businessId;
    data['productImage'] = productImage;
    data['cityName'] = cityName;
    data['pincode'] = pincode;
    data['status'] = status;
    data['adminNote'] = adminNote;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    return data;
  }
}

class MyMissingProductRequestsResponse {
  List<MissingProductRequestData>? data;
  MissingProductPagination? pagination;

  MyMissingProductRequestsResponse({this.data, this.pagination});

  MyMissingProductRequestsResponse.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <MissingProductRequestData>[];
      json['data'].forEach((v) {
        data!.add(MissingProductRequestData.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? MissingProductPagination.fromJson(json['pagination'])
        : null;
  }
}

class MissingProductPagination {
  int? total;
  int? page;
  int? limit;
  int? totalPages;

  MissingProductPagination({this.total, this.page, this.limit, this.totalPages});

  MissingProductPagination.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    page = json['page'];
    limit = json['limit'];
    totalPages = json['totalPages'];
  }
}