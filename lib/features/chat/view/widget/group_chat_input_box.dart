import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/chat/view/widget/picked_media_preview.dart';
import 'package:BlueEra/features/chat/view/widget/send_live_location_page.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:dio/dio.dart' as dio;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_icon_assets.dart';
import '../../../../core/constants/common_methods.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/group_chat_view_controller.dart';
import '../../auth/model/GetListOfMessageData.dart';
import 'component_widgets.dart';

class GroupChatInputBar extends StatefulWidget {
  const GroupChatInputBar(
      {super.key, required this.conversationId, required this.userId, required this.isInitialMessage});

  final String conversationId;
  final String userId;
  final bool isInitialMessage;

  @override
  State<GroupChatInputBar> createState() => _GroupChatInputBarState();
}

class _GroupChatInputBarState extends State<GroupChatInputBar>   with WidgetsBindingObserver {
  bool isKeyboardVisible = false;
  final chatViewController = Get.find<GroupChatViewController>();
  final chatThemeController = Get.find<ChatThemeController>();
  final _scrollController = ScrollController();

  String? imagePath;
  FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  bool isRecording = false;
  bool isReadyToSend = false;
  bool isPaused = false;
  Offset startPosition = Offset.zero;
  Offset currentPosition = Offset.zero;
  String? recordedFilePath;
  final FocusNode _focusNode = FocusNode();
  bool _isEmojiVisible = false;
  void _toggleEmojiKeyboard() {
    if (_isEmojiVisible) {
      _focusNode.requestFocus();
      setState(() => _isEmojiVisible = false);
    } else {
      FocusScope.of(context).unfocus();
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() => _isEmojiVisible = true);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _initializeRecorder() async {
    await _audioRecorder.openRecorder();
  }

  @override
  void dispose() {
    _audioRecorder.closeRecorder();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final newValue = bottomInset > 0.0;

    if (newValue != isKeyboardVisible) {
      setState(() {
        isKeyboardVisible = newValue;
      });
      if(newValue){
        _isEmojiVisible=false;
      }
      print("Keyboard is now: ${isKeyboardVisible ? 'OPEN' : 'CLOSED'}");
    }
  }
  Future<bool> _requestMicrophonePermission() async {
    var status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> startRecording(Offset position) async {
    await _initializeRecorder();
    final hasPermission = await _requestMicrophonePermission();
    if (!hasPermission) {
      commonSnackBar(
          message: "Microphone permission is required");
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/audio_${DateTime
        .now()
        .millisecondsSinceEpoch}.aac';

    try {
      await _audioRecorder.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
      );

      setState(() {
        isRecording = true;
        isPaused = false;
        isReadyToSend = false;
        startPosition = position;
        currentPosition = position;
        recordedFilePath = path;
      });

      print("Recording started: $path");
    } catch (e) {
      print("Failed to start recorder: $e");
    }
  }

  void updateRecording(Offset position) {
    setState(() {
      currentPosition = position;
    });
    double dx = position.dx - startPosition.dx;
    double dy = position.dy - startPosition.dy;

    if (dy < -50) {
      setState(() {
        isReadyToSend = true;
      });
      print("Recording locked");
    } else if (dx < -100) {
      cancelRecording();
    }
  }

  Future<void> stopRecording() async {
    try {
      final path = await _audioRecorder.stopRecorder();
      setState(() {
        isRecording = false;
        isPaused = false;
      });
      print("Recording stopped. File saved at: $path");
    } catch (e) {
      print("Error stopping recorder: $e");
    }
  }

  Future<void> pauseRecording() async {
    try {
      await _audioRecorder.pauseRecorder();
      setState(() {
        isPaused = true;
      });
      print("Recording paused");
    } catch (e) {
      print("Error pausing recorder: $e");
    }
  }

  Future<void> resumeRecording() async {
    try {
      await _audioRecorder.resumeRecorder();
      setState(() {
        isPaused = false;
      });
      print("Recording resumed");
    } catch (e) {
      print("Error resuming recorder: $e");
    }
  }

  Future<void> cancelRecording() async {
    try {
      await _audioRecorder.stopRecorder();
      if (recordedFilePath != null) {
        final file = File(recordedFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      print("Error canceling recording: $e");
    }

    setState(() {
      isRecording = false;
      isReadyToSend = false;
      isPaused = false;
      recordedFilePath = null;
    });
    print("Recording canceled");
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        Obx(() {
          Messages? reply = chatViewController.replyMessage?.value;
          if (reply?.id == null) return SizedBox.shrink();

          return Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Replying to",
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      messageTypeIconWithLabel(reply??Messages()),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20),
                  onPressed: () {
                    chatViewController.setReplyMessage(Messages());
                  },
                )
              ],
            ),
          );
        }),
        Obx(() {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                child: Row(crossAxisAlignment: CrossAxisAlignment.end,
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
                        child: (isRecording)
                            ? Padding(
                          padding: EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [

                              Row(
                                children: [
                                  InkWell(
                                      onTap: cancelRecording,
                                      child: Icon(
                                        Icons.delete, color: Colors.red,)),
                                  const SizedBox(width: 10,),
                                  CustomText((isPaused)
                                      ? "Recording Paused"
                                      : "Recording..."),

                                ],
                              ),
                              InkWell(
                                  onTap: () {
                                    if (isPaused) {
                                      resumeRecording();
                                    } else {
                                      pauseRecording();
                                    }
                                  },
                                  child: Icon(
                                      (isPaused) ? Icons.play_arrow : Icons.pause)),
                              Row(
                                children: [
                                  const CustomText("Slide left to cancel"),
                                ],
                              )
                            ],
                          ),

                        ) :
                        Row(crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                overlayColor: WidgetStateProperty.resolveWith<Color?>(
                                      (states) {
                                    if (states.contains(WidgetState.pressed)) {
                                      return Colors.grey.withOpacity(0.4); // pressed
                                    }
                                    if (states.contains(WidgetState.hovered)) {
                                      return Colors.grey.withOpacity(0.2); // hover
                                    }
                                    return null;
                                  },
                                ),
                                onTap: _toggleEmojiKeyboard,
                                child: Ink(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8,horizontal: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 3.0),
                                    child: SvgPicture.asset(height: 22, width: 22, AppIconAssets
                                        .chat_box_smile, color: AppColors
                                        .chat_input_icon_color,),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                scrollController: _scrollController,
                                keyboardType: TextInputType.text,
                                textCapitalization: TextCapitalization.words,
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
                                  contentPadding: EdgeInsets.only(left: 6,bottom: 10,top: 8),
                                  fillColor: Colors.transparent,
                                  filled: true,
                                  isDense: true,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                ),
                              ),
                            ),

