// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/app_constant.dart';
// import 'package:BlueEra/core/constants/app_icon_assets.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
// import 'package:BlueEra/l10n/app_localizations.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:BlueEra/widgets/local_assets.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// void showCodeDeliveryDialog(BuildContext context, String mobileNumber) {
//   final appLocalizations = AppLocalizations.of(context);

//   showDialog(
//     context: context,
//     builder: (context) {
//       return Dialog(
//         backgroundColor: Colors.white,
//         child: Padding(
//           padding: EdgeInsets.symmetric(
//               horizontal: SizeConfig.size20, vertical: SizeConfig.size20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Close icon
//               Align(
//                 alignment: Alignment.topRight,
//                 child: GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Icon(Icons.close, color: Colors.black),
//                 ),
//               ),
//               SizedBox(height: SizeConfig.size15),

//               // Title
//               CustomText(
//                 appLocalizations?.howWouldYouLikeToGetTheCode,
//                 textAlign: TextAlign.center,
//                 color: Colors.black,
//                 fontSize: SizeConfig.large,
//                 fontWeight: FontWeight.w700,
//               ),
//               SizedBox(height: SizeConfig.size18),

//               // WhatsApp & SMS buttons
//               _codeOptionButton(
//                   iconPath: AppIconAssets.whatsapp,
//                   label: appLocalizations?.whatsApp ?? "",
//                   otpType: AppConstants.WhatsApp),
//               SizedBox(height: SizeConfig.size15),
//               _codeOptionButton(
//                   iconPath: AppIconAssets.sms_sky,
//                   label: appLocalizations?.sms ?? "",
//                   otpType: AppConstants.SMS),
//               SizedBox(height: SizeConfig.size20),
//             ],
//           ),
//         ),
//       );
//     },
//   );
// }

// Widget _codeOptionButton({
//   required String iconPath,
//   required String label,
//   required String otpType,
// }) {
//   return SizedBox(
//     width: SizeConfig.screenWidth / 1.5,
//     child: ElevatedButton.icon(
//       onPressed: () async {
//         Get.find<AuthController>().isOtpType.value = otpType;
//         await Get.find<AuthController>()
//             .authMobileOtpSendViewModel();
//       },
//       style: ElevatedButton.styleFrom(
//         elevation: 0,
//         side: BorderSide(color: AppColors.primaryColor, width: 1),
//         backgroundColor: AppColors.white,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         padding: EdgeInsets.symmetric(
//             horizontal: SizeConfig.size20, vertical: SizeConfig.size10),
//       ),
//       icon: LocalAssets(
//         imagePath: iconPath,
//         imgColor: AppColors.primaryColor,
//       ),
//       label: CustomText(
//         label,
//         fontWeight: FontWeight.w600,
//         color: AppColors.primaryColor,
//       ),
//     ),
//   );
// }
