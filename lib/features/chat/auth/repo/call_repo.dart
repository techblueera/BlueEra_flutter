import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CallRepo extends BaseService {
  static const String _basePath = 'call';

  /// Dedicated Dio instance for call service (https://call.blueera.ai/)
  static Dio? _callDio;

  static Dio get callDio {
    if (_callDio == null) {
      _callDio = Dio(BaseOptions(
        baseUrl: callBaseUrl ?? '',
        responseType: ResponseType.json,
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          ApiKeys.authorization: 'Bearer $authTokenGlobal',
          'Content-Type': 'application/json; charset=UTF-8',
          'X-Device-Type': 'mobile',
          'X-Device-OS':
              '${Platform.operatingSystem} ${deviceOsVersionGlobal}',
          'X-Browser-Name': AppConstants.appName,
        },
      ));

      if (!kReleaseMode) {
        _callDio!.interceptors.add(
          LogInterceptor(
            request: true,
            error: true,
            responseHeader: false,
            requestHeader: false,
          ),
        );
      }

      _callDio!.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            options.headers[ApiKeys.authorization] =
                'Bearer $authTokenGlobal';
            handler.next(options);
          },
        ),
      );
    }
    return _callDio!;
  }

  Future<ResponseModel> _post(String path, Map<String, dynamic> params) async {
    try {
      final response = await callDio.post(path, data: params);
      return ResponseModel(
        statusCode: response.statusCode,
        response: response,
      );
    } on DioException catch (e) {
      return ResponseModel(
        statusCode: e.response?.statusCode,
        response: e.response,
      );
    }
  }

  Future<ResponseModel> _get(String path) async {
    try {
      final response = await callDio.get(path);
      return ResponseModel(
        statusCode: response.statusCode,
        response: response,
      );
    } on DioException catch (e) {
      return ResponseModel(
        statusCode: e.response?.statusCode,
        response: e.response,
      );
    }
  }

  /// POST /call/initiate
  Future<ResponseModel> initiateCall(Map<String, dynamic> params) async {
    return await _post('$_basePath/initiate', params);
  }

  /// POST /call/accept
  Future<ResponseModel> acceptCall(Map<String, dynamic> params) async {
    return await _post('$_basePath/accept', params);
  }

  /// POST /call/decline
  Future<ResponseModel> declineCall(Map<String, dynamic> params) async {
    return await _post('$_basePath/decline', params);
  }

  /// POST /call/cancel
  Future<ResponseModel> cancelCall(Map<String, dynamic> params) async {
    return await _post('$_basePath/cancel', params);
  }

  /// POST /call/end
  Future<ResponseModel> endCall(Map<String, dynamic> params) async {
    return await _post('$_basePath/end', params);
  }

  /// POST /call/join (group call)
  Future<ResponseModel> joinCall(Map<String, dynamic> params) async {
    return await _post('$_basePath/join', params);
  }

  /// GET /call/history
  Future<ResponseModel> getCallHistory({
    String? conversationId,
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, dynamic> params = {
      ApiKeys.page: page,
      ApiKeys.limit: limit,
    };
    if (conversationId != null) {
      params[ApiKeys.conversation_id] = conversationId;
    }
    final response = await ApiBaseHelper().getHTTP(
      callHistory,
      showProgress: false,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// POST /call/switch-type
  Future<ResponseModel> switchCallType(Map<String, dynamic> params) async {
    return await _post('$_basePath/switch-type', params);
  }

  /// POST /call/switch-type/respond
  Future<ResponseModel> respondToSwitchType(
      Map<String, dynamic> params) async {
    return await _post('$_basePath/switch-type/respond', params);
  }

  /// POST /call/add-user
  Future<ResponseModel> addUserToCall(Map<String, dynamic> params) async {
    return await _post('$_basePath/add-user', params);
  }

  /// GET /call/active
  Future<ResponseModel> getActiveCall() async {
    return await _get('$_basePath/active');
  }

  /// GET /call/ice-servers
  Future<ResponseModel> getIceServers() async {
    return await _get('$_basePath/ice-servers');
  }
}
