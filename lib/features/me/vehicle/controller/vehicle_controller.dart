import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/features/me/vehicle/repo/vehicle_repo.dart';
import 'package:get/get.dart';
import 'package:mime/mime.dart';

/// GetX controller for the BlueEra vehicle service.
///
/// Mirrors the pattern used by `LabFullDetailsController`,
/// `AiProfessionalsController` etc. — every async call exposes its
/// state via an [ApiResponse]-typed Rx so views can switch on
/// `LOADING / COMPLETE / ERROR` and a typed payload field carries the
/// parsed model. Keep this file dependency-light so it can be
/// `Get.put()` from any tab without dragging unrelated controllers in.
class VehicleController extends GetxController {
  final VehicleRepo _repo = VehicleRepo();

  // ─── Type taxonomy (drives the type picker) ───────────────────────
  // Populated from `GET /vehicles/types` — never hardcoded. The chosen
  // `value` is sent back as `category` on create/update.
  final RxList<VehicleType> vehicleTypes = <VehicleType>[].obs;
  final Rx<ApiResponse> vehicleTypesState = ApiResponse.initial().obs;

  // ─── Owner-side state (Me-tab) ────────────────────────────────────
  final RxList<Vehicle> myVehicles = <Vehicle>[].obs;
  final Rx<ApiResponse> myVehiclesState = ApiResponse.initial().obs;

  final RxList<VehicleContact> myContacts = <VehicleContact>[].obs;
  final RxList<VehicleFacility> myFacilities = <VehicleFacility>[].obs;
  final RxList<VehicleGalleryItem> myGallery = <VehicleGalleryItem>[].obs;
  final RxList<VehicleLivePhoto> myLivePhotos = <VehicleLivePhoto>[].obs;
  final RxList<VehicleTestimonial> receivedTestimonials =
      <VehicleTestimonial>[].obs;

  // ─── Public listing state (Discover) ──────────────────────────────
  final RxList<Vehicle> publicVehicles = <Vehicle>[].obs;
  final Rx<ApiResponse> publicVehiclesState = ApiResponse.initial().obs;
  final RxInt publicTotal = 0.obs;
  final RxInt publicPage = 1.obs;
  final RxInt publicLimit = 20.obs;
  final RxBool publicHasMore = true.obs;
  // Last-applied filters — preserved across pagination calls.
  String? _filterCategory;
  String? _filterSubCategory;
  int? _filterPincode;
  String? _filterUserId;
  String? _filterQuery;

  // ─── Single vehicle (detail screen) ───────────────────────────────
  final Rx<ApiResponse> vehicleDetailState = ApiResponse.initial().obs;
  final Rxn<Vehicle> selectedVehicle = Rxn<Vehicle>();

  // ─── Mutation flags ───────────────────────────────────────────────
  final RxBool isSavingVehicle = false.obs;
  final RxBool isUploadingMedia = false.obs;
  final RxDouble uploadProgress = 0.0.obs;

  // ────────────────────────────────────────────────────────────────
  // Vehicle types (taxonomy)
  // ────────────────────────────────────────────────────────────────

  /// Load the canonical type taxonomy for the picker. Cached — the
  /// taxonomy is server-static, so we skip the call once it's populated
  /// unless [force] is set.
  Future<void> fetchVehicleTypes({bool force = false}) async {
    if (!force && vehicleTypes.isNotEmpty) return;
    vehicleTypesState.value = ApiResponse.loading();
    try {
      final res = await _repo.listVehicleTypes();
      if (res.isSuccess) {
        final list =
            (res.response?.data?['vehicleTypes'] as List?) ?? const [];
        vehicleTypes.value = list
            .whereType<Map>()
            .map((m) => VehicleType.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        vehicleTypesState.value = ApiResponse.complete(vehicleTypes);
      } else {
        vehicleTypesState.value =
            ApiResponse.error(res.message?.toString() ?? 'Failed to load');
      }
    } catch (e) {
      vehicleTypesState.value = ApiResponse.error(e.toString());
    }
  }

  /// Resolve a category `value` (e.g. `"CAR"`) to its display label
  /// (e.g. `"Car"`) using the loaded taxonomy. Falls back to the raw
  /// value when the taxonomy isn't loaded or the value is unknown.
  String labelForCategory(String? value) {
    if (value == null || value.isEmpty) return '';
    for (final t in vehicleTypes) {
      if (t.value == value) return t.label;
    }
    return value;
  }

  // ────────────────────────────────────────────────────────────────
  // Vehicles — owner
  // ────────────────────────────────────────────────────────────────

  /// Hydrate [myVehicles] for the Me-tab. Idempotent — safe to call
  /// from `initState` of every tab without spamming the server (the
  /// repo's progress dialog is suppressed when the list is already
  /// populated and a refresh is being triggered manually).
  Future<void> fetchMyVehicles({bool showProgress = true}) async {
    myVehiclesState.value = ApiResponse.loading();
    try {
      final res = await _repo.listMyVehicles(showProgress: showProgress);
      if (res.isSuccess) {
        final list = (res.response?.data?['vehicles'] as List?) ?? const [];
        myVehicles.value = list
            .whereType<Map>()
            .map((m) => Vehicle.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        myVehiclesState.value = ApiResponse.complete(myVehicles);
      } else {
        myVehiclesState.value =
            ApiResponse.error(res.message?.toString() ?? 'Failed to load');
      }
    } catch (e) {
      myVehiclesState.value = ApiResponse.error(e.toString());
    }
  }

  /// Load a single public vehicle (called from list tap → detail).
  Future<void> fetchVehicleById(String id) async {
    vehicleDetailState.value = ApiResponse.loading();
    try {
      final res = await _repo.getVehicleById(id);
      if (res.isSuccess) {
        final raw = res.response?.data?['vehicle'];
        if (raw is Map) {
          selectedVehicle.value =
              Vehicle.fromJson(Map<String, dynamic>.from(raw));
          vehicleDetailState.value = ApiResponse.complete(selectedVehicle.value);
        } else {
          vehicleDetailState.value = ApiResponse.error('Vehicle not found');
        }
      } else {
        vehicleDetailState.value =
            ApiResponse.error(res.message?.toString() ?? 'Failed to load');
      }
    } catch (e) {
      vehicleDetailState.value = ApiResponse.error(e.toString());
    }
  }

  /// Create a new vehicle. Uploads any local-file cover/images first
  /// via the presigned PUT flow, then POSTs the JSON payload.
  Future<Vehicle?> createVehicle({
    required Vehicle draft,
    File? coverImageFile,
    List<File> imageFiles = const [],
  }) async {
    isSavingVehicle.value = true;
    try {
      String? coverUrl = draft.coverImage;
      if (coverImageFile != null) {
        coverUrl = await uploadFile(coverImageFile);
      }

      final imageUrls = <String>[...draft.images];
      for (final f in imageFiles) {
        final url = await uploadFile(f);
        if (url != null) imageUrls.add(url);
      }

      final body = Vehicle(
        name: draft.name,
        description: draft.description,
        category: draft.category,
        subCategory: draft.subCategory,
        brand: draft.brand,
        model: draft.model,
        year: draft.year,
        color: draft.color,
        registrationNo: draft.registrationNo,
        fuelType: draft.fuelType,
        transmission: draft.transmission,
        seatingCapacity: draft.seatingCapacity,
        mileage: draft.mileage,
        price: draft.price,
        currency: draft.currency,
        location: draft.location,
        coverImage: coverUrl,
        images: imageUrls,
        businessId: draft.businessId,
      ).toCreateJson();

      final res = await _repo.createVehicle(body: body);
      if (res.isSuccess) {
        final raw = res.response?.data?['vehicle'];
        if (raw is Map) {
          final created = Vehicle.fromJson(Map<String, dynamic>.from(raw));
          myVehicles.insert(0, created);
          commonSnackBar(message: 'Vehicle added');
          return created;
        }
      }
      commonSnackBar(message: res.message?.toString() ?? 'Failed to add vehicle');
      return null;
    } catch (e) {
      commonSnackBar(message: e.toString());
      return null;
    } finally {
      isSavingVehicle.value = false;
    }
  }

  /// Patch an existing vehicle. Pass only the fields you want to
  /// update; the server preserves anything you omit.
  Future<bool> updateVehicle({
    required String id,
    required Map<String, dynamic> patch,
  }) async {
    isSavingVehicle.value = true;
    try {
      final res = await _repo.updateVehicle(id: id, patch: patch);
      if (res.isSuccess) {
        final raw = res.response?.data?['vehicle'];
        if (raw is Map) {
          final updated = Vehicle.fromJson(Map<String, dynamic>.from(raw));
          final idx = myVehicles.indexWhere((v) => v.id == id);
          if (idx >= 0) {
            myVehicles[idx] = updated;
          }
          if (selectedVehicle.value?.id == id) {
            selectedVehicle.value = updated;
          }
        }
        commonSnackBar(message: 'Vehicle updated');
        return true;
      }
      commonSnackBar(
          message: res.message?.toString() ?? 'Failed to update vehicle');
      return false;
    } catch (e) {
      commonSnackBar(message: e.toString());
      return false;
    } finally {
      isSavingVehicle.value = false;
    }
  }

  Future<bool> deleteVehicle(String id) async {
    try {
      final res = await _repo.deleteVehicle(id);
      if (res.isSuccess) {
        myVehicles.removeWhere((v) => v.id == id);
        commonSnackBar(message: 'Vehicle removed');
        return true;
      }
      commonSnackBar(message: res.message?.toString() ?? 'Failed to remove');
      return false;
    } catch (e) {
      commonSnackBar(message: e.toString());
      return false;
    }
  }

  Future<bool> addVehicleImagesFromFiles({
    required String id,
    required List<File> files,
  }) async {
    try {
      final urls = <String>[];
      for (final f in files) {
        final u = await uploadFile(f);
        if (u != null) urls.add(u);
      }
      if (urls.isEmpty) return false;
      final res = await _repo.addVehicleImages(id: id, imageUrls: urls);
      if (res.isSuccess) {
        final raw = res.response?.data?['vehicle'];
        if (raw is Map) {
          final updated = Vehicle.fromJson(Map<String, dynamic>.from(raw));
          final idx = myVehicles.indexWhere((v) => v.id == id);
          if (idx >= 0) myVehicles[idx] = updated;
          if (selectedVehicle.value?.id == id) selectedVehicle.value = updated;
        }
        return true;
      }
      return false;
    } catch (e) {
      commonSnackBar(message: e.toString());
      return false;
    }
  }

  Future<bool> removeVehicleImage({
    required String id,
    required String imageUrl,
  }) async {
    try {
      final res = await _repo.removeVehicleImage(id: id, imageUrl: imageUrl);
      if (res.isSuccess) {
        final raw = res.response?.data?['vehicle'];
        if (raw is Map) {
          final updated = Vehicle.fromJson(Map<String, dynamic>.from(raw));
          final idx = myVehicles.indexWhere((v) => v.id == id);
          if (idx >= 0) myVehicles[idx] = updated;
          if (selectedVehicle.value?.id == id) selectedVehicle.value = updated;
        }
        return true;
      }
      return false;
    } catch (e) {
      commonSnackBar(message: e.toString());
      return false;
    }
  }

  // ────────────────────────────────────────────────────────────────
  // Vehicles — public listing (Discover)
  // ────────────────────────────────────────────────────────────────

  /// First-page public load. Replace results and reset pagination.
  /// Pass any combination of filters; null/empty values are dropped.
  Future<void> fetchPublicVehicles({
    String? category,
    String? subCategory,
    int? pincode,
    String? userId,
    String? q,
    int limit = 20,
  }) async {
    _filterCategory = category;
    _filterSubCategory = subCategory;
    _filterPincode = pincode;
    _filterUserId = userId;
    _filterQuery = q;
    publicPage.value = 1;
    publicLimit.value = limit;
    publicHasMore.value = true;
    publicVehicles.clear();

    publicVehiclesState.value = ApiResponse.loading();
    try {
      final res = await _repo.listVehicles(
        category: category,
        subCategory: subCategory,
        pincode: pincode,
        userId: userId,
        q: q,
        page: 1,
        limit: limit,
      );
      if (res.isSuccess) {
        final paginated = PaginatedVehicles.fromJson(
          Map<String, dynamic>.from(res.response?.data ?? const {}),
        );
        publicVehicles.assignAll(paginated.vehicles);
        publicTotal.value = paginated.total;
        publicHasMore.value = publicVehicles.length < paginated.total;
        publicVehiclesState.value = ApiResponse.complete(publicVehicles);
      } else {
        publicVehiclesState.value =
            ApiResponse.error(res.message?.toString() ?? 'Failed to load');
      }
    } catch (e) {
      publicVehiclesState.value = ApiResponse.error(e.toString());
    }
  }

  /// Append the next page using the previously-applied filters.
  Future<void> loadMorePublicVehicles() async {
    if (!publicHasMore.value) return;
    if (publicVehiclesState.value.status == Status.LOADING) return;
    final nextPage = publicPage.value + 1;
    publicVehiclesState.value = ApiResponse.loading();
    try {
      final res = await _repo.listVehicles(
        category: _filterCategory,
        subCategory: _filterSubCategory,
        pincode: _filterPincode,
        userId: _filterUserId,
        q: _filterQuery,
        page: nextPage,
        limit: publicLimit.value,
        showProgress: false,
      );
      if (res.isSuccess) {
        final paginated = PaginatedVehicles.fromJson(
          Map<String, dynamic>.from(res.response?.data ?? const {}),
        );
        publicVehicles.addAll(paginated.vehicles);
        publicPage.value = nextPage;
        publicTotal.value = paginated.total;
        publicHasMore.value = publicVehicles.length < paginated.total;
        publicVehiclesState.value = ApiResponse.complete(publicVehicles);
      } else {
        publicVehiclesState.value =
            ApiResponse.error(res.message?.toString() ?? 'Failed to load');
      }
    } catch (e) {
      publicVehiclesState.value = ApiResponse.error(e.toString());
    }
  }

  // ────────────────────────────────────────────────────────────────
  // Facilities
  // ────────────────────────────────────────────────────────────────

  Future<void> fetchMyFacilities({bool showProgress = false}) async {
    final res = await _repo.listMyFacilities(showProgress: showProgress);
    if (res.isSuccess) {
      final list = (res.response?.data?['facilities'] as List?) ?? const [];
      myFacilities.value = list
          .whereType<Map>()
          .map((m) => VehicleFacility.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
  }

  Future<bool> addFacility(VehicleFacility facility) async {
    final res = await _repo.createFacility(facility.toCreateJson());
    if (res.isSuccess) {
      await fetchMyFacilities();
      return true;
    }
    commonSnackBar(message: res.message?.toString() ?? 'Failed to add');
    return false;
  }

  Future<bool> deleteFacility(String id) async {
    final res = await _repo.deleteFacility(id);
    if (res.isSuccess) {
      myFacilities.removeWhere((f) => f.id == id);
      return true;
    }
    return false;
  }

  // ────────────────────────────────────────────────────────────────
  // Gallery
  // ────────────────────────────────────────────────────────────────

  Future<void> fetchMyGallery({String? album, bool showProgress = false}) async {
    final res = await _repo.listMyGallery(album: album, showProgress: showProgress);
    if (res.isSuccess) {
      final list = (res.response?.data?['items'] as List?) ?? const [];
      myGallery.value = list
          .whereType<Map>()
          .map((m) => VehicleGalleryItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
  }

  Future<bool> addGalleryFromFile(File file, {String? album, String? title}) async {
    final url = await uploadFile(file);
    if (url == null) return false;
    final res = await _repo.addGalleryItem(VehicleGalleryItem(
      mediaUrl: url,
      album: album,
      title: title,
    ).toCreateJson());
    if (res.isSuccess) {
      await fetchMyGallery();
      return true;
    }
    commonSnackBar(message: res.message?.toString() ?? 'Failed to upload');
    return false;
  }

  Future<bool> deleteGalleryItem(String id) async {
    final res = await _repo.deleteGalleryItem(id);
    if (res.isSuccess) {
      myGallery.removeWhere((g) => g.id == id);
      return true;
    }
    return false;
  }

  // ────────────────────────────────────────────────────────────────
  // Live photos
  // ────────────────────────────────────────────────────────────────

  Future<void> fetchMyLivePhotos({bool showProgress = false}) async {
    final res = await _repo.listMyLivePhotos(showProgress: showProgress);
    if (res.isSuccess) {
      final list = (res.response?.data?['photos'] as List?) ?? const [];
      myLivePhotos.value = list
          .whereType<Map>()
          .map((m) => VehicleLivePhoto.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
  }

  Future<bool> addLivePhotoFromFile(File file, {String? caption, double? lat, double? lon}) async {
    final url = await uploadFile(file);
    if (url == null) return false;
    final res = await _repo.addLivePhoto(VehicleLivePhoto(
      imageUrl: url,
      caption: caption,
      capturedAt: DateTime.now(),
      location: (lat != null && lon != null)
          ? VehicleLivePhotoLocation(lat: lat, lon: lon)
          : null,
    ).toCreateJson());
    if (res.isSuccess) {
      await fetchMyLivePhotos();
      return true;
    }
    commonSnackBar(message: res.message?.toString() ?? 'Failed to upload');
    return false;
  }

  Future<bool> deleteLivePhoto(String id) async {
    final res = await _repo.deleteLivePhoto(id);
    if (res.isSuccess) {
      myLivePhotos.removeWhere((p) => p.id == id);
      return true;
    }
    return false;
  }

  // ────────────────────────────────────────────────────────────────
  // Contacts
  // ────────────────────────────────────────────────────────────────

  Future<void> fetchMyContacts({bool showProgress = false}) async {
    final res = await _repo.listMyContacts(showProgress: showProgress);
    if (res.isSuccess) {
      final list = (res.response?.data?['contacts'] as List?) ?? const [];
      myContacts.value = list
          .whereType<Map>()
          .map((m) => VehicleContact.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
  }

  Future<bool> addContact(VehicleContact contact) async {
    final res = await _repo.createContact(contact.toCreateJson());
    if (res.isSuccess) {
      await fetchMyContacts();
      return true;
    }
    commonSnackBar(message: res.message?.toString() ?? 'Failed to add contact');
    return false;
  }

  Future<bool> updateContact({
    required String id,
    required Map<String, dynamic> patch,
  }) async {
    final res = await _repo.updateContact(id: id, patch: patch);
    if (res.isSuccess) {
      await fetchMyContacts();
      return true;
    }
    return false;
  }

  Future<bool> deleteContact(String id) async {
    final res = await _repo.deleteContact(id);
    if (res.isSuccess) {
      myContacts.removeWhere((c) => c.id == id);
      return true;
    }
    return false;
  }

  // ────────────────────────────────────────────────────────────────
  // Testimonials
  // ────────────────────────────────────────────────────────────────

  Future<void> fetchReceivedTestimonials() async {
    final res = await _repo.listReceivedTestimonials();
    if (res.isSuccess) {
      final list = (res.response?.data?['testimonials'] as List?) ?? const [];
      receivedTestimonials.value = list
          .whereType<Map>()
          .map((m) =>
              VehicleTestimonial.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
  }

  Future<bool> addTestimonial(VehicleTestimonial t) async {
    final res = await _repo.addVehicleTestimonial(t.toCreateJson());
    if (res.isSuccess) {
      commonSnackBar(message: 'Thanks for your testimonial');
      return true;
    }
    commonSnackBar(message: res.message?.toString() ?? 'Failed to submit');
    return false;
  }

  // ────────────────────────────────────────────────────────────────
  // Upload helper — runs both steps and returns the public URL.
  // ────────────────────────────────────────────────────────────────

  /// Uploads [file] via the presigned-PUT flow and returns the public
  /// URL to persist. Returns null + surfaces a snackbar on failure so
  /// callers can short-circuit cleanly.
  Future<String?> uploadFile(File file, {String? contentTypeOverride}) async {
    isUploadingMedia.value = true;
    uploadProgress.value = 0.0;
    try {
      final fileName = file.uri.pathSegments.last;
      final contentType = contentTypeOverride ??
          lookupMimeType(file.path) ??
          'application/octet-stream';
      final initRes =
          await _repo.initUpload(fileName: fileName, fileType: contentType);
      if (!initRes.isSuccess) {
        commonSnackBar(
            message: initRes.message?.toString() ?? 'Upload init failed');
        return null;
      }
      final init = VehicleUploadInit.fromJson(
        Map<String, dynamic>.from(initRes.response?.data ?? const {}),
      );
      if (init.uploadUrl.isEmpty || init.publicUrl.isEmpty) {
        commonSnackBar(message: 'Invalid upload URL');
        return null;
      }
      await _repo.putToS3(
        uploadUrl: init.uploadUrl,
        file: file,
        contentType: contentType,
        onProgress: (sent, total) {
          if (total > 0) uploadProgress.value = sent / total;
        },
      );
      return init.publicUrl;
    } catch (e) {
      commonSnackBar(message: 'Upload failed: $e');
      return null;
    } finally {
      isUploadingMedia.value = false;
      uploadProgress.value = 0.0;
    }
  }

  /// Convenience guard so a tab can early-return when the user isn't
  /// signed in (mirrors `isGuestUser()` checks elsewhere — duplicating
  /// that helper here would pull in unrelated imports).
  bool get isLoggedInUser => (userId).toString().isNotEmpty;
}
