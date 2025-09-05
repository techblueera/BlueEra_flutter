import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';

// class HideConformationDialog extends StatelessWidget {
//   const HideConformationDialog(
//       {super.key,
//         required this.postId,
//         required this.postModelIndex
//       });
//
//   final String postId;
//   final int postModelIndex;
//
//   void hidePost(BuildContext context, int postModelIndex) {
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.transparent,
//       child: Container(
//         width: double.maxFinite,
//         color: Colors.transparent,
//         padding: EdgeInsets.only(
//           bottom: MediaQuery.of(context)
//               .viewInsets
//               .bottom, // Adjusts the padding when the keyboard appears
//         ),
//         child:
//         // Stack(
//         //   children: [
//         Padding(
//           padding: const EdgeInsets.all(12.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       AppLocalizations.of(context)!.areYouSureYouWantToHideThisPost,
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                           fontSize: SizeConfig.screenWidth * .045,
//                           fontWeight: FontWeight.w500,
//                           color: AppColors.black),
//                     ),
//                   ),
//                   SizedBox(width: SizeConfig.size10),
//                   InkWell(
//                     onTap: () => Navigator.pop(context),
//                     child: Icon(
//                       Icons.close,
//                       color: AppColors.black,
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: SizeConfig.size25),
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20,),
//                 child: CustomBtn(
//                   title: AppLocalizations.of(context)!.hide,
//                   width: SizeConfig.screenWidth,
//                   isValidate: true,
//                   onTap: () {
//                     // context.read<FeedBloc>().add(HidePostEvent(postId: postId));
//                     Navigator.pop(context);
//
//                     commonSnackBar(message: "Post Hide Successfully", isFromHomeScreen: true);
//
//                     showDialog(
//                       context: context,
//                       builder: (context) => Dialog(
//                         child: CustomSuccessSheet(
//                           buttonText: AppLocalizations.of(context)!.gotIt,
//                           subTitle: '',
//                           title: AppLocalizations.of(context)!.postHidden,
//                           onPress: () {
//                             Navigator.pop(context);
//                           },
//                         ),
//                       ),
//                       // const DeactivateAccountDialog(),
//                     );
//                   },
//                 ),
//               ),
//               SizedBox(height: SizeConfig.size5),
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20, vertical: SizeConfig.size5),
//                 child: CustomBtn(
//                   width: SizeConfig.screenWidth,
//                   title: AppLocalizations.of(context)!.goBack,
//                   onTap: () {
//                     Navigator.pop(context);
//                   },
//                   fontWeight: FontWeight.bold,
//                   isValidate: true,
//                   bgColor: AppColors.white,
//                   borderColor: AppColors.black,
//                   textColor: AppColors.black,
//                   fontSize: SizeConfig.screenWidth * 0.036,
//                 ),
//               ),
//
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }



class CustomSuccessSheet extends StatelessWidget {
  const CustomSuccessSheet(
      {super.key,
        required this.title,
        required this.subTitle,
        required this.buttonText,
        required this.onPress});

  final String title;
  final String subTitle;
  final String buttonText;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(
            color: AppColors.grey66,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12)),
      width: SizeConfig.screenWidth,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            AppIconAssets.circleCheck,
            height: 80,
            width: 80,
          ),
          SizedBox(height: SizeConfig.size15),
          Text(
            title,
            style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: SizeConfig.screenWidth * .06),
            textAlign: TextAlign.center,
          ),
          if (subTitle.isNotEmpty) SizedBox(height: SizeConfig.size15),
          if (subTitle.isNotEmpty)
            Text(
              subTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.black28,
                  fontWeight: FontWeight.w600,
                  fontSize: SizeConfig.screenWidth * .04),
            ),
          SizedBox(height: SizeConfig.size30),
          CustomBtn(
              title: buttonText,
              onTap: onPress,
              isValidate: true)
        ],
      ),
    );
  }
}