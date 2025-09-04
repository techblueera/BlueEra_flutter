import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/constants/typedef_utils.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/workmanager_upload_service.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/reel/controller/reel_upload_details_controller.dart';
import 'package:BlueEra/features/common/reel/models/video_category_response.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/uploading_progressing_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

enum VideoType { video, short }

class ReelUploadDetailsScreen extends StatefulWidget {
  final String videoPath;
  final VideoType videoType;
  final String? videoId;
  final PostVia? postVia;
  const ReelUploadDetailsScreen({super.key, required this.videoPath, required this.videoType, required this.videoId, this.postVia});

  @override
  State<ReelUploadDetailsScreen> createState() => _ReelUploadDetailsScreenState();
}

class _ReelUploadDetailsScreenState extends State<ReelUploadDetailsScreen> {
  String? visibility;

  // Shorts
  TextEditingController _shortDescription = TextEditingController();
  TextEditingController _shortLink = TextEditingController();
  TextEditingController _brandPromotionLink = TextEditingController();

  // Videos
  TextEditingController _videoTitle = TextEditingController();

  // TextEditingController _videoSubtitle = TextEditingController();
  TextEditingController _videoDescription = TextEditingController();

  // Common
  String? _commonCoverImage;
  VideoCategoryData? _commonCategory;
  TextEditingController _commonKeywords = TextEditingController();

  bool _is18Plus = false;
  bool _showComments = false;
  bool _acceptBookings = false;
  bool _isBrandPromotion = false;

  final _formKey = GlobalKey<FormState>();
  final reelUploadDetailsController = Get.put<ReelUploadDetailsController>(
      ReelUploadDetailsController());
  Map<String, String>? tagUsers;
  Map<String, dynamic>? songData;
  Map<String, dynamic>? selectedLocation;
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;
  bool isBookingAvailabilitySet = false;


  // /// for showing progress of video uploading
  // RxDouble totalProgress = 0.0.obs;
  //
  // void setProgress(double value) {
  //   totalProgress.value = value;
  // }


