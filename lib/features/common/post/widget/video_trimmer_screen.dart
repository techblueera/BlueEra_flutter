import 'dart:io';

import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:video_trimmer/video_trimmer.dart';

class VideoTrimmerPage extends StatefulWidget {
  final String videoPath;

  const VideoTrimmerPage({super.key, required this.videoPath});

  @override
  State<VideoTrimmerPage> createState() => _VideoTrimmerPageState();
}

class _VideoTrimmerPageState extends State<VideoTrimmerPage> {
  final Trimmer _trimmer = Trimmer();

  double startValue = 0.0;
  double endValue = 0.0;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  void _loadVideo() async {
    await _trimmer.loadVideo(videoFile: File(widget.videoPath));
    setState(() {});
  }

  Future<void> _saveTrimmedVideo() async {
    setState(() => isSaving = true);

    await _trimmer.saveTrimmedVideo(
      videoFileName: "trimmed_video_${DateTime.now().millisecondsSinceEpoch}",
      startValue: startValue,
      endValue: endValue,
      onSave: (outputPath) {
        setState(() => isSaving = false);
        Navigator.pop(context, outputPath); // ✅ return trimmed video path
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonBackAppBar(
        title: "Trim Video",
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: VideoViewer(trimmer: _trimmer),
            ),
            TrimViewer(
              trimmer: _trimmer,
              viewerHeight: 50,
              viewerWidth: MediaQuery.of(context).size.width,
              maxVideoLength: const Duration(seconds: 150),
              // ✅ Max 150 seconds
              onChangeStart: (value) => startValue = value,
              onChangeEnd: (value) => endValue = value,
              onChangePlaybackState: (isPlaying) {},
              durationTextStyle: TextStyle(color: Colors.black),
              durationStyle: DurationStyle.FORMAT_MM_SS,
            ),
            const SizedBox(height: 20),
            isSaving
                ? const CircularProgressIndicator()
                : Padding(
                  padding:  EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                  child: PositiveCustomBtn(
                      onTap: isSaving ? null : _saveTrimmedVideo,
                      title: "Save Trimmed Video"),
                ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
