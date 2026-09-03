import 'dart:io';
import 'dart:typed_data';

import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/post/widget/video_trimmer_screen.dart';
import '../../../auth/controller/add_chat_symbol_controller.dart';

class SymbolUploadWidget extends StatefulWidget {
  SymbolUploadWidget({super.key, this.isFromRepost = false});

  final bool isFromRepost;

  @override
  State<SymbolUploadWidget> createState() => _SymbolUploadWidgetState();
}

class _SymbolUploadWidgetState extends State<SymbolUploadWidget> {
  final controller = Get.isRegistered<AddChatSymbolController>()
      ? Get.find<AddChatSymbolController>()
      : Get.put(AddChatSymbolController());

  late final List<_SymbolTypeOption> _options = [
    _SymbolTypeOption(
      label: AppStrings.photo.tr,
      subtitle: AppStrings.upToFourImages.tr,
      icon: Icons.photo_rounded,
      gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
      type: SymbolPostType.image,
    ),
    _SymbolTypeOption(
      label: AppStrings.video.tr,
      subtitle: AppStrings.recordOrPick.tr,
      icon: Icons.videocam_rounded,
      gradient: const [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
      type: SymbolPostType.video,
    ),
    _SymbolTypeOption(
      label: AppStrings.textLabel.tr,
      subtitle: AppStrings.shareThoughts.tr,
      icon: Icons.text_fields_rounded,
      gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
      type: SymbolPostType.text,
    ),
    _SymbolTypeOption(
      label: AppStrings.linkLabel.tr,
      subtitle: AppStrings.shareAUrl.tr,
      icon: Icons.link_rounded,
      gradient: const [Color(0xFFF7971E), Color(0xFFFFD200)],
      type: SymbolPostType.link,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasMedia = controller.imagesList.isNotEmpty;
      final isPhoto = controller.selectedSymbolPostType.value == SymbolPostType.image;
      final isVideo = controller.selectedSymbolPostType.value == SymbolPostType.video;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- INITIAL TYPE SELECTOR ---
          if (controller.selectedSymbolPostType.value == null) ...[
            CustomText(
              AppStrings.whatWouldYouLikeToShare.tr,
              color: const Color(0xFF2D3142),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 6),
            CustomText(
              AppStrings.chooseSymbolType.tr,
              color: const Color(0xFF2D3142).withValues(alpha: 0.45),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            const SizedBox(height: 20),
            _buildTypeGrid(),
          ],

          // --- MEDIA SELECTED STATE ---
          if (hasMedia && (isPhoto || isVideo)) ...[
            // Header with count + add more
            _buildMediaHeader(),
            const SizedBox(height: 16),

            // Media preview
            if (isPhoto) _buildPhotoGrid(),
            if (isVideo) _buildVideoPreview(),
          ],

          // --- MEDIA NOT SELECTED BUT TYPE CHOSEN (for Photo/Video) ---
          if (!hasMedia && (isPhoto || isVideo)) ...[
            _buildMediaHeader(),
            const SizedBox(height: 16),
            _buildEmptyMediaPlaceholder(),
          ],

          // --- TEXT OR LINK TYPE CHOSEN ---
          // Removed redundant display as per user request
        ],
      );
    });
  }

  // ─── TYPE SELECTOR GRID ────────────────────────────────────────────

  Widget _buildTypeGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.45,
      children: _options.map((option) => _buildTypeCard(option)).toList(),
    );
  }

  Widget _buildTypeCard(_SymbolTypeOption option) {
    return GestureDetector(
      onTap: () {
        if (option.type == SymbolPostType.image) {
          if (controller.imagesList.length < 4) controller.pickMedia();
        } else if (option.type == SymbolPostType.video) {
          controller.pickVideoMedia();
        } else {
          controller.choosePostType(option.type);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: option.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: option.gradient.first.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: -10,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              right: 15,
              bottom: -15,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(option.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 10),
                  CustomText(
                    option.label,
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── MEDIA HEADER (count + add more) ───────────────────────────────

  Widget _buildMediaHeader() {
    final isPhoto = controller.selectedSymbolPostType.value == SymbolPostType.image;
    final count = controller.imagesList.length;

    return Row(
      children: [
        // Icon
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isPhoto
                ? const Color(0xFF667EEA).withValues(alpha: 0.1)
                : const Color(0xFFFF6B6B).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            isPhoto ? Icons.photo_library_rounded : Icons.videocam_rounded,
            size: 17,
            color: isPhoto ? const Color(0xFF667EEA) : const Color(0xFFFF6B6B),
          ),
        ),
        const SizedBox(width: 10),

        // Title + count
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                isPhoto
                    ? AppStrings.selectedPhotos.tr
                    : AppStrings.selectedVideo.tr,
                color: const Color(0xFF2D3142),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: 2),
              CustomText(
                isPhoto
                    ? '$count ${AppStrings.photosUnit.tr}'
                    : AppStrings.oneVideoSelected.tr,
                color: const Color(0xFF2D3142).withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ],
          ),
        ),

        // Add more / Pick button
        if (count < (isPhoto ? 4 : 1))
          GestureDetector(
            onTap: () =>
                isPhoto ? controller.pickMedia() : controller.pickVideoMedia(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPhoto
                      ? [const Color(0xFF667EEA), const Color(0xFF764BA2)]
                      : [const Color(0xFFFF6B6B), const Color(0xFFEE5A24)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isPhoto
                            ? const Color(0xFF667EEA)
                            : const Color(0xFFFF6B6B))
                        .withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  CustomText(
                    count == 0
                        ? AppStrings.selectLabel.tr
                        : AppStrings.addMoreLabel.tr,
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ─── PHOTO GRID ────────────────────────────────────────────────────

  Widget _buildPhotoGrid() {
    final images = controller.imagesList;
    final count = images.length;

    // Single image - full width hero
    if (count == 1) {
      return _buildSinglePhoto(images[0], 0);
    }

    // 2 images - side by side
    if (count == 2) {
      return Row(
        children: [
          Expanded(child: _buildPhotoTile(images[0], 0, height: 200)),
          const SizedBox(width: 10),
          Expanded(child: _buildPhotoTile(images[1], 1, height: 200)),
        ],
      );
    }

    // 3 images - 1 large + 2 small
    if (count == 3) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _buildPhotoTile(images[0], 0, height: 220),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildPhotoTile(images[1], 1, height: 105),
                const SizedBox(height: 10),
                _buildPhotoTile(images[2], 2, height: 105),
              ],
            ),
          ),
        ],
      );
    }

    // 4 images - 2x2 grid
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildPhotoTile(images[0], 0, height: 150)),
            const SizedBox(width: 10),
            Expanded(child: _buildPhotoTile(images[1], 1, height: 150)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildPhotoTile(images[2], 2, height: 150)),
            const SizedBox(width: 10),
            Expanded(child: _buildPhotoTile(images[3], 3, height: 150)),
          ],
        ),
      ],
    );
  }

  Widget _buildSinglePhoto(File file, int index) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(file, fit: BoxFit.cover),
            // Subtle gradient at top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Remove button
            _buildRemoveButton(index),
            // Image index badge
            _buildIndexBadge(index),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoTile(File file, int index, {required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => openImagePreview(controller.imagesList, index),
              child: FutureBuilder<Uint8List>(
                future: file.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData) {
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    );
                  } else {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            // Top gradient
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            _buildRemoveButton(index),
          ],
        ),
      ),
    );
  }

  // ─── VIDEO PREVIEW ─────────────────────────────────────────────────

  Widget _buildVideoPreview() {
    final file = controller.imagesList[0];

    return GestureDetector(
      onTap: () => openVideoPreview(file),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF1A1A2E),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail
              Obx(() {
                final thumb = controller.videoThumbnails[file.path];
                if (thumb != null) {
                  return Image.file(
                    thumb,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      );
                    },
                  );
                }
                return const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                    ),
                  ),
                );
              }),

              // Dark overlay
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.4),
                    ],
                    radius: 1.2,
                  ),
                ),
              ),

              // Play button center
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),

              // "Tap to preview" label
              Positioned(
                bottom: 14,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.touch_app_rounded,
                            size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        CustomText(
                          AppStrings.tapToPreview.tr,
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Top gradient + remove
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              _buildRemoveButton(0),

              // Video badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_rounded,
                          size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      CustomText(
                        AppStrings.videoBadge.tr,
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ],
                  ),
                ),
              ),

              // Clip length — the same value posted as `media_duration`, so
              // what the user sees here is what the feed will show.
              Obx(() {
                final seconds = controller.videoDurationSeconds.value;
                if (seconds == null) return const SizedBox.shrink();
                return Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomText(
                      formatMediaDuration(seconds),
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ─── EMPTY STATE PLACEHOLDER ───────────────────────────────────────

  Widget _buildEmptyMediaPlaceholder() {
    final isPhoto = controller.selectedSymbolPostType.value == SymbolPostType.image;
    final option = isPhoto ? _options[0] : _options[1];

    return GestureDetector(
      onTap: () =>
          isPhoto ? controller.pickMedia() : controller.pickVideoMedia(),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: option.gradient.first.withValues(alpha: 0.2),
            width: 2,
            style: BorderStyle
                .none, // We'll use a dotted border effect via decoration if possible, or just a nice shadow
          ),
          boxShadow: [
            BoxShadow(
              color: option.gradient.first.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Dotted border simulator
            Positioned.fill(
              child: CustomPaint(
                painter: _DottedBorderPainter(
                  color: option.gradient.first.withValues(alpha: 0.3),
                  borderRadius: 20,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: option.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: option.gradient.first.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(option.icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  CustomText(
                    isPhoto ? AppStrings.addPhotos.tr : AppStrings.addVideo.tr,
                    color: const Color(0xFF2D3142),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    option.subtitle,
                    color: const Color(0xFF2D3142).withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SHARED COMPONENTS ─────────────────────────────────────────────

  Widget _buildRemoveButton(int index) {
    return Positioned(
      right: 10,
      top: 10,
      child: GestureDetector(
        onTap: () => controller.removeMedia(index),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Center(
            child:
                Icon(Icons.close_rounded, color: Color(0xFF2D3142), size: 16),
          ),
        ),
      ),
    );
  }

  void openImagePreview(List<File> files, int initialIndex) {
    int currentIndex = initialIndex;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: StatefulBuilder(
          builder: (context, setState) => Stack(
            fit: StackFit.expand,
            children: [
              FutureBuilder<Uint8List>(
                future: files[currentIndex].readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData) {
                    return InteractiveViewer(
                      child: Image.memory(
                        snapshot.data!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image,
                                color: Colors.white, size: 50),
                          );
                        },
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.white, size: 50),
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  }
                },
              ),
              // Close button
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              // Previous button
              if (currentIndex > 0)
                Positioned(
                  left: 20,
                  top: MediaQuery.of(context).size.height / 2 - 30,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 40),
                    onPressed: () {
                      setState(() {
                        currentIndex = currentIndex - 1;
                      });
                    },
                  ),
                ),
              // Next button
              if (currentIndex < files.length - 1)
                Positioned(
                  right: 20,
                  top: MediaQuery.of(context).size.height / 2 - 30,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward,
                        color: Colors.white, size: 40),
                    onPressed: () {
                      setState(() {
                        currentIndex = currentIndex + 1;
                      });
                    },
                  ),
                ),
              // Index indicator
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CustomText(
                      '${currentIndex + 1} / ${files.length}',
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              // Delete button
              Positioned(
                bottom: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.black, size: 30),
                  onPressed: () {
                    Get.find<AddChatSymbolController>()
                        .removeMedia(currentIndex);
                    if (Get.find<AddChatSymbolController>()
                        .imagesList
                        .isEmpty) {
                      Navigator.of(context).pop();
                    } else {
                      if (currentIndex >=
                          Get.find<AddChatSymbolController>()
                              .imagesList
                              .length) {
                        currentIndex = Get.find<AddChatSymbolController>()
                                .imagesList
                                .length -
                            1;
                      }
                      setState(() {});
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndexBadge(int index) {
    return Positioned(
      left: 12,
      top: 12,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
            ),
          ],
        ),
        child: Center(
          child: CustomText(
            '${index + 1}',
            color: const Color(0xFF2D3142),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SymbolTypeOption {
  final String label;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final SymbolPostType type;

  _SymbolTypeOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.type,
  });
}

void openVideoPreview(File file) async {
  final trimmedPath = await Get.to(() => VideoTrimmerPage(videoPath: file.path));
  if (trimmedPath != null) {
    await Get.find<AddChatSymbolController>().setVideoFile(File(trimmedPath));
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  _DottedBorderPainter({required this.color, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const double dashWidth = 5;
    const double dashSpace = 5;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final dashPath = Path();
    double distance = 0.0;

    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
