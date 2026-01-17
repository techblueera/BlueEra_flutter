import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class HotelServiceRepo extends BaseService {
  ///============ NEW REPO ===================
  // GET: Get hotel profile (Name, Address, etc.)
  Future<ResponseModel> getHotelProfileRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      hotelProfile, // your variable for /api/hotel-profile
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // POST: Create or update hotel profile
  Future<ResponseModel> saveHotelProfileRepo({
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      hotelProfile,
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // POST: Create or update hotel profile
  Future<ResponseModel> getCreatedRoomProfileRepo({
    required String roomType,
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      "${hotelRoomsType}/$roomType",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // GET: Get all contacts for the authenticated business
  Future<ResponseModel> getAllHotelContactsRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      hotelContacts,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // GET: Get a contact by ID
  Future<ResponseModel> getHotelContactByIdRepo(String id) async {
    final response = await ApiBaseHelper().getHTTP(
      "$hotelContacts/$id",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // GET: Get contacts by type
  Future<ResponseModel> getHotelContactsByTypeRepo(String type) async {
    final response = await ApiBaseHelper().getHTTP(
      "$hotelContacts/type/$type",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  // GET: Get contacts by type
  Future<ResponseModel> getHotelHomeRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      "$hotelHomeFull",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // POST: Create a new contact
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

  // PUT: Update a contact
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

  // DELETE: Delete a contact
  Future<ResponseModel> deleteHotelContactRepo(String id) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "$hotelContacts/$id",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

// GET: Get all rooms for the authenticated business
  Future<ResponseModel> getAllHotelRoomsRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      hotelRoom,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // GET: Get all rooms for the authenticated business
  Future<ResponseModel> getAllHotelRoomsTypeRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      hotelRoomType,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> addAllHotelRoomsTypeRepo({required Map<String,dynamic> reqBODY}) async {
    final response = await ApiBaseHelper().postHTTP(
      hotelRoomType,
      params:reqBODY ,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // GET: Get a room by ID
  Future<ResponseModel> getHotelRoomByIdRepo(String id) async {
    final response = await ApiBaseHelper().getHTTP(
      "$hotelRoom/$id",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // GET: Get rooms by room type
  Future<ResponseModel> getHotelRoomsByTypeRepo(String type) async {
    final response = await ApiBaseHelper().getHTTP(
      "$hotelRoom/type/$type",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // POST: Create a new room
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

  // PUT: Update a room
  Future<ResponseModel> updateHotelRoomRepo({
    required String id,
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      "$hotelRoom/$id",
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // DELETE: Delete a room
  Future<ResponseModel> deleteHotelRoomRepo(String id) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "$hotelRoom/$id",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // GET: Fetch property photos
  Future<ResponseModel> getHotelPropertyPhotosRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      hotelPropertyPhotos,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // POST: Upload/Add a new photo
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

  // DELETE: Remove a specific photo
  Future<ResponseModel> deleteHotelPropertyPhotosRepo({required Map<String,dynamic> reqBODY}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "$hotelPropertyPhotos",params: reqBODY,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

// GET: Fetch hotel policies
  Future<ResponseModel> getHotelPoliciesRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      hotelPolicies,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // POST: Create a new hotel policy
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

  // PUT: Update an existing hotel policy
  Future<ResponseModel> updateHotelPoliciesRepo({
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      hotelPolicies,
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // DELETE: Remove a hotel policy
  Future<ResponseModel> deleteHotelPoliciesRepo(String id) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "$hotelPolicies/$id",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // GET: Fetch all amenities
  Future<ResponseModel> getHotelAmenitiesRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      hotelAmenities, // Your URL variable
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // POST: Add a new amenity
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

  // PUT: Update an existing amenity
  Future<ResponseModel> updateHotelAmenitiesRepo({
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      hotelAmenities,
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // DELETE: Remove an amenity
  // Note: Usually requires an ID passed in the URL or as a param
  Future<ResponseModel> deleteHotelAmenitiesRepo(String id) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "$hotelAmenities/$id",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

// GET: Fetch room amenities
  Future<ResponseModel> getHotelRoomAmenitiesRepo({required String roomId}) async {
    final response = await ApiBaseHelper().getHTTP(
      "${hotelRoomAmenities}/$roomId",
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // POST: Create a new room amenity
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

  // PUT: Update an existing room amenity
  Future<ResponseModel> updateHotelRoomAmenitiesRepo({
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      hotelRoomAmenities,
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // DELETE: Delete a room amenity
  Future<ResponseModel> deleteHotelRoomAmenitiesRepo(String id) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "$hotelRoomAmenities/$id",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///============OLD===================

  ///GET SCHOOL/UNIVERSITY DETAILS...
  Future<ResponseModel> getHotelServiceCategoryRepo() async {
    final response = await ApiBaseHelper().getHTTP("${hotelBulkCatalogStatus}",
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///GET AI HOTEL SERVICE DETAILS...
  Future<ResponseModel> aiHotelFetchDetailsRepo(
      {required Map<String, dynamic> reqBody}) async {
    final response = await ApiBaseHelper().postHTTP(fetchHotelFromAi,
        params: reqBody, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///CREATE HOTEL SERVICE DETAILS...
  Future<ResponseModel> createHotelServiceRepo(
      {required Map<String, dynamic> reqBody}) async {
    final response = await ApiBaseHelper().postHTTP(createHotelService,
        params: reqBody, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  ///PUT  COURSE....
  Future<ResponseModel> updateHotelProfileRepo(
      {required Map<String, dynamic> reqBODY,}) async {
    final response = await ApiBaseHelper().putHTTP(
        createHotelService,
        params: reqBODY,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }
  ///GET HOTEL CONTACT REPO....
  Future<ResponseModel> getHotelRepo() async {
    final response = await ApiBaseHelper().getHTTP(createHotelService,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  ///UPDATE HOTEL Bulk SERVICE DETAILS...
  Future<ResponseModel> updateHotelServiceRepo(
      {required Map<String, dynamic> reqBody}) async {
    final response = await ApiBaseHelper().patchHTTP(hotelBulkStatus,
        params: reqBody, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  // ///UPDATE HOTEL Bulk SERVICE DETAILS...
  // Future<ResponseModel> addHotelPoliciesRepo(
  //     {required Map<String, dynamic> reqBody}) async {
  //   final response = await ApiBaseHelper().postHTTP(hotelsOfferings,
  //       params: reqBody, onError: (error) {}, onSuccess: (data) {});
  //   return response;
  // }
  Future<ResponseModel> getHotelContactRepo() async {
    final response = await ApiBaseHelper().getHTTP("${hotelsContactUsGet}",
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///CREATE CONTACT US SCHOOL Course REPO....
  Future<ResponseModel> createHotelBranchContactRepo(
      {required Map<String, dynamic> reqParm}) async {
    final response = await ApiBaseHelper().patchHTTP("${hotelsContactUsGet}",
        params: reqParm, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
}
