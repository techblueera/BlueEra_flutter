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

class VisitingCardEleven extends StatefulWidget {
  final BusinessProfileDetails? businessDetails;
  final PersonalProfileDetailsModel? personalDetails;

  const VisitingCardEleven({super.key,
    this.businessDetails,
    this.personalDetails
  });

  @override
  State<VisitingCardEleven> createState() => _VisitingCardElevenState();
}

class _VisitingCardElevenState extends State<VisitingCardEleven> {
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
              color: AppColors.white,
            ),
            child: Row(
              children: [
                // LEFT SECTION: Dark background with contact details
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black,
                    ),
                    child: Stack(
                      children: [
                        // Red Vertical Accent Line
                        Container(
                          margin: const EdgeInsets.only(left: 16),
                          decoration: BoxDecoration(color: AppColors.red),
                          width: 3,
                          height: 250,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Owner Name and Role Row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                      color: AppColors.black,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.red, width: 3)),
                                  child: const Icon(Icons.person_2, color: AppColors.white),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if ((_ownerName ?? "").isNotEmpty)
                                        CustomText(
                                          _ownerName!,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          fontWeight: FontWeight.w700,
                                          fontSize: SizeConfig.medium,
                                          color: AppColors.white,
                                        ),
                                      if ((_roleInOffice ?? "").isNotEmpty)
                                        CustomText(
                                          _roleInOffice!,
                                          color: AppColors.white,
                                          fontSize: SizeConfig.small,
                                          fontWeight: FontWeight.w500,
                                        ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Mobile Number
                            if (_officeMobileNumber != null)
                              _buildContactRow(Icons.call, _officeMobileNumber.toString(), iconSize: 16),

                            const SizedBox(height: 6),

                            // Email
                            if ((_email ?? "").isNotEmpty)
                              _buildContactRow(Icons.email, _email!, isExpanded: true),

                            const SizedBox(height: 6),

                            // Website
                            if ((_website ?? "").isNotEmpty)
                              _buildContactRow(Icons.language, _website!, iconSize: 16, isExpanded: true),

                            const SizedBox(height: 6),

                            // Address
                            if ((_address ?? "").isNotEmpty)
                              _buildContactRow(Icons.location_on, _address!, iconSize: 16, isExpanded: true, maxLines: 3),
                          ],
                        )
                      ],
                    ),
                  ),
                ),

                // RIGHT SECTION: White background with Business Branding
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(12),
                          topRight: Radius.circular(12)),
                      color: AppColors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 1,
                          offset: const Offset(-4, 0),
                        ),
                      ],
                    ),
                    margin: const EdgeInsets.only(right: 20, bottom: 20, top: 6),
                    padding: const EdgeInsets.only(left: 20, bottom: 20, top: 6, right: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey[200],
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
                        const SizedBox(height: 8),

                        if ((_name ?? "").isNotEmpty)
                          CustomText(
                            _name!,
                            fontWeight: FontWeight.w700,
                            fontSize: SizeConfig.medium,
                            color: AppColors.black,
                            textAlign: TextAlign.center,
                          ),

                        SizedBox(height: SizeConfig.size1),

                        if ((_profession ?? "").isNotEmpty)
                          CustomText(
                            _profession!,
                            color: AppColors.black,
                            fontSize: SizeConfig.small11,
                            fontWeight: FontWeight.w500,
                            textAlign: TextAlign.center,
                          ),

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
        VisitingCardShareButton(cardKey: _cardKey)
      ],
    );
  }

// Helper widget to keep the contact rows consistent
  Widget _buildContactRow(IconData icon, String text, {double iconSize = 16, bool isExpanded = false, int maxLines = 1}) {
    return Row(
      children: [
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: AppColors.black,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.red, width: 3)),
          child: Icon(icon, color: AppColors.white, size: iconSize),
        ),
        const SizedBox(width: 6),
        isExpanded
            ? Expanded(child: CustomText(text, fontSize: SizeConfig.small11, fontWeight: FontWeight.w500, color: AppColors.white, maxLines: maxLines, overflow: TextOverflow.ellipsis))
            : CustomText(text, fontSize: SizeConfig.small11, fontWeight: FontWeight.w500, color: AppColors.white),
      ],
    );
  }

}
