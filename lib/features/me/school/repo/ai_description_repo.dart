import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';

class AIService extends BaseService {
  Future<List<String>?> generateDescriptionRepo({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    final response = await ApiBaseHelper().postHTTP(generateAIDescription,
        params: {
          "type": type,
          "data": data,
        },
        onError: (error) {},
        onSuccess: (data) {});

    return _suggestionsFrom(response.response?.data);
  }

  Future<List<String>?> generateExpertiseDescriptionRepo() async {
    final response = await ApiBaseHelper().postHTTP(aiExpertise,
        params: {

        },
        onError: (error) {},
        onSuccess: (data) {});

    return _suggestionsFrom(response.response?.data);
  }

  /// Reads `{success: true, data: [...]}` without trusting any of it.
  ///
  /// `response.data` is whatever the transport produced, not necessarily the
  /// documented envelope. Indexing a non-Map with a String key throws
  ///
  ///   type 'String' is not a subtype of type 'int' of 'index'
  ///
  /// which is how a gateway error page — a bare String body, or a List —
  /// reaching [generateExpertiseDescriptionRepo] crashed the app rather than
  /// showing the "Failed to generate suggestions" snackbar the caller already
  /// has for exactly this case. `List<String>.from` was the second trap: it
  /// throws on a null payload, and on any element that is not a String.
  ///
  /// Null means "no usable suggestions", which is what both callers already
  /// treat as failure.
  static List<String>? _suggestionsFrom(dynamic body) {
    if (body is! Map) return null;
    if (body['success'] != true) return null;

    final dynamic items = body['data'];
    if (items is! List) return null;

    final List<String> suggestions = items
        .map((dynamic e) => e?.toString().trim() ?? '')
        .where((String s) => s.isNotEmpty)
        .toList();
    return suggestions.isEmpty ? null : suggestions;
  }
}
