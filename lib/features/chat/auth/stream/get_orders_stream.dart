import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/shared_preference_utils.dart';

// Make sure authTokenGlobal is initialized before calling this function
// Example: authTokenGlobal = await getUserAuthToken();

Stream<dynamic> getOrderFromUserStream() async* {
  final url = Uri.parse(
    'https://rider.beapp.in/riders/orders/requested/stream',
  );

  final request = http.Request('GET', url);

  // Required headers
  request.headers.addAll({
    'Authorization': 'Bearer $authTokenGlobal',
    'Accept': 'text/event-stream', // important for SSE
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive',
  });


  // Failures are yielded, not thrown. A gateway timeout on this endpoint takes
  // about a minute to come back — long enough for the rider to leave the screen
  // and for DeliveryPartnerOrdersController.stopStream() to cancel the
  // subscription while the request is still in flight. Throwing into a stream
  // nobody is listening to any more makes an unhandled async error, which is
  // how a routine 504 reached Crashlytics as a fatal. A yield cannot do that:
  // delivered to a live listener it reads as a non-List event, which the
  // consumer already maps to ApiResponse.error exactly as it did the throw, and
  // to a cancelled one it simply ends the generator.
  final http.StreamedResponse response;
  try {
    response = await request.send();
  } catch (e) {
    yield 'Failed to connect to SSE: $e';
    return;
  }

  if (response.statusCode != 200) {
    String body;
    try {
      body = await response.stream.bytesToString();
    } catch (e) {
      body = '<unreadable: $e>';
    }
    yield 'Failed to connect to SSE. Status: ${response.statusCode}, Body: $body';
    return;
  }

  // Listen to the stream
  final buffer = StringBuffer();

  try {
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
  } catch (e) {
    // A long-lived SSE connection dropping mid-flight is ordinary: the same
    // reasoning as above applies to the read as to the connect.
    yield 'SSE stream ended unexpectedly: $e';
  }
}