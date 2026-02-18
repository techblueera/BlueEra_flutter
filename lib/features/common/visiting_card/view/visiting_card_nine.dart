import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/common/visiting_card/widget/share_button.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/api/model/personal_profile_details_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

class VisitingCardNine extends StatefulWidget {
  final BusinessProfileDetails? businessDetails;
  final PersonalProfileDetailsModel? personalDetails;

  const VisitingCardNine({super.key,
    this.businessDetails,
    this.personalDetails,});

  @override
  State<VisitingCardNine> createState() => _VisitingCardNineState();
}

class _VisitingCardNineState extends State<VisitingCardNine> {
  final GlobalKey _cardKey = GlobalKey();

  String? _logo;
  String? _name;
  String? _profession;
  int? _officeLandlineNumber;
  int? _officeMobileNumber;
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
      _officeMobileNumber = int.parse(_user?.contactNo??'0');
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
                image: AssetImage("assets/images/card_bg_8.png"),
                fit: BoxFit.fill,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // LEFT COLUMN: Business Identity (Dark text on light side)
                  SizedBox(
                    width: Get.width * 0.299,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
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
                            textAlign: TextAlign.center,
                            fontSize: SizeConfig.small,
                            color: AppColors.black,
                          ),

                        SizedBox(height: SizeConfig.size2),

                        if ((_profession ?? "").isNotEmpty)
                          CustomText(
                            _profession!,
                            color: AppColors.black,
                            fontSize: SizeConfig.small11,
                            fontWeight: FontWeight.w500,
                          ),

                        SizedBox(height: SizeConfig.size2),

                        if (_officeLandlineNumber != null)
                          cardRow(
                            icon: Icons.call,
                            title: _officeLandlineNumber.toString(),
                            fontSize: SizeConfig.small11,
                            fontWeight: FontWeight.w500,
                            imagePath: "assets/svg/call_icon.svg",
                          ),

                        SizedBox(height: SizeConfig.size8),

                        if ((_description ?? "").isNotEmpty)
                          CustomText(
                            textAlign: TextAlign.start,
                            _description!,
                            color: AppColors.black,
                            fontSize: SizeConfig.small11,
                            fontWeight: FontWeight.w500,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  // RIGHT COLUMN: Owner Details (White text on dark side)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 10.0, left: Get.width * 0.1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((_ownerName ?? "").isNotEmpty)
                            CustomText(
                              _ownerName!,
                              fontWeight: FontWeight.w700,
                              fontSize: SizeConfig.medium,
                              color: AppColors.white,
                            ),

                          if ((_roleInOffice ?? "").isNotEmpty)
                            CustomText(
                              _roleInOffice!,
                              color: AppColors.white,
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w500,
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

                          SizedBox(height: SizeConfig.size8),

                          if ((_email ?? "").isNotEmpty)
                            cardRow(
                              icon: Icons.email,
                              textColor: AppColors.white,
                              title: _email!,
                              fontWeight: FontWeight.w500,
                              fontSize: SizeConfig.small11,
                              imagePath: "assets/svg/email_icon.svg",
                            ),

                          SizedBox(height: SizeConfig.size8),

                          if ((_address ?? "").isNotEmpty)
                            cardRow(
                              icon: Icons.language, // Note: using website icon for URL later, current logic uses address here
                              textColor: AppColors.white,
                              title: _address!,
                              fontSize: SizeConfig.small11,
                              fontWeight: FontWeight.w500,
                              imagePath: "assets/svg/website_icon.svg",
                            ),

                          SizedBox(height: SizeConfig.size8),

                          if ((_website ?? "").isNotEmpty)
                            cardRow(
                              icon: Icons.location_on,
                              textColor: AppColors.white,
                              imagePath: "assets/svg/card_location_icon.svg",
                              fontSize: SizeConfig.small11,
                              fontWeight: FontWeight.w500,
                              title: _website!,
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
        VisitingCardShareButton(cardKey: _cardKey)
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
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            LocalAssets(
              imagePath: imagePath,
              height: 18,
              width: 18,
              imgColor: Colors.white,
            ),
            Icon(
              icon,
              color: Colors.black,
              size: 12,
            )
          ],
        ),
        SizedBox(width: 4),
        Expanded(
          child: CustomText(
            title,
            color: textColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
            textAlign: textAlign,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

}

