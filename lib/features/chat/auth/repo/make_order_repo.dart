
import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MakeOrderRepo extends BaseService {
  Future<ResponseModel> createOrder(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        createOrderApi,
        isMultipart: false,
        showProgress: false,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> verifyPayment(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        verifyPaymentApi,
        isMultipart: false,
        showProgress: false,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

}

// class PorterApiService extends BaseService  {
//   final String baseUrl = "https://pfe-apigw-uat.porter.in";
//   // final String apiKey = dotenv.env['PORTER_API_KEY']!;
//
//   Future<Map<String, dynamic>> getQuote({
//     required double pickupLat,
//     required double pickupLng,
//     required double dropLat,
//     required double dropLng,
//     required String customerName,
//     required String countryCode,
//     required String phoneNumber,
//   }) async {
//     final url = Uri.parse('$baseUrl/v1/get_quote');
//
//     final headers = {
//       'X-API-KEY': apiKey,
//       'Content-Type': 'application/json',
//     };
//
//     final body = {
//       "pickup_details": {
//         "lat": pickupLat,
//         "lng": pickupLng,
//       },
//       "drop_details": {
//         "lat": dropLat,
//         "lng": dropLng,
//       },
//       "customer": {
//         "name": customerName,
//         "mobile": {
//           "country_code": countryCode,
//           "number": phoneNumber,
//         },
//       },
//     };
//
//     final response = await http.post(
//       url,
//       headers: headers,
//       body: jsonEncode(body),
//     );
//
//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     } else {
//       throw Exception(
//         'Porter Get Quote Failed [${response.statusCode}]: ${response.body}',
//       );
//     }
//   }
// }
