import 'dart:async';
import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:audio_waveforms/audio_waveforms.dart' hide PlayerState;
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class AddSongScreen extends StatefulWidget {
  final String videoPath;
  final String audioUrl;
  final Map<String, dynamic> song;

  const AddSongScreen({super.key, required this.videoPath, required this.audioUrl, required this.song});

  @override
  State<AddSongScreen> createState() => _AddSongScreenState();
}

class _AddSongScreenState extends State<AddSongScreen> {
  late VideoPlayerController _videoPlayerController;
  late final PlayerController _waveformController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  File? _audioFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _waveformController = PlayerController();
    _setupAudioListeners();
    _setupVideoListeners();
  }

  void _setupVideoListeners(){
  _videoPlayerController = VideoPlayerController.file(File(widget.videoPath))
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

      // Download the file using Dio
      final response = await dio.download(
        url,
        filePath,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        _audioFile = File(filePath);

        // Set the audio source for the player
        await _audioPlayer.setSourceDeviceFile(_audioFile!.path);

        // Prepare waveform
        await _waveformController.preparePlayer(
          path: _audioFile!.path,
          shouldExtractWaveform: true,
          noOfSamples: 100,
        );

        await _waveformController.startPlayer(); // Optional: auto-play
      } else {
        throw Exception("Failed to download file");
      }
    } catch (e) {
      print("Download or playback error: $e");
    }

    setState(() => _isLoading = false);
  }



  Future<void> _addSongToVideo() async {
    final data = widget.song;
    disposeAllController();

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

  void disposeAllController(){
    _videoPlayerController.dispose();
    _audioPlayer.dispose();
    _waveformController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Add Song',
        isSaveButton: true,
        onSavedTap: _addSongToVideo ,
      ),
      body: SafeArea(
        child: Column(
          // fit: StackFit.expand,
          children: [
            Expanded(
              child: _videoPlayerController.value.isInitialized
                ? Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                      height: _videoPlayerController.value.size.height,
                      width: _videoPlayerController.value.size.width,
                        child: AspectRatio(
                            aspectRatio: _videoPlayerController.value.aspectRatio,
                            child: VideoPlayer(_videoPlayerController),
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
                          margin:  const EdgeInsets.only(bottom: 25),
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
                              imageUrl: widget.song['coverUrl'],
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
                                    widget.song['name'],
                                    fontSize: SizeConfig.extraLarge,
                                    color: AppColors.black,
                                  ),
                                  CustomText(
                                    widget.song['artist'],
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
                )
                : const Center(child: CircularProgressIndicator())
            ),
            SizedBox(
              height: SizeConfig.size20,
            ),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_audioFile != null) ...[

              const SizedBox(height: 20),

              // Waveform visualization
              AudioFileWaveforms(
                size: const Size(double.infinity, 120),
                playerController: _waveformController,
                waveformType: WaveformType.fitWidth,
                    playerWaveStyle: const PlayerWaveStyle(
                      fixedWaveColor: AppColors.black,
                      liveWaveColor: AppColors.primaryColor,
                      spacing: 4,
                    ),
              ),

              const SizedBox(height: 16),

            ],
          ],
        ),
      ),
    );
  }
}