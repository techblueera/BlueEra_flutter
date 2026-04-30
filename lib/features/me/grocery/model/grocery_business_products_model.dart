import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';

class GroceryBusinessProductsModel {
  List<BusinessProductData>? data;
  GroceryBusinessProductsModel({this.data});

  GroceryBusinessProductsModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <BusinessProductData>[];
      json['data'].forEach((v) {
        data!.add(BusinessProductData.fromJson(v));
      });
    }
  }
}

class BusinessProductData {
  String? sId;
  ProductVariants? productVariant;
  String? cityName;
  List<Batches>? batches;
  Product? product;
  Category? category;
  int? totalStock;
  num? minSellingPrice;
  num? minMrp;
  num? avgDiscount;

  BusinessProductData({
    this.sId,
    this.productVariant,
    this.cityName,
    this.batches,
    this.product,
    this.category,
    this.totalStock,
    this.minSellingPrice,
    this.minMrp,
    this.avgDiscount,
  });

  BusinessProductData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    productVariant = json['productVariant'] != null
        ? ProductVariants.fromJson(json['productVariant'])
        : null;
    cityName = json['cityName'];
    if (json['batches'] != null) {
      batches = <Batches>[];
      json['batches'].forEach((v) => batches!.add(Batches.fromJson(v)));
    }
    product = json['product'] != null ? Product.fromJson(json['product']) : null;
    category = json['category'] != null ? Category.fromJson(json['category']) : null;
    totalStock = json['totalStock'];
    minSellingPrice = json['minSellingPrice'];
    minMrp = json['minMrp'];
    avgDiscount = json['avgDiscount'];

    // Backend recently stopped populating the top-level price rollups
    // (minSellingPrice / minMrp / avgDiscount come back null). Derive them
    // from productVariant.pricing so the UI doesn't render "null" — the
    // raw variant pricing is the source of truth either way.
    final pricing = productVariant?.pricing;
    if (pricing != null && pricing.isNotEmpty) {
      if (minSellingPrice == null) {
        final selling =
            pricing.map((p) => p.sellingPrice).whereType<num>().toList();
        if (selling.isNotEmpty) {
          minSellingPrice = selling.reduce((a, b) => a < b ? a : b);
        }
      }
      if (minMrp == null) {
        final mrps = pricing.map((p) => p.mrp).whereType<num>().toList();
        if (mrps.isNotEmpty) {
          minMrp = mrps.reduce((a, b) => a < b ? a : b);
        }
      }
      final mrp = minMrp;
      final sp = minSellingPrice;
      if ((avgDiscount == null || avgDiscount == 0) &&
          mrp != null && sp != null && mrp > 0) {
        final d = ((mrp - sp) / mrp) * 100;
        avgDiscount = d < 0 ? 0 : d;
      }
    }
  }
}

class Product {
  String? sId;
  String? name;
  String? description;
  String? brand;
  List<ProductImage>? images;

  Product({this.sId, this.name, this.description, this.brand, this.images});

  Product.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    description = json['description'];
    brand = json['brand'];
    if (json['images'] != null) {
      images = <ProductImage>[];
      json['images'].forEach((v) => images!.add(ProductImage.fromJson(v)));
    }
  }
}

class Batches {
  String? sId;
  num? mrp;
  num? sellingPrice;

  Batches({this.sId, this.mrp, this.sellingPrice});

  Batches.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    mrp = json['mrp'];
    sellingPrice = json['sellingPrice'];
  }
}

class ProductImage {
  String? url;
  ProductImage.fromJson(Map<String, dynamic> json) { url = json['url']; }
}

class Category {
  String? sId;
  String? name;
  Category.fromJson(Map<String, dynamic> json) { sId = json['_id']; name = json['name']; }
}