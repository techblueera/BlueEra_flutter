import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/common/visiting_card/widget/share_button.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/api/model/personal_profile_details_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

class VisitingCardTwelve extends StatefulWidget {
  final BusinessProfileDetails? businessDetails;
  final PersonalProfileDetailsModel? personalDetails;

  const VisitingCardTwelve({super.key,
    this.businessDetails,
    this.personalDetails
  });

  @override
  State<VisitingCardTwelve> createState() => _VisitingCardTwelveState();
}

class _VisitingCardTwelveState extends State<VisitingCardTwelve> {
  final GlobalKey _cardKey = GlobalKey();

  String? _logo;
  String? _name;
  String? _profession;
  String? _officeLandlineNumber;
  String? _officeMobileNumber;
  String? _description;
  String? _ownerName;
  String? _roleInOffice;
  String? _email;
  String? _website;
  String? _address;

  @override
  void initState() {
    if(accountTypeGlobal == AppConstants.business) {
      BusinessProfileDetails? _data = widget.businessDetails;
      _logo = _data?.logo;
      _name = _data?.businessName;
      _profession = _data?.categoryDetails?.name;
      _officeLandlineNumber = _data?.businessNumber?.officeLandlineNo?.number;
      _officeMobileNumber = _data?.businessNumber?.officeMobNo?.number;
      _description = _data?.businessDescription;
      _ownerName = _data?.ownerDetails?.first.name;
      _roleInOffice = _data?.ownerDetails?.first.role_in_business;
      _website = _data?.websiteUrl;
      _email = _data?.ownerDetails?.first.email;
      _address = _data?.address;
    }else{
      User? _user = widget.personalDetails?.user;
      _logo = _user?.profileImage;
      _name = _user?.name;
      _profession = _user?.profession;
      _officeMobileNumber = _user?.contactNo??'0';
      _description = _user?.bio;
      _ownerName = _user?.username;
      _roleInOffice = _user?.designation;
      // _website = _user?.websiteUrl;
      _email = _user?.email;
      _address = _user?.location;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RepaintBoundary(
          key: _cardKey,
          child: Container(
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [AppShadows.textFieldShadow],
              image: const DecorationImage(
                image: AssetImage("assets/images/card_bg_11.png"),
                fit: BoxFit.fill,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: Get.width * 0.056, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // LEFT SECTION: Personal Info (White text on dark side)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20.0, left: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Owner Name & Role Block
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if ((_ownerName ?? "").isNotEmpty) ...[
                                    CustomText(
                                      _ownerName!,
                                      textAlign: TextAlign.center,
                                      fontWeight: FontWeight.w700,
                                      fontSize: SizeConfig.medium,
                                      color: AppColors.white,
                                    ),
                                    Container(
                                      height: 1,
                                      width: 100,
                                      color: Colors.white,
                                    ),
                                  ],
                                  if ((_roleInOffice ?? "").isNotEmpty)
                                    CustomText(
                                      _roleInOffice!,
                                      color: AppColors.white,
                                      fontSize: SizeConfig.small,
                                      fontWeight: FontWeight.w500,
                                    ),
                                ],
                              ),
                            ],
                          ),

                          SizedBox(height: SizeConfig.size18),

                          if (_officeMobileNumber != null)
                            cardRow(
                              icon: Icons.call,
                              title: _officeMobileNumber.toString(),
                              textColor: AppColors.white,
                              fontSize: SizeConfig.small11,
                              fontWeight: FontWeight.w500,
                              imagePath: "assets/svg/call_icon.svg",
                            ),

                          SizedBox(height: SizeConfig.size12),

                          if ((_email ?? "").isNotEmpty)
                            cardRow(
                              icon: Icons.email,
                              title: _email!,
                              fontWeight: FontWeight.w500,
                              textColor: AppColors.white,
                              fontSize: SizeConfig.small11,
                              imagePath: "assets/svg/email_icon.svg",
                            ),

                          SizedBox(height: SizeConfig.size12),

                          if ((_website ?? "").isNotEmpty)
                            cardRow(
                              icon: Icons.language,
                              title: _website!,
                              textColor: AppColors.white,
                              fontSize: SizeConfig.small11,
                              fontWeight: FontWeight.w500,
                              imagePath: "assets/svg/website_icon.svg",
                            ),

                          SizedBox(height: SizeConfig.size12),

                          if ((_address ?? "").isNotEmpty)
                            cardRow(
                              icon: Icons.location_on,
                              textColor: AppColors.white,
                              imagePath: "assets/svg/card_location_icon.svg",
                              fontSize: SizeConfig.small11,
                              fontWeight: FontWeight.w500,
                              title: _address!,
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 30),

                  // RIGHT SECTION: Business Identity (Dark text on light side)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.transparent,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: (_logo != null && _logo!.isNotEmpty)
                                  ? Image.network(
                                _logo!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Image.asset("assets/images/be_logo.png"),
                              )
                                  : Image.asset("assets/images/be_logo.png"),
                            ),
                          ),
                          SizedBox(height: SizeConfig.size8),

                          if ((_name ?? "").isNotEmpty)
                            CustomText(
                              _name!,
                              fontWeight: FontWeight.w700,
                              fontSize: SizeConfig.small,
                              color: AppColors.black,
                              textAlign: TextAlign.center,
                            ),

                          SizedBox(height: SizeConfig.size2),

                          if ((_profession ?? "").isNotEmpty)
                            CustomText(
                              _profession!,
                              color: AppColors.black,
                              fontSize: SizeConfig.small11,
                              fontWeight: FontWeight.w500,
                              textAlign: TextAlign.center,
                            ),

                          SizedBox(height: SizeConfig.size2),

                          if (_officeLandlineNumber != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.call, size: 16),
                                const SizedBox(width: 4),
                                CustomText(
                                  _officeLandlineNumber.toString(),
                                  color: AppColors.black,
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ],
                            ),

                          SizedBox(height: SizeConfig.size8),

                          if ((_description ?? "").isNotEmpty)
                            CustomText(
                              _description!,
                              color: AppColors.black,
                              fontSize: SizeConfig.small11,
                              fontWeight: FontWeight.w500,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        VisitingCardShareButton(cardKey: _cardKey),
      ],
    );
  }

  Widget cardRow(
      {required IconData icon,
        required String imagePath,
        required String? title,
        Color? textColor,
        double? fontSize,
        FontWeight? fontWeight,
        TextAlign? textAlign,
        Color? iconColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 18,
          width: 18,
          decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.white)),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: Colors.white,
            size: 12,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: CustomText(
            title,
            color: textColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
            textAlign: textAlign,
          ),
        ),
      ],
    );
  }

}
