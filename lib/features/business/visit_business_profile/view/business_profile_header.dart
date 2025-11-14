import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/profile_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/gestures.dart';

import '../../../../widgets/common_box_shadow.dart';
import '../../../../widgets/highlight_text_widget.dart';

class BusinessProfileHeader extends StatefulWidget {
  BusinessProfileHeader({super.key, required this.businessProfileDetails});

  final BusinessProfileDetails businessProfileDetails;

  @override
  State<BusinessProfileHeader> createState() => _BusinessProfileHeaderState();
}

class _BusinessProfileHeaderState extends State<BusinessProfileHeader> {
  final controllerVisit = Get.put(VisitProfileController());

  final chatViewController = Get.find<ChatViewController>();

  final viewBusinessDetailsController =
  Get.find<ViewBusinessDetailsController>();

  @override
  void initState() {
    // TODO: implement initState
    controllerVisit.followerCount.value =
        widget.businessProfileDetails.total_followers ?? 0;
    super.initState();
  }
  bool isBusinessOpen(String open, String close) {
    DateTime now = DateTime.now();

    DateTime parseTime(String timeStr) {
      final parts = timeStr.split(":");
      int hour = int.tryParse(parts[0]) ?? 0;
      int minute = int.tryParse(parts[1]) ?? 0;
      return DateTime(now.year, now.month, now.day, hour, minute);
    }

    DateTime openTime = parseTime(open);
    DateTime closeTime = parseTime(close);

    // Handle overnight close (e.g. 22:00 → 03:00)
    if (closeTime.isBefore(openTime)) {
      return now.isAfter(openTime) || now.isBefore(closeTime);
    }

    return now.isAfter(openTime) && now.isBefore(closeTime);
  }


