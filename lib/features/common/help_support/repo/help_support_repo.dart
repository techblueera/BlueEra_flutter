import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

/// The two chat-service endpoints behind the Discover help bubble.
/// See lib/docs/HELP_WIDGET_FLUTTER_GUIDE.md §1.
class HelpSupportRepo extends BaseService {
  /// Questions tailored to the caller (account type + category/profession are
  /// resolved server-side from the JWT, so there is nothing to send).
  ///
  /// `showProgress: false` — this is prefetched on Discover load; a blocking
  /// spinner over the feed for a widget the user hasn't touched would be wrong.
  Future<ResponseModel> getSupportQuestions() async {
    return ApiBaseHelper().getHTTP(
      supportQuestions,
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// Starts (or reuses) the support thread, posting [params] as the first
  /// message. Body: `{question, questionId?}` → `{conversation_id, message_id}`.
  Future<ResponseModel> startSupportInquiry(Map<String, dynamic> params) async {
    return ApiBaseHelper().postHTTP(
      supportInquiry,
      params: params,
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }
}
