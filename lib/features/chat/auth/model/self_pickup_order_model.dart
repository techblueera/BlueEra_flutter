class SelfPickupOrderModel {
  String? orderId;
  String? businessId;
  List<SelfPickupItem>? items;
  int? totalItems;
  num? grandTotal;
  String? deliveryType;
  bool? isReady;

  SelfPickupOrderModel({
    this.orderId,
    this.businessId,
    this.items,
    this.totalItems,
    this.grandTotal,
    this.deliveryType,
    this.isReady,
  });

  factory SelfPickupOrderModel.fromJson(Map<String, dynamic> json) {
    return SelfPickupOrderModel(
      orderId: json['orderId']?.toString(),
      businessId: json['businessId']?.toString(),
      items: json['items'] != null
          ? (json['items'] as List)
              .map((e) => SelfPickupItem.fromJson(e))
              .toList()
          : null,
      totalItems: json['totalItems'] is int
          ? json['totalItems']
          : int.tryParse(json['totalItems']?.toString() ?? '0'),
      grandTotal: json['grandTotal'],
      deliveryType: json['deliveryType']?.toString(),
      isReady: json['isReady'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'businessId': businessId,
      'items': items?.map((e) => e.toJson()).toList(),
      'totalItems': totalItems,
      'grandTotal': grandTotal,
      'deliveryType': deliveryType,
      'isReady': isReady,
    };
  }
}

class SelfPickupItem {
  String? inventoryId;
  String? productVariantId;
  String? productId;
  String? variantId;
  String? productName;
  String? variantName;
  String? quantityLabel;
  String? unit;
  List<SelfPickupItemImage>? images;
  int? quantity;
  num? mrp;
  num? sellingPrice;

  SelfPickupItem({
    this.inventoryId,
    this.productVariantId,
    this.productId,
    this.variantId,
    this.productName,
    this.variantName,
    this.quantityLabel,
    this.unit,
    this.images,
    this.quantity,
    this.mrp,
    this.sellingPrice,
  });

  factory SelfPickupItem.fromJson(Map<String, dynamic> json) {
    return SelfPickupItem(
      inventoryId: json['inventoryId']?.toString(),
      productVariantId: json['productVariantId']?.toString(),
      // Home-made-food items carry `homeMadeFoodId`, tiffin items `tiffinId`,
      // instead of `productId`.
      productId: (json['productId'] ??
              json['homeMadeFoodId'] ??
              json['tiffinId'])
          ?.toString(),
      variantId: json['variantId']?.toString(),
      // Home-made-food items carry `foodName`, tiffin items `tiffinName`,
      // instead of `productName`.
      productName: (json['productName'] ??
              json['foodName'] ??
              json['tiffinName'])
          ?.toString(),
      variantName: json['variantName']?.toString(),
      quantityLabel: json['quantityLabel']?.toString(),
      unit: json['unit']?.toString(),
      images: json['images'] != null
          ? (json['images'] as List).map((e) {
              if (e is String) {
                return SelfPickupItemImage(url: e);
              }
              return SelfPickupItemImage.fromJson(e);
            }).toList()
          : null,
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse(json['quantity']?.toString() ?? '0'),
      mrp: json['mrp'],
      sellingPrice: json['sellingPrice'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inventoryId': inventoryId,
      'productVariantId': productVariantId,
      'productId': productId,
      'variantId': variantId,
      'productName': productName,
      'variantName': variantName,
      'quantityLabel': quantityLabel,
      'unit': unit,
      'images': images?.map((e) => e.toJson()).toList(),
      'quantity': quantity,
      'mrp': mrp,
      'sellingPrice': sellingPrice,
    };
  }
}

class SelfPickupItemImage {
  String? url;
  String? id;

  SelfPickupItemImage({this.url, this.id});

  factory SelfPickupItemImage.fromJson(Map<String, dynamic> json) {
    return SelfPickupItemImage(
      url: json['url']?.toString(),
      id: json['_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      '_id': id,
    };
  }
}
