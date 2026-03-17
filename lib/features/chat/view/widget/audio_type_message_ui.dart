import 'dart:ui';

import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/services/chat_media_storage_service.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/model/messageMediaUrl.dart';

class AudioMessageWidget extends StatefulWidget {
  final MessageMediaUrl? audioUrl;
  final bool isReceiveMsg;
  final Messages message;

  const AudioMessageWidget({super.key, required this.audioUrl, required this.isReceiveMsg, required this.message});

  @override
  State<AudioMessageWidget> createState() => _AudioMessageWidgetState();
}

enum _AudioDlState { idle, downloading, ready }

class _AudioMessageWidgetState extends State<AudioMessageWidget> {
  late AudioPlayer _player;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;

  _AudioDlState _dlState = _AudioDlState.idle;
  double _dlProgress = 0;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    if (widget.isReceiveMsg) {
      _checkLocalFile();
    } else {
      _dlState = _AudioDlState.ready;
      _init();
    }
  }

  Future<void> _checkLocalFile() async {
    final url = widget.audioUrl?.url ?? '';
    if (url.isEmpty) return;
    final existing = await ChatMediaStorageService.findExistingFile(
      url: url, messageType: 'audio', fileName: widget.audioUrl?.name,
    );
    if (existing != null && mounted) {
      setState(() { _dlState = _AudioDlState.ready; _localPath = existing.path; });
      _init();
    }
  }

  Future<void> _download() async {
    final url = widget.audioUrl?.url ?? '';
    if (url.isEmpty) return;
    setState(() { _dlState = _AudioDlState.downloading; _dlProgress = 0; });

    final file = await ChatMediaStorageService.downloadAndSave(
      url: url, messageType: 'audio', fileName: widget.audioUrl?.name,
      onProgress: (r, t) { if (t > 0 && mounted) setState(() => _dlProgress = r / t); },
    );
    if (!mounted) return;
    if (file != null) {
      setState(() { _dlState = _AudioDlState.ready; _localPath = file.path; });
      _init();
    } else {
      setState(() => _dlState = _AudioDlState.idle);
    }
  }

  Future<void> _init() async {
    try {
      if (_localPath != null) {
        await _player.setFilePath(_localPath!);
      } else {
        await _player.setUrl(widget.audioUrl?.url ?? "");
      }
      _duration = _player.duration ?? Duration.zero;
      _player.positionStream.listen((pos) { if (mounted) setState(() => _position = pos); });
      _player.playerStateStream.listen((state) { if (mounted) setState(() => _isPlaying = state.playing); });
    } catch (_) {}
  }

  final chatThemeController = Get.find<ChatThemeController>();

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isReceiveMsg
        ? chatThemeController.receiveMessageBgColor.value
        : chatThemeController.myMessageBgColor.value;

    return Align(
      alignment: widget.isReceiveMsg ? Alignment.centerLeft : Alignment.centerRight,
      child: IntrinsicWidth(
        child: Container(
          width: 254,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _dlState == _AudioDlState.ready
              ? _buildPlayer()
              : _buildDownloadState(),
        ),
      ),
    );
  }

  Widget _buildDownloadState() {
    return SizedBox(
      height: 56,
      child: Stack(
        children: [
          // Blurred placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
          // Download button / progress
          Center(
            child: _dlState == _AudioDlState.downloading
                ? _circularProgress()
                : _downloadBtn(),
          ),
        ],
      ),
    );
  }

  Widget _downloadBtn() {
    return GestureDetector(
      onTap: _download,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_rounded, color: Colors.white, size: 20),
            SizedBox(width: 4),
            Text('Audio', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _circularProgress() {
    final pct = (_dlProgress * 100).toInt();
    return SizedBox(
      width: 48, height: 48,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(width: 44, height: 44, child: CircularProgressIndicator(
          value: _dlProgress > 0 ? _dlProgress : null,
          strokeWidth: 3, backgroundColor: Colors.white24,
          valueColor: const AlwaysStoppedAnimation(Colors.white),
        )),
        Text('$pct%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildPlayer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isReceiveMsg)
          CustomText("${widget.message.sender?.name}",
              fontWeight: FontWeight.w900, color: Colors.grey.shade700, fontSize: 12.3),
        if (widget.isReceiveMsg) const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              child: Center(child: Text(_formatDuration(_duration),
                  style: const TextStyle(color: Colors.white, fontSize: 12))),
            ),
            const SizedBox(width: 2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                    onPressed: () { _isPlaying ? _player.pause() : _player.play(); },
                  ),
                  SizedBox(
                    width: 130,
                    child: Slider(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      value: _position.inSeconds.toDouble(),
                      max: _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1,
                      onChanged: (v) { _player.seek(Duration(seconds: v.toInt())); },
                      activeColor: Colors.yellow,
                      inactiveColor: Colors.white54,
                    ),
                  ),
                ]),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    return "${duration.inMinutes.remainder(60).toString().padLeft(1, '0')}:${(duration.inSeconds.remainder(60)).toString().padLeft(2, '0')}";
  }
}
