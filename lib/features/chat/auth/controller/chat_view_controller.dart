import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/model/base_ai_chat_model.dart';
import 'package:BlueEra/features/chat/auth/model/business_service_ask_ai_model.dart';
import 'package:BlueEra/features/chat/auth/model/education_ask_ai_model.dart';
import 'package:BlueEra/features/chat/auth/model/food_ask_ai_model.dart';
import 'package:BlueEra/features/chat/auth/model/health_care_ask_ai_model.dart';
import 'package:BlueEra/features/chat/auth/model/messageMediaUrl.dart';
import 'package:BlueEra/features/chat/auth/model/service_ask_ai_model.dart';
import 'package:BlueEra/features/chat/auth/model/travel_and_stay_ask_ai_model.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/check_internet_connectivity.dart';
import '../../../../core/services/chat_media_storage_service.dart';
import '../../../../core/services/local_strorage_helper.dart';
import '../../../../core/services/notification_utils.dart';
import '../../../../core/services/pending_message_drainer.dart';
import '../../../personal/personal_profile/model/check_chat_connection_model.dart';
import '../../view/business_chat/business_chat_screen_updated.dart';
import '../../view/personal_chat/personal_chat_screen.dart';
import '../model/Generate_Upload_Ulr_Model.dart';
import '../model/GetChatListModel.dart';
import '../model/GetChatRequestListModel.dart';
import '../model/GetListOfMessageData.dart';
import '../model/GetListOfMessageData.dart' as messageModel;
import '../model/ai_chat_history_msg_model.dart';
import '../model/ai_chat_reply_msg_model.dart';
import '../model/contactListModel.dart';
import '../model/find_service_by_contact_model.dart';
import '../model/getChatRequestProfileDetailsModel.dart';
import '../model/getMediaMsgCommentsModel.dart' as cmdImport;
import '../model/getMediaMsgCommentsModel.dart';
import '../model/group_details_model.dart';
import '../model/inventory_ask_ai_model.dart';
import '../model/visit_chat_view_model.dart';
import '../repo/chat_view_repo.dart';
import '../socket/ai_socket.dart';
import '../socket/chat_socket.dart';
import '../socket/live_location_track_socket.dart';

class ChatViewController extends GetxController {
  Rx<ApiResponse> chatMessageResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> personalChatListResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> businessChatListResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> groupChatListResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> orderChatListResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getListOfMessageResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getListOfAiMessageResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getListOfInventoryAiMessageResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getGroupMembersResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getServiceByContactResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> generateUploadUrlResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> chatMessageRequestResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> groupDetailsResponse =
      ApiResponse.initial('Initial').obs;
  RxInt personalTabSelectedIndex=0.obs;
  RxInt businessChatTabSelectedIndex=0.obs;
  Rx<ApiResponse> viewContactsListResponse = ApiResponse.initial('Initial').obs;
  final chatSocket      = ChatSocketService();
  final aiSocket        = AiSocketService();

  /// Whether the user has scrolled up away from the bottom of the chat.
  RxBool isUserScrolledUp = false.obs;

  /// Count of new messages that arrived while the user was scrolled up.
  RxInt unreadNewMessageCount = 0.obs;
  Rx<GetChatRequestListModel>? getChatRequestListModel =
      GetChatRequestListModel().obs;
  Rx<GetChatRequestProfileDetailsModel>? getChatRequestProfileDetailsModel =
      GetChatRequestProfileDetailsModel().obs;
  RxBool showMentionList = false.obs;
  RxString mentionQuery = "".obs;
  RxList<GroupMembersListModel> filteredMembers = <GroupMembersListModel>[].obs;
  RxList<String> taggedUserIds = <String>[].obs;
  Rx<GroupDetailsModel> groupDetailsModel=GroupDetailsModel().obs;

  static final Map<String, dynamic> aiChatListModel = {
    "last_message": "Ask anything with friend",
    "last_message_type": "text",
    "sender": {
      "name": "BlueEra Friend",
      "contact_no": "BlueEra Friend",
      "profile_image":AppImageAssets.app_logo,
      "account_type": AppConstants.personal_Chat_Type,
    }
  };

  static final Map<String, dynamic> businessAiChatListModel = {
    "last_message": "Ask anything about business",
    "last_message_type": "text",
    "sender": {
      "name": "BlueEra Business Friend",
      "contact_no": "BlueEra Friend",
      "profile_image":
          AppImageAssets.app_logo,
      "account_type": AppConstants.business_Chat_Type,
    }
  };
  static final Map<String, dynamic> aiChatSearch = {
    "last_message": "Ask anything with blueEra friend",
    "last_message_type": "text",
    "sender": {
      "name": "BlueEra Friend",
      "contact_no": "BlueEra Friend",
      "profile_image":
      AppImageAssets.app_logo,
      "account_type": AppConstants.search_Chat_Type,
    }
  };
  static final Map<String, dynamic> inventoryAiSearch = {
    "last_message": "Ask anything with Inventory Friend",
    "last_message_type": "text",
    "sender": {
      "name": "Sarthi Ai",
      "contact_no": "BlueEra Inventory Friend",
      "profile_image":
          AppImageAssets.app_logo,
      "account_type": AppConstants.askInventory_Chat_Type,
    }
  };
  static final Map<String, dynamic> foodAiSearch = {
    "last_message": "Ask anything with Inventory Friend",
    "last_message_type": "text",
    "sender": {
      "name": "Sarthi Ai",
      "contact_no": "BlueEra Food Friend",
      "profile_image":
      AppImageAssets.app_logo,
      "account_type": AppConstants.askFood_Chat_Type,
    }
  };
  static final Map<String, dynamic> serviceAiSearch = {
    "last_message": "Ask anything with Inventory Friend",
    "last_message_type": "text",
    "sender": {
      "name": "Sarthi Ai",
      "contact_no": "BlueEra Service Friend",
      "profile_image":
      AppImageAssets.app_logo,
      "account_type": AppConstants.askService_Chat_Type,
    }
  };
  static final Map<String, dynamic> healthCareAiSearch = {
    "last_message": "Ask anything with Inventory Friend",
    "last_message_type": "text",
    "sender": {
      "name": "Sarthi Ai",
      "contact_no": "BlueEra Health Care Friend",
      "profile_image":
      AppImageAssets.app_logo,
      "account_type": AppConstants.askHealthCare_Chat_Type,
    }
  };
  static final Map<String, dynamic> educationAiSearch = {
    "last_message": "Ask anything with Inventory Friend",
    "last_message_type": "text",
    "sender": {
      "name": "Sarthi Ai",
      "contact_no": "BlueEra Education Friend",
      "profile_image":
      AppImageAssets.app_logo,
      "account_type": AppConstants.askEducation_Chat_Type,
    }
  };
  static final Map<String, dynamic> homeServiceAiSearch = {
    "last_message": "Ask anything with Inventory Friend",
    "last_message_type": "text",
    "sender": {
      "name": "Sarthi Ai",
      "contact_no": "BlueEra Home Service Friend",
      "profile_image":
      AppImageAssets.app_logo,
      "account_type": AppConstants.askHomeService_Chat_Type,
    }
  };
  static final Map<String, dynamic> travelAndStayAiSearch = {
    "last_message": "Ask anything with Inventory Friend",
    "last_message_type": "text",
    "sender": {
      "name": "Sarthi Ai",
      "contact_no": "BlueEra Travel and Stay Friend",
      "profile_image":
      AppImageAssets.app_logo,
      "account_type": AppConstants.askTravelStay_Chat_Type,
    }
  };
  static final Map<String, dynamic> consultingTalkAiSearch = {
    "last_message": "Ask anything with Inventory Friend",
    "last_message_type": "text",
    "sender": {
      "name": "Sarthi Ai",
      "contact_no": "BlueEra Consulting Talk Friend",
      "profile_image":
      AppImageAssets.app_logo,
      "account_type": AppConstants.askConsultingTalk_Chat_Type,
    }
  };
  static final ChatList? personalAiChatModule =
      ChatList.fromJson(aiChatListModel);
  static final ChatList? businessAiChatModule =
      ChatList.fromJson(businessAiChatListModel);
  static final ChatList? aiChatListSearchModule =
      ChatList.fromJson(aiChatSearch);
  static final ChatList? inventoryAiChatListSearchModule =
      ChatList.fromJson(inventoryAiSearch);
  static final ChatList? foodAiChatListSearchModule =
      ChatList.fromJson(foodAiSearch);
  static final ChatList? serviceAiChatListSearchModule =
      ChatList.fromJson(serviceAiSearch);
  static final ChatList? healthCareAiChatListSearchModule =
      ChatList.fromJson(healthCareAiSearch);
  static final ChatList? educationAiChatListSearchModule =
     ChatList.fromJson(educationAiSearch);
  static final ChatList? homeServiceAiChatListSearchModule =
      ChatList.fromJson(homeServiceAiSearch);
  static final ChatList? travelAndStayAiChatListSearchModule =
     ChatList.fromJson(travelAndStayAiSearch);
  static final ChatList? consultingTalkAiChatListSearchModule =
     ChatList.fromJson(consultingTalkAiSearch);

  Rx<GetChatListModel>? getPersonalChatListModel = GetChatListModel().obs;
  Rx<GetChatListModel>? getOrderChatListModel = GetChatListModel().obs;
  Rx<GetChatListModel>? getBusinessChatListModel = GetChatListModel().obs;
  Rx<GetChatListModel>? getGroupChatListModel = GetChatListModel().obs;
  Rx<GetChatListModel>? getPersonalFilteredChatListModel =
      GetChatListModel().obs;

  List<Messages>? get getListOfMessageData =>
      getListOfMessageResponse.value.data;
  RxList<InventoryAskAiModel> getListOfInventoryAiMessages = <InventoryAskAiModel>[].obs;

  Rx<ContactListModel>? contactsListModel = ContactListModel().obs;
  Rx<GetMediaMsgCommentsModel>? getMediaMsgCommentsModel =
      GetMediaMsgCommentsModel().obs;
  RxList<ProfessionalContact> findProfessionalContactList = <ProfessionalContact>[].obs;
  Rx<TextEditingController> sendMessageController = TextEditingController().obs;
  RxBool isTextFieldEmpty = false.obs;
  RxBool isSending = false.obs;
  RxBool socketConnected = false.obs;
  RxBool chatFromBusinessProfile = false.obs;
  RxBool canPopBusiness = false.obs;
  RxBool socketConnectedCalled = false.obs;
  final ScrollController scrollController = ScrollController();
  Rx<Messages?>? replyMessage = Messages().obs;

  RxString userOnlineStatus = 'Offline'.obs;
  RxString userOpenConversationId = ''.obs;
  RxString userOpenUserId = ''.obs;
  RxString readMessageStatus = ''.obs;

  /// Cached set of online user IDs — survives chat list re-renders.
  RxSet<String> onlineUserIds = <String>{}.obs;

  /// Last-seen timestamps keyed by conversation ID.
  RxMap<String, String> lastSeenMap = <String, String>{}.obs;

  // Typing indicator state
  RxString typingText = ''.obs;
  Timer? _typingDebounceTimer;
  final Map<String, Timer> _typingHideTimers = {};

  /// Per-conversation typing indicator for the chat list.
  /// Key = conversation_id, Value = typer's name.
  RxMap<String, String> typingByConversation = <String, String>{}.obs;
  final Map<String, Timer> _chatListTypingTimers = {};
  RxInt selectedIndex =0.obs;

  Rx<Messages> sendLoadingFile = Messages().obs;
  RxList selectedUserIds = <String>[].obs;
  RxList<ChatList?> selectedChatList = <ChatList?>[].obs;
  RxList<String> openedConversation = <String>[].obs;
  // Conversations whose pending queue is currently being drained. The drainer
  // (on connectivity change) and getLocalConversation (on chat reopen) can both
  // fire sendOfflineMessage nearly simultaneously; without this guard the same
  // pending row gets retried twice, so the server receives each queued message
  // twice.
  final Set<String> _drainingConversations = <String>{};
  RxList<Map<String, dynamic>> groupConnections = <Map<String, dynamic>>[].obs;
  List<Messages>? getListOfAiMessageData = [];
  Rx<GenerateUploadUlrModel?>? generateUploadUlrModel =
      GenerateUploadUlrModel().obs;
  RxString VideoUploadProgress = ''.obs;
  RxInt selectedChatTabIndex = 0.obs;
  TabController? chatMainTabController;
  final localStorageHelper = LocalStorageHelper();
  RxInt businessTabIndexSelected = 0.obs;
  RxBool chatBotReading = false.obs;
  RxBool viewAllMembers = false.obs;

  // Chat list selection mode (WhatsApp-style long press)
  RxBool isChatListSelectionMode = false.obs;
  RxList<String> selectedConversationIds = <String>[].obs;
  RxList<ChatList?> selectedChatItems = <ChatList?>[].obs;

  void toggleChatListSelection(ChatList? chat) {
    final convId = chat?.conversationId ?? '';
    if (convId.isEmpty) return;
    if (selectedConversationIds.contains(convId)) {
      selectedConversationIds.remove(convId);
      selectedChatItems.removeWhere((c) => c?.conversationId == convId);
    } else {
      selectedConversationIds.add(convId);
      selectedChatItems.add(chat);
    }
    if (selectedConversationIds.isEmpty) {
      isChatListSelectionMode.value = false;
    }
  }

  void exitChatListSelectionMode() {
    isChatListSelectionMode.value = false;
    selectedConversationIds.clear();
    selectedChatItems.clear();
  }

  void selectAllChats(List<ChatList?> allChats) {
    selectedConversationIds.clear();
    selectedChatItems.clear();
    for (final chat in allChats) {
      if (chat?.conversationId != null) {
        selectedConversationIds.add(chat!.conversationId!);
        selectedChatItems.add(chat);
      }
    }
  }

