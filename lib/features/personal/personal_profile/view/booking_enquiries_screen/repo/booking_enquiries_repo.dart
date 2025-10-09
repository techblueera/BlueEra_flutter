import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class BookingEnquiriesRepo extends BaseService{

  /// Get Video Booking Availability...
  Future<ResponseModel> getBookingAvailability({required String channelId}) async {
    final response = await ApiBaseHelper().getHTTP(
      bookingAvailability(channelId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Add Video Booking Availability...
  Future<ResponseModel> addUpdateBookingAvailability({required String channelId, required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().putHTTP(
      bookingAvailability(channelId),
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }


}