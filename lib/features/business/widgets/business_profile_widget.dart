import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/no_leading_space_formatter.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/business_description/business_description_controller.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/business_profile_header.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_details_bottom_sheet.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_bottom_sheet.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/owner_details_bottom_sheet.dart';
import 'package:BlueEra/features/business/visiting_card/visiting_cardlist_screen.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/visiting_card_helper.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
// import 'package:lottie/lottie.dart';
import '../../../core/constants/shared_preference_utils.dart';
import 'package:dio/dio.dart' as dioObj;
import '../visit_business_profile/view/visit_business_profile_new.dart';

class BusinessProfileWidget extends StatefulWidget {
  BusinessProfileWidget({
    super.key,
  });

  @override
  State<BusinessProfileWidget> createState() => _BusinessProfileWidgetState();
}

class _BusinessProfileWidgetState extends State<BusinessProfileWidget> {
  BusinessProfileDetails? details;
  // final listingDescriptionController = TextEditingController();
  final controller = Get.find<ViewBusinessDetailsController>();


  final businessDescriptionController =
      Get.put(BusinessDescriptionController());

  @override
  void initState() {
    // TODO: implement initState
    controller.isListingDescriptionEdit = true.obs;
    businessDescriptionController.descriptionSuggestions.clear();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    details = controller.businessProfileDetails?.data;

    final appLocalizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      children: [
        // CustomFormCard(
        //     padding: EdgeInsets.all(SizeConfig.size10),
        //     child: Column(
        //       children: [
        //         ///COMPANY PROFILE VIEW ....
        //         Row(
        //           crossAxisAlignment: CrossAxisAlignment.start,
        //           children: [
        //             ///UPLOAD PROFILE....
        //             CommonProfileImage(
        //               imagePath:
        //               controller.imagePath?.value ?? "",
        //               onImageUpdate: (image) async {
        //                 controller.imagePath?.value = image;
        //                 dioObj.MultipartFile? imageByPart;
        //                 // if (viewBusinessDetailsController.isImageUpdated.value) {
        //                 if (controller
        //                         .imagePath?.value.isNotEmpty ??
        //                     false) {
        //                   String fileName = controller
        //                           .imagePath?.value
        //                           .split('/')
        //                           .last ??
        //                       "";
        //                   imageByPart = await dioObj.MultipartFile.fromFile(
        //                       controller.imagePath?.value ??
        //                           "",
        //                       filename: fileName);
        //                 }
        //                 // }
        //                 dynamic reqData = {
        //                   ApiKeys.businessId: businessId,
        //                   ApiKeys.logo_image: imageByPart,
        //                 };
        //
        //                 await controller
        //                     .updateBusinessDetails(reqData);
        //               },
        //               dialogTitle: 'Upload Business Logo',
        //             ),
        //             SizedBox(width: SizeConfig.size10),
        //             Expanded(
        //               child: Padding(
        //                 padding: EdgeInsets.only(
        //                     top: SizeConfig.size10, left: SizeConfig.size8),
        //                 child: Column(
        //                   crossAxisAlignment: CrossAxisAlignment.start,
        //                   mainAxisAlignment: MainAxisAlignment.start,
        //                   children: [
        //                     Row(
        //                       children: [
        //                         Flexible(
        //                           child: CustomText(
        //                             "${details?.businessName ?? ''}",
        //                             fontWeight: FontWeight.w700,
        //                             fontSize: SizeConfig.size20,
        //                             color: AppColors.mainTextColor,
        //                             maxLines: 1,
        //                             overflow: TextOverflow.ellipsis,
        //                           ),
        //                         ),
        //                         SizedBox(
        //                           width: SizeConfig.size8,
        //                         ),
        //                         InkWell(
        //                             onTap: () {
        //                               // navigatePushTo(
        //                               //     context,
        //                               //     BusinessDetailsEditPageOne(
        //                               //         prevBusinessDetails: details
        //                               //     ));
        //
        //                               showModalBottomSheet(
        //                                 context: context,
        //                                 isScrollControlled: true,
        //                                 backgroundColor: Colors.transparent,
        //                                 builder: (context) =>
        //                                     BusinessDetailsBottomSheet(
        //                                   prevBusinessDetails: details,
        //                                 ),
        //                               );
        //                             },
        //                             child: LocalAssets(
        //                               height: 18,
        //                               imagePath: AppIconAssets.pen_line,
        //                               imgColor: AppColors.primaryColor,
        //                             ))
        //                       ],
        //                     ),
        //                     CustomText(
        //                       (details?.categoryDetails?.name?.isNotEmpty ??
        //                               false)
        //                           ? details?.categoryDetails?.name ?? 'Other'
        //                           : (details?.subCategoryDetails?.name
        //                                       ?.isNotEmpty ??
        //                                   false)
        //                               ? details?.subCategoryDetails?.name ?? ''
        //                               : (details?.natureOfBusiness ?? 'OTHERS'),
        //                       fontWeight: FontWeight.w400,
        //                       fontSize: SizeConfig.large,
        //                       color: AppColors.mainTextColor,
        //                       maxLines: 1,
        //                       overflow: TextOverflow.ellipsis,
        //                     ),
        //
        //                     if (details?.ownerDetails?.isNotEmpty ?? false)
        //                       Padding(
        //                         padding: EdgeInsets.only(top: SizeConfig.size8),
        //                         child: FittedBox(
        //                           fit: BoxFit.scaleDown,
        //                           child: Row(
        //                             crossAxisAlignment:
        //                                 CrossAxisAlignment.center,
        //                             children: [
        //                               CustomText(
        //                                 details?.ownerDetails?[0].name,
        //                                 fontWeight: FontWeight.w400,
        //                                 fontSize: SizeConfig.medium,
        //                                 color: AppColors.mainTextColor,
        //                               ),
        //                               SizedBox(width: SizeConfig.size4),
        //                               Container(
        //                                 padding: EdgeInsets.symmetric(
        //                                   horizontal: SizeConfig.size8,
        //                                   vertical: SizeConfig.size2,
        //                                 ),
        //                                 decoration: BoxDecoration(
        //                                     color: AppColors.appBackgroundColor,
        //                                     borderRadius:
        //                                         BorderRadius.circular(100.0),
        //                                     border: Border.all(
        //                                         color: AppColors
        //                                             .secondaryTextColor,
        //                                         width: 0.5)),
        //                                 child: CustomText(
        //                                   'Owner',
        //                                   fontWeight: FontWeight.w400,
        //                                   fontSize: SizeConfig.extraSmall,
        //                                   color: AppColors.secondaryTextColor,
        //                                 ),
        //                               ),
        //                               SizedBox(
        //                                 width: SizeConfig.size8,
        //                               ),
        //                               InkWell(
        //                                   onTap: () {
        //                                     showModalBottomSheet(
        //                                       context: context,
        //                                       isScrollControlled: true,
        //                                       backgroundColor:
        //                                           Colors.transparent,
        //                                       builder: (context) =>
        //                                           OwnerDetailsBottomSheet(
        //                                         prevBusinessDetails: details,
        //                                         // Pass existing params
        //                                         isFromCreateUser: false,
        //                                       ),
        //                                     );
        //                                   },
        //                                   child: LocalAssets(
        //                                     height: 18,
        //                                     imagePath: AppIconAssets.pen_line,
        //                                     imgColor: AppColors.primaryColor,
        //                                   ))
        //                             ],
        //                           ),
        //                         ),
        //                       )
        //
        //                     //   (details?.address == null || details?.address == '')
        //                     //     ? SizedBox()
        //                     //     : const SizedBox(
        //                     //   height: 4,
        //                     // ),
        //
        //                     // Row(
        //                     //   children: [
        //                     //     (details?.address == null || details?.address == '')
        //                     //         ? SizedBox()
        //                     //         : SvgPicture.asset(
        //                     //             height: 28,
        //                     //             width: 28,
        //                     //             "assets/svg/profile_location.svg",
        //                     //           ),
        //                     //     const SizedBox(
        //                     //       width: 4,
        //                     //     ),
        //                     //     Expanded(
        //                     //       child: CustomText(
        //                     //         "${details?.address ?? ''}",
        //                     //         fontSize: SizeConfig.size14,
        //                     //         maxLines: 2,
        //                     //         overflow: TextOverflow.ellipsis,
        //                     //       ),
        //                     //     ),
        //                     //   ],
        //                     // ),
        //                     // (details?.address == null || details?.address == '')
        //                     //     ? SizedBox()
        //                     //     : SizedBox(
        //                     //         height: SizeConfig.size10,
        //                     //       ),
        //                   ],
        //                 ),
        //               ),
        //             ),
        //           ],
        //         ),
        //         SizedBox(
        //           height: SizeConfig.size10,
        //         ),
        //
        //         (details?.businessIsVerified ?? false)
        //             ? Container(
        //                 width: Get.width,
        //                 padding: EdgeInsets.only(
        //                     top: SizeConfig.size10, left: SizeConfig.size10),
        //                 child: Container(
        //                   decoration: BoxDecoration(
        //                     color: theme.colorScheme.inversePrimary,
        //                     borderRadius: BorderRadius.circular(10),
        //                   ),
        //                   padding:
        //                       EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        //                   child: Row(
        //                     mainAxisSize: MainAxisSize.min,
        //                     crossAxisAlignment: CrossAxisAlignment.center,
        //                     mainAxisAlignment: MainAxisAlignment.center,
        //                     children: [
        //                       Icon(
        //                         Icons.check,
        //                         color: theme.colorScheme.onTertiary,
        //                       ),
        //                       const SizedBox(
        //                         width: 4,
        //                       ),
        //                       CustomText(
        //                         "Your business is verified.",
        //                         color: theme.colorScheme.onTertiary,
        //                         fontWeight: FontWeight.w500,
        //                         fontSize: SizeConfig.medium,
        //                         fontStyle: FontStyle.italic,
        //                       ),
        //                     ],
        //                   ),
        //                 ),
        //               )
        //             : Padding(
        //                 padding: EdgeInsets.only(
        //                     top: SizeConfig.size10, left: SizeConfig.size10),
        //                 child: Container(
        //                   width: Get.width,
        //                   decoration: BoxDecoration(
        //                     color: theme.colorScheme.tertiary,
        //                     borderRadius: BorderRadius.circular(10),
        //                   ),
        //                   padding:
        //                       EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        //                   child: Row(
        //                     mainAxisSize: MainAxisSize.min,
        //                     // crossAxisAlignment: CrossAxisAlignment.center,
        //                     // mainAxisAlignment: MainAxisAlignment.center,
        //                     children: [
        //                       SvgPicture.asset(
        //                         height: 18,
        //                         width: 18,
        //                         "assets/svg/ac_verify_icon.svg",
        //                       ),
        //                       const SizedBox(
        //                         width: 4,
        //                       ),
        //                       Expanded(
        //                         child: CustomText(
        //                           "Your business is not verified ",
        //                           color: theme.colorScheme.onTertiary,
        //                           fontWeight: FontWeight.w500,
        //                           fontSize: SizeConfig.medium,
        //                           fontStyle: FontStyle.italic,
        //                         ),
        //                       ),
        //                       SizedBox(
        //                         width: 1,
        //                       ),
        //                       Expanded(
        //                         child: InkWell(
        //                           onTap: () {
        //                             // Navigator.push(
        //                             //     context,
        //                             //     MaterialPageRoute(
        //                             //         builder: (context) =>
        //                             //             BusinessVerificationScrn()));
        //                             Get.to(() => VisitBusinessProfileNew(
        //                                   businessId: businessId,
        //                                   screenName: AppConstants.feedScreen,
        //                                 ));
        //                           },
        //                           child: CustomText(
        //                             fontWeight: FontWeight.w900,
        //                             "Verify Now",
        //                             color: theme.colorScheme.onTertiary,
        //                             fontStyle: FontStyle.italic,
        //                             fontSize: SizeConfig.medium,
        //                             decoration: TextDecoration.underline,
        //                             decorationColor:
        //                                 theme.colorScheme.onTertiary,
        //                           ),
        //                         ),
        //                       ),
        //                     ],
        //                   ),
        //                 ),
        //               ),
        //         SizedBox(
        //           height: SizeConfig.size18,
        //         ),
        //
        //         Row(
        //           children: [
        //             Expanded(
        //               child: TextButton(
        //                 style: TextButton.styleFrom(
        //                     shape: RoundedRectangleBorder(
        //                       borderRadius: BorderRadius.circular(
        //                           8), // Set your desired radius here
        //                     ),
        //                     side: BorderSide(color: theme.colorScheme.primary),
        //                     backgroundColor: theme.colorScheme.primary),
        //                 onPressed: null,
        //                 // onPressed: _captureAndShareCard,
        //                 child: Padding(
        //                   padding: const EdgeInsets.symmetric(vertical: 4),
        //                   child: Row(
        //                     mainAxisAlignment: MainAxisAlignment.center,
        //                     children: [
        //                       SizedBox(
        //                         width: SizeConfig.paddingXSmall,
        //                       ),
        //                       CustomText(
        //                         "Your Orders",
        //                         color: theme.colorScheme.surface,
        //                         fontSize: 15,
        //                         fontWeight: FontWeight.w700,
        //                       ),
        //                     ],
        //                   ),
        //                 ),
        //               ),
        //             ),
        //             SizedBox(
        //               width: SizeConfig.size12,
        //             ),
        //             Expanded(
        //               child: TextButton(
        //                 style: TextButton.styleFrom(
        //                     shape: RoundedRectangleBorder(
        //                       borderRadius: BorderRadius.circular(
        //                           8), // Set your desired radius here
        //                     ),
        //                     side: BorderSide(
        //                       color: theme.colorScheme.primary,
        //                     )),
        //                 onPressed: () {
        //                   _showVisitingCardDialog(context);
        //                 },
        //                 child: Padding(
        //                   padding: const EdgeInsets.symmetric(vertical: 4),
        //                   child: CustomText(
        //                     AppLocalizations.of(context)!.visitingCard,
        //                     color: theme.colorScheme.primary,
        //                     fontSize: 15,
        //                     fontWeight: FontWeight.w700,
        //                   ),
        //                 ),
        //               ),
        //             ),
        //           ],
        //         ),
        //         SizedBox(
        //           height: 16,
        //         ),
        //         SizedBox(height: SizeConfig.size12),
        //         Container(
        //           // margin: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
        //           padding: EdgeInsets.symmetric(
        //             vertical: SizeConfig.size10,
        //             horizontal: SizeConfig.size10,
        //           ),
        //           decoration: BoxDecoration(
        //             color: AppColors.white,
        //             border: Border.all(
        //               color: AppColors.whiteE5, // #E5E5E5 border
        //               width: 1,
        //             ),
        //             borderRadius: BorderRadius.circular(SizeConfig.size10),
        //             boxShadow: [AppShadows.textFieldShadow],
        //             // color: Colors.white, // optional background
        //           ),
        //           child: Row(
        //             mainAxisSize: MainAxisSize.min,
        //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //             children: [
        //               Expanded(
        //                 flex: 2,
        //                 child: Column(
        //                   crossAxisAlignment: CrossAxisAlignment.start,
        //                   children: [
        //                     buildInfo("Rating",
        //                         "★ ${(details?.rating ?? 0).toStringAsFixed(1)}"),
        //                     SizedBox(
        //                       height: SizeConfig.size12,
        //                     ),
        //                     buildInfo("Views",
        //                         "${formatIndianNumber(details?.total_views ?? 0)}"),
        //                   ],
        //                 ),
        //               ),
        //               // SizedBox(
        //               //   width: 100,
        //               // ),
        //               Expanded(
        //                 child: SizedBox(
        //                   height: SizeConfig.size50,
        //                   child: VerticalDivider(
        //                     color: AppColors.coloGreyText,
        //                     width: 12,
        //                     thickness: 1.2,
        //                   ),
        //                 ),
        //               ),
        //               // SizedBox(
        //               //   width: SizeConfig.size24,
        //               // ),
        //               Flexible(
        //                 flex: 2,
        //                 child: Container(
        //                   // color: Colors.red,
        //                   width: Get.width,
        //                   alignment: Alignment.center,
        //                   child: Column(
        //                     crossAxisAlignment: CrossAxisAlignment.start,
        //                     mainAxisAlignment: MainAxisAlignment.start,
        //                     children: [
        //                       buildInfo("Inquiries", formatIndianNumber(0)),
        //                       SizedBox(
        //                         height: SizeConfig.size12,
        //                       ),
        //                       InkWell(
        //                           onTap: () {
        //                             Get.to(() => FollowersFollowingPage(
        //                                   tabIndex: 1,
        //                                   userID: details?.id ?? "",
        //                                 ));
        //                           },
        //                           child: buildInfo("Followers",
        //                               "${formatIndianNumber(details?.total_followers ?? 0)}")),
        //                     ],
        //                   ),
        //                 ),
        //               ),
        //               // SizedBox(
        //               //   width: SizeConfig.size20,
        //               // ),
        //               SizedBox(
        //                 height: SizeConfig.size50,
        //                 child: VerticalDivider(
        //                   color: AppColors.coloGreyText,
        //                   width: 12,
        //                   thickness: 1.2,
        //                 ),
        //               ),
        //               SizedBox(
        //                 width: SizeConfig.size15,
        //               ),
        //               Column(
        //                 mainAxisAlignment: MainAxisAlignment.start,
        //                 crossAxisAlignment: CrossAxisAlignment.end,
        //                 children: [
        //                   CustomText(
        //                     "Joined",
        //                     fontSize: SizeConfig.size12,
        //                     color: AppColors.secondaryTextColor,
        //                     fontWeight: FontWeight.w700,
        //                   ),
        //                   SizedBox(height: SizeConfig.size2),
        //                   CustomText(
        //                     details?.dateOfIncorporation == null
        //                         ? ""
        //                         : "${details?.dateOfIncorporation?.date ?? ""}/${(details?.dateOfIncorporation?.month ?? 1)}/${details?.dateOfIncorporation?.year ?? ""}",
        //                     fontSize: SizeConfig.size12,
        //                     maxLines: 1,
        //                     fontWeight: FontWeight.w400,
        //                   ),
        //                   SizedBox(height: SizeConfig.size10),
        //                 ],
        //               )
        //             ],
        //           ),
        //         ),
        //         SizedBox(height: SizeConfig.size12),
        //       ],
        //     )),

        SizedBox(
          height: SizeConfig.size10,
        ),

        ///ABOUT YOUR BUSINESS...
        Obx(() {
          return CustomFormCard(
            padding: EdgeInsets.all(SizeConfig.size10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      letterSpacing: 0.4,
                      "Business Description",
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                      color: AppColors.secondaryTextColor,
                    ),
                    (controller.isListingDescriptionEdit.value)
                        ? Row(
                            children: [
                              InkWell(
                                  onTap: () {
                                    controller.listingDescriptionController.value.text =
                                        controller.businessDescription.value
                                            .toString();
                                    businessDescriptionController
                                        .generateDescriptions(bodyRequest: {
                                      ApiKeys.business_name: controller
                                          .businessProfileDetails
                                          ?.data
                                          ?.businessName,
                                      ApiKeys.category: controller
                                          .businessProfileDetails
                                          ?.data
                                          ?.categoryDetails
                                          ?.name,
                                      ApiKeys.sub_category: controller
                                          .businessProfileDetails
                                          ?.data
                                          ?.subCategoryDetails
                                          ?.name,
                                      ApiKeys.city: controller
                                          .businessProfileDetails
                                          ?.data
                                          ?.cityStatePincode,
                                    });
                                    // listingDescriptionController.text = controller
                                    //     .businessProfileDetails?.data.businessName.value
                                    //     .toString();
                                    setState(() {
                                      controller
                                              .isListingDescriptionEdit.value =
                                          !controller
                                              .isListingDescriptionEdit.value;
                                    });
                                  },
                                  child: LocalAssets(
                                    height: 25,
                                    width: 25,
                                    imgColor: AppColors.primaryColor,
                                    imagePath: AppIconAssets.ai_generative,
                                  )),
                              SizedBox(
                                width: SizeConfig.size10,
                              ),
                              InkWell(
                                  onTap: () {
                                    controller.listingDescriptionController.value.text=
                                        controller.businessDescription.value
                                            .toString();
                                    setState(() {
                                      controller
                                              .isListingDescriptionEdit.value =
                                          !controller
                                              .isListingDescriptionEdit.value;
                                    });
                                  },
                                  child: LocalAssets(
                                    height: 16,
                                    imagePath: AppIconAssets.pen_line,
                                  )),
                            ],
                          )
                        : Row(
                            children: [
                              CustomBtn(
                                  height: 24,
                                  width: 56,
                                  onTap: () {
                                    businessDescriptionController
                                        .descriptionSuggestions
                                        .clear();
                                    setState(() {
                                      controller
                                              .isListingDescriptionEdit.value =
                                          !controller
                                              .isListingDescriptionEdit.value;
                                    });
                                  },
                                  title: "Cancel"),
                              const SizedBox(
                                width: 8,
                              ),
                              CustomBtn(
                                  height: 24,
                                  width: 56,
                                  bgColor: theme.colorScheme.primary,
                                  onTap: () async {
                                    if (controller.listingDescriptionController.value.text.isNotEmpty) {
                                      businessDescriptionController
                                          .descriptionSuggestions
                                          .clear();
                                      setState(() {
                                        controller.isListingDescriptionEdit
                                                .value =
                                            !controller
                                                .isListingDescriptionEdit.value;
                                      });
                                      Map<String, dynamic> params = {
                                        ApiKeys.description:
                                            "${controller.listingDescriptionController.value.text}"
                                      };
                                      await controller
                                          .updateBusinessDescription(params);
                                    } else {
                                      commonSnackBar(
                                          message:
                                              "Description can not be empty");
                                    }
                                  },
                                  title: "Save"),
                            ],
                          )
                  ],
                ),
                CustomText(
                  appLocalizations?.tellCustomersWhatYouOffer,
                  fontSize: SizeConfig.size12,
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w400,
                ),

                (controller.isListingDescriptionEdit.value)
                    ? SizedBox()
                    : const SizedBox(
                        height: 4,
                      ),
                (controller.isListingDescriptionEdit.value &&
                        controller.businessDescription != '')
                    ? Container(
                        decoration: BoxDecoration(
                            color: AppColors.white,
                            border: Border.all(color: AppColors.whiteE5),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [AppShadows.textFieldShadow]),
                        width: double.infinity,
                        margin: EdgeInsets.only(top: 16),
                        padding:
                            EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                        child: Obx(() {
                          return CustomText(
                            "${controller.businessDescription.value}",
                            fontSize: SizeConfig.medium,
                            color: Colors.black,
                          );
                        }),
                      )
                    : CommonTextField(
                      validator: null,
                      borderWidth: 0,
                      borderColor: Colors.transparent,

                      hintText: "Add your business details",
                      textEditController: controller.listingDescriptionController.value,
                      maxLine: 5,
                      isValidate: false,
                      maxLength: AppConstants.inputCharterLimit400,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                          AppConstants.inputCharterLimit400,
                        ),
                        NoLeadingSpaceFormatter(),
                        NoConsecutiveSpacesFormatter(),
                      ],
                    ),

                Obx(() {
                  return SizedBox(
                    height: (controller.isListingDescriptionEdit.value)
                        ? 8
                        : SizeConfig.size18,
                  );
                }),
              ],
            ),
          );
        }),
        SizedBox(
          height: SizeConfig.size10,
        ),

        /// Inventory
        CustomFormCard(
          padding: EdgeInsets.all(SizeConfig.size10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                color: AppColors.secondaryTextColor,
                appLocalizations?.listYourProductServices,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(
                height: SizeConfig.size10,
              ),
              InkWell(
                onTap: () {
                  // details?.livePhotos
                  // controller.imgLocalL3.length
                  if ((details?.livePhotos?.length == 3) ||
                      controller.imgLocalL3.length == 3) {
                    Get.toNamed(RouteHelper.getInventoryScreenRoute());
                  } else {
                    commonSnackBar(
                        message: "Upload 3 store picture at least...");
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                      boxShadow: [AppShadows.textFieldShadow],
                      color: AppColors.white,
                      border:
                          Border.all(color: AppColors.primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size10,
                      vertical: SizeConfig.size10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              appLocalizations?.addYourProductServices,
                              // fontSize: SizeConfig.small,
                              fontWeight: FontWeight.bold,
                              color: AppColors.mainTextColor,
                            ),
                            SizedBox(
                              height: SizeConfig.size6,
                            ),
                            CustomText(
                              appLocalizations?.startSellingNow,
                              // fontSize: SizeConfig.small,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondaryTextColor,
                            ),
                            // CustomText(
                            //   "Organize your products into 👔 Men • 👗 Women • 🧒 Kids. Make shopping easier for your customers!",
                            //   fontSize: SizeConfig.extraSmall,
                            // ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: SizeConfig.size20,
                      ),
                      LocalAssets(imagePath: AppIconAssets.store_bg)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: SizeConfig.size10,
        ),

        ///STORE IMAGE...
        CustomFormCard(
            padding: EdgeInsets.all(SizeConfig.size10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      letterSpacing: 0.6,
                      "Your live store pictures",
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
                Row(
                  children: [
                    CustomText(
                      textAlign: TextAlign.left,
                      appLocalizations?.minThreeImg,
                      fontSize: SizeConfig.size12,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ],
                ),
                SizedBox(
                  height: SizeConfig.size10,
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ///API
                      (details?.livePhotos?.isNotEmpty ?? false)
                          ? Row(
                              children: List<Widget>.generate(
                                  (details?.livePhotos?.length ?? 0),
                                  (apiIndex) {
                                return _APIbuildImageContainer(
                                    details?.livePhotos?[apiIndex],
                                    apiIndex,
                                    false,
                                    apiIndex,
                                    theme,
                                    controller);
                              }),
                            )
                          : SizedBox(),

                      ///LOCAL
                      Row(
                        children: List<Widget>.generate(
                            controller.imgLocalL3.length, (localIndex) {
                          return _buildImageContainer(
                              controller.imgLocalL3[localIndex],
                              localIndex,
                              false,
                              controller);
                        }),
                      ),

                      ///EMPTY.....
                      (3 -
                                      (details?.livePhotos?.length ?? 0) -
                                      // controller.imgUploadL2.length -
                                      controller.imgLocalL3.length) +
                                  controller.imgDeleteL3.length >
                              0
                          ? Row(
                              children: List<Widget>.generate(
                                  (3 -
                                      (details?.livePhotos?.length ?? 0) -
                                      // controller.imgUploadL2.length -
                                      controller.imgLocalL3.length), (index) {
                                return _buildImageContainer(
                                    "", 0, false, controller);
                              }),
                            )
                          : SizedBox(),
                    ],
                  ),
                ),
              ],
            )),
        SizedBox(
          height: SizeConfig.size10,
        ),

        /// business Location
        if ((details?.businessLocation?.lat != null &&
                details?.businessLocation?.lat != 0) &&
            (details?.businessLocation?.lon != null &&
                details?.businessLocation?.lon != 0)) ...[
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.start,
          //   children: [
          //     CustomText(
          //       "Your business live location",
          //       fontSize: SizeConfig.large,
          //       fontWeight: FontWeight.bold,
          //       overflow: TextOverflow.ellipsis,
          //     ),
          //   ],
          // ),

          CustomFormCard(
            padding: EdgeInsets.all(SizeConfig.size10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CustomText(
                        "Your business live location",
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                    InkWell(
                        onTap: () => updateLocationDialog(context),
                        child: LocalAssets(
                          height: 16,
                          imagePath: AppIconAssets.pen_line,
                        ))
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CustomText(
                    "Your store’s map location",
                    fontSize: SizeConfig.medium,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w400,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  height: SizeConfig.size10,
                ),
                BusinessLocationWidget(
                  latitude: (details?.businessLocation?.lat?.toDouble() ?? 0.0),
                  longitude:
                      (details?.businessLocation?.lon?.toDouble() ?? 0.0),
                  businessName: details?.businessName ?? "",
                  isTitleShow: false,
                  locationText: details?.address ?? "",
                  padding: 0,
                ),
              ],
            ),
          )
        ],

        SizedBox(
          height: SizeConfig.size20,
        ),
      ],
    );
  }

  void _showVisitingCardDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey,
      builder: (context) {
        return SizedBox(
          height: Get.height * 0.8,
          child: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: SingleChildScrollView(
              child: Column(children: [
                Center(
                  child: Container(
                    height: 4,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: AppColors.white,
                    ),
                  ),
                ),
                SizedBox(
                  height: 12,
                ),
                Container(
                    // color: AppColors.pinkE2,
                    padding: EdgeInsets.all(SizeConfig.size12),
                    child: SingleChildScrollView(
                        child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SizedBox(height: SizeConfig.size12),

                        // Theme selector (4 themes) as pill chips
                        // Row(
                        //   mainAxisSize: MainAxisSize.max,
                        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //   children: [
                        //     CustomText(
                        //       'Visiting Card',
                        //       fontWeight: FontWeight.w600,
                        //       fontSize: SizeConfig.size14,
                        //       color: AppColors.black,
                        //     ),
                        //     InkWell(
                        //       onTap: () {
                        //         Get.back();
                        //         Get.to(() => VisitingCardlistScreen(),
                        //             arguments: details);
                        //         // Get.to(()=>VisitingCardlistScreen());
                        //       },
                        //       child: CustomText('View All',
                        //           fontWeight: FontWeight.w600,
                        //           fontSize: SizeConfig.size14,
                        //           color: AppColors.black),
                        //     ),
                        //   ],
                        // ),

                        VisitingCardPreview(details: details),
                        SizedBox(height: SizeConfig.size20),
                        Column(
                          children: [
                            buildCard1(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard2(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard3(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard4(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard5(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard6(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard7(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard8(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard9(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard10(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard11(details!),
                          ],
                        )
                        //
                        //                   // Footer actions
                        //                   Align(
                        //                     alignment: Alignment.center,
                        //                     child: ElevatedButton.icon(
                        //                       style: ElevatedButton.styleFrom(
                        //                         shape: const StadiumBorder(),
                        //                         // backgroundColor: accentChip, // per theme
                        //                         foregroundColor: Colors.white,
                        //                       ),
                        //                       onPressed: () {
                        //                         Navigator.of(context).maybePop();
                        //                       },
                        //                       icon: const Icon(Icons.ios_share,color: AppColors.black,),
                        //                       label: Text(
                        //                           AppLocalizations.of(context)!.shareVisitingCard,style: TextStyle(color: AppColors.black),
                        //                           ),
                        //                     ),
                        //                   ),
                      ],
                    )))
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageContainer(String? imagePath, int index,
      bool uploadFromGallery, ViewBusinessDetailsController controller) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () async {
            if (imagePath == "") {
              showCommonDialog(
                  context: context,
                  header: "Store Live Photo",
                  text: 'First of all you submit your store Live Photo (all 3)',
                  confirmCallback: () async {
                    Get.back();
                  },
                  cancelCallback: () async {
                    Get.back();
                    final imgStr =
                        await SelectProfilePictureDialog.pickFromCamera(
                      context,
                    );
                    if (imgStr != null) {
                      saveBusinessImages(
                          imgStr, controller.imgDeleteL3, controller);
                    }
                  },
                  confirmText: 'Cancel',
                  cancelText: 'Ok');
            } else {
              navigatePushTo(
                context,
                ImageViewScreen(
                  subTitle: '',
                  appBarTitle: AppLocalizations.of(context)!.imageViewer,
                  imageUrls: controller.imgLocalL3,
                  initialIndex: index,
                ),
              );
            }
          },
          child: Container(
            height: SizeConfig.screenWidth * .30,
            width: SizeConfig.screenWidth * .30,
            margin: EdgeInsets.only(
                right: SizeConfig.size6, bottom: 8, left: 4, top: 4),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.red),
              boxShadow: [AppShadows.textFieldShadow],
              borderRadius: BorderRadius.circular(10),
              image: imagePath != null
                  ? DecorationImage(
                      image: imagePath.startsWith("http")
                          ? NetworkImage(imagePath) as ImageProvider
                          : FileImage(File(imagePath)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imagePath == ""
                ? Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LocalAssets(
                            imagePath: AppIconAssets.profile_camera_pic),
                        SizedBox(
                          height: SizeConfig.size5,
                        ),
                        CustomText(
                          "Add Live \nStore Photo",
                          textAlign: TextAlign.center,
                          fontSize: SizeConfig.extraSmall,
                          decoration: TextDecoration.underline,
                        )
                      ],
                    ),
                  )
                : null,
          ),
        ),
        if (imagePath != "")
          Positioned(
            top: 8,
            right: 18,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(50)),
              child: GestureDetector(
                onTap: () {
                  Map<String, dynamic> data = {ApiKeys.image_url: imagePath};
                  controller.deleteLiveStoreImage(data);
                },
                child: const Icon(
                  Icons.close,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }

  ///UPDATE BUSINESS IMAGES....
  saveBusinessImages(String imagePath, List<int> deleteProfileId,
      ViewBusinessDetailsController controller) async {
    dio.MultipartFile? imageByPart;

    String fileName = imagePath.split('/').last;
    imageByPart =
        await dio.MultipartFile.fromFile(imagePath, filename: fileName);

    Map<String, dynamic> params = {ApiKeys.category_image: imageByPart};

    controller.uploadLiveStoreImage(params);
    await Future.delayed(Duration(seconds: 2));
    controller.imgDeleteL3.clear();
    // viewBusinessDetailsController.imgUploadL2.addAll(viewBusinessDetailsController.imgLocalL3);
  }

  Widget _APIbuildImageContainer(
      String? imagePath,
      int index,
      bool uploadFromGallery,
      int indexDelete,
      ThemeData theme,
      ViewBusinessDetailsController controller) {
    return Stack(
      children: [
        Container(
          height: SizeConfig.screenWidth * .30,
          width: SizeConfig.screenWidth * .30,
          margin: EdgeInsets.only(right: SizeConfig.size10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [AppShadows.textFieldShadow],
            image: imagePath != null
                ? DecorationImage(
                    image: imagePath.startsWith("http")
                        ? NetworkImage(imagePath) as ImageProvider
                        : FileImage(File(imagePath)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imagePath == null
              ? const Center(
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 32,
                  ),
                )
              : null,
        ),
        if (imagePath != null)
          Positioned(
            top: 8,
            right: 18,
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(50)),
              child: GestureDetector(
                onTap: () {
                  Map<String, dynamic> data = {ApiKeys.image_url: imagePath};
                  controller.deleteLiveStoreImage(data);
                  // if (!viewBusinessDetailsController.imgDeleteL3.contains(indexDelete)) {
                  //   viewBusinessDetailsController.imgDeleteL3.add(indexDelete);
                  // }
                },
                child: const Icon(
                  Icons.close,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> updateLocationDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size40),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          backgroundColor: AppColors.white,
          contentPadding: EdgeInsets.zero,
          content: Container(
            margin: EdgeInsets.only(
                left: SizeConfig.size16,
                right: SizeConfig.size16,
                bottom: SizeConfig.size16,
                top: SizeConfig.size8),
            // vertical: SizeConfig.size30, horizontal: SizeConfig.size40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                    alignment: Alignment.topRight,
                    child: InkWell(
                      onTap: () => Get.back(),
                      child: Icon(
                        Icons.close,
                        color: AppColors.secondaryTextColor,
                      ),
                    )),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LocalAssets(imagePath: AppIconAssets.warningIcon),
                    SizedBox(width: SizeConfig.size5),
                    CustomText(
                      "Update Location?",
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w700,
                      textAlign: TextAlign.center,
                      color: AppColors.mainTextColor,
                    ),
                  ],
                ),
                SizedBox(
                  height: SizeConfig.size7,
                ),
                CustomText(
                    "You can only update your location once in your lifetime. Make sure your in right location.",
                    fontSize: SizeConfig.medium,
                    textAlign: TextAlign.center,
                    color: AppColors.secondaryTextColor),
                SizedBox(height: SizeConfig.size15),
                Row(
                  children: [
                    Expanded(
                      child: CustomBtn(
                        height: SizeConfig.size45,
                        onTap: () => Get.back(),
                        title: "Cancel",
                        textColor: AppColors.secondaryTextColor,
                        bgColor: AppColors.white,
                        borderColor: AppColors.secondaryTextColor,
                        radius: 8.0,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size6),
                    Expanded(
                      child: CustomBtn(
                        height: SizeConfig.size45,
                        onTap: () {
                          Get.back();
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => BusinessLocationBottomSheet(
                                prevBusinessDetails: details),
                          );
                        },
                        title: "Confirm",
                        isValidate: true,
                        bgColor: AppColors.red02,
                        radius: 8.0,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class VisitingCardPreview extends StatelessWidget {
  final GlobalKey cardKey = GlobalKey();

  // final VisitingCardTheme theme;
  final BusinessProfileDetails? details;

  VisitingCardPreview({required this.details});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RepaintBoundary(
          key: cardKey,
          child: Container(
            padding: EdgeInsets.all(SizeConfig.size16),
            decoration: BoxDecoration(
              color: Color(0xFF31475A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: avatar + company block
                  Expanded(
                    // flex: 11,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: (details?.logo != null &&
                                      (details?.logo ?? '').isNotEmpty)
                                  ? NetworkImage(details?.logo ?? '')
                                  : null,
                              backgroundColor: Color(0xFF31475A),
                              child: (details?.logo == null ||
                                      (details?.logo ?? '').isEmpty)
                                  ? CustomText(
                                      (details?.businessName ?? 'B')
                                          .trim()
                                          .split(' ')
                                          .map((e) => e.isNotEmpty ? e[0] : '')
                                          .take(2)
                                          .join()
                                          .toUpperCase(),
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                        SizedBox(height: SizeConfig.size12),

                        // Company name and tagline
                        CustomText(
                          // 'BLUE (OPC) PVT LTD',
                          details?.businessName ?? "",
                          // details?.businessName ?? 'BLUE (OPC) PVT LTD',
                          fontWeight: FontWeight.w700,
                          fontSize: SizeConfig.size14,
                          color: AppColors.white,
                        ),
                        SizedBox(height: SizeConfig.size6),
                        CustomText(
                          details?.natureOfBusiness ?? 'Consultant Services',
                          color: AppColors.white,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w400,
                        ),
                        infoRow(
                            icon: Icons.call,
                            title:
                                (details?.businessNumber?.officeMobNo?.number ??
                                        0)
                                    .toString(),
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            textColor: AppColors.white),

                        SizedBox(height: SizeConfig.size12),

                        // Short description (optional)
                        CustomText(
                          details?.businessDescription ??
                              'to unique custom designs, we offer something special for every occasion.',
                          color: AppColors.white,
                          fontSize: SizeConfig.small,
                        ),
                      ],
                    ),
                  ),
                  VerticalDivider(
                    color: AppColors.appBackgroundColor,
                  ),

                  // Right: person and contact info
                  Expanded(
                    // flex: 10,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            details?.ownerDetails?.isNotEmpty ?? false
                                ? details?.ownerDetails?.first.name ?? ""
                                : "",
                            // details?.ownerDetails?.first.name ?? 'Manish Kumar',
                            fontWeight: FontWeight.w700,
                            fontSize: SizeConfig.size14,
                            color: AppColors.appBackgroundColor,
                          ),
                          SizedBox(height: SizeConfig.size2),
                          CustomText(
                            details?.ownerDetails?.isNotEmpty ?? false
                                ? details?.ownerDetails?.first
                                        .role_in_business ??
                                    ""
                                : "",
                            color: AppColors.appBackgroundColor,
                            fontSize: SizeConfig.small,
                          ),
                          SizedBox(height: SizeConfig.size10),
                          infoRow(
                              icon: Icons.call,
                              title: (details?.businessNumber?.officeMobNo
                                          ?.number ??
                                      0)
                                  .toString(),
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              textColor: AppColors.white),
                          // _infoRow(
                          //     Icons.phone,
                          //   (details?.businessNumber?.officeMobNo
                          //                           ?.number ??
                          //                       0)
                          //                   .toString(),

                          //     ),
                          SizedBox(height: SizeConfig.size8),

                          infoRow(
                              icon: Icons.email,
                              title: details?.ownerDetails?.isNotEmpty ?? false
                                  ? details?.ownerDetails?.first.email ?? ""
                                  : "",
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              textColor: AppColors.white),
                          SizedBox(height: SizeConfig.size8),
                          // _infoRow(
                          //     Icons.public,
                          //     details?.websiteUrl??"",
                          //     // details?.websiteUrl ?? 'www.vikash.bluehr.com',
                          //     textPrimary,
                          //     textSecondary,
                          //     iconAccent,
                          //     ellipsis: true),
                          infoRow(
                              icon: Icons.language,
                              title: details?.websiteUrl ?? "",
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              textColor: AppColors.white),
                          SizedBox(height: SizeConfig.size10),
                          infoRow(
                              icon: Icons.add_location,
                              title: details?.address ?? "",
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              textColor: AppColors.white)
                          // _infoRow(
                          //   Icons.add_location,
                          //   details?.address??"",
                          //   // details?.websiteUrl ?? 'www.vikash.bluehr.com',
                          //   textPrimary,
                          //   textSecondary,
                          //   iconAccent,
                          //   ellipsis: true),
                          // CustomText(
                          //   // "'www.vikash.bluehr.com",""
                          //   details?.address ??"",
                          //   //     '115, Road No 04 BN Ready Nagar Address abcdefgh1234567890 nmae Nagar\nHyderabad 834553',
                          //   color: textSecondary,
                          //   fontSize: SizeConfig.small,
                          // ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: InkWell(
            onTap: () async =>
                await VisitingCardHelper().shareVisitingCard(cardKey),
            child: Container(
              decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.white, blurRadius: 6, spreadRadius: 2)
                  ],
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.ios_share,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget infoRow(
      {required IconData? icon,
      required String? title,
      Color? textColor,
      double? fontSize,
      FontWeight? fontWeight,
      TextAlign? textAlign,
      Color? iconColor}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: AppColors.white,
        ),
        SizedBox(
          width: 5,
        ),
        Expanded(
            child: CustomText(
          title,
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: textColor,
        ))
      ],
    );
  }
}
