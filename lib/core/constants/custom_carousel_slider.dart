import 'dart:async';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CustomImageSlideshow extends StatefulWidget {
  final bool isLoading;
  final List<String> imagePaths;
  final double height;
  final double width;
  final bool isLocal;
  final Color dotColor;
  final Color dotInactiveColor;
  final Duration autoPlayInterval;
  final BorderRadius? borderRadius;

  const CustomImageSlideshow({
    Key? key,
    required this.isLoading,
    required this.imagePaths,
    this.height = 160,
    this.width = 100,
    this.isLocal = false,
    this.dotColor = AppColors.primaryColor,
    this.dotInactiveColor = Colors.grey,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.borderRadius,
  }) : super(key: key);

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
        child: const Center(child: Text("No banners available")),
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
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image),
                ),
              );

              return ClipRRect(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(10),
                child: imageWidget,
              );
            },
          ),

          // Dots indicator (overlayed at bottom)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
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
        ],
      ),
    );
  }
}
