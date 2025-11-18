import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/visiting_card_helper.dart';
import 'package:flutter/material.dart';

class VisitingCardPreview extends StatelessWidget {
  final GlobalKey cardKey = GlobalKey();

  // final VisitingCardTheme theme;
  final BusinessProfileDetails? details;

  VisitingCardPreview({required this.details});

  @override
  Widget build(BuildContext context) {
    bool _isBottomSheetOpen = false;

    return Stack(
      children: [
        RepaintBoundary(
          key: cardKey,
          child: Container(
            padding: EdgeInsets.all(SizeConfig.size16),
            decoration: BoxDecoration(
              color: Color(0xFF31475A),
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
                              backgroundImage: (details?.logo != null &&
                                      (details?.logo ?? '').isNotEmpty)
                                  ? NetworkImage(details?.logo ?? '')
                                  : null,
                              backgroundColor: Color(0xFF31475A),
                              child: (details?.logo == null ||
                                      (details?.logo ?? '').isEmpty)
                                  ? CustomText(
                                      (details?.businessName ?? 'B')
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
                        CustomText(
                          // 'BLUE (OPC) PVT LTD',
                          details?.businessName ?? "",
                          // details?.businessName ?? 'BLUE (OPC) PVT LTD',
                          fontWeight: FontWeight.w700,
                          fontSize: SizeConfig.size14,
                          color: AppColors.white,
                        ),
                        SizedBox(height: SizeConfig.size6),
                        CustomText(
                          details?.natureOfBusiness ?? 'N/A',
                          color: AppColors.white,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w400,
                        ),
                        infoRow(
                            icon: Icons.call,
                            title: (details?.businessNumber?.officeLandlineNo
                                        ?.number ??
                                    0)
                                .toString(),
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            textColor: AppColors.white),

                        SizedBox(height: SizeConfig.size12),

                        // Short description (optional)
                        CustomText(
                          details?.businessDescription ??
                              AppStrings.uniqueCustomDesigns,
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
                          CustomText(
                            details?.ownerDetails?.isNotEmpty ?? false
                                ? details?.ownerDetails?.first.name ?? ""
                                : "",
                            // details?.ownerDetails?.first.name ?? 'Manish Kumar',
                            fontWeight: FontWeight.w700,
                            fontSize: SizeConfig.size14,
                            color: AppColors.appBackgroundColor,
                          ),
                          SizedBox(height: SizeConfig.size2),
                          CustomText(
                            details?.ownerDetails?.isNotEmpty ?? false
                                ? details?.ownerDetails?.first
                                        .role_in_business ??
                                    ""
                                : "",
                            color: AppColors.appBackgroundColor,
                            fontSize: SizeConfig.small,
                          ),
                          SizedBox(height: SizeConfig.size10),
                          infoRow(
                              icon: Icons.call,
                              title: (details?.businessNumber?.officeMobNo
                                          ?.number ??
                                      0)
                                  .toString(),
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              textColor: AppColors.white),
                          // _infoRow(
                          //     Icons.phone,
                          //   (details?.businessNumber?.officeMobNo
                          //                           ?.number ??
                          //                       0)
                          //                   .toString(),

                          //     ),
                          SizedBox(height: SizeConfig.size8),

                          infoRow(
                              icon: Icons.email,
                              title: details?.ownerDetails?.isNotEmpty ?? false
                                  ? details?.ownerDetails?.first.email ?? ""
                                  : "",
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              textColor: AppColors.white),
                          SizedBox(height: SizeConfig.size8),
                          // _infoRow(
                          //     Icons.public,
                          //     details?.websiteUrl??"",
                          //     // details?.websiteUrl ?? 'www.vikash.bluehr.com',
                          //     textPrimary,
                          //     textSecondary,
                          //     iconAccent,
                          //     ellipsis: true),
                          infoRow(
                              icon: Icons.language,
                              title: details?.websiteUrl ?? "",
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              textColor: AppColors.white),
                          SizedBox(height: SizeConfig.size10),
                          infoRow(
                              icon: Icons.add_location,
                              title: details?.address ?? "",
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              textColor: AppColors.white)
                          // _infoRow(
                          //   Icons.add_location,
                          //   details?.address??"",
                          //   // details?.websiteUrl ?? 'www.vikash.bluehr.com',
                          //   textPrimary,
                          //   textSecondary,
                          //   iconAccent,
                          //   ellipsis: true),
                          // CustomText(
                          //   // "'www.vikash.bluehr.com",""
                          //   details?.address ??"",
                          //   //     '115, Road No 04 BN Ready Nagar Address abcdefgh1234567890 nmae Nagar\nHyderabad 834553',
                          //   color: textSecondary,
                          //   fontSize: SizeConfig.small,
                          // ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: InkWell(
            onTap: () async {
              if (_isBottomSheetOpen) return; // ✅ Block second tap instantly
              _isBottomSheetOpen = true; // ✅ Lock immediately

              await VisitingCardHelper()
                  .shareVisitingCard(cardKey); // Wait for sheet to close

              _isBottomSheetOpen = false; //
            },
            child: Container(
              decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.white, blurRadius: 6, spreadRadius: 2)
                  ],
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.ios_share,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
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
