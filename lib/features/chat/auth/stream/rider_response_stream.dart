import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

import '../../../../core/constants/shared_preference_utils.dart';

// Make sure authTokenGlobal is initialized before calling this function
// Example: authTokenGlobal = await getUserAuthToken();

Stream<dynamic> riderOrderStream(String userId,) async* {

  final url = Uri.parse(
    'https://rider.blueera.ai/riders/orders/stream/$userId',
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
  await for (final chunk in response.stream.transform(utf8.decoder)) {
    for (final line in chunk.split('\n')) {
      if (line.startsWith('data:')) {
        final jsonStr = line.substring(5).trim();
        if (jsonStr.isNotEmpty) {
          try {
            final data = jsonDecode(jsonStr);
            yield data;
          } catch (e) {
            log('Invalid JSON in SSE: $jsonStr');
          }
        }
      }
    }
  }
}

Stream<dynamic> riderLiveLocationOrderStream(String riderId,) async* {

  final url = Uri.parse(
    'https://map.blueera.ai/api/provider/live-stream/$riderId',
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
  await for (final chunk in response.stream.transform(utf8.decoder)) {
    for (final line in chunk.split('\n')) {
      log('Invalid JSON in SSE: $line');
      if (line.startsWith('data:')) {
        final jsonStr = line.substring(5).trim();
        if (jsonStr.isNotEmpty) {
          try {
            final data = jsonDecode(jsonStr);
            yield data;
          } catch (e) {
            log('Invalid JSON in SSE: $jsonStr');
          }
        }
      }
    }
  }
}
