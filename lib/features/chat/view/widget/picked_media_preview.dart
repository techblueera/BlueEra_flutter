import 'dart:io';
import 'dart:ui' as ui;

import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_icon_assets.dart';
import '../../auth/controller/chat_view_controller.dart';

class MultiImagePreviewPage extends StatefulWidget {
  final List<File> mediaFiles;
  final Function(List<File> file, String? commands) onSend;
  final String? recipientName;

  const MultiImagePreviewPage({
    super.key,
    required this.mediaFiles,
    required this.onSend,
    this.recipientName,
  });

  @override
  State<MultiImagePreviewPage> createState() => _MultiImagePreviewPageState();
}

class _MultiImagePreviewPageState extends State<MultiImagePreviewPage> {
  late PageController _pageController;
  final TextEditingController _captionController = TextEditingController();
  final List<VideoPlayerController?> _videoControllers = [];
  List<File> _mediaFiles = [];
  int _currentIndex = 0;
  bool _isHdEnabled = false;

  // Text overlay state
  final List<_TextOverlayItem> _textOverlays = [];
  bool _isAddingText = false;
  final TextEditingController _overlayTextController = TextEditingController();
  Color _overlayTextColor = Colors.white;

  // Drawing state
  bool _isDrawing = false;
  final List<_DrawingPath> _drawingPaths = [];
  List<Offset> _currentStroke = [];
  Color _drawingColor = Colors.red;
  double _drawingStrokeWidth = 3.0;

  // Emoji state
  bool _showEmojiPicker = false;

  // Global key for screenshot capture (drawing + overlays)
  final GlobalKey _mediaKey = GlobalKey();

  final chatViewController = Get.find<ChatViewController>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _mediaFiles = [...widget.mediaFiles];
    _initializeMediaControllers(widget.mediaFiles);
  }

  Future<void> _initializeMediaControllers(List<File> files) async {
    for (var file in files) {
      if (_isVideo(file)) {
        final controller = VideoPlayerController.file(file);
        await controller.initialize();
        _videoControllers.add(controller);
      } else {
        _videoControllers.add(null);
      }
    }
    if (mounted) setState(() {});
  }

  bool _isVideo(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'mkv', 'avi', 'webm'].contains(ext);
  }

  @override
  void dispose() {
    for (var vc in _videoControllers) {
      vc?.dispose();
    }
    _captionController.dispose();
    _overlayTextController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _togglePlayPause(int index) {
    if (index >= _videoControllers.length) return;
    final controller = _videoControllers[index];
    if (controller == null) return;
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  Future<void> _pickMoreMedia() async {
    final picker = ImagePicker();
    List<File> files = [];
    final hasVideo = _mediaFiles.any((f) => _isVideo(f));

    if (hasVideo) {
      final XFile? pickedVideo =
          await picker.pickVideo(source: ImageSource.gallery);
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
      for (var file in files) {
        if (_isVideo(file)) {
          final controller = VideoPlayerController.file(file);
          await controller.initialize();
          _videoControllers.add(controller);
        } else {
          _videoControllers.add(null);
        }
      }
      setState(() {
        _mediaFiles.addAll(files);
      });
    }
  }

  void _removeMedia(int index) {
    if (_mediaFiles.length <= 1) return;
    setState(() {
      _videoControllers[index]?.dispose();
      _videoControllers.removeAt(index);
      _mediaFiles.removeAt(index);
      if (_currentIndex >= _mediaFiles.length) {
        _currentIndex = _mediaFiles.length - 1;
      }
      _pageController.jumpToPage(_currentIndex);
    });
  }

  Future<void> _cropImage(int index) async {
    if (_isVideo(_mediaFiles[index])) return;
    final file = _mediaFiles[index];
    final fileImage = FileImage(file);

    // Precache before showing cropper
    await precacheImage(fileImage, context);

    File? croppedFile;

    await showCupertinoImageCropper(
      context,
      locale: const Locale('en', 'US'),
      imageProvider: fileImage,
      enabledTransformations: [
        Transformation.resize,
        Transformation.panAndScale,
      ],
      shouldPopAfterCrop: true,
      allowedAspectRatios: [
        const CropAspectRatio(width: 1, height: 1),
        const CropAspectRatio(width: 3, height: 4),
        const CropAspectRatio(width: 4, height: 3),
        const CropAspectRatio(width: 16, height: 9),
      ],
      showLoadingIndicatorOnSubmit: true,
      postProcessFn: (result) async {
        final byteData =
            await result.uiImage.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final tempDir = await getTemporaryDirectory();
          croppedFile = File(
              '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png');
          await croppedFile!.writeAsBytes(byteData.buffer.asUint8List());
        }
        return result;
      },
    );

    if (croppedFile != null && mounted) {
      setState(() {
        _mediaFiles[index] = croppedFile!;
      });
    }
  }

  void _startTextOverlay() {
    _overlayTextController.clear();
    _overlayTextColor = Colors.white;
    setState(() {
      _isAddingText = true;
    });
  }

  void _confirmTextOverlay() {
    if (_overlayTextController.text.trim().isNotEmpty) {
      setState(() {
        _textOverlays.add(_TextOverlayItem(
          text: _overlayTextController.text.trim(),
          color: _overlayTextColor,
          position: const Offset(100, 300),
        ));
      });
    }
    setState(() {
      _isAddingText = false;
    });
  }

  void _toggleDrawingMode() {
    setState(() {
      _isDrawing = !_isDrawing;
      if (!_isDrawing && _currentStroke.isNotEmpty) {
        _drawingPaths.add(_DrawingPath(
          points: List.from(_currentStroke),
          color: _drawingColor,
          strokeWidth: _drawingStrokeWidth,
        ));
        _currentStroke = [];
      }
    });
  }

  void _undoDrawing() {
    if (_drawingPaths.isNotEmpty) {
      setState(() {
        _drawingPaths.removeLast();
      });
    }
  }

  void _onSendPressed() {
    widget.onSend(
      _mediaFiles,
      _captionController.text.isEmpty ? null : _captionController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: _isAddingText ? _buildTextOverlayEditor() : _buildMainPreview(),
      ),
    );
  }

  // ─── Text Overlay Editor ──────────────────────────────────────────────────

  Widget _buildTextOverlayEditor() {
    return Container(
      color: Colors.black87,
      child: Column(
        children: [
          // Top bar with Done button & color picker
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isAddingText = false),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                // Color options
                Row(
                  children: [
                    for (final color in [
                      Colors.white,
                      Colors.red,
                      Colors.yellow,
                      Colors.green,
                      Colors.blue,
                      Colors.purple,
                    ])
                      GestureDetector(
                        onTap: () =>
                            setState(() => _overlayTextColor = color),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _overlayTextColor == color
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                GestureDetector(
                  onTap: _confirmTextOverlay,
                  child: const Text('Done',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Text input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: TextField(
              controller: _overlayTextController,
              autofocus: true,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _overlayTextColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              maxLines: null,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Type text',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 28),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ─── Main Preview ─────────────────────────────────────────────────────────

  Widget _buildMainPreview() {
    return Column(
      children: [
        // Top toolbar
        _buildTopToolbar(),

        // Media content area (expanded)
        Expanded(child: _buildMediaContent()),

        // Thumbnail strip (if multiple media)
        if (_mediaFiles.length > 1) _buildThumbnailStrip(),

        // Bottom caption + send
        _buildBottomBar(),
      ],
    );
  }

  // ─── Top Toolbar ──────────────────────────────────────────────────────────

  Widget _buildTopToolbar() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Close button
          _toolbarIcon(Icons.close, onTap: () => Navigator.pop(context)),
          const Spacer(),
          // HD toggle
          _toolbarIconWithLabel(
            _isHdEnabled ? 'HD' : 'HD',
            isActive: _isHdEnabled,
            onTap: () {
              setState(() => _isHdEnabled = !_isHdEnabled);
              Get.snackbar(
                'Quality',
                _isHdEnabled
                    ? 'HD quality enabled'
                    : 'Standard quality',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.black87,
                colorText: Colors.white,
                duration: const Duration(seconds: 1),
              );
            },
          ),
          const SizedBox(width: 4),
          // Crop / Rotate
          _toolbarIcon(
            Icons.crop_rotate,
            onTap: () => _cropImage(_currentIndex),
          ),
          const SizedBox(width: 4),
          // Emoji / Sticker
          _toolbarIcon(
            Icons.emoji_emotions_outlined,
            onTap: () {
              setState(() => _showEmojiPicker = !_showEmojiPicker);
            },
          ),
          const SizedBox(width: 4),
          // Text overlay
          _toolbarIcon(
            Icons.title,
            onTap: _startTextOverlay,
          ),
          const SizedBox(width: 4),
          // Draw / Paint
          _toolbarIcon(
            Icons.edit,
            isActive: _isDrawing,
            onTap: _toggleDrawingMode,
          ),
        ],
      ),
    );
  }

  Widget _toolbarIcon(IconData icon,
      {VoidCallback? onTap, bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          color: isActive ? Colors.blue : Colors.white,
          size: 26,
        ),
      ),
    );
  }

  Widget _toolbarIconWithLabel(String label,
      {VoidCallback? onTap, bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isActive ? Colors.blue : Colors.white54,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.blue : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ─── Media Content ────────────────────────────────────────────────────────

  Widget _buildMediaContent() {
    final isLoading = _mediaFiles.length == 1 &&
        _isVideo(_mediaFiles.first) &&
        _videoControllers.isEmpty;

    return RepaintBoundary(
      key: _mediaKey,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Media PageView
          isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : GestureDetector(
                  onPanStart: _isDrawing
                      ? (details) {
                          setState(() {
                            _currentStroke = [details.localPosition];
                          });
                        }
                      : null,
                  onPanUpdate: _isDrawing
                      ? (details) {
                          setState(() {
                            _currentStroke.add(details.localPosition);
                          });
                        }
                      : null,
                  onPanEnd: _isDrawing
                      ? (details) {
                          setState(() {
                            if (_currentStroke.isNotEmpty) {
                              _drawingPaths.add(_DrawingPath(
                                points: List.from(_currentStroke),
                                color: _drawingColor,
                                strokeWidth: _drawingStrokeWidth,
                              ));
                              _currentStroke = [];
                            }
                          });
                        }
                      : null,
                  child: PageView.builder(
                    controller: _pageController,
                    physics: _isDrawing
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    itemCount: _mediaFiles.length,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    itemBuilder: (_, index) {
                      final file = _mediaFiles[index];
                      final videoController =
                          (index < _videoControllers.length)
                              ? _videoControllers[index]
                              : null;

                      if (_isVideo(file)) {
                        return _buildVideoPreview(videoController, index);
                      }
                      return Image.file(
                        file,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      );
                    },
                  ),
                ),

          // Drawing overlay
          if (_drawingPaths.isNotEmpty || _currentStroke.isNotEmpty)
            IgnorePointer(
              child: CustomPaint(
                painter: _DrawingPainter(
                  paths: _drawingPaths,
                  currentStroke: _currentStroke,
                  currentColor: _drawingColor,
                  currentStrokeWidth: _drawingStrokeWidth,
                ),
              ),
            ),

          // Text overlays
          for (int i = 0; i < _textOverlays.length; i++)
            Positioned(
              left: _textOverlays[i].position.dx,
              top: _textOverlays[i].position.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _textOverlays[i] = _textOverlays[i].copyWith(
                      position: Offset(
                        _textOverlays[i].position.dx + details.delta.dx,
                        _textOverlays[i].position.dy + details.delta.dy,
                      ),
                    );
                  });
                },
                onLongPress: () {
                  setState(() => _textOverlays.removeAt(i));
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _textOverlays[i].text,
                    style: TextStyle(
                      color: _textOverlays[i].color,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // Drawing mode controls
          if (_isDrawing) _buildDrawingControls(),

          // Emoji sticker picker
          if (_showEmojiPicker) _buildEmojiPicker(),
        ],
      ),
    );
  }

  Widget _buildVideoPreview(
      VideoPlayerController? videoController, int index) {
    if (videoController == null || !videoController.value.isInitialized) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    return GestureDetector(
      onTap: () => _togglePlayPause(index),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: videoController.value.aspectRatio,
              child: VideoPlayer(videoController),
            ),
          ),
          // Play/Pause overlay
          AnimatedOpacity(
            opacity: videoController.value.isPlaying ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.5),
              ),
              child: Icon(
                videoController.value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
          ),
          // Video duration bar
          Positioned(
            bottom: 12,
            left: 24,
            right: 24,
            child: VideoProgressIndicator(
              videoController,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.white,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingControls() {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Column(
        children: [
          // Undo button
          if (_drawingPaths.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 8),
                child: GestureDetector(
                  onTap: _undoDrawing,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.undo, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          // Color picker & stroke width
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final color in [
                  Colors.white,
                  Colors.red,
                  Colors.orange,
                  Colors.yellow,
                  Colors.green,
                  Colors.blue,
                  Colors.purple,
                ])
                  GestureDetector(
                    onTap: () => setState(() => _drawingColor = color),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: _drawingColor == color ? 28 : 22,
                      height: _drawingColor == color ? 28 : 22,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _drawingColor == color
                              ? Colors.white
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                // Stroke width slider
                SizedBox(
                  width: 60,
                  child: Slider(
                    value: _drawingStrokeWidth,
                    min: 1.0,
                    max: 10.0,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white24,
                    onChanged: (val) =>
                        setState(() => _drawingStrokeWidth = val),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    final emojis = [
      '😀', '😂', '😍', '🥳', '😎', '🤔', '😢', '😡',
      '👍', '👎', '❤️', '🔥', '⭐', '🎉', '💯', '🙏',
      '😊', '🤗', '😘', '🥺', '😤', '🤩', '😴', '🤑',
    ];

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Stickers',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => setState(() => _showEmojiPicker = false),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: emojis
                  .map(
                    (emoji) => GestureDetector(
                      onTap: () {
                        setState(() {
                          _textOverlays.add(_TextOverlayItem(
                            text: emoji,
                            color: Colors.white,
                            position: const Offset(150, 300),
                            isEmoji: true,
                          ));
                          _showEmojiPicker = false;
                        });
                      },
                      child: Text(emoji, style: const TextStyle(fontSize: 30)),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Thumbnail Strip ──────────────────────────────────────────────────────

  Widget _buildThumbnailStrip() {
    return Container(
      color: Colors.black,
      height: 64,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _mediaFiles.length + 1, // +1 for add button
        itemBuilder: (context, index) {
          if (index == _mediaFiles.length) {
            // Add more media button
            return GestureDetector(
              onTap: _pickMoreMedia,
              child: Container(
                width: 52,
                height: 52,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white38, width: 1.5),
                ),
                child: const Icon(Icons.add, color: Colors.white54, size: 28),
              ),
            );
          }

          final file = _mediaFiles[index];
          final isSelected = _currentIndex == index;

          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              );
            },
            onLongPress: () => _removeMedia(index),
            child: Container(
              width: 52,
              height: 52,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _isVideo(file)
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.videocam,
                                color: Colors.white54, size: 22),
                          ),
                          const Positioned(
                            bottom: 2,
                            right: 2,
                            child: Icon(Icons.play_circle_filled,
                                color: Colors.white, size: 14),
                          ),
                        ],
                      )
                    : Image.file(file, fit: BoxFit.cover),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Bottom Bar ───────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Caption input + Send
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      // Add media button
                      IconButton(
                        onPressed: _pickMoreMedia,
                        icon: SvgPicture.asset(
                          AppIconAssets.chat_input_add_media,
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                              Colors.white54, BlendMode.srcIn),
                        ),
                      ),
                      // Caption text field
                      Expanded(
                        child: TextField(
                          controller: _captionController,
                          style: const TextStyle(
                              color: Colors.black, fontSize: 15),
                          decoration: const InputDecoration(
                            hintText: 'Add a caption...',
                            hintStyle:
                                TextStyle(color: Colors.black, fontSize: 15),
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Send button
              GestureDetector(
                onTap: _onSendPressed,
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00A884),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    AppIconAssets.send_message_chat,
                    height: 22,
                    width: 22,
                    colorFilter: const ColorFilter.mode(
                        Colors.white, BlendMode.srcIn),
                  ),
                ),
              ),
            ],
          ),
          // Recipient name chip
          if (widget.recipientName != null &&
              widget.recipientName!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2C34),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.recipientName!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Drawing painter ────────────────────────────────────────────────────────

class _DrawingPainter extends CustomPainter {
  final List<_DrawingPath> paths;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double currentStrokeWidth;

  _DrawingPainter({
    required this.paths,
    required this.currentStroke,
    required this.currentColor,
    required this.currentStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final dp in paths) {
      _paintStroke(canvas, dp.points, dp.color, dp.strokeWidth);
    }
    if (currentStroke.isNotEmpty) {
      _paintStroke(canvas, currentStroke, currentColor, currentStrokeWidth);
    }
  }

  void _paintStroke(
      Canvas canvas, List<Offset> points, Color color, double strokeWidth) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}

// ─── Data classes ───────────────────────────────────────────────────────────

class _TextOverlayItem {
  final String text;
  final Color color;
  final Offset position;
  final bool isEmoji;

  const _TextOverlayItem({
    required this.text,
    required this.color,
    required this.position,
    this.isEmoji = false,
  });

  _TextOverlayItem copyWith({
    String? text,
    Color? color,
    Offset? position,
  }) {
    return _TextOverlayItem(
      text: text ?? this.text,
      color: color ?? this.color,
      position: position ?? this.position,
      isEmoji: isEmoji,
    );
  }
}

class _DrawingPath {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  const _DrawingPath({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}
