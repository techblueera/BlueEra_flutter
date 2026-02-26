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

class VisitingCardTen extends StatefulWidget {
  final BusinessProfileDetails? businessDetails;
  final PersonalProfileDetailsModel? personalDetails;

  const VisitingCardTen({super.key,
    this.businessDetails,
    this.personalDetails,});

  @override
  State<VisitingCardTen> createState() => _VisitingCardTenState();
}

class _VisitingCardTenState extends State<VisitingCardTen> {
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
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [AppShadows.textFieldShadow],
              image: const DecorationImage(
                image: AssetImage("assets/images/card_bg_9.png"),
                fit: BoxFit.fill,
              ),
            ),
            height: 250,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: Get.width * 0.056, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // LEFT COLUMN: Owner and Contact Info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // Rotating Green Person Icon
                              Transform.rotate(
                                angle: 0.8,
                                child: Container(
                                  height: 18,
                                  width: 18,
                                  decoration: BoxDecoration(
                                    color: const Color(0xff19A03B),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  alignment: Alignment.center,
                                  child: Transform.rotate(
                                    angle: -0.8,
                                    child: const Icon(
                                      Icons.person_2,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if ((_ownerName ?? "").isNotEmpty)
                                    CustomText(
                                      _ownerName!,
                                      fontWeight: FontWeight.w700,
                                      fontSize: SizeConfig.medium,
                                      color: AppColors.black,
                                    ),
                                  if ((_roleInOffice ?? "").isNotEmpty)
                                    CustomText(
                                      _roleInOffice!,
                                      color: AppColors.black,
                                      fontSize: SizeConfig.small,
                                      fontWeight: FontWeight.w500,
                                    ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: SizeConfig.size8),

                          if (_officeMobileNumber != null)
                            cardRow(
                              icon: Icons.call,
                              title: _officeMobileNumber.toString(),
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
                              fontSize: SizeConfig.small11,
                              imagePath: "assets/svg/email_icon.svg",
                            ),

                          SizedBox(height: SizeConfig.size12),

                          if ((_website ?? "").isNotEmpty)
                            cardRow(
                              icon: Icons.language,
                              title: _website!,
                              fontSize: SizeConfig.small11,
                              fontWeight: FontWeight.w500,
                              imagePath: "assets/svg/website_icon.svg",
                            ),

                          SizedBox(height: SizeConfig.size2),

                          if ((_address ?? "").isNotEmpty)
                            cardRow(
                              icon: Icons.location_on,
                              imagePath: "assets/svg/card_location_icon.svg",
                              fontSize: SizeConfig.small11,
                              fontWeight: FontWeight.w500,
                              title: _address!,
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 24),

                  // RIGHT COLUMN: Business Branding (Inside elevated white container)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(-4, 0),
                            ),
                            const BoxShadow(
                                color: Colors.white,
                                spreadRadius: 1,
                                blurRadius: 2,
                                offset: Offset(0, -4)),
                            const BoxShadow(
                                color: Colors.white,
                                spreadRadius: 1,
                                blurRadius: 2,
                                offset: Offset(0, 4)),
                          ],
                        ),
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
                                      Image.asset(
                                        "assets/images/be_logo.png",
                                        color: AppColors.green39,
                                      ),
                                )
                                    : Image.asset(
                                  "assets/images/be_logo.png",
                                  color: AppColors.green39,
                                ),
                              ),
                            ),
                            SizedBox(height: SizeConfig.size8),

                            if ((_name ?? "").isNotEmpty)
                              CustomText(
                                _name!,
                                fontWeight: FontWeight.w700,
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.rotate(
          angle: 0.8,
          child: Container(
            height: 18,
            width: 18,
            decoration: BoxDecoration(
              color: Color(0xff19A03B),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Transform.rotate(
              angle: -0.8,
              child: Icon(
                icon,
                color: Colors.white,
                size: 12,
              ),
            ),
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
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

}
