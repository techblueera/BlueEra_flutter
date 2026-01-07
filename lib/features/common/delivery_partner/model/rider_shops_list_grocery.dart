class RiderShopsListGrocery {
  final List<BusinessListModel> businesses;

  RiderShopsListGrocery({required this.businesses});

  factory RiderShopsListGrocery.fromJson(List<dynamic> json) {
    return RiderShopsListGrocery(
      businesses: json.map((e) => BusinessListModel.fromJson(e)).toList(),
    );
  }
}

// --------------------------------------------------

class BusinessListModel {
  final String businessId;
  final String name;
  final String profilePicture;
  final int noOfItemsAvailable;
  final double totalPriceForAvailableItems;
  final double distance;
  final List<AvailableProduct> availableProducts;

  BusinessListModel({
    required this.businessId,
    required this.name,
    required this.profilePicture,
    required this.noOfItemsAvailable,
    required this.totalPriceForAvailableItems,
    required this.distance,
    required this.availableProducts,
  });

  factory BusinessListModel.fromJson(Map<String, dynamic> json) {
    return BusinessListModel(
      businessId: json['businessId'] ?? '',
      name: json['name'] ?? '',
      profilePicture: json['profilePicture'] ?? '',
      noOfItemsAvailable: json['noOfItemsAvailable'] ?? 0,
      totalPriceForAvailableItems:
      (json['totalPriceForAvailableItems'] as num?)?.toDouble() ?? 0.0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      availableProducts: (json['availableProducts'] as List? ?? [])
          .map((e) => AvailableProduct.fromJson(e))
          .toList(),
    );
  }
}

// --------------------------------------------------

class AvailableProduct {
  final Variant variant;
  final Inventory inventory;

  AvailableProduct({
    required this.variant,
    required this.inventory,
  });

  factory AvailableProduct.fromJson(Map<String, dynamic> json) {
    return AvailableProduct(
      variant: Variant.fromJson(json['variant'] ?? {}),
      inventory: Inventory.fromJson(json['inventory'] ?? {}),
    );
  }
}

// --------------------------------------------------

class Variant {
  final String id;
  final String product;
  final String variantName;
  final String unit;
  final int weight;
  final List<Pricing> pricing;

  Variant({
    required this.id,
    required this.product,
    required this.variantName,
    required this.unit,
    required this.weight,
    required this.pricing,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: json['_id'] ?? '',
      product: json['product'] ?? '',
      variantName: json['variantName'] ?? '',
      unit: json['unit'] ?? '',
      weight: json['weight'] ?? 0,
      pricing: (json['pricing'] as List? ?? [])
          .map((e) => Pricing.fromJson(e))
          .toList(),
    );
  }
}

// --------------------------------------------------

class Pricing {
  final String pincode;
  final String cityName;
  final int mrp;
  final int sellingPrice;
  final String currency;

  Pricing({
    required this.pincode,
    required this.cityName,
    required this.mrp,
    required this.sellingPrice,
    required this.currency,
  });

  factory Pricing.fromJson(Map<String, dynamic> json) {
    return Pricing(
      pincode: json['pincode'] ?? '',
      cityName: json['cityName'] ?? '',
      mrp: json['mrp'] ?? 0,
      sellingPrice: json['sellingPrice'] ?? 0,
      currency: json['currency'] ?? '',
    );
  }
}

// --------------------------------------------------

class Inventory {
  final String id;
  final String businessId;
  final String pincode;
  final String cityName;
  final int reorderPoint;
  final List<Batch> batches;

  Inventory({
    required this.id,
    required this.businessId,
    required this.pincode,
    required this.cityName,
    required this.reorderPoint,
    required this.batches,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      id: json['_id'] ?? '',
      businessId: json['businessId'] ?? '',
      pincode: json['pincode'] ?? '',
      cityName: json['cityName'] ?? '',
      reorderPoint: json['reorderPoint'] ?? 0,
      batches: (json['batches'] as List? ?? [])
          .map((e) => Batch.fromJson(e))
          .toList(),
    );
  }
}

// --------------------------------------------------

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
}