  File? editedGroupFile;
  File? editedGroupCoverFile;
  RxBool isPublicGroup = false.obs;
  RxBool isDeleteBtnLoading = false.obs;
  RxBool isPinMessageLoading = false.obs;
  RxBool isEditGroupBtnLoading = false.obs;
  final groupNameController=TextEditingController();
  final groupDescriptionController=TextEditingController();

  RxInt groupChatScreenSelectedTab = 0.obs;
  final RxInt selectedDays = 1.obs;
  final List<String> tabs = [
    'Chat',
    'Products',
    'Foods',
    'Services',
    'Post',
    'Reviews',
    'Others'
  ];

  Rxn<CollapsibleGridModel> askAiFor = Rxn<CollapsibleGridModel>();
  final List<CollapsibleGridModel> arrAskForOptions = [
    CollapsibleGridModel(
      name: 'Products',
      slugId: PRODUCT,
      icon: AppImageAssets.products,
    ),
    CollapsibleGridModel(
      name: 'Foods',
      slugId: FOOD,
      icon: AppImageAssets.foods,
    ),
    CollapsibleGridModel(
      name: 'Services',
      slugId: SERVICE,
      icon: AppImageAssets.services,
    ),
    CollapsibleGridModel(
      name: 'Health Care',
      slugId: HEALTHCARE_MEDICAL_SERVICES,
      icon: AppImageAssets.healthCare,
    ),
    CollapsibleGridModel(
      name: 'Education',
      slugId: EDUCATION_TRAINING,
      icon: AppImageAssets.education,
    ),
    CollapsibleGridModel(
      name: 'Home Services',
      slugId: HOME_SERVICES,
      icon: AppImageAssets.homeService,
    ),
    CollapsibleGridModel(
      name: 'Travel & Stay',
      slugId: RENTAL_SERVICES,
      icon: AppImageAssets.travelAndStay,
    ),
    CollapsibleGridModel(
      name: 'Consulting Talk',
      slugId: PROFESSIONAL,
      icon: AppImageAssets.consultingTalk,
    ),
    CollapsibleGridModel(
      name: 'Let’s Talk',
      slugId: 'LETS_TALK',
      icon: AppImageAssets.sampleGirlImage,
    ),
  ];

  String productInitialMessage = 'Looking for the right product? Find TVs, refrigerators, washing machines & smartphones. Browse kitchen appliances, home essentials, electronics & gifts. All from trusted sellers near you. Just tell me what you’re looking for, and I’ll take care of the rest.';

  Future<void> disposeAiSocket() async {
    aiSocket.disposeSocket();
  }

  String formattedDate() {
    final now = DateTime.now().toUtc();
    return "${now.toIso8601String().substring(0, 23)}Z";
  }

  Future<bool?> clearChatHistory(Map<String, dynamic> params) async {
    try {
      isDeleteBtnLoading.value=true;
      ResponseModel responseModel =
      await ChatViewRepo().clearChatHistoryApi(params);

      if (responseModel.isSuccess) {
        isDeleteBtnLoading.value=false;
        getListOfMessageData?.clear();
         getListOfMessageResponse.value =ApiResponse.complete(getListOfMessageData);
        return true;
      } else {
        isDeleteBtnLoading.value=false;

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      isDeleteBtnLoading.value=false;

      commonSnackBar(message: e.toString());
    }
    return null;
  }
  void parseAiChatHistory(List<dynamic> jsonList) {
    for (var item in jsonList) {
      final details = AiChatHistoryMessageModel.fromJson(item);
      getListOfAiMessageData?.add(
        Messages(
          sendStatus: AppStrings.PersonalChatAi,
          status: "read",
          messageRead: 1,
          message: details.content,
          // Use details.content for text
          conversationId: details.id,
          // Or details.conversationId if exists
          myMessage: details.role == "user",
          // Mark user's messages
          createdAt: details.timestamp,
          messageType: "text",
        ),
      );
    }

    getListOfAiMessageResponse.value =
        ApiResponse.complete(getListOfAiMessageData);
  }

  Future<void> sendMessageToAiSocket({
    String? conversationId,
    required String type,
    String? message,
    String? tag,
    Uint8List? imageBytes,
    String? mimeType,
  }) async {
    chatBotReading.value = true;
    String? converId = await AiChatLocalStorage.getConversationId(
        type
    );
    aiSocket.sendMessage(
        message: message,
        conversationId: converId,
        imageBytes: imageBytes,
        mimeType: mimeType);
    getListOfAiMessageData?.add(Messages(
        sendStatus: AppStrings.PersonalChatAi,
        messageRead: 1,
        message: message,
        status: "read",
        conversationId: conversationId,
        myMessage: true,
        createdAt: formattedDate(),
        messageType: "text")); // Add message to UI

    getListOfAiMessageResponse.value =
        ApiResponse.complete(getListOfAiMessageData);
    sendMessageController.value.clear();
  }

  Future<void> connectAiSocket(String type) async {
    getListOfAiMessageData?.clear();
    aiSocket.disposeSocket();
    await aiSocket.connect();

    aiSocket.onMessage((data) {
      chatBotReading.value = false;
      AiReplyMessageModel details = AiReplyMessageModel.fromJson(data);
      saveAiConversationId(details.conversationId, type);
      getListOfAiMessageData?.add(Messages(
          sendStatus: AppStrings.PersonalChatAi,
          messageRead: 1,
          status: "read",
          message: details.reply,
          conversationId: details.conversationId,
          myMessage: false,
          createdAt: details.timestamp,
          messageType: "text"));
      getListOfAiMessageResponse.value =
          ApiResponse.complete(getListOfAiMessageData);
    });
    aiSocket.onHistory((data) {
      parseAiChatHistory(data);
    });
    String? converId = await AiChatLocalStorage.getConversationId(
        type
    );
    log('conversation id of $type is -- $converId');

    aiSocket.getHistory(converId ?? '');
    getListOfAiMessageResponse.value =
        ApiResponse.complete(getListOfAiMessageData);
  }

  Future<void> saveAiConversationId(String id, String type) async {
    await AiChatLocalStorage.saveConversationIdIfEmpty(
        id: id,
        type: type);
  }

  String _getInitialMessageText(String type) {
    switch (type) {
      case AppConstants.askInventory_Chat_Type:
        return AppStrings.aiChatInventory.tr;

      case AppConstants.askFood_Chat_Type:
        return AppStrings.aiChatFood.tr;

      case AppConstants.askService_Chat_Type:
        return AppStrings.aiChatService.tr;

      case AppConstants.askHealthCare_Chat_Type:
        return AppStrings.aiChatHealthCare.tr;

      case AppConstants.askEducation_Chat_Type:
        return AppStrings.aiChatEducation.tr;

      case AppConstants.askHomeService_Chat_Type:
        return AppStrings.aiChatHomeService.tr;

      case AppConstants.askTravelStay_Chat_Type:
        return AppStrings.aiChatTravelStay.tr;

      case AppConstants.askConsultingTalk_Chat_Type:
        return AppStrings.aiChatConsulting.tr;

      default:
        return AppStrings.aiChatDefault.tr;
    }
  }

  RxList<BaseAiChatModel> currentChatMessages = <BaseAiChatModel>[].obs;

  Future<void> connectSearchAiSocket(String type) async {
    chatBotReading.value = true;
    currentChatMessages.clear();
    aiSocket.disposeSocket();
    await aiSocket.connectSearchSocket();

    String? converId = await AiChatLocalStorage.getConversationId(type);
    log('conversation id of $type is -- $converId');

    // --- HISTORY LISTENER ---
    aiSocket.onHistory((data) {
      if (data is List) {
        List<BaseAiChatModel> history = data.map((jsonItem) {
          return _parseDataByType(type, jsonItem as Map<String, dynamic>);
        }).toList();

        currentChatMessages.assignAll(history);
      }
      // else if (data == null || (data is List && data.isEmpty)) {
      //   // 🟢 CASE 1: NO HISTORY -> Show Predefined Message
      //   BaseAiChatModel welcomeMsg = _createInitialModel(type);
      //   currentChatMessages.add(welcomeMsg);
      //
      //   log('➕ Added Initial Message for $type');
      // }

      chatBotReading.value = false;
    });

    // Listen for Live Messages
    aiSocket.onMessage((data) {
      chatBotReading.value = false;

      BaseAiChatModel msg = _parseDataByType(type, data);
      saveAiConversationId(msg.conversationId ?? '', type);

      currentChatMessages.add(msg);
      getListOfAiMessageResponse.value = ApiResponse.complete(currentChatMessages);
    });

    // --- FETCH HISTORY ---
    // aiSocket.getHistory(converId ?? '');

    if (converId != null) {
      aiSocket.getHistory(converId);
    } else {
      // NO HISTORY -> Show Predefined Message
      BaseAiChatModel welcomeMsg = _createInitialModel(type);
      currentChatMessages.add(welcomeMsg);

      log('➕ Added Initial Message for $type');
      chatBotReading.value = false;
    }
  }


  Future<void> sendMessageToAiSearchSocket({
    required String type,
    required String message,
    Uint8List? imageBytes,
    String? mimeType,
  }) async {

    BaseAiChatModel userMsg = _createLocalUserMessage(type, message);
    currentChatMessages.add(userMsg);

    sendMessageController.value.clear();
    chatBotReading.value = true;

    String? converId = await AiChatLocalStorage.getConversationId(type);
    log('conversation id of $type is -- $converId');


    if (converId == null &&
        type != AppConstants.personal_Chat_Type &&
        type != AppConstants.business_Chat_Type) {
      aiSocket.joinConversation(type);
    }

    aiSocket.sendMessage(
        message: message,
        conversationId: converId,
        serviceType: type,
        imageBytes: imageBytes,
        mimeType: mimeType
    );
  }

  BaseAiChatModel _parseDataByType(String type, Map<String, dynamic> json) {
    try {
      switch (type) {
        case AppConstants.askInventory_Chat_Type:
          return InventoryAskAiModel.fromJson(json);

        case AppConstants.askFood_Chat_Type:
          return FoodAskAiModel.fromJson(json);

        case AppConstants.askService_Chat_Type:
          return BusinessServicesAskAiModel.fromJson(json);

        case AppConstants.askHealthCare_Chat_Type:
          return HealthCareAskAiModel.fromJson(json);

        case AppConstants.askEducation_Chat_Type:
          return EducationAskAiModel.fromJson(json);

        case AppConstants.askHomeService_Chat_Type:
          return ServiceAskAiModel.fromJson(json);

        case AppConstants.askTravelStay_Chat_Type:
          return TravelAndStayAskAiModel.fromJson(json);

        case AppConstants.askConsultingTalk_Chat_Type:
          return ServiceAskAiModel.fromJson(json);

        default:
          return InventoryAskAiModel.fromJson(json);
      }
    } catch (e, stackTrace) {
      // 🔴 Log the Error and Stack Trace
      print("❌ Error in _parseDataByType for type: $type");
      print("Error: $e");
      print("Stack Trace: $stackTrace");

      // Recommended: Rethrow the error so the UI knows something failed
      rethrow;
    }
  }

  BaseAiChatModel _createLocalUserMessage(String type, String text) {
    String time = formattedDate();

    switch (type) {
      case AppConstants.askInventory_Chat_Type:
        return InventoryAskAiModel(message: text, role: "user", timestamp: time);
      case AppConstants.askFood_Chat_Type:
        return FoodAskAiModel(message: text, role: "user", timestamp: time);
      case AppConstants.askService_Chat_Type:
        return BusinessServicesAskAiModel(message: text, role: "user", timestamp: time);
      case AppConstants.askHealthCare_Chat_Type:
        return HealthCareAskAiModel(message: text, role: "user", timestamp: time);
      case AppConstants.askEducation_Chat_Type:
        return EducationAskAiModel(message: text, role: "user", timestamp: time);
      case AppConstants.askHomeService_Chat_Type:
        return ServiceAskAiModel(message: text, role: "user", timestamp: time);
      case AppConstants.askTravelStay_Chat_Type:
        return TravelAndStayAskAiModel(message: text, role: "user", timestamp: time);
      case AppConstants.askConsultingTalk_Chat_Type:
        return ServiceAskAiModel(message: text, role: "user", timestamp: time);
      default:
        return InventoryAskAiModel(message: text, role: "user", timestamp: time);
    }
  }

  BaseAiChatModel _createInitialModel(String type) {
    String text = _getInitialMessageText(type); // Gets the welcome text we defined earlier

    final DateTime date = DateTime.parse(DateTime.now().toIso8601String()).toLocal(); // Convert to local time
    String time = DateFormat('h:mm a').format(date);

    switch (type) {
      case AppConstants.askInventory_Chat_Type:
        return InventoryAskAiModel(
            message: text, role: "model", timestamp: time);

      case AppConstants.askFood_Chat_Type:
        return FoodAskAiModel(
            message: text, role: "model", timestamp: time);

      case AppConstants.askService_Chat_Type:
        return BusinessServicesAskAiModel(
            message: text, role: "model", timestamp: time);

      case AppConstants.askHealthCare_Chat_Type:
        return HealthCareAskAiModel(
            message: text, role: "model", timestamp: time);

      case AppConstants.askEducation_Chat_Type:
        return EducationAskAiModel(
            message: text, role: "model", timestamp: time);

      case AppConstants.askHomeService_Chat_Type:
        return ServiceAskAiModel(
            message: text, role: "model", timestamp: time);

      case AppConstants.askTravelStay_Chat_Type:
        return TravelAndStayAskAiModel(
            message: text, role: "model", timestamp: time);

      case AppConstants.askConsultingTalk_Chat_Type:
        return ServiceAskAiModel(
            message: text, role: "model", timestamp: time);

      default:
        return InventoryAskAiModel(
            message: text, role: "model", timestamp: time);
    }
  }

  Future<void> connectSocket() async {
    // Always ensure socket is connected
    await chatSocket.connectToSocket();

    if (socketConnected.value == false) {
      socketConnected.value = true;
      chatSocket.listenEvent(ChatEmitEvents.ChatList, (data) async {
        log("ksdjjknksdjcnsdc ${data}");
        //1200000039
        final parsedData = GetChatListModel.fromJson(data);
        loadChatListWithType(chatListModel: parsedData);
        getPersonalFilteredChatListModel?.value = parsedData;
        // Persist server-authoritative chat list for offline render on next open.
        if ((parsedData.type ?? '').isNotEmpty) {
          await localStorageHelper.saveChatList(
              parsedData.chatList ?? [], parsedData.type ?? '');
        }
      });

      chatSocket.listenEvent(ChatEmitEvents.messageViewed, (data) {
        getMediaMsgCommentsModel?.value =
            GetMediaMsgCommentsModel.fromJson(data);
      });
      chatSocket.listenEvent(ChatEmitEvents.messageReceived, (data) async {
        log("sldcsdlkslk ${data}");
          final parsedData = GetListOfMessageData.fromJson(data);

          if (parsedData.messages != null) {
            for (var message in parsedData.messages!) {
              if (message.myMessage == null) {
                final currentUserId = userId;
                final senderId = message.senderId;
                message.myMessage = currentUserId == senderId;
              }
            }
          }

          if (parsedData.messages?.isNotEmpty ?? false) {
            // The first entry is often a "date" separator with
            // conversation_id "0" — scan until we find a real message so the
            // Hive save key matches the actual conversationId the chat list
            // uses when loading offline. Otherwise every conversation's
            // messages would be stored under "0" and getMessagesByConversationId
            // would return empty for the real id.
            String conversationId = '';
            for (final m in parsedData.messages!) {
              if (m.messageType == 'date') continue;
              final id = m.conversationId ?? '';
              if (id.isEmpty || id == '0') continue;
              conversationId = id;
              break;
            }
            // Fall back to the open conversation id so sync still works for
            // edge cases where every message entry is a date separator.
            if (conversationId.isEmpty) {
              conversationId = userOpenConversationId.value;
            }
            if (parsedData.messages != null && conversationId.isNotEmpty) {
              // Deduplicate server messages by ID before setting
              final seen = <String>{};
              final deduped = <Messages>[];
              for (final m in parsedData.messages!) {
                final id = m.id ?? '';
                if (id.isEmpty || seen.add(id)) {
                  deduped.add(m);
                }
              }
              // Resolve local file paths for already-downloaded media
              // so images/videos show instantly from local storage
              await _resolveLocalMediaPaths(deduped);
              getListOfMessageResponse.value = ApiResponse.complete(deduped);
              scrollDown();
              // saveMessagesByConversationId REPLACES the full list — this is
              // the authoritative server data. The helper preserves any locally
              // pending messages that the server hasn't acked yet.
              localStorageHelper.saveMessagesByConversationId(
                  conversationId, deduped);
            } else {
              getListOfMessageResponse.value =
                  ApiResponse.complete(parsedData.messages);
            }
          } else {
            getListOfMessageResponse.value =
                ApiResponse.complete(parsedData.messages);
          }


      });
      chatSocket.listenEvent(ChatEmitEvents.newMessageReceived, (data) async {


        Messages? message;
        if (data['message'] != null) {
          message = Messages.fromJson(data['message']);
        } else {
          message = null;
        }
        if (message == null) return;

        if (message.myMessage == null) {
          final currentUserId = userId;
          final senderId = message.senderId;
          message.myMessage = currentUserId == senderId;
        }

        // Always refresh the relevant chat list tab
        final msgType = message.conversation?.type;
        if (msgType == AppConstants.business_Chat_Type) {
          emitEvent(ChatEmitEvents.ChatList,
              {ApiKeys.type: AppConstants.business_Chat_Type});
        } else if (msgType == AppConstants.group_Chat_Type) {
          emitEvent(ChatEmitEvents.ChatList,
              {ApiKeys.type: AppConstants.group_Chat_Type});
        } else if (msgType == AppConstants.order_Chat_Type) {
          emitEvent(ChatEmitEvents.ChatList,
              {ApiKeys.type: AppConstants.order_Chat_Type});
        } else {
          emitEvent(ChatEmitEvents.ChatList,
              {ApiKeys.type: AppConstants.personal_Chat_Type});
        }

        // Only add to currently open conversation
        String checkedConversationId = userOpenConversationId.value;
        if (checkedConversationId.isEmpty ||
            checkedConversationId != message.conversationId) {
          // Increment unread count locally for conversations the user is not viewing
          if (message.myMessage != true && message.conversationId != null) {
            _incrementChatListUnreadCount(message.conversationId!);
          }
          return;
        }

        // Deduplicate: skip if message with same ID already exists
        // This prevents doubles when sendMessage() already added it via API response
        final existingIds = getListOfMessageData
            ?.map((m) => m.id)
            .where((id) => id != null)
            .toSet() ?? {};
        if (message.id != null && existingIds.contains(message.id)) {
          return;
        }

        // Resolve local file paths for media so it shows from local storage instantly
        await _resolveLocalMediaPaths([message]);
        getListOfMessageData?.add(message);
        getListOfMessageResponse.value =
            ApiResponse.complete(getListOfMessageData);
        saveSingleMessageToLocal(
            message.conversationId ?? '', message);

        // Auto-mark as read: user is viewing this conversation, so incoming
        // messages should be marked read immediately (guide §5.2)
        if (message.myMessage != true) {
          chatSocket.emitEvent(ChatEmitEvents.markConversationRead,
              {ApiKeys.conversation_id: checkedConversationId});
        }
        scrollDown();
      });
      chatSocket.listenEvent(ChatEmitEvents.isOnLine, (data) {
        final uid = data['user_id'] as String?;
        final isOnline = data['is_online'] == true;
        if (uid != null) {
          if (isOnline) {
            onlineUserIds.add(uid);
          } else {
            onlineUserIds.remove(uid);
          }
        }
        if (uid == userOpenUserId.value) {
          userOnlineStatus.value = isOnline ? "Online" : "Offline";
        }
      });
      chatSocket.listenEvent(ChatEmitEvents.isOnlineFromChatList, (data) {
        final List<Map<String, dynamic>> datas =
        List<Map<String, dynamic>>.from(data);

        for (final update in datas) {
          final uid = update['user_id'] as String?;
          final isOnline = update['is_online'] == true;

          if (uid != null) {
            if (isOnline) {
              onlineUserIds.add(uid);
            } else {
              onlineUserIds.remove(uid);
            }
          }

          // Update the active chat screen
          if (uid == userOpenUserId.value) {
            userOnlineStatus.value = isOnline ? "Online" : "Offline";
          }
        }
      });

      // Last-seen timestamps
      chatSocket.listenEvent(ChatEmitEvents.userLastSeenList, (data) {
        if (data is List) {
          for (final item in data) {
            final conversationId = item['conversation_id'] as String?;
            final lastSeen = item['last_seen'] as String?;
            if (conversationId != null && lastSeen != null) {
              lastSeenMap[conversationId] = lastSeen;
            }
          }
        }
      });

      // Typing indicator listener
      chatSocket.listenEvent(ChatEmitEvents.isTyping, (data) {
        final conversationId = data['conversation_id'] as String?;
        final typingUserId = data['user_id'] as String?;
        final typingUser = data['user'];

        if (conversationId == null) return;
        if (typingUserId == null) return;

        final name = typingUser?['name'] ?? 'Someone';

        // Update chat list typing indicator for ALL conversations
        typingByConversation[conversationId] = name;
        _chatListTypingTimers[conversationId]?.cancel();
        _chatListTypingTimers[conversationId] =
            Timer(const Duration(seconds: 3), () {
          typingByConversation.remove(conversationId);
          _chatListTypingTimers.remove(conversationId);
        });

        // Update open chat screen typing indicator
        if (conversationId != userOpenConversationId.value) return;

        typingText.value = 'typing...';

        // Auto-hide after 3 seconds
        _typingHideTimers[typingUserId]?.cancel();
        _typingHideTimers[typingUserId] = Timer(const Duration(seconds: 3), () {
          _typingHideTimers.remove(typingUserId);
          if (_typingHideTimers.isEmpty) {
            typingText.value = '';
          }
        });
      });

      chatSocket.listenEvent(ChatEmitEvents.messageStatusUpdate, (data) {
        if (data['conversation_id'] == userOpenConversationId.value) {
          final newStatus = data['status'] as String? ?? '';
          // Status only goes forward: sent(0) → delivered(1) → read(2)
          const statusOrder = {'sent': 0, 'delivered': 1, 'read': 2};
          final currentRank = statusOrder[readMessageStatus.value] ?? -1;
          final newRank = statusOrder[newStatus] ?? -1;
          if (newRank > currentRank) {
            readMessageStatus.value = newStatus;
          }

          // Update per-message status for all outgoing messages in this conversation
          final messages = getListOfMessageData;
          if (messages != null) {
            for (final msg in messages) {
              if (msg.myMessage == true) {
                final msgRank = statusOrder[msg.status] ?? 0;
                if (newRank > msgRank) {
                  msg.status = newStatus;
                }
              }
            }
            getListOfMessageResponse.refresh();
          }
        }
      });

      // Unread count cleared listener
      chatSocket.listenEvent(ChatEmitEvents.unreadCountCleared, (data) {
        final conversationId = data['conversation_id'] as String?;
        if (conversationId != null) {
          _updateChatListUnreadCount(conversationId, 0);
        }
      });
      chatSocket.listenEvent(ChatEmitEvents.update_data, (data) {
        emitEvent(ChatEmitEvents.messageReceived, {
          ApiKeys.conversation_id: data[ApiKeys.conversation_id],
          ApiKeys.page: 1,
          ApiKeys.is_online_user: userOpenUserId.value,
          ApiKeys.per_page_message: 30,
        });
      });

      // Self-Pickup: New order received (business side)
      chatSocket.listenEvent(ChatEmitEvents.newSelfPickupOrderReceived, (data) {
        if (data['message'] != null) {
          final message = Messages.fromJson(data['message']);
          final conversationId = message.conversationId ?? '';
          if (conversationId.isNotEmpty && conversationId == userOpenConversationId.value) {
            final currentMessages = getListOfMessageResponse.value.data as List<Messages>? ?? [];
            final exists = currentMessages.any((m) => m.id == message.id);
            if (!exists) {
              currentMessages.add(message);
              getListOfMessageResponse.value = ApiResponse.complete(currentMessages);
              scrollDown();
            }
          }
          // Refresh chat list
          emitEvent(ChatEmitEvents.ChatList, {
            ApiKeys.page: 1,
            ApiKeys.per_page_message: 30,
          });
        }
      });

      // Self-Pickup: Order marked as ready
      chatSocket.listenEvent(ChatEmitEvents.selfPickupOrderReady, (data) {

        final messageId = data['messageId']?.toString() ?? '';
        if (messageId.isNotEmpty) {
          final currentMessages = getListOfMessageResponse.value.data as List<Messages>? ?? [];
          for (var msg in currentMessages) {
            if (msg.id == messageId) {
              msg.metadata?.orderStatus = true;
              msg.metadata?.selfPickupOrder?.isReady = true;
              break;
            }
          }
          getListOfMessageResponse.value = ApiResponse.complete(currentMessages);
        }
      });

      // Food Self-Pickup: New order received (restaurant side)
      chatSocket.listenEvent(ChatEmitEvents.newFoodPickupOrderReceived, (data) {
        if (data['message'] != null) {
          final message = Messages.fromJson(data['message']);
          final conversationId = message.conversationId ?? '';
          if (conversationId.isNotEmpty && conversationId == userOpenConversationId.value) {
            final currentMessages = getListOfMessageResponse.value.data as List<Messages>? ?? [];
            final exists = currentMessages.any((m) => m.id == message.id);
            if (!exists) {
              currentMessages.add(message);
              getListOfMessageResponse.value = ApiResponse.complete(currentMessages);
              scrollDown();
            }
          }
          emitEvent(ChatEmitEvents.ChatList, {
            ApiKeys.page: 1,
            ApiKeys.per_page_message: 30,
          });
        }
      });

      // Food Self-Pickup: Order marked as ready
      chatSocket.listenEvent(ChatEmitEvents.foodPickupOrderReady, (data) {
        log("foodPickupOrderReady: $data");
        final messageId = data['messageId']?.toString() ?? '';
        if (messageId.isNotEmpty) {
          final currentMessages = getListOfMessageResponse.value.data as List<Messages>? ?? [];
          for (var msg in currentMessages) {
            if (msg.id == messageId) {
              msg.metadata?.orderStatus = true;
              if (msg.metadata?.foodPickupOrder != null) {
                msg.metadata?.foodPickupOrder?.isReady = true;
              }
              if (msg.metadata?.selfPickupOrder != null) {
                msg.metadata?.selfPickupOrder?.isReady = true;
              }
              break;
            }
          }
          getListOfMessageResponse.value = ApiResponse.complete(currentMessages);
        }
      });

      // Product Self-Pickup: New order received (seller side)
      chatSocket.listenEvent(ChatEmitEvents.newProductPickupOrderReceived, (data) {
        if (data['message'] != null) {
          final message = Messages.fromJson(data['message']);
          final conversationId = message.conversationId ?? '';
          if (conversationId.isNotEmpty && conversationId == userOpenConversationId.value) {
            final currentMessages = getListOfMessageResponse.value.data as List<Messages>? ?? [];
            final exists = currentMessages.any((m) => m.id == message.id);
            if (!exists) {
              currentMessages.add(message);
              getListOfMessageResponse.value = ApiResponse.complete(currentMessages);
              scrollDown();
            }
          }
          emitEvent(ChatEmitEvents.ChatList, {
            ApiKeys.page: 1,
            ApiKeys.per_page_message: 30,
          });
        }
      });

      // Product Self-Pickup: Order marked as ready
      chatSocket.listenEvent(ChatEmitEvents.productPickupOrderReady, (data) {
        log("productPickupOrderReady: $data");
        final messageId = data['messageId']?.toString() ?? '';
        if (messageId.isNotEmpty) {
          final currentMessages = getListOfMessageResponse.value.data as List<Messages>? ?? [];
          for (var msg in currentMessages) {
            if (msg.id == messageId) {
              msg.metadata?.orderStatus = true;
              if (msg.metadata?.productPickupOrder != null) {
                msg.metadata?.productPickupOrder?.isReady = true;
              }
              if (msg.metadata?.selfPickupOrder != null) {
                msg.metadata?.selfPickupOrder?.isReady = true;
              }
              break;
            }
          }
          getListOfMessageResponse.value = ApiResponse.complete(currentMessages);
        }
      });

      socketConnectedCalled.value = true;
    }
    try {
      // openedConversation.value = await localStorageHelper.getConversation();
      // await loadAllChatListFromLocal();
    } catch (e) {
      debugPrint('connectSocket local storage init error: $e');
    }
    // final connectivityResult = await NetworkUtils.isConnected();
    // if (connectivityResult) {
    //   await loadChatListFromLocal(AppConstants.personal_Chat_Type);
    // }

    // }
  }

  void changeBusinessInsideTab(int index) {
    businessTabIndexSelected.value = index;
  }

  void setReplyMessage(Messages? message) {
    replyMessage?.value = message;
  }

  void onSelectChatTab(int index) {
    selectedChatTabIndex.value = index;
    if (chatMainTabController == null) {
      // Tab controller not yet created — selectedChatTabIndex is stored so
      // that initState in NewChatMainScreen picks it up as initialIndex.
      return;
    }
    chatMainTabController!.animateTo(index);
  }

  void isChatFromBusinessProfile(bool value) {
    chatFromBusinessProfile.value = value;
  }

  void clearMessageControllerCommon() {
    sendMessageController.value.clear();
    isTextFieldEmpty.value = false;
  }

  //
  // Future<void> loadChatListFromLocal(String type) async {
  //   List<ChatList> localChats =
  //       await localStorageHelper.getChatListFromLocal(type);
  //   getPersonalChatListModel?.value = GetChatListModel(
  //     success: true,
  //     chatList: localChats,
  //     archived: [],
  //   );
  //   personalChatListResponse.value =
  //       ApiResponse.complete(getPersonalChatListModel?.value);
  // }

  void loadChatListWithType({required GetChatListModel chatListModel}) {
    if (chatListModel.type == AppConstants.business_Chat_Type) {
      getBusinessChatListModel?.value = chatListModel;
      businessChatListResponse.value = ApiResponse.complete(chatListModel);
    } else if (chatListModel.type == AppConstants.personal_Chat_Type) {
      getPersonalChatListModel?.value = chatListModel;
      personalChatListResponse.value = ApiResponse.complete(chatListModel);
    } else if (chatListModel.type == AppConstants.group_Chat_Type) {
      getGroupChatListModel?.value = chatListModel;
      groupChatListResponse.value =
          ApiResponse.complete(getGroupChatListModel?.value);
    } else if (chatListModel.type == AppConstants.order_Chat_Type) {
      getOrderChatListModel?.value = chatListModel;
      orderChatListResponse.value =
          ApiResponse.complete(getOrderChatListModel?.value);
    } else {
      getPersonalChatListModel?.value = chatListModel;
      personalChatListResponse.value = ApiResponse.complete(chatListModel);
    }
  }

  /// Locally update the last message in all chat list models so the chat list
  /// reflects the sent message immediately (without waiting for a server round-trip).
  void _updateChatListLastMessage(
    String? conversationId,
    String? lastMessage,
    String? lastMessageType,
    String? updatedAt,
  ) {
    if (conversationId == null) return;

    void _patchList(Rx<GetChatListModel>? model) {
      final list = model?.value.chatList;
      if (list == null) return;
      for (final chat in list) {
        if (chat?.conversationId == conversationId) {
          chat?.lastMessage = lastMessage;
          chat?.lastMessageType = lastMessageType;
          if (updatedAt != null) chat?.updatedAt = updatedAt;
          break;
        }
      }
      model?.refresh();
    }

    _patchList(getPersonalChatListModel);
    _patchList(getPersonalFilteredChatListModel);
    _patchList(getBusinessChatListModel);
    _patchList(getGroupChatListModel);
    _patchList(getOrderChatListModel);
  }

  void onSearchChatList(String searchQuery) {
    if (selectedChatTabIndex.value == 0) {
      List<ChatList?>? fullChatList =
          getPersonalFilteredChatListModel?.value.chatList;

      if (searchQuery.isNotEmpty) {
        List<ChatList?> filteredList = fullChatList
                ?.where((e) =>
                    (e?.sender?.name?.toLowerCase().contains(searchQuery) ??
                        false))
                .toList() ??
            [];
        getPersonalChatListModel?.value.chatList = filteredList;
        loadChatListWithType(chatListModel: getPersonalChatListModel!.value);
      } else {
        // if empty query, show full list
        loadChatListWithType(
            chatListModel: getPersonalFilteredChatListModel!.value);
      }
    } else if (selectedChatTabIndex.value == 1) {
    } else if (selectedChatTabIndex.value == 2) {}
  }

  Future<void> saveSingleMessageToLocal(String conversationId, Messages msg,
      [Map<String, dynamic>? params]) async {
    if (conversationId.isEmpty) return;
    if (params != null) {
      // Outgoing message with send params — mark as pending for offline retry.
      msg.sendPendingMsgParams = params;
      await localStorageHelper.saveSingleMessageToConversationId(
          conversationId, msg,
          sendStatus: "pending");
    } else {
      // Received message or already-sent message — save without pending status.
      await localStorageHelper.saveSingleMessageToConversationId(
          conversationId, msg);
    }
  }

  /// Re-send locally queued pending messages for a conversation. Typically
  /// called when the user reopens a chat that had messages stuck in pending
  /// (e.g. media that couldn't be uploaded last time). Text-like messages
  /// are also drained by PendingMessageDrainer on connectivity change.
  Future<void> sendOfflineMessage(
    String conversationId,
  ) async {
    if (conversationId.isEmpty) return;
    if (_drainingConversations.contains(conversationId)) return;
    _drainingConversations.add(conversationId);
    try {
      await _sendOfflineMessageInternal(conversationId);
    } finally {
      _drainingConversations.remove(conversationId);
    }
  }

  Future<void> _sendOfflineMessageInternal(String conversationId) async {
    List<Map<String, dynamic>> data =
        await localStorageHelper.getUnsentMessages(conversationId);

    if (data.isEmpty) return;

    // Iterate oldest-first so each retry gets a server createdAt in the same
    // order the user queued them offline. Reversing here made the last item
    // hit the server first, inverting the visible chronological order once
    // the pending rows were replaced by server-authoritative ones.
    for (int i = 0; i < data.length; i++) {
      final String type = data[i]["message_type"]?.toString() ?? '';
      final bool hasFilePaths = data[i]['pendingFilePaths'] is List &&
          (data[i]['pendingFilePaths'] as List).isNotEmpty;
      final bool hasParams = data[i]['sendPendingMsgParams'] != null;
      if (!hasParams) continue;

      // Audio / document queued offline save their local paths so the
      // drainer can rebuild MultipartFile parts on retry. Without this
      // branch these types silently fell back to the plain text retry
      // path, which does a JSON POST and so delivered no file.
      if ((type == 'audio' || type == 'document') && hasFilePaths) {
        final List<String> paths = (data[i]['pendingFilePaths'] as List)
            .map((e) => e.toString())
            .toList();
        final String tempId = data[i]['_id']?.toString() ?? '';
        localStorageHelper.markPendingInFlight(tempId);
        try {
          await _retryPendingFileMessage(
            params:
                Map<String, dynamic>.from(data[i]['sendPendingMsgParams']),
            filePaths: paths,
            messageId: tempId,
            fileName: data[i]['docFileName']?.toString(),
          );
        } finally {
          localStorageHelper.clearPendingInFlight(tempId);
        }
      } else if (type == 'document' ||
          type == 'text' ||
          type == 'contact' ||
          type == 'location' ||
          type == 'live_location') {
        if (data[i]['_id'] != null) {
          // Awaited so the per-conversation drain guard is only released
          // after the HTTP ack + Hive replace lands. Otherwise a second
          // drain event could fire during the in-flight window and resend.
          await sendOfflineMessageToServer(
              Map<String, dynamic>.from(data[i]['sendPendingMsgParams']),
              data[i]['_id'].toString());
        }
      } else if ((type == 'image' || type == 'video') && hasFilePaths) {
        final List<File> listFiles = (data[i]['pendingFilePaths'] as List)
            .map((e) => File(e.toString()))
            .toList();
        final String tempId = data[i]['_id']?.toString() ?? '';
        // Block concurrent pagination saves from re-preserving this pending
        // row while the retry is in flight. Cleared after retry + Hive
        // replace completes (or the call throws).
        localStorageHelper.markPendingInFlight(tempId);
        try {
          await generateUploadUrlsApi(
              params:
                  Map<String, dynamic>.from(data[i]['sendPendingMsgParams']),
              listFile: listFiles,
              userId: [data[i]['userId']?.toString() ?? ""],
              conversationId: data[i][ApiKeys.conversation_id]?.toString(),
              // The caption was saved into the Messages.message field
              // (JSON key "message"). Reading "comments" here dropped the
              // caption on every retry, so the receiver only saw the media.
              commands: data[i]["message"]?.toString(),
              messageType: type,
              isPendingMessage: true,
              messageId: tempId);
        } finally {
          localStorageHelper.clearPendingInFlight(tempId);
        }
      }
    }
  }

  Future<bool?> sendOfflineMessageToServer(
      Map<String, dynamic> params, String messageId) async {
    try {
      if (replyMessage?.value?.id != null) {
        replyMessage?.value = Messages();
      }

      ResponseModel responseModel =
          await ChatViewRepo().sendMessageToUser(params);
      clearMessageControllerCommon();
      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;

        Messages? message = Messages.fromJson(data['data']);
        if (message.subType != "comment") {
          Messages? msg = getListOfMessageData
              ?.firstWhereOrNull((element) => element.id == messageId);
          if (msg != null) {
            getListOfMessageData?.remove(msg);
          }
          // Dedup: the newMessageReceived socket echo may have already
          // inserted this server message while the HTTP ack was in flight.
          final alreadyExists = message.id != null &&
              (getListOfMessageData?.any((m) => m.id == message.id) ?? false);
          if (!alreadyExists) {
            getListOfMessageData?.add(message);
          }
          getListOfMessageResponse.value =
              ApiResponse.complete(getListOfMessageData);
          // Replace the local pending entry with the server-authoritative
          // message so next local-first load shows the right id/status.
          await localStorageHelper.replacePendingWithServerMessage(
              params[ApiKeys.conversation_id]?.toString() ?? '',
              messageId,
              message);
        }
        scrollDown();
        clearMessageControllerCommon();
        return true;
      } else {
        clearMessageControllerCommon();
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {}
    return null;
  }

  void listenUserNewMessages(
      {required String conversationId, required String userId}) {
    userOpenConversationId.value = conversationId;
    userOpenUserId.value = userId;
    // Set current user's online status from cache
    userOnlineStatus.value =
        onlineUserIds.contains(userId) ? "Online" : "Offline";
    // Paint cached history immediately (WhatsApp-style offline-first).
    // Always fire-and-forget — cheap Hive read, and calling it on every
    // entry keeps the screen in sync with disk even when the caller did
    // not run getLocalConversation first, or when leaveConversation never
    // ran between opens. loadOfflineMessages publishes a complete() with
    // the cached list, so the UI renders history instantly — even when
    // offline and the socket emit below never gets a reply.
    if (conversationId.isNotEmpty) {
      unawaited(loadOfflineMessages(conversationId));
    }
    emitEvent(ChatEmitEvents.screenRoom,
        {ApiKeys.conversation_id: "${conversationId}"});
    // Mark conversation as read on the server
    chatSocket.emitEvent(ChatEmitEvents.markConversationRead,
        {ApiKeys.conversation_id: conversationId});
    addConversationOnce(conversationId);
    // Reset message status for new conversation (avoid stale ticks)
    readMessageStatus.value = '';
    // Reset typing indicator for new conversation
    typingText.value = '';
    _typingHideTimers.forEach((_, timer) => timer.cancel());
    _typingHideTimers.clear();
  }

  /// Call this when the user leaves a conversation (back button, dispose, etc.).
  /// Tells the server the user is no longer viewing any conversation so new
  /// incoming messages get "delivered" status instead of "read".
  void leaveConversation() {
    debugPrint('[CHAT_DEBUG] leaveConversation() called — emitting screenRoom: online');
    userOpenConversationId.value = '';
    userOpenUserId.value = '';
    readMessageStatus.value = '';
    typingText.value = '';
    userOnlineStatus.value = '';
    _typingHideTimers.forEach((_, timer) => timer.cancel());
    _typingHideTimers.clear();
    // Tell the server the user is online but not in any conversation
    chatSocket.emitEvent(
        ChatEmitEvents.screenRoom, {ApiKeys.conversation_id: "online"});
  }

  /// Check if a user is currently online (for chat list dots).
  bool isUserOnline(String? userId) =>
      userId != null && onlineUserIds.contains(userId);

  /// Emit typing indicator (debounced — max once per second per guide)
  void emitTyping(String conversationId) {
    if (_typingDebounceTimer?.isActive ?? false) return;
    chatSocket.emitEvent(ChatEmitEvents.isTyping,
        {ApiKeys.conversation_id: conversationId});
    _typingDebounceTimer = Timer(const Duration(seconds: 1), () {});
  }

  /// Increment unread count by 1 for a conversation in all chat list models
  void _incrementChatListUnreadCount(String conversationId) {
    for (final model in [
      getPersonalChatListModel,
      getBusinessChatListModel,
      getGroupChatListModel,
      getOrderChatListModel,
    ]) {
      final chatList = model?.value.chatList;
      if (chatList == null) continue;
      for (final chat in chatList) {
        if (chat?.conversationId == conversationId) {
          chat?.unreadCount = (chat.unreadCount ?? 0) + 1;
        }
      }
      model?.refresh();
    }
  }

  /// Update unread count in chat list models
  void _updateChatListUnreadCount(String conversationId, num count) {
    for (final model in [
      getPersonalChatListModel,
      getBusinessChatListModel,
      getGroupChatListModel,
      getOrderChatListModel,
    ]) {
      final chatList = model?.value.chatList;
      if (chatList == null) continue;
      for (final chat in chatList) {
        if (chat?.conversationId == conversationId) {
          chat?.unreadCount = count;
        }
      }
      model?.refresh();
    }
  }

  void addConversationOnce(String conversationId) {
    // localStorageHelper.putConversation(conversationId);
    if (!openedConversation.contains(conversationId)) {
      openedConversation.add(conversationId);
    }
  }
  /// Check if the scroll position is near the bottom (within 150px).
  bool get _isNearBottom {
    if (!scrollController.hasClients) return true;
    if (scrollController.positions.length != 1) return true;
    // In a reversed list, minScrollExtent is the bottom (newest messages)
    return scrollController.offset <= 150;
  }

  /// Scroll to bottom if user is near bottom, otherwise increment unread badge.
  Future<void> scrollDown({bool force = false}) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (!scrollController.hasClients) return;
    if (scrollController.positions.length != 1) return;

    if (force || _isNearBottom) {
      unreadNewMessageCount.value = 0;
      isUserScrolledUp.value = false;
      scrollController.animateTo(
        scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      // User is reading old messages — don't interrupt, just show badge
      unreadNewMessageCount.value++;
    }
  }

  /// Force scroll to bottom and clear badge — called from scroll-to-bottom FAB.
  void jumpToBottom() {
    if (!scrollController.hasClients) return;
    if (scrollController.positions.length != 1) return;
    unreadNewMessageCount.value = 0;
    isUserScrolledUp.value = false;
    scrollController.animateTo(
      scrollController.position.minScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }


  Future<List<Messages>> loadOfflineMessages(String conversationId) async {
    if (conversationId.isEmpty) return [];
    final localMessages =
        await localStorageHelper.getMessagesByConversationId(conversationId);
    // Deduplicate by message ID from local storage (may contain duplicates
    // from previous sessions where send + socket both saved the same message).
    final seen = <String>{};
    final deduped = <Messages>[];
    for (final m in localMessages) {
      final id = m.id ?? '';
      if (id.isEmpty || seen.add(id)) {
        deduped.add(m);
      }
    }
    if (deduped.isNotEmpty) {
      await _resolveLocalMediaPaths(deduped);
    }
    // Always settle the response — even when the cache is empty — so the
    // chat screen doesn't stay stuck on its "Initial"-state spinner while
    // offline (the server pagination call will never come back).
    // getListOfMessageData reads from the response's .data list, so we
    // install the fresh list through the observable.
    getListOfMessageResponse.value = ApiResponse.complete(deduped);
    if (deduped.isNotEmpty) scrollDown();
    return deduped;
  }

  Future<bool?> sendProductMessages(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await ChatViewRepo().sendMessageToUserLargeFile(params);
      clearMessageControllerCommon();
      if (responseModel.isSuccess) {

        final data = responseModel.response?.data;
        Messages? message = Messages.fromJson(data['data']);
        if (message.subType != "comment") {
          final alreadyExists = message.id != null &&
              (getListOfMessageData?.any((m) => m.id == message.id) ?? false);
          if (!alreadyExists) {
            getListOfMessageData?.add(message);
          }
          getListOfMessageResponse.value =
              ApiResponse.complete(getListOfMessageData);
          scrollDown();
          saveSingleMessageToLocal(
              message.conversationId ?? '', message);
        } else if (message.subType == 'comment') {
          getMediaMsgCommentsModel?.value.comments?.insert(
              0,
              Comments(
                message: message.message,
                likesCount: 0,
                sender: cmdImport.Sender(
                    name: message.sender?.name,
                    profileImage: message.sender?.profileImage),
                updatedAt: message.updatedAt,
                myComment: true,
              ));
        }

        if (chatFromBusinessProfile.value) {
          canPopBusiness.value = true;
        }
        scrollDown();

        clearMessageControllerCommon();
        return true;
      } else {
        clearMessageControllerCommon();
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: e.toString());
    }
    return null;
  }



  Future<void> getLocalConversation(String conversationId, userId,
      [String? otherUserId, String? name]) async {
    // Clear previous conversation data to prevent stale messages from mixing in.
    getListOfMessageResponse.value = ApiResponse.initial('Initial');
    // Load cached messages first for instant UI. Awaiting here means the
    // screen either paints the cached list or settles on an empty-complete
    // state before the async socket emit runs — so we never strand the UI
    // on the loading spinner when the network is down.
    await loadOfflineMessages(conversationId);
    // }
    // else if (openedConversation.contains(conversationId)) {
    //   loadOfflineMessages(conversationId);
    // }
    // else {
    // if(chatList.isEmpty){

    Map<String,dynamic> params={
      if(conversationId.isEmpty)
        ApiKeys.other_user_id: otherUserId
      else
        ApiKeys.conversation_id: conversationId,
      ApiKeys.page: 1,
      ApiKeys.is_online_user: userId,
      ApiKeys.per_page_message: 30,
      if (name != null && name == "BlueEra Orders")
        ApiKeys.orders_conversation: true
    };
    //    Map<String,dynamic> params={
    //       if(conversationId.isEmpty)
    //         ApiKeys.other_user_id: otherUserId
    //       else
    //         ApiKeys.conversation_id: conversationId,
    //       ApiKeys.page: 1,
    //       ApiKeys.is_online_user: userId,
    //       ApiKeys.per_page_message: 30,
    //       if (name != null && name == "BlueEra Orders")
    //         ApiKeys.orders_conversation: true
    //     };
    emitEvent(
        ChatEmitEvents.messageReceived,params);
    // Drain any pending messages for this conversation in the background —
    // text-like ones will be retried via repo, media via generateUploadUrlsApi.
    // Fire and forget; errors are handled inside the drainer/offline methods.
    if (conversationId.isNotEmpty) {
      unawaited(PendingMessageDrainer.instance.drainNow());
      unawaited(sendOfflineMessage(conversationId));
    }
    // }

    // }
  }

  void emitEvent(String event, dynamic data,
      [ String? conversationId]) async {
    if (event == ChatEmitEvents.messageReceived &&
        (conversationId ?? "").isNotEmpty &&
        conversationId != userOpenConversationId.value) {
      // Only clear when we're explicitly switching to a different conversation.
      // Bare calls (no conversationId arg) must NOT wipe the cached list —
      // that would strand the offline UI on the spinner after loadOfflineMessages
      // just populated it. The pre-.value comparison also compared a String to
      // an RxString object, which was always unequal.
      getListOfMessageResponse.value = ApiResponse.initial('Initial');
    }
    if (event == ChatEmitEvents.ChatList) {
      final type = data[ApiKeys.type];
      // Local-first: paint cached chat list instantly so offline users still
      // see their history. The socket response will overwrite this once it
      // arrives with authoritative data.
      try {
        if (type is String && type.isNotEmpty) {
          final List<ChatList> localChats =
              await localStorageHelper.getChatListFromLocal(type);
          if (localChats.isNotEmpty) {
            loadChatListWithType(
                chatListModel: GetChatListModel(
              type: type,
              success: true,
              chatList: List<ChatList?>.from(localChats),
              archived: [],
            ));
          }
        }
      } catch (e) {
        debugPrint('emitEvent getChatListFromLocal error: $e');
      }

      Map<String, dynamic> dataParams = {ApiKeys.type: data[ApiKeys.type]};
      chatSocket.emitEvent(event, dataParams);
      chatSocket.emitEvent(
          ChatEmitEvents.screenRoom, {ApiKeys.conversation_id: "online"});
    } else {
      chatSocket.emitEvent(event, data);
    }
  }

  // Future<void> loadAllChatListFromLocal() async {
  //   try {
  //     final allChats = await localStorageHelper.getAllChatListsFromLocal();
  //
  //     for (final entry in allChats.entries) {
  //       loadChatListWithType(
  //           chatListModel: GetChatListModel(
  //         type: entry.key,
  //         success: true,
  //         chatList: List<ChatList?>.from(entry.value),
  //         archived: [],
  //       ));
  //     }
  //   } catch (e) {
  //     debugPrint('loadAllChatListFromLocal error: $e');
  //   }
  // }

  void disposeSocket() {
    socketConnected.value = false;
    socketConnectedCalled.value = false;
    chatSocket.disposeSocket();
  }

  List<Map<String, dynamic>>? contactListParamsData;
  String? findServiceByContactParamsType;

  void loadContactsFromLocalStorage(Map<String, dynamic> value) {
    contactsListModel?.value = ContactListModel.fromJson(value);
    viewContactsListResponse.value = ApiResponse.complete(value);
  }

  /// Try to hydrate the contacts model from Hive without hitting the network.
  /// Returns true when cache was found and the UI was pointed at it.
  Future<bool> hydrateContactsFromCache() async {
    if (contactsListModel?.value.data != null) {
      viewContactsListResponse.value =
          ApiResponse.complete(contactsListModel?.value);
      return true;
    }
    final cached = await localStorageHelper.getContacts();
    if (cached == null) return false;
    contactsListModel?.value = ContactListModel.fromJson(cached);
    viewContactsListResponse.value =
        ApiResponse.complete(contactsListModel?.value);
    return true;
  }

  /// Upload contacts to API and save response to Hive.
  /// Memory → Hive → API, in that order.
  Future<void> uploadContacts(List<Map<String, dynamic>> params) async {
    contactListParamsData = params;

    // Already loaded in memory — skip everything
    if (contactsListModel?.value.data != null) {
      viewContactsListResponse.value =
          ApiResponse.complete(contactsListModel?.value);
      return;
    }

    // Hive cache — lets us render the contact list offline after the first
    // successful sync. Callers who want a fresh snapshot use refreshContacts.
    final cached = await localStorageHelper.getContacts();
    if (cached != null) {
      contactsListModel?.value = ContactListModel.fromJson(cached);
      viewContactsListResponse.value =
          ApiResponse.complete(contactsListModel?.value);
      return;
    }

    // No cache yet — hit the API and persist the response for next time.
    ResponseModel responseModel =
        await ChatViewRepo().getConnectionsSync(params);

    if (responseModel.isSuccess) {
      final data = responseModel.response?.data;
      if (data is Map<String, dynamic>) {
        await localStorageHelper.saveContacts(data);
      }
      contactsListModel?.value = ContactListModel.fromJson(data);
      viewContactsListResponse.value = ApiResponse.complete(responseModel);
    } else {
      commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong);
    }
  }

  /// Force refresh contacts from API (called by refresh button).
  /// Always hits the network; updates the Hive cache on success.
  Future<void> refreshContacts(List<Map<String, dynamic>> params) async {
    contactListParamsData = params;
    viewContactsListResponse.value = ApiResponse.initial('Initial');

    ResponseModel responseModel =
        await ChatViewRepo().getConnectionsSync(params);

    if (responseModel.isSuccess) {
      final data = responseModel.response?.data;
      if (data is Map<String, dynamic>) {
        await localStorageHelper.saveContacts(data);
      }
      contactsListModel?.value = ContactListModel.fromJson(data);
      viewContactsListResponse.value = ApiResponse.complete(responseModel);
    } else {
      // Fallback to whatever we already have so the list doesn't blank out.
      if (contactsListModel?.value.data != null) {
        viewContactsListResponse.value =
            ApiResponse.complete(contactsListModel?.value);
      } else {
        final cached = await localStorageHelper.getContacts();
        if (cached != null) {
          contactsListModel?.value = ContactListModel.fromJson(cached);
          viewContactsListResponse.value =
              ApiResponse.complete(contactsListModel?.value);
        } else {
          commonSnackBar(
              message: responseModel.message ?? AppStrings.somethingWentWrong);
        }
      }
    }
  }

  Future<void> setContact(String type,List<Map<String, dynamic>> params)async{
    contactListParamsData=params;
    await findServiceByContacts(type, params);
  }
  Future<void> reloadContact()async{

    await findServiceByContacts(findServiceByContactParamsType??'',null);
  }
  Future<void> findServiceByContacts(String type,List<Map<String, dynamic>>? contactList) async {
    getServiceByContactResponse.value=ApiResponse.initial("Initial");

    findServiceByContactParamsType=type;
    final params={
      ApiKeys.profile_type: type,
      ApiKeys.contact_list:contactList??contactListParamsData
    };
      ResponseModel responseModel =
          await ChatViewRepo().findServiceByContactApi(params);
      if (responseModel.isSuccess) {
        final List<dynamic> listOf = responseModel.data ?? [];

        findProfessionalContactList.value = listOf
            .map((e) => ProfessionalContact.fromJson(e as Map<String, dynamic>))
            .toList();

        getServiceByContactResponse.value=ApiResponse.complete(findProfessionalContactList);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        getServiceByContactResponse.value=ApiResponse.error(responseModel.message ?? AppStrings.somethingWentWrong);

      }
  }

  Future<void> loadGroupConnections(
      {int limit = 20, int offset = 0, String? search}) async {
    try {
      viewContactsListResponse.value = ApiResponse.initial('Initial');
      final Map<String, dynamic> query = {
        'limit': limit,
        'offset': offset,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      ResponseModel responseModel =
          await ChatViewRepo().getGroupConnectionsSync(query);
      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;

        List<dynamic>? items;
        if (data is List) {
          items = data;
        } else if (data is Map<String, dynamic>) {
          final inner = data['data'];
          if (inner is List) items = inner;
        }
        groupConnections.value = (items ?? []).cast<Map<String, dynamic>>();
        viewContactsListResponse.value = ApiResponse.complete(groupConnections);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        viewContactsListResponse.value = ApiResponse.error(
            responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      viewContactsListResponse.value = ApiResponse.error('error');
    }
  }

  Future<void> getLatestChat() async {
    try {
      ResponseModel responseModel = await ChatViewRepo().getLatestChatRepo();
      if (responseModel.isSuccess) {
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {}
  }

  Future<void> getChatRequestList() async {
    try {
      ResponseModel responseModel = await ChatViewRepo().getChatRequestList();
      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;
        getChatRequestListModel?.value = GetChatRequestListModel.fromJson(data);
        chatMessageRequestResponse.value = ApiResponse.complete(responseModel);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      chatMessageRequestResponse.value = ApiResponse.error('error');
    }
  }

  Future<void> getDetailsChatRequestPerson(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await ChatViewRepo().getDetailsChatRequestPerson(params);
      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;

        getChatRequestProfileDetailsModel?.value =
            GetChatRequestProfileDetailsModel.fromJson(data);
        chatMessageRequestResponse.value = ApiResponse.complete(responseModel);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      chatMessageRequestResponse.value = ApiResponse.error('error');
    }
  }

  Future<void> acceptOrRejectRequest(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await ChatViewRepo().acceptOrDeclineRequest(params);
      if (responseModel.isSuccess) {
        chatSocket.emitEvent(ChatEmitEvents.ChatList,
            {ApiKeys.type: AppConstants.personal_Chat_Type});
        getChatRequestList();
        chatMessageRequestResponse.value = ApiResponse.complete(responseModel);
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      chatMessageRequestResponse.value = ApiResponse.error('error');
    }
  }

  Future<void> startLiveLocationTracking(Duration duration) async {
    final permission = await Permission.locationWhenInUse.request();
    if (!permission.isGranted) return;
    Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
    );
    await LiveTrackingSocketService().connectToSocket(LatLng(pos.latitude, pos.longitude));

     Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // 🔥 10 meters move = update
      ),
    ).listen((Position pos) {
      LiveTrackingSocketService().emitEvent(
        LiveTrackEmitEvents.updateLocation,
        {
          ApiKeys.coordinates: [pos.longitude, pos.latitude],
          ApiKeys.availabilityStatus: "OPEN",
        },
      );
    });
    Timer(duration, (){
      LiveTrackingSocketService().disconnectSocket();
    });
  }

  //
  void stopLiveLocationTracking() {
    LiveTrackingSocketService().disconnectSocket();
  }
  Duration labelToDuration(String label) {
    switch (label) {
      case "15min":
        return const Duration(minutes: 15);
      case "1h":
        return const Duration(hours: 1);
      case "8h":
        return const Duration(hours: 8);
      default:
      // fallback: "30min", "45min" madhiri iruntha
        if (label.endsWith("min")) {
          final mins = int.tryParse(label.replaceAll("min", ""));
          return Duration(minutes: mins ?? 0);
        }
        if (label.endsWith("h")) {
          final hrs = int.tryParse(label.replaceAll("h", ""));
          return Duration(hours: hrs ?? 0);
        }
        return Duration.zero;
    }
  }
  List<String> getMentionedUserIds({
    required String message,
    required List<GroupMembersListModel> members,
  }) {
    final RegExp mentionRegExp = RegExp(r'@(\w+)');

    final matches = mentionRegExp.allMatches(message);

    List<String> mentionedIds = [];

    for (final match in matches) {
      final mentionedName = match.group(1)?.toLowerCase().trim();

      if (mentionedName == null) continue;

      final user = members.firstWhereOrNull(
            (member) => member.name?.toLowerCase().trim() == mentionedName,
      );

      if (user?.id != null) {
        mentionedIds.add(user!.id!);
      }
    }

    return mentionedIds;
  }
  /// Build a local pending-message stand-in for a message that can't be sent
  /// right now (offline or API failure). Persists to Hive with sendStatus
  /// "pending" and its retry params so the drainer can re-fire it later.
  Messages _buildPendingMessage(
      Map<String, dynamic> params, String? fileName) {
    final now = DateTime.now().toUtc();
    final isoTime = now.toIso8601String();
    // Populate senderId + sender from the signed-in user so the pending card
    // renders identically to a server-returned message. Without these, the
    // fallback in MessageCard (currentUserId != senderId) flips the bubble
    // to the receiver side whenever myMessage gets lost across a Hive
    // round-trip, and tick marks / avatar / name stay blank until the
    // server response overwrites the entry.
    return Messages(
        docFileName: fileName,
        id: "${isoTime}_${params[ApiKeys.conversation_id]}",
        messageType: params[ApiKeys.message_type],
        sharedContactName: params[ApiKeys.message_type] == "contact"
            ? params[ApiKeys.shared_contact_name]
            : null,
        sharedContactNumber: params[ApiKeys.message_type] == "contact"
            ? params[ApiKeys.shared_contact_number]
            : null,
        sendStatus: "pending",
        status: "sent",
        message: params[ApiKeys.message],
        latitude: params[ApiKeys.message_type] == "location"
            ? params[ApiKeys.latitude]
            : null,
        longitude: params[ApiKeys.message_type] == "location"
            ? params[ApiKeys.longitude]
            : null,
        myMessage: true,
        senderId: userId,
        sender: messageModel.Sender(
          id: userId,
          name: userNameGlobal,
          profileImage: userProfileGlobal,
        ),
        conversationId: params[ApiKeys.conversation_id],
        createdAt: isoTime,
        sendPendingMsgParams: params);
  }

  /// Optimistically show a pending message in the open conversation, persist
  /// it to Hive, and patch the chat list preview. Returns the temp message.
  Future<Messages> _enqueuePendingMessage(
      Map<String, dynamic> params, String? fileName) async {
    final message = _buildPendingMessage(params, fileName);
    getListOfMessageData?.add(message);
    getListOfMessageResponse.value =
        ApiResponse.complete(getListOfMessageData);
    await saveSingleMessageToLocal(
        params[ApiKeys.conversation_id] ?? '', message, params);
    _updateChatListLastMessage(
      params[ApiKeys.conversation_id],
      message.message,
      message.messageType,
      message.createdAt,
    );
    return message;
  }

  /// Queue an audio / document message for offline retry.
  ///
  /// MultipartFile objects can't be JSON-encoded into Hive, so the offline
  /// path in sendMessage used to silently lose these messages. This helper
  /// stores the raw local file path list in `pendingFilePaths` and a clean
  /// params map (no MultipartFile) in `sendPendingMsgParams`, mirroring
  /// the image/video offline flow. The drainer rebuilds MultipartFile
  /// objects from the paths when it retries.
  Future<void> enqueuePendingFileMessage({
    required String messageType,
    required List<String> filePaths,
    String? conversationId,
    String? otherUserId,
    String? caption,
    String? fileName,
    bool isInitial = false,
  }) async {
    final now = DateTime.now().toUtc();
    final isoTime = now.toIso8601String();
    final convKey = conversationId ?? '';
    final String tempId = "${isoTime}_$convKey";

    final Map<String, dynamic> params = {
      if (isInitial)
        ApiKeys.other_user_id: otherUserId
      else
        ApiKeys.conversation_id: conversationId,
      if (caption != null && caption.isNotEmpty) ApiKeys.message: caption,
      ApiKeys.message_type: messageType,
    };

    final message = Messages(
      docFileName: fileName,
      id: tempId,
      messageType: messageType,
      sendStatus: "pending",
      status: "sent",
      message: caption,
      myMessage: true,
      senderId: userId,
      sender: messageModel.Sender(
        id: userId,
        name: userNameGlobal,
        profileImage: userProfileGlobal,
      ),
      conversationId: conversationId,
      createdAt: isoTime,
      pendingFilePaths: filePaths,
      url: filePaths.map((p) => MessageMediaUrl(url: p)).toList(),
      sendPendingMsgParams: params,
    );

    getListOfMessageData?.add(message);
    getListOfMessageResponse.value =
        ApiResponse.complete(getListOfMessageData);
    await saveSingleMessageToLocal(convKey, message, params);
    _updateChatListLastMessage(
      conversationId,
      caption,
      messageType,
      isoTime,
    );
  }

  /// Retry an audio / document pending row by rebuilding MultipartFile parts
  /// from its saved local paths, then calling the standard send endpoint.
  Future<void> _retryPendingFileMessage({
    required Map<String, dynamic> params,
    required List<String> filePaths,
    required String messageId,
    String? fileName,
  }) async {
    try {
      if (replyMessage?.value?.id != null) {
        replyMessage?.value = Messages();
      }
      final List<dio.MultipartFile> parts = [];
      for (final p in filePaths) {
        if (p.isEmpty) continue;
        final name = p.split('/').last;
        parts.add(await dio.MultipartFile.fromFile(p, filename: name));
      }
      if (parts.isEmpty) return;
      final retryParams = Map<String, dynamic>.from(params)
        ..[ApiKeys.files] = parts;

      final ResponseModel responseModel =
          await ChatViewRepo().sendMessageToUser(retryParams);
      if (!responseModel.isSuccess) return;

      final data = responseModel.response?.data;
      if (data == null) return;
      final Messages message = Messages.fromJson(data['data']);
      if (message.subType == "comment") return;

      Messages? oldPending = getListOfMessageData
          ?.firstWhereOrNull((element) => element.id == messageId);
      if (oldPending != null) getListOfMessageData?.remove(oldPending);
      final alreadyExists = message.id != null &&
          (getListOfMessageData?.any((m) => m.id == message.id) ?? false);
      if (!alreadyExists) getListOfMessageData?.add(message);
      getListOfMessageResponse.value =
          ApiResponse.complete(getListOfMessageData);
      await localStorageHelper.replacePendingWithServerMessage(
          params[ApiKeys.conversation_id]?.toString() ?? '',
          messageId,
          message);
    } catch (e) {
      debugPrint('_retryPendingFileMessage failed: $e');
    }
  }

  Future<bool?> sendMessage(Map<String, dynamic> params,
      [List<File>? sendFiles, String? fileName]) async {
    if (isSending.value) return null;
    isSending.value = true;
    try {
      params[ApiKeys.tagged_users] = taggedUserIds.join(',');
      taggedUserIds.clear();
      if(params[ApiKeys.message_type]=="live_location"){
       await startLiveLocationTracking(labelToDuration(params[ApiKeys.live_location_validity]));
      }

      clearMessageControllerCommon();

      if (replyMessage?.value?.id != null) {
        replyMessage?.value = Messages();
      }
      final isVideoSend = sendFiles != null &&
          sendFiles.isNotEmpty &&
          params[ApiKeys.message_type] == 'video';

      // Offline branch — skip the network call entirely, queue locally,
      // and let PendingMessageDrainer flush when connectivity returns.
      // Media (image/video) skips this branch: generateUploadUrlsApi owns
      // its own retry path with the pending file list.
      if (!isVideoSend &&
          (sendFiles == null || sendFiles.isEmpty) &&
          !await checkInternetStatus()) {
        await _enqueuePendingMessage(params, fileName);
        return true;
      }

      if (isVideoSend) {
        sendLoadingFile.value = Messages(
            sendLoadingFile: sendFiles,
            myMessage: true,
            messageType: params[ApiKeys.message_type]);
        getListOfMessageData?.add(sendLoadingFile.value);


        getListOfMessageResponse.value =
            ApiResponse.complete(getListOfMessageData);
      }
      ResponseModel responseModel =
          await ChatViewRepo().sendMessageToUser(params);
      if (responseModel.isSuccess) {
        // For video: swap loading placeholder with real message in a single update
        if (isVideoSend) {
          if (getListOfMessageData != null && getListOfMessageData!.isNotEmpty) {
            getListOfMessageData!.removeLast();
          }
          // Don't reassign getListOfMessageResponse here — batch with the add below
        }

        final data = responseModel.response?.data;
        Messages? message = Messages.fromJson(data['data']);
        if (message.subType != "comment") {
          // Reset conversation-level status to match the new message's actual
          // status from the server. Without this, a stale 'read' value from a
          // previous messageStatusUpdate would make new messages show blue ticks
          // even when the receiver has already left the conversation.
          if (message.status != null) {
            readMessageStatus.value = message.status!;
          }

          // Deduplicate: newMessageReceived socket event may have already added this

          final alreadyExists = message.id != null &&
              (getListOfMessageData?.any((m) => m.id == message.id) ?? false);
          if (!alreadyExists) {
            getListOfMessageData?.add(message);


          }
          // Single rebuild: removes loading placeholder + adds real message at once
          getListOfMessageResponse.value =
              ApiResponse.complete(getListOfMessageData);
          saveSingleMessageToLocal(
              params[ApiKeys.conversation_id], message);
          // Update chat list locally so last message is visible immediately
          _updateChatListLastMessage(
            params[ApiKeys.conversation_id],
            message.message,
            message.messageType,
            message.updatedAt ?? message.createdAt,
          );
        } else if (message.subType == 'comment') {
          getMediaMsgCommentsModel?.value.comments?.insert(
              0,
              Comments(
                message: message.message,
                likesCount: 0,
                sender: cmdImport.Sender(
                    name: message.sender?.name,
                    profileImage: message.sender?.profileImage),
                updatedAt: message.updatedAt,
                myComment: true,
              ));
        }
        if (chatFromBusinessProfile.value) {
          canPopBusiness.value = true;
        }
        scrollDown();

        clearMessageControllerCommon();
        return true;
      } else {
        clearMessageControllerCommon();
        // Non-success response (network error, 5xx, etc.): for non-media
        // messages, persist as pending so the drainer can retry. Media
        // messages fall through with a snackbar because their upload path
        // is separate.
        final isMediaPayload = (sendFiles != null && sendFiles.isNotEmpty) ||
            params[ApiKeys.message_type] == 'video' ||
            params[ApiKeys.message_type] == 'image';
        if (!isMediaPayload) {
          await _enqueuePendingMessage(params, fileName);
          return true;
        }
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      clearMessageControllerCommon();
      final isMediaPayload = (sendFiles != null && sendFiles.isNotEmpty) ||
          params[ApiKeys.message_type] == 'video' ||
          params[ApiKeys.message_type] == 'image';
      if (!isMediaPayload) {
        await _enqueuePendingMessage(params, fileName);
      }
      if (sendFiles != null &&
          sendFiles.isNotEmpty &&
          params[ApiKeys.message_type] == 'video') {
        if (getListOfMessageData != null && getListOfMessageData!.isNotEmpty) {
          getListOfMessageData!.removeLast();
        }
        getListOfMessageResponse.value =
            ApiResponse.complete(getListOfMessageData);
      }
    } finally {
      isSending.value = false;
    }
    return null;
  }

  Future<bool> forwardMessageApi(
    Map<String, dynamic> params,
  ) async {
    ResponseModel responseModel =
        await ChatViewRepo().forwardMessageApi(params);
    clearMessageControllerCommon();
    if (responseModel.isSuccess) {
      clearMessageControllerCommon();
      return true;
    } else {
      clearMessageControllerCommon();
      commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong);
      return false;
    }
  }

  Future<bool> createGroupApi(Map<String, dynamic> params,
      {bool? isFromFile,
      Map<String, dynamic>? fileParams,
      File? fileSended}) async {
    if (isFromFile != null) {
      ResponseModel responseModel =
          await ChatViewRepo().generateUploadUrlsApi(fileParams!);
      clearMessageControllerCommon();

      if (!responseModel.isSuccess) {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        return false;
      }

      final data = responseModel.response?.data;
      final uploadModel = GenerateUploadUlrModel.fromJson(data);
      generateUploadUlrModel?.value = uploadModel;

      final files = uploadModel.files;

      // Parallel Uploads using Future.wait
      await Future.wait(List.generate(files!.length, (i) {
        final file = fileSended;
        final url = files[i].uploadUrl ?? '';
        final type = files[i].fileType ?? '';
        return uploadFileToS3(file: file!, fileType: type, preSignedUrl: url);
      }));
      List<String> sharedFile = uploadModel.files?.map((element) {
            return element.publicUrl ?? '';
          }).toList() ??
          [];
      params.addAll({
        ApiKeys.group_profile_image: sharedFile,
      });
      ResponseModel responseModelCreas =
          await ChatViewRepo().createNewGroupApi(params);
      if (responseModelCreas.isSuccess) {
        emitEvent(ChatEmitEvents.ChatList, {ApiKeys.type: "group"});
        return true;
      } else {
        commonSnackBar(
            message:
                responseModelCreas.message ?? AppStrings.somethingWentWrong);
        return false;
      }
    } else {
      ResponseModel responseModel =
          await ChatViewRepo().createNewGroupApi(params);

      if (responseModel.isSuccess) {
        emitEvent(ChatEmitEvents.ChatList,
            {ApiKeys.type: AppConstants.group_Chat_Type});
        return true;
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        return false;
      }
    }
  }


  Future<void> getGroupMembersApi(
    Map<String, dynamic> params,
  ) async {
    ResponseModel responseModel =
        await ChatViewRepo().getGroupMembersApi(params);

    if (responseModel.isSuccess) {
      // Ensure data is a List
      List dataList = responseModel.data as List;
      List<GroupMembersListModel> members =
          dataList.map((item) => GroupMembersListModel.fromJson(item)).toList();


      getGroupMembersResponse.value = ApiResponse.complete(members);
      ;
    } else {
      commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong);
    }
  }
  /// Open a chat directly from the chat list without an API call.
  /// All required data is already available from the ChatList object.
  Future<void> openChatFromChatList({
    required String userId,
    required String conversationId,
    required String type,
    String? contactName,
    String? contactNo,
    String? profileImage,
  }) async {
    businessTabIndexSelected.value = 0;
    await getLocalConversation(
        conversationId, userId, userId, contactName ?? '');

    _navigateToChatScreen(
      type: type,
      userId: userId,
      conversationId: conversationId,
      profileImage: profileImage ?? '',
      contactName: contactName ?? '',
      contactNo: contactNo ?? '',
      isFromContactList: false,
    );
  }

