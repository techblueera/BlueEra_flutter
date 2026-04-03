import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/services/chat_media_compression_service.dart';
import 'package:BlueEra/features/chat/view/widget/picked_media_preview.dart';
import 'package:BlueEra/features/chat/view/widget/quick_reply_bottom_sheet.dart';
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
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/constants/app_icon_assets.dart';
import '../../../../core/constants/common_methods.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetListOfMessageData.dart';
import 'component_widgets.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar(
      {super.key, required this.conversationId,  this.userId, required this.isInitialMessage, this.hideMedia});

  final String conversationId;
   final String? userId;
  final bool isInitialMessage;
  final bool? hideMedia;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar>   with WidgetsBindingObserver {
  bool get isInitialFlow => widget.isInitialMessage && widget.conversationId.isEmpty;
  bool isKeyboardVisible = false;
  final chatViewController = Get.find<ChatViewController>();
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
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  String _transcribedText = '';
  bool _isSpeechAvailable = false;

  String _formatRecordDuration(Duration d) {
    String minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
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
    _recordingTimer?.cancel();
    _speechToText.stop();
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
        _recordingDuration = Duration.zero;
        _transcribedText = '';
      });

      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration += Duration(seconds: 1);
        });
      });

      _startSpeechRecognition();
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
      _recordingTimer?.cancel();
      _recordingTimer = null;
      _speechToText.stop();
      final path = await _audioRecorder.stopRecorder();
      setState(() {
        isRecording = false;
        isPaused = false;
        _recordingDuration = Duration.zero;
      });
      print("Recording stopped. File saved at: $path");
    } catch (e) {
      print("Error stopping recorder: $e");
    }
  }

  Future<void> pauseRecording() async {
    try {
      _recordingTimer?.cancel();
      _recordingTimer = null;
      await _audioRecorder.pauseRecorder();
      _speechToText.stop();
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
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration += Duration(seconds: 1);
        });
      });
      _startSpeechRecognition();
      print("Recording resumed");
    } catch (e) {
      print("Error resuming recorder: $e");
    }
  }

  Future<void> cancelRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _speechToText.stop();
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
      _recordingDuration = Duration.zero;
      _transcribedText = '';
    });
    print("Recording canceled");
  }

  Future<void> _startSpeechRecognition() async {
    if (!_isSpeechAvailable) {
      _isSpeechAvailable = await _speechToText.initialize(
        onError: (error) => print("Speech error: ${error.errorMsg}"),
      );
    }
    if (_isSpeechAvailable) {
      _speechToText.listen(
        onResult: (result) {
          setState(() {
            _transcribedText = result.recognizedWords;
          });
        },
        listenFor: Duration(minutes: 5),
        pauseFor: Duration(seconds: 10),
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      );
    }
  }

  Future<void> _showAudioSendDialog() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _speechToText.stop();
    await _audioRecorder.stopRecorder();

    if (!mounted) return;

    final duration = _formatRecordDuration(_recordingDuration);
    final hasTranscription = _transcribedText.trim().isNotEmpty;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                // Animated audio waveform icon
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryColor.withValues(alpha: 0.15),
                        Color(0xFF7C4DFF).withValues(alpha: 0.10),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    size: 32,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: 14),
                CustomText(
                  'Recording Ready',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                SizedBox(height: 4),
                CustomText(
                  'Duration: $duration',
                  fontSize: 13,
                  color: AppColors.grayText,
                ),
                SizedBox(height: 6),
                CustomText(
                  'How would you like to send this?',
                  fontSize: 13,
                  color: AppColors.grayText,
                ),
                SizedBox(height: 22),
                // Option cards row
                Row(
                  children: [
                    // Send as Audio
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _sendAsAudioFile();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryColor,
                                Color(0xFF0066CC),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryColor.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.mic_rounded, color: Colors.white, size: 24),
                              ),
                              SizedBox(height: 10),
                              CustomText(
                                'Send Audio',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              SizedBox(height: 2),
                              CustomText(
                                'Voice message',
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 14),
                    // Send as Text
                    Expanded(
                      child: GestureDetector(
                        onTap: hasTranscription
                            ? () {
                                Navigator.pop(ctx);
                                _sendAsText();
                              }
                            : null,
                        child: Opacity(
                          opacity: hasTranscription ? 1.0 : 0.45,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF7C4DFF),
                                  Color(0xFF5B2FE6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF7C4DFF).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.text_fields_rounded, color: Colors.white, size: 24),
                                ),
                                SizedBox(height: 10),
                                CustomText(
                                  'Send as Text',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 2),
                                CustomText(
                                  hasTranscription ? 'Speech to text' : 'No speech found',
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Transcription preview
                if (hasTranscription) ...[
                  SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFF7C4DFF).withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.format_quote_rounded, size: 18, color: Color(0xFF7C4DFF)),
                        SizedBox(width: 8),
                        Expanded(
                          child: CustomText(
                            _transcribedText.trim(),
                            fontSize: 13,
                            color: Color(0xFF3D3366),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 16),
                // Cancel button
                GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _resetRecordingState();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: CustomText(
                        'Discard Recording',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendAsAudioFile() async {
    final filePath = recordedFilePath ?? '';
    setState(() {
      isRecording = false;
      isReadyToSend = false;
      isPaused = false;
      _recordingDuration = Duration.zero;
      _transcribedText = '';
    });
    if (filePath.isNotEmpty) {
      await submitRecordedAudio(filePath);
    }
    recordedFilePath = null;
  }

  Future<void> _sendAsText() async {
    final text = _transcribedText.trim();
    _resetRecordingState();

    if (text.isEmpty) {
      commonSnackBar(message: "Could not recognize any speech. Please try again.");
      return;
    }

    Messages? reply = chatViewController.replyMessage?.value;
    Map<String, dynamic> data;

    if (isInitialFlow) {
      data = {
        ApiKeys.other_user_id: widget.userId,
        ApiKeys.message: text,
        ApiKeys.message_type: "text",
      };
    } else if (reply?.id != null) {
      data = {
        if (isInitialFlow)
          ApiKeys.other_user_id: widget.userId
        else
          ApiKeys.conversation_id: widget.conversationId,
        ApiKeys.message: text,
        ApiKeys.reply_id: "${reply?.id}",
        ApiKeys.message_type: "text",
      };
    } else {
      data = {
        if (isInitialFlow)
          ApiKeys.other_user_id: widget.userId
        else
          ApiKeys.conversation_id: widget.conversationId,
        ApiKeys.message: text,
        ApiKeys.message_type: "text",
      };
    }

    print('SEND PAYLOAD (audio-to-text): ' + data.toString());
    sendMessageToUser(data: data, isInitial: isInitialFlow);
  }

  void _resetRecordingState() {
    setState(() {
      isRecording = false;
      isReadyToSend = false;
      isPaused = false;
      _recordingDuration = Duration.zero;
      _transcribedText = '';
      recordedFilePath = null;
    });
  }

  bool _hasReplyMedia(Messages? reply) {
    if (reply?.url != null && reply!.url!.isNotEmpty) {
      final type = reply.messageType;
      return type == 'image' || type == 'video' || type == 'document';
    }
    return false;
  }

  String? _getReplyMediaUrl(Messages? reply) {
    if (reply?.url != null && reply!.url!.isNotEmpty) {
      return reply.url!.first.url;
    }
    return null;
  }

  String _getReplyTypeLabel(Messages reply) {
    switch (reply.messageType) {
      case 'image': return 'Photo';
      case 'video': return 'Video';
      case 'document': return 'Document';
      case 'audio': return 'Audio';
      case 'contact': return 'Contact';
      case 'location': return 'Location';
      case 'live_location': return 'Live Location';
      default: return reply.message ?? '';
    }
  }

  IconData? _getReplyTypeIcon(Messages reply) {
    switch (reply.messageType) {
      case 'image': return Icons.photo_camera;
      case 'video': return Icons.videocam;
      case 'document': return Icons.insert_drive_file;
      case 'audio': return Icons.mic;
      case 'contact': return Icons.person;
      case 'location': return Icons.location_on;
      case 'live_location': return Icons.location_on;
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {

    // Treat as initial only when conversationId is actually empty
    final bool isInitialFlow = widget.isInitialMessage && widget.conversationId.isEmpty;

    return Column(
      children: [
        Obx(() {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                child: Row(crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Reply preview inside input container
                            Obx(() {
                              Messages? reply = chatViewController.replyMessage?.value;
                              if (reply?.id == null) return SizedBox.shrink();
                              final bool hasMedia = _hasReplyMedia(reply);
                              final String? mediaUrl = _getReplyMediaUrl(reply);
                              final String senderName = (reply?.myMessage ?? false)
                                  ? "You"
                                  : reply?.sender?.name ?? "";
                              return Stack(
                                children: [
                                Container(
                                margin: EdgeInsets.only(left: 6, right: 6, top: 6),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF0F2F5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    // Left color accent bar
                                    Container(
                                      width: 4,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(8),
                                          bottomLeft: Radius.circular(8),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    // Text content
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(vertical: 6),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CustomText(
                                              senderName,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primaryColor,
                                              maxLines: 1,
                                            ),
                                            SizedBox(height: 2),
                                            Row(
                                              children: [
                                                if (_getReplyTypeIcon(reply!) != null) ...[
                                                  Icon(
                                                    _getReplyTypeIcon(reply),
                                                    size: 14,
                                                    color: AppColors.grayText,
                                                  ),
                                                  SizedBox(width: 3),
                                                ],
                                                Expanded(
                                                  child: CustomText(
                                                    reply.messageType == 'text'
                                                        ? (reply.message ?? '')
                                                        : _getReplyTypeLabel(reply),
                                                    fontSize: 12,
                                                    color: AppColors.grayText,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Media thumbnail on the right
                                    if (hasMedia && (reply.messageType == 'image' || reply.messageType == 'video'))
                                      Padding(
                                        padding: EdgeInsets.only(left: 6),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(8),
                                            bottomRight: Radius.circular(8),
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Image.network(
                                                mediaUrl ?? '',
                                                width: 52,
                                                height: 52,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(
                                                  width: 52, height: 52,
                                                  color: Colors.grey.shade300,
                                                  child: Icon(Icons.broken_image, size: 20, color: Colors.grey),
                                                ),
                                              ),
                                              if (reply.messageType == 'video')
                                                Icon(Icons.play_circle_fill, size: 24, color: Colors.white70),
                                            ],
                                          ),
                                        ),
                                      )
                                    else if (hasMedia && reply.messageType == 'document')
                                      Padding(
                                        padding: EdgeInsets.only(left: 6, right: 8),
                                        child: Container(
                                          width: 40, height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Icon(Icons.insert_drive_file, size: 22, color: Colors.red.shade400),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Close button positioned top-right
                              Positioned(
                                top: 8,
                                right: 10,
                                child: GestureDetector(
                                  onTap: () {
                                    chatViewController.setReplyMessage(Messages());
                                  },
                                  child: Icon(Icons.close, size: 18, color: AppColors.grayText),
                                ),
                              ),
                              ],
                              );
                            }),
                            // Input row
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: (isRecording)
                            ? Padding(
                          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          child: Row(
                            children: [
                              // Delete button
                              GestureDetector(
                                onTap: cancelRecording,
                                child: Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 20),
                                ),
                              ),
                              SizedBox(width: 12),
                              // Recording indicator + timer
                              Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                  color: isPaused ? Colors.grey : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8),
                              CustomText(
                                _formatRecordDuration(_recordingDuration),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              SizedBox(width: 6),
                              CustomText(
                                isPaused ? "Paused" : "Recording",
                                fontSize: 12,
                                color: isPaused ? AppColors.grayText : Colors.red.shade400,
                              ),
                              Spacer(),
                              // Pause/Resume button
                              GestureDetector(
                                onTap: () {
                                  if (isPaused) {
                                    resumeRecording();
                                  } else {
                                    pauseRecording();
                                  }
                                },
                                child: Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                    color: AppColors.primaryColor,
                                    size: 22,
                                  ),
                                ),
                              ),
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
                                      return Colors.grey..withValues(alpha: 0.4); // pressed
                                    }
                                    if (states.contains(WidgetState.hovered)) {
                                      return Colors.grey.withValues(alpha: 0.2); // hover
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
                                    // Emit typing indicator (debounced)
                                    if (widget.conversationId.isNotEmpty) {
                                      chatViewController.emitTyping(
                                          widget.conversationId);
                                    }
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
                            if(widget.hideMedia!=true)
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
                            return Colors.grey..withValues(alpha: 0.4); // pressed
                          }
                          if (states.contains(WidgetState.hovered)) {
                            return Colors.grey.withValues(alpha: 0.2); // hover
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
                            if(widget.hideMedia!=true)
                            ( chatViewController.isTextFieldEmpty.value)?SizedBox():SizedBox(width: 8),
                            if(widget.hideMedia!=true)
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
                                      return Colors.grey..withValues(alpha: 0.4); // pressed
                                    }
                                    if (states.contains(WidgetState.hovered)) {
                                      return Colors.grey.withValues(alpha: 0.2); // hover
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
                                return Colors.grey..withValues(alpha: 0.4); // pressed
                              }
                              if (states.contains(WidgetState.hovered)) {
                                return Colors.grey.withValues(alpha: 0.2); // hover
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
                                if (isInitialFlow) {
                                  data = {
                                    ApiKeys.other_user_id: widget.userId,
                                    ApiKeys.message: "${chatViewController
                                        .sendMessageController.value.text}",
                                    ApiKeys.message_type: "text",
                                  };
                                } else if (reply?.id != null) {
                                  data = {
                                    if(isInitialFlow)
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
                                    if(isInitialFlow)
                                      ApiKeys.other_user_id: widget.userId
                                    else
                                      ApiKeys.conversation_id: widget.conversationId,
                                    ApiKeys.message: "${chatViewController
                                        .sendMessageController.value.text}",
                                    ApiKeys.message_type: "text",
                                  };
                                }
                                print('SEND PAYLOAD (text): '+data.toString());
                                sendMessageToUser(
                                    data: data, isInitial: isInitialFlow);
                              }
                            } else {
                              if (isRecording) {
                                await _showAudioSendDialog();
                              }
                            }
                          },
                          child: Center(
                            child: Ink(
                              decoration: BoxDecoration(
                                color:(chatViewController.isTextFieldEmpty.value || isRecording)?
                                chatThemeController.myMessageBgColor.value:Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: EdgeInsets.all(14),
                              child: (chatViewController.isTextFieldEmpty.value || isRecording)
                                  ? SvgPicture.asset(
                                AppIconAssets.send_message_chat,
                                height: 21,
                                width: 21,
                              )
                                  : GestureDetector(
                                onTap: () => startRecording(Offset.zero),
                                child: SvgPicture.asset(AppIconAssets.chat_mic_icon, color: Colors.black),
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
        // Compress recorded audio before sending
        File audioFile = File(filePath);
        File compressedAudio = (await ChatMediaCompressionService.compressAudio(audioFile)) ?? audioFile;

        String fileName = compressedAudio.path
            .split('/')
            .last;

        dio.MultipartFile audioPart = await dio.MultipartFile.fromFile(
          compressedAudio.path,
          filename: fileName,
        );

        Map<String, dynamic> data = {
          if(isInitialFlow)
            ApiKeys.other_user_id: widget.userId
          else
            ApiKeys.conversation_id: widget.conversationId,
          ApiKeys.message: chatViewController.sendMessageController.value.text,
          ApiKeys.message_type: "audio",
          ApiKeys.files: [audioPart],
        };

        print('SEND PAYLOAD (audio): '+data.toString());
        await sendMessageToUser(
          data: data,
          isInitial: isInitialFlow,
        );
        return  ;
      }
    } catch (e) {
      debugPrint('Failed to submit recorded audio: $e');
    }
  }

  void _showMediaOptions(BuildContext context) {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                childAspectRatio: 0.78,
                crossAxisSpacing: 16,
                mainAxisSpacing: 20,
                children: [
                  // Row 1
                  _buildMediaOption(
                    iconData: Icons.camera_alt_outlined,
                    iconColor: Color(0xFFFF5252),
                    label: 'Camera',
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      Navigator.pop(context);
                      _pickFromCamera();
                    },
                  ),
                  _buildMediaOption(
                    iconData: Icons.photo_outlined,
                    iconColor: Color(0xFF7C4DFF),
                    label: 'Image',
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      Navigator.pop(context);
                      _pickFromGallery(false);
                    },
                  ),
                  _buildMediaOption(
                    iconData: Icons.videocam_outlined,
                    iconColor: Color(0xFFE91E63),
                    label: 'Video',
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      Navigator.pop(context);
                      _pickFromGallery(true);
                    },
                  ),

                  _buildMediaOption(
                    iconData: Icons.description_outlined,
                    iconColor: Color(0xFF5C6BC0),
                    label: 'Document',
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      Navigator.pop(context);
                      await _pickDocument();
                    },
                  ),
                  // Row 2
                  _buildMediaOption(
                    iconData: Icons.headset_outlined,
                    iconColor: Color(0xFFFF6D00),
                    label: 'Audio',
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      Navigator.pop(context);
                      await _pickAudioFile();
                    },
                  ),
                  _buildMediaOption(
                    iconData: Icons.location_on_outlined,
                    iconColor: Color(0xFF009688),
                    label: 'Location',
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      Navigator.pop(context);
                      Navigator.push(
                          context, MaterialPageRoute(builder: (context) =>
                          SendLocationPage(
                              onLiveLocationSubmit: (double lat, double long, String? duration)async{
                                Map<String, dynamic> data = {
                                  if(isInitialFlow)
                                    ApiKeys.other_user_id: widget.userId
                                  else
                                    ApiKeys.conversation_id: widget.conversationId,
                                  ApiKeys.message_type: "live_location",
                                    ApiKeys.message: "Live Location",
                                  ApiKeys.live_location_validity:duration,
                                  ApiKeys.latitude: lat,
                                  ApiKeys.longitude: long,
                                };
                               await sendMessageToUser(data: data, isInitial: isInitialFlow);
                                Get.back();
                          },
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
                    iconData: Icons.person_outline_rounded,
                    iconColor: Color(0xFF2196F3),
                    label: 'Contact',
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      Navigator.pop(context);
                      await _pickContact();
                    },
                  ),
                  _buildMediaOption(
                    iconData: Icons.storefront_outlined,
                    iconColor: Color(0xFFFF9800),
                    label: 'Catalog',
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      Navigator.pop(context);
                      // TODO: Navigate to catalog screen
                    },
                  ),
                  // Row 3
                  _buildMediaOption(
                    iconData: Icons.card_giftcard_outlined,
                    iconColor: Color(0xFFD81B60),
                    label: 'Send Gift',
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      Navigator.pop(context);
                      // TODO: Navigate to send gift screen
                    },
                  ),
                  _buildMediaOption(
                    iconData: Icons.restaurant_outlined,
                    iconColor: Color(0xFFEF6C00),
                    label: 'Book Food',
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      Navigator.pop(context);
                      // TODO: Navigate to book food screen
                    },
                  ),
                  _buildMediaOption(
                    iconData: Icons.local_taxi_outlined,
                    iconColor: Color(0xFF00897B),
                    label: 'Book Ride',
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      Navigator.pop(context);
                      // TODO: Navigate to book ride screen
                    },
                  ),
                  _buildMediaOption(
                    iconData: Icons.quickreply_outlined,
                    iconColor: Color(0xFF8D6E63),
                    label: 'Quick Reply',
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      Navigator.pop(context);
                      showHiveBottomSheet(context,widget.userId??"",widget.conversationId,isInitialFlow);
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'wma', 'flac'],
    );

    if (result != null && result.files.isNotEmpty) {
      String? filePath = result.files.first.path;

      // Compress audio before sending
      File audioFile = File(filePath!);
      File compressedAudio = (await ChatMediaCompressionService.compressAudio(audioFile)) ?? audioFile;

      String fileName = compressedAudio.path.split('/').last;

      dio.MultipartFile audioPart = await dio.MultipartFile.fromFile(
        compressedAudio.path,
        filename: fileName,
      );

      Map<String, dynamic> data = {
        if(isInitialFlow)
          ApiKeys.other_user_id: widget.userId
        else
          ApiKeys.conversation_id: widget.conversationId,
        ApiKeys.message: chatViewController.sendMessageController.value.text,
        ApiKeys.message_type: "audio",
        ApiKeys.files: [audioPart],
      };
      print('SEND PAYLOAD (audio file): '+data.toString());
      sendMessageToUser(data: data, isInitial: isInitialFlow);
    }
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
        if(isInitialFlow)
          ApiKeys.other_user_id: widget.userId
        else
          ApiKeys.conversation_id: widget.conversationId,
        ApiKeys.message: chatViewController.sendMessageController.value.text,
        ApiKeys.message_type: "document",
        ApiKeys.files: documentParts,
      };
      print('SEND PAYLOAD (document): '+data.toString());
      sendMessageToUser(
          data: data, isInitial: isInitialFlow, fileName: fileddName);
    }
  }


  Widget _buildMediaOption({
    required IconData iconData,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  iconColor.withValues(alpha: 0.15),
                  iconColor.withValues(alpha: 0.06),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 26),
          ),
          SizedBox(height: 6),
          CustomText(
            label,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.grayText,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
      if(isInitialFlow)
        ApiKeys.other_user_id: widget.userId
      else
        ApiKeys.conversation_id: widget.conversationId,
      ApiKeys.message_type: "location",
      if(name != null)
        ApiKeys.message: "$name \n${address}",
      ApiKeys.latitude: latitude,
      ApiKeys.longitude: longitude,
    };
    print('SEND PAYLOAD (location): '+data.toString());
    sendMessageToUser(data: data, isInitial: isInitialFlow);
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
          if(isInitialFlow)
            ApiKeys.other_user_id: widget.userId
          else
            ApiKeys.conversation_id: widget.conversationId,
          ApiKeys.message_type: 'contact',
          ApiKeys.shared_contact_name: '$displayName',
          ApiKeys.shared_contact_number: '$phoneNumber',
        };
        print('SEND PAYLOAD (contact): '+contactData.toString());
        sendMessageToUser(
            data: contactData, isInitial: isInitialFlow);
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

                  // Compress media files before upload (~80% size reduction)
                  List<File> selectedFiles = await ChatMediaCompressionService.compressMediaFiles(getFile);

                  List<String?> fileNames = [];
                  List<String?> fileTypes = [];

                  for (var file in selectedFiles) {
                    Map<String, String?> fileInfo = getFileInfo(file);
                    fileNames.add(fileInfo['fileName']);
                    fileTypes.add(fileInfo['mimeType']);
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
                    userId: [widget.userId??''],
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

                  // Compress camera file before upload (~80% size reduction)
                  File originalFile = File(pickedFile.path);
                  File compressedFile = (await ChatMediaCompressionService.compressImage(originalFile)) ?? originalFile;

                  String? imagePath = compressedFile.path;
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
                    if(isInitialFlow)
                      ApiKeys.other_user_id: widget.userId
                    else
                      ApiKeys.conversation_id: widget.conversationId,
                    if(commands != null)
                      ApiKeys.message: commands,
                    ApiKeys.message_type: messageType,
                    ApiKeys.files: imageByPart,
                  };
                  print('SEND PAYLOAD (camera ${messageType}): '+data.toString());
                  sendMessageToUser(
                      data: data, isInitial: isInitialFlow);
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

