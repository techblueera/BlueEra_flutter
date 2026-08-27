import 'package:BlueEra/core/api/apiService/response_model.dart';

/// The store to credit on a shared product — name, logo, and the id that
/// opens it.
///
/// ## Why this exists
///
/// `GET product-service/api/products/{id}` returns the **master product**
/// record: name, media, variants, features. It carries no seller, because the
/// same record is what every store listing that product points at. So a link
/// built from a product id names a T-shirt, not a shop — which is why the
/// share landing had a product with nothing behind it.
///
/// This is assembled from whichever of two very different responses answered:
///
/// - [ProductSeller.fromBusinessProfile] — `GET user-service/business/{userId}`,
///   reached when the link carried `?seller=`. Keyed by USER id, which is the
///   id the visit-store and visit-profile screens take, so the card can route
///   without translating anything.
/// - [ProductSeller.fromFullBusinessProfile] —
///   `GET product-service/api/business-profile/{businessId}/full`, the
///   fallback for a link with no seller. Keyed by the product-service BUSINESS
///   id (`created_by_business`), and its `profile.userId` is what gets us back
///   to a routable id.
///
/// Both are parsed defensively off the raw map rather than through a typed
/// model: this decorates a screen, and a shape change backend-side should cost
/// the card, never the product.
class ProductSeller {
  /// The id every seller-facing screen routes on. **Never empty** on a
  /// constructed instance — a seller with no route is not worth a card, so
  /// the factories return null instead.
  final String userId;

  final String name;
  final String logoUrl;

  /// The shop's category line ("Clothing & Apparel"), when the response had
  /// one. Display only.
  final String category;

  /// Whether this is a business account, which decides where the card goes:
  /// a business opens its product store, an individual opens their profile.
  ///
  /// Defaults true — every path that produces a [ProductSeller] starts from a
  /// business profile lookup, and a business landing on its store is the
  /// expected destination for a product share.
  final bool isBusiness;

  const ProductSeller({
    required this.userId,
    this.name = '',
    this.logoUrl = '',
    this.category = '',
    this.isBusiness = true,
  });

  /// The `data` object of a 2xx envelope, or null. Mirrors the defensive
  /// reading used elsewhere: `badResponse` is RETURNED rather than thrown, so
  /// every caller checks rather than catches.
  static Map<String, dynamic>? _dataOf(dynamic res) {
    if (res is! ResponseModel) return null;
    if (res.isSuccess != true) return null;
    final body = res.response?.data;
    if (body is! Map) return null;
    final data = body['data'];
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  static String _str(dynamic v) => v?.toString().trim() ?? '';

  /// `GET user-service/business/{userId}` — the profile behind a `?seller=` id.
  ///
  /// [fallbackUserId] is the id we asked with: the response is allowed to omit
  /// `user_id`, and the id we already hold is just as routable, so a thin
  /// response still produces a working card rather than none.
  static ProductSeller? fromBusinessProfile(
    dynamic res, {
    String? fallbackUserId,
  }) {
    final data = _dataOf(res);
    final id = _str(data?['user_id']).isNotEmpty
        ? _str(data!['user_id'])
        : _str(fallbackUserId);
    if (id.isEmpty) return null;
    return ProductSeller(
      userId: id,
      name: _str(data?['business_name']),
      logoUrl: _str(data?['logo']),
      category: _str(data?['category']),
    );
  }

  /// `GET product-service/api/business-profile/{businessId}/full` — the
  /// creating business, used when the link carried no seller.
  ///
  /// Everything lives under `data.profile` here, and `profile.userId` is the
  /// only field that makes the card routable: without it there is a shop name
  /// and nowhere to go, so this returns null rather than a dead card.
  static ProductSeller? fromFullBusinessProfile(dynamic res) {
    final data = _dataOf(res);
    final profile = data?['profile'];
    if (profile is! Map) return null;
    final p = Map<String, dynamic>.from(profile);
    final id = _str(p['userId']);
    if (id.isEmpty) return null;
    return ProductSeller(
      userId: id,
      name: _str(p['profileName']),
      logoUrl: _str(p['logoUrl']),
      category: _str(p['category'] ?? p['categoryName']),
    );
  }

  /// Whether there is anything to say beyond the route. A card with only an id
  /// still earns its place — it opens the shop — but it words itself
  /// differently, so the screen needs to be able to tell.
  bool get hasProfile => name.isNotEmpty || logoUrl.isNotEmpty;
}
