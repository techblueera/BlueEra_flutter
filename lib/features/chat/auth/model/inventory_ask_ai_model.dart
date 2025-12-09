import '../../../personal/personal_profile/view/inventory/model/get_product_model.dart';

class InventoryAskAiModel {
  String? reply;
  String? messageStatus;
  String? message;
  List<ProductItem>? products;

  InventoryAskAiModel({this.reply, this.products,this.message,this.messageStatus});

  factory InventoryAskAiModel.fromJson(Map<String, dynamic> json) {
    return InventoryAskAiModel(
      reply: json['reply'],
      message: json['message'],
      messageStatus: json['messageStatus'],
      products: (json['products'] as List?)
          ?.map((e) => ProductItem.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'reply': reply,
    "message":message,
    'messageStatus':messageStatus,
    'products': products?.map((e) => e.toJson()).toList(),
  };
}

// -----------------------------------------------------------------------------
// PRODUCT ITEM
// -----------------------------------------------------------------------------
class ProductItem {
  ProductStore? product;

  ProductItem({this.product});

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      product:
      json['product'] != null ? ProductStore.fromJson(json['product']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'product': product?.toJson(),
  };
}

// -----------------------------------------------------------------------------
// PRODUCT DATA
// -----------------------------------------------------------------------------
//--------------------------------------------------------------------------