import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
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
import '../../../../core/services/chat_media_storage_service.dart';
import '../../../../core/services/local_strorage_helper.dart';
import '../../../../core/services/notification_utils.dart';
import '../../../personal/personal_profile/model/check_chat_connection_model.dart';
import '../../view/business_chat/business_chat_screen_updated.dart';
import '../../view/personal_chat/personal_chat_screen.dart';
import '../model/Generate_Upload_Ulr_Model.dart';
import '../model/GetChatListModel.dart';
import '../model/GetChatRequestListModel.dart';
import '../model/GetListOfMessageData.dart';
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
import '../repo/e2e_repo.dart';
import '../socket/ai_socket.dart';
import '../socket/chat_socket.dart';
import '../socket/live_location_track_socket.dart';
import '../../../../core/services/e2e/e2e_key_service.dart';
import '../../../../core/services/e2e/e2e_local_db_service.dart';
import '../../../../core/services/e2e/e2e_media_service.dart';
import '../../../../core/services/e2e/e2e_session_service.dart';
import '../../../../core/services/e2e/e2e_sync_service.dart';
import '../model/e2e_models.dart';

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

  // ── E2E Encryption Services ──────────────────────────────────────────────
  final _e2eKeyService  = E2EKeyService();
  final _e2eSessions    = E2ESessionService();
  final _e2eSync        = E2ESyncService();
  final _e2eMedia       = E2EMediaService();

  /// Whether the server resolved this connection as E2E-capable.
  RxBool e2eActive = false.obs;

  /// Whether the user has scrolled up away from the bottom of the chat.
  RxBool isUserScrolledUp = false.obs;

  /// Count of new messages that arrived while the user was scrolled up.
  RxInt unreadNewMessageCount = 0.obs;

  /// Guard flag: prevents infinite prekey:low → replenish retry loops.
  /// Reset on new socket connection. See doc section 6.4.
  bool _opkReplenishFailed = false;

  /// E2E messages for the currently open conversation (reactive list for UI).
  RxList<EncryptedMessageLocal> e2eMessages = <EncryptedMessageLocal>[].obs;
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
  RxBool socketConnected = false.obs;
  RxBool chatFromBusinessProfile = false.obs;
  RxBool canPopBusiness = false.obs;
  RxBool socketConnectedCalled = false.obs;
  final ScrollController scrollController = ScrollController();
  Rx<Messages?>? replyMessage = Messages().obs;

  RxString userOnlineStatus = ''.obs;
  RxString userOpenConversationId = ''.obs;
  RxString userOpenUserId = ''.obs;
  RxString readMessageStatus = ''.obs;
  RxInt selectedIndex =0.obs;

  Rx<Messages> sendLoadingFile = Messages().obs;
  RxList selectedUserIds = <String>[].obs;
  RxList<ChatList?> selectedChatList = <ChatList?>[].obs;
  RxList<String> openedConversation = <String>[].obs;
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
        return "Hello! I can help you check our product. What product are you looking for?";

      case AppConstants.askFood_Chat_Type:
        return "Hungry? I can help you find food details and calories. What did you eat?";

      case AppConstants.askService_Chat_Type:
        return "Hello! Looking for a specific service? Let me know what you need help with.";

      case AppConstants.askHealthCare_Chat_Type:
        return "Hello. I am your health assistant. How can I help you today?";

      case AppConstants.askEducation_Chat_Type:
        return "Welcome! Ask me anything about courses, degrees, or educational institutes.";

      case AppConstants.askHomeService_Chat_Type:
        return "Need help around the house? Ask me about cleaning, repairs, or other home services.";

      case AppConstants.askTravelStay_Chat_Type:
        return "Planning a trip? Ask me about hotels, flights, and travel options.";

      case AppConstants.askConsultingTalk_Chat_Type:
        return "Hi there. I'm here to provide expert consulting and advice. What topic would you like to discuss?";

      default:
        return "Hi there! How can I assist you today?";
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
    // E2E: init local DB + register Signal Protocol keys on first run
    await initializeE2E();

    // Always ensure socket is connected
    await chatSocket.connectToSocket();

    if (socketConnected.value == false) {
      socketConnected.value = true;
      chatSocket.listenEvent(ChatEmitEvents.ChatList, (data) async {
        log("skjdnsdjcnsjkc ${data}");
        final parsedData = GetChatListModel.fromJson(data);
        loadChatListWithType(chatListModel: parsedData);
        getPersonalFilteredChatListModel?.value = parsedData;
        await localStorageHelper.saveChatList(
            parsedData.chatList ?? [], parsedData.type ?? '');
      });

      chatSocket.listenEvent(ChatEmitEvents.messageViewed, (data) {
        getMediaMsgCommentsModel?.value =
            GetMediaMsgCommentsModel.fromJson(data);
      });
      chatSocket.listenEvent(ChatEmitEvents.isOnlineFromChatList, (data) {

      });
      chatSocket.listenEvent(ChatEmitEvents.messageReceived, (data) async {

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
          final conversationId =
              parsedData.messages?.first.conversationId ?? '';
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
            // the authoritative server data, so it cleans up any local duplicates
            localStorageHelper.saveMessagesByConversationId(
                userOpenConversationId.value, deduped);
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
        scrollDown();
      });
      // chatSocket.listenEvent(ChatEmitEvents.isOnLine, (data) {
      //   if (userOpenUserId.value == data['user_id']) {
      //     if (data['is_online']) {
      //       userOnlineStatus.value = "Online";
      //     }
      //   } else {
      //     userOnlineStatus.value = "Offline";
      //   }
      // });
      chatSocket.listenEvent(ChatEmitEvents.isOnlineFromChatList, (data) {
        final List<Map<String, dynamic>> datas =
        List<Map<String, dynamic>>.from(data);

        final Map<String, dynamic> user = datas.firstWhere(
              (e) => e['user_id'] == userOpenUserId.value,
          orElse: () => <String, dynamic>{},
        );

        userOnlineStatus.value =
        user['is_online'] == true ? "Online" : "Offline";
      });

      chatSocket.listenEvent(ChatEmitEvents.messageStatusUpdate, (data) {
        if (data['conversation_id'] == userOpenConversationId.value) {
          readMessageStatus.value = data['status'];
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
        log("selfPickupOrderReady: $data");
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

      socketConnectedCalled.value = true;

      // ── E2E: Register socket callbacks ──────────────────────────────────
      _registerE2ESocketCallbacks();
    }
    try {
      openedConversation.value = await localStorageHelper.getConversation();
      await loadAllChatListFromLocal();
    } catch (e) {
      debugPrint('connectSocket local storage init error: $e');
    }
    // final connectivityResult = await NetworkUtils.isConnected();
    // if (connectivityResult) {
    //   await loadChatListFromLocal(AppConstants.personal_Chat_Type);
    // }

    // }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // E2E ENCRYPTION — Phase 1-4 Integration
  // ═══════════════════════════════════════════════════════════════════════════

  /// E2E initialization — matches web tester's autoRegisterE2EKeys() flow:
  ///  1. Init SQLite database
  ///  2. Generate NaCl keys if needed
  ///  3. Revoke stale old devices (web tester does this!)
  ///  4. Verify server has our device's keys, register if missing
  Future<void> initializeE2E() async {
    try {
      // Step 1: Init local database
      await E2ELocalDbService().init();
      if (kDebugMode) print('[E2E-INIT] ═══ E2E Initialization Start ═══');

      final myDeviceId = await _e2eKeyService.getOrCreateDeviceId();
      if (kDebugMode) print('[E2E-INIT] deviceId: $myDeviceId');

      // Step 2: Ensure NaCl keys exist locally
      final hasLocalKeys = await _e2eKeyService.isRegistered();
      if (kDebugMode) print('[E2E-INIT] Local NaCl v2 keys: $hasLocalKeys');

      // Step 3: Check server for our device
      final myUserId = userId; // global from shared_preference_utils
      if (myUserId.isEmpty) {
        if (kDebugMode) print('[E2E-INIT] No userId yet — skipping registration');
        return;
      }

      // Use capability endpoint (no OPK consumption) instead of getPrekeyBundles
      // which consumes a one-time prekey on every call.
      final capability = await E2ERepo().getCapability(myUserId);
      final serverHasE2E = capability?.protocol == E2EProtocol.e2e;
      if (kDebugMode) {
        print('[E2E-INIT] Server capability for us: ${capability?.protocol}');
      }

      if (hasLocalKeys && serverHasE2E) {
        // Everything is good — keys exist locally AND on server
        if (kDebugMode) print('[E2E-INIT] ✓ Keys already registered on server');
      } else {
        // Need to register — either no local keys or server doesn't have ours
        if (kDebugMode) print('[E2E-INIT] Registration needed (local=$hasLocalKeys, serverE2E=$serverHasE2E)');

        // Register our keys (server handles device replacement)
        if (kDebugMode) print('[E2E-INIT] Registering keys...');
        final success = await _e2eKeyService.registerKeys();
        if (kDebugMode) print('[E2E-INIT] Registration: ${success ? "✓ SUCCESS" : "✘ FAILED"}');
      }

      if (kDebugMode) print('[E2E-INIT] ═══ E2E Initialization Complete ═══');
    } catch (e) {
      if (kDebugMode) print('[E2E-INIT] ✘ Error: $e');
    }
  }

  /// Wire all E2E socket callbacks — called once inside connectSocket().
  void _registerE2ESocketCallbacks() {
    // Reset OPK replenish guard on new connection
    _opkReplenishFailed = false;

    // Phase 1: Protocol resolved — server tells us if E2E is active
    chatSocket.onProtocolResolved((protocol) {
      e2eActive.value = protocol == 'e2e';
      // Phase 4: On reconnect, sync any missed encrypted messages
      if (protocol == 'e2e') {
        _e2eSync.syncAllConversations();
      }
    });

    // Phase 2: OPK pool low — replenish in background (with guard against retry loops)
    chatSocket.onPrekeyLow((remainingCount) async {
      if (_opkReplenishFailed) return;
      // Server remainingCount can be unreliable (negative values observed).
      // Use a small safe batch size to avoid exceeding the 200 pool limit.
      const safeCount = 10;
      if (kDebugMode) print('[E2E] prekey:low (remaining=$remainingCount) — uploading $safeCount OPKs');
      final success = await _e2eKeyService.replenishOPKs(count: safeCount);
      if (!success) {
        if (kDebugMode) print('[E2E] OPK replenish failed/rejected — disabling retries until reconnect');
        _opkReplenishFailed = true;
      }
    });

    // Phase 3: New encrypted message received
    chatSocket.onE2EMessageNew((data) async {
      if (kDebugMode) print('[E2E] message:new callback fired');
      final msg = await _e2eSync.handleIncomingMessage(data);
      if (msg == null) {
        if (kDebugMode) print('[E2E] handleIncomingMessage returned null — message dropped');
        return;
      }

      // Send delivery ACK
      chatSocket.sendMessageAck(msg.messageId);

      // Convert to Messages format and add to the regular message list
      final converted = e2eMessageToMessages(msg);

      // Add to currently open conversation
      if (msg.conversationId == userOpenConversationId.value) {
        e2eMessages.add(msg);

        // Also add to the regular list so it appears in the existing ListView
        final alreadyExists = getListOfMessageData?.any((m) => m.id == converted.id) ?? false;
        if (!alreadyExists) {
          getListOfMessageData?.add(converted);
          getListOfMessageResponse.value = ApiResponse.complete(getListOfMessageData);
        }
        scrollDown();
      }

      // Refresh chat list
      emitEvent(ChatEmitEvents.ChatList, {ApiKeys.type: AppConstants.personal_Chat_Type});
    });

    // Phase 3: Delivery status update — update local DB + reactive UI
    chatSocket.onE2EMessageStatus((data) async {
      await _e2eSync.handleMessageStatus(data);
      final messageId = data['message_id'] as String?;
      final status    = data['status'] as String?;
      final seqNum    = data['seq_num'] as int?;
      if (messageId == null || status == null) return;
      // Update optimistic message in the reactive list
      final idx = e2eMessages.indexWhere((m) =>
          m.messageId == messageId || (m.status == 'sending' && m.seqNum == -1));
      if (idx != -1) {
        final old = e2eMessages[idx];
        final confirmed = EncryptedMessageLocal(
          messageId:      messageId,
          conversationId: old.conversationId,
          seqNum:         seqNum ?? old.seqNum,
          senderId:       old.senderId,
          senderDeviceId: old.senderDeviceId,
          plaintext:      old.plaintext,
          encryptedMedia: old.encryptedMedia,
          expiresAt:      old.expiresAt,
          status:         status,
          createdAt:      old.createdAt,
        );
        e2eMessages[idx] = confirmed;

        // Persist to SQLite: replace the optimistic temp-ID entry with the real one.
        // If the old messageId was a temp ID (optimistic), delete it first.
        final db = E2ELocalDbService();
        if (old.messageId != messageId) {
          await db.deleteMessage(old.messageId);
        }
        await db.upsertMessage(confirmed);
      }
    });

    // Phase 4: Sync cursor confirmed by server
    chatSocket.onE2ESyncComplete((data) {
      if (kDebugMode) {
        print('[E2E] sync:complete at seq ${data['seq_num']}');
      }
    });

    // E2E error handler (doc section 7.4)
    chatSocket.listenEvent('error', (data) {
      if (data is Map) {
        final d = Map<String, dynamic>.from(data);
        final message = d['message']?.toString() ?? '';
        if (message.contains('e2e') || message.contains('E2E') ||
            message.contains('encrypt') || message.contains('Protocol')) {
          if (kDebugMode) print('[E2E] Server error: $message');
        }
      }
    });
  }

  /// Send an encrypted message to [recipientUserId] in [conversationId].
  ///
  /// [text]  — the plaintext message string.
  /// [mediaFiles] — optional list of {file, mimeType} for media attachments.
  ///
  /// Falls back to the plain `messageReceived` event if E2E is not active.
  /// Returns true if E2E send succeeded, false if it failed (caller should fallback to plain).
  Future<bool> sendE2EMessage({
    required String conversationId,
    required String recipientUserId,
    required String text,
    List<Map<String, dynamic>>? mediaFiles, // [{file: File, mimeType: String}]
  }) async {
    try {
      if (kDebugMode) {
        print('[E2E-SEND] ═══════════════════════════════════════');
        print('[E2E-SEND] conversationId: $conversationId');
        print('[E2E-SEND] recipientUserId: $recipientUserId');
        print('[E2E-SEND] text: "${text.substring(0, text.length.clamp(0, 100))}"');
        print('[E2E-SEND] mediaFiles: ${mediaFiles?.length ?? 0}');
      }

      // Phase 3 media: upload encrypted files first
      final mediaMetaList = <EncryptedMediaMetadata>[];
      final encryptedMediaRefs = <Map<String, dynamic>>[];

      if (mediaFiles != null) {
        for (final m in mediaFiles) {
          if (kDebugMode) print('[E2E-SEND] Uploading encrypted media: ${m['mimeType']}');
          final meta = await _e2eMedia.uploadEncryptedMedia(
            file:     m['file'],
            mimeType: m['mimeType'],
          );
          if (meta != null) {
            mediaMetaList.add(meta);
            encryptedMediaRefs.add({
              's3_key':    meta.s3Key,
              'mime_type': meta.mimeType,
              'size':      meta.size,
            });
            if (kDebugMode) print('[E2E-SEND]   ✓ Media uploaded: ${meta.s3Key}');
          } else {
            if (kDebugMode) print('[E2E-SEND]   ✘ Media upload failed');
          }
        }
      }

      // Build plaintext JSON payload
      final payload = E2EMessagePayload(
        text:  text,
        media: mediaMetaList.isNotEmpty ? mediaMetaList : null,
      );
      final payloadJson = payload.toJsonString();
      if (kDebugMode) print('[E2E-SEND] Payload JSON: ${payloadJson.substring(0, payloadJson.length.clamp(0, 150))}');

      // Encrypt for each recipient device
      final ciphertextEntries = await _e2eSessions.encryptForRecipient(
        recipientUserId: recipientUserId,
        plaintextJson:   payloadJson,
      );

      if (ciphertextEntries.isEmpty) {
        if (kDebugMode) print('[E2E-SEND] ✘ No ciphertext entries — recipient has no E2E keys, falling back to plain');
        return false;
      }

      if (kDebugMode) {
        print('[E2E-SEND] Emitting message:send with ${ciphertextEntries.length} ciphertext entries');
        for (final e in ciphertextEntries) {
          print('[E2E-SEND]   deviceId=${e.deviceId}, bodyLen=${e.body.length}');
        }
      }

      // Emit message:send
      chatSocket.sendEncryptedMessage(
        conversationId:     conversationId,
        ciphertextEntries:  ciphertextEntries
            .map((e) => {'deviceId': e.deviceId, 'body': e.body})
            .toList(),
        encryptedMediaRefs: encryptedMediaRefs.isNotEmpty ? encryptedMediaRefs : null,
      );

      if (kDebugMode) print('[E2E-SEND] ✓ message:send emitted successfully');

      // Optimistic UI update — also persist to SQLite so message survives navigation
      final optimistic = EncryptedMessageLocal(
        messageId:      DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: conversationId,
        seqNum:         -1,
        senderId:       userId,
        plaintext:      text,
        expiresAt:      DateTime.now().add(const Duration(days: 30)),
        status:         'sending',
        createdAt:      DateTime.now(),
      );
      await E2ELocalDbService().upsertMessage(optimistic);
      e2eMessages.add(optimistic);
      scrollDown();

      // Track conversation for future syncs
      await _e2eSync.trackConversation(conversationId);
      if (kDebugMode) print('[E2E-SEND] ═══════════════════════════════════════');
      return true;
    } catch (e) {
      if (kDebugMode) print('[E2E] sendE2EMessage error: $e');
      return false;
    }
  }

  /// Load E2E messages for [conversationId] from local SQLite and set [e2eMessages].
  Future<void> loadE2EMessages(String conversationId) async {
    try {
      final msgs = await E2ELocalDbService().getMessages(conversationId);
      e2eMessages.assignAll(msgs);
    } catch (e) {
      if (kDebugMode) print('[E2E] loadE2EMessages error: $e');
    }
  }

  /// Convert an [EncryptedMessageLocal] to a [Messages] object for UI rendering
  /// in the existing MessageCard widget.
  Messages e2eMessageToMessages(EncryptedMessageLocal e2eMsg) {

    return Messages(
      id: e2eMsg.messageId,
      message: e2eMsg.plaintext ?? (e2eMsg.ciphertext != null ? '\u{1F512} Encrypted message' : ''),
      messageType: 'text',
      conversationId: e2eMsg.conversationId,
      senderId: e2eMsg.senderId,
      createdAt: e2eMsg.createdAt.toIso8601String(),
      myMessage: e2eMsg.senderId == userId,
      status: e2eMsg.status == 'device_delivered' ? 'read'
          : e2eMsg.status == 'server_received' ? 'delivered'
          : e2eMsg.status == 'sending' ? 'pending' : 'sent',
    );
  }

  /// Get merged message list: combines plain messages and E2E messages for display.
  /// Returns a deduplicated, sorted list ready for rendering.
  List<Messages> getMergedMessages() {
    final plainMessages = getListOfMessageData ?? [];
    if (!e2eActive.value || e2eMessages.isEmpty) return plainMessages;

    // Single-pass merge + dedup using a Set for O(1) lookups
    final seen = <String>{};
    final merged = <Messages>[];

    for (final m in plainMessages) {
      final key = m.id ?? '';
      if (key.isEmpty || seen.add(key)) {
        merged.add(m);
      }
    }

    for (final e2eMsg in e2eMessages) {
      final converted = e2eMessageToMessages(e2eMsg);
      final key = converted.id ?? '';
      if (key.isEmpty || seen.add(key)) {
        merged.add(converted);
      }
    }

    // Sort by created_at — parse once per item using milliseconds for fast comparison
    merged.sort((a, b) {
      final msA = _parseCreatedAtMs(a.createdAt);
      final msB = _parseCreatedAtMs(b.createdAt);
      return msA.compareTo(msB);
    });

    return merged;
  }

  /// Fast date parser — returns epoch millis, avoids creating DateTime objects in sort.
  int _parseCreatedAtMs(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return 0;
    try {
      return DateTime.parse(createdAt).millisecondsSinceEpoch;
    } catch (_) {
      return 0;
    }
  }

  /// Check if a recipient supports E2E (GET /protocol/capability/:userId).
  Future<bool> recipientSupportsE2E(String userId) async {
    try {
      final cap = await E2ERepo().getCapability(userId);
      return cap?.protocol == E2EProtocol.e2e;
    } catch (_) {
      return false;
    }
  }

  /// On app resume — trigger offline sync for all tracked conversations.
  Future<void> triggerE2ESync() async {
    await _e2eSync.syncAllConversations();
  }

  /// On logout — revoke this device's keys from the server.
  Future<void> revokeE2EDevice() async {
    await _e2eKeyService.revokeDevice();
  }

  /// Detect MIME type from file extension for E2E media uploads.
  static String _detectMimeType(String ext) {
    const mimeMap = {
      'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png',
      'gif': 'image/gif', 'webp': 'image/webp', 'heic': 'image/heic',
      'mp4': 'video/mp4', 'mov': 'video/quicktime', 'avi': 'video/x-msvideo',
      'mkv': 'video/x-matroska', 'webm': 'video/webm',
      'pdf': 'application/pdf', 'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel', 'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'mp3': 'audio/mpeg', 'aac': 'audio/aac', 'wav': 'audio/wav',
      'ogg': 'audio/ogg',
    };
    return mimeMap[ext] ?? 'application/octet-stream';
  }

  // ═══════════════════════════════════════════════════════════════════════════

  void changeBusinessInsideTab(int index) {
    businessTabIndexSelected.value = index;
  }

  void setReplyMessage(Messages? message) {
    replyMessage?.value = message;
  }

  void onSelectChatTab(int index) {
    if (chatMainTabController == null) {
      // Optionally initialize here if possible
      // chatMainTabController = TabController(length: ..., vsync: this);
      return; // or handle gracefully
    }
    chatMainTabController!.animateTo(index);
    selectedChatTabIndex.value = index;
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
    if (params != null) {
      // Outgoing message with send params — mark as pending for offline retry
      msg.sendPendingMsgParams = params;
      localStorageHelper.saveSingleMessageToConversationId(
          conversationId, msg,
          sendStatus: "pending");
    } else {
      // Received message or already-sent message — save without pending status
      localStorageHelper.saveSingleMessageToConversationId(
          conversationId, msg);
    }
  }

  Future<void> sendOfflineMessage(
    String conversationId,
  ) async {
    List<Map<String, dynamic>> data =
        await localStorageHelper.getUnsentMessages(conversationId);

    if (data.isEmpty) return;

    data = data.reversed.toList();
    for (int i = 0; i < data.length; i++) {
      if ((data[i]["message_type"] == 'document' ||
              data[i]["message_type"] == 'text' ||
              data[i]["message_type"] == 'contact' ||
              data[i]["message_type"] == 'location') &&
          data[i]['sendPendingMsgParams'] != null) {
        if (data[i]['_id'] != null) {
          sendOfflineMessageToServer(
              data[i]['sendPendingMsgParams'], data[i]['_id']);
        }
      } else if ((data[i]["message_type"] == 'image' ||
              data[i]["message_type"] == 'video') &&
          data[i]['sendPendingMsgParams'] != null) {
        List<File> listFiles = [];
        List<dynamic> pendingFilePaths = data[i]['pendingFilePaths'];
        listFiles = pendingFilePaths.map((e) => File(e)).toList();
        await generateUploadUrlsApi(
            params: data[i]['sendPendingMsgParams'],
            listFile: listFiles,
            userId: [data[i]['userId'] ?? ""],
            conversationId: data[i][ApiKeys.conversation_id],
            commands: data[i]["comments"],
            messageType: data[i]["message_type"],
            isPendingMessage: true,
            messageId: data[i]['_id']);
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
              ?.firstWhere((element) => element.id == messageId);
          getListOfMessageData?.remove(msg);
          getListOfMessageData?.add(message);
          getListOfMessageResponse.value =
              ApiResponse.complete(getListOfMessageData);
          await localStorageHelper.markMessageAsSent(
              params[ApiKeys.conversation_id], messageId);
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
    emitEvent(ChatEmitEvents.screenRoom,
        {ApiKeys.conversation_id: "${conversationId}"});
    addConversationOnce(conversationId);
    // E2E: load locally stored decrypted messages for this conversation
    loadE2EMessages(conversationId);
  }

  void addConversationOnce(String conversationId) {
    localStorageHelper.putConversation(conversationId);
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
    final localMessages =
        await localStorageHelper.getMessagesByConversationId(conversationId);
    // Deduplicate by message ID from local storage (may contain duplicates
    // from previous sessions where send + socket both saved the same message)
    final seen = <String>{};
    final deduped = <Messages>[];
    for (final m in localMessages) {
      final id = m.id ?? '';
      if (id.isEmpty || seen.add(id)) {
        deduped.add(m);
      }
    }
    // Resolve local file paths for already-downloaded media
    await _resolveLocalMediaPaths(deduped);
    getListOfMessageResponse.value = ApiResponse.complete(deduped);
    scrollDown();
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

  Future<void> openAnyOneChatFunction(
      {required String conversationId,
      String? otherUserId,
      required String? userId,
      required String? type,
      String? profileImage,
      bool? isWithProductSend,
      Map<String, dynamic>? shareProductParams,
      required String? contactName,
      required String? contactNo,
      required bool isInitialMessage,
      bool? isFromContactList}) async {
    businessTabIndexSelected.value = 0;
    await getLocalConversation(
        conversationId, userId, otherUserId, contactName);

    if (isWithProductSend == true) {
      await sendProductMessages(shareProductParams ?? {});
    }

    if (type == AppConstants.business_Chat_Type) {
      if (isFromContactList != null && isFromContactList) {
        Get.off(
          () => BusinessChatScreenUpdated(
            type: type,
            isInitialMessage: isInitialMessage,
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
            isInitialMessage: isInitialMessage,
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
            isInitialMessage: isInitialMessage,
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
            isInitialMessage: isInitialMessage,
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

  Future<void> getLocalConversation(String conversationId, userId,
      [String? otherUserId, String? name]) async {
    // Clear previous conversation data to prevent stale messages from mixing in
    getListOfMessageResponse.value = ApiResponse.initial('Initial');
    // Load cached messages first for instant UI
    loadOfflineMessages(conversationId);
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
    // }

    // }
  }

  void emitEvent(String event, dynamic data,
      [ String? conversationId]) async {
    if (event == ChatEmitEvents.messageReceived &&
        (conversationId ?? "") != userOpenConversationId) {
      getListOfMessageResponse.value = ApiResponse.initial('Initial');
    }
    if (event == ChatEmitEvents.ChatList) {
      final type = data[ApiKeys.type];
      try {
        List<ChatList> localChats =
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

  Future<void> loadAllChatListFromLocal() async {
    try {
      final allChats = await localStorageHelper.getAllChatListsFromLocal();

      for (final entry in allChats.entries) {
        loadChatListWithType(
            chatListModel: GetChatListModel(
          type: entry.key,
          success: true,
          chatList: List<ChatList?>.from(entry.value),
          archived: [],
        ));
      }
    } catch (e) {
      debugPrint('loadAllChatListFromLocal error: $e');
    }
  }

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

  /// Upload contacts to API and save response to Hive.
  /// If data already exists in memory, skip API call.
  Future<void> uploadContacts(List<Map<String, dynamic>> params) async {
    contactListParamsData = params;

    // Already loaded in memory — skip everything
    if (contactsListModel?.value.data != null) {
      viewContactsListResponse.value =
          ApiResponse.complete(contactsListModel?.value);
      return;
    }

    // Try Hive cache first
    final cached = await localStorageHelper.getContacts();
    if (cached != null) {
      contactsListModel?.value = ContactListModel.fromJson(cached);
      viewContactsListResponse.value =
          ApiResponse.complete(contactsListModel?.value);
      return;
    }

    // No cache — call API
    ResponseModel responseModel =
        await ChatViewRepo().getConnectionsSync(params);

    if (responseModel.isSuccess) {
      final data = responseModel.response?.data;

      // Save to Hive
      await localStorageHelper.saveContacts(data);
      contactsListModel?.value = ContactListModel.fromJson(data);
      viewContactsListResponse.value = ApiResponse.complete(responseModel);
    } else {
      commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong);
    }
  }

  /// Force refresh contacts from API (called by refresh button).
  Future<void> refreshContacts(List<Map<String, dynamic>> params) async {
    contactListParamsData = params;
    viewContactsListResponse.value = ApiResponse.initial('Initial');

    ResponseModel responseModel =
        await ChatViewRepo().getConnectionsSync(params);

    if (responseModel.isSuccess) {
      final data = responseModel.response?.data;

      // Update Hive cache
      await localStorageHelper.saveContacts(data);
      contactsListModel?.value = ContactListModel.fromJson(data);
      viewContactsListResponse.value = ApiResponse.complete(responseModel);
    } else {
      // Fallback to existing data if available
      if (contactsListModel?.value.data != null) {
        viewContactsListResponse.value =
            ApiResponse.complete(contactsListModel?.value);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
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
  Future<bool?> sendMessage(Map<String, dynamic> params,
      [List<File>? sendFiles, String? fileName]) async {
    try {
      params[ApiKeys.tagged_users] = taggedUserIds.join(',');
      taggedUserIds.clear();
      if(params[ApiKeys.message_type]=="live_location"){
       await startLiveLocationTracking(labelToDuration(params[ApiKeys.live_location_validity]));
      }

      // ── E2E: Route to encrypted send path if BOTH sides support E2E ──
      final msgType = params[ApiKeys.message_type]?.toString() ?? '';
      final e2eSupportedTypes = ['text', 'image', 'video', 'document'];
      // Determine recipient: from open conversation OR from params (forward/share intent)
      final recipientId = userOpenUserId.value.isNotEmpty
          ? userOpenUserId.value
          : (params[ApiKeys.other_user_id]?.toString() ?? '');
      final convId = params[ApiKeys.conversation_id]?.toString() ?? '';
      if (e2eActive.value &&
          recipientId.isNotEmpty &&
          convId.isNotEmpty &&
          e2eSupportedTypes.contains(msgType)) {
        final text = params[ApiKeys.message]?.toString() ?? '';
        List<Map<String, dynamic>>? mediaFiles;
        if (sendFiles != null && sendFiles.isNotEmpty) {
          mediaFiles = sendFiles.map((f) {
            final ext = f.path.split('.').last.toLowerCase();
            final mimeType = _detectMimeType(ext);
            return <String, dynamic>{
              'file': f,
              'mimeType': mimeType,
            };
          }).toList();
        }
        if (text.isNotEmpty || (mediaFiles != null && mediaFiles.isNotEmpty)) {
          final e2eSuccess = await sendE2EMessage(
            conversationId:  convId,
            recipientUserId: recipientId,
            text:            text,
            mediaFiles:      mediaFiles,
          );
          if (e2eSuccess) {
            _updateChatListLastMessage(
              convId,
              text,
              msgType,
              DateTime.now().toUtc().toIso8601String(),
            );
            clearMessageControllerCommon();
            return true;
          }
          // E2E failed (recipient has no keys) — fall through to plain text below
          if (kDebugMode) print('[E2E] Recipient has no E2E keys — sending as plain text');
        }
      }
      // ── End E2E routing (falls through to plain text if E2E failed) ──

      clearMessageControllerCommon();

      if (replyMessage?.value?.id != null) {
        replyMessage?.value = Messages();
      }
      final isVideoSend = sendFiles != null &&
          sendFiles.isNotEmpty &&
          params[ApiKeys.message_type] == 'video';

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
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      clearMessageControllerCommon();
      if (e == "Something went wrong") {
        final now = DateTime.now().toUtc();
        final isoTime = now.toIso8601String();
        clearMessageControllerCommon();
        Messages message = Messages(
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
            message: params[ApiKeys.message],
            latitude: params[ApiKeys.message_type] == "location"
                ? params[ApiKeys.latitude]
                : null,
            longitude: params[ApiKeys.message_type] == "location"
                ? params[ApiKeys.longitude]
                : null,
            myMessage: true,
            conversationId: params[ApiKeys.conversation_id],
            createdAt: isoTime,
            sendPendingMsgParams: params);

        getListOfMessageData?.add(message);
        getListOfMessageResponse.value =
            ApiResponse.complete(getListOfMessageData);
        saveSingleMessageToLocal(
            params[ApiKeys.conversation_id], message, params);
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
      String chatPersonUserId=details.data?.sender?.id??'';
      String contactNo=details.data?.sender?.contact??'';
      String contactName=details.data?.sender?.name??'';
      String profileImage=details.data?.sender?.profileImage??'';
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

    // If not in memory, search Hive cache
    cachedChat ??= await localStorageHelper.findChatByUserId(userId);

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
    try {
      clearMessageControllerCommon();
      ResponseModel responseModel =
          await ChatViewRepo().sendMessageToUser(params);

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;

        Messages? message = Messages.fromJson(data['data']);
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
    } catch (e) {}
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
            message:responseModel.message?? "Message Pinned Successfully");
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
        // if (isInitialMessage)
          ApiKeys.other_user_id: userId,
        // else
        //   ApiKeys.conversation_id: conversationId,
        if (commands != null) ApiKeys.message: commands,
        ApiKeys.message_type: messageType,
        ApiKeys.url: urlList,
      };
      sendMessageLargeFile(
          messagePayload, listFile, isPendingMessage, messageId);
      generateUploadUrlResponse.value = ApiResponse.complete(uploadModel);
    } catch (e) {
      _removeUploadingPlaceholder();
      clearMessageControllerCommon();
      if (e == "Something went wrong") {
        final now = DateTime.now().toUtc();
        final isoTime = now.toIso8601String();
        clearMessageControllerCommon();
        List<String> filePathsList = [];
        listFile.forEach((e) {
          filePathsList.add(e.path);
        });
        Messages message = Messages(
            userId: userId?.first,
            id: "${isoTime}_${params[ApiKeys.conversation_id]}",
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
        getListOfMessageData?.add(message);
        getListOfMessageResponse.value =
            ApiResponse.complete(getListOfMessageData);

        saveSingleMessageToLocal(conversationId??'', message, params);
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
        if (sendFiles != null &&
            sendFiles.isNotEmpty &&
            params[ApiKeys.message_type] == 'video' &&
            isPendingMessage == null) {
          if (getListOfMessageData != null && getListOfMessageData!.isNotEmpty) {
            getListOfMessageData!.removeLast();
          }
          getListOfMessageResponse.value =
              ApiResponse.complete(getListOfMessageData);
        }
        final data = responseModel.response?.data;
        Messages? message = Messages.fromJson(data['data']);
        if (message.subType != "comment") {
          if (isPendingMessage != null && isPendingMessage) {
            Messages? msg = getListOfMessageData
                ?.firstWhere((element) => element.id == messageId);
            getListOfMessageData?.remove(msg);
            getListOfMessageData?.add(message);
            getListOfMessageResponse.value =
                ApiResponse.complete(getListOfMessageData);
            await localStorageHelper.markMessageAsSent(
                params[ApiKeys.conversation_id], messageId ?? "");
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
        clearMessageControllerCommon();
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      if (sendFiles != null &&
          sendFiles.isNotEmpty &&
          params[ApiKeys.message_type] == 'video') {
        if (getListOfMessageData != null && getListOfMessageData!.isNotEmpty) {
          getListOfMessageData!.removeLast();
        }
        getListOfMessageResponse.value =
            ApiResponse.complete(getListOfMessageData);
      }
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
        commonSnackBar(message: "Group Member Added");
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
        if(details["status"]!="completed"||details["status"]!="rejected"||details["status"]!="cancelled"){
          return true;
        }else{
          return false;
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
