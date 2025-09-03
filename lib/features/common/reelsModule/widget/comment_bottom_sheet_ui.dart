// import 'dart:async';
//
// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/app_icon_assets.dart';
// import 'package:BlueEra/core/constants/common_methods.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/features/common/reelsModule/controller/reels_controller.dart';
// import 'package:BlueEra/features/common/reelsModule/font_style.dart';
// import 'package:BlueEra/features/common/reelsModule/model/get_reels_comment_model.dart';
// import 'package:BlueEra/features/common/reelsModule/widget/comment_shimmer_ui.dart';
// import 'package:BlueEra/l10n/app_localizations.dart';
// import 'package:BlueEra/widgets/commom_textfield.dart';
// import 'package:BlueEra/widgets/common_delete_conformation_dialog.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:BlueEra/widgets/local_assets.dart';
// import 'package:BlueEra/widgets/network_assets.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get/get_rx/src/rx_typedefs/rx_typedefs.dart';
//
// class CommentBottomSheetUi {
//   static RxBool isLoading = false.obs;
//   static GetReelCommentsModel? commentModel;
//   static RxList<ReelCommentsData> comments = <ReelCommentsData>[].obs;
//   static TextEditingController commentController = TextEditingController();
//   static ScrollController scrollController = ScrollController();
//   final reelsController = Get.find<ReelsController>();
//
//   Future<void> onGetComments({
//     required int commentType,
//     required String commentTypeId,
//   }) async {
//     isLoading.value = true;
//     comments.clear();
//
//     if (commentModel?.data != null) {
//       isLoading.value = false;
//       comments.addAll(commentModel?.data ?? []);
//     }
//   }
//
//
//   Future<int> show({
//     required BuildContext context,
//     required int commentType,
//     required String commentTypeId,
//     required int totalComments,
//   }) async {
//     final appLan = AppLocalizations.of(context);
//     commentController.clear();
//     onGetComments(commentType: commentType, commentTypeId: commentTypeId);
//
//     await showModalBottomSheet(
//       isScrollControlled: true,
//       scrollControlDisabledMaxHeightRatio: Get.height,
//       context: context,
//       backgroundColor: AppColors.transparent,
//       builder: (context) => Padding(
//         padding: MediaQuery.of(context).viewInsets,
//         child: Container(
//           height: 500,
//           width: Get.width,
//           clipBehavior: Clip.antiAlias,
//           decoration: const BoxDecoration(
//             color: AppColors.blue3F,
//             borderRadius: BorderRadius.only(
//               topLeft: Radius.circular(40),
//               topRight: Radius.circular(40),
//             ),
//           ),
//           child: Column(
//             children: [
//               Container(
//                 height: 65,
//                 color: AppColors.black28,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   children: [
//                     const Spacer(),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Container(
//                           height: 4,
//                           width: 35,
//                           decoration: BoxDecoration(
//                             color: AppColors.colorTextDarkGrey,
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                         SizedBox(
//                           height: SizeConfig.size10,
//                         ),
//                         CustomText(
//                           appLan?.comment,
//                           fontSize: SizeConfig.large,
//                         ),
//                       ],
//                     ).paddingOnly(left: 50),
//                     const Spacer(),
//                     InkWell(
//                       onTap: Get.back,
//                       child: Container(
//                         height: 30,
//                         width: 30,
//                         margin: const EdgeInsets.only(right: 20),
//                         child: Center(
//                           child:
//                               LocalAssets(imagePath: AppIconAssets.close_white),
//                         ),
//                       ),
//                     )
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: Obx(
//                   () => isLoading.value
//                       ? CommentShimmerUi()
//                       : comments.isEmpty
//                           ? CustomText("No data found")
//                           : SingleChildScrollView(
//                               controller: scrollController,
//                               child: ListView.builder(
//                                 itemCount: comments.length,
//                                 shrinkWrap: true,
//                                 padding: const EdgeInsets.only(
//                                     top: 15, left: 15, right: 15),
//                                 physics: NeverScrollableScrollPhysics(),
//                                 itemBuilder: (context, index) => Padding(
//                                   padding: const EdgeInsets.only(bottom: 20),
//                                   child: Row(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Container(
//                                           height: 45,
//                                           width: 45,
//                                           clipBehavior: Clip.antiAlias,
//                                           decoration: BoxDecoration(
//                                               shape: BoxShape.circle),
//                                           child: Stack(
//                                             children: [
//                                               AspectRatio(
//                                                 aspectRatio: 1,
//                                                 child: LocalAssets(
//                                                     imagePath: AppIconAssets
//                                                         .profilesIcon),
//                                               ),
//                                               AspectRatio(
//                                                 aspectRatio: 1,
//                                                 child: NetWorkOcToAssets(
//                                                     imgUrl: comments[index]
//                                                         .users
//                                                         ?.profileImage),
//                                               ),
//                                             ],
//                                           )),
//                                       SizedBox(
//                                         width: SizeConfig.size12,
//                                       ),
//                                       Expanded(
//                                         child: Column(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.end,
//                                           children: [
//                                             RichText(
//                                               text: TextSpan(
//                                                 text:
//                                                     comments[index].users?.name,
//                                                 style: AppFontStyle.styleW700(
//                                                     AppColors.white, 15),
//                                                 children: [
//                                                   TextSpan(
//                                                     text:
//                                                         "   ${timeAgo(DateTime.parse(comments[index].createdAt ?? DateTime.now().toString()))}",
//                                                     style:
//                                                         AppFontStyle.styleW600(
//                                                             AppColors
//                                                                 .coloGreyText,
//                                                             14),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                             SizedBox(
//                                               height: SizeConfig.size5,
//                                             ),
//                                             CustomText(
//                                               comments[index].message ?? "",
//                                               color: AppColors.white,
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                       SizedBox(
//                                         width: SizeConfig.size5,
//                                       ),
//                                       IconButton(
//                                           onPressed: () {
//                                             showDialog(
//                                               context: context,
//                                               builder: (context) =>
//                                                   ConfirmDeleteDialog(
//                                                 content:
//                                                     "Are you sure you want to delete this comment?",
//                                                 onDelete: () async {
//                                                   Navigator.of(context).pop();
//                                                 },
//                                               ),
//                                             );
//                                           },
//                                           icon: Icon(
//                                             Icons.delete_outline,
//                                             color: AppColors.red00,
//                                           ))
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                 ),
//               ),
//               CommentTextFieldUi(
//                 controller: commentController,
//                 onSend: () {
//
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//     return comments.isEmpty ? totalComments : comments.length;
//   }
// }
//
// class CommentTextFieldUi extends StatelessWidget {
//   const CommentTextFieldUi({
//     super.key,
//     required this.onSend,
//     required this.controller,
//   });
//
//   final Callback onSend;
//   final TextEditingController controller;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 50,
//       padding: const EdgeInsets.only(left: 15, right: 5),
//       alignment: Alignment.center,
//       margin: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(30),
//         color: AppColors.black28,
//         border: Border.all(color: AppColors.colorBorder.withOpacity(0.6)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           LocalAssets(imagePath: AppIconAssets.comment_white),
//           SizedBox(
//             width: SizeConfig.size5,
//           ),
//           VerticalDivider(
//             indent: 12,
//             endIndent: 12,
//             color: AppColors.coloGreyText.withOpacity(0.3),
//           ),
//           Expanded(
//             child: CommonTextField(
//               textEditController: controller,
//               maxLine: 1,
//               hintText: "Type a comment...",
//               isValidate: false,
//             ),
//           ),
//           GestureDetector(
//             onTap: onSend,
//             child: Container(
//               height: 40,
//               width: 40,
//               color: AppColors.transparent,
//               child: Center(child: LocalAssets(imagePath: AppIconAssets.send)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
