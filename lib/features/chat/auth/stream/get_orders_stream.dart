import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/constants/shared_preference_utils.dart';

// Make sure authTokenGlobal is initialized before calling this function
// Example: authTokenGlobal = await getUserAuthToken();

Stream<dynamic> getOrderFromUserStream() async* {
  final url = Uri.parse(
    'https://rider.blueera.ai/riders/orders/requested/stream',
  );

  final request = http.Request('GET', url);

  // Required headers
  request.headers.addAll({
    'Authorization': 'Bearer $authTokenGlobal',
    'Accept': 'text/event-stream', // important for SSE
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive',
  });

  print("Connecting to: $url");
  print("Auth token length: ${authTokenGlobal}");

  final response = await request.send();

  if (response.statusCode != 200) {
    final body = await response.stream.bytesToString();
    throw Exception(
      'Failed to connect to SSE. Status: ${response.statusCode}, Body: $body',
    );
  }

  // Listen to the stream
  final buffer = StringBuffer();

  await for (final chunk in response.stream.transform(utf8.decoder)) {
    for (final line in chunk.split('\n')) {

      if (line.startsWith('data:')) {
        // IMPORTANT: keep newline
        buffer.writeln(line.substring(5));
      }

      // SSE event ends with empty line
      if (line.trim().isEmpty && buffer.isNotEmpty) {
        try {
          final jsonStr = buffer.toString().trim();
          buffer.clear();

          final decoded = jsonDecode(jsonStr);
          yield decoded;
        } catch (e) {
          print('❌ JSON DECODE FAILED');
          print(buffer.toString());
          buffer.clear();
        }
      }
    }
  }

}
