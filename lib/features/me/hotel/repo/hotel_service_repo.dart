import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

/// Thin Dio wrapper for the hotel-service backend.
///
/// Endpoint constants (`hotelProfile`, `hotelContacts`, …) come from
/// [BaseService]. Only methods that are actually called by a controller are
/// kept here — the broader CRUD surface (per-id lookups, per-type filters,
/// individual amenity update/delete, etc.) was unreachable code and has been
/// dropped.
class HotelServiceRepo extends BaseService {
  // ---- Hotel profile & service catalog --------------------------------------

  /// Bootstraps a new hotel record for the signed-in business.
  Future<ResponseModel> createHotelServiceRepo({
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      createHotelService,
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Patches the hotel profile (name, logo, banner, ...).
  Future<ResponseModel> updateHotelProfileRepo({
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      createHotelService,
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Full home payload: profile + rooms + policies + amenities.
  Future<ResponseModel> getHotelHomeRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      hotelHomeFull,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Reads the service-catalog tree (categories + subcategory toggles).
  Future<ResponseModel> getHotelServiceCategoryRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      hotelBulkCatalogStatus,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Bulk-updates the `isEnabled` flag on a list of catalog nodes.
  Future<ResponseModel> updateHotelServiceRepo({
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().patchHTTP(
      hotelBulkStatus,
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // ---- Reception / branch contacts ------------------------------------------

  Future<ResponseModel> getAllHotelContactsRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      hotelContacts,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> addHotelContactRepo({
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      hotelContacts,
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> updateHotelContactRepo({
    required String id,
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      "$hotelContacts/$id",
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> deleteHotelContactRepo(String id) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "$hotelContacts/$id",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // ---- Rooms ----------------------------------------------------------------

  /// Lists existing rooms filtered by [roomType].
  Future<ResponseModel> getCreatedRoomProfileRepo({
    required String roomType,
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      "$hotelRoomsType/$roomType",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Creates a new room. Triggers an upload progress indicator because the
  /// body carries image URLs from the prior S3 step.
  Future<ResponseModel> addHotelRoomRepo({
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      hotelRoom,
      params: reqBody,
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> deleteHotelRoomRepo(String id) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "$hotelRoom/$id",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // ---- Property photos ------------------------------------------------------

  Future<ResponseModel> getHotelPropertyPhotosRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      hotelPropertyPhotos,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> addHotelPropertyPhotosRepo({
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      hotelPropertyPhotos,
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Removes a single image reference from a category album. Backend expects
  /// `{ category, imageReferences }` in the request body.
  Future<ResponseModel> deleteHotelPropertyPhotosRepo({
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().deleteHTTP(
      hotelPropertyPhotos,
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // ---- Policies -------------------------------------------------------------

  Future<ResponseModel> getHotelPoliciesRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      hotelPolicies,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Upsert: backend accepts the full policy record on POST.
  Future<ResponseModel> addHotelPoliciesRepo({
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      hotelPolicies,
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // ---- Hotel-wide amenities -------------------------------------------------

  Future<ResponseModel> getHotelAmenitiesRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      hotelAmenities,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> addHotelAmenitiesRepo({
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      hotelAmenities,
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // ---- Per-room amenities ---------------------------------------------------

  /// Fetches amenities for [roomId]. Empty string returns the template
  /// of available amenity keys with default values.
  Future<ResponseModel> getHotelRoomAmenitiesRepo({
    required String roomId,
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      "$hotelRoomAmenities/$roomId",
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> addHotelRoomAmenitiesRepo({
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      hotelRoomAmenities,
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
