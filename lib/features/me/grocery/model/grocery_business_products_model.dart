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

  /// Full variant list for this product. Populated when the backend enriches
  /// the business-products response (see docs/backend/GROCERY_TOP_SELLING_VARIANTS.md).
  /// Until then it's null and the UI falls back to grouping the flat rows by
  /// product and collecting their single [productVariant].
  List<ProductVariants>? variants;

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
    this.variants,
  });

  BusinessProductData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    productVariant = json['productVariant'] != null
        ? ProductVariants.fromJson(json['productVariant'])
        : null;
    if (json['variants'] != null) {
      variants = <ProductVariants>[];
      json['variants'].forEach((v) => variants!.add(ProductVariants.fromJson(v)));
    }
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

  /// Display image with the same fallback the floating cart uses: the
  /// variant's own images first, then the product-level images. Returns
  /// null when neither carries a usable URL.
  ///
  /// Single source of truth so the top-selling tile and the cart show
  /// the same photo. The tile previously read product-level images
  /// only, so variant-only products rendered the placeholder here while
  /// the cart (which falls back to the variant) showed fine.
  String? get primaryImageUrl {
    final variantImages = productVariant?.images;
    if (variantImages != null && variantImages.isNotEmpty) {
      final url = variantImages.first.url;
      if (url != null && url.isNotEmpty) return url;
    }
    final productImages = product?.images;
    if (productImages != null && productImages.isNotEmpty) {
      final url = productImages.first.url;
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  /// Product-level image only (no variant fallback). Used as the variant
  /// sheet's per-variant fallback when a variant has no image of its own.
  String? get productImageUrlOnly {
    final imgs = product?.images;
    if (imgs != null && imgs.isNotEmpty) {
      final url = imgs.first.url;
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }
}

/// One product plus all of its variants, after collapsing the (possibly
/// per-variant) flat business-products list. See
/// docs/backend/GROCERY_TOP_SELLING_VARIANTS.md.
class GroceryProductVariantGroup {
  final BusinessProductData product;
  final List<ProductVariants> variants;

  GroceryProductVariantGroup({required this.product, required this.variants});
}

/// Collapse a flat business-products list (one row per variant) into one entry
/// per product, gathering that product's variants. Prefers a backend-provided
/// full `variants[]`; otherwise collects each row's single representative
/// [BusinessProductData.productVariant]. De-dupes variants by id.
List<GroceryProductVariantGroup> groupBusinessProductsByProduct(
    List<BusinessProductData> items) {
  final order = <String>[];
  final reps = <String, BusinessProductData>{};
  final variants = <String, List<ProductVariants>>{};
  final seen = <String, Set<String>>{};

  for (final item in items) {
    final pid = item.product?.sId ?? item.sId ?? '';
    if (!reps.containsKey(pid)) {
      order.add(pid);
      reps[pid] = item;
      variants[pid] = [];
      seen[pid] = <String>{};
    }
    final fromItem = item.variants ??
        (item.productVariant != null
            ? [item.productVariant!]
            : const <ProductVariants>[]);
    for (final v in fromItem) {
      final vid = v.sId ?? '${v.variantName}-${v.quantity}-${v.unit}';
      if (seen[pid]!.add(vid)) variants[pid]!.add(v);
    }
  }

  return order
      .map((pid) =>
          GroceryProductVariantGroup(product: reps[pid]!, variants: variants[pid]!))
      .toList();
}

class Product {
  String? sId;
  String? name;
  String? description;
  String? brand;
  List<ProductImage>? images;

  /// MEDICAL-SERVICE ONLY: whether this medicine is prescription-only, which
  /// the pharmacy card marks with the red **Rx** chip.
  ///
  /// This model is shared because `medical-service/inventory/business-products`
  /// returns grocery's exact response shape — but medical's rows carry a few
  /// extra product fields on top. Grocery's response has no such key, so it
  /// parses to null there and nothing renders.
  ///
  /// `== true` rather than a cast: absent means "not prescription-only", and a
  /// hard cast would throw on every grocery row.
  bool? isPrescriptionRequired;

  /// MEDICAL-SERVICE ONLY: dosage form — "Spray", "Tablet", "Syrup". Same
  /// deal as [isPrescriptionRequired]: medical's rows carry it, grocery's
  /// don't, so it parses to null there and nothing renders.
  ///
  /// It is the first half of the pack label the pharmacy cards show
  /// (`form · variantName`), matching the customer-facing card.
  String? productForm;

  Product({
    this.sId,
    this.name,
    this.description,
    this.brand,
    this.images,
    this.isPrescriptionRequired,
    this.productForm,
  });

  Product.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    description = json['description'];
    brand = json['brand'];
    if (json['images'] != null) {
      images = <ProductImage>[];
      json['images'].forEach((v) => images!.add(ProductImage.fromJson(v)));
    }
    isPrescriptionRequired = json['is_prescription_required'] == true;
    productForm = json['product_form']?.toString();
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
  ProductImage({this.url});

  /// Tolerant of both shapes the API uses: `product.images` comes back as plain
  /// strings (`["https://..."]`) while variant images are objects
  /// (`[{ "url": "https://..." }]`). See GROCERY_TOP_SELLING_VARIANTS_INTEGRATION.md.
  factory ProductImage.fromJson(dynamic json) {
    if (json is String) return ProductImage(url: json);
    if (json is Map) return ProductImage(url: json['url']?.toString());
    return ProductImage();
  }
}

class Category {
  String? sId;
  String? name;
  String? image;
  Category.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    image = json['image'];
  }
}