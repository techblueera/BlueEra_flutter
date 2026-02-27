import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/environment_config.dart';
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
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
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

  // final SpeechToText _speechToText = SpeechToText();
  // bool _speechEnabled = false;
  // String _lastWords = "";
  // // String _lastError = '';
  // // String _lastStatus = '';
  // String _textBeforeListening = '';


  // Add a flag to track User Intent
  // bool _isListeningWanted = false;


  // --- CHANGED: Audio Recorder Variables ---
  late final AudioRecorder _audioRecorder;
  // String? _audioPath;

  late final AudioPlayer _audioPlayer;
  Timer? _recordTimer;

  // UI States
  bool _isRecording = false;      // Mic is active
  bool _isAudioTransmitToText = false;  // Recording done, waiting to send
  bool _isPlayingPreview = false; // User is listening to the recorded file
  bool _isRecordingPaused = false;

  // 1. Store all the audio parts here
  List<String> _recordedChunks = [];
  List<int> _chunkDurations = [];

// 2. Track total duration of COMPLETED chunks
  int _accumulatedDuration = 0;

// 3. Current active chunk duration
  int _currentChunkDuration = 0;

  @override
  initState(){
    chatViewController.connectSearchAiSocket(widget.chatType);
    _audioPlayer = AudioPlayer();
    _audioRecorder = AudioRecorder();
    super.initState();
  }

  Future<void> listenForPermissions() async {
    final status = await Permission.microphone.status;
    log('status-- $status');
    switch (status) {
      case PermissionStatus.denied:
        requestForPermission();
        break;
      case PermissionStatus.granted:
      case PermissionStatus.limited: // iOS limited access
        _startRecording();
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
      _startRecording();
    } else if (status == PermissionStatus.permanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();

        // 🟢 GENERATE UNIQUE PATH FOR THIS CHUNK
        final path = '${dir.path}/chunk_${DateTime.now().millisecondsSinceEpoch}.m4a';

        // Start recording to the NEW file
        await _audioRecorder.start(const RecordConfig(), path: path);

        setState(() {
          _isRecording = true;
          _isRecordingPaused = false;
          // _audioPath = path; // Current active chunk
          _currentChunkDuration = 0; // Reset "current chunk" timer
        });

        // 🟢 TIMER LOGIC
        _recordTimer?.cancel();
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _currentChunkDuration++;
          });
        });

        log('Started recording chunk to: $path');
      }
    } catch (e) {
      log('Error starting record: $e');
    }
  }

  // --- 3. Stop Recording & Convert ---
  Future<void> _stopRecordingAndPreview() async {
    _recordTimer?.cancel();

    try {
      // 1. Finalize the current recording chunk (if active)
      if (!_isRecordingPaused) {
        final path = await _audioRecorder.stop();
        if (path != null) {
          _recordedChunks.add(path);
          _chunkDurations.add(_currentChunkDuration);
          _chunkDurations.add(_currentChunkDuration);
        }
      }

      if (_recordedChunks.isNotEmpty) {

        // 2. 🟢 OPTIONAL: Load Player (Only if you want them to be able to play it in case of error)
        // If you are sending immediately, you can technically skip this,
        // but it's good backup in case the API fails and they want to review.
        try {
          final playlist = ConcatenatingAudioSource(
            children: _recordedChunks.map((path) => AudioSource.uri(Uri.parse(path))).toList(),
          );
          await _audioPlayer.setAudioSource(playlist);
        } catch (e) {
          log("Player load error (ignoring since we are sending): $e");
        }

        // 3. 🟢 SEND TO API
        String? extractWords =  await _convertAudioToTextApi(null);
        if(extractWords.isNotEmpty) {
          chatViewController.sendMessageController.value.text = extractWords;
          if(chatViewController.sendMessageController.value.text.isNotEmpty){
            chatViewController.isTextFieldEmpty.value = true;
          }else{
            chatViewController.isTextFieldEmpty.value = false;
          }
        }

        // 4. Update UI
        // We set _isRecording = false, but we do NOT set _isRecordingPaused = true
        // because the API function turns on its own Loading Spinner (_isAudioTransmitToText).
        setState(() {
          _isRecording = false;
        });

      } else {
        // _cancelRecording();
      }

    } catch (e) {
      log('Error stopping record: $e');
      // _cancelRecording();
    }
  }

  void _cancelRecording() async {
    // 1. Stop Timer
    _recordTimer?.cancel();

    // 2. Stop Recorder (if active)
    if (await _audioRecorder.isRecording()) {
      await _audioRecorder.stop();
    }

    // 3. Stop Player (if active)
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      }
    } catch (e) {
      // Ignore player errors
    }

    // 4. Reset ALL State
    setState(() {
      // UI Flags
      _isRecording = false;
      _isRecordingPaused = false;
      _isPlayingPreview = false;
      // _audioPath = null;
      _recordedChunks.clear();
      _chunkDurations.clear();
      _accumulatedDuration = 0;
      _currentChunkDuration = 0;
    });

    log("Recording session cancelled. All chunks cleared.");
  }

  void _togglePreviewPlay() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
      setState(() => _isPlayingPreview = false);
    } else {
      await _audioPlayer.play();
      setState(() => _isPlayingPreview = true);

      // Reset when ENTIRE playlist finishes
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() => _isPlayingPreview = false);
          _audioPlayer.seek(Duration.zero, index: 0); // Reset to start of first file
          _audioPlayer.pause();
        }
      });
    }
  }

  void _onMicrophoneTap() {
    listenForPermissions();
  }

  Future<void> _togglePause() async {
    if (_isRecordingPaused) {
      // --- RESUME (Start New Chunk) ---

      // 1. Stop the player if user was listening during pause
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      }

      // 2. Start recording new chunk
      await _startRecording(); // This sets _isRecordingPaused = false

    } else {
      // --- PAUSE (Stop & Save Chunk & Prepare for Listening) ---
      _recordTimer?.cancel();

      // 1. Stop recorder to save current chunk
      final path = await _audioRecorder.stop();

      if (path != null) {
        // 2. Add to our list
        _recordedChunks.add(path);

        // 🟢 SAVE DURATION
        _chunkDurations.add(_currentChunkDuration);
      }

      // 3. 🟢 PREPARE PLAYER IMMEDIATELY
      // We load all chunks so the user can click "Play" while paused.
      if (_recordedChunks.isNotEmpty) {
        try {
          final playlist = ConcatenatingAudioSource(
            children: _recordedChunks.map((p) => AudioSource.uri(Uri.parse(p))).toList(),
          );
          await _audioPlayer.setAudioSource(playlist);
        } catch (e) {
          log("Error loading playlist: $e");
        }
      }

      setState(() {
        _isRecordingPaused = true;
      });
    }
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<String> _convertAudioToTextApi(String? singleFilePath) async {
    // 1. Update UI to show loading state
    setState(() {
      _isAudioTransmitToText = true; // Show loading spinner
    });

    try {

      // Initialize the Flash model (Fast & supports Audio)
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: geminiApiKey,
      );

      // ---------------------------------------------------------
      // 🟢 PREPARE DATA (Handle Multiple Chunks)
      // ---------------------------------------------------------
      List<Part> parts = [];

      // Add the instruction prompt
      parts.add(TextPart("Please transcribe this audio exactly as spoken. Do not add any introduction or summary."));

      // Check if we have chunks (from Pause/Resume) or a single file
      if (_recordedChunks.isNotEmpty) {
        for (String path in _recordedChunks) {
          final file = File(path);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            // Gemini accepts 'audio/mp4' for .m4a files
            parts.add(DataPart('audio/mp4', bytes));
          }
        }
      } else if (singleFilePath != null) {
        // Fallback for single file
        final file = File(singleFilePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          parts.add(DataPart('audio/mp4', bytes));
        }
      }

      if (parts.length <= 1) {
        log("Error: No audio data found to send.");
        _resetUI();
        return "";
      }

      // ---------------------------------------------------------
      // 🟢 SEND TO GEMINI
      // ---------------------------------------------------------
      log("Sending ${parts.length - 1} audio parts to Gemini...");

      final response = await model.generateContent([
        Content.multi(parts)
      ]);

      final text = response.text;
      log("Gemini Transcription: $text");

      _resetUI(); // Clear flags and lists
      return text ?? "";

    } catch (e) {
      log("Error transcribing with Gemini: $e");
      _resetUI();
      return "";
    }
  }

// Helper to reset UI and clear data
  void _resetUI() {
    setState(() {
      // UI Flags
      _isRecording = false;
      _isAudioTransmitToText = false;
      _isRecordingPaused = false;
      _isPlayingPreview = false;
      // _audioPath = null;
      _recordedChunks.clear();
      _chunkDurations.clear();
      _accumulatedDuration = 0;
      _currentChunkDuration = 0;
    });
  }



  // /// This has to happen only once per app
  // void _initSpeech() async {
  //   log('Initialize');
  //
  //   if (_speechEnabled) return;
  //
  //   try {
  //     var hasSpeech = await _speechToText.initialize(
  //       onError: errorListener,
  //       onStatus: statusListener,
  //       // debugLogging: currentOptions.debugLogging,
  //     );
  //     if (mounted) {
  //       setState(() {
  //         _speechEnabled = hasSpeech;
  //       });
  //     }
  //   }catch (e) {
  //     setState(() {
  //       // _lastError = 'Speech recognition failed: ${e.toString()}';
  //       _speechEnabled = false;
  //     });
  //   }
  // }
  //
  // void errorListener(SpeechRecognitionError error) {
  //   log(
  //       'Received error status: $error, listening: ${_speechToText.isListening}');
  //   // setState(() {
  //   //   _lastStatus = '${error.errorMsg} - ${error.permanent}';
  //   // });
  // }
  //
  // void statusListener(String status) {
  //   log(
  //       'Received listener status: $status, listening: ${_speechToText.isListening}, available: ${_speechToText.isAvailable}');
  //   // setState(() {
  //   //   _lastStatus = status;
  //   // });
  //
  // //   if (_speechToText.isAvailable &&
  // //   status == 'notListening'  &&
  // //       _isListeningWanted) {
  // //     log('coming - Restarting Listener');
  // //     // The OS stopped us, but the user didn't. Restart!
  // //
  // //     // Add a tiny delay to prevent CPU spinning
  // //     Future.delayed(const Duration(milliseconds: 100), () {
  // //       // Check one more time in case user pressed stop during the delay
  // //       if (_isListeningWanted) {
  // //         _startInternalListen();
  // //       }
  // //     });
  // //   }
  // }
  //
  // // void _startInternalListen() async {
  // //   log('---internal listening---');
  // //   await _speechToText.listen(
  // //     onResult:(speechResultListener)=>  _onSpeechResult(
  // //         speechResultListener, continueSpeaking: true),
  // //     listenFor: const Duration(minutes: 2),
  // //     pauseFor: const Duration(seconds: 60),
  // //     localeId: "en_US",
  // //     listenOptions: SpeechListenOptions(
  // //         // listenMode: ListenMode.dictation, // (better for continuous speech than Confirmation)
  // //         listenMode: ListenMode.confirmation,
  // //         onDevice: false,
  // //         cancelOnError: false,
  // //         partialResults: true,
  // //         autoPunctuation: true,
  // //         enableHapticFeedback: true
  // //     ),
  // //   );
  // //   setState(() {});
  // // }
  //
  // void _startListening() async {
  //   log('---start listening---');
  //   // _isListeningWanted = true;
  //   // _lastWords = '';
  //   // _lastError = '';
  //
  //   // 1. Save what is already in the text field (e.g., from typing or previous speech)
  //   _textBeforeListening = chatViewController.sendMessageController.value.text;
  //
  //   // If there is text, add a space so new speech doesn't stick to it
  //   if (_textBeforeListening.isNotEmpty && !_textBeforeListening.endsWith(' ')) {
  //     _textBeforeListening += ' ';
  //   }
  //
  //   await _speechToText.listen(
  //     onResult:(speechResultListener)=>  _onSpeechResult(
  //         speechResultListener, continueSpeaking: false),
  //     listenFor: const Duration(minutes: 5),
  //     pauseFor: const Duration(seconds: 60),
  //     localeId: "en_US",
  //     listenOptions: SpeechListenOptions(
  //         listenMode: ListenMode.dictation, // (better for continuous speech than Confirmation)
  //         // listenMode: ListenMode.confirmation,
  //         onDevice: false,
  //         cancelOnError: false,
  //         partialResults: true,
  //         autoPunctuation: true,
  //         enableHapticFeedback: true
  //    ),
  //   );
  //   setState(() {});
  // }
  //
  // // onDevice: false (Cloud Mode): Sends your voice to Google/Apple servers. To save bandwidth and server costs, the server automatically cuts the connection if it detects ~3-4 seconds of silence. Your app code cannot override this server-side limit.
  // // onDevice: true (Local Mode): Processes voice directly on the phone's chip. Because it doesn't use a server, it respects your pauseFor setting and can listen through long silences.
  //
  // void _stopListening() async {
  //   // _isListeningWanted = false;
  //   await _speechToText.stop();
  //   setState(() {});
  // }
  //
  // void _onSpeechResult(SpeechRecognitionResult result, {required bool continueSpeaking}) {
  //   setState(() {
  //     // if(continueSpeaking){
  //     //   _lastWords = "$_lastWords${result.recognizedWords} ";
  //     // }else{
  //     //   _lastWords = "${result.recognizedWords}";
  //     // }
  //     _lastWords = "$_textBeforeListening${result.recognizedWords}";
  //     chatViewController.sendMessageController.value.text = _lastWords;
  //     if(chatViewController.sendMessageController.value.text.isNotEmpty){
  //       chatViewController.isTextFieldEmpty.value = true;
  //     }else{
  //       chatViewController.isTextFieldEmpty.value = false;
  //     }
  //     log('last words-- ${_lastWords}');
  //
  //   });
  // }
  // void _onMicrophoneTap() {
  //   if (_speechToText.isAvailable) {
  //     if (_speechToText.isNotListening) {
  //       _startListening();
  //     } else {
  //       _stopListening();
  //     }
  //   } else {
  //     listenForPermissions();
  //   }
  // }

  @override
  void dispose() {
    chatViewController.disposeAiSocket();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _recordTimer?.cancel();
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
          )
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
    if (_isRecording) {
      return _buildAudioRecorderUI();
    }

    return _buildTextInputUI();
  }

  Widget _buildTextInputUI(){
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
                    IconButton(
                      icon: Icon(Icons.mic, color: AppColors.primaryColor),
                      onPressed: _onMicrophoneTap,
                    ),

                    // // Microphone Button
                    // ListeningRipple(
                    //   isListening: !_speechToText.isNotListening,
                    //   child: IconButton(
                    //     icon: Icon(
                    //       _speechToText.isNotListening ? Icons.mic_off : Icons.mic,
                    //       color: _speechToText.isNotListening
                    //           ? AppColors.chat_input_icon_color
                    //           : Colors.white,
                    //     ),
                    //     style: IconButton.styleFrom(
                    //       backgroundColor: _speechToText.isNotListening
                    //           ? null
                    //           : AppColors.primaryColor,
                    //     ),
                    //     onPressed: _onMicrophoneTap,
                    //   ),
                    // ),


                  ],
                ),
              ),
            ),
            SizedBox(width: 8),

            // SEND BUTTON
            _buildSendButton(isAudio: false),

          ],
        ),
      ),
    );
  }

  // --- B. The WhatsApp Style Audio Recorder UI ---
  Widget _buildAudioRecorderUI() {
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))
                  ],
                ),
                child: _buildRecordingCompleteUI(),
              ),
            ),
            SizedBox(width: 8),

            // Send Audio Button
            // if (_isAudioRecorded)
            _buildSendButton(isAudio: true),
          ],
        ),
      ),
    );
  }

