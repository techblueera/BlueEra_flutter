import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

import '../../../../../../core/api/apiService/base_service.dart';


final String getUserByIdUrl = "user-service/user/getUserById";

class BookingRepo extends BaseService{

  Future<ResponseModel> postAppointment({Map<String, dynamic>? bodyRequest}) async {
    print("databody$bodyRequest");
    final response = await ApiBaseHelper().postHTTP(
      bookings,
      params: bodyRequest,
      isMultipart: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  Future<ResponseModel> postEnquiry({Map<String, dynamic>? bodyRequest}) async {
    print("databody$bodyRequest");
    final response = await ApiBaseHelper().postHTTP(
      Inquiries,
      params: bodyRequest,
      isMultipart: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  Future<ResponseModel> getMyBooking() async {
    final response = await ApiBaseHelper().getHTTP(
      MyBookingList,
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> getReceivedBooking({String? channelId,String?videoId}) async {
     if (channelId == null) {
       throw Exception('Channel ID is required');
     }
     String receivebook =  receivedBooking(channelId);
    final response = await ApiBaseHelper().getHTTP(
      
      receivebook,
     
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> getMyInquiries() async {
    final response = await ApiBaseHelper().getHTTP(
      myInquiries,
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> getReceivedInquiries({String? channelId}) async {
       if (channelId == null) {
         throw Exception('Channel ID is required');
       }
       String receivedinq =  receivedEnquiry(channelId);
    final response = await ApiBaseHelper().getHTTP(
 receivedinq,
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
Future<ResponseModel> getVideoBookings({String? channelId,String? videoId}) async {
     if (channelId == null || videoId == null) {
       throw Exception('Channel ID and Video ID are required');
     }
     String getvideobookings =  receivedVideoBooking(channelId, videoId);
    final response = await ApiBaseHelper().getHTTP(
 getvideobookings,
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  Future<ResponseModel> getVideoEnquiry({String? channelId,String? videoId}) async {
     if (channelId == null || videoId == null) {
       throw Exception('Channel ID and Video ID are required');
     }
     String getvideobookings =  receivedVideoEnquiry(channelId, videoId);
    final response = await ApiBaseHelper().getHTTP(
 getvideobookings,
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
Future<ResponseModel> getBookingByIds({String? bookingId}) async {
     
       String getbookigids =  getBookingById(bookingId!);
    final response = await ApiBaseHelper().getHTTP(
 getbookigids,
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  Future<ResponseModel> bookingStatusUpdate({
    required String id,
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().patchHTTP(
      updateBookingStatus(id),
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }
    Future<ResponseModel> enquiryStatusUpdate({
    required String id,
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().patchHTTP(
      enquiryBookingStatus(id),
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> checkAvailability({required String channelId, required Map<String, dynamic> params,}) async {
    final response = await ApiBaseHelper().putHTTP(
      setAvailability(channelId),
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> getAvailability({required String channelId, required Map<String, dynamic> params,}) async {
    final response = await ApiBaseHelper().getHTTP(
      setAvailability(channelId),
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    print('logsdata:$response');
    return response;
  }

  Future<ResponseModel> getavailableCalender({required String channelId, required Map<String, dynamic> params,}) async {
    final response = await ApiBaseHelper().getHTTP(
     getcalender(channelId),
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

}
