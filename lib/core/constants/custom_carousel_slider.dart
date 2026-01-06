import 'dart:async';
import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CustomImageSlideshow extends StatefulWidget {
  final bool isLoading;
  final List<String> imagePaths;
  final double height;
  final double width;
  final bool isLocal;
  final Color dotColor;
  final BoxFit boxFit;
  final Color dotInactiveColor;
  final Duration autoPlayInterval;
  final BorderRadius? borderRadius;
  final Function(int)? onPhotoIndex;

  const CustomImageSlideshow(
      {Key? key,
      required this.isLoading,
      required this.imagePaths,
      this.height = 160,
      this.width = 100,
      this.isLocal = false,
      this.dotColor = AppColors.primaryColor,
      this.boxFit = BoxFit.cover,
      this.dotInactiveColor = AppColors.whiteFE,
      this.autoPlayInterval = const Duration(seconds: 3),
      this.borderRadius,
      this.onPhotoIndex})
      : super(key: key);

  @override
  State<CustomImageSlideshow> createState() => _CustomImageSlideshowState();
}

class _CustomImageSlideshowState extends State<CustomImageSlideshow> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!widget.isLoading && widget.imagePaths.isNotEmpty) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(widget.autoPlayInterval, (timer) {
      if (_pageController.hasClients && widget.imagePaths.isNotEmpty) {
        int nextPage = (_currentIndex + 1) % widget.imagePaths.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.imagePaths.isEmpty) {
      return Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(10),
          color: Colors.grey[200],
        ),
        child: LocalAssets(
          imagePath: AppIconAssets.place_holder_image,
          boxFix: BoxFit.cover,
        ),
        // child: const Center(child: Text("No banners available")),
      );
    }

    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: Stack(
        children: [
          // PageView
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imagePaths.length,
            onPageChanged: (index) {
              if (widget.onPhotoIndex != null) widget.onPhotoIndex!(index);
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final imagePath = widget.imagePaths[index];
              final imageWidget = widget.isLocal
                  ? Image.asset(imagePath, fit: BoxFit.cover)
                  : CachedNetworkImage(
                      imageUrl: imagePath,
                      fit: widget.boxFit,
                      memCacheWidth: 600,
                      memCacheHeight: 600,
                      fadeInDuration: const Duration(milliseconds: 100),
                      fadeOutDuration: Duration.zero,
                      placeholder: (context, url) => LocalAssets(
                        imagePath: AppIconAssets.place_holder_image,
                        boxFix: BoxFit.cover,
                      ),
                errorWidget: (context, url, error) {
                  try {
                    if (imagePath.isNotEmpty && !imagePath.startsWith('http')) {
                      final file = File(imagePath);
                      if (file.existsSync()) {
                        return Image.file(
                          file,
                          fit: BoxFit.cover,
                        );
                      }
                    }

                    // fallback if not valid local file or url failed
                    return LocalAssets(
                      imagePath: AppIconAssets.place_holder_image,
                      boxFix: BoxFit.cover,
                    );
                  } catch (e) {
                    // in case something goes wrong in file handling
                    return LocalAssets(
                      imagePath: AppIconAssets.place_holder_image,
                      boxFix: BoxFit.cover,
                    );
                  }
                },
                     /* errorWidget: (context, url, error) =>
                          (!imagePath.contains('http'))
                              ? Image.file(
                                  File(imagePath),
                                  fit: BoxFit.cover,
                                )
                              : LocalAssets(
                                  imagePath: AppIconAssets.place_holder_image,
                                  boxFix: BoxFit.cover,
                                ),*/
                    );

              return ClipRRect(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(10),
                child: imageWidget,
              );
            },
          ),

          // Dots indicator (overlayed at bottom)
          if (widget.imagePaths.length > 1)
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.imagePaths.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      width: _currentIndex == index ? 8 : 6,
                      height: _currentIndex == index ? 8 : 6,
                      decoration: BoxDecoration(
                        color: _currentIndex == index
                            ? widget.dotColor
                            : widget.dotInactiveColor,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