  Future<void> checkChatConnectionAndOpenChat(
      {required String userId,bool? isFromContactList,
        bool? isWithProductSend,
        Map<String, dynamic>? shareProductParams,
        String? name,
        String? conductNo,
        String? profile,
      }) async {
    Map<String, dynamic> params = {
      ApiKeys.user_id: userId
    };
    ResponseModel responseModel =
    await ChatViewRepo().checkChatConnectionApi(params);

    if (responseModel.isSuccess) {
      final data = responseModel.response?.data;
      CheckChatConversationModel details =
      CheckChatConversationModel.fromJson(data);
      String conversationId=details.data?.conversationId??'';
      String otherUserId=details.data?.otherUserId??'';
      String chatPersonUserId=userId;
      String contactNo=conductNo??details.data?.sender?.contact??'';
      String contactName=name??details.data?.sender?.name??'';
      String profileImage=profile??details.data?.sender?.profileImage??'';
      String type=details.data?.conversation?.type??'';
      businessTabIndexSelected.value = 0;
      await getLocalConversation(
          conversationId, chatPersonUserId, otherUserId, contactName);

      if (isWithProductSend == true) {
        await sendProductMessages(shareProductParams ?? {});
      }

      _navigateToChatScreen(
        type: type,
        userId: userId,
        conversationId: conversationId,
        profileImage: profileImage,
        contactName: contactName,
        contactNo: contactNo,
        isFromContactList: isFromContactList,
      );
    } else {
      // Offline fallback: try to open from local cache
      final opened = await _tryOpenChatFromLocalCache(
        userId: userId,
        isFromContactList: isFromContactList,
      );
      if (!opened) {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    }
  }

  /// Try to open a chat from locally cached chat list data.
  /// Returns true if a cached conversation was found and opened.
  Future<bool> _tryOpenChatFromLocalCache({
    required String userId,
    bool? isFromContactList,
  }) async {
    // First search in-memory chat lists (already loaded)
    ChatList? cachedChat = _findChatInMemory(userId);

    // // If not in memory, search Hive cache
    // cachedChat ??= await localStorageHelper.findChatByUserId(userId);

    if (cachedChat == null || (cachedChat.conversationId ?? '').isEmpty) {
      return false;
    }

    final conversationId = cachedChat.conversationId ?? '';
    final contactName = cachedChat.sender?.name ?? '';
    final profileImage = cachedChat.sender?.profileImage ?? '';
    final contactNo = cachedChat.sender?.contactNo ?? '';
    final chatPersonUserId = cachedChat.sender?.id ?? '';

    businessTabIndexSelected.value = 0;

    // Load cached messages for instant display (no server fetch)
    getListOfMessageResponse.value = ApiResponse.initial('Initial');
    await loadOfflineMessages(conversationId);
    listenUserNewMessages(conversationId: conversationId, userId: chatPersonUserId);

    // Determine type from cached data — default to personal
    String type = AppConstants.personal_Chat_Type;
    if (cachedChat.isGroup == true) {
      type = AppConstants.group_Chat_Type;
    } else {
      // Check in-memory business chat list
      final businessChats = getBusinessChatListModel?.value.chatList ?? [];
      final isBusiness = businessChats.any(
              (c) => c?.conversationId == conversationId);
      if (isBusiness) type = AppConstants.business_Chat_Type;
    }

    _navigateToChatScreen(
      type: type,
      userId: userId,
      conversationId: conversationId,
      profileImage: profileImage,
      contactName: contactName,
      contactNo: contactNo,
      isFromContactList: isFromContactList,
    );
    return true;
  }

  /// Search in-memory chat lists for a conversation with this userId.
  ChatList? _findChatInMemory(String userId) {
    final allLists = [
      getPersonalChatListModel?.value.chatList,
      getBusinessChatListModel?.value.chatList,
      getGroupChatListModel?.value.chatList,
    ];
    for (final chatList in allLists) {
      if (chatList == null) continue;
      for (final chat in chatList) {
        if (chat?.sender?.id == userId) return chat;
      }
    }
    return null;
  }

  /// Navigate to the appropriate chat screen (personal or business).
  void _navigateToChatScreen({
    required String type,
    required String userId,
    required String conversationId,
    required String profileImage,
    required String contactName,
    required String contactNo,
    bool? isFromContactList,
  }) {
    if (type == AppConstants.business_Chat_Type) {
      if (isFromContactList != null && isFromContactList) {
        Get.off(
              () => BusinessChatScreenUpdated(
            type: type,
            isInitialMessage: conversationId=='',
            userId: userId,
            conversationId: conversationId,
            profileImage: profileImage,
            name: contactName,
            contactNo: contactNo,
          ),
        );
      } else {
        Get.to(
              () => BusinessChatScreenUpdated(
            type: type,
            isInitialMessage: conversationId=='',
            userId: userId,
            conversationId: conversationId,
            profileImage: profileImage,
            name: contactName,
            contactNo: contactNo,
          ),
        );
      }
    } else {
      if (isFromContactList != null && isFromContactList) {
        Get.off(
              () => PersonalChatScreen(
            type: type,
            isInitialMessage: conversationId=='',
            userId: userId,
            conversationId: conversationId,
            profileImage: profileImage,
            name: contactName,
            contactNo: contactNo,
          ),
        );
      } else {
        Get.to(
              () => PersonalChatScreen(
            type: type,
            isInitialMessage: conversationId=='',
            userId: userId,
            conversationId: conversationId,
            profileImage: profileImage,
            name: contactName,
            contactNo: contactNo,
          ),
        );
      }
    }
  }
  Future<Map<String,dynamic>?> checkChatConnection(Map<String, dynamic> params) async {
    ResponseModel responseModel =
        await ChatViewRepo().checkChatConnectionApi(params);

    if (responseModel.isSuccess) {
      final data = responseModel.response?.data;

      NewConvoContactVisitDetails value =
          NewConvoContactVisitDetails.fromJson(data);
      return {
        ApiKeys.conversation_id:value.data?.conversationId,
        ApiKeys.other_user_id:value.data?.otherUserId,
      };
    } else {
      commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong);
      return null;
    }
  }

