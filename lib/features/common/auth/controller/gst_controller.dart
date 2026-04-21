import 'dart:convert';
import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/features/common/auth/model/gst_details_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:http/http.dart' as http;

class GstController extends GetxController {

  RxBool isLoading = false.obs;
  Rx<GstDetailsModel?> gstDetails = Rx<GstDetailsModel?>(null);
  Rx<ApiResponse> gstResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> otpResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> authTokenResponse = ApiResponse.initial('Initial').obs;

  Rx<String?> selectedStateCode = Rx<String?>(null);
  final TextEditingController gstUsernameController = TextEditingController();

  void resetState() {
    gstDetails.value = null;
    gstResponse.value = ApiResponse.initial('Initial');
    otpResponse.value = ApiResponse.initial('Initial');
    selectedStateCode.value = null;
    gstUsernameController.clear();
    isLoading.value = false;
  }

  Future<void> getGstDetails(String email, String gstin) async {

    try {
      log("Fetching GST details: https://api.whitebooks.in/public/search?email=$email&gstin=$gstin");
      isLoading.value = true;


      final response = await http.get(
        Uri.parse(
            "https://api.whitebooks.in/public/search?email=$email&gstin=$gstin"),
        headers: {
          "client_id": "GSTP4b021d8b-6069-490f-ba91-b28dc0228509",
          "client_secret": "GSTP70a28405-d61f-4720-b4bc-7297f25eecd2",
        },
      );
      
      log("GST API Response: ${response.body}");
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final model = GstDetailsModel.fromJson(data);
        
        // Checking for status_cd "1" as per the provided response sample
        if (model.statusCd == "1" || data['completed'] == true) {
          gstDetails.value = model;
          gstResponse.value = ApiResponse.complete(model);
        } else {
          gstResponse.value = ApiResponse.error(model.statusDesc ?? 'Gst Details Not Found');
        }
      } else {
        gstResponse.value = ApiResponse.error("Error: ${response.statusCode}");
      }

    } catch (e) {
      log("GST Error: $e");
      gstResponse.value = ApiResponse.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }
  Future<String> _getIpAddress() async {
    try {
      final response = await http.get(Uri.parse("https://api.ipify.org"));
      if (response.statusCode == 200) {
        return response.body.trim();
      }
    } catch (e) {
      log("IP fetch error: $e");
    }
    return "0.0.0.0";
  }

  String _getStateCodeFromGst() {
    final gstData = gstDetails.value;
    // Try to get state name from address and look up the 2-digit code
    final stcd = gstData?.data?.pradr?.addr?.stcd;
    if (stcd != null && stcd.isNotEmpty) {
      // If it's already a 2-digit code, return as-is
      if (RegExp(r'^\d{2}$').hasMatch(stcd)) return stcd;
      // Otherwise it's a state name — look up the code
      try {
        final match = gstStateCodes.firstWhere(
          (e) => e['state']!.toLowerCase().contains(stcd.toLowerCase()),
        );
        return match['code']!;
      } catch (_) {}
    }
    // Fallback: first 2 digits of GSTIN
    final gstin = gstData?.data?.gstin;
    if (gstin != null && gstin.length >= 2) return gstin.substring(0, 2);
    return "";
  }

  Future<void> requestOtp(String email) async {
    try {
      isLoading.value = true;

      final ipAddress = await _getIpAddress();
      final stateCd = _getStateCodeFromGst();
      final gstUsername = gstUsernameController.text.trim();

      final url = Uri.parse(
          "https://api.whitebooks.in/authentication/otprequest?email=$email");

      log("OTP API URL: $url");
      log("OTP Params: gst_username=$gstUsername, state_cd=$stateCd, ip_address=$ipAddress");

      final response = await http.get(
        url,
        headers: {
          "gst_username": gstUsername,
          "state_cd": stateCd,
          "ip_address": ipAddress,
          "client_id": "GSTP4b021d8b-6069-490f-ba91-b28dc0228509",
          "client_secret": "GSTP70a28405-d61f-4720-b4bc-7297f25eecd2",
        },
      );

      log("OTP API Response: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data["status_cd"] == "1") {
          otpResponse.value = ApiResponse.complete(data);
        } else {
          otpResponse.value =
              ApiResponse.error(data["status_desc"] ?? "OTP Request Failed");
        }
      } else {
        otpResponse.value =
            ApiResponse.error("Error: ${response.statusCode}");
      }
    } catch (e) {
      log("OTP API Error: $e");
      otpResponse.value = ApiResponse.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> requestAuthToken(String email, String otp) async {
    try {
      isLoading.value = true;

      final ipAddress = await _getIpAddress();
      final stateCd = _getStateCodeFromGst();
      final gstUsername = gstUsernameController.text.trim();
      final txnId = DateTime.now().millisecondsSinceEpoch.toString();

      final url = Uri.parse(
          "https://api.whitebooks.in/authentication/authtoken?email=$email&otp=$otp");

      log("Auth Token API URL: $url");

      final response = await http.get(
        url,
        headers: {
          "gst_username": gstUsername,
          "state_cd": stateCd,
          "ip_address": ipAddress,
          "txn": txnId,
          "client_id": "GSTP4b021d8b-6069-490f-ba91-b28dc0228509",
          "client_secret": "GSTP70a28405-d61f-4720-b4bc-7297f25eecd2",
        },
      );

      log("Auth Token Response: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data["status_cd"] == "1") {
          authTokenResponse.value = ApiResponse.complete(data);
        } else {
          authTokenResponse.value =
              ApiResponse.error(data["status_desc"] ?? "Auth Token Failed");
        }
      } else {
        authTokenResponse.value =
            ApiResponse.error("Error: ${response.statusCode}");
      }
    } catch (e) {
      log("Auth Token API Error: $e");
      authTokenResponse.value = ApiResponse.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  static const List<Map<String, String>> gstStateCodes = [
    {"code": "01", "state": "Jammu & Kashmir"},
    {"code": "02", "state": "Himachal Pradesh"},
    {"code": "03", "state": "Punjab"},
    {"code": "04", "state": "Chandigarh"},
    {"code": "05", "state": "Uttarakhand"},
    {"code": "06", "state": "Haryana"},
    {"code": "07", "state": "Delhi"},
    {"code": "08", "state": "Rajasthan"},
    {"code": "09", "state": "Uttar Pradesh"},
    {"code": "10", "state": "Bihar"},
    {"code": "11", "state": "Sikkim"},
    {"code": "12", "state": "Arunachal Pradesh"},
    {"code": "13", "state": "Nagaland"},
    {"code": "14", "state": "Manipur"},
    {"code": "15", "state": "Mizoram"},
    {"code": "16", "state": "Tripura"},
    {"code": "17", "state": "Meghalaya"},
    {"code": "18", "state": "Assam"},
    {"code": "19", "state": "West Bengal"},
    {"code": "20", "state": "Jharkhand"},
    {"code": "21", "state": "Odisha"},
    {"code": "22", "state": "Chhattisgarh"},
    {"code": "23", "state": "Madhya Pradesh"},
    {"code": "24", "state": "Gujarat"},
    {"code": "25", "state": "Daman & Diu"},
    {"code": "26", "state": "Dadra & Nagar Haveli"},
    {"code": "27", "state": "Maharashtra"},
    {"code": "28", "state": "Andhra Pradesh (Old)"},
    {"code": "29", "state": "Karnataka"},
    {"code": "30", "state": "Goa"},
    {"code": "31", "state": "Lakshadweep"},
    {"code": "32", "state": "Kerala"},
    {"code": "33", "state": "Tamil Nadu"},
    {"code": "34", "state": "Puducherry"},
    {"code": "35", "state": "Andaman & Nicobar Islands"},
    {"code": "36", "state": "Telangana"},
    {"code": "37", "state": "Andhra Pradesh (New)"},
    {"code": "38", "state": "Ladakh"},
    {"code": "97", "state": "Other Territory"},
  ];

}
