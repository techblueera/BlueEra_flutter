import 'package:BlueEra/features/chat/auth/model/base_ai_chat_model.dart';

import '../../../personal/personal_profile/view/inventory/model/get_product_model.dart';

class InventoryAskAiModel extends BaseAiChatModel {
  List<String>? suggestions;
  Data? data;

  InventoryAskAiModel({
    super.conversationId,
    super.role,
    super.timestamp,
    super.message,
    this.suggestions,
    this.data,
  });

  factory InventoryAskAiModel.fromJson(Map<String, dynamic> json) {
    return InventoryAskAiModel(
      message: json['reply'] ?? json['content'],
      role: json['role'],
      conversationId: json['conversationId'],
      timestamp: json['timestamp'],
      suggestions: json['suggestions'] != null
          ? List<String>.from(json['suggestions'])
          : null,
      data: json['data'] != null ? Data.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'content': message,
    'role': role,
    'conversationId': conversationId,
    'timestamp': timestamp,
    'suggestions': suggestions,
    'data': data?.toJson(),
  };
}

class Data{
  bool? found;
  List<ProductItem>? products;

  Data({
    this.found,
    this.products,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      found: json['found'],
      products: (json['products'] as List?)
          ?.map((e) => ProductItem.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'found': found,
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