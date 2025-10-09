// import 'package:BlueEra/core/api/apiService/api_keys.dart';
// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/app_icon_assets.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/features/common/comment/controller/comment_controller.dart';
// import 'package:BlueEra/features/common/comment/view/comment_bottom_sheet.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:BlueEra/widgets/local_assets.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// class SendCommentField extends StatefulWidget {
//   final CommentType commentType;
//   final VoidCallback? onCommentAdded; // optional callback after comment is sent
//
//   const SendCommentField({
//     Key? key,
//     required this.commentType,
//     this.onCommentAdded,
//   }) : super(key: key);
//
//   @override
//   State<SendCommentField> createState() => _SendCommentFieldState();
// }
//
// class _SendCommentFieldState extends State<SendCommentField> {
//   final commentController = Get.find<CommentController>();
//
//   @override
//   Widget build(BuildContext context) {
//     final replyingTo = commentController.replyingToUser.value;
//
//     return Container(
//       color: AppColors.whiteFE,
//       padding: EdgeInsets.symmetric(
//         horizontal: SizeConfig.size15,
//         vertical: SizeConfig.size15,
//       ),
//       child: Column(
//         children: [
//           if (replyingTo != null)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 10),
//               child: _buildReplyBar(replyingTo),
//             ),
//           Row(
//             children: [
//               Expanded(child: _buildTextField(context)),
//               SizedBox(width: SizeConfig.size10),
//               _buildSendButton(context),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildReplyBar(String replyingTo) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(8),
//         color: AppColors.whiteEE.withValues(alpha: 0.5),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: CustomText(
//               "Replying to @$replyingTo",
//               fontWeight: FontWeight.w500,
//               fontSize: SizeConfig.medium,
//               color: AppColors.mainTextColor,
//             ),
//           ),
//           GestureDetector(
//             onTap: () {
//               commentController.replyingToUser.value = null;
//               commentController.parentCommentId = null;
//               commentController.sendMessageController.clear();
//             },
//             child: Icon(Icons.close, size: 20, color: AppColors.black),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTextField(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//       decoration: BoxDecoration(
//         color: AppColors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: AppColors.greyE5),
//       ),
//       child: Row(
//         children: [
//           LocalAssets(
//             imagePath: AppIconAssets.chat_box_smile,
//             imgColor: AppColors.coloGreyText,
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: TextFormField(
//               focusNode: commentController.replyFocusNode,
//               controller: commentController.sendMessageController,
//               style: const TextStyle(color: Colors.black),
//               onChanged: (_) => setState(() {}),
//               decoration: InputDecoration(
//                 hintText: "Write a comment...",
//                 hintStyle: TextStyle(
//                   color: AppColors.greyBf,
//                   fontSize: SizeConfig.size14,
//                 ),
//                 border: InputBorder.none,
//                 isDense: true,
//                 filled: true,
//                 fillColor: Colors.transparent,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSendButton(BuildContext context) {
//     final hasText =
//         commentController.sendMessageController.text.trim().isNotEmpty;
//
//     final isLoading = commentController.isSendCommentLoading.isTrue;
//
//     return InkWell(
//       onTap: hasText && !isLoading
//           ? () {
//         if (widget.commentType == CommentType.video) {
//           addVideoCommentToPost();
//         } else {
//           addCommentToPost();
//         }
//
//         // Clear input
//         commentController.sendMessageController.clear();
//
//         // Optional callback
//         widget.onCommentAdded?.call();
//
//         // Close keyboard
//         FocusScope.of(context).unfocus();
//       }
//           : null,
//       borderRadius: BorderRadius.circular(18),
//       child: Container(
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: hasText
//               ? AppColors.primaryColor
//               : AppColors.greyB3,
//           borderRadius: BorderRadius.circular(18),
//         ),
//         child: isLoading
//             ? const SizedBox(
//           height: 18,
//           width: 18,
//           child: CircularProgressIndicator(
//             strokeWidth: 2,
//             color: Colors.white,
//           ),
//         )
//             : LocalAssets(
//           height: 21,
//           width: 21,
//           imagePath: AppIconAssets.send_message_chat,
//         ),
//       ),
//     );
//   }
//
//   void addCommentToPost({String? media}) {
//     if (commentController.sendMessageController.value.text.isNotEmpty) {
//       Map<String, dynamic> params = {
//         ApiKeys.post_id: widget.id,
//         ApiKeys.message: "${commentController.sendMessageController.text}",
//       };
//       if (commentController.parentCommentId != null)
//         params[ApiKeys.parentCommentId] = commentController.parentCommentId;
//       commentController.addPostComment(params: params, postId: widget.id);
//     }
//   }
//
//   // New method for adding video comments
//   void addVideoCommentToPost({String? media}) {
//     if (commentController.sendMessageController.value.text.isNotEmpty) {
//       Map<String, dynamic> params = {
//         ApiKeys.videoId: widget.id,
//         ApiKeys.content: "${commentController.sendMessageController.text}",
//       };
//       if (commentController.parentCommentId != null)
//         params[ApiKeys.parentId] = commentController.parentCommentId;
//       commentController.addVideoComment(params: params, videoId: widget.id);
//     }
//   }
//
//
// }
