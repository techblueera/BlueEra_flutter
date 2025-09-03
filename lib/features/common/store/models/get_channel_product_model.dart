class GetProductResponse {
  bool? success;
  List<ProductData>? data;

  GetProductResponse({this.success, this.data});

  GetProductResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <ProductData>[];
      json['data'].forEach((v) {
        data!.add(new ProductData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ProductData {
  String? sId;
  String? channelId;
  String? ownerId;
  String? name;
  String? description;
  String? price;
  String? link;
  String? image;
  bool? isPublished;
  String? createdAt;
  String? updatedAt;
  int? iV;

  ProductData(
      {this.sId,
        this.channelId,
        this.ownerId,
        this.name,
        this.description,
        this.price,
        this.link,
        this.image,
        this.isPublished,
        this.createdAt,
        this.updatedAt,
        this.iV});

  ProductData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    channelId = json['channelId'];
    ownerId = json['ownerId'];
    name = json['name'];
    description = json['description'];
    price = json['price'];
    link = json['link'];
    image = json['image'];
    isPublished = json['isPublished'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['channelId'] = this.channelId;
    data['ownerId'] = this.ownerId;
    data['name'] = this.name;
    data['description'] = this.description;
    data['price'] = this.price;
    data['link'] = this.link;
    data['image'] = this.image;
    data['isPublished'] = this.isPublished;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}