import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class CallRepo {
  static const String _basePath = 'chat-service/call';

  /// POST /call/initiate
  Future<ResponseModel> initiateCall(Map<String, dynamic> params) async {
    return await ApiBaseHelper().postHTTP(
      '$_basePath/initiate',
      isMultipart: false,
      showProgress: false,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// POST /call/accept
  Future<ResponseModel> acceptCall(Map<String, dynamic> params) async {
    return await ApiBaseHelper().postHTTP(
      '$_basePath/accept',
      isMultipart: false,
      showProgress: false,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// POST /call/decline
  Future<ResponseModel> declineCall(Map<String, dynamic> params) async {
    return await ApiBaseHelper().postHTTP(
      '$_basePath/decline',
      isMultipart: false,
      showProgress: false,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// POST /call/cancel
  Future<ResponseModel> cancelCall(Map<String, dynamic> params) async {
    return await ApiBaseHelper().postHTTP(
      '$_basePath/cancel',
      isMultipart: false,
      showProgress: false,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// POST /call/end
  Future<ResponseModel> endCall(Map<String, dynamic> params) async {
    return await ApiBaseHelper().postHTTP(
      '$_basePath/end',
      isMultipart: false,
      showProgress: false,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// POST /call/join (group call)
  Future<ResponseModel> joinCall(Map<String, dynamic> params) async {
    return await ApiBaseHelper().postHTTP(
      '$_basePath/join',
      isMultipart: false,
      showProgress: false,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// GET /call/history
  Future<ResponseModel> getCallHistory({
    String? conversationId,
    int page = 1,
    int limit = 20,
  }) async {
    String url = '$_basePath/history?page=$page&limit=$limit';
    if (conversationId != null) {
      url += '&conversation_id=$conversationId';
    }
    return await ApiBaseHelper().getHTTP(url);
  }

  /// POST /call/switch-type
  Future<ResponseModel> switchCallType(Map<String, dynamic> params) async {
    return await ApiBaseHelper().postHTTP(
      '$_basePath/switch-type',
      isMultipart: false,
      showProgress: false,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// POST /call/switch-type/respond
  Future<ResponseModel> respondToSwitchType(Map<String, dynamic> params) async {
    return await ApiBaseHelper().postHTTP(
      '$_basePath/switch-type/respond',
      isMultipart: false,
      showProgress: false,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// POST /call/add-user
  Future<ResponseModel> addUserToCall(Map<String, dynamic> params) async {
    return await ApiBaseHelper().postHTTP(
      '$_basePath/add-user',
      isMultipart: false,
      showProgress: false,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// GET /call/active
  Future<ResponseModel> getActiveCall() async {
    return await ApiBaseHelper().getHTTP('$_basePath/active');
  }

  /// GET /call/ice-servers
  Future<ResponseModel> getIceServers() async {
    return await ApiBaseHelper().getHTTP('$_basePath/ice-servers');
  }
}