                            Material(
                              color: Colors.transparent,
                              child: InkWell(

                                onTap: () {
                                  _showMediaOptions(context);
                                },
                                borderRadius: BorderRadius.circular(30),
                                overlayColor: WidgetStateProperty.resolveWith<Color?>(
                                      (states) {
                                    if (states.contains(WidgetState.pressed)) {
                                      return Colors.grey.withOpacity(0.4); // pressed
                                    }
                                    if (states.contains(WidgetState.hovered)) {
                                      return Colors.grey.withOpacity(0.2); // hover
                                    }
                                    return null;
                                  },
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    // background if you want
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                                  child: SvgPicture.asset(
                                    AppIconAssets.chat_pick_media,
                                    height: 22,
                                    width: 22,
                                    color: AppColors.chat_input_icon_color,
                                  ),
                                ),
                              ),
                            ),
                            ( chatViewController.isTextFieldEmpty.value)?SizedBox():SizedBox(width: 8),
                            ( chatViewController.isTextFieldEmpty.value)?SizedBox():Material(
                              color: Colors.transparent,

                              child: InkWell(
                                onTap: () {
                                  _pickFromCamera();
                                },
                                borderRadius: BorderRadius.circular(30),
                                overlayColor: WidgetStateProperty.resolveWith<Color?>(
                                      (states) {
                                    if (states.contains(WidgetState.pressed)) {
                                      return Colors.grey.withOpacity(0.4); // pressed
                                    }
                                    if (states.contains(WidgetState.hovered)) {
                                      return Colors.grey.withOpacity(0.2); // hover
                                    }
                                    return null;
                                  },
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    // background if you want
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                                  child: Icon(Icons.camera_alt_outlined,
                                      color: AppColors.chat_input_icon_color,
                                      size: 24),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Obx(() {
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          overlayColor: WidgetStateProperty.resolveWith<Color?>(
                                (states) {
                              if (states.contains(WidgetState.pressed)) {
                                return Colors.grey.withOpacity(0.4); // pressed
                              }
                              if (states.contains(WidgetState.hovered)) {
                                return Colors.grey.withOpacity(0.2); // hover
                              }
                              return null;
                            },
                          ),
                          onTap: () async {
                            if (chatViewController.isTextFieldEmpty.value) {
                              if (chatViewController.sendMessageController.value.text
                                  .isNotEmpty) {
                                Messages? reply = chatViewController.replyMessage
                                    ?.value;
                                Map<String, dynamic> data;
                                if (widget.isInitialMessage) {
                                  data = {
                                    ApiKeys.other_user_id: widget.userId,
                                    ApiKeys.message: "${chatViewController
                                        .sendMessageController.value.text}",
                                    ApiKeys.message_type: "text",
                                  };
                                } else if (reply?.id != null) {
                                  data = {
                                    if(widget.isInitialMessage)
                                      ApiKeys.other_user_id: widget.userId
                                    else
                                      ApiKeys.conversation_id: widget.conversationId,
                                    ApiKeys.message: "${chatViewController
                                        .sendMessageController.value.text}",
                                    ApiKeys.reply_id: "${reply?.id}",
                                    ApiKeys.message_type: "text",
                                  };
                                } else {
                                  data = {
                                    if(widget.isInitialMessage)
                                      ApiKeys.other_user_id: widget.userId
                                    else
                                      ApiKeys.conversation_id: widget.conversationId,
                                    ApiKeys.message: "${chatViewController
                                        .sendMessageController.value.text}",
                                    ApiKeys.message_type: "text",
                                  };
                                }
                                sendMessageToUser(
                                    data: data, isInitial: widget.isInitialMessage);
                              }
                            } else {
                              if (isRecording) {
                                submitRecordedAudio(recordedFilePath ?? "");
                              }
                            }
                          },
                          child: Center(
                            child: Ink(
                              decoration: BoxDecoration(
                                color:(chatViewController.isTextFieldEmpty.value || isRecording)?
                                chatThemeController.myMessageBgColor.value:Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.all(14),
                              child: (chatViewController.isTextFieldEmpty.value || isRecording)
                                  ? SvgPicture.asset(
                                AppIconAssets.send_message_chat,
                                height: 21,
                                width: 21,
                              )
                                  : GestureDetector(
                                onLongPressStart: (details) =>
                                    startRecording(details.globalPosition),
                                onLongPressMoveUpdate: (details) =>
                                    updateRecording(details.globalPosition),
                                onLongPressEnd: (_) {
                                  // stopRecording();
                                },
                                child: SvgPicture.asset(AppIconAssets.chat_mic_icon,color: Colors.black,),
                              ),
                            ),
                          ),
                        ),
                      );
                    })
                  ],
                ),
              ),
              Offstage(
                offstage: !_isEmojiVisible||isKeyboardVisible,
                child: Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: EmojiPicker(onBackspacePressed: (){
                    if(chatViewController.sendMessageController.value.text.isEmpty){
                      chatViewController.isTextFieldEmpty.value = false;
                    }
                  },
                    onEmojiSelected: (va,k){
                      chatViewController.isTextFieldEmpty.value = true;
                    },
                    textEditingController: chatViewController.sendMessageController
                        .value,
                    scrollController: _scrollController,
                    config: Config(
                      height: 296,
                      checkPlatformCompatibility: true,
                      viewOrderConfig: const ViewOrderConfig(),
                      emojiViewConfig: EmojiViewConfig(
                        emojiSizeMax: 28 *
                            (foundation.defaultTargetPlatform ==
                                TargetPlatform.iOS
                                ? 1.2
                                : 1.0),
                      ),
                      skinToneConfig: const SkinToneConfig(),
                      categoryViewConfig: const CategoryViewConfig(),
                      bottomActionBarConfig: const BottomActionBarConfig(),
                      searchViewConfig: const SearchViewConfig(),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Future<void> submitRecordedAudio(String filePath) async {
    try {
      if (filePath.isNotEmpty) {
        String fileName = filePath
            .split('/')
            .last;

        dio.MultipartFile audioPart = await dio.MultipartFile.fromFile(
          filePath,
          filename: fileName,
        );

        Map<String, dynamic> data = {
          if(widget.isInitialMessage)
            ApiKeys.other_user_id: widget.userId
          else
            ApiKeys.conversation_id: widget.conversationId,
          ApiKeys.message: chatViewController.sendMessageController.value.text,
          ApiKeys.message_type: "audio",
          ApiKeys.files: [audioPart],
        };

        await sendMessageToUser(
          data: data,
          isInitial: widget.isInitialMessage,
        );
      }
    } catch (e) {
      debugPrint('Failed to submit recorded audio: $e');
    }
  }

  void _showMediaOptions(BuildContext context) {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      builder: (_) =>
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              childAspectRatio: 1.1,
              crossAxisSpacing: 20,
              mainAxisSpacing: 16,

              children: [
                _buildMediaOption(
                  icon: AppIconAssets.chat_input_gallery,
                  label: 'Image',
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context);
                    _pickFromGallery(false);
                  },
                ),
                _buildMediaOption(
                  icon: AppIconAssets.chat_input_gallery,
                  label: 'Video',
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context);
                    _pickFromGallery(true);
                  },
                ),
                // _buildMediaOption(
                //   icon: AppIconAssets.chat_input_camera,
                //   label: 'Camera',
                //   onTap: () {
                //     Navigator.pop(context);
                //     _pickFromCamera();
                //   },
                // ),
                // _buildMediaOption(
                //   icon: AppIconAssets.chat_input_audio,
                //   label: 'Audio',
                //   onTap: () async{
                //     Navigator.pop(context);
                //     await _pickAudioFile();
                //     // Implement audio logic here
                //   },
                // ),
                _buildMediaOption(
                  icon: AppIconAssets.chat_input_contact,
                  label: 'Contact',
                  onTap: () async {
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context);
                    await _pickContact();
                  },
                ),
                _buildMediaOption(
                  icon: AppIconAssets.chat_input_location,
                  label: 'Location',
                  onTap: () async {
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context);
                    Navigator.push(
                        context, MaterialPageRoute(builder: (context) =>
                        SendLocationPage(
                            onSubmit: (double lat, double long, String? address,
                                String? name) async {
                              await pickCurrentLocation(
                                  lat, long, address, name);
                              Navigator.pop(context);
                            }
                        )));
                  },
                ),
                _buildMediaOption(
                  icon: AppIconAssets.chat_input_document,
                  label: 'Document',
                  onTap: () async {
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context);
                    await _pickDocument();
                  },
                ),
                _buildMediaOption(
                  icon: AppIconAssets.chat_input_quick_reply,
                  label: 'Quick Reply',
                  onTap: () async {
                    FocusScope.of(context).unfocus();
                    // Navigator.pop(context);

                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.isNotEmpty) {
      List<dio.MultipartFile> documentParts = [];
      String? fileddName;
      for (var file in result.files) {
        if (file.path != null) {
          String filePath = file.path!;
          String filedName = filePath
              .split('/')
              .last;
          fileddName = filedName;
          final multipartFile = await dio.MultipartFile.fromFile(
            filePath,
            filename: filedName,
          );

          documentParts.add(multipartFile);
        }
      }

      Map<String, dynamic> data = {
        if(widget.isInitialMessage)
          ApiKeys.other_user_id: widget.userId
        else
          ApiKeys.conversation_id: widget.conversationId,
        ApiKeys.message: chatViewController.sendMessageController.value.text,
        ApiKeys.message_type: "document",
        ApiKeys.files: documentParts,
      };
      sendMessageToUser(
          data: data, isInitial: widget.isInitialMessage, fileName: fileddName);
    }
  }


  Widget _buildMediaOption({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          (label == "Video") ? Padding(
            padding: const EdgeInsets.only(bottom: 2.0, top: 1),
            child: Icon(Icons.video_camera_back_outlined, size: 36,
              color: AppColors.primaryColor,),
          ) : SvgPicture.asset(icon, height: 38,
            width: 38,),
          SizedBox(height: 8),
          CustomText(
            label,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }

  // Future<void> _pickAudioFile() async {
  //   FilePickerResult? result = await FilePicker.platform.pickFiles(
  //     type: FileType.custom,
  //     allowedExtensions: ['mp3', 'wav', 'm4a'],
  //   );
  //
  //   if (result != null && result.files.isNotEmpty) {
  //     String? filePath = result.files.first.path;
  //     String fileName = filePath?.split('/').last ?? '';
  //
  //     dio.MultipartFile audioPart = await dio.MultipartFile.fromFile(
  //       filePath!,
  //       filename: fileName,
  //     );
  //
  //     Map<String, dynamic> data = {
  //       ApiKeys.conversation_id: widget.conversationId,
  //       ApiKeys.message: chatViewController.sendMessageController.value.text,
  //       ApiKeys.message_type: "audio",
  //       ApiKeys.files: audioPart,
  //     };
  //
  //     sendMessageToUser(data: data,isInitial: widget.isInitialMessage);
  //   }
  // }

  Future<void> pickCurrentLocation(double latitude, double longitude,
      String? address, String? name) async {
    Map<String, dynamic> data = {
      if(widget.isInitialMessage)
        ApiKeys.other_user_id: widget.userId
      else
        ApiKeys.conversation_id: widget.conversationId,
      ApiKeys.message_type: "location",
      if(name != null)
        ApiKeys.message: "$name \n${address}",
      ApiKeys.latitude: latitude,
      ApiKeys.longitude: longitude,
    };
    sendMessageToUser(data: data, isInitial: widget.isInitialMessage);
  }


  Future<void> _pickContact() async {
    if (await FlutterContacts.requestPermission()) {
      // Fetch and open contact picker
      final contact = await FlutterContacts.openExternalPick();

      if (contact != null) {
        final displayName = contact.displayName;
        final phoneNumber = contact.phones.isNotEmpty ? contact.phones.first
            .number : '';

        log('Picked contact: $displayName - $phoneNumber');

        final contactData = {
          if(widget.isInitialMessage)
            ApiKeys.other_user_id: widget.userId
          else
            ApiKeys.conversation_id: widget.conversationId,
          ApiKeys.message_type: 'contact',
          ApiKeys.shared_contact_name: '$displayName',
          ApiKeys.shared_contact_number: '$phoneNumber',
        };
        sendMessageToUser(
            data: contactData, isInitial: widget.isInitialMessage);
      } else {
        log("No contact selected");
      }
    } else {
      commonSnackBar(
          message: "Please allow contacts access to share contact.");
    }
  }


  Future<void> _pickFromGallery(bool isVideo) async {
    final picker = ImagePicker();
    List<File> files = [];
    if (isVideo) {
      final XFile? pickedVideo = await picker.pickVideo(
          source: ImageSource.gallery);
      if (pickedVideo != null) {
        files.add(File(pickedVideo.path));
      }
    } else {
      final List<XFile>? pickedImages = await picker.pickMultiImage();
      if (pickedImages != null && pickedImages.isNotEmpty) {
        files.addAll(pickedImages.map((xfile) => File(xfile.path)));
      }
    }
    if (files.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MultiImagePreviewPage(
                mediaFiles: files,
                onSend: (List<File> getFile, String? commands) async {
                  Navigator.pop(context);
                  List<File> selectedFiles = getFile;
                  List<dio.MultipartFile> mediaParts = [];
                  List<String?> fileNames = [];
                  List<String?> fileTypes = [];

                  for (var file in selectedFiles) {
                    String filePath = file.path;
                    String fileName = filePath
                        .split('/')
                        .last;
                    Map<String, String?> fileInfo = getFileInfo(file);
                    fileNames.add(fileInfo['fileName']);
                    fileTypes.add(fileInfo['mimeType']);

                    final multipartFile = await dio.MultipartFile.fromFile(
                      filePath,
                      filename: fileName,
                    );
                    mediaParts.add(multipartFile);
                  }

                  String firstFileExtension = selectedFiles.first.path
                      .split('.')
                      .last
                      .toLowerCase();
                  String messageType = ['mp4', 'mov', 'avi', 'mkv'].contains(
                      firstFileExtension)
                      ? 'video'
                      : 'image';

                  final uploadParams = {
                    ApiKeys.fileName: fileNames,
                    ApiKeys.fileType: fileTypes,
                  };

                  await chatViewController.generateUploadUrlsApi(
                    params: uploadParams,
                    listFile: selectedFiles,
                    isInitialMessage: widget.isInitialMessage,
                    userId: widget.userId,
                    conversationId: widget.conversationId,
                    commands: commands,
                    messageType: messageType,
                  );
                },
              ),
        ),
      );
    }
  }


  Future<void> _pickFromCamera() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MultiImagePreviewPage(
                mediaFiles: [File(pickedFile.path)],
                onSend: (val, String? commands) async {
                  Navigator.pop(context);
                  String? imagePath = File(pickedFile.path).path;
                  String fileName = imagePath
                      .split('/')
                      .last;
                  String fileExtension = fileName
                      .split('.')
                      .last
                      .toLowerCase();
                  String messageType = ['mp4', 'mov', 'avi', 'mkv'].contains(
                      fileExtension)
                      ? 'video'
                      : 'image';

                  dio.MultipartFile? imageByPart = await dio.MultipartFile
                      .fromFile(
                    imagePath,
                    filename: fileName,
                  );

                  Map<String, dynamic> data = {
                    if(widget.isInitialMessage)
                      ApiKeys.other_user_id: widget.userId
                    else
                      ApiKeys.conversation_id: widget.conversationId,
                    if(commands != null)
                      ApiKeys.message: commands,
                    ApiKeys.message_type: messageType,
                    ApiKeys.files: imageByPart,
                  };
                  sendMessageToUser(
                      data: data, isInitial: widget.isInitialMessage);
                },
              ),
        ),
      );
    }
  }

  Future<void> sendMessageToUser(
      {required Map<String, dynamic> data, required bool isInitial, List<
          File>? sendLoadingFiles, String? fileName}) async {
    if (widget.isInitialMessage) {
      chatViewController.sendInitialMessage(data);
    } else {
      chatViewController.sendMessage(data, sendLoadingFiles, fileName);
    }
  }


}