  @override
   initState()  {
    super.initState();
    log('post via--> ${widget.postVia}');
    reelUploadDetailsController.getVideoCategories();
    if (widget.videoId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        reelUploadDetailsController.getVideosDetails(
            videoId: widget.videoId ?? '').then((response) {
          setVideoMetaData(reelUploadDetailsController.videoData.value);
        });
      });
    }else{
      setInitialCover();
    }

  }
  Future<void> setInitialCover() async {

    print("Video path: ${widget.videoPath}");

    final videoPath = widget.videoPath;

    if (videoPath != null && videoPath.isNotEmpty && File(videoPath).existsSync()) {
      try {
        final tempDir = await getTemporaryDirectory();

        final thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: videoPath,
          thumbnailPath: tempDir.path,
          imageFormat: ImageFormat.JPEG,
          maxHeight: 0,
          quality: 75,
        );

        if (thumbnailPath != null) {
          setState(() {
            _commonCoverImage = thumbnailPath;

          });
          print("Thumbnail generated at: $_commonCoverImage");
        } else {
          print("Failed to generate thumbnail");
        }
      } catch (e) {
        print("Thumbnail generation error: $e");
        _commonCoverImage = reelUploadDetailsController.videoData.value.video?.coverUrl ?? '';
      }
    } else {
      print("Video path invalid or file does not exist");
      _commonCoverImage = reelUploadDetailsController.videoData.value.video?.coverUrl ?? '';
    }
  }

  void setVideoMetaData(ShortFeedItem VideoFeedItemMetaData) async {
    // final response = await reelUploadDetailsController.getVideosDetails(videoId: widget.videoId ?? '');

    if (VideoFeedItemMetaData.video?.type == 'long') {
      _videoTitle.text = VideoFeedItemMetaData.video?.title ?? '';
      _videoDescription.text = VideoFeedItemMetaData.video?.description ?? '';
    } else {
      _shortDescription.text = VideoFeedItemMetaData.video?.title ?? '';
      songData = {
        ApiKeys.id: VideoFeedItemMetaData.video?.song?.id,
        ApiKeys.name: VideoFeedItemMetaData.video?.song?.name,
        ApiKeys.artist: VideoFeedItemMetaData.video?.song?.artist,
        ApiKeys.coverUrl: VideoFeedItemMetaData.video?.song?.coverUrl
      };
      _shortLink.text = VideoFeedItemMetaData.video?.relatedVideoLink ?? '';
    }

    _commonCoverImage = VideoFeedItemMetaData.video?.coverUrl ?? '';

    final savedCategoryId = VideoFeedItemMetaData.video!.categories![0].id;
    _commonCategory = reelUploadDetailsController.videoCategory
        .firstWhere((item) => item.sId == savedCategoryId);

    selectedLocation = {
      ApiKeys.name: VideoFeedItemMetaData.video?.location?.name ?? '',
      ApiKeys.lat: VideoFeedItemMetaData.video?.location?.lat ?? '',
      ApiKeys.lng: VideoFeedItemMetaData.video?.location?.lng ?? ''
    };

    final List<dynamic> rawList = VideoFeedItemMetaData.video?.taggedUsers ??
        [];

    tagUsers = {
      for (final item in rawList)
        if (item is Map<String, dynamic> &&
            item.containsKey(ApiKeys.id) &&
            item.containsKey(ApiKeys.name))
          item[ApiKeys.id] as String: item[ApiKeys.name] as String,
    };

    if (VideoFeedItemMetaData.video?.keywords != null)
      _commonKeywords.text = VideoFeedItemMetaData.video!.keywords!.join(', ');

    _is18Plus = VideoFeedItemMetaData.video?.isMatureContent ?? false;
    _showComments = VideoFeedItemMetaData.video?.allowComments ?? false;
    _acceptBookings =
        VideoFeedItemMetaData.video?.acceptBookingsOrEnquiries ?? false;
    _isBrandPromotion = VideoFeedItemMetaData.video?.isBrandPromotion ?? false;
    _brandPromotionLink.text =
        VideoFeedItemMetaData.video?.brandPromotionLink ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CommonBackAppBar(
          isLeading: true,
          title: (widget.videoId != null) ? 'Upload Post' : 'Create Post',
        ),

        body: Obx(() {
          if (reelUploadDetailsController.isVideoDetailsLoading.isFalse) {
            // if (widget.videoId != null) {
            //   setVideoMetaData(reelUploadDetailsController.videoData.value);
            // }
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Container(
                  margin: EdgeInsets.only(
                    left: SizeConfig.size15,
                    right: SizeConfig.size15,
                    top: SizeConfig.size15,
                    bottom: SizeConfig.size35,
                  ),
                  padding: EdgeInsets.all(SizeConfig.size15),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(SizeConfig.size10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: SizeConfig.size10,
                        offset: Offset(0, SizeConfig.size2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Builder(builder: (context) {
                              final height = (widget.videoType ==
                                  VideoType.video)
                                  ? SizeConfig.size220
                                  : SizeConfig.size250;
                              final width = (widget.videoType ==
                                  VideoType.video)
                                  ? SizeConfig.size320
                                  : SizeConfig.size180;
                              final addBtnWidth = (widget.videoType ==
                                  VideoType.video)
                                  ? SizeConfig.size220
                                  : SizeConfig.size140;
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    height: height,
                                    width: width,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.greyCA,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(SizeConfig.size18)),
                                    ),
                                    child: (_commonCoverImage != null)
                                        ? isNetworkImage(_commonCoverImage) ?
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          SizeConfig.size18),
                                      child: CachedNetworkImage(
                                        imageUrl: _commonCoverImage!,
                                        fit: BoxFit.cover,
                                        height: height,
                                        width: width,
                                      ),
                                    )
                                        : ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          SizeConfig.size18),
                                      child: Image.file(
                                        File(_commonCoverImage!),
                                        fit: BoxFit.cover,
                                        height: height,
                                        width: width,
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                  ),
                                  Positioned(
                                    bottom: SizeConfig.size12,
                                    left: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => selectImage(context),
                                      child: Center(
                                        child: Container(
                                            height: SizeConfig.size38,
                                            width: addBtnWidth,
                                            padding: EdgeInsets.all(8.0),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                  alpha: 0.6),
                                              borderRadius: BorderRadius
                                                  .circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment
                                                  .center,
                                              children: [
                                                Icon(Icons.add,
                                                    size: SizeConfig.size20,
                                                    color: Colors.white),
                                                SizedBox(
                                                    width: SizeConfig.size4),
                                                Text(
                                                  "Add Cover",
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ],
                                            )),
                                      ),
                                    ),
                                  )
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                      SizedBox(height: SizeConfig.size20),

                      if (widget.videoType == VideoType.video) ...[
                        CommonTextField(
                          textEditController: _videoTitle,
                          maxLength: 50,
                          maxLine: 1,
                          keyBoardType: TextInputType.text,
                          title: "Long Video Title",
                          hintText: "Enter the full video title (max 50 characters)",
                          isValidate: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter video title';
                            }
                            return null;
                          },
                          autovalidateMode: _autoValidate,
                        ),
                        // SizedBox(height: SizeConfig.size18),
                        // CommonTextField(
                        //   textEditController: _videoSubtitle,
                        //   maxLength: 60,
                        //   maxLine: 1,
                        //   keyBoardType: TextInputType.text,
                        //   title: "Video Subtitle",
                        //   hintText: "Add a short subheading (max 60 characters)",
                        //   isValidate: true,
                        //   validator: (value) {
                        //     if (value == null || value.isEmpty) {
                        //       return 'Please enter video subtitle';
                        //     }
                        //     return null;
                        //   },
                        //   autovalidateMode: _autoValidate,
                        // ),
                        SizedBox(height: SizeConfig.size18),
                        CommonTextField(
                          textEditController: _videoDescription,
                          maxLength: 500,
                          maxLine: 4,
                          keyBoardType: TextInputType.text,
                          title: "Video Description",
                          hintText: "Write a detailed description about the video content and hashtags... eg. Best day at the beach! #sunset#vibes",
                          isValidate: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter video description';
                            }
                            return null;
                          },
                          autovalidateMode: _autoValidate,
                        ),
                      ],
                      if (widget.videoType == VideoType.short) ...[
                        CommonTextField(
                          textEditController: _shortDescription,
                          maxLength: 120,
                          maxLine: 3,
                          keyBoardType: TextInputType.text,
                          title: "Description",
                          hintText: "Write your caption and add hashtags...eg. Best day at the beach! #sunset #vibes",
                          isValidate: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter video description';
                            }
                            return null;
                          },
                          autovalidateMode: _autoValidate,
                        ),
                      ],
                      SizedBox(height: SizeConfig.size18),

                      _tagPeopleTile(
                        icon: "assets/svg/tag_icon.svg",
                        label: "Tag people",
                        afterLabelText: "(Optional)",
                        callBack: () async {
                          final result = await Navigator.pushNamed(
                              context,
                              RouteHelper.getTagPeopleScreenRoute(),
                              arguments: {
                                ApiKeys.previouslySelectedItems: tagUsers
                              }
                          ) as Map<String, String>?;

                          if (result != null) {
                            setState(() {
                              tagUsers = Map.from(result);
                            });
                          } else {
                            tagUsers = null;
                          }
                        },
                        chips: tagUsers,
                        onChipDelete: (String userId) {
                          setState(() {
                            tagUsers?.remove(userId);
                          });
                        },
                      ),
                      SizedBox(height: SizeConfig.size20),

                      _optionTile(
                        icon: "assets/svg/location_icon.svg",
                        label: "Add location",
                        afterLabelText: "(Optional)",
                        callBack: () {
                          Navigator.pushNamed(
                            context,
                            RouteHelper.getSearchLocationScreenRoute(),
                            arguments: {
                              ApiKeys.onPlaceSelected: (double? lat,
                                  double? lng, String? address) {
                                if (address != null) {
                                  setState(() =>
                                  selectedLocation = {
                                    ApiKeys.name: address,
                                    ApiKeys.lat: lat,
                                    ApiKeys.lng: lng,
                                  });
                                }
                              },
                              ApiKeys.fromScreen: RouteConstant.CreateReelScreen
                            },
                          );
                        },
                        chips: selectedLocation?[ApiKeys.name] != null ? [
                          selectedLocation?[ApiKeys.name]
                        ] : [],
                        onChipDelete: (value) {
                          setState(() => selectedLocation?.clear());
                        },
                      ),


                      if (widget.videoType == VideoType.short) ...[
                        SizedBox(height: SizeConfig.size20),
                        _optionTile(
                          icon: "assets/svg/music_icon.svg",
                          label: "Add Song",
                          afterLabelText: "(Optional)",
                          callBack: () async {
                            final result = await Navigator.pushNamed(
                              context,
                              RouteHelper.getGetAllSongsScreenRoute(),
                              arguments: {
                                ApiKeys.videoPath: widget.videoPath,
                              },
                            ) as Map<String, dynamic>?;

                            if (result != null && result.isNotEmpty) {
                              setState(() {
                                songData = result;
                              });
                              log("songData--> $songData");
                            }
                          },
                          chips: songData?[ApiKeys.name] != null ? [
                            songData?[ApiKeys.name]
                          ] : [],
                          onChipDelete: (_) {
                            setState(() {
                              songData?.clear();
                            });
                          },
                        ),

                        SizedBox(height: SizeConfig.size20),
                        HttpsTextField(
                          controller: _shortLink,
                          title: "Add Long Video Link (Optional)",
                          hintText: "Eg., https://...",
                          isUrlValidate: false,
                        ),
                      ],

                      SizedBox(height: SizeConfig.size15),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: CustomText(
                          "Select Category",
                          fontSize: SizeConfig.medium,
                        ),
                      ),
                      SizedBox(height: SizeConfig.size10),
                      CommonDropdownDialog<VideoCategoryData>(
                        items: reelUploadDetailsController.videoCategory,
                        selectedValue: _commonCategory,
                        title: "Select Video Category",
                        hintText: "Eg. Entertainment, Educa...",
                        displayValue: (value) => value.name ?? '',
                        onChanged: (value) {
                          setState(() {
                            log('value--> $value');
                            _commonCategory = value;
                          });
                        },
                        // validator: (value) {
                        //   if (value == null) {
                        //     return 'Please select category';
                        //   }
                        //   return null;
                        // },
                      ),
                      SizedBox(height: SizeConfig.size15),

                      /// Keywords
                      CommonTextField(
                        textEditController: _commonKeywords,
                        keyBoardType: TextInputType.text,
                        title: "Add Keywords",
                        hintText: "Eg. Celebrity, Funny, Fitness, DIY",
                        isValidate: true,
                      ),

                      SizedBox(height: SizeConfig.size4),
                      CheckboxListTile(
                        side: BorderSide(
                          color: AppColors.greyCA,
                          width: 2.0,
                        ),
                        contentPadding: EdgeInsets.zero,
                        value: _is18Plus,
                        onChanged: (value) {
                          setState(() {
                            _is18Plus = value ?? false;
                          });
                        },
                        title: CustomText(
                          'Is this video/content 18+?',
                          fontSize: SizeConfig.medium,
                          color: AppColors.black,
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.primaryColor,
                        checkColor: AppColors.white,
                        visualDensity: const VisualDensity(horizontal: -4.0),
                      ),
                      SwitchListTile(
                        visualDensity: VisualDensity(vertical: -2),
                        contentPadding: EdgeInsets.zero,
                        value: _showComments,
                        onChanged: (value) {
                          setState(() {
                            _showComments = value;
                          });
                        },
                        title: Text(
                          'Show Comments',
                          style: TextStyle(
                            fontSize: SizeConfig.medium,
                            color: AppColors.black,
                          ),
                        ),
                        thumbColor: WidgetStateProperty.all(Colors.white),
                        inactiveTrackColor: AppColors.greyE6,
                      ),
                      if(channelId != '')...[
                        // if (widget.videoType == VideoType.short) ...[
                        //   SizedBox(height: SizeConfig.size10),
                        //   Align(
                        //     alignment: Alignment.centerLeft,
                        //     child: CustomText(
                        //       'How to Earn with BlueEra',
                        //       fontSize: SizeConfig.medium,
                        //       color: AppColors.black,
                        //     ),
                        //   ),
                        //   SizedBox(height: SizeConfig.size10),
                        // ],
                       /* SwitchListTile(
                          visualDensity: VisualDensity(vertical: -2),
                          contentPadding: EdgeInsets.zero,
                          value: _acceptBookings,
                          onChanged: (value) async {
                            log('value-- >> $value');

                            /// first we need to set availability is set or not
                            if (value) {
                              if (!isBookingAvailabilitySet) {
                                await showCommonDialog(
                                    context: context,
                                    text: 'Please set video booking availability',
                                    confirmCallback: () async {
                                      Navigator.of(context).pop();
                                      bool isBookingAvailability = await Get.to(
                                            () => SetAvailabilityScreen(
                                            id: channelId),
                                        // or AvailabilityScreen()
                                        routeName: RouteHelper
                                            .getAvailabilityScreenRoute(),
                                        arguments: {ApiKeys.id: channelId},
                                        transition: Transition.downToUp,
                                        duration: const Duration(
                                            milliseconds: 500),
                                        curve: Curves.easeOut,
                                      );
                                      setState(() {
                                        isBookingAvailabilitySet =
                                            isBookingAvailability;
                                        _acceptBookings =
                                            isBookingAvailabilitySet;
                                      });
                                    },
                                    cancelCallback: () {
                                      Navigator.of(context)
                                          .pop(); // Close the dialog
                                    },
                                    confirmText: AppLocalizations.of(context)!
                                        .yes,
                                    cancelText: AppLocalizations.of(context)!
                                        .no);
                              } else {
                                setState(() {
                                  _acceptBookings = value;
                                });
                              }
                            } else {
                              setState(() {
                                _acceptBookings = value;
                              });
                            }
                          },
                          title: Text(
                            'Accept Bookings or Enquiries',
                            style: TextStyle(
                              fontSize: SizeConfig.medium,
                              color: AppColors.black,
                            ),
                          ),
                          thumbColor: WidgetStateProperty.all(Colors.white),
                          inactiveTrackColor: AppColors.greyE6,
                        ),*/
                        // if (_acceptBookings) ...[
                        //   SizedBox(height: SizeConfig.size25),
                        //
                        //   Align(
                        //     alignment: Alignment.centerLeft,
                        //     child: CustomText(
                        //       'Bookings & Enquiries',
                        //       fontSize: SizeConfig.large,
                        //       fontWeight: FontWeight.w700,
                        //     ),
                        //   ),
                        //   SizedBox(height: SizeConfig.size25),
                        //   // Select Time slot
                        //   Align(
                        //     alignment: Alignment.centerLeft,
                        //     child: CustomText(
                        //       'Select Time Slot',
                        //       fontSize: SizeConfig.medium,
                        //     ),
                        //   ),
                        //   SizedBox(height: SizeConfig.paddingXSL),
                        //   SingleChildScrollView(
                        //     scrollDirection: Axis.horizontal,
                        //     child: Row(
                        //       children: [15, 20, 30].map((sec) {
                        //         final label = sec >= 60 ? '${(sec ~/ 60)} ${sec == 60 ? "hour" : "hours"}' : '$sec mins';
                        //         return Padding(
                        //           padding: const EdgeInsets.only(right: 12.0),
                        //           child: InkWell(
                        //             onTap: () {
                        //               _selectedTimeSlot = sec;
                        //               setState(() {});
                        //             },
                        //             borderRadius: BorderRadius.circular(10.0),
                        //             child: Container(
                        //               decoration: BoxDecoration(
                        //                 color: (_selectedTimeSlot == sec) ? AppColors.primaryColor : AppColors.greyE6,
                        //                 borderRadius: BorderRadius.circular(10.0),
                        //               ),
                        //               padding: EdgeInsets.symmetric(horizontal: SizeConfig.size25, vertical: SizeConfig.size12),
                        //               child: CustomText(
                        //                 label,
                        //                 fontSize: SizeConfig.medium,
                        //                 color: (_selectedTimeSlot == sec) ? AppColors.white : AppColors.black,
                        //               ),
                        //             ),
                        //           ),
                        //         );
                        //       }).toList(),
                        //     ),
                        //   ),
                        //
                        //   SizedBox(height: SizeConfig.size15),
                        //   // select days
                        //   Align(
                        //     alignment: Alignment.centerLeft,
                        //     child: CustomText(
                        //       'Select Days',
                        //       fontSize: SizeConfig.medium,
                        //     ),
                        //   ),
                        //   SizedBox(height: SizeConfig.paddingXSL),
                        //   Row(
                        //     children: [
                        //       Expanded(
                        //         child: CommonDropdown<String>(
                        //           items: daysOfWeek,
                        //           selectedValue: _selectedFromDay ?? null,
                        //           hintText: "From",
                        //           displayValue: (value) => value,
                        //           onChanged: (value) {
                        //             _selectedFromDay = value;
                        //             setState(() {});
                        //           },
                        //           validator: _acceptBookings ? (value) {
                        //             if (value == null) {
                        //               return 'Please select booking days';
                        //             }
                        //             return null;
                        //           } : null,
                        //         ),
                        //       ),
                        //       SizedBox(width: SizeConfig.size15),
                        //       Expanded(
                        //         child: CommonDropdown<String>(
                        //           items: daysOfWeek,
                        //           selectedValue: _selectedToDay ?? null,
                        //           hintText: "To",
                        //           displayValue: (value) => value,
                        //           onChanged: (value) {
                        //             _selectedToDay = value;
                        //             setState(() {});
                        //           },
                        //           validator: _acceptBookings ? (value) {
                        //             if (value == null) {
                        //               return 'Please select booking days';
                        //             }
                        //             return null;
                        //           } : null,
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        //   SizedBox(height: SizeConfig.size15),
                        //
                        //   // select time
                        //   Align(
                        //     alignment: Alignment.centerLeft,
                        //     child: CustomText(
                        //       'Select Time',
                        //       fontSize: SizeConfig.medium,
                        //     ),
                        //   ),
                        //   SizedBox(height: SizeConfig.paddingXSL),
                        //   Row(
                        //     children: [
                        //       Expanded(
                        //         child: CommonDropdown<String>(
                        //           items: _timeOfDay,
                        //           selectedValue: _selectedFromTime ?? null,
                        //           hintText: "From",
                        //           displayValue: (value) => value,
                        //           onChanged: (value) {
                        //             _selectedFromTime = value;
                        //             setState(() {});
                        //           },
                        //           validator: _acceptBookings ? (value) {
                        //             if (value == null) {
                        //               return 'Please select booking time';
                        //             }
                        //             return null;
                        //           } : null,
                        //         ),
                        //       ),
                        //       SizedBox(width: SizeConfig.size15),
                        //       Expanded(
                        //         child: CommonDropdown<String>(
                        //           items: _timeOfDay,
                        //           selectedValue: _selectedToTime ?? null,
                        //           hintText: "To",
                        //           displayValue: (value) => value,
                        //           onChanged: (value) {
                        //             _selectedToTime = value;
                        //             setState(() {});
                        //           },
                        //           validator: _acceptBookings ? (value) {
                        //             if (value == null) {
                        //               return 'Please select booking time';
                        //             }
                        //             return null;
                        //           } : null,
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        //   SizedBox(height: SizeConfig.size15),
                        //
                        //   // Type of booking
                        //   Align(
                        //     alignment: Alignment.centerLeft,
                        //     child: CustomText(
                        //       'Type of Booking',
                        //       fontSize: SizeConfig.medium,
                        //     ),
                        //   ),
                        //   SizedBox(height: SizeConfig.paddingXSL),
                        //
                        //   ///BOOKING TYPE...
                        //   CommonDropdown<String>(
                        //     items: ["Consultation", "Appointment", "Interview"],
                        //     selectedValue: _selectedTypeOfBooking ?? null,
                        //     hintText: "Eg. Consultation, Appointment...",
                        //     displayValue: (value) => value,
                        //     onChanged: (value) {
                        //       _selectedTypeOfBooking = value;
                        //       setState(() {});
                        //     },
                        //     validator: _acceptBookings ? (value) {
                        //       if (value == null) {
                        //         return 'Please select type of booking';
                        //       }
                        //       return null;
                        //     } : null,
                        //   ),
                        //   SizedBox(height: SizeConfig.size15),
                        //
                        //   CommonTextField(
                        //     textEditController: _feeController,
                        //     keyBoardType: TextInputType.number,
                        //     title: "Fee per Session",
                        //     hintText: "Eg. ₹499 Leave blank if you accept free...",
                        //     isValidate: false,
                        //   ),
                        //   SizedBox(height: SizeConfig.size10),
                        // ],
                        SwitchListTile(
                          visualDensity: VisualDensity(vertical: -2),
                          contentPadding: EdgeInsets.zero,
                          value: _isBrandPromotion,
                          onChanged: (value) {
                            setState(() {
                              _isBrandPromotion = value;
                            });
                          },
                          title: Row(
                            children: [
                              Text(
                                'Brand Promotion',
                                style: TextStyle(
                                  fontSize: SizeConfig.medium,
                                  color: AppColors.black,
                                ),
                              ),
                              SizedBox(width: SizeConfig.size10),
                              SvgPicture.asset(
                                "assets/svg/info_icon.svg",
                                height: SizeConfig.size18,
                                width: SizeConfig.size18,
                              ),
                            ],
                          ),
                          thumbColor: WidgetStateProperty.all(Colors.white),
                          inactiveTrackColor: AppColors.greyE6,
                        ),
                        if(_isBrandPromotion)
                          ...[
                            SizedBox(height: SizeConfig.size15),
                            HttpsTextField(
                              controller: _brandPromotionLink,
                              title: "Add brand promotion Link (Optional)",
                              hintText: "Eg., https://...",
                              isUrlValidate: _isBrandPromotion ? true : false,
                            ),
                          ]
                      ],
                      SizedBox(height: SizeConfig.size20),

                      (widget.videoId != null) ?
                      CustomBtn(
                        onTap: () => updateVideoDetails(),
                        height: SizeConfig.size40,
                        width: SizeConfig.screenWidth,
                        radius: 8,
                        title: 'Update Post',
                        borderColor: AppColors.primaryColor,
                        bgColor: AppColors.primaryColor,
                        textColor: AppColors.white,
                      )
                          : Row(
                        children: [
                          Expanded(
                            child: CustomBtn(
                              onTap: () => _onSubmit(visibleTo: 'unlisted'),
                              height: SizeConfig.size40,
                              width: SizeConfig.size140,
                              radius: 8,
                              title: 'Save as draft',
                              borderColor: AppColors.primaryColor,
                              bgColor: Colors.white,
                              textColor: AppColors.primaryColor,
                            ),
                          ),
                          SizedBox(width: SizeConfig.size10),
                          Expanded(
                            child: CustomBtn(
                              onTap: () => _onSubmit(visibleTo: 'public'),
                              height: SizeConfig.size40,
                              width: SizeConfig.size290,
                              radius: 8,
                              title: 'Post Now',
                              borderColor: AppColors.primaryColor,
                              bgColor: AppColors.primaryColor,
                              textColor: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size10),
                    ],
                  ),
                ),
              ),
            );
          }
          return Center(child: CircularProgressIndicator());
        })
    );
  }

  Widget _tagPeopleTile({
    required String icon,
    required String label,
    String? afterLabelText,
    required OnTab callBack,
    Map<String, String>? chips,
    void Function(String)? onChipDelete,
  }) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [AppShadows.textFieldShadow],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              width: 1,
              color: AppColors.greyE5
          )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            leading: LocalAssets(
              imagePath: icon,
              imgColor: AppColors.black,
            ),
            title: Row(
              children: [
                CustomText(
                  label,
                  fontSize: SizeConfig.large,
                  color: AppColors.black,
                ),
                const SizedBox(width: 4),
                if (afterLabelText != null)
                  CustomText(
                    afterLabelText,
                    fontSize: SizeConfig.small,
                    color: AppColors.grey83,
                  ),
              ],
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: AppColors.grey83,
              size: SizeConfig.size15,
            ),
            onTap: (chips == null) ? callBack : null,
          ),

          if (chips != null && chips.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      left: SizeConfig.size15, right: SizeConfig.size15),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 2,
                    children: chips.entries.map((entry) {
                      final id = entry.key;
                      final name = entry.value;

                      return Chip(
                        label: Text(name),
                        backgroundColor: AppColors.primaryColor.withValues(
                            alpha: 0.1),
                        labelStyle: TextStyle(color: AppColors.mainTextColor,
                            fontWeight: FontWeight.w400,
                            fontSize: SizeConfig.large),
                        deleteIcon: const Icon(Icons.close, size: 20,
                            color: AppColors.mainTextColor),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.transparent),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        onDeleted: onChipDelete != null
                            ? () => onChipDelete(id)
                            : null,
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                      left: SizeConfig.size5, right: SizeConfig.size15),
                  child: TextButton(
                    onPressed: callBack,
                    child: Row(
                      children: [
                        LocalAssets(imagePath: AppIconAssets.addBlueIcon,
                            imgColor: AppColors.primaryColor),
                        SizedBox(width: SizeConfig.size1),
                        CustomText('Add People', color: AppColors.primaryColor,
                            fontWeight: FontWeight.w400,
                            fontSize: SizeConfig.large),
                      ],
                    ),
                  ),
                )
              ],
            ),
        ],
      ),
    );
  }


  Widget _optionTile({
    required String icon,
    required String label,
    String? afterLabelText,
    required OnTab callBack,
    List<String>? chips,
    void Function(String)? onChipDelete,
  }) {
    return Container(
      // padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [AppShadows.textFieldShadow],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              width: 1,
              color: AppColors.greyE5
          )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            leading: LocalAssets(
              imagePath: icon,
              imgColor: AppColors.black,
            ),
            title: Row(
              children: [
                CustomText(
                  label,
                  fontSize: SizeConfig.large,
                  color: AppColors.black,
                ),
                const SizedBox(width: 4),
                if (afterLabelText != null)
                  CustomText(
                    afterLabelText,
                    fontSize: SizeConfig.small,
                    color: AppColors.grey83,
                  ),
              ],
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: AppColors.grey83,
              size: SizeConfig.size15,
            ),
            onTap: callBack,
          ),

          if (chips != null && chips.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: SizeConfig.size15,
                  right: SizeConfig.size15,
                  bottom: SizeConfig.size10),
              child: Wrap(
                spacing: 10,
                runSpacing: 2,
                children: chips.map((item) {
                  return Chip(
                    label: Text(item),
                    backgroundColor: AppColors.primaryColor.withValues(
                        alpha: 0.1),
                    labelStyle: TextStyle(color: AppColors.mainTextColor,
                        fontWeight: FontWeight.w400,
                        fontSize: SizeConfig.large),
                    deleteIcon: const Icon(
                        Icons.close, size: 20, color: AppColors.mainTextColor),
                    shape: RoundedRectangleBorder(side: BorderSide(color: Colors
                        .transparent),
                        borderRadius: BorderRadius.circular(8.0)),
                    onDeleted: onChipDelete != null
                        ? () => onChipDelete(item)
                        : null,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }


  void selectImage(BuildContext context) async {
    final croppedPath = await SelectProfilePictureDialog.pickFromGallery(
        context,
        cropAspectRatio: (widget.videoType == VideoType.video)
            ? CropAspectRatio(width: 16, height: 9)
            : CropAspectRatio(width: 9, height: 16));
    if (croppedPath != null) {
      _commonCoverImage = croppedPath;
      if (_commonCoverImage?.isNotEmpty ?? false) {
        setState(() {});
      }
    }
  }


  Future<void> _onSubmit({required String visibleTo}) async {
    visibility = visibleTo;
    if (_formKey.currentState?.validate() ?? false) {
      if (_commonCoverImage == null) {
        commonSnackBar(message: "Please add cover picture.");
        return;
      }

      // if(_acceptBookings){
      //   if(_selectedTimeSlot == null){
      //     commonSnackBar(message: "Please select your booking time slot");
      //     return;
      //   }
      // }

       uploadVideo();

      //uploadVideoNewsync();

      // videoUploadInBackground();

    } else {
      setState(() {
        _autoValidate = AutovalidateMode.always;
      });
    }
  }

  // /// Upload video + cover; returns true on success
  // Future<bool> _uploadAssets() async {
  //   try {
  //
  //     reelUploadDetailsController.showProgressVideoUploading(true);
  //
  //     final videoFile = File(widget.videoPath);
  //     final vInfo = getFileInfo(videoFile);
  //
  //     final coverFile = File(_commonCoverImage!);
  //     final cInfo = getFileInfo(coverFile);
  //
  //     // STEP 1: Init both uploads in parallel
  //     await Future.wait([
  //       reelUploadDetailsController.uploadInit(
  //         queryParams: {
  //           ApiKeys.fileName: vInfo['fileName'],
  //           ApiKeys.fileType: vInfo['mimeType']
  //         },
  //         isVideoUpload: true,
  //       ),
  //       reelUploadDetailsController.uploadInit(
  //         queryParams: {
  //           ApiKeys.fileName: cInfo['fileName'],
  //           ApiKeys.fileType: cInfo['mimeType']
  //         },
  //         isVideoUpload: false,
  //       ),
  //     ]);
  //
  //     // STEP 2: Upload both files in parallel
  //     double videoProgress = 0.0;
  //     double coverProgress = 0.0;
  //
  //     showUploadingProgressDialog(
  //       context: context,
  //       text: 'Uploading...',
  //       progressNotifier: totalProgress,
  //     );
  //     await Future.wait([
  //       reelUploadDetailsController.uploadFileToS3(
  //         file: videoFile,
  //         fileType: vInfo['mimeType']!,
  //         preSignedUrl: reelUploadDetailsController.uploadInitVideoFile!.uploadUrl!,
  //         onProgress: (sent) {
  //           videoProgress = sent;
  //           totalProgress.value = (videoProgress + coverProgress) / 2;
  //         },
  //       ),
  //       reelUploadDetailsController.uploadFileToS3(
  //         file: coverFile,
  //         fileType: cInfo['mimeType']!,
  //         preSignedUrl: reelUploadDetailsController.uploadInitCoverImageFile!.uploadUrl!,
  //         onProgress: (sent) {
  //           videoProgress = sent;
  //           totalProgress.value = (videoProgress + coverProgress) / 2;
  //         },
  //       ),
  //     ]);
  //
  //     /// for closing dialog need to pop the dialog
  //     Navigator.of(context).pop();
  //
  //     return true;
  //   } catch (e) {
  //
  //     /// for closing dialog need to pop the dialog
  //     Navigator.of(context).pop();
  //
  //     /// close this dialog
  //     reelUploadDetailsController.showProgressVideoUploading(false);
  //     // handle or rethrow
  //     return false;
  //   }
  // }

  Future<void> uploadVideo() async {
    double progress = 0.0;

    void updateProgress(double value) {
      progress = value.clamp(0.0, 1.0);
      UploadProgressDialog.update(progress);
    }

    // ✅ Show the dialog (GetX version, no context needed)
    UploadProgressDialog.show(initialProgress: progress);

    final videoFile = File(widget.videoPath);
    final coverFile = File(_commonCoverImage!);

    final videoInfo = getFileInfo(videoFile);
    final coverInfo = getFileInfo(coverFile);

    try {
      // 1. Init both uploads (20%)
      await Future.wait([
        reelUploadDetailsController.uploadInit(
          queryParams: {
            ApiKeys.fileName: videoInfo['fileName'],
            ApiKeys.fileType: videoInfo['mimeType']
          },
          isVideoUpload: true,
        ),
        reelUploadDetailsController.uploadInit(
          queryParams: {
            ApiKeys.fileName: coverInfo['fileName'],
            ApiKeys.fileType: coverInfo['mimeType']
          },
          isVideoUpload: false,
        ),
      ]);
      updateProgress(0.2);

      // 2. Upload files with combined progress (20% → 90%)
      double videoProgress = 0.0;
      double coverProgress = 0.0;

      void updateCombinedProgress() {
        // 20% init + 70% file uploads
        final combined = 0.2 + ((videoProgress + coverProgress) / 2) * 0.7;
        updateProgress(combined);
      }

      await Future.wait([
        reelUploadDetailsController.uploadFileToS3(
          file: videoFile,
          fileType: videoInfo['mimeType']!,
          preSignedUrl: reelUploadDetailsController.uploadInitVideoFile?.uploadUrl ?? "",
          onProgress: (total) {
            videoProgress = total;
            updateCombinedProgress();
          },
        ),
        reelUploadDetailsController.uploadFileToS3(
          file: coverFile,
          fileType: coverInfo['mimeType']!,
          preSignedUrl: reelUploadDetailsController.uploadInitCoverImageFile?.uploadUrl ?? "",
          onProgress: (total) {
            coverProgress = total;
            updateCombinedProgress();
          },
        ),
      ]);

      updateProgress(0.9);

      /// ✅ Common request data builder
      Map<String, dynamic> buildRequestData() {
        final baseData = <String, dynamic>{
          ApiKeys.videoUrl:
          reelUploadDetailsController.uploadInitVideoFile?.publicUrl ?? '',
          ApiKeys.videoKey:
          reelUploadDetailsController.uploadInitVideoFile?.fileKey ?? '',
          ApiKeys.coverUrl:
          reelUploadDetailsController.uploadInitCoverImageFile?.publicUrl ?? '',
          ApiKeys.visibility: visibility,
          if (widget.postVia == PostVia.channel) ApiKeys.channelId: channelId,
          if (tagUsers != null) ApiKeys.taggedUsers: tagUsers!.keys.toList(),
          if (selectedLocation != null && (selectedLocation?.isNotEmpty ?? false))
            ApiKeys.location: selectedLocation,
          if (_commonCategory != null) ApiKeys.categories: [_commonCategory?.sId],
          if (_commonKeywords.text.isNotEmpty)
            ApiKeys.keywords: _commonKeywords.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
          ApiKeys.isMatureContent: _is18Plus,
          ApiKeys.allowComments: _showComments,
          ApiKeys.acceptBookingsOrEnquiries: _acceptBookings,
          ApiKeys.isBrandPromotion: _isBrandPromotion,
        };

        if (widget.videoType == VideoType.video) {
          baseData.addAll({
            ApiKeys.type: 'long',
            ApiKeys.title: _videoTitle.text,
            if (_videoDescription.text.isNotEmpty)
              ApiKeys.description: _videoDescription.text,
          });
        } else {
          baseData.addAll({
            ApiKeys.type: 'short',
            ApiKeys.title: _shortDescription.text,
            if (songData != null) ApiKeys.song: songData,
            if (_shortLink.text.isNotEmpty) ApiKeys.relatedVideoLink: _shortLink.text,
          });
        }

        if (_isBrandPromotion && _brandPromotionLink.text.isNotEmpty) {
          baseData[ApiKeys.brandPromotionLink] = _brandPromotionLink.text;
        }

        return baseData;
      }

      final requestData = buildRequestData();

      await reelUploadDetailsController.uploadVideo(
        postVia: widget.postVia,
        reqData: requestData,
        onProgress: (value) => updateProgress(value),
      );

    } catch (e) {
      /// ❌ On error also close dialog
      UploadProgressDialog.close();
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }


  // Future<void> uploadVideoNewsync() async {
  //   double progress = 0.0;
  //
  //   // void updateProgress(double value) {
  //   //   progress = value.clamp(0.0, 1.0);
  //   //   updateUploadingProgress(progress);
  //   // }
  //
  //   showUploadingProgressDialog(context: context, progress: progress);
  //
  //
  //   Map<String, dynamic> requestData = {};
  //   if (widget.videoType == VideoType.video) {
  //     requestData = {
  //       ApiKeys.type: 'long',
  //       ApiKeys.videoUrl: reelUploadDetailsController.uploadInitVideoFile
  //           ?.publicUrl ?? '',
  //       ApiKeys.videoKey: reelUploadDetailsController.uploadInitVideoFile
  //           ?.fileKey ?? '',
  //       ApiKeys.coverUrl: reelUploadDetailsController.uploadInitCoverImageFile
  //           ?.publicUrl ?? '',
  //       ApiKeys.title: _videoTitle.text,
  //       ApiKeys.visibility: visibility,
  //       if(widget.postVia == PostVia.channel) ApiKeys.channelId: channelId,
  //       if(_videoDescription.text.isNotEmpty) ApiKeys
  //           .description: _videoDescription.text,
  //       if(tagUsers != null) ApiKeys.taggedUsers: tagUsers!.keys.toList(),
  //       if(selectedLocation != null &&
  //           (selectedLocation?.isNotEmpty ?? false)) ApiKeys
  //           .location: selectedLocation,
  //       if(_shortLink.text.isNotEmpty) ApiKeys.relatedVideoLink: _shortLink
  //           .text,
  //       if(_commonCategory != null) ApiKeys.categories: [_commonCategory?.sId],
  //       if(_commonKeywords.text.isNotEmpty) ApiKeys.keywords: _commonKeywords
  //           .text
  //           .split(',')
  //           .map((e) => e.trim())
  //           .where((e) => e.isNotEmpty)
  //           .toList(),
  //       ApiKeys.isMatureContent: _is18Plus,
  //       ApiKeys.allowComments: _showComments,
  //       ApiKeys.acceptBookingsOrEnquiries: _acceptBookings,
  //       ApiKeys.isBrandPromotion: _isBrandPromotion,
  //     };
  //     if (_isBrandPromotion) {
  //       if (_brandPromotionLink.text.isNotEmpty)
  //         requestData[ApiKeys.brandPromotionLink] = _brandPromotionLink.text;
  //     }
  //   }
  //
  //   // Close the progress dialog
  //   Navigator.of(context).pop();
  //
  //   // Start background upload using workmanager
  //   await WorkmanagerUploadService.startVideoUpload(
  //     videoPath: widget.videoPath,
  //     coverPath: _commonCoverImage!,
  //     requestData: requestData,
  //     isLongVideo: widget.videoType == VideoType.video,
  //   );
  //
  //   // Navigate back to the previous screen
  //   Get.until(
  //     (route) => Get.currentRoute == RouteHelper.getBottomNavigationBarScreenRoute(),
  //   );
  // }

  /// update video details (this video update is only completed for channels not for profile)
  Future<void> updateVideoDetails() async {
    Map<String, dynamic> requestData = {};

    if (widget.videoType == VideoType.video) {
      requestData = {
        ApiKeys.type: 'long',
        ApiKeys.videoUrl: reelUploadDetailsController.uploadInitVideoFile
            ?.publicUrl ?? '',
        ApiKeys.videoKey: reelUploadDetailsController.uploadInitVideoFile
            ?.fileKey ?? '',
        ApiKeys.coverUrl: reelUploadDetailsController.uploadInitCoverImageFile
            ?.publicUrl ?? '',
        ApiKeys.title: _videoTitle.text,
        ApiKeys.visibility: 'public',
        if(channelId.isNotEmpty) ApiKeys.channelId: channelId,
        if(_videoDescription.text.isNotEmpty) ApiKeys
            .description: _videoDescription.text,
        if(tagUsers != null) ApiKeys.taggedUsers: tagUsers?.keys.toList(),
        if(selectedLocation != null &&
            (selectedLocation?.isNotEmpty ?? false)) ApiKeys
            .location: selectedLocation,
        if(songData != null) ApiKeys.song: songData,
        if(_shortLink.text.isNotEmpty) ApiKeys.relatedVideoLink: _shortLink
            .text,
        if(_commonCategory != null) ApiKeys.categories: [_commonCategory?.sId],
        if(_commonKeywords.text.isNotEmpty) ApiKeys.keywords: _commonKeywords
            .text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        ApiKeys.isMatureContent: _is18Plus,
        ApiKeys.allowComments: _showComments,
        ApiKeys.acceptBookingsOrEnquiries: _acceptBookings,
        ApiKeys.isBrandPromotion: _isBrandPromotion,
      };
      if (_isBrandPromotion) {
        if (_brandPromotionLink.text.isNotEmpty)
          requestData[ApiKeys.brandPromotionLink] = _brandPromotionLink.text;
      }
    } else {
      requestData = {
        ApiKeys.type: 'short',
        ApiKeys.videoKey: reelUploadDetailsController.uploadInitVideoFile
            ?.fileKey ?? '',
        ApiKeys.videoUrl: reelUploadDetailsController.uploadInitVideoFile
            ?.publicUrl ?? '',
        ApiKeys.coverUrl: reelUploadDetailsController.uploadInitCoverImageFile
            ?.publicUrl ?? '',
        ApiKeys.visibility: visibility,
        ApiKeys.title: _shortDescription.text,
        // if(channelId.isNotEmpty)
        if(widget.postVia == PostVia.channel) ApiKeys.channelId: channelId,
        if(tagUsers != null) ApiKeys.taggedUsers: tagUsers!.keys.toList(),
        if(selectedLocation != null &&
            (selectedLocation?.isNotEmpty ?? false)) ApiKeys
            .location: selectedLocation,
        if(songData != null) ApiKeys.song: songData,
        if(_shortLink.text.isNotEmpty) ApiKeys.relatedVideoLink: _shortLink
            .text,
        if(_commonCategory != null) ApiKeys.categories: [_commonCategory?.sId],
        if(_commonKeywords.text.isNotEmpty) ApiKeys.keywords: _commonKeywords
            .text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        ApiKeys.isMatureContent: _is18Plus,
        ApiKeys.allowComments: _showComments,
        ApiKeys.acceptBookingsOrEnquiries: _acceptBookings,
        ApiKeys.isBrandPromotion: _isBrandPromotion,
      };
      if (_isBrandPromotion) {
        if (_brandPromotionLink.text.isNotEmpty)
          requestData[ApiKeys.brandPromotionLink] = _brandPromotionLink.text;
      }
    }
    await reelUploadDetailsController.updateVideoDetails(
        videoId: widget.videoId ?? '', reqData: requestData);
  }

  // late void Function(double) _updateProgressUI;
  //
  // void updateUploadingProgress(double progress) {
  //   _updateProgressUI(progress);
  // }
  //
  // void showUploadingProgressDialog({
  //   required BuildContext context,
  //   required double progress,
  // }) {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (_) {
  //       return AlertDialog(
  //         title: const Text(
  //           "Uploading...",
  //           style: TextStyle(fontSize: 14),
  //         ),
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(SizeConfig.size10),
  //         ),
  //         contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  //         content: StatefulBuilder(
  //           builder: (context, setState) {
  //             _updateProgressUI = (double newProgress) {
  //               setState(() {
  //                 progress = newProgress;
  //               });
  //             };
  //
  //             return Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.center,
  //               children: [
  //                 SizedBox(
  //                   height: 8,
  //                 ),
  //                 LinearProgressIndicator(
  //                   value: progress,
  //                   minHeight: 6,
  //                   backgroundColor: Colors.grey[300],
  //                   color: Colors.blue,
  //                 ),
  //                 const SizedBox(height: 12),
  //                 Text(
  //                   "${(progress * 100).toStringAsFixed(0)}% completed",
  //                   style: const TextStyle(fontSize: 14),
  //                 ),
  //               ],
  //             );
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }



// void videoUploadInBackground() {
  //   Map<String, dynamic> _longPayload(Map<String, dynamic> d,
  //       Map<String, dynamic> vInit,
  //       Map<String, dynamic> cInit,) =>
  //       {
  //         ApiKeys.type: 'long',
  //         'videoUrl': vInit['publicUrl'],
  //         'videoKey': vInit['fileKey'],
  //         'coverUrl': cInit['publicUrl'],
  //         'title': d['title'],
  //         'visibility': d['visibility'],
  //         if (d['channelId']?.isNotEmpty == true) 'channelId': d['channelId'],
  //         if (d['description']?.isNotEmpty ==
  //             true) 'description': d['description'],
  //         if (d['tagUsers'] != null) 'taggedUsers': d['tagUsers'],
  //         if (d['location']?.isNotEmpty == true) 'location': d['location'],
  //         if (d['categoryId'] != null) 'categories': [d['categoryId']],
  //         if (d['keywords']?.isNotEmpty == true) 'keywords': d['keywords'],
  //         'isMatureContent': d['is18Plus'],
  //         'allowComments': d['showComments'],
  //         'acceptBookingsOrEnquiries': d['acceptBookings'],
  //         'isBrandPromotion': d['isBrandPromotion'],
  //         if (d['isBrandPromotion'] == true &&
  //             d['brandPromotionLink']?.isNotEmpty == true)
  //           'brandPromotionLink': d['brandPromotionLink'],
  //       };
  //
  //   Map<String, dynamic> _shortPayload(Map<String, dynamic> d,
  //       Map<String, dynamic> vInit,
  //       Map<String, dynamic> cInit,) =>
  //       {
  //         'type': 'short',
  //         'videoUrl': vInit['publicUrl'],
  //         'videoKey': vInit['fileKey'],
  //         'coverUrl': cInit['publicUrl'],
  //         'title': d['shortDescription'],
  //         'visibility': d['visibility'],
  //         if (d['channelId']?.isNotEmpty == true) 'channelId': d['channelId'],
  //         if (d['tagUsers'] != null) 'taggedUsers': d['tagUsers'],
  //         if (d['location']?.isNotEmpty == true) 'location': d['location'],
  //         if (d['songData'] != null) 'song': d['songData'],
  //         if (d['relatedVideoLink']?.isNotEmpty == true)
  //           'relatedVideoLink': d['relatedVideoLink'],
  //         if (d['categoryId'] != null) 'categories': [d['categoryId']],
  //         if (d['keywords']?.isNotEmpty == true) 'keywords': d['keywords'],
  //         'isMatureContent': d['is18Plus'],
  //         'allowComments': d['showComments'],
  //         'acceptBookingsOrEnquiries': d['acceptBookings'],
  //         'isBrandPromotion': d['isBrandPromotion'],
  //         if (d['isBrandPromotion'] == true &&
  //             d['brandPromotionLink']?.isNotEmpty == true)
  //           'brandPromotionLink': d['brandPromotionLink'],
  //       };
  // }

}





