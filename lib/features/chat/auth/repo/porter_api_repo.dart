import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/snackbar_helper.dart';

/// Pulls `message` out of a response body that is only *expected* to be JSON.
///
/// This repo calls Dio directly, so `ResponseModel`'s guarded accessor is not
/// available and `Response.data` is whatever the transport produced. On an
/// error status that is most often an HTML page or a bare string — one of
/// these methods even does `jsonDecode(response.data)` on the success path,
/// confirming the body arrives as a String — and indexing a non-Map with a
/// String key throws `type 'String' is not a subtype of type 'int' of 'index'`.
String? _bodyMessage(dynamic body) =>
    body is Map ? body['message']?.toString() : null;

class PorterApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://pfe-apigw.porter.in/v1',
      // replace {porter_host} dynamically if needed
      headers: {
        'X-API-KEY': '59a65237-212c-4612-863b-22857612149d',
        // 'X-API-KEY': '659d4aaf-3797-4186-b7c3-2c231f5d0e22',
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  Future<Map<String, dynamic>?> getQuote(Map<String, dynamic> payload) async {
    const url = '/get_quote';
    try {
      final response = await _dio.post(url, data: payload);

      if (response.statusCode == 200) {
        print("✅ Porter Quote Response: ${response.data}");
        return {"status": true, "data": response.data};
      } else {
        commonSnackBar(
            message: _bodyMessage(response.data) ?? AppStrings.somethingWentWrong);
        return {"status": false, "data": response.data};
      }
    } on DioException catch (e) {
      // `e` is a DioException, not a ResponseModel, so the guarded accessor is
      // not available — the shape check has to be inline. An error body is the
      // likeliest of all to be an HTML page rather than the JSON envelope.
      final dynamic errorBody = e.response?.data;
      commonSnackBar(
          message: (errorBody is Map ? errorBody['message'] : null) ??
              AppStrings.somethingWentWrong);

      if (e.response != null) {
        print("❌ Error response: ${e.response?.data}");
        print("Status code: ${e.response?.statusCode}");
        return {"status": false, "data": e.response?.data};
      } else {
        return {"status": false, "data": e.response?.data};
      }
    } catch (e) {
      commonSnackBar(message: e.toString());

      return null;
    }
  }

  Future<Map<String, dynamic>?> createOrder(
      Map<String, dynamic> payload) async {
    const url = '/orders/create';

    try {
      final response = await _dio.post(
        url,
        data: payload,
        options: Options(
          responseType: ResponseType
              .plain, // Prevents FormatException for empty responses
        ),
      );
      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 201) {
        return jsonDecode(response.data);
      } else {
        commonSnackBar(
            message: _bodyMessage(response.data) ?? AppStrings.somethingWentWrong);
      }
      return null;
    } catch (e) {
      commonSnackBar(message: e.toString());
    }
    return null;
  }

  Future<bool?> cancelOrder(String orderId) async {
    String url = '/orders/$orderId/cancel';

    try {
      final response = await _dio.post(
        url,
        options: Options(
          responseType: ResponseType
              .plain, // Prevents FormatException for empty responses
        ),
      );
      log(" Order Canceled successfully jjj ${response.data}");
      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 201) {
        commonSnackBar(
            message: _bodyMessage(response.data) ?? "Order Canceled Successfully");

        return true;
      } else {
        commonSnackBar(
            message: _bodyMessage(response.data) ?? AppStrings.somethingWentWrong);
        return null;
      }

    } catch (e) {
      commonSnackBar(message: e.toString());
      return null;
    }
  }
}
