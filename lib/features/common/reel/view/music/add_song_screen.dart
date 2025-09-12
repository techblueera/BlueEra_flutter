import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/reel/models/song.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:audio_waveforms/audio_waveforms.dart' as aw;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class AddSongScreen extends StatefulWidget {
  final String? video;
  final List<String>? images;
  final String audioUrl;
  final SongModel song;

  const AddSongScreen({
    super.key,
    required this.video,
    required this.images,
    required this.audioUrl,
    required this.song,
  });

  @override
  State<AddSongScreen> createState() => _AddSongScreenState();
}

class _AddSongScreenState extends State<AddSongScreen> {
  VideoPlayerController? _videoPlayerController;
  late final aw.PlayerController _waveformController;

  File? _audioFile;
  bool _isLoading = false;
  bool _isPlaying = false;
  int _currentPosition = 0;
  int _totalDuration = 0;
  Timer? _timer;


  @override
  void initState() {
    super.initState();
    _waveformController = aw.PlayerController();
    _setupAudioListeners();

    if (widget.video != null) {
      _setupVideoListeners();
    }
  }

  void _setupVideoListeners() {
    _videoPlayerController = VideoPlayerController.file(File(widget.video!))
      ..initialize().then((_) => setState(() {}))
      ..setLooping(true)
      ..setVolume(0.0)
      ..play();
  }

  Future<void> _setupAudioListeners() async {
    await _pickAudioFromUrlWithDio(widget.audioUrl);
  }

  Future<void> _pickAudioFromUrlWithDio(String url) async {
    setState(() => _isLoading = true);

    try {
      final dio = Dio();
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.mp3';

      final response = await dio.download(
        url,
        filePath,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        _audioFile = File(filePath);

        // Prepare waveform
        await _waveformController.preparePlayer(
          path: _audioFile!.path,
          shouldExtractWaveform: true,
          noOfSamples: 100,
        );

        await _waveformController.startPlayer(); // optional auto-play

        if (!mounted) return;

        _isPlaying = true;

        _totalDuration = await _waveformController.getDuration(aw.DurationType.max);

        // Start periodic timer to update current position
        _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
          if (_isPlaying) {
            final pos = await _waveformController.getDuration(aw.DurationType.current);
            setState(() => _currentPosition = pos);
          }
        });

      } else {
        throw Exception("Failed to download file");
      }
    } catch (e) {
      debugPrint("Download or playback error: $e");
    }

    setState(() => _isLoading = false);
  }

  Future<void> _addSongToVideo() async {
    final data = widget.song;

    // Pop AddSongScreen
    Navigator.pop(context);

    // Then pop SongScreen and pass data to ReelUpdateScreen
    Navigator.pop(context, data);
  }

  @override
  void dispose() {
    disposeAllController();
    super.dispose();
  }

  void disposeAllController() {
    _timer?.cancel();
    _videoPlayerController?.dispose();
    _waveformController.dispose();
  }

  String formatTime(int ms) {
    final seconds = (ms / 1000).floor();
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Add Song',
        isSaveButton: true,
        onSavedTap: _addSongToVideo,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: AppColors.grey5B.withValues(alpha: 0.2),
                child: Stack(
                  children: [
                    (widget.video != null)
                        ? _videoPlayerController!.value.isInitialized
                        ? Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        height:
                        _videoPlayerController?.value.size.height,
                        width:
                        _videoPlayerController?.value.size.width,
                        child: AspectRatio(
                          aspectRatio: _videoPlayerController!
                              .value.aspectRatio,
                          child:
                          VideoPlayer(_videoPlayerController!),
                        ),
                      ),
                    )
                        : const Center(
                      child: CircularProgressIndicator(),
                    )
                        : Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Center(
                        child: CarouselSlider.builder(
                          itemCount: widget.images?.length,
                          options: CarouselOptions(
                            viewportFraction: 0.8,
                            enlargeCenterPage: true,
                            enableInfiniteScroll: false,
                            aspectRatio: 1.1,
                          ),
                          itemBuilder: (context, index, realIdx) {
                            return Center(
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.whiteFE,
                                      borderRadius:
                                      BorderRadius.circular(12.0),
                                      border: Border.all(
                                        color: AppColors.mainTextColor
                                            .withValues(alpha: 0.5),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          blurRadius: 2.0,
                                          offset: const Offset(0, 1),
                                          color: const Color(0x14000000),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius:
                                      BorderRadius.circular(12.0),
                                      child: Image.file(
                                        File(widget.images![index]),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (_audioFile != null)
                      Positioned(
                        bottom: 25.0,
                        left: 0.0,
                        right: 0.0,
                        child: Align(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 25),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: CachedNetworkImage(
                                    imageUrl: widget.song.coverUrl,
                                    fit: BoxFit.cover,
                                    height: SizeConfig.size50,
                                    width: SizeConfig.size50,
                                    errorWidget: (context, url, error) =>
                                    const Icon(Icons.image),
                                  ),
                                ),
                                SizedBox(width: SizeConfig.size12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      widget.song.name,
                                      fontSize: SizeConfig.extraLarge,
                                      color: AppColors.black,
                                    ),
                                    CustomText(
                                      widget.song.artist,
                                      fontSize: SizeConfig.small,
                                      color: AppColors.black,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: SizeConfig.size20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_audioFile != null) ...[
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10),
                        onPressed: () async {
                          final currentPos = await _waveformController.getDuration(aw.DurationType.current);
                          final totalDuration = await _waveformController.getDuration(aw.DurationType.max);
                          final newPos = (currentPos - 10000).clamp(0, totalDuration).toInt();
                          await _waveformController.seekTo(newPos);
                        },
                      ),
                      IconButton(
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () async {
                          if (_isPlaying) {
                            await _waveformController.pausePlayer();
                            _isPlaying = false;
                          } else {
                            await _waveformController.startPlayer();
                            _isPlaying = true;
                          }
                          setState(() {}); // rebuild the button
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.forward_10),
                        onPressed: () async {
                          final currentPos = await _waveformController.getDuration(aw.DurationType.current);
                          final totalDuration = await _waveformController.getDuration(aw.DurationType.max);
                          final newPos = (currentPos + 10000).clamp(0, totalDuration).toInt();
                          await _waveformController.seekTo(newPos);

                        },
                      ),
                    ],
                  ),

                  // Current Time / Total Duration
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formatTime(_currentPosition), style: const TextStyle(fontSize: 12)),
                        Text(formatTime(_totalDuration), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),

                  aw.AudioFileWaveforms(
                    size: const Size(double.infinity, 100),
                    playerController: _waveformController,
                    waveformType: aw.WaveformType.fitWidth,
                    playerWaveStyle: const aw.PlayerWaveStyle(
                      fixedWaveColor: AppColors.black,
                      liveWaveColor: AppColors.primaryColor,
                      spacing: 4,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
