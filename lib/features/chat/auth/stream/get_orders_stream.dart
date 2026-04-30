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
    buffer.write(chunk);

    while (true) {
      final data = buffer.toString();
      final eventEndIndex = data.indexOf('\n\n');

      if (eventEndIndex == -1) break;

      final event = data.substring(0, eventEndIndex).trim();
      buffer.clear();
      buffer.write(data.substring(eventEndIndex + 2));

      if (event.startsWith('data:')) {
        final jsonStr = event.substring(5).trim();

        try {
          final decoded = jsonDecode(jsonStr);
          yield decoded;
        } catch (e) {

        }
      }
    }
  }
}