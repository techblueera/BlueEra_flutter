import 'dart:developer';
import 'package:BlueEra/core/anim/listening_ripple.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_theme_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/model/base_ai_chat_model.dart';
import 'package:BlueEra/features/chat/auth/model/business_service_ask_ai_model.dart';
import 'package:BlueEra/features/chat/auth/model/education_ask_ai_model.dart';
import 'package:BlueEra/features/chat/auth/model/food_ask_ai_model.dart';
import 'package:BlueEra/features/chat/auth/model/health_care_ask_ai_model.dart';
import 'package:BlueEra/features/chat/auth/model/inventory_ask_ai_model.dart';
import 'package:BlueEra/features/chat/auth/model/service_ask_ai_model.dart';
import 'package:BlueEra/features/chat/auth/model/travel_and_stay_ask_ai_model.dart';
import 'package:BlueEra/features/chat/view/ai_chat/widget/ask_consulting_talk_msg_card.dart';
import 'package:BlueEra/features/chat/view/ai_chat/widget/ask_education_msg_card.dart';
import 'package:BlueEra/features/chat/view/ai_chat/widget/ask_food_msg_card.dart';
import 'package:BlueEra/features/chat/view/ai_chat/widget/ask_health_care_msg_card.dart';
import 'package:BlueEra/features/chat/view/ai_chat/widget/ask_home_service_msg_card.dart';
import 'package:BlueEra/features/chat/view/ai_chat/widget/ask_service_msg_card.dart';
import 'package:BlueEra/features/chat/view/ai_chat/widget/ask_travel_stay_msg_card.dart';
import 'package:BlueEra/features/chat/view/widget/component_widgets.dart';
import 'package:BlueEra/features/chat/view/widget/message_bubble.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../widget/ask_inventory_product_msg_card.dart';

class AiCommonSearchScreen extends StatefulWidget {
  final String chatType;
  final String? conversationId;
  final String? userId;
  final String? profileImage;
  final String? businessId;
  final String? name;
  final String? contactNo;
  final String? type;
  final bool isInitialMessage;

  const AiCommonSearchScreen({super.key,
    required this.chatType,
    required this.conversationId,
    required this.userId,
    required this.businessId,
    this.profileImage,
    required this.type,
    this.name,
    this.contactNo,
    required this.isInitialMessage,
  });

  @override
  State<AiCommonSearchScreen> createState() => _AiCommonSearchScreenState();
}

class _AiCommonSearchScreenState extends State<AiCommonSearchScreen> {
  final chatViewController = getOrPut(() => ChatViewController());
  final chatThemeController = getOrPut(() => ChatThemeController());
  final TextEditingController editingController = TextEditingController();
  final _scrollController = ScrollController();

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = "";
  // String _lastError = '';
  // String _lastStatus = '';
  String _textBeforeListening = '';


  // Add a flag to track User Intent
  // bool _isListeningWanted = false;

  @override
  initState(){
    chatViewController.connectSearchAiSocket(widget.chatType);
    listenForPermissions();
    super.initState();
  }

  Future<void> listenForPermissions() async {
    final status = await Permission.microphone.status;
    switch (status) {
      case PermissionStatus.denied:
        requestForPermission();
        break;
      case PermissionStatus.granted:
      case PermissionStatus.limited: // iOS limited access
        _initSpeech();
        break;
      case PermissionStatus.permanentlyDenied:
      // 4. If permanently denied, you should open settings
        openAppSettings();
        break;
      case PermissionStatus.restricted:
      case PermissionStatus.provisional:
        requestForPermission();
        break;
    }
  }

  Future<void> requestForPermission() async {
    final status = await Permission.microphone.request();

    if (status == PermissionStatus.granted || status == PermissionStatus.limited) {
      _initSpeech();
    } else if (status == PermissionStatus.permanentlyDenied) {
      openAppSettings();
    }
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    log('Initialize');

    if (_speechEnabled) return;

    try {
      var hasSpeech = await _speechToText.initialize(
        onError: errorListener,
        onStatus: statusListener,
        // debugLogging: currentOptions.debugLogging,
      );
      if (mounted) {
        setState(() {
          _speechEnabled = hasSpeech;
        });
      }
    }catch (e) {
      setState(() {
        // _lastError = 'Speech recognition failed: ${e.toString()}';
        _speechEnabled = false;
      });
    }
  }

  void errorListener(SpeechRecognitionError error) {
    log(
        'Received error status: $error, listening: ${_speechToText.isListening}');
    // setState(() {
    //   _lastStatus = '${error.errorMsg} - ${error.permanent}';
    // });
  }

  void statusListener(String status) {
    log(
        'Received listener status: $status, listening: ${_speechToText.isListening}, available: ${_speechToText.isAvailable}');
    // setState(() {
    //   _lastStatus = status;
    // });

  //   if (_speechToText.isAvailable &&
  //   status == 'notListening'  &&
  //       _isListeningWanted) {
  //     log('coming - Restarting Listener');
  //     // The OS stopped us, but the user didn't. Restart!
  //
  //     // Add a tiny delay to prevent CPU spinning
  //     Future.delayed(const Duration(milliseconds: 100), () {
  //       // Check one more time in case user pressed stop during the delay
  //       if (_isListeningWanted) {
  //         _startInternalListen();
  //       }
  //     });
  //   }
  }

  // void _startInternalListen() async {
  //   log('---internal listening---');
  //   await _speechToText.listen(
  //     onResult:(speechResultListener)=>  _onSpeechResult(
  //         speechResultListener, continueSpeaking: true),
  //     listenFor: const Duration(minutes: 2),
  //     pauseFor: const Duration(seconds: 60),
  //     localeId: "en_US",
  //     listenOptions: SpeechListenOptions(
  //         // listenMode: ListenMode.dictation, // (better for continuous speech than Confirmation)
  //         listenMode: ListenMode.confirmation,
  //         onDevice: false,
  //         cancelOnError: false,
  //         partialResults: true,
  //         autoPunctuation: true,
  //         enableHapticFeedback: true
  //     ),
  //   );
  //   setState(() {});
  // }

  void _startListening() async {
    log('---start listening---');
    // _isListeningWanted = true;
    // _lastWords = '';
    // _lastError = '';

    // 1. Save what is already in the text field (e.g., from typing or previous speech)
    _textBeforeListening = chatViewController.sendMessageController.value.text;

    // If there is text, add a space so new speech doesn't stick to it
    if (_textBeforeListening.isNotEmpty && !_textBeforeListening.endsWith(' ')) {
      _textBeforeListening += ' ';
    }

    await _speechToText.listen(
      onResult:(speechResultListener)=>  _onSpeechResult(
          speechResultListener, continueSpeaking: false),
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 60),
      localeId: "en_US",
      listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation, // (better for continuous speech than Confirmation)
          // listenMode: ListenMode.confirmation,
          onDevice: false,
          cancelOnError: false,
          partialResults: true,
          autoPunctuation: true,
          enableHapticFeedback: true
     ),
    );
    setState(() {});
  }

  // onDevice: false (Cloud Mode): Sends your voice to Google/Apple servers. To save bandwidth and server costs, the server automatically cuts the connection if it detects ~3-4 seconds of silence. Your app code cannot override this server-side limit.
  // onDevice: true (Local Mode): Processes voice directly on the phone's chip. Because it doesn't use a server, it respects your pauseFor setting and can listen through long silences.

  void _stopListening() async {
    // _isListeningWanted = false;
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result, {required bool continueSpeaking}) {
    setState(() {
      // if(continueSpeaking){
      //   _lastWords = "$_lastWords${result.recognizedWords} ";
      // }else{
      //   _lastWords = "${result.recognizedWords}";
      // }
      _lastWords = "$_textBeforeListening${result.recognizedWords}";
      chatViewController.sendMessageController.value.text = _lastWords;
      if(chatViewController.sendMessageController.value.text.isNotEmpty){
        chatViewController.isTextFieldEmpty.value = true;
      }else{
        chatViewController.isTextFieldEmpty.value = false;
      }
      log('last words-- ${_lastWords}');

    });
  }

  void _onMicrophoneTap() {
    if (_speechToText.isAvailable) {
      if (_speechToText.isNotListening) {
        _startListening();
      } else {
        _stopListening();
      }
    } else {
      listenForPermissions();
    }
  }

  @override
  void dispose() {
    chatViewController.disposeAiSocket();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fillColor,
      appBar: (chatThemeController.isMessageSelectionActive.value &&
          widget.type != AppStrings.Admin)
          ? getChatOptionsAppBar(
          context,
          profileImage: widget.profileImage,
          editingController: editingController,
          conversationId: widget.conversationId,
          userId: widget.userId,
          type: widget.type,
          name: widget.name,
          contactNo: widget.contactNo)
          : getChatTitleAppBar(
          socketType: "personal",
          context,
          userId: widget.userId,
          type: widget.type,
          name: widget.name,
          profileImage: widget.profileImage,
          contactNo: widget.contactNo,
          conversationId: widget.conversationId,
          onBackCallback:(){
            if (MediaQuery.of(context).viewInsets.bottom > 0) {
              unFocus();
              return;
            }
            Get.back();
          }
      ),
      body: Obx(()=> _UnifiedAiChatWidget()),
    );

  }

  Widget _UnifiedAiChatWidget() {
    // 🟢 USE THE UNIFIED LIST (BaseAiChatModel)
    List<BaseAiChatModel> messages = chatViewController.currentChatMessages;

    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset(
            AppImageAssets.chating_bg,
            fit: BoxFit.cover,
            width: SizeConfig.screenWidth,
            height: SizeConfig.screenHeight,
          ),

          Column(
            children: [
              Expanded(
                child: (messages.isEmpty)
                    ? _buildEmptyState()
                    : LayoutBuilder(
                  builder: (context, constraints) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: SingleChildScrollView(
                            padding: EdgeInsets.zero,
                            controller: chatViewController.scrollController,
                            reverse: (widget.type == AppStrings.Admin) ? false : true,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: messages.map((message) {

                                // 🟢 DYNAMIC MESSAGE BUILDER
                                return _buildMessageWidget(message);

                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Loading Indicator
              (chatViewController.chatBotReading.value == true)
                  ? staggeredDotsWaveLoading(
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
                  color: AppColors.grayText)
                  : SizedBox(height: SizeConfig.size6),

              // 🟢 INPUT FIELD AREA
              _buildInputArea(),

              const SizedBox(height: 14),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMessageWidget(BaseAiChatModel message) {
    // 1. If it's the User's message, show simple bubble
    if (message.role == 'user') {
      return MessageBubble(
        messages: Messages(),
        message: message.message ?? "",
        time:
        formatChatTime(message.timestamp ?? ''),
        isReceiveMsg: false,
      );
    }


    // A. INVENTORY LOGIC
    if (message is InventoryAskAiModel && widget.chatType == AppConstants.askInventory_Chat_Type) {
      return AskInventoryProductMsgCard(response: message);
    }

    // B. FOOD LOGIC
    if (message is FoodAskAiModel && widget.chatType == AppConstants.askFood_Chat_Type) {
       return AskFoodMsgCard(response: message);
    }

    // C. Service LOGIC
    if(message is BusinessServicesAskAiModel && widget.chatType == AppConstants.askService_Chat_Type){
      return AskServiceMsgCard(response: message);
    }

    // D. HEALTH CARE LOGIC
    if(message is HealthCareAskAiModel && widget.chatType == AppConstants.askHealthCare_Chat_Type){
      return AskHealthCareMsgCard(response: message);
    }

    // E. EDUCATION LOGIC
    if(message is EducationAskAiModel && widget.chatType == AppConstants.askEducation_Chat_Type){
      return AskEducationMsgCard(response: message);
    }

    // F. HOME SERVICE LOGIC
    if(message is ServiceAskAiModel && widget.chatType == AppConstants.askHomeService_Chat_Type){
      return AskHomeServiceMsgCard (response: message);
    }

    // G. HOTEL LOGIC(STAY)
    if(message is TravelAndStayAskAiModel && widget.chatType == AppConstants.askTravelStay_Chat_Type){
      return AskTravelStayMsgCard(response: message);
    }

    // F. CONSULTING TALK LOGIC
    if(message is ServiceAskAiModel && widget.chatType == AppConstants.askConsultingTalk_Chat_Type){
      return AskConsultingTalkMsgCard(response: message);
    }

    return MessageBubble(
      messages: Messages(),
      message: message.message ?? "",
      time: message.timestamp ?? '',
      isReceiveMsg: true, // Left side
    );
  }

  Widget _buildEmptyState() {
    String text;
    switch (widget.chatType) { // Use the widget.chatType passed from previous screen
      case AppConstants.askInventory_Chat_Type:
        text = "No conversation yet. Search for Products.";
        break;
      case AppConstants.askFood_Chat_Type:
        text = "No conversation yet. Tell me what you ate.";
        break;
      case AppConstants.askEducation_Chat_Type:
        text = "Start asking about courses or education.";
        break;
      default:
        text = "Start a conversation.";
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    )
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // // Emoji Button
                    // Material(
                    //   color: Colors.transparent,
                    //   child: InkWell(
                    //     borderRadius: BorderRadius.circular(30),
                    //     onTap: _toggleEmojiKeyboard,
                    //     child: Padding(
                    //       padding: const EdgeInsets.all(8.0),
                    //       child: LocalAssets(
                    //         height: 22,
                    //         width: 22,
                    //         imagePath: AppIconAssets.chat_box_smile,
                    //         imgColor: AppColors.chat_input_icon_color,
                    //       ),
                    //     ),
                    //   ),
                    // ),

                    // Text Field
                    Expanded(
                      child: TextFormField(
                        scrollController: _scrollController,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.sentences,
                        controller: chatViewController.sendMessageController
                            .value,
                        minLines: 1,
                        maxLines: 5,
                        onChanged: (value) {
                          if (!value.isEmpty) {
                            chatViewController.isTextFieldEmpty.value =
                            true;
                          } else {
                            chatViewController.isTextFieldEmpty.value =
                            false;
                          }
                        },
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 16),
                        decoration: InputDecoration(
                          hintText: "Type Message...",
                          hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500
                          ),
                          contentPadding: EdgeInsets.only(left: 6, top: 8, bottom: 4),
                          fillColor: Colors.transparent,
                          filled: true,
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          suffixIconConstraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                          ),
                          suffixIcon: Obx(()=> chatViewController.isTextFieldEmpty.value
                              ? Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: InkWell(
                                onTap: () {
                                                            chatViewController.sendMessageController.value.clear();
                                                            chatViewController.isTextFieldEmpty.value = false;
                                                          }, child: Icon(
                                Icons.close,
                                color: AppColors.chat_input_icon_color,
                                size: 20,
                                                          )),
                              )
                              : SizedBox())
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a URL';
                          }
                          final httpsUrlRegex = RegExp('r^https:\/\/[a-zA-Z0-9\-._~:\/?#\[\]@!\$&\'()*+,;=%]+\$');
                          if (!httpsUrlRegex.hasMatch(value)) {
                            return 'Only HTTPS URLs are allowed';
                          }
                          return null;
                        },
                      ),
                    ),

                    // Microphone Button
                    ListeningRipple(
                      isListening: !_speechToText.isNotListening,
                      child: IconButton(
                        icon: Icon(
                          _speechToText.isNotListening ? Icons.mic_off : Icons.mic,
                          color: _speechToText.isNotListening
                              ? AppColors.chat_input_icon_color
                              : Colors.white,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: _speechToText.isNotListening
                              ? null
                              : AppColors.primaryColor,
                        ),
                        onPressed: _onMicrophoneTap,
                      ),
                    ),


                  ],
                ),
              ),
            ),
            SizedBox(width: 8),

            // SEND BUTTON
            Obx(() {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    if (chatViewController.sendMessageController.value.text.isNotEmpty) {

                      chatViewController.sendMessageToAiSearchSocket(
                        type: widget.chatType,
                        message: chatViewController.sendMessageController.value.text.trim(),
                      );

                    }
                  },
                  child: Center(
                    child: Ink(
                      decoration: BoxDecoration(
                        color: chatThemeController.myMessageBgColor.value,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.all(14),
                      child: LocalAssets(
                        imagePath: AppIconAssets.send_message_chat,
                        height: 21,
                        width: 21,
                      ),
                    ),
                  ),
                ),
              );
            })
          ],
        ),
      ),
    );
  }

  // void _toggleEmojiKeyboard() {
  //   if (_isEmojiVisible) {
  //     _focusNode.requestFocus();
  //     setState(() => _isEmojiVisible = false);
  //   } else {
  //     FocusScope.of(context).unfocus();
  //     Future.delayed(const Duration(milliseconds: 100), () {
  //       setState(() => _isEmojiVisible = true);
  //     });
  //   }
  // }

}
