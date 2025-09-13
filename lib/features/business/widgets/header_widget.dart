import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/profile_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/size_config.dart';
import '../../chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:share_plus/share_plus.dart';

class HeaderWidget extends StatefulWidget {
  final String businessName;
  final String logoUrl;
  final String businessType;
  final String userId;
  final String location;
  final String businessId;

  const HeaderWidget({
    super.key,
    required this.businessName,
    required this.logoUrl,
    required this.businessType,
    required this.userId,
    required this.location,
    required this.businessId,
  });

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  late VisitProfileController controller;
  final viewBusiness = Get.find<ViewBusinessDetailsController>();
  final chatViewController = Get.find<ChatViewController>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller = Get.put(VisitProfileController());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InkWell(
              onTap: () {
                // navigatePushTo(context, BusinessDetailsEditPageOne());
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: widget.logoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.logoUrl,
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(Icons.business, color: Colors.grey),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(Icons.business, color: Colors.grey),
                        ),
                      )
                    : Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child:
                            Icon(Icons.business, color: Colors.grey, size: 40),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          widget.businessName,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          shareProfile();
                        },
                        child: Image.asset(
                          'assets/images/arrow.png',
                          height: 25,
                          width: 25,
                          fit: BoxFit.cover,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 3,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF2399F5)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CustomText(
                      widget.businessType,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2399F5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Location
                  (widget.location == '')
                      ? SizedBox()
                      : Row(
                          children: [
                            Image.asset(
                              'assets/images/location.jpg',
                              height: 20,
                              width: 20,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.location,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Follow & Chat Buttons
        Obx(() {
          return Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(color: AppColors.primaryColor),
                      backgroundColor: AppColors.primaryColor),
                  onPressed: () async {
                    if (isGuestUser()) {
                      createProfileScreen();

                      return;
                    }
                    if (controller.isFollow.value) {
                      await controller.unFollowUserController(
                          candidateResumeId: widget.userId);
                    } else {
                      await controller.followUserController(
                          candidateResumeId: widget.userId);
                    }

                    // await  viewBusiness.viewBusinessProfileById(widget.businessId);

                    // Handle follow action
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: SizeConfig.paddingXSmall),
                        CustomText(
                          controller.isFollow.value ? "Unfollow" : "Follow",
                          color: AppColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: SizeConfig.size12),
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(color: AppColors.primaryColor)),
                  onPressed: () async {
                    if (isGuestUser()) {
                      createProfileScreen();

                      return;
                    }
                    if (chatViewController.newVisitContactApiResponse?.value
                                ?.data?.conversationStatus ==
                            "business" ||
                        chatViewController.newVisitContactApiResponse?.value
                                ?.data?.conversationStatus ==
                            "contact") {
                      chatViewController.openAnyOneChatFunction(
                          type: "business",
                          profileImage: chatViewController
                              .newVisitContactApiResponse
                              ?.value
                              ?.data
                              ?.sender
                              ?.profileImage,
                          isInitialMessage: true,
                          userId: chatViewController.newVisitContactApiResponse
                                  ?.value?.data?.otherUserId ??
                              '',
                          conversationId: chatViewController
                                  .newVisitContactApiResponse
                                  ?.value
                                  ?.data
                                  ?.otherUserId ??
                              '',
                          contactName: chatViewController
                                  .newVisitContactApiResponse
                                  ?.value
                                  ?.data
                                  ?.sender
                                  ?.name ??
                              widget.businessName,
                          contactNo: chatViewController
                              .newVisitContactApiResponse
                              ?.value
                              ?.data
                              ?.sender
                              ?.contact,
                          businessId: chatViewController
                              .newVisitContactApiResponse
                              ?.value
                              ?.data
                              ?.sender
                              ?.businessId,
                          isFromContactList: true);
                    } else {
                      chatViewController.openAnyOneChatFunction(
                          type: "personal",
                          profileImage: chatViewController
                              .newVisitContactApiResponse
                              ?.value
                              ?.data
                              ?.sender
                              ?.profileImage,
                          isInitialMessage: false,
                          userId: chatViewController.newVisitContactApiResponse
                                  ?.value?.data?.sender?.id ??
                              "",
                          conversationId: chatViewController
                                  .newVisitContactApiResponse
                                  ?.value
                                  ?.data
                                  ?.conversationId ??
                              '',
                          contactName: chatViewController
                                  .newVisitContactApiResponse
                                  ?.value
                                  ?.data
                                  ?.sender
                                  ?.name ??
                              "",
                          contactNo: chatViewController
                                  .newVisitContactApiResponse
                                  ?.value
                                  ?.data
                                  ?.sender
                                  ?.contact ??
                              "",
                          businessId: chatViewController
                                  .newVisitContactApiResponse
                                  ?.value
                                  ?.data
                                  ?.sender
                                  ?.businessId ??
                              '',
                          isFromContactList: false);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: CustomText(
                      "Chat",
                      // (chatViewController.newVisitContactApiResponse?.value
                      //     ?.message?.isContact != null && (chatViewController
                      //     .newVisitContactApiResponse?.value?.message
                      //     ?.isContact ?? false)) ?
                      // "Chat" : (chatViewController.newConvResponse != null &&
                      //     (chatViewController.newConvResponse?.value?.message
                      //         ?.isConversation ?? false))
                      //     ? "Chat"
                      //     : "Request Chat",
                      color: AppColors.primaryColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  bool _isSharing = false;

  Future<void> shareProfile() async {
    // Prevent multiple calls
    if (_isSharing) return;

    try {
      _isSharing = true; // Set flag to prevent multiple calls

      final link = profileDeepLink(userId: widget.userId);
      final message = "See my profile on BlueEra:\n$link\n";

      await SharePlus.instance.share(ShareParams(
        text: message,
        subject: widget.businessName,
      ));

    } catch (e) {
      print("Profile share failed: $e");
    } finally {
      _isSharing = false; // Reset flag
    }
  }
}
