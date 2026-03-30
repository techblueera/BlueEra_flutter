import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/common/visiting_card/widget/share_button.dart';
import 'package:BlueEra/features/common/visiting_card/widget/visiting_cardlist_screen.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/api/model/personal_profile_details_model.dart';

class VisitingCardTwo extends StatefulWidget {
  final BusinessProfileDetails? businessDetails;
  final PersonalProfileDetailsModel? personalDetails;

  const VisitingCardTwo({super.key,
    this.businessDetails,
    this.personalDetails,
  });

  @override
  State<VisitingCardTwo> createState() => _VisitingCardTwoState();
}

class _VisitingCardTwoState extends State<VisitingCardTwo> {
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
            child: Stack(
              children: [
                Container(
                  height: 250,
                  width: Get.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [AppShadows.textFieldShadow],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: LocalAssets(
                      imagePath: AppIconAssets.visiting_bg,
                      boxFix: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                                radius: 30,
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(32),
                                    child: Image.network(
                                      _logo ?? "",
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                          Image.asset(
                                              "assets/images/be_logo.png"),
                                    ))),
                            SizedBox(height: SizeConfig.size8),
                            (_name ?? "").isEmpty
                                ? SizedBox()
                                : CustomText(
                              _name ?? "",
                              fontWeight: FontWeight.w700,
                              fontSize: SizeConfig.medium,
                              color: AppColors.black,
                            ),
                            SizedBox(height: SizeConfig.size6),
                            (_profession ?? "").isEmpty
                                ? SizedBox()
                                : CustomText(
                              _profession ?? "",
                              color: AppColors.black,
                              fontSize: SizeConfig.small11,
                              fontWeight: FontWeight.w500,
                            ),

                            SizedBox(height: SizeConfig.size6),

                            if (_officeLandlineNumber != null)
                            Widget_infoRow(
                              title: _officeLandlineNumber.toString(),
                              fontSize: SizeConfig.small11,
                              fontWeight: FontWeight.w500,
                              imagePath: "assets/svg/call_icon.svg",
                            ),
                            // Short description (optional)
                            SizedBox(height: SizeConfig.size16),

                            (_description ?? "").isEmpty
                                ? SizedBox()
                                : CustomText(
                              _description ?? "",
                              color: AppColors.black,
                              fontSize: SizeConfig.small11,
                              fontWeight: FontWeight.w500,
                              maxLines: 4,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              (_ownerName?.isEmpty ?? true)
                                  ? SizedBox()
                                  : CustomText(
                                  _ownerName ?? "",
                                fontWeight: FontWeight.w700,
                                fontSize: SizeConfig.medium,
                                color: AppColors.black,
                              ),
                             (_roleInOffice ?? "")
                                  .isEmpty
                                  ? SizedBox()
                                  : CustomText(
                               _roleInOffice ?? "",
                                color: AppColors.black,
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w500,
                              ),
                              SizedBox(height: SizeConfig.size18),
                              ((_officeMobileNumber ?? 0)
                                  .toString())
                                  .isEmpty
                                  ? SizedBox()
                                  : Widget_infoRow(
                                title: (_officeMobileNumber ?? 0)
                                    .toString(),
                                fontSize: SizeConfig.small11,
                                fontWeight: FontWeight.w500,
                                imagePath: "assets/svg/call_icon.svg",
                              ),
                              SizedBox(height: SizeConfig.size8),
                              (_email ?? "").isEmpty
                                  ? SizedBox()
                                  : Widget_infoRow(
                                title:_email ?? "",
                                fontWeight: FontWeight.w500,
                                fontSize: SizeConfig.small11,
                                imagePath: "assets/svg/email_icon.svg",
                              ),
                              SizedBox(height: SizeConfig.size8),
                              (_website ?? "").isEmpty
                                  ? SizedBox()
                                  : Widget_infoRow(
                                  title: _website ?? "",
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                  imagePath: "assets/svg/website_icon.svg"),
                              SizedBox(height: SizeConfig.size8),
                              (_address ?? "").isEmpty
                                  ? SizedBox()
                                  : Widget_infoRow(
                                imagePath:
                                "assets/svg/card_location_icon.svg",
                                fontSize: SizeConfig.small11,
                                fontWeight: FontWeight.w500,
                                title: _address ?? "",
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        VisitingCardShareButton(
          cardKey: _cardKey,
        )
      ],
    );
  }

}
