import '../../../personal/personal_profile/view/inventory/model/get_product_model.dart';

class InventoryAskAiModel {
  String? reply;
  String? role;
  String? conversationId;
  String? timestamp;
  List<String>? suggestions;
  List<ProductItem>? products;

  InventoryAskAiModel({this.reply, this.role,this.timestamp, this.conversationId, this.suggestions, this.products,});

  factory InventoryAskAiModel.fromJson(Map<String, dynamic> json) {
    return InventoryAskAiModel(
      reply: json['reply'],
      role: json['role'],
      conversationId: json['conversationId'],
      timestamp: json['timestamp'],
      suggestions: json['suggestions'] != null
          ? List<String>.from(json['suggestions'])
          : null,
      products: (json['products'] as List?)
          ?.map((e) => ProductItem.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'reply': reply,
    "role": role,
    'conversationId': conversationId,
    'timestamp': timestamp,
    'suggestions': suggestions,
    'products': products?.map((e) => e.toJson()).toList(),
  };
}

class InventoryAskHistoryAiModel {
  String? content;
  String? role;
  String? conversationId;
  String? timestamp;
  List<String>? suggestions;
  List<ProductItem>? products;

  InventoryAskHistoryAiModel({this.content, this.role,this.timestamp, this.conversationId, this.suggestions, this.products,});

  factory InventoryAskHistoryAiModel.fromJson(Map<String, dynamic> json) {
    return InventoryAskHistoryAiModel(
      content: json['content'],
      role: json['role'],
      conversationId: json['conversationId'],
      timestamp: json['timestamp'],
      suggestions: json['suggestions'] != null
          ? List<String>.from(json['suggestions'])
          : null,
      products: (json['products'] as List?)
          ?.map((e) => ProductItem.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'content': content,
    "role": role,
    'conversationId': conversationId,
    'timestamp': timestamp,
    'suggestions': suggestions,
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