/// All `vehicle-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
///
/// See `lib/docs/FLUTTER_INTEGRATION_GUIDE.md` for the full contract.
mixin VehicleServiceApi {
  // Public + owner vehicle CRUD
  final String vehiclesList = 'vehicle-service/vehicles';
  String vehicleById(String id) => 'vehicle-service/vehicles/get/$id';
  final String vehiclesCreate = 'vehicle-service/vehicles/create';
  final String vehiclesMineList = 'vehicle-service/vehicles/me/list';
  String vehiclesUpdate(String id) => 'vehicle-service/vehicles/update/$id';
  String vehiclesDelete(String id) => 'vehicle-service/vehicles/delete/$id';
  String vehiclesImagesAdd(String id) => 'vehicle-service/vehicles/$id/images';
  String vehiclesImagesRemove(String id) =>
      'vehicle-service/vehicles/$id/images';

  // Facilities
  final String vehicleFacilitiesCreate = 'vehicle-service/facilities/create';
  final String vehicleFacilitiesMineList = 'vehicle-service/facilities/me/list';
  String vehicleFacilitiesPublic(String userId) =>
      'vehicle-service/facilities/public/$userId';
  String vehicleFacilitiesUpdate(String id) =>
      'vehicle-service/facilities/update/$id';
  String vehicleFacilitiesDelete(String id) =>
      'vehicle-service/facilities/delete/$id';

  // Live photos
  final String vehicleLivePhotosAdd = 'vehicle-service/live-photos/add';
  final String vehicleLivePhotosBulk = 'vehicle-service/live-photos/bulk';
  final String vehicleLivePhotosMineList =
      'vehicle-service/live-photos/me/list';
  String vehicleLivePhotosPublic(String userId) =>
      'vehicle-service/live-photos/public/$userId';
  String vehicleLivePhotosDelete(String id) =>
      'vehicle-service/live-photos/delete/$id';

  // Gallery
  final String vehicleGalleryAdd = 'vehicle-service/gallery/add';
  final String vehicleGalleryBulk = 'vehicle-service/gallery/bulk';
  final String vehicleGalleryMineList = 'vehicle-service/gallery/me/list';
  String vehicleGalleryPublic(String userId) =>
      'vehicle-service/gallery/public/$userId';
  String vehicleGalleryUpdate(String id) =>
      'vehicle-service/gallery/update/$id';
  String vehicleGalleryDelete(String id) =>
      'vehicle-service/gallery/delete/$id';

  // Testimonials
  final String vehicleTestimonialsAdd = 'vehicle-service/testimonials/add';
  final String vehicleTestimonialsReceived =
      'vehicle-service/testimonials/me/received';
  String vehicleTestimonialsPublic(String userId) =>
      'vehicle-service/testimonials/public/$userId';
  String vehicleTestimonialsById(String id) =>
      'vehicle-service/testimonials/get/$id';
  String vehicleTestimonialsUpdate(String id) =>
      'vehicle-service/testimonials/update/$id';
  String vehicleTestimonialsDelete(String id) =>
      'vehicle-service/testimonials/delete/$id';

  // Contact us
  final String vehicleContactCreate = 'vehicle-service/contact-us/create';
  final String vehicleContactMineList = 'vehicle-service/contact-us/me/list';
  String vehicleContactPublic(String userId) =>
      'vehicle-service/contact-us/public/$userId';
  String vehicleContactById(String id) => 'vehicle-service/contact-us/get/$id';
  String vehicleContactUpdate(String id) =>
      'vehicle-service/contact-us/update/$id';
  String vehicleContactDelete(String id) =>
      'vehicle-service/contact-us/delete/$id';

  // S3 upload init (presigned PUT)
  final String vehicleUploadInit = 'vehicle-service/upload/init';
}
