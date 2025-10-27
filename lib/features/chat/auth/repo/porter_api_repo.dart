import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';

class PorterApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://pfe-apigw-uat.porter.in/v1', // replace {porter_host} dynamically if needed
      headers: {
        'X-API-KEY': '659d4aaf-3797-4186-b7c3-2c231f5d0e22',
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  Future<Map<String, dynamic>?> getQuote(Map<String,dynamic> payload) async {
    const url = '/get_quote';


    try {
      final response = await _dio.post(url, data: payload);

      if (response.statusCode == 200) {
        print("✅ Porter Quote Response: ${response.data}");
        return response.data;
      } else {
        print("⚠️ Unexpected status: ${response.statusCode}");
        return null;
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print("❌ Error response: ${e.response?.data}");
        print("Status code: ${e.response?.statusCode}");
      } else {
        print("❌ Network or parsing error: ${e.message}");
      }
      return null;
    } catch (e) {
      print("❌ Unexpected error: $e");
      return null;
    }
  }
  Future<Map<String, dynamic>?> createOrder(Map<String,dynamic> payload) async {
    const url = '/orders/create';


    // try {

    final response = await _dio.post(
      url,
      data: payload,
      options: Options(
        responseType: ResponseType.plain, // Prevents FormatException for empty responses
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 204|| response.statusCode == 201) {
      log("✅ Order created successfully");
      log("Response: ${response.data}");
      return jsonDecode(response.data);
    } else {
      log("⚠️ Unexpected status code: ${response.statusCode}");
      log("Response: ${response.data}");
    }
    return null;
      // if (response.statusCode == 200) {
      //   log("✅ Create Order Response :  ${response.data}");
      //   return response.data;
      // } else {
      //   print("⚠️ Unexpected status: ${response.statusCode}");
      //   return null;
      // }
    // } on DioException catch (e) {
    //   if (e.response != null) {
    //     print("❌ Error response: ${e.response?.data}");
    //     print("Status code: ${e.response?.statusCode}");
    //   } else {
    //     print("❌ Network or parsing error: ${e.message}");
    //   }
    //   return null;
    // } catch (e) {
    //   print("❌ Unexpected error: $e");
    //   return null;
    // }
  }
}
