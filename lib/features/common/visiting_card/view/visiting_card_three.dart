import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/common/visiting_card/widget/share_button.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/api/model/personal_profile_details_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

class VisitingCardThree extends StatefulWidget {
  final BusinessProfileDetails? businessDetails;
  final PersonalProfileDetailsModel? personalDetails;

  const VisitingCardThree({super.key,
    this.businessDetails,
    this.personalDetails,
  });

  @override
  State<VisitingCardThree> createState() => _VisitingCardThreeState();
}

class _VisitingCardThreeState extends State<VisitingCardThree> {
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
              boxShadow: [AppShadows.textFieldShadow],
              image: const DecorationImage(
                image: AssetImage("assets/images/card_bg_2.png"),
                fit: BoxFit.fill,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 38.0, vertical: 12),
            child: Column(
              children: [
                // Header Section: Logo and Business Name
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primaryColor,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: (_logo != null && _logo!.isNotEmpty)
                            ? Image.network(
                          _logo!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset("assets/images/be_logo.png"),
                        )
                            : CustomText(
                          (_name ?? 'B')
                              .trim()
                              .split(' ')
                              .map((e) => e.isNotEmpty ? e[0] : '')
                              .take(2)
                              .join()
                              .toUpperCase(),
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((_name ?? "").isNotEmpty)
                            CustomText(
                              _name!,
                              fontWeight: FontWeight.w700,
                              fontSize: SizeConfig.medium,
                              color: AppColors.black,
                            ),
                          SizedBox(height: SizeConfig.size4),
                          if ((_profession ?? "").isNotEmpty)
                            CustomText(
                              _profession!,
                              color: AppColors.black,
                              fontSize: SizeConfig.small11,
                              fontWeight: FontWeight.w500,
                            ),
                          if (_officeLandlineNumber != null)
                            Row(
                              children: [
                                const Icon(Icons.call, color: Colors.black, size: 14),
                                const SizedBox(width: 4),
                                CustomText(
                                  _officeLandlineNumber.toString(),
                                  color: Colors.black,
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Description
                if ((_description ?? "").isNotEmpty)
                  CustomText(
                    _description!,
                    fontSize: SizeConfig.small11,
                    fontWeight: FontWeight.w500,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),

                // Owner Details Row
                Row(
                  children: [
                    if ((_ownerName ?? "").isNotEmpty)
                      CustomText(
                        _ownerName!,
                        fontWeight: FontWeight.w700,
                        fontSize: SizeConfig.medium,
                        color: AppColors.black,
                      ),
                    if ((_ownerName ?? "").isNotEmpty && (_roleInOffice ?? "").isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Container(color: Colors.black, height: 15, width: 1),
                      ),
                    if ((_roleInOffice ?? "").isNotEmpty)
                      Expanded(
                        child: CustomText(
                          _roleInOffice!,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w500,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Contact Info: Mobile and Email
                Row(
                  children: [
                    if (_officeMobileNumber != null) ...[
                      const Icon(Icons.call, size: 14),
                      const SizedBox(width: 4),
                      CustomText(_officeMobileNumber.toString(), fontSize: SizeConfig.small11),
                    ],
                    if (_officeMobileNumber != null && (_email ?? "").isNotEmpty)
                      const SizedBox(width: 10),
                    if ((_email ?? "").isNotEmpty) ...[
                      const Icon(Icons.email, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: CustomText(
                          _email!,
                          fontSize: SizeConfig.small11,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Website
                if ((_website ?? "").isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.language, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: CustomText(_website!, fontSize: SizeConfig.small11),
                      ),
                    ],
                  ),

                const SizedBox(height: 4),

                // Address
                if ((_address ?? "").isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: CustomText(
                          _address!,
                          maxLines: 2,
                          fontSize: SizeConfig.small11,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        VisitingCardShareButton(cardKey: _cardKey)
      ],
    );
  }



}