  Future<bool> updateMessageApi(
    Map<String, dynamic> params,
  ) async {
    try {
      ResponseModel responseModel =
          await ChatViewRepo().updateSingleMessage(params);
      clearMessageControllerCommon();
      if (responseModel.isSuccess) {
        clearMessageControllerCommon();
        return true;
      } else {
        clearMessageControllerCommon();
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);

        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateGroupInfo(
    Map<String, dynamic> params,
  {
  bool? isFromFile,
  bool? isFromCoverImage,
  Map<String, dynamic>? fileParams,
  File? fileSended
  }
  ) async {
    try {
      isEditGroupBtnLoading.value=true;
      if (isFromFile != null||isFromCoverImage!=null) {
        ResponseModel responseModel =
        await ChatViewRepo().generateUploadUrlsApi(fileParams!);
        clearMessageControllerCommon();

        if (!responseModel.isSuccess) {
          commonSnackBar(
              message: responseModel.message ?? AppStrings.somethingWentWrong);
          return false;
        }

        final data = responseModel.response?.data;
        final uploadModel = GenerateUploadUlrModel.fromJson(data);
        generateUploadUlrModel?.value = uploadModel;

        final files = uploadModel.files;

        // Parallel Uploads using Future.wait
        await Future.wait(List.generate(files!.length, (i) {
          final file = fileSended;
          final url = files[i].uploadUrl ?? '';
          final type = files[i].fileType ?? '';
          return uploadFileToS3(file: file!, fileType: type, preSignedUrl: url);
        }));
        List<String> sharedFile = uploadModel.files?.map((element) {
          return element.publicUrl ?? '';
        }).toList() ??
            [];
        params.addAll({
          if(isFromCoverImage!=null)
            ApiKeys.group_cover_image: sharedFile
            else
          ApiKeys.group_profile_image: sharedFile,
        });
        ResponseModel responseModelCreas =
        await ChatViewRepo().updateGroupApi(params);
        if (responseModelCreas.isSuccess) {

          groupDetailsModel.value.copyWith(
              groupProfileImage:responseModelCreas.data['group_profile_image'],
            groupCoverImage: responseModelCreas.data['group_cover_image'],
            groupName: responseModelCreas.data['group_name'],
            publicGroup: responseModelCreas.data['public_group'],
          );
          emitEvent(ChatEmitEvents.ChatList, {ApiKeys.type: AppConstants.group_Chat_Type});
          isEditGroupBtnLoading.value=false;
          return true;
        } else {
          isEditGroupBtnLoading.value=false;

          commonSnackBar(
              message:
              responseModelCreas.message ?? AppStrings.somethingWentWrong);
          return false;
        }
      }else{
        ResponseModel responseModelCreas =
        await ChatViewRepo().updateGroupApi(params);
        clearMessageControllerCommon();
        emitEvent(ChatEmitEvents.ChatList, {ApiKeys.type: AppConstants.group_Chat_Type});

        if (responseModelCreas.isSuccess) {

          clearMessageControllerCommon();
          emitEvent(ChatEmitEvents.ChatList, {ApiKeys.type: AppConstants.group_Chat_Type});

          groupDetailsModel.value.copyWith(
            groupProfileImage:responseModelCreas.data['group_profile_image'],
            groupCoverImage: responseModelCreas.data['group_cover_image'],
            groupName: responseModelCreas.data['group_name'],
            publicGroup: responseModelCreas.data['public_group'],
          );
          isEditGroupBtnLoading.value=false;

          return true;
        } else {
          clearMessageControllerCommon();
          commonSnackBar(
              message: responseModelCreas.message ?? AppStrings.somethingWentWrong);
          isEditGroupBtnLoading.value=false;

          return false;
      }

      }

    } catch (e) {
      isEditGroupBtnLoading.value=false;

      return false;
    }
  }

  String getCurrentIsoTime() {
    return DateTime.now().toUtc().toIso8601String();
  }
  Future<void> getGroupDetailsApi(Map<String, dynamic> params) async {
    // try {

      ResponseModel responseModel =
          await ChatViewRepo().getGroupDetailsApi(params);

      if (responseModel.isSuccess) {
        final data = responseModel.data;
        groupDetailsModel.value=GroupDetailsModel.fromJson(data);
        groupDetailsResponse.value=ApiResponse.complete(groupDetailsModel.value);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        groupDetailsResponse.value=ApiResponse.error( responseModel.message ?? AppStrings.somethingWentWrong);

      }
    // } catch (e) {
    //   groupDetailsResponse.value=ApiResponse.error(AppStrings.somethingWentWrong);
    //
    // }
  }
  Future<void> sendInitialMessage(Map<String, dynamic> params) async {
    if (isSending.value) return;
    isSending.value = true;
    try {
      clearMessageControllerCommon();
      ResponseModel responseModel =
          await ChatViewRepo().sendMessageToUser(params);

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;

        Messages? message = Messages.fromJson(data['data']);
        if (message.status != null) {
          readMessageStatus.value = message.status!;
        }
        getListOfMessageData?.add(message);
        getListOfMessageResponse.value =
            ApiResponse.complete(getListOfMessageData);
        if (chatFromBusinessProfile.value) {
          canPopBusiness.value = true;
        }
        scrollDown();
        saveSingleMessageToLocal(message.conversationId ?? '', message);
        emitEvent(ChatEmitEvents.ChatList,
            {ApiKeys.type: AppConstants.personal_Chat_Type},);
        clearMessageControllerCommon();
      } else {
        clearMessageControllerCommon();
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
    } finally {
      isSending.value = false;
    }
  }

  Future<void> deleteChatMessage(
      Map<String, dynamic> params, String userId) async {
    try {
      ResponseModel responseModel =
          await ChatViewRepo().deleteSingleMessage(params);
      clearMessageControllerCommon();
      if (responseModel.isSuccess) {
     emitEvent(ChatEmitEvents.messageReceived, {
      ApiKeys.conversation_id: params[ApiKeys.conversation_id],
      ApiKeys.page: 1,
      ApiKeys.is_online_user: userId,
      ApiKeys.per_page_message: 30,
    });
      } else {
        clearMessageControllerCommon();
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {}
  }

  Future<bool> likeAndUnlikeMessage(
      Map<String, dynamic> params, String userId, String conversationId) async {
    try {
      ResponseModel responseModel =
          await ChatViewRepo().likeUnlikeSingleMessage(params);
      clearMessageControllerCommon();

      if (responseModel.isSuccess) {
        emitEvent(ChatEmitEvents.messageReceived, {
          ApiKeys.conversation_id: conversationId,
          ApiKeys.page: 1,
          ApiKeys.is_online_user: userId,
          ApiKeys.per_page_message: 30,
        });
        return true;
      } else {
        clearMessageControllerCommon();
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> addToPinMessage(Map<String, dynamic> params) async {
    try {
      isPinMessageLoading.value=true;
      ResponseModel responseModel =
          await ChatViewRepo().addToPinMultiMessage(params);
      if (responseModel.isSuccess) {
        isPinMessageLoading.value=false;
        commonSnackBar(
            message:responseModel.message?? AppStrings.messagePinnedSuccessfully.tr);
        return true;
      } else {
        isPinMessageLoading.value=false;
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        return false;
      }
    } catch (e) {
      isPinMessageLoading.value=false;
      commonSnackBar(
          message: AppStrings.somethingWentWrong);
      return false;
    }
  }
  Future<bool> getPinMessageListDataApi(Map<String, dynamic> params) async {
    // try {

      ResponseModel responseModel =
          await ChatViewRepo().getPinMessageListData(params);
      if (responseModel.isSuccess) {
        getListOfMessageData?.clear();
        List<dynamic> details=responseModel.response?.data['messages'];
        getListOfMessageData?.addAll(details.map((e) => Messages.fromJson(e)).toList());
        getListOfMessageResponse.value =ApiResponse.complete(getListOfMessageData);
        return true;
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        return false;
      }
    // } catch (e) {
    //
    //   commonSnackBar(
    //       message: AppStrings.somethingWentWrong);
    //   return false;
    // }
  }

  /// Resolve remote URLs to local file paths for media messages.
  /// For each message with media URLs, checks if the file was already downloaded
  /// locally and replaces the remote URL with the local path so widgets show
  /// the file instantly without network loading.
  Future<void> _resolveLocalMediaPaths(List<Messages> messages) async {
    final mediaTypes = {'image', 'video', 'audio', 'document'};
    for (final msg in messages) {
      if (msg.url == null || msg.url!.isEmpty) continue;
      if (!mediaTypes.contains(msg.messageType)) continue;
      for (final media in msg.url!) {
        final url = media.url;
        if (url == null || url.isEmpty || !url.contains('http')) continue;
        final localFile = await ChatMediaStorageService.findExistingFile(
          url: url,
          messageType: msg.messageType ?? 'image',
          fileName: media.name,
        );
        if (localFile != null) {
          media.url = localFile.path;
        }
      }
    }
  }

  /// Remove the uploading placeholder card from the message list.
  void _removeUploadingPlaceholder() {
    if (sendLoadingFile.value.sendLoadingFile != null) {
      getListOfMessageData?.remove(sendLoadingFile.value);
      getListOfMessageResponse.value =
          ApiResponse.complete(getListOfMessageData);
      sendLoadingFile.value = Messages();
    }
  }

  Future<void> generateUploadUrlsApi({
    required Map<String, dynamic> params,
    required List<File> listFile,
    required List<String?>? userId,
    String? conversationId,
    String? commands,
    required String messageType,
    bool? isPendingMessage,
    String? messageId,
  }) async {
    try {
      VideoUploadProgress.value = "0";

      // Show uploading card immediately so the user sees progress right away
      if (listFile.isNotEmpty &&
          (messageType == 'video' || messageType == 'image') &&
          isPendingMessage == null) {
        final now = DateTime.now().toUtc();
        final isoTime = now.toIso8601String();
        sendLoadingFile.value = Messages(
            url: listFile.map((e) => MessageMediaUrl(url: e.path)).toList(),
            sendLoadingFile: listFile,
            myMessage: true,
            messageType: messageType,
            createdAt: isoTime);
        getListOfMessageData?.add(sendLoadingFile.value);
        getListOfMessageResponse.value =
            ApiResponse.complete(getListOfMessageData);
        scrollDown();
      }

      ResponseModel responseModel =
          await ChatViewRepo().generateUploadUrlsApi(params);
      clearMessageControllerCommon();

      if (!responseModel.isSuccess) {
        _removeUploadingPlaceholder();
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        return;
      }

      final data = responseModel.response?.data;
      final uploadModel = GenerateUploadUlrModel.fromJson(data);
      generateUploadUlrModel?.value = uploadModel;

      final files = uploadModel.files;
      if (files?.isEmpty ?? true) return;

      // Parallel Uploads using Future.wait
      await Future.wait(List.generate(files!.length, (i) {
        final file = listFile[i];
        final url = files[i].uploadUrl ?? '';
        final type = files[i].fileType ?? '';
        return uploadFileToS3(file: file, fileType: type, preSignedUrl: url);
      }));

      // Build final URL map
      final List<Map<String, dynamic>> urlList = files.map((element) {
        return {
          "url": element.publicUrl,
          "type": element.fileType,
          "name": element.fileName,
          "size": 0,
          "mimetype": element.fileType,
        };
      }).toList();

      final Map<String, dynamic> messagePayload = {
        if (conversationId==null)
          ApiKeys.other_user_id: userId
        else
          ApiKeys.conversation_id: conversationId,
        if (commands != null) ApiKeys.message: commands,
        ApiKeys.message_type: messageType,
        ApiKeys.url: urlList,
      };
      // Await the final send + Hive write so callers (e.g. sendOfflineMessage)
      // can clear their in-flight pending guard only after the replacement of
      // the temp row by the server row has actually hit Hive.
      await sendMessageLargeFile(
          messagePayload, listFile, isPendingMessage, messageId);
      generateUploadUrlResponse.value = ApiResponse.complete(uploadModel);
    } catch (e) {
      _removeUploadingPlaceholder();
      clearMessageControllerCommon();
      // A retry of an already-pending message that fails again must not
      // create a second pending entry — the original one is still in Hive
      // and will be drained by the next reopen/connectivity tick. Without
      // this guard every offline reopen duplicates the message.
      if (isPendingMessage == true) {
        return;
      }
      // Save a pending placeholder whenever the device is offline so the
      // message waits and is re-sent when connectivity returns. Skipping the
      // pending entry for actual server errors prevents an infinite retry.
      final bool isOffline = !await checkInternetStatus();
      if (isOffline || e == "Something went wrong") {
        final now = DateTime.now().toUtc();
        final isoTime = now.toIso8601String();
        List<String> filePathsList =
            listFile.map((f) => f.path).toList();
        final String tempId = "${isoTime}_${conversationId ?? ''}";
        final bool alreadyExists =
            getListOfMessageData?.any((m) => m.id == tempId) ?? false;
        Messages message = Messages(
            userId: userId?.first,
            id: tempId,
            messageType: messageType,
            sendStatus: "pending",
            message: commands,
            myMessage: true,
            conversationId: conversationId,
            createdAt: isoTime,
            pendingFilePaths: filePathsList,
            url: filePathsList
                .map((e) => MessageMediaUrl(
                      url: e,
                    ))
                .toList(),
            sendPendingMsgParams: params);
        if (!alreadyExists) {
          getListOfMessageData?.add(message);
          getListOfMessageResponse.value =
              ApiResponse.complete(getListOfMessageData);
        }
        saveSingleMessageToLocal(conversationId ?? '', message, params);
      }
    }
  }

  Future<bool?> sendMessageLargeFile(Map<String, dynamic> params,
      [List<File>? sendFiles,
      bool? isPendingMessage,
      String? messageId]) async {
    try {
      if (replyMessage?.value?.id != null) {
        replyMessage?.value = Messages();
      }
      ResponseModel responseModel =
          await ChatViewRepo().sendMessageToUserLargeFile(params);
      clearMessageControllerCommon();
      if (responseModel.isSuccess) {
        // Remove the uploading placeholder (shown for both image & video)
        _removeUploadingPlaceholder();

        final data = responseModel.response?.data;
        Messages? message = Messages.fromJson(data['data']);
        if (message.subType != "comment") {
          if (message.status != null) {
            readMessageStatus.value = message.status!;
          }
          if (isPendingMessage != null && isPendingMessage) {
            Messages? msg = getListOfMessageData
                ?.firstWhereOrNull((element) => element.id == messageId);
            if (msg != null) {
              getListOfMessageData?.remove(msg);
            }
            // Deduplicate: the newMessageReceived socket echo may have
            // already inserted this server message while the HTTP response
            // was in flight. Without this guard, retried pending media show
            // up twice in the conversation.
            final alreadyExists = message.id != null &&
                (getListOfMessageData?.any((m) => m.id == message.id) ?? false);
            if (!alreadyExists) {
              getListOfMessageData?.add(message);
            }
            getListOfMessageResponse.value =
                ApiResponse.complete(getListOfMessageData);
            await localStorageHelper.replacePendingWithServerMessage(
                params[ApiKeys.conversation_id]?.toString() ?? '',
                messageId ?? "",
                message);
          } else {
            final alreadyExists = message.id != null &&
                (getListOfMessageData?.any((m) => m.id == message.id) ?? false);
            if (!alreadyExists) {

              getListOfMessageData?.add(message);
            }
            getListOfMessageResponse.value =
                ApiResponse.complete(getListOfMessageData);
            scrollDown();
            saveSingleMessageToLocal(
                message.conversationId ?? '', message);
          }
        } else if (message.subType == 'comment') {
          getMediaMsgCommentsModel?.value.comments?.insert(
              0,
              Comments(
                message: message.message,
                likesCount: 0,
                sender: cmdImport.Sender(
                    name: message.sender?.name,
                    profileImage: message.sender?.profileImage),
                updatedAt: message.updatedAt,
                myComment: true,
              ));
        }

        scrollDown();

        clearMessageControllerCommon();
        return true;
      } else {
        _removeUploadingPlaceholder();
        clearMessageControllerCommon();
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      _removeUploadingPlaceholder();
    }
    return null;
  }

  Future<void> uploadFileToS3(
      {required File file,
      required String fileType,
      required String preSignedUrl}) async {
    try {
      ResponseModel? response = await ChatViewRepo().uploadVideoToS3(
          onProgress: (double progress) {
            VideoUploadProgress.value = (progress * 100).toStringAsFixed(2);
          },
          file: file,
          fileType: fileType,
          preSignedUrl: preSignedUrl);
      if (response?.isSuccess ?? false) {
      } else {
        commonSnackBar(
            message: response?.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> addGroupMember({required Map<String, dynamic> params}) async {
    try {
      ResponseModel? response = await ChatViewRepo().addGroupMembers(params);
      if (response.isSuccess) {
        commonSnackBar(message: AppStrings.groupMemberAdded.tr);
        Map<String, dynamic> data = {
          ApiKeys.conversation_id: params[ApiKeys.conversation_id]
        };
        getGroupMembersApi(data);
        Get.back();
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> generateDownloadUrlsApi(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await ChatViewRepo().generateDownloadUrlsApi(params);
      clearMessageControllerCommon();

      if (responseModel.isSuccess) {
      } else {
        clearMessageControllerCommon();
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {}
  }
  Future<bool> checkTrackOrderStatusApi(
      String orderId) async {
    try {
      ResponseModel responseModel =
      await ChatViewRepo().checkTrackOrderStatusApi(orderId);
      if (responseModel.isSuccess) {
        var details=responseModel.response?.data;
        if(details["status"]=="rejected"||details["status"]=="cancelled"){
        // if(details["status"]=="completed"||details["status"]=="rejected"||details["status"]=="cancelled"){
          return false;
        }else{
          return true;
        }

      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
