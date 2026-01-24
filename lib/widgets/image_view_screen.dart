import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/widget/feed_author_header_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ImageViewScreen extends StatefulWidget {
  final String? subTitle;
  final List<String> imageUrls;
  final int initialIndex;
  final String appBarTitle;
  Post? postData;

  ImageViewScreen({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
    required this.appBarTitle,
    this.subTitle = '',
    this.postData,
  });

  @override
  State<ImageViewScreen> createState() => _ImageViewScreenState();
}

class _ImageViewScreenState extends State<ImageViewScreen> {
  late PageController _pageController;
  final TransformationController _transformationController =
      TransformationController();
  bool _showSubtitle = true;

  @override
  void initState() {
    super.initState();
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
      onTap: () {
        setState(() {
          _showSubtitle = !_showSubtitle;
        });
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  widget.imageUrls.isEmpty ||
                          (widget.imageUrls.isNotEmpty &&
                              widget.imageUrls[0] == 'N/A')
                      ? Expanded(
                          child: Center(
                            child: CustomText(
                              'Not able to download',
                              fontSize: SizeConfig.screenWidth * 0.05,
                              color: AppColors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : Flexible(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: widget.imageUrls.length,
                            itemBuilder: (context, index) {
                              final imageUrl = widget.imageUrls[index];
                              final isNetworkUrl = isNetworkImage(imageUrl);

                              return InteractiveViewer(
                                panEnabled: true,
                                transformationController:
                                    _transformationController,
                                // minScale: 1.0,
                                // maxScale: 5.0,
                                child: isNetworkUrl
                                    ? CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        scale: 1,
                                        fit: BoxFit.fitWidth,
                                        placeholder: (context, url) => LocalAssets(
                                            imagePath: AppIconAssets
                                                .place_holder_image) /*const CircularProgressIndicator()*/,
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.error),
                                      )
                                    : Image.file(
                                        File(imageUrl),
                                        scale: 1,
                                        fit: BoxFit.fitWidth,
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
                    icon: Icon(Icons.chevron_left,
                        color: Colors.white, size: SizeConfig.size40),
                    onPressed: () {
                      Get.back();
                    },
                  ),
                ),
              ),

              if (widget.postData?.type?.toLowerCase() == "image_post" &&
                  widget.postData?.user?.id != userId)
                Positioned(
                  top: SizeConfig.size25,
                  right: SizeConfig.size15,
                  child: SafeArea(
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      // offset: const Offset(-6, 36),
                      color: AppColors.white,

                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      onSelected: (value) async {
                        logs("value $value");
                        if (value.toUpperCase() == "BLOCK USER") {
                          if (isGuestUser()) {
                            createProfileScreen();
                          } else {
                            blockUserPopUp(
                                postType: PostType.all,
                                postData: widget.postData ?? Post(id: ''));
                          }
                        }
                        if (value.toUpperCase() == "REPORT POST") {
                          if (isGuestUser()) {
                            createProfileScreen();
                          } else {
                            postReportPopUp(
                                postData: widget.postData ?? Post(id: ''),
                                postType: PostType.all);
                          }
                        }
                      },
                      icon: IconButton(
                          onPressed: null,
                          icon: Icon(
                            Icons.more_vert,
                            color: AppColors.white,
                          )),
                      itemBuilder: (context) =>
                          popupMenuVisitProfileActionItems(
                              isShowSaveOption: false),
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
                    margin: EdgeInsets.only(bottom: SizeConfig.size20),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color:
                          AppColors.secondaryTextColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ExpandableText(
                      text: widget.subTitle ?? '',
                      trimLines: 4,
                      isReadMoreNewLine: true,
                      expandMode: ExpandMode.dialog,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w400,
                        fontFamily: AppConstants.OpenSans,
                      ),
                    ),

                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
