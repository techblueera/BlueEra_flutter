class AddGroceryOrderResponseModel {
  String? userId;
  List<Items>? items;
  num? totalItems;
  num? totalMRP;
  num? discount;
  num? grandTotal;
  String? deliveryType;
  String? orderStatus;
  String? id;
  String? createdAt;
  String? updatedAt;
  num? iV;

  AddGroceryOrderResponseModel(
      {this.userId,
        this.items,
        this.totalItems,
        this.totalMRP,
        this.discount,
        this.grandTotal,
        this.deliveryType,
        this.orderStatus,
        this.id,
        this.createdAt,
        this.updatedAt,
        this.iV});

  AddGroceryOrderResponseModel.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    if (json['items'] != null) {
      items = <Items>[];
      json['items'].forEach((v) {
        items!.add(Items.fromJson(v));
      });
    }
    totalItems = json['totalItems'];
    totalMRP = json['totalMRP'];
    discount = json['discount'];
    grandTotal = json['grandTotal'];
    deliveryType = json['deliveryType'];
    orderStatus = json['orderStatus'];
    id = json['_id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['_v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    data['totalItems'] = totalItems;
    data['totalMRP'] = totalMRP;
    data['discount'] = discount;
    data['grandTotal'] = grandTotal;
    data['deliveryType'] = deliveryType;
    data['orderStatus'] = orderStatus;
    data['_id'] = id;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['_v'] = iV;
    return data;
  }
}

class Items {
  String? productVariant;
  num? quantity;
  num? mrp;
  num? sellingPrice;

  Items({this.productVariant, this.quantity, this.mrp, this.sellingPrice});

  Items.fromJson(Map<String, dynamic> json) {
    productVariant = json['productVariant'];
    quantity = json['quantity'];
    mrp = json['mrp'];
    sellingPrice = json['sellingPrice'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['productVariant'] = productVariant;
    data['quantity'] = quantity;
    data['mrp'] = mrp;
    data['sellingPrice'] = sellingPrice;
    return data;
  }
}