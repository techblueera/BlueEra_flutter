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

class VisitingCardEight extends StatefulWidget {
  final BusinessProfileDetails? businessDetails;
  final PersonalProfileDetailsModel? personalDetails;

  const VisitingCardEight({super.key,
    this.businessDetails,
    this.personalDetails,});

  @override
  State<VisitingCardEight> createState() => _VisitingCardEightState();
}

class _VisitingCardEightState extends State<VisitingCardEight> {
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
              color: const Color(0xff067EEC),
              image: const DecorationImage(
                image: AssetImage("assets/images/card_bg_7.png"),
                fit: BoxFit.fill,
              ),
            ),
            height: 250,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // TOP SECTION: Logo, Business Name, and Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
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
                        SizedBox(width: SizeConfig.size8),
                        SizedBox(
                          width: Get.width * 0.3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((_name ?? "").isNotEmpty)
                                CustomText(
                                  _name!,
                                  fontWeight: FontWeight.w700,
                                  fontSize: SizeConfig.medium,
                                  color: AppColors.white,
                                ),
                              SizedBox(height: SizeConfig.size2),
                              if ((_profession ?? "").isNotEmpty)
                                CustomText(
                                  _profession!,
                                  color: AppColors.white,
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                ),
                              SizedBox(height: SizeConfig.size6),
                              if (_officeLandlineNumber != null)
                                Row(
                                  children: [
                                    const Icon(Icons.call, size: 14, color: Colors.white),
                                    const SizedBox(width: 4),
                                    CustomText(
                                      _officeLandlineNumber.toString(),
                                      color: AppColors.white,
                                      fontSize: SizeConfig.small11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: SizeConfig.size20),
                        if ((_description ?? "").isNotEmpty)
                          Expanded(
                            child: CustomText(
                              _description!,
                              color: AppColors.white,
                              fontSize: SizeConfig.small11,
                              fontWeight: FontWeight.w500,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // DECORATIVE DIVIDER SECTION
                  const Column(
                    children: [
                      Divider(color: Color(0xff003DCC), thickness: 10, height: 2),
                      Divider(color: Colors.white, thickness: 10, height: 2),
                      Divider(color: Color(0xff003DCC), thickness: 2, height: 2),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // MIDDLE SECTION: Contact Info and Owner details
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_officeMobileNumber != null)
                                cardRow(
                                  icon: Icons.call,
                                  title: _officeMobileNumber.toString(),
                                  textColor: Colors.white,
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                  imagePath: "assets/svg/call_icon.svg",
                                ),
                              SizedBox(height: SizeConfig.size8),
                              if ((_email ?? "").isNotEmpty)
                                cardRow(
                                  icon: Icons.email,
                                  textColor: Colors.white,
                                  title: _email!,
                                  fontWeight: FontWeight.w500,
                                  fontSize: SizeConfig.small11,
                                  imagePath: "assets/svg/email_icon.svg",
                                ),
                              SizedBox(height: SizeConfig.size8),
                              if ((_website ?? "").isNotEmpty)
                                cardRow(
                                  icon: Icons.language,
                                  textColor: Colors.white,
                                  title: _website!,
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                  imagePath: "assets/svg/website_icon.svg",
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.person_2, color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((_ownerName ?? "").isNotEmpty)
                                  CustomText(
                                    _ownerName!,
                                    color: Colors.white,
                                    fontSize: SizeConfig.medium15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                if ((_roleInOffice ?? "").isNotEmpty)
                                  CustomText(
                                    _roleInOffice!,
                                    color: Colors.white,
                                    fontSize: SizeConfig.medium,
                                  )
                              ],
                            )
                          ],
                        )
                      ],
                    ),
                  ),

                  // BOTTOM SECTION: Address
                  if ((_address ?? "").isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 60, left: 20),
                      child: cardRow(
                        icon: Icons.location_on,
                        textColor: Colors.white,
                        imagePath: "assets/svg/card_location_icon.svg",
                        fontSize: SizeConfig.small11,
                        fontWeight: FontWeight.w500,
                        title: _address!,
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
        Icon(
          icon,
          color: Colors.white,
          size: 16,
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

