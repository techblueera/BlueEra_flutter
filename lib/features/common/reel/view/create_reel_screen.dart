// import 'dart:io';
// import 'dart:ui';
// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/app_constant.dart';
// import 'package:BlueEra/core/constants/app_icon_assets.dart';
// import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/core/constants/typedef_utils.dart';
// import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
// import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
// import 'package:BlueEra/features/common/map/view/searchLocationScreen.dart';
// import 'package:BlueEra/features/common/reelsModule/controller/reels_controller.dart';
// import 'package:BlueEra/features/common/reelsModule/model/fetch_reels_model.dart';
// import 'package:BlueEra/l10n/app_localizations.dart';
// import 'package:BlueEra/widgets/commom_textfield.dart';
// import 'package:BlueEra/widgets/common_back_app_bar.dart';
// import 'package:BlueEra/widgets/common_drop_down.dart';
// import 'package:BlueEra/widgets/custom_btn.dart';
// import 'package:BlueEra/widgets/custom_check_box.dart';
// import 'package:BlueEra/widgets/custom_switch_widget.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:BlueEra/widgets/local_assets.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import 'add_keywords.dart';
//
// class CreateReelScreen extends StatefulWidget {
//   final String videoPath;
//   String? videoThumbNail;
//   String? videoUploadType;
//   bool? isEditReel;
//   GetReelsData? reelsData;
//
//   CreateReelScreen(
//       {super.key,
//       required this.videoPath,
//       this.videoThumbNail,
//       this.isEditReel=false,
//       this.reelsData,
//       required this.videoUploadType});
//
//   @override
//   State<CreateReelScreen> createState() => _CreateReelScreenState();
// }
//
// class _CreateReelScreenState extends State<CreateReelScreen> {
//   List<String> timeOfDay = [];
//   File? coverPhoto;
//   String? _selectedTypeOfBooking;
//   String? _selectedFromDay;
//   String? _selectedToDay;
//   String? _selectedFromTime;
//   String? _selectedToTime;
//   bool showComments = true;
//   bool enableGift = false;
//   bool enableBookings = false;
//   bool isEighteenPlus = false;
//   int? selectedTimeSlot;
//   final captionController = TextEditingController();
//   final longVideoTitleController = TextEditingController();
//   final longVideoSubTitleController = TextEditingController();
//   final feeController = TextEditingController();
//   final longVideoLinkController = TextEditingController();
//   CategoryData? selectedCategory;
//   String? locationPlaceId, locationAddress;
//   final reelsController = Get.find<ReelsController>();
//
//   @override
//   void initState() {
//     super.initState();
//     reelsController.KeyWordList?.clear();
//     if (widget.isEditReel == false) {
//       timeOfDay = generate24HoursAmPm();
//     }
//
//     if (widget.isEditReel == true) {
//       GetReelsData? reelsData = widget.reelsData;
//
//       captionController.text = reelsData?.caption ?? "";
//       longVideoLinkController.text = reelsData?.video_long_link ?? "";
//       longVideoTitleController.text = reelsData?.long_video_title ?? "";
//       longVideoSubTitleController.text = reelsData?.video_sub_title ?? "";
//
//       showComments = reelsData?.allow_comments ?? false;
//       if (reelsData?.keywords?.isNotEmpty ?? false)
//         reelsController.KeyWordList?.addAll(reelsData?.keywords ?? []);
//
//
//     }
//
//   }
//
//   getCurrentLocation() async {
//
//   }
//
//   @override
//   void dispose() {
//     captionController.dispose();
//     super.dispose();
//   }
//
//   ///SELECT COVER IMAGE AND SHOW DIALOG...
//   selectImage(BuildContext context) async {
//     String imagePath = await SelectProfilePictureDialog.showLogoDialog(context, "Upload Cover Photo");
//     coverPhoto = File(imagePath);
//     if (coverPhoto?.path.isNotEmpty ?? false) {
//       ///SET IMAGE PATH...
//       widget.videoThumbNail = coverPhoto?.path;
//       setState(() {});
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final appLocalizations = AppLocalizations.of(context);
//
//     return Scaffold(
//       appBar: CommonBackAppBar(
//         isLeading: true,
//         title: widget.isEditReel == true ? "Edit Post" : "Create Post",
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.symmetric(vertical: SizeConfig.size25),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             /// Thumbnail + Add Cover
//             if (widget.isEditReel == false)
//               Align(
//                 alignment: Alignment.center,
//                 child: SizedBox(
//                   width: SizeConfig.screenWidth * 0.4,
//                   height: SizeConfig.screenHeight * 0.3,
//                   child: Stack(
//                     alignment: Alignment.bottomCenter,
//                     children: [
//                       (widget.videoThumbNail != null)
//                           ? ClipRRect(
//                               borderRadius: BorderRadius.circular(16),
//                               child: Image.file(
//                                   File(widget.videoThumbNail ?? ""),
//                                   width: SizeConfig.screenWidth * 0.4,
//                                   height: SizeConfig.screenHeight * 0.3,
//                                   fit: BoxFit.cover),
//                             )
//                           : CircularProgressIndicator(),
//                       if (coverPhoto != null)
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(16),
//                           child: BackdropFilter(
//                             filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
//                             child: Image.file(coverPhoto!,
//                                 width: SizeConfig.screenWidth * 0.4,
//                                 height: SizeConfig.screenHeight * 0.3,
//                                 fit: BoxFit.cover),
//                           ),
//                         ),
//                       InkWell(
//                         onTap: () => selectImage(context),
//                         child: Container(
//                           decoration: BoxDecoration(
//                               color: AppColors.blackD9,
//                               borderRadius: BorderRadius.circular(8)),
//                           padding: EdgeInsets.symmetric(
//                               vertical: SizeConfig.size10,
//                               horizontal: SizeConfig.size25),
//                           margin: EdgeInsets.symmetric(
//                               vertical: SizeConfig.size15,
//                               horizontal: SizeConfig.size12),
//                           child: Row(
//                             children: [
//                               Icon(Icons.add, size: 12, color: AppColors.white),
//                               SizedBox(width: SizeConfig.size10),
//                               Flexible(
//                                 child: CustomText(
//                                   "Add Cover",
//                                   fontSize: SizeConfig.small,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             SizedBox(height: SizeConfig.size15),
//
//             /// Long Video Title
//             if (widget.videoUploadType == AppConstants.long)
//               Padding(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: SizeConfig.size15,
//                 ),
//                 child: CommonTextField(
//                   textEditController: longVideoTitleController,
//                   maxLine: 2,
//                   maxLength: 50,
//                   // inputLength: AppConstants.inputCharterLimit50,
//                   keyBoardType: TextInputType.text,
//                   // regularExpression: RegularExpressionUtils.alphabetSpacePattern,
//                   title: "Long Video Title",
//                   hintText: "Enter the full video title (max 50 characters)",
//                   isValidate: false,
//                 ),
//               ),
//
//             /// Long Video Sub-Title
//             if (widget.videoUploadType == AppConstants.long)
//               Padding(
//                 padding: EdgeInsets.symmetric(
//                     horizontal: SizeConfig.size15, vertical: SizeConfig.size15),
//                 child: CommonTextField(
//                   textEditController: longVideoSubTitleController,
//                   maxLine: 2,
//                   maxLength: 60,
//                   keyBoardType: TextInputType.text,
//                   title: "Video Subtitle",
//                   hintText: "Add a short subheading (max 60 characters)",
//                   isValidate: false,
//                 ),
//               ),
//
//             /// Caption field
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
//               child: CommonTextField(
//                 textEditController: captionController,
//                 maxLine: 3,
//                 maxLength: 150,
//                 // inputLength: AppConstants.inputCharterLimit50,
//                 keyBoardType: TextInputType.text,
//                 // regularExpression: RegularExpressionUtils.alphabetSpacePattern,
//                 title: (widget.videoUploadType == AppConstants.long)
//                     ? "Video Description (optional)"
//                     : "Description",
//                 hintText:
//                     "Write your caption and add hashtags...\neg. Best day at the beach! #sunset #vibes",
//                 isValidate: false,
//                 // onChange: (value) => validateForm(),
//               ),
//             ),
//             SizedBox(height: SizeConfig.size15),
//
//             /// Tag/Location/Song Buttons
//
//             if ((widget.isEditReel == false))
//               Obx(() {
//                 return _optionButton(
//                     AppIconAssets.locationOutlinedIcon,
//                     (locationAddress?.isNotEmpty ?? false)
//                         ? locationAddress ?? ""
//                         : "Add location", () async {
//                   final data = await Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => SearchLocationScreen(),
//                     ),
//                   );
//                   if (data != null) {
//                     locationPlaceId = data[1];
//                     setState(() {});
//                   }
//                 });
//               }),
//             _optionButton(
//                 AppIconAssets.musicOutlinedIcon, "Add song (optional)", () {}),
//             ...widget.videoUploadType == AppConstants.short
//                 ? [
//                     SizedBox(height: SizeConfig.size15),
//                     Padding(
//                       padding:
//                           EdgeInsets.symmetric(horizontal: SizeConfig.size15),
//                       child: CustomText(
//                         "Add Long Video Link (Optional)",
//                         fontSize: SizeConfig.medium,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     SizedBox(height: SizeConfig.size10),
//                     Padding(
//                       padding:
//                           EdgeInsets.symmetric(horizontal: SizeConfig.size15),
//                       child: HttpsTextField(
//                         controller: longVideoLinkController,
//                         hintText: "Long video link",
//                       ),
//                     ),
//                   ]
//                 : [],
//             SizedBox(height: SizeConfig.size15),
//
//             ///Business Category ...
//             if ((widget.isEditReel == false)) ...[
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
//                 child: CustomText(
//                   appLocalizations?.businessCategory,
//                   fontSize: SizeConfig.medium,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               SizedBox(
//                 height: SizeConfig.size10,
//               ),
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
//                 child: BusinessCategoryWidget(
//                   editSelectedCategory: selectedCategory ?? null,
//                   onChanged: (value) {
//                     setState(() {
//                       selectedCategory = value as CategoryData?;
//                       // validateForm();
//                     });
//                   },
//                   validator: (value) {
//                     if (value == null) {
//                       return appLocalizations?.selectBusinessCategory;
//                     }
//                     return null;
//                   },
//                 ),
//               ),
//               SizedBox(
//                 height: SizeConfig.size20,
//               ),
//             ],
//
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
//               child: CustomText(
//                 appLocalizations?.keywords,
//                 fontSize: SizeConfig.medium,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//
//             Obx(() {
//               return InkWell(
//                 onTap: () {
//                   Get.to(KeyWordInputWidget(
//                       isSelectedSkills: reelsController.KeyWordList ?? []));
//                 },
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: AppColors.black28,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   margin: EdgeInsets.symmetric(
//                       horizontal: SizeConfig.size15,
//                       vertical: SizeConfig.size10),
//                   padding: EdgeInsets.symmetric(
//                       horizontal: SizeConfig.size15,
//                       vertical: SizeConfig.size10),
//                   width: SizeConfig.screenWidth,
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(
//                         horizontal: SizeConfig.size5,
//                         vertical: SizeConfig.size5),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: (reelsController.KeyWordList?.isNotEmpty ??
//                                   false)
//                               ? Wrap(
//                                   crossAxisAlignment: WrapCrossAlignment.start,
//                                   spacing: 12, // horizontal spacing
//                                   runSpacing: 12, // vertical spacing
//                                   children:
//                                       reelsController.KeyWordList!.map((skill) {
//                                     return Container(
//                                       padding: EdgeInsets.symmetric(
//                                           horizontal: SizeConfig.size15,
//                                           vertical: SizeConfig.size5),
//                                       decoration: BoxDecoration(
//                                         color: AppColors.blue3F,
//                                         // background color (custom dark)
//                                         borderRadius: BorderRadius.circular(
//                                             30), // pill shape
//                                       ),
//                                       child: CustomText(
//                                         skill,
//                                         color: Colors.white,
//                                         fontSize: SizeConfig.large,
//                                       ),
//                                     );
//                                   }).toList(),
//                                 )
//                               : CustomText("Add your keyword"),
//                         ),
//                         CustomText(
//                           "ADD",
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             }),
//             if ((widget.isEditReel == false)) _buildCheckBoxTile(),
//
//             _switchTile("Show Comments", showComments, (val) {
//               showComments = val;
//               setState(() {});
//             }),
//             if ((widget.isEditReel == false))
//               _switchTile("Enable Gifts", enableGift, (val) {
//                 enableGift = val;
//                 setState(() {});
//               }),
//             if ((widget.isEditReel == false))
//               _switchTile(
//                   "Accept Bookings or Enquiries (optional)", enableBookings,
//                   (val) {
//                 enableBookings = val;
//                 setState(() {});
//               }),
//
//             /// Booking Section
//             if (enableBookings) ...[
//               SizedBox(height: SizeConfig.size25),
//
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
//                 child: CustomText(
//                   'Bookings & Enquiries',
//                   fontSize: SizeConfig.large,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//               SizedBox(height: SizeConfig.size25),
//               // Select Time slot
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
//                 child: CustomText(
//                   'Select Time Slot',
//                   fontSize: SizeConfig.medium,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               SizedBox(height: SizeConfig.paddingXSL),
//               SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: Padding(
//                   padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
//                   child: Row(
//                     children: [15, 20, 30].map((sec) {
//                       final label = sec >= 60
//                           ? '${(sec ~/ 60)} ${sec == 60 ? "hour" : "hours"}'
//                           : '$sec mins';
//                       return Padding(
//                         padding: const EdgeInsets.only(right: 12.0),
//                         child: InkWell(
//                           onTap: () {
//                             selectedTimeSlot = sec;
//                             setState(() {});
//                           },
//                           borderRadius: BorderRadius.circular(10.0),
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: (selectedTimeSlot == sec)
//                                   ? AppColors.primaryColor
//                                   : AppColors.black28,
//                               borderRadius: BorderRadius.circular(10.0),
//                             ),
//                             padding: EdgeInsets.symmetric(
//                               horizontal: SizeConfig.size25,
//                               vertical: SizeConfig.size15,
//                             ),
//                             child: CustomText(
//                               label,
//                               fontSize: SizeConfig.large,
//                             ),
//                           ),
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               ),
//
//               SizedBox(height: SizeConfig.size15),
//
//               // select days
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
//                 child: CustomText(
//                   'Select Days',
//                   fontSize: SizeConfig.medium,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               SizedBox(height: SizeConfig.paddingXSL),
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: CommonDropdown<String>(
//                         items: daysOfWeek,
//                         selectedValue: _selectedFromDay ?? null,
//                         hintText: "From",
//                         displayValue: (value) => value,
//                         onChanged: (value) {
//                           _selectedFromDay = value;
//                           setState(() {});
//                         },
//                       ),
//                     ),
//                     SizedBox(width: SizeConfig.size15),
//                     Expanded(
//                       child: CommonDropdown<String>(
//                         items: daysOfWeek,
//                         selectedValue: _selectedToDay ?? null,
//                         hintText: "To",
//                         displayValue: (value) => value,
//                         onChanged: (value) {
//                           _selectedToDay = value;
//                           setState(() {});
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: SizeConfig.size15),
//
//               // select time
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
//                 child: CustomText(
//                   'Select Time',
//                   fontSize: SizeConfig.medium,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               SizedBox(height: SizeConfig.paddingXSL),
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: CommonDropdown<String>(
//                         items: timeOfDay,
//                         selectedValue: _selectedFromTime ?? null,
//                         hintText: "From",
//                         displayValue: (value) => value,
//                         onChanged: (value) {
//                           _selectedFromTime = value;
//                           setState(() {});
//                         },
//                       ),
//                     ),
//                     SizedBox(width: SizeConfig.size15),
//                     Expanded(
//                       child: CommonDropdown<String>(
//                         items: timeOfDay,
//                         selectedValue: _selectedToTime ?? null,
//                         hintText: "To",
//                         displayValue: (value) => value,
//                         onChanged: (value) {
//                           _selectedToTime = value;
//                           setState(() {});
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: SizeConfig.size15),
//
//               // Type of booking
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
//                 child: CustomText(
//                   'Type of Booking',
//                   fontSize: SizeConfig.medium,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               SizedBox(height: SizeConfig.paddingXSL),
//
//               ///BOOKING TYPE...
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
//                 child: CommonDropdown<String>(
//                   items: ["Consultation", "Appointment", "Interview"],
//                   selectedValue: _selectedTypeOfBooking ?? null,
//                   hintText: "e.g. Consultation, Appointment...",
//                   displayValue: (value) => value,
//                   onChanged: (value) {
//                     _selectedTypeOfBooking = value;
//                     setState(() {});
//                   },
//                 ),
//               ),
//               SizedBox(height: SizeConfig.size15),
//
//               /// SESSION FEES....
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
//                 child: CommonTextField(
//                   textEditController: feeController,
//                   keyBoardType: TextInputType.number,
//                   title: "Fee per Session",
//                   hintText: "e.g. ₹499 Leave blank if you accept free...",
//                   isValidate: false,
//                   // onChange: (value) => validateForm(),
//                 ),
//               ),
//             ],
//             SizedBox(height: SizeConfig.size20),
//
//             SizedBox(height: SizeConfig.size40),
//
//             // Buttons
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
//               child: CustomBtn(
//                 title: widget.isEditReel == true ? "Edit Post" : "Post Now",
//                 onTap: () async {
//                 },
//                 isValidate: true,
//               ),
//             ),
//
//
//             SizedBox(height: SizeConfig.size20),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _optionButton(String icon, String label, OnTab callBack) {
//     return Container(
//       margin: EdgeInsets.symmetric(vertical: 4, horizontal: SizeConfig.size15),
//       decoration: BoxDecoration(
//         color: AppColors.black28,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: ListTile(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//         leading: LocalAssets(
//           imagePath: icon,
//         ),
//         title: CustomText(
//           label,
//           fontSize: SizeConfig.large,
//         ),
//         trailing: Icon(Icons.arrow_forward_ios,
//             color: Colors.white, size: SizeConfig.size15),
//         onTap: () => callBack(),
//       ),
//     );
//   }
//
//   Widget _switchTile(String title, bool value, Function(bool) callback) {
//     return Padding(
//       padding: EdgeInsets.symmetric(
//           horizontal: SizeConfig.size15, vertical: SizeConfig.size10),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           CustomText(
//             title,
//             fontSize: SizeConfig.large,
//           ),
//           CustomSwitch(
//             value: value,
//             onChanged: (val) {
//               callback(val);
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCheckBoxTile() {
//     return Padding(
//       padding: EdgeInsets.symmetric(
//           horizontal: SizeConfig.size15, vertical: SizeConfig.size20),
//       child: Row(
//         // mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           CustomCheckBox(
//             isChecked: isEighteenPlus,
//             onChanged: () => setState(() => isEighteenPlus = !isEighteenPlus),
//             size: SizeConfig.size20,
//             activeColor: AppColors.primaryColor,
//             borderColor: Colors.white,
//           ),
//           SizedBox(
//             width: SizeConfig.size10,
//           ),
//           CustomText(
//             "Is this video/content 18+?",
//             color: Colors.white,
//             fontSize: SizeConfig.large,
//           ),
//         ],
//       ),
//     );
//   }
// }
