import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/reelsModule/font_style.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ImageViewScreen extends StatefulWidget {
  final String? subTitle;
  final List<String> imageUrls;
  final int initialIndex;
  final String appBarTitle;

   ImageViewScreen({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
    required this.appBarTitle,
   this.subTitle = '',
  });

  @override
  State<ImageViewScreen> createState() => _ImageViewScreenState();
}

class _ImageViewScreenState extends State<ImageViewScreen> {
  late PageController _pageController;
  final TransformationController _transformationController = TransformationController();
  bool _showSubtitle = true;

  @override
  void initState() {
    super.initState();
    print('subtitle-- ${widget.subTitle}');
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        setState(() {
          _showSubtitle = !_showSubtitle;
        });
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.imageUrls.isEmpty ||
                    (widget.imageUrls.isNotEmpty &&
                        widget.imageUrls[0] == 'N/A')
                    ? Expanded(
                  child: Center(
                    child: Text(
                      'Not able to download',
                      style: TextStyle(
                        fontSize: SizeConfig.screenWidth * 0.05,
                        color: AppColors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                    : Flexible(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.imageUrls.length,
                    itemBuilder: (context, index) {
                      final imageUrl = widget.imageUrls[index];
                      log("Dynamic Value: '$imageUrl'");

                      return Center(
                        child: InteractiveViewer(
                          panEnabled: true,
                          transformationController: _transformationController,
                          minScale: 1.0,
                          maxScale: 5.0,
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // Back Button
            Positioned(
              top: SizeConfig.size25,
              left: SizeConfig.size15,
              child: SafeArea(
                child: IconButton(
                  icon: Icon(Icons.chevron_left, color: Colors.white, size: SizeConfig.size40),
                  onPressed: () {
                    Get.back();
                  },
                ),
              ),
            ),

            // Subtitle at bottom
            if (_showSubtitle)
              Positioned(
                bottom: SizeConfig.size20,
                left: SizeConfig.size10,
                right: SizeConfig.size10,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                child: ExpandableText(
                  text: widget.subTitle ?? '',
                  trimLines: 4,
                  expandMode: ExpandMode.dialog,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppConstants.OpenSans,
                  ),
                ),
                  // child: Text(
                  //   widget.subTitle ?? '',
                  //   textAlign: TextAlign.left,
                  //   style: TextStyle(
                  //     color: Colors.white,
                  //     fontSize: SizeConfig.screenWidth * 0.045,
                  //     fontWeight: FontWeight.w500,
                  //   ),
                  // ),
                ),
              ),
          ],
        ),

      ),
    );
  }
}
