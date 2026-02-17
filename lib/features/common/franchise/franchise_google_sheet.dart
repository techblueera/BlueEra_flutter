import 'package:http/http.dart' as http;
import 'dart:developer';

Future<bool> askFranchiseEnquiryApi(Map<String, dynamic> params) async {
  final url = Uri.parse(
    "https://script.google.com/macros/s/AKfycbx-A4ByElwLzolMtuXTlB62N9fSFyxg1GXnBKP8EVrgZkYpUBGcOPEYwPhnJpvv0CAs/exec",
  );

  try {
    final response = await http.post(
      url,
      body: params.map((k, v) => MapEntry(k, v.toString())),
    );

    log("StatusCode:hh ${response.statusCode}");
    log("Response: ${response.body}");

    // 🔥 GOOGLE SCRIPT SUCCESS CODES
    if (response.statusCode == 200 || response.statusCode == 302) {
      return true; // SUCCESS (Sheet already updated)
    }

    return false;
  } catch (e) {
    log("API Error: $e");
    return false;
  }
}
