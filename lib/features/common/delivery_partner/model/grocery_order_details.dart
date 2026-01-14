class GroceryOrderDetails {
  final String id;
  final String rideOrder;
  final List<BusinessOrder> businesses;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroceryOrderDetails({
    required this.id,
    required this.rideOrder,
    required this.businesses,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroceryOrderDetails.fromJson(Map<String, dynamic> json) {
    return GroceryOrderDetails(
      id: json['_id'] ?? '',
      rideOrder: json['rideOrder'] ?? '',
      businesses: (json['businesses'] as List? ?? [])
          .map((e) => BusinessOrder.fromJson(e))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'rideOrder': rideOrder,
    'businesses': businesses.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

/* ================= BUSINESS ================= */

class BusinessOrder {
  final String businessId;
  final List<OrderItem> items;
  final bool paymentStatus;
  final String paymentMode;
  final int amountPaid;

  BusinessOrder({
    required this.businessId,
    required this.items,
    required this.paymentStatus,
    required this.paymentMode,
    required this.amountPaid,
  });

  factory BusinessOrder.fromJson(Map<String, dynamic> json) {
    return BusinessOrder(
      businessId: json['businessId'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((e) => OrderItem.fromJson(e))
          .toList(),
      paymentStatus: json['paymentStatus'] ?? false,
      paymentMode: json['paymentMode'] ?? '',
      amountPaid: json['amountPaid'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'businessId': businessId,
    'items': items.map((e) => e.toJson()).toList(),
    'paymentStatus': paymentStatus,
    'paymentMode': paymentMode,
    'amountPaid': amountPaid,
  };
}

/* ================= ITEMS ================= */

class OrderItem {
  final String variantId;
  final String inventoryId;
  final bool isPickedUp;
  final String availability;
  final InventoryDetails inventoryDetails;
  final ProductDetails productDetails;

  OrderItem({
    required this.variantId,
    required this.inventoryId,
    required this.isPickedUp,
    required this.availability,
    required this.inventoryDetails,
    required this.productDetails,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      variantId: json['variantId'] ?? '',
      inventoryId: json['inventoryId'] ?? '',
      isPickedUp: json['isPickedUp'] ?? false,
      availability: json['availability'] ?? '',
      inventoryDetails:
      InventoryDetails.fromJson(json['inventoryDetails'] ?? {}),
      productDetails:
      ProductDetails.fromJson(json['productDetails'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'variantId': variantId,
    'inventoryId': inventoryId,
    'isPickedUp': isPickedUp,
    'availability': availability,
    'inventoryDetails': inventoryDetails.toJson(),
    'productDetails': productDetails.toJson(),
  };
}

/* ================= INVENTORY ================= */

class InventoryDetails {
  final String id;
  final int totalStock;
  final List<Batch> batches;

  InventoryDetails({
    required this.id,
    required this.totalStock,
    required this.batches,
  });

  factory InventoryDetails.fromJson(Map<String, dynamic> json) {
    return InventoryDetails(
      id: json['id'] ?? '',
      totalStock: json['totalStock'] ?? 0,
      batches: (json['batches'] as List? ?? [])
          .map((e) => Batch.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'totalStock': totalStock,
    'batches': batches.map((e) => e.toJson()).toList(),
  };
}

class Batch {
  final String batchNumber;
  final int quantity;
  final int mrp;
  final int sellingPrice;

  Batch({
    required this.batchNumber,
    required this.quantity,
    required this.mrp,
    required this.sellingPrice,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      batchNumber: json['batchNumber'] ?? '',
      quantity: json['quantity'] ?? 0,
      mrp: json['mrp'] ?? 0,
      sellingPrice: json['sellingPrice'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'batchNumber': batchNumber,
    'quantity': quantity,
    'mrp': mrp,
    'sellingPrice': sellingPrice,
  };
}

/* ================= PRODUCT ================= */

class ProductDetails {
  final String id;
  final String variantName;
  final int weight;
  final Product product;

  ProductDetails({
    required this.id,
    required this.variantName,
    required this.weight,
    required this.product,
  });

  factory ProductDetails.fromJson(Map<String, dynamic> json) {
    return ProductDetails(
      id: json['id'] ?? '',
      variantName: json['variantName'] ?? '',
      weight: json['weight'] ?? 0,
      product: Product.fromJson(json['product'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'variantName': variantName,
    'weight': weight,
    'product': product.toJson(),
  };
}

class Product {
  final String id;
  final String name;
  final String description;
  final String brand;
  final bool isVegetarian;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.brand,
    required this.isVegetarian,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      brand: json['brand'] ?? '',
      isVegetarian: json['isVegetarian'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'brand': brand,
    'isVegetarian': isVegetarian,
  };
}
