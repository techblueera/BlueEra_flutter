import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetChatListModel.dart';
import 'package:BlueEra/features/common/help_support/model/help_question.dart';
import 'package:BlueEra/features/common/help_support/repo/help_support_repo.dart';
import 'package:get/get.dart';

/// State behind the Discover help bubble: the tailored questions, whether the
/// user already has a support thread, and sending an inquiry.
///
/// Held by a controller rather than the widget so the prefetch survives the
/// bubble being rebuilt as the user moves between Discover's own tabs — the
/// panel is meant to open instantly, which it can't do if every rebuild
/// re-issues the request. See lib/docs/HELP_WIDGET_FLUTTER_GUIDE.md §2.
class HelpSupportController extends GetxController {
  final HelpSupportRepo _repo = HelpSupportRepo();

  final RxList<HelpQuestion> questions = <HelpQuestion>[].obs;

  /// Support thread the user already has, if any. When set the bubble opens it
  /// straight away instead of asking the same questions again.
  final RxnString existingConversationId = RxnString();

  /// True while `POST /support/inquiry` is in flight — the Send button waits on
  /// it so a double tap can't open two threads.
  final RxBool isSending = false.obs;

  /// One prefetch per app session unless it failed; a failed load is retried
  /// when the user actually taps the bubble.
  bool _loaded = false;
  bool _inFlight = false;

  /// 'hi' or 'en' — the language the questions are shown and sent in. Read from
  /// the live GetX locale, so switching language re-labels the panel without a
  /// refetch (the payload carries both).
  String get languageCode => Get.locale?.languageCode == 'hi' ? 'hi' : 'en';

  @override
  void onInit() {
    super.onInit();
    prefetch();
  }

  /// Load the questions. Safe to call repeatedly — no-ops once loaded and
  /// while a request is already out.
  Future<void> prefetch() async {
    // Both endpoints resolve the caller from their JWT — a guest has no
    // account type or category to tailor questions to, and no thread to open.
    if (!isLoggedIn() || isGuestUser()) return;
    if (_loaded || _inFlight) return;
    _inFlight = true;
    try {
      final res = await _repo.getSupportQuestions();
      if (!res.isSuccess) return;
      final body = res.response?.data;
      if (body is! Map) return;
      final parsed = HelpQuestionsResult.fromJson(body);
      questions.assignAll(parsed.questions);
      existingConversationId.value = parsed.existingConversationId;
      _loaded = parsed.questions.isNotEmpty;
    } catch (_) {
      // Silent: the bubble is an affordance, not a feature the screen owes the
      // user. A failed prefetch just means the panel loads on tap instead.
    } finally {
      _inFlight = false;
    }
  }

  /// Send [text] as the opening message of the support thread and open it.
  ///
  /// Returns true when the chat was opened, so the caller can collapse the
  /// panel only on success and leave the typed question in place otherwise.
  Future<bool> sendInquiry(String text, {String? questionId}) async {
    final question = text.trim();
    if (question.isEmpty || isSending.value) return false;

    isSending.value = true;
    try {
      final res = await _repo.startSupportInquiry({
        ApiKeys.question: question,
        if (questionId != null && questionId.isNotEmpty)
          ApiKeys.questionId: questionId,
      });

      final conversationId =
          (res.getExtraData('conversation_id') ?? '').toString();
      if (!res.isSuccess || conversationId.isEmpty) {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
        return false;
      }

      // Remember it, so the next tap goes straight into the thread.
      existingConversationId.value = conversationId;
      await openSupportChat(conversationId);
      return true;
    } catch (_) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      isSending.value = false;
    }
  }

  /// Open the support conversation on the app's normal chat screen.
  ///
  /// The support endpoints return only a conversation id, so the counterpart's
  /// identity is recovered from the chat lists already in memory when the row
  /// is there (it will be, once the socket has delivered the thread). When it
  /// isn't, the chat still opens on the conversation id alone — history and
  /// sends are both keyed on it — just without a name or avatar in the header
  /// until the list catches up.
  Future<void> openSupportChat(String conversationId) async {
    if (conversationId.isEmpty) return;
    final chat = getOrPut(() => ChatViewController());
    final row = _findRow(chat, conversationId);

    await chat.openChatFromChatList(
      userId: row?.sender?.id ?? '',
      conversationId: conversationId,
      type: (row?.type?.isNotEmpty ?? false)
          ? row!.type!
          : AppConstants.personal_Chat_Type,
      contactName: row?.sender?.name,
      contactNo: row?.sender?.contactNo,
      profileImage: row?.sender?.profileImage,
    );
  }

  /// The loaded chat-list row for [conversationId], across both lanes.
  ChatList? _findRow(ChatViewController chat, String conversationId) {
    final lists = [
      chat.getPersonalChatListModel?.value.chatList,
      chat.getBusinessChatListModel?.value.chatList,
    ];
    for (final list in lists) {
      if (list == null) continue;
      for (final row in list) {
        if (row?.conversationId == conversationId) return row;
      }
    }
    return null;
  }
}
