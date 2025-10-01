import 'dart:convert';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class CallRepo extends BaseService {
  Future<ResponseModel> callToUser(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        callUser,
        isMultipart: false,
        showProgress: false,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

}