// 1. UI While Recording (Blinking Red Dot + Timer + Cancel)
  Widget _buildRecordingCompleteUI() {
    return Column(
      children: [

        _isRecordingPaused
          ? _buildPreviewUI()
          : _buildRecordingUI(),

        Row(
          children: [
            IconButton(
              icon: Icon(
                  Icons.delete_outline,
                size: 24,
                color: Colors.red,
              ),
              onPressed: _cancelRecording,
            ),
            SizedBox(width: 10),

            Spacer(),

            // Swipe Text (Optional)
            Text("Recording...", style: TextStyle(color: Colors.grey)),
            Spacer(),

            SizedBox(width: 10),

            // Stop Button (Done)
            IconButton(
              icon: Icon(
                  _isRecordingPaused ? Icons.mic : Icons.pause,
                  color: AppColors.secondaryTextColor,
                  size: 24
              ),
              onPressed: _togglePause,
            ),
            // IconButton(
            //   icon: Icon(Icons.stop_circle_outlined, color: Colors.red, size: 28),
            //   onPressed: _stopRecordingAndPreview,
            // ),
          ],
        ),
      ],
    );
  }

// 2. UI After Recording (Play/Pause + Trash + Send)
  Widget _buildPreviewUI() {
    return Padding(
      padding: const EdgeInsets.only(
          top: 15,
          left: 10,
          right: 10,
          bottom: 10
      ),
      // 🟢 MOVED STREAMBUILDER UP: Now it wraps the whole Row
      child: StreamBuilder<Duration>(
        stream: _audioPlayer.positionStream,
        builder: (context, snapshot) {

          // --- 1. CALCULATIONS (Now available to everyone below) ---
          final currentChunkPosition = snapshot.data ?? Duration.zero;
          final int currentIndex = _audioPlayer.currentIndex ?? 0;

          // Calculate Total Duration
          final int totalSeconds = _chunkDurations.fold(0, (sum, item) => sum + item);
          final Duration totalDuration = Duration(seconds: totalSeconds);

          // Calculate Cumulative Position
          int previousChunksSeconds = 0;
          if (currentIndex < _chunkDurations.length) {
            previousChunksSeconds = _chunkDurations
                .take(currentIndex)
                .fold(0, (sum, item) => sum + item);
          }

          final Duration cumulativePosition = Duration(seconds: previousChunksSeconds) + currentChunkPosition;

          // Calculate Progress (0.0 to 1.0)
          double progress = 0.0;
          if (totalDuration.inMilliseconds > 0) {
            progress = cumulativePosition.inMilliseconds / totalDuration.inMilliseconds;
            progress = progress.clamp(0.0, 1.0);
          }

          // --- 2. BUILD THE UI ---
          return Row(
            children: [

              // Play/Pause Button
              InkWell(
                onTap: _togglePreviewPlay,
                child: Icon(
                    _isPlayingPreview ? Icons.pause : Icons.play_arrow,
                    color: AppColors.secondaryTextColor,
                    size: 24
                ),
              ),

              SizedBox(width: SizeConfig.size15),

              // Waveform / Progress Bar
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                ),
              ),

              SizedBox(width: SizeConfig.size15),

              // Duration Text (Now works because it's inside the builder scope)
              CustomText(
                  "${_formatDuration(cumulativePosition.inSeconds)} / ${_formatDuration(totalDuration.inSeconds)}",
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondaryTextColor
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecordingUI(){

    final int totalSeconds = _accumulatedDuration + _currentChunkDuration;

    return Padding(
      padding: const EdgeInsets.only(
          top: 15,
          left: 10,
          right: 10,
          bottom: 17
      ),
      child: Row(
        children: [
          CustomText(
              _formatDuration(totalSeconds),
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.bold,
              color: AppColors.secondaryTextColor
          ),

          SizedBox(width: SizeConfig.size10),

          Expanded(
            child: SizedBox(
              height: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
                  minHeight: 4,
                ),
              ),
            ),
          ),
        ],),
    );
  }

  // Common Send Button
  Widget _buildSendButton({required bool isAudio}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          if (isAudio) {
            // SEND AUDIO FILE TO API
            _stopRecordingAndPreview();

            // if(_audioPath!=null) {
            //   _convertAudioToTextApi(_audioPath!);
            // }else{
            //   commonSnackBar(message: 'There is no audio');
            // }

          } else {
            // SEND TEXT
            if (chatViewController.sendMessageController.value.text.isNotEmpty) {
              chatViewController.sendMessageToAiSearchSocket(
                type: widget.chatType,
                message: chatViewController.sendMessageController.value.text.trim(),
              );

            }
          }
        },
        child: Center(
          child: Ink(
            decoration: BoxDecoration(
              color: chatThemeController.myMessageBgColor.value,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.all(14),
            child: isAudio && _isAudioTransmitToText
                ? Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                  ),
                )
                : LocalAssets(
                  imagePath: AppIconAssets.send_message_chat, // Change icon if needed
                  height: 21,
                  width: 21,
                  imgColor: Colors.white,
                ),
          ),
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
