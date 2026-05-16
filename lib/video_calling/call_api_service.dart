import 'dart:convert';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/video_calling/response_model_jwt.dart';
import 'package:http/http.dart' as http;

class CallApiService {
  static const String baseUrl = "https://api.beapp.in/api/chat-service/call/user";

  static Future<AudioCallResponse?> startAudioCall({
    required String conversationId,
    required String callType,
  }) async {
    try {
      final uri = Uri.parse(baseUrl);
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": 'Bearer $authTokenGlobal'
        },
        body: jsonEncode({
          'conversation_id': conversationId,
          'call_type': callType,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return AudioCallResponse.fromJson(jsonData);
      } else {
        print("❌ API Error: ${response.statusCode} => ${response.body}");
        return null;
      }
    } catch (e) {
      print("⚠️ Exception in startAudioCall: $e");
      return null;
    }
  }
}
