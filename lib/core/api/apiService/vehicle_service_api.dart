/// All `vehicle-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
///
/// The service was rebuilt around the same four-tier shape as grocery
/// (Category → Product → ProductVariant → Inventory) and the `/vehicles`
/// prefix is **gone** — every path that carried it (`/vehicles/types`,
/// `/vehicles/catalog/*`, `/vehicles/create`, `/facilities/*`, `/gallery/*`,
/// `/testimonials/*`, `/contact-us/*`, `/upload/init*`) now answers 404, and
/// those constants were removed along with the screens that called them.
///
/// Contract: `docs/backend/FRONTEND_INTEGRATION_GUIDE.md`.
mixin VehicleServiceApi {

  /// Flat category reads. `?level=0|1|2` + `?parentId=` drive the three
  /// pickers (type → brand → model). `level` is derived server-side — never
  /// send it on a write.
  final String vehicleV3Categories = 'vehicle-service/categories';
  final String vehicleV3CategoriesNested = 'vehicle-service/categories/nested';
  final String vehicleV3CategoriesNestedWithInventory =
      'vehicle-service/categories/nested/with-inventory';
  final String vehicleV3CategoriesSearch = 'vehicle-service/categories/search';
  String vehicleV3CategoryById(String id) => 'vehicle-service/categories/$id';
  String vehicleV3CategoryChildren(String id) =>
      'vehicle-service/categories/$id/children';

  /// Children by parent **key** (`4W`, `BRAND_MARUTI_SUZUKI`). `key` is
  /// globally unique and stable, so it is the safer thing to hardcode against.
  String vehicleV3CategoryChildrenByKey(String key) =>
      'vehicle-service/categories/key/$key/children';
  String vehicleV3CategoryChildrenByKeyWithInventory(String key) =>
      'vehicle-service/categories/key/$key/children/with-inventory';

  /// Trims. `categoryId` resolves to the whole subtree, so a brand — or even
  /// a root key — returns everything beneath it.
  final String vehicleV3ProductsSearch = 'vehicle-service/products/search';
  final String vehicleV3ProductsUserSearch =
      'vehicle-service/products/user/search';
  final String vehicleV3ProductsPopular = 'vehicle-service/products/popular';
  final String vehicleV3ProductsByRootCategory =
      'vehicle-service/products/by-root-category';
  final String vehicleV3ProductsSimilar = 'vehicle-service/products/similar';

  /// Single trim **and its colours** — the colour `_id` is what a listing is
  /// created against, and this is the only endpoint that returns them.
  String vehicleV3ProductById(String productId) =>
      'vehicle-service/products/$productId';

  /// Listings. `POST`/`PUT` take JSON *or* multipart — there is no separate
  /// upload step and no presigned URL any more.
  final String vehicleV3Inventory = 'vehicle-service/inventory';
  final String vehicleV3InventoryMine = 'vehicle-service/inventory/my';
  final String vehicleV3InventorySummary = 'vehicle-service/inventory/summary';
  final String vehicleV3InventoryBrowse = 'vehicle-service/inventory/browse';
  String vehicleV3InventoryById(String id) => 'vehicle-service/inventory/$id';
  String vehicleV3InventoryToggle(String id) =>
      'vehicle-service/inventory/$id/toggle';
  String vehicleV3InventoryBySeller(String userId) =>
      'vehicle-service/inventory/seller/$userId';

  /// Enquiries. Named `booking` by the contract; there is no payment and no
  /// stock decrement. Creating one opens a chat card automatically.
  final String vehicleV3Bookings = 'vehicle-service/bookings';
  final String vehicleV3BookingsMine = 'vehicle-service/bookings/me';
  final String vehicleV3BookingsSellerMine =
      'vehicle-service/bookings/seller/me';
  String vehicleV3BookingById(String id) => 'vehicle-service/bookings/$id';
  String vehicleV3BookingStatus(String id) =>
      'vehicle-service/bookings/$id/status';
  String vehicleV3BookingCancel(String id) =>
      'vehicle-service/bookings/$id/cancel';
}
