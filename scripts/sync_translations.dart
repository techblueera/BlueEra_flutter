/// Fetches all translations from the API and saves them to assets/translations/.
/// Run before release builds to ensure local JSON files match the API.
///
/// Usage:
///   dart run scripts/sync_translations.dart
///   dart run scripts/sync_translations.dart --base-url https://be.beapp.in/api/

import 'dart:convert';
import 'dart:io';

import 'package:BlueEra/core/constants/common_methods.dart';

const defaultBaseUrl = 'https://be.beapp.in/api/';
const languagesEndpoint = 'language-service/languages/names';
const downloadEndpoint = 'language-service/languages';
const outputDir = 'assets/translations';

Future<void> main(List<String> args) async {
  final baseUrl = _parseBaseUrl(args);
  final client = HttpClient();

  try {
    // Step 1: Fetch available languages
    print('Fetching available languages from $baseUrl$languagesEndpoint ...');
    final langResponse = await _get(client, '$baseUrl$languagesEndpoint');

    List<dynamic> langList;
    final decoded = jsonDecode(langResponse);
    if (decoded is List) {
      langList = decoded;
    } else if (decoded is Map && decoded.containsKey('data')) {
      langList = decoded['data'];
    } else {
      print('Unexpected response format: $langResponse');
      exit(1);
    }

    final codes = langList
        .map((e) => (e is Map ? e['languageCode'] ?? e['code'] : e).toString())
        .where((c) => c.isNotEmpty)
        .toList();

    print('Found ${codes.length} languages: ${codes.join(', ')}');

    // Ensure output directory exists
    final dir = Directory(outputDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    // Step 2: Download each language
    var successCount = 0;
    for (final code in codes) {
      try {
        print('Downloading "$code" ...');
        final body = await _get(client, '$baseUrl$downloadEndpoint/$code');

        final Map<String, dynamic> jsonData =
            jsonDecode(body);

        if (jsonData.isEmpty) {
          print('  WARNING: Empty response for "$code", skipping.');
          continue;
        }

        // Sort keys for stable diffs
        final sorted = Map.fromEntries(
          jsonData.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
        );

        final file = File('$outputDir/$code.json');
        const encoder = JsonEncoder.withIndent('  ');
        file.writeAsStringSync('${encoder.convert(sorted)}\n');
        print('  Saved ${sorted.length} keys to ${file.path}');
        successCount++;
      } catch (e) {
        print('  ERROR downloading "$code": $e');
      }
    }

    print('\nDone! Synced $successCount/${codes.length} languages to $outputDir/');
  } finally {
    client.close();
  }
}

Future<String> _get(HttpClient client, String url) async {
  final request = await client.getUrl(Uri.parse(url));
  final response = await request.close();
logs("response=11111=== ${response}");
  if (response.statusCode != 200) {
    final body = await response.transform(utf8.decoder).join();
    throw HttpException('HTTP ${response.statusCode}: $body', uri: Uri.parse(url));
  }

  return response.transform(utf8.decoder).join();
}

String _parseBaseUrl(List<String> args) {
  for (var i = 0; i < args.length - 1; i++) {
    if (args[i] == '--base-url') {
      var url = args[i + 1];
      if (!url.endsWith('/')) url += '/';
      return url;
    }
  }
  return defaultBaseUrl;
}
