import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:dio/dio.dart';

/// Repository for the BlueEra vehicle service
/// (`vehicle-service/...` endpoints).
///
/// Mirrors `lib/docs/FLUTTER_INTEGRATION_GUIDE.md` § 4 — every method
/// maps 1-to-1 to a documented REST endpoint and returns the project's
/// shared [ResponseModel] so controllers can switch on
/// `isSuccess` / read `response?.data` exactly the way the rest of the
/// codebase does.
class VehicleRepo extends BaseService {
  // ─── Vehicles ────────────────────────────────────────────────────

  /// GET /vehicles/types — public, no auth. Canonical type taxonomy
  /// used to populate the type picker (step 1 of the upload flow).
  Future<ResponseModel> listVehicleTypes({bool showProgress = false}) async {
    return ApiBaseHelper().getHTTP(
      vehicleTypes,
      showProgress: showProgress,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// GET /vehicles/conditions — public. NEW / USED picker options.
  Future<ResponseModel> listConditions({bool showProgress = false}) async {
    return ApiBaseHelper().getHTTP(
      vehicleConditions,
      showProgress: showProgress,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// GET /vehicles/options — public. Every non-taxonomy picker in one
  /// call (availability, delivery_time, special_offers, ownership,
  /// condition_grade).
  Future<ResponseModel> listOptions({bool showProgress = false}) async {
    return ApiBaseHelper().getHTTP(
      vehicleOptions,
      showProgress: showProgress,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// GET /vehicles/seller-defaults — auth. Pre-fills seller_name /
  /// seller_mobile from the caller's own profile.
  Future<ResponseModel> getSellerDefaults({bool showProgress = false}) async {
    return ApiBaseHelper().getHTTP(
      vehicleSellerDefaults,
      showProgress: showProgress,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// GET /vehicles  — public, paginated, filterable.
  Future<ResponseModel> listVehicles({
    String? category,
    String? subCategory,
    int? pincode,
    String? userId,
    String? q,
    int page = 1,
    int limit = 20,
    bool showProgress = true,
  }) async {
    final query = <String, dynamic>{
      if (category != null && category.isNotEmpty) 'category': category,
      if (subCategory != null && subCategory.isNotEmpty)
        'sub_category': subCategory,
      if (pincode != null) 'pincode': pincode,
      if (userId != null && userId.isNotEmpty) 'user_id': userId,
      if (q != null && q.isNotEmpty) 'q': q,
      'page': page,
      'limit': limit,
    };
    return ApiBaseHelper().getHTTP(
      vehiclesList,
      params: query,
      showProgress: showProgress,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// GET /vehicles/get/:id — public, owner+business hydrated.
  Future<ResponseModel> getVehicleById(String id,
      {bool showProgress = true}) async {
    return ApiBaseHelper().getHTTP(
      vehicleById(id),
      showProgress: showProgress,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// POST /vehicles/create — auth required.
  Future<ResponseModel> createVehicle({
    required Map<String, dynamic> body,
    bool showProgress = true,
  }) async {
    return ApiBaseHelper().postHTTP(
      vehiclesCreate,
      params: body,
      showProgress: showProgress,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// GET /vehicles/me/list — auth required, vehicles owned by caller.
  Future<ResponseModel> listMyVehicles({bool showProgress = true}) async {
    return ApiBaseHelper().getHTTP(
      vehiclesMineList,
      showProgress: showProgress,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// PUT /vehicles/update/:id — auth required, must be owner.
  Future<ResponseModel> updateVehicle({
    required String id,
    required Map<String, dynamic> patch,
    bool showProgress = true,
  }) async {
    return ApiBaseHelper().putHTTP(
      vehiclesUpdate(id),
      params: patch,
      showProgress: showProgress,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// DELETE /vehicles/delete/:id — auth required, must be owner.
  Future<ResponseModel> deleteVehicle(String id,
      {bool showProgress = true}) async {
    return ApiBaseHelper().deleteHTTP(
      vehiclesDelete(id),
      showProgress: showProgress,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// POST /vehicles/:id/images — append URLs (already uploaded to S3).
  Future<ResponseModel> addVehicleImages({
    required String id,
    required List<String> imageUrls,
    bool showProgress = true,
  }) async {
    return ApiBaseHelper().postHTTP(
      vehiclesImagesAdd(id),
      params: {'images': imageUrls},
      showProgress: showProgress,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// DELETE /vehicles/:id/images — remove a single URL from the array.
  Future<ResponseModel> removeVehicleImage({
    required String id,
    required String imageUrl,
    bool showProgress = true,
  }) async {
    return ApiBaseHelper().deleteHTTP(
      vehiclesImagesRemove(id),
      params: {'image': imageUrl},
      showProgress: showProgress,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  // ─── Facilities ──────────────────────────────────────────────────

  Future<ResponseModel> createFacility(Map<String, dynamic> body) async {
    return ApiBaseHelper().postHTTP(
      vehicleFacilitiesCreate,
      params: body,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> listMyFacilities({bool showProgress = true}) async {
    return ApiBaseHelper().getHTTP(
      vehicleFacilitiesMineList,
      showProgress: showProgress,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> listFacilitiesForUser(String userId,
      {bool showProgress = true}) async {
    return ApiBaseHelper().getHTTP(
      vehicleFacilitiesPublic(userId),
      showProgress: showProgress,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> updateFacility({
    required String id,
    required Map<String, dynamic> patch,
  }) async {
    return ApiBaseHelper().putHTTP(
      vehicleFacilitiesUpdate(id),
      params: patch,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> deleteFacility(String id) async {
    return ApiBaseHelper().deleteHTTP(
      vehicleFacilitiesDelete(id),
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  // ─── Live photos ─────────────────────────────────────────────────

  Future<ResponseModel> addLivePhoto(Map<String, dynamic> body) async {
    return ApiBaseHelper().postHTTP(
      vehicleLivePhotosAdd,
      params: body,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> addLivePhotosBulk(List<Map<String, dynamic>> photos) async {
    return ApiBaseHelper().postHTTP(
      vehicleLivePhotosBulk,
      params: {'photos': photos},
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> listMyLivePhotos({bool showProgress = true}) async {
    return ApiBaseHelper().getHTTP(
      vehicleLivePhotosMineList,
      showProgress: showProgress,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> listLivePhotosForUser(String userId,
      {bool showProgress = true}) async {
    return ApiBaseHelper().getHTTP(
      vehicleLivePhotosPublic(userId),
      showProgress: showProgress,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> deleteLivePhoto(String id) async {
    return ApiBaseHelper().deleteHTTP(
      vehicleLivePhotosDelete(id),
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  // ─── Gallery ─────────────────────────────────────────────────────

  Future<ResponseModel> addGalleryItem(Map<String, dynamic> body) async {
    return ApiBaseHelper().postHTTP(
      vehicleGalleryAdd,
      params: body,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> addGalleryBulk(List<Map<String, dynamic>> items) async {
    return ApiBaseHelper().postHTTP(
      vehicleGalleryBulk,
      params: {'items': items},
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> listMyGallery({String? album, bool showProgress = true}) async {
    return ApiBaseHelper().getHTTP(
      vehicleGalleryMineList,
      params: {if (album != null && album.isNotEmpty) 'album': album},
      showProgress: showProgress,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> listGalleryForUser(String userId,
      {String? album, bool showProgress = true}) async {
    return ApiBaseHelper().getHTTP(
      vehicleGalleryPublic(userId),
      params: {if (album != null && album.isNotEmpty) 'album': album},
      showProgress: showProgress,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> updateGalleryItem({
    required String id,
    required Map<String, dynamic> patch,
  }) async {
    return ApiBaseHelper().putHTTP(
      vehicleGalleryUpdate(id),
      params: patch,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> deleteGalleryItem(String id) async {
    return ApiBaseHelper().deleteHTTP(
      vehicleGalleryDelete(id),
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  // ─── Testimonials ────────────────────────────────────────────────

  Future<ResponseModel> addVehicleTestimonial(Map<String, dynamic> body) async {
    return ApiBaseHelper().postHTTP(
      vehicleTestimonialsAdd,
      params: body,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> listReceivedTestimonials() async {
    return ApiBaseHelper().getHTTP(
      vehicleTestimonialsReceived,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> listTestimonialsForUser(String userId,
      {bool showProgress = true}) async {
    return ApiBaseHelper().getHTTP(
      vehicleTestimonialsPublic(userId),
      showProgress: showProgress,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> getVehicleTestimonialById(String id) async {
    return ApiBaseHelper().getHTTP(
      vehicleTestimonialsById(id),
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> updateTestimonial({
    required String id,
    required Map<String, dynamic> patch,
  }) async {
    return ApiBaseHelper().putHTTP(
      vehicleTestimonialsUpdate(id),
      params: patch,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> deleteTestimonial(String id) async {
    return ApiBaseHelper().deleteHTTP(
      vehicleTestimonialsDelete(id),
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  // ─── Contact us ──────────────────────────────────────────────────

  Future<ResponseModel> createContact(Map<String, dynamic> body) async {
    return ApiBaseHelper().postHTTP(
      vehicleContactCreate,
      params: body,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> listMyContacts({bool showProgress = true}) async {
    return ApiBaseHelper().getHTTP(
      vehicleContactMineList,
      showProgress: showProgress,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> listContactsForUser(String userId,
      {bool showProgress = true}) async {
    return ApiBaseHelper().getHTTP(
      vehicleContactPublic(userId),
      showProgress: showProgress,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> getContactById(String id) async {
    return ApiBaseHelper().getHTTP(
      vehicleContactById(id),
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> updateContact({
    required String id,
    required Map<String, dynamic> patch,
  }) async {
    return ApiBaseHelper().putHTTP(
      vehicleContactUpdate(id),
      params: patch,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> deleteContact(String id) async {
    return ApiBaseHelper().deleteHTTP(
      vehicleContactDelete(id),
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  // ─── Upload (presigned PUT) ──────────────────────────────────────

  /// Step 1 — ask backend for a presigned URL.
  /// GET /upload/init?fileName=...&fileType=...
  Future<ResponseModel> initUpload({
    required String fileName,
    required String fileType,
  }) async {
    return ApiBaseHelper().getHTTP(
      vehicleUploadInit,
      params: {'fileName': fileName, 'fileType': fileType},
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// Step 2 — PUT the binary body to the presigned URL.
  ///
  /// IMPORTANT: do NOT send the Authorization header here; S3 only
  /// accepts the signed Content-Type. We use a fresh [Dio] (not the
  /// shared interceptor-decorated client) so app headers don't leak
  /// into the upload.
  Future<void> putToS3({
    required String uploadUrl,
    required File file,
    required String contentType,
    void Function(int sent, int total)? onProgress,
  }) async {
    final length = await file.length();
    final stream = file.openRead();
    final dio = Dio();
    await dio.put(
      uploadUrl,
      data: stream,
      options: Options(
        headers: {
          Headers.contentLengthHeader: length,
          'Content-Type': contentType,
        },
        contentType: contentType,
      ),
      onSendProgress: onProgress,
    );
  }
}