  @override
  Widget build(BuildContext context) {
    print('ssss${widget.businessProfileDetails.openTime}');
    print('ssss${widget.businessProfileDetails.closeTime}');
    final open = widget.businessProfileDetails.openTime ?? "09:00 AM";
    final close = widget.businessProfileDetails.closeTime ?? "06:00 PM";

    bool isOpenNow = isBusinessOpen(open, close);
    return Material(
      borderRadius: BorderRadius.circular(SizeConfig.size10),
      // elevation: 1.5,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === COVER PHOTO ===
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(SizeConfig.size10),
                  topRight: Radius.circular(SizeConfig.size10),
                ),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: Image.network(
                    (widget.businessProfileDetails.coverimage != null &&
                        widget.businessProfileDetails.coverimage!.isNotEmpty)
                        ? widget.businessProfileDetails.coverimage!
                        : (widget.businessProfileDetails.logo ?? ''),                    fit: BoxFit.cover,
                    // errorWidget: (_, __, ___) => Container(
                    //   color: Colors.grey.shade300,
                    //   alignment: Alignment.center,
                    //   child: Icon(Icons.image, color: Colors.grey),
                    // ),
                  ),
                ),
              ),

              // === PROFILE AVATAR ===
              Positioned(
                left: 16,
                bottom: -40,
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 43,
                    backgroundImage: NetworkImage(
                        widget.businessProfileDetails.logo ?? ''),
                    backgroundColor: Colors.grey.shade300,
                  ),
                ),
              ),
              // Positioned(
              //   right: 0,top: 180,
              //
              //     child: )
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14.0, right: 14),
            child: Obx(() {


              return Row(mainAxisAlignment: MainAxisAlignment.end,

                children: [

                  _buildActionButton("Chat", AppColors.white,
                      AppColors.primaryColor,
                          true,

                          () {
                        if (isGuestUser()) {
                          createProfileScreen();

                          return;
                        }
                        chatViewController
                            .openAnyOneChatFunction(
                          profileImage: widget.businessProfileDetails.logo,
                          otherUserId: (viewBusinessDetailsController
                              .conversationId.value == '')
                              ? viewBusinessDetailsController
                              .otherUserId?.value
                              : null,
                          businessId: widget.businessProfileDetails.id,
                          type: "business",
                          isInitialMessage: (viewBusinessDetailsController
                              .conversationId.value == '') ? true : false,
                          userId: widget.businessProfileDetails.userId,
                          conversationId:
                          viewBusinessDetailsController
                              .conversationId.value,
                          contactName: widget.businessProfileDetails
                              .businessName,
                          contactNo: widget.businessProfileDetails
                              .businessNumber
                              ?.officeMobNo
                              ?.number
                              .toString(),
                        );
                      }),
                  const SizedBox(width: 6),
                  _buildActionButton(controllerVisit.isFollow.value
                      ? "Unfollow"
                      : "Follow",
                      controllerVisit.isFollow.value?  AppColors.greylite:AppColors.primaryColor,
                      controllerVisit.isFollow.value? AppColors.secondaryTextColor:AppColors.white,
                          false,
                          () async {
                        if (isGuestUser()) {
                          createProfileScreen();
                        } else {
                          if (controllerVisit.isFollow.value) {
                            await controllerVisit.unFollowUserController(
                                candidateResumeId:
                                widget.businessProfileDetails.userId);
                          } else {
                            await controllerVisit.followUserController(
                                candidateResumeId:
                                widget.businessProfileDetails.userId);
                          }
                        }
                      }),

                  Material(
                    color: Colors.transparent,
                    child: SizedBox(
                      height: 28,
                      width: 28,
                      child: PopupMenuButton<String>(

                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),
                        color: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        icon: LocalAssets(imagePath: AppIconAssets
                            .more_vertical),
                        itemBuilder: (context) => popupMenuVisitProfileItemss(),
                        onSelected: (value) async {
                          if (value.toUpperCase() == "SHARE") {
                            final link = profileDeepLink(
                                userId: widget.businessProfileDetails.userId);
                            final message = "See my profile on BlueEra:\n$link\n";
                            await SharePlus.instance.share(
                              ShareParams(
                                text: message,
                                subject: widget.businessProfileDetails
                                    .businessName,
                              ),
                            );
                          } else if (value.toUpperCase() == "REPORT") {
                            // 👉 Handle report logic here
                            // e.g. open a dialog, send API call, etc.
                            showDialog(
                              context: context,
                              builder: (_) =>
                                  AlertDialog(
                                    title: const Text("Report"),
                                    content: const Text("Report this profile?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          // Perform report action
                                        },
                                        child: const Text("Report"),
                                      ),
                                    ],
                                  ),
                            );
                          }
                        },
                      ),
                    ),
                  )

                ],);
            }),
          ),

          // === NAME, BUTTONS ===
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10,vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: CustomText(
                    widget.businessProfileDetails.businessName ?? '',
                    fontSize: SizeConfig.size24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              ],
            ),
          ),

         // const SizedBox(height: 6),

          // === TAGS (Shop / Close) ===
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
            child: Row(
              children: [
                _buildTag(
                    widget.businessProfileDetails.categoryDetails?.name ?? '',
                    bgColor: AppColors.white,
                    textColor: AppColors.blackLite
                ),
                const SizedBox(width: 8),
                _buildTag(
                  isOpenNow ? "Open" : "Close",
                  bgColor: AppColors.white,
                  textColor: isOpenNow ? AppColors.greenShade : AppColors.redLite,
                ),

              ],
            ),
          ),

          const SizedBox(height: 12),

          // === DESCRIPTION ===
          if (widget.businessProfileDetails.businessDescription?.isNotEmpty ??
              false)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: DescriptionPreview(
                text: widget.businessProfileDetails.businessDescription ?? '',
                dialogTitle: "Business Description", // optional
              ),
            ),


          if (widget.businessProfileDetails.businessDescription?.isNotEmpty ??
              false)  const SizedBox(height: 12),

          // === STATS CONTAINER ===
          Container(
            margin: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
            padding: EdgeInsets.symmetric(
              vertical: SizeConfig.size10,
              horizontal: SizeConfig.size10,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(
                color: AppColors.whiteE5, // #E5E5E5 border
                width: 1,
              ),
              borderRadius: BorderRadius.circular(SizeConfig.size10),
              boxShadow: [AppShadows.textFieldShadow],
              // color: Colors.white, // optional background
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildInfo("Rating",
                          "★ ${(widget.businessProfileDetails.rating ?? 0)
                              .toStringAsFixed(1)}"),
                      SizedBox(
                        height: SizeConfig.size12,
                      ),
                      buildInfo("Views",
                          "${formatIndianNumber(
                              widget.businessProfileDetails.total_views ??
                                  0)}"),
                    ],
                  ),
                ),
                // SizedBox(
                //   width: 100,
                // ),
                Expanded(
                  child: SizedBox(
                    height: SizeConfig.size50,
                    child: VerticalDivider(
                      color: AppColors.coloGreyText,
                      width: 12,
                      thickness: 1.2,
                    ),
                  ),
                ),
                // SizedBox(
                //   width: SizeConfig.size24,
                // ),
                Obx(() {
                  return Flexible(
                    flex: 2,
                    child: Container(
                      // color: Colors.red,
                      width: Get.width,
                      alignment: Alignment.center,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          buildInfo("Inquiries", formatIndianNumber(0)),
                          SizedBox(
                            height: SizeConfig.size12,
                          ),

                          InkWell(
                              onTap: () {
                                Get.to(() =>
                                    FollowersFollowingPage(
                                      tabIndex: 1,
                                      userID: widget.businessProfileDetails
                                          ?.userId ?? "",
                                    ));
                              },
                              child: buildInfo("Followers",
                                  "${formatIndianNumber(
                                      controllerVisit.followerCount.value)}")),
                        ],
                      ),
                    ),
                  );
                }),
                // SizedBox(
                //   width: SizeConfig.size20,
                // ),
                SizedBox(
                  height: SizeConfig.size50,
                  child: VerticalDivider(
                    color: AppColors.coloGreyText,
                    width: 12,
                    thickness: 1.2,
                  ),
                ),
                SizedBox(
                  width: SizeConfig.size15,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CustomText(
                      "Joined",
                      fontSize: SizeConfig.size12,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                    SizedBox(height: SizeConfig.size2),
                    CustomText(
                      formattedCreatedAt(
                          widget.businessProfileDetails?.createdAt),
                      fontSize: SizeConfig.size12,
                      maxLines: 1,
                      fontWeight: FontWeight.w400,
                    ),

                    SizedBox(height: SizeConfig.size10),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// small info column
  Widget _buildInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          label,
          fontSize: SizeConfig.size12,
          fontWeight: FontWeight.w600,
          color: AppColors.secondaryTextColor,
        ),
        const SizedBox(height: 2),
        CustomText(
          value,
          fontSize: SizeConfig.size13,
          fontWeight: FontWeight.w700,
          color: AppColors.black,
        ),
      ],
    );
  }

  /// vertical divider
  Widget _divider() =>
      Container(
        height: 30,
        width: 1,
        color: const Color(0xFFE5E5E5),
      );

  /// tag (like Shop / Close)
  Widget _buildTag(String text, {Color? bgColor, Color? textColor}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: bgColor ?? Colors.grey.shade200,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: textColor ?? AppColors.black,)

      ),
      child: CustomText(
        text,
        fontSize: SizeConfig.size12,
        color: textColor ?? AppColors.black,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  /// reusable action buttons (Chat / Follow)
  Widget _buildActionButton(String label,
      Color bg,
      Color textColor,
      bool border,
      VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border?AppColors.primaryColor:Colors.transparent)
        ),
        child: CustomText(
          label,
          color: textColor,
          fontSize: SizeConfig.size10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

List<PopupMenuEntry<String>> popupMenuVisitProfileItemss() {
  return [
    PopupMenuItem<String>(
      value: 'Share',
      child: Row(
        children: [
          LocalAssets(
            imagePath: AppIconAssets.share_bold,
            height: SizeConfig.size20,
            width: SizeConfig.size20,
          ),
          const SizedBox(width: 8),
          Text(
            'Share',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
    const PopupMenuItem<String>(
      enabled: false,
      padding: EdgeInsets.zero,
      height: 1,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Divider(
          height: 1,
          thickness: 1,
          color: AppColors.greyE5,
        ),
      ),
    ),
    PopupMenuItem<String>(
      value: 'Report',
      child: Row(
        children: [

          const Icon(Icons.block_outlined, color: Colors.black54, size: 20),
          const SizedBox(width: 8),
          Text(
            'Report',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
    const PopupMenuItem<String>(
      enabled: false,
      padding: EdgeInsets.zero,
      height: 1,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Divider(
          height: 1,
          thickness: 1,
          color: AppColors.greyE5,
        ),
      ),
    ),
  ];
}

Widget buildInfo(String title, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CustomText(
        title + ":",
        fontSize: SizeConfig.size12,
        color: AppColors.secondaryTextColor,
        fontWeight: FontWeight.w400,
      ),
      SizedBox(width: SizeConfig.size6),
      Flexible(
        child: CustomText(
          value,
          fontSize: SizeConfig.size12,
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryTextColor,
        ),
      ),
    ],
  );
}

class DescriptionPreview extends StatefulWidget {
  final String text;
  final String? dialogTitle;

  const DescriptionPreview({
    Key? key,
    required this.text,
    this.dialogTitle,
  }) : super(key: key);

  @override
  State<DescriptionPreview> createState() => _DescriptionPreviewState();
}

class _DescriptionPreviewState extends State<DescriptionPreview> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final maxChars = 120; // ~4 lines

    final showMore = widget.text.length > maxChars;

    final displayText = showMore && !_expanded
        ? "${widget.text.substring(0, maxChars)}..."
        : widget.text;

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: SizeConfig.medium,
          color: Colors.black,
          fontFamily: AppConstants.OpenSans,
        ),
        children: [
          TextSpan(text: displayText),

          if (showMore && !_expanded)
            TextSpan(
              text: " Read more",
              style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  _showFullTextDialog(context, TextStyle());
                },
            ),
        ],
      ),
    );
  }

  void _showFullTextDialog(BuildContext context, TextStyle style) {
    showDialog(
      context: context,
      builder: (_) =>
          Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            insetPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Container(
              padding: EdgeInsets.all(SizeConfig.size16),
              constraints: BoxConstraints(
                maxWidth: MediaQuery
                    .of(context)
                    .size
                    .width * 0.92,
                // ⬇️ height expands naturally but limits only when too tall
                maxHeight: MediaQuery
                    .of(context)
                    .size
                    .height * 0.85,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                // 🔹 dynamic height based on content
                children: [
                  CustomText(
                    widget.dialogTitle ?? 'Business Description',
                    fontSize: SizeConfig.large18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),

                  SizedBox(height: SizeConfig.size10),

                  Flexible(
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: HighlightText(
                        text: widget.text,
                        style: TextStyle(
                          color: AppColors.mainTextColor,
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.w400,
                          fontFamily: AppConstants.OpenSans,
                          height: 1.30,
                        ),
                      ),
                    ),
                  ),

                  // ⬇️ Reduced gap to minimize bottom space
                  SizedBox(height: SizeConfig.size4),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      // 🔹 small bottom padding
                      child: TextButton(
                        style: ButtonStyle(
                          padding: MaterialStateProperty.all(EdgeInsets.zero),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: CustomText(
                          'Close',
                          fontWeight: FontWeight.w600,
                          fontSize: SizeConfig.medium15,
                          color: AppColors.primaryColor,
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

