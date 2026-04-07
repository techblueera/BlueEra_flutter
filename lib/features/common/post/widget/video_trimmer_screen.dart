import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
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
  bool isLoaded = false;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  void _loadVideo() async {
    try {
      await _trimmer.loadVideo(videoFile: File(widget.videoPath));
      await Future.delayed(const Duration(milliseconds: 100));
      final controller = _trimmer.videoPlayerController;
      if (controller == null || !controller.value.isInitialized) {
        throw Exception('Video player failed to initialize');
      }
      if (controller.value.hasError) {
        throw Exception(controller.value.errorDescription ?? 'Video source error');
      }
      endValue = controller.value.duration.inSeconds.toDouble();
      if (endValue <= 0) {
        throw Exception('Invalid video duration');
      }
      if (mounted) setState(() => isLoaded = true);
    } catch (e) {
      if (!mounted) return;
      commonSnackBar(
        message: 'Unable to load video. The file may be corrupted or unsupported.',
        snackBackgroundColor: AppColors.red,
      );
      Navigator.pop(context);
    }
  }

  Future<void> _toggleTrimPlayback() async {
    final bool playingState = await _trimmer.videoPlaybackControl(
      startValue: startValue,
      endValue: endValue,
    );
    if (mounted) setState(() => isPlaying = playingState);
  }

  Future<void> _saveTrimmedVideo() async {
    setState(() => isSaving = true);

    await _trimmer.saveTrimmedVideo(
      videoFileName: "trimmed_video_${DateTime.now().millisecondsSinceEpoch}",
      startValue: startValue,
      endValue: endValue,
      onSave: (outputPath) {
        setState(() => isSaving = false);
        Navigator.pop(context, outputPath);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: SafeArea(
        child: Column(
          children: [
            // ─── TOP BAR ───────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Trim Video',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ─── VIDEO VIEWER ──────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: isLoaded && !isSaving ? _toggleTrimPlayback : null,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFF1A1A2E),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isLoaded
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoViewer(trimmer: _trimmer),
                            AnimatedOpacity(
                              opacity: isPlaying ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.5),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF667EEA)),
                            ),
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ─── TRIM CONTROLS ─────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.content_cut_rounded,
                          size: 14, color: Colors.white.withValues(alpha: 0.5)),
                      const SizedBox(width: 6),
                      Text(
                        'Drag handles to trim your video',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: TrimViewer(
                      trimmer: _trimmer,
                      viewerHeight: 56,
                      viewerWidth: MediaQuery.of(context).size.width - 32,
                      maxVideoLength: const Duration(seconds: 150),
                      onChangeStart: (value) {
                        startValue = value;
                        if (isPlaying) setState(() => isPlaying = false);
                      },
                      onChangeEnd: (value) {
                        endValue = value;
                        if (isPlaying) setState(() => isPlaying = false);
                      },
                      onChangePlaybackState: (playing) {
                        if (mounted) setState(() => isPlaying = playing);
                      },
                      durationTextStyle: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      durationStyle: DurationStyle.FORMAT_MM_SS,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Max 2 min 30 sec',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── SAVE BUTTON ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: isSaving ? null : _saveTrimmedVideo,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: isSaving
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                    color: isSaving ? const Color(0xFF2A2A3E) : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSaving
                        ? []
                        : [
                            BoxShadow(
                              color: const Color(0xFF667EEA)
                                  .withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: Center(
                    child: isSaving
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white70),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Saving...',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_rounded,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Save & Continue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
