import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class BookingEnquiriesRepo extends BaseService{

  /// Get Video Booking Availability...
  Future<ResponseModel> getVideoBookingAvailability({required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      products,
      params: params,
      showProgress: false,
      isMultipart: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Add Video Booking Availability...
  Future<ResponseModel> addVideoBookingAvailability({required String channelId, required Map<String, dynamic> params}) async {
    String availability = bookingAvailability(channelId);
    final response = await ApiBaseHelper().putHTTP(
      availability,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Update Video Booking Availability ...
  Future<ResponseModel> updateVideoBookingAvailability({required String channelId}) async {
    String availability = bookingAvailability(channelId);
    final response = await ApiBaseHelper().putHTTP(
      availability,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

}