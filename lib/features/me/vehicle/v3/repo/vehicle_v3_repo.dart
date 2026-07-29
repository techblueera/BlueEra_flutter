import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_listing_draft_v3.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

/// Network layer for the rebuilt vehicle service (v3).
///
/// One repo for the whole contract — catalog reads, listing CRUD and
/// enquiries — because they are one service and the screens cross between
/// them constantly (the add flow reads three category levels, a product and
/// then writes an inventory row).
///
/// Nothing here throws on a non-2xx: every method returns the raw
/// [ResponseModel] and the controller decides. That matters more than usual
/// here because the guide documents specific status codes as *expected*
/// outcomes — 409 on a duplicate enquiry, 400 on enquiring against your own
/// listing — not failures to surface as errors.
class VehicleV3Repo extends BaseService {
  // ───── Catalog (all public) ───────────────────────────────────────

  /// Flat category read. `level` 0/1/2 with `parentId` drives the
  /// type → brand → model pickers.
  Future<ResponseModel> getCategories({
    int? level,
    String? parentId,
  }) async {
    return ApiBaseHelper().getHTTP(
      vehicleV3Categories,
      params: {
        if (level != null) 'level': level,
        if (parentId != null && parentId.isNotEmpty) 'parentId': parentId,
      },
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// Direct children by parent **key** (`4W`) — safer to hardcode against
  /// than an `_id`, per §4 of the guide.
  Future<ResponseModel> getCategoryChildrenByKey(String key) async {
    return ApiBaseHelper().getHTTP(
      vehicleV3CategoryChildrenByKey(key),
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// The whole tree in one call, for clients that would rather cache it and
  /// drive all three pickers locally.
  Future<ResponseModel> getNestedCategories({
    String? categoryId,
    String? categoryKey,
  }) async {
    return ApiBaseHelper().getHTTP(
      vehicleV3CategoriesNested,
      params: {
        if (categoryId != null && categoryId.isNotEmpty)
          'categoryId': categoryId,
        if (categoryKey != null && categoryKey.isNotEmpty)
          'categoryKey': categoryKey,
      },
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// The tree pruned to branches that actually hold live stock. Pass
  /// `userId`/`businessId` to scope it to one seller's storefront.
  Future<ResponseModel> getNestedCategoriesWithInventory({
    String? userId,
    String? businessId,
  }) async {
    return ApiBaseHelper().getHTTP(
      vehicleV3CategoriesNestedWithInventory,
      params: {
        if (userId != null && userId.isNotEmpty) 'userId': userId,
        if (businessId != null && businessId.isNotEmpty)
          'businessId': businessId,
      },
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// Type-ahead over the tree.
  Future<ResponseModel> searchCategories({
    String? key,
    String? name,
    int? level,
  }) async {
    return ApiBaseHelper().getHTTP(
      vehicleV3CategoriesSearch,
      params: {
        if (key != null && key.isNotEmpty) 'key': key,
        if (name != null && name.isNotEmpty) 'name': name,
        if (level != null) 'level': level,
      },
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// Trims under a category. `categoryId` resolves to the whole subtree, so a
  /// brand id returns every trim beneath it — not just direct children.
  Future<ResponseModel> searchTrims({
    String? categoryId,
    String? categoryKey,
    String? searchTerm,
    int page = 1,
    int limit = 20,
  }) async {
    return ApiBaseHelper().getHTTP(
      vehicleV3ProductsSearch,
      params: {
        if (categoryId != null && categoryId.isNotEmpty)
          'categoryId': categoryId,
        if (categoryKey != null && categoryKey.isNotEmpty) 'key': categoryKey,
        if (searchTerm != null && searchTerm.trim().isNotEmpty)
          'searchTerm': searchTerm.trim(),
        'page': page,
        'limit': limit,
      },
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// The **buyer** search — a different endpoint from [searchTrims], and the
  /// difference matters: this one starts from live listings and rolls them up
  /// into trim cards carrying `listingCount` and `priceFrom`, so a buyer only
  /// ever sees trims someone is actually selling near them.
  ///
  /// [location] must carry either `pincode` or `lat` + `lng` + `range`; the
  /// endpoint 400s without one, so the caller resolves it before calling.
  Future<ResponseModel> searchBuyerTrims({
    required Map<String, dynamic> location,
    String? categoryId,
    String? condition,
    String? searchTerm,
    int page = 1,
    int limit = 20,
  }) async {
    return ApiBaseHelper().getHTTP(
      vehicleV3ProductsUserSearch,
      params: {
        ...location,
        if (categoryId != null && categoryId.isNotEmpty)
          'categoryId': categoryId,
        if (condition != null && condition.isNotEmpty) 'condition': condition,
        if (searchTerm != null && searchTerm.trim().isNotEmpty)
          'searchTerm': searchTerm.trim(),
        'page': page,
        'limit': limit,
      },
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// Newest trims bucketed per root category — the add screen's "Quick
  /// Upload" rails, and the direct analogue of grocery's
  /// `products/by-root-category`.
  Future<ResponseModel> getProductsByRootCategory({int limit = 10}) async {
    return ApiBaseHelper().getHTTP(
      vehicleV3ProductsByRootCategory,
      params: {'limit': limit},
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// Trims ranked by live-listing count — the "popular near you" rail.
  Future<ResponseModel> getPopularTrims() async {
    return ApiBaseHelper().getHTTP(
      vehicleV3ProductsPopular,
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// A single trim **and its colours** — the only place colour ids come from,
  /// and therefore a mandatory step in the add flow.
  Future<ResponseModel> getTrim(String productId) async {
    return ApiBaseHelper().getHTTP(
      vehicleV3ProductById(productId),
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  // ───── Listings (owner side) ──────────────────────────────────────

  /// The signed-in seller's listings, **including inactive ones** — which is
  /// why the owner dashboard uses this and not `/inventory/browse`.
  Future<ResponseModel> getMyListings({
    int page = 1,
    int limit = 20,
    String? condition,
  }) async {
    return ApiBaseHelper().getHTTP(
      vehicleV3InventoryMine,
      params: {
        'page': page,
        'limit': limit,
        if (condition != null && condition.isNotEmpty) 'condition': condition,
      },
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  Future<ResponseModel> getMySummary() async {
    return ApiBaseHelper().getHTTP(
      vehicleV3InventorySummary,
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  Future<ResponseModel> getListing(String id) async {
    return ApiBaseHelper().getHTTP(
      vehicleV3InventoryById(id),
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// Creates the listing.
  ///
  /// Posts `multipart/form-data` whenever the draft carries local photos and
  /// plain JSON otherwise — there is no presigned-upload step in v3, the
  /// files ride along with the fields. A NEW listing normally takes the JSON
  /// path since its photos come from the catalog.
  ///
  /// `images` is repeated once per file (max 12, enforced in
  /// [VehicleListingDraftV3.validate]); `cover_image` is a single optional
  /// part, and when it is absent the server promotes the first `images` entry.
  Future<ResponseModel> createListing(
    VehicleListingDraftV3 draft, {
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final fields = draft.toFields();
    final files = await _multipartFiles(draft.imagePaths);
    final cover = await _multipartFile(draft.coverImagePath);

    if (files.isEmpty && cover == null) {
      return ApiBaseHelper().postHTTP(
        vehicleV3Inventory,
        params: fields,
        showProgress: false,
        onError: (_) {},
        onSuccess: (_) {},
      );
    }

    return ApiBaseHelper().postHTTP(
      vehicleV3Inventory,
      params: {
        ...fields,
        if (files.isNotEmpty) 'images': files,
        if (cover != null) 'cover_image': cover,
      },
      isMultipart: true,
      showProgress: false,
      onSendProgress: onSendProgress,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// Edits a listing.
  ///
  /// Two things the guide calls out and this signature carries: new files
  /// **append** rather than replace, and [imagesToRemove] deletes photos from
  /// the row and from S3 (the cover re-points itself if it was one of them).
  /// `productVariant` is create-only, so it is stripped here — re-listing a
  /// different colour is a new listing.
  Future<ResponseModel> updateListing(
    String id, {
    Map<String, dynamic> fields = const {},
    List<String> newImagePaths = const [],
    String? coverImagePath,
    List<String> imagesToRemove = const [],
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final body = Map<String, dynamic>.from(fields)..remove('productVariant');
    final files = await _multipartFiles(newImagePaths);
    final cover = await _multipartFile(coverImagePath);

    if (imagesToRemove.isNotEmpty) {
      // Accepted as a repeated field, a single URL, or a JSON array string.
      // Passing the list itself covers both transports: `FormData.fromMap`
      // expands a List into repeated fields, and the JSON path serialises it
      // as an array.
      body['imagesToRemove'] = imagesToRemove;
    }

    if (files.isEmpty && cover == null) {
      return ApiBaseHelper().putHTTP(
        vehicleV3InventoryById(id),
        params: body,
        showProgress: false,
      );
    }

    return ApiBaseHelper().putHTTP(
      vehicleV3InventoryById(id),
      params: {
        ...body,
        if (files.isNotEmpty) 'images': files,
        if (cover != null) 'cover_image': cover,
      },
      isMultipart: true,
      showProgress: false,
      onSendProgress: onSendProgress,
    );
  }

  /// Flips `is_active`. Omitting the body toggles server-side; we pass the
  /// value explicitly so an optimistic UI update can't drift out of sync with
  /// what the server decided.
  Future<ResponseModel> toggleListing(String id, {bool? isActive}) async {
    return ApiBaseHelper().patchHTTP(
      vehicleV3InventoryToggle(id),
      params: {if (isActive != null) 'is_active': isActive},
      showProgress: false,
    );
  }

  /// Soft delete.
  Future<ResponseModel> deleteListing(String id) async {
    return ApiBaseHelper().deleteHTTP(
      vehicleV3InventoryById(id),
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  // ───── Buyer side ─────────────────────────────────────────────────

  /// Live listings for a trim / colour. One of pincode or lat+lng+range is
  /// required by the search endpoints; `/browse` accepts either or neither.
  Future<ResponseModel> browseListings({
    String? productId,
    String? productVariant,
    String? condition,
    String? pincode,
    double? lat,
    double? lng,
    num? range,
    int page = 1,
    int limit = 20,
  }) async {
    return ApiBaseHelper().getHTTP(
      vehicleV3InventoryBrowse,
      params: {
        if (productId != null && productId.isNotEmpty) 'productId': productId,
        if (productVariant != null && productVariant.isNotEmpty)
          'productVariant': productVariant,
        if (condition != null && condition.isNotEmpty) 'condition': condition,
        if (pincode != null && pincode.isNotEmpty) 'pincode': pincode,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (range != null) 'range': range,
        'page': page,
        'limit': limit,
      },
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// A seller's public storefront (live listings only).
  Future<ResponseModel> getSellerListings(String userId,
      {int page = 1, int limit = 20}) async {
    return ApiBaseHelper().getHTTP(
      vehicleV3InventoryBySeller(userId),
      params: {'page': page, 'limit': limit},
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  // ───── Enquiries ──────────────────────────────────────────────────

  /// Creates an enquiry. Also opens a chat card in the chat service — no
  /// second call needed.
  Future<ResponseModel> createEnquiry({
    required String inventoryId,
    required String intent,
    num? offerPrice,
    String? note,
    List<String> photos = const [],
  }) async {
    return ApiBaseHelper().postHTTP(
      vehicleV3Bookings,
      params: {
        'inventoryId': inventoryId,
        'intent': intent,
        if (offerPrice != null) 'offerPrice': offerPrice,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        if (photos.isNotEmpty) 'photos': photos,
      },
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  Future<ResponseModel> getEnquiriesReceived({
    int page = 1,
    int limit = 20,
  }) async {
    return ApiBaseHelper().getHTTP(
      vehicleV3BookingsSellerMine,
      params: {'page': page, 'limit': limit},
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  Future<ResponseModel> getEnquiriesSent({int page = 1, int limit = 20}) async {
    return ApiBaseHelper().getHTTP(
      vehicleV3BookingsMine,
      params: {'page': page, 'limit': limit},
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// Seller decision — `accepted` or `declined`.
  Future<ResponseModel> setEnquiryStatus(String id, String status) async {
    return ApiBaseHelper().putHTTP(
      vehicleV3BookingStatus(id),
      params: {'status': status},
      showProgress: false,
    );
  }

  /// Buyer cancel — only valid while the enquiry is pending.
  Future<ResponseModel> cancelEnquiry(String id) async {
    return ApiBaseHelper().putHTTP(
      vehicleV3BookingCancel(id),
      params: const {},
      showProgress: false,
    );
  }

  // ───── Multipart helpers ──────────────────────────────────────────

  Future<List<MultipartFile>> _multipartFiles(List<String> paths) async {
    final files = <MultipartFile>[];
    for (final path in paths) {
      final file = await _multipartFile(path);
      if (file != null) files.add(file);
    }
    return files;
  }

  Future<MultipartFile?> _multipartFile(String? path) async {
    if (path == null || path.trim().isEmpty) return null;
    // Already-hosted URLs are passed through as JSON fields by the caller, not
    // re-uploaded — only local paths become files.
    if (path.startsWith('http://') || path.startsWith('https://')) return null;
    return MultipartFile.fromFile(path, filename: p.basename(path));
  }
}
