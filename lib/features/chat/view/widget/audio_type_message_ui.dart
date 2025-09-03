import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/model/messageMediaUrl.dart';

class AudioMessageWidget extends StatefulWidget {
  final MessageMediaUrl? audioUrl; // Can be local or network URL
  final bool isReceiveMsg; // Can be local or network URL
  final Messages message;

  const AudioMessageWidget({super.key, required this.audioUrl, required this.isReceiveMsg, required this.message});

  @override
  State<AudioMessageWidget> createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends State<AudioMessageWidget> {
  late AudioPlayer _player;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _init();
  }


  Future<void> _init() async {
    await _player.setUrl(widget.audioUrl?.url??"");
    _duration = _player.duration ?? Duration.zero;

    _player.positionStream.listen((pos) {
      setState(() => _position = pos);
    });

    _player.playerStateStream.listen((state) {
        _isPlaying = state.playing;
    });
  }
  final chatThemeController = Get.find<ChatThemeController>();

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return GestureDetector(
      onLongPress: (){
        chatThemeController.activateSelection(widget.message);
      },
      onTap: () {
        FocusScope.of(context).unfocus();
        if(chatThemeController.isMessageSelectionActive.value){
          chatThemeController.selectMoreMessage(widget.message);
        }else{

        }
      },
      child: Align(
        alignment: (widget.isReceiveMsg) ? Alignment.centerLeft : Alignment.centerRight,
        child: IntrinsicWidth(
          child: Container(
            width: 254,
            // margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:widget.isReceiveMsg? chatThemeController.receiveMessageBgColor.value:chatThemeController.myMessageBgColor.value, // WhatsApp green bubble
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                (widget.isReceiveMsg)?CustomText(
                  "${widget.message.sender?.name}",
                  fontWeight: FontWeight.w900,
                  color: Colors.grey.shade700,
                  fontSize: 12.3,
                ):SizedBox(),
                (widget.isReceiveMsg)?SizedBox(
                  height: 4,
                ):SizedBox(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _formatDuration(_duration),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),

                    // Play/Pause + Seek Bar + FileName + Time
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Play/Pause and Seek
                        Row(mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                _isPlaying ? _player.pause() : _player.play();
                              },
                            ),
                            SizedBox(
                              width: 130,
                              child: Slider(padding: EdgeInsets.symmetric(horizontal: 4,vertical: 0),
                                value: _position.inSeconds.toDouble(),
                                max: _duration.inSeconds.toDouble(),
                                onChanged: (value) {
                                  _player.seek(Duration(seconds: value.toInt()));
                                },
                                activeColor: Colors.yellow,
                                inactiveColor: Colors.white54,
                              ),
                            ),
                          ],
                        ),

                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    return "${duration.inMinutes.remainder(60).toString().padLeft(1, '0')}:${(duration.inSeconds.remainder(60)).toString().padLeft(2, '0')}";
  }
}
