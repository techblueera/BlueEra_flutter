import 'package:BlueEra/core/api/model/personal_profile_details_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/common/visiting_card/widget/share_button.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class VisitingCardOne extends StatefulWidget {
  final BusinessProfileDetails? businessDetails;
  final PersonalProfileDetailsModel? personalDetails;

  const VisitingCardOne({
    super.key,
    this.businessDetails,
    this.personalDetails,

  });

  @override
  State<VisitingCardOne> createState() => _VisitingCardOneState();
}

class _VisitingCardOneState extends State<VisitingCardOne> {
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
    if(accountTypeGlobal == AppConstants.business){
      BusinessProfileDetails? _businessDetails = widget.businessDetails;
      _logo = _businessDetails?.logo;
      _name = _businessDetails?.businessName;
      _profession = _businessDetails?.categoryDetails?.name;
      _officeLandlineNumber = _businessDetails?.businessNumber?.officeLandlineNo?.number;
      _officeMobileNumber = _businessDetails?.businessNumber?.officeMobNo?.number;
      _description = _businessDetails?.businessDescription;
      _ownerName = _businessDetails?.ownerDetails?.first.name;
      _roleInOffice = _businessDetails?.ownerDetails?.first.role_in_business;
      _website = _businessDetails?.websiteUrl;
      _email = _businessDetails?.ownerDetails?.first.email;
      _address = _businessDetails?.address;
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
            padding: EdgeInsets.all(SizeConfig.size16),
            decoration: BoxDecoration(
              color: Color(0xFF31475A),
              boxShadow: [AppShadows.textFieldShadow],
              borderRadius: BorderRadius.circular(16),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: avatar + company block
                  Expanded(
                    // flex: 11,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: (_logo != null && _logo!.isNotEmpty)
                                  ? NetworkImage(_logo ?? '')
                                  : null,
                              backgroundColor: Color(0xFF31475A),
                              child: (_logo == null ||
                                  (_logo ?? '').isEmpty)
                                  ? CustomText(
                                (_name ?? 'B')
                                    .trim()
                                    .split(' ')
                                    .map((e) => e.isNotEmpty ? e[0] : '')
                                    .take(2)
                                    .join()
                                    .toUpperCase(),
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              )
                                  : null,
                            ),
                          ],
                        ),
                        SizedBox(height: SizeConfig.size12),

                        // Company name and tagline
                        (_name ?? "").isEmpty
                            ? SizedBox()
                            : CustomText(
                          _name,
                          fontWeight: FontWeight.w700,
                          fontSize: SizeConfig.size14,
                          color: AppColors.white,
                        ),
                        SizedBox(height: SizeConfig.size6),

                        (_profession ?? "").isEmpty
                            ? SizedBox()
                            : CustomText(
                          _profession ?? AppStrings.na,
                          color: AppColors.white,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w400,
                        ),

                        if (_officeLandlineNumber != null)
                        infoRow(
                            icon: Icons.call,
                            title: _officeLandlineNumber.toString(),
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            textColor: AppColors.white),

                        SizedBox(height: SizeConfig.size12),

                        if ((_description ?? "").isNotEmpty)
                        CustomText(
                          _description ?? AppStrings.uniqueCustomDesigns,
                          color: AppColors.white,
                          fontSize: SizeConfig.small,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  VerticalDivider(
                    color: AppColors.appBackgroundColor,
                  ),

                  // Right: person and contact info
                  Expanded(
                    // flex: 10,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((_ownerName ?? "").isNotEmpty)
                          CustomText(
                            _ownerName,
                            fontWeight: FontWeight.w700,
                            fontSize: SizeConfig.size14,
                            color: AppColors.appBackgroundColor,
                          ),
                          SizedBox(height: SizeConfig.size2),
                          if ((_roleInOffice ?? "").isNotEmpty)
                          CustomText(
                            _roleInOffice,
                            color: AppColors.appBackgroundColor,
                            fontSize: SizeConfig.small,
                          ),
                          SizedBox(height: SizeConfig.size10),
                          if (_officeMobileNumber != null)
                          infoRow(
                              icon: Icons.call,
                              title: _officeMobileNumber.toString(),
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              textColor: AppColors.white),

                          SizedBox(height: SizeConfig.size8),

                          if ((_email ?? "").isNotEmpty)
                          infoRow(
                              icon: Icons.email,
                              title: _email,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              textColor: AppColors.white),
                          SizedBox(height: SizeConfig.size8),

                          if ((_website ?? "").isNotEmpty)
                          infoRow(
                              icon: Icons.language,
                              title: _website,
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              textColor: AppColors.white),
                          SizedBox(height: SizeConfig.size10),

                          if ((_address ?? "").isNotEmpty)
                          infoRow(
                              icon: Icons.add_location,
                              title: _address,
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              textColor: AppColors.white)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        VisitingCardShareButton(
           cardKey: _cardKey,
        )
      ],
    );
  }

  Widget infoRow(
      {required IconData? icon,
        required String? title,
        Color? textColor,
        double? fontSize,
        FontWeight? fontWeight,
        TextAlign? textAlign,
        Color? iconColor}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: AppColors.white,
        ),
        SizedBox(
          width: 5,
        ),
        Expanded(
            child: CustomText(
              title,
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: textColor,
              maxLines: 3,
            ))
      ],
    );
  }

}
