import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/visiting_card_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';


class VisitingCardlistScreen extends StatelessWidget {
  const VisitingCardlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    BusinessProfileDetails data = Get.arguments;
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Choose Card',
        isLeading: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SingleChildScrollView(
          child: Column(
            children: [
              InkWell(
                  onTap: () {
                    _showVisitingCardDialog(context, card: buildCard1(data));
                  },
                  child: buildCard1(data)),
              SizedBox(
                height: 20,
              ),
              InkWell(
                  onTap: () {
                    _showVisitingCardDialog(context, card: buildCard2(data));
                  },
                  child: buildCard2(data)),
              SizedBox(
                height: 20,
              ),
              InkWell(
                  onTap: () {
                    _showVisitingCardDialog(context, card: buildCard3(data));
                  },
                  child: buildCard3(data)),
              SizedBox(
                height: 20,
              ),
              InkWell(
                  onTap: () {
                    _showVisitingCardDialog(context, card: buildCard4(data));
                  },
                  child: buildCard4(data)),
              SizedBox(
                height: 20,
              ),
              InkWell(
                  onTap: () {
                    _showVisitingCardDialog(context, card: buildCard5(data));
                  },
                  child: buildCard5(data)),
              SizedBox(
                height: 20,
              ),
              InkWell(
                  onTap: () {
                    _showVisitingCardDialog(context, card: buildCard6(data));
                  },
                  child: buildCard6(data)),
              SizedBox(
                height: 20,
              ),
              InkWell(
                  onTap: () {
                    _showVisitingCardDialog(context, card: buildCard7(data));
                  },
                  child: buildCard7(data)),
              SizedBox(
                height: 20,
              ),
              InkWell(
                  onTap: () {
                    _showVisitingCardDialog(context, card: buildCard8(data));
                  },
                  child: buildCard8(data)),
              SizedBox(
                height: 20,
              ),
              InkWell(
                  onTap: () {
                    _showVisitingCardDialog(context, card: buildCard9(data));
                  },
                  child: buildCard9(data)),
              SizedBox(
                height: 20,
              ),
              InkWell(
                  onTap: () {
                    _showVisitingCardDialog(context, card: buildCard10(data));
                  },
                  child: buildCard10(data)),
              SizedBox(
                height: 20,
              ),
              InkWell(
                  onTap: () {
                    _showVisitingCardDialog(context, card: buildCard11(data));
                  },
                  child: buildCard11(data)),
            ],
          ),
        ),
      ),
    );
  }
}

Widget_infoRow(
    {required String imagePath,
    required String? title,
    Color? textColor,
    double? fontSize,
    FontWeight? fontWeight,
    TextAlign? textAlign,
    Color? iconColor}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      SvgPicture.asset(
        imagePath,
        height: 18,
        width: 18,
      ),
      SizedBox(width: 4),
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

Widget buildCard1(BusinessProfileDetails data) {
  final GlobalKey _cardKey = GlobalKey();

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
                    image: DecorationImage(
                      image: AssetImage(AppIconAssets.visiting_bg),
                      fit: BoxFit.cover,
                    ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SvgPicture.asset(
                    AppIconAssets.visiting_bg,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
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
                                    data.logo ?? "",
                                    errorBuilder: (context, error, stackTrace) =>
                                        Image.asset("assets/images/be_logo.png"),
                                  ))),
                          SizedBox(height: SizeConfig.size8),
                          (data.businessName ?? "").isEmpty
                              ? SizedBox()
                              : CustomText(
                                  data.businessName ?? "",
                                  fontWeight: FontWeight.w700,
                                  fontSize: SizeConfig.medium,
                                  color: AppColors.black,
                                ),
                          SizedBox(height: SizeConfig.size6),
                          (data.natureOfBusiness ?? "").isEmpty
                              ? SizedBox()
                              : CustomText(
                                  data.natureOfBusiness ?? "",
                                  color: AppColors.black,
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                ),

                          SizedBox(height: SizeConfig.size6),
                           Widget_infoRow(
                                  title: (data.businessNumber?.officeLandlineNo
                                              ?.number ??
                                          0)
                                      .toString(),
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                  imagePath: "assets/svg/call_icon.svg",
                                ),
                          // Short description (optional)
                          SizedBox(height: SizeConfig.size16),
                          (data.businessDescription ?? "").isEmpty
                              ? SizedBox()
                              : CustomText(
                                  data.businessDescription ?? "",
                                  color: AppColors.black,
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
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
                            (data.ownerDetails?.isNotEmpty ?? false
                                        ? data.ownerDetails?.first.name ?? ""
                                        : "")
                                    .isEmpty
                                ? SizedBox()
                                : CustomText(
                                    data.ownerDetails?.isNotEmpty ?? false
                                        ? data.ownerDetails?.first.name ?? ""
                                        : "",
                                    fontWeight: FontWeight.w700,
                                    fontSize: SizeConfig.medium,
                                    color: AppColors.black,
                                  ),
                            (data.ownerDetails?.isNotEmpty ?? false
                                        ? data.ownerDetails?.first.role_in_business ??
                                            ""
                                        : "")
                                    .isEmpty
                                ? SizedBox()
                                : CustomText(
                                    data.ownerDetails?.isNotEmpty ?? false
                                        ? data.ownerDetails?.first.role_in_business ??
                                            ""
                                        : "",
                                    color: AppColors.black,
                                    fontSize: SizeConfig.medium,
                                    fontWeight: FontWeight.w500,
                                  ),
                            SizedBox(height: SizeConfig.size18),
                            ((data.businessNumber?.officeMobNo?.number ?? 0)
                                        .toString())
                                    .isEmpty
                                ? SizedBox()
                                : Widget_infoRow(
                                    title:
                                        (data.businessNumber?.officeMobNo?.number ??
                                                0)
                                            .toString(),
                                    fontSize: SizeConfig.small11,
                                    fontWeight: FontWeight.w500,
                                    imagePath: "assets/svg/call_icon.svg",
                                  ),
                            SizedBox(height: SizeConfig.size8),
                            (data.ownerDetails?.isNotEmpty ?? false
                                        ? data.ownerDetails?.first.email ?? ""
                                        : "")
                                    .isEmpty
                                ? SizedBox()
                                : Widget_infoRow(
                                    title: data.ownerDetails?.isNotEmpty ?? false
                                        ? data.ownerDetails?.first.email ?? ""
                                        : "",
                                    fontWeight: FontWeight.w500,
                                    fontSize: SizeConfig.small11,
                                    imagePath: "assets/svg/email_icon.svg",
                                  ),
                            SizedBox(height: SizeConfig.size8),
                            (data.websiteUrl ?? "").isEmpty
                                ? SizedBox()
                                : Widget_infoRow(
                                    title: data.websiteUrl ?? "",
                                    fontSize: SizeConfig.small11,
                                    fontWeight: FontWeight.w500,
                                    imagePath: "assets/svg/website_icon.svg"),
                            SizedBox(height: SizeConfig.size8),
                            (data.address ?? "").isEmpty
                                ? SizedBox()
                                : Widget_infoRow(
                                    imagePath: "assets/svg/card_location_icon.svg",
                                    fontSize: SizeConfig.small11,
                                    fontWeight: FontWeight.w500,
                                    title: data.address ?? "",
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
      Positioned(
        bottom: 10,
        right: 10,
        child: InkWell(
          onTap: () async => await VisitingCardHelper().shareVisitingCard(_cardKey),
          child: Container(
            decoration: BoxDecoration(
                color: AppColors.primaryColor,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.white,
                      blurRadius: 6,
                      spreadRadius: 2
                  )
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

Widget buildCard2(BusinessProfileDetails data) {
  final GlobalKey _cardKey = GlobalKey();
  return Stack(
    children: [
      RepaintBoundary(
        key: _cardKey,
        child: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("assets/images/card_bg_2.png"),
                    fit: BoxFit.fill)),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                        radius: 30,
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Image.network(
                              data.logo ?? "",
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset("assets/images/be_logo.png"),
                            ))),
                    SizedBox(
                      width: 16,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        (data.businessName ?? "").isEmpty
                            ? SizedBox()
                            : CustomText(
                                data.businessName ?? "",
                                fontWeight: FontWeight.w700,
                                fontSize: SizeConfig.medium,
                                color: AppColors.black,
                              ),
                        SizedBox(height: SizeConfig.size6),
                        (data.natureOfBusiness ?? "").isEmpty
                            ? SizedBox()
                            : CustomText(
                                data.natureOfBusiness ?? "",
                                color: AppColors.black,
                                fontSize: SizeConfig.small11,
                                fontWeight: FontWeight.w500,
                              ),
                        ((data.businessNumber?.officeLandlineNo?.number ?? 0)
                                    .toString())
                                .isEmpty
                            ? SizedBox()
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.call,
                                    color: Colors.black,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  CustomText(
                                    (data.businessNumber?.officeLandlineNo?.number ??
                                            0)
                                        .toString(),
                                    color: Colors.black,
                                    fontSize: SizeConfig.small11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ],
                              )
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: 8,
                ),
                (data.businessDescription ?? "").isEmpty
                    ? SizedBox()
                    : CustomText(
                        data.businessDescription ?? "",
                        fontSize: SizeConfig.small11,
                        fontWeight: FontWeight.w500,
                      ),
                SizedBox(
                  height: 8,
                ),
                Row(
                  children: [
                    (data.ownerDetails?.isNotEmpty ?? false
                                ? data.ownerDetails?.first.name ?? ""
                                : "")
                            .isEmpty
                        ? SizedBox()
                        : CustomText(
                            data.ownerDetails?.isNotEmpty ?? false
                                ? data.ownerDetails?.first.name ?? ""
                                : "",
                            // details?.businessName ?? 'BLUE (OPC) PVT LTD',
                            fontWeight: FontWeight.w700,
                            fontSize: SizeConfig.medium,
                            color: AppColors.black,
                          ),
                    SizedBox(
                      width: 8,
                    ),
                    Container(
                      decoration: BoxDecoration(color: Colors.black),
                      height: 20,
                      width: 1,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    (data.ownerDetails?.isNotEmpty ?? false
                                ? data.ownerDetails?.first.role_in_business ?? ""
                                : "")
                            .isEmpty
                        ? SizedBox()
                        : CustomText(
                            data.ownerDetails?.isNotEmpty ?? false
                                ? data.ownerDetails?.first.role_in_business ?? ""
                                : "",
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w500,
                          ),
                  ],
                ),
                SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ((data.businessNumber?.officeMobNo?.number ?? 0).toString())
                            .isEmpty
                        ? SizedBox()
                        : Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.call,
                                  size: 16,
                                ),
                                SizedBox(
                                  width: 4,
                                ),
                                Expanded(
                                  child: CustomText(
                                    (data.businessNumber?.officeMobNo?.number ?? 0)
                                        .toString(),
                                    fontSize: SizeConfig.small11,
                                  ),
                                )
                              ],
                            ),
                          ),
                    SizedBox(
                      width: 8,
                    ),
                    (data.ownerDetails?.isNotEmpty ?? false
                                ? data.ownerDetails?.first.email ?? ""
                                : "")
                            .isEmpty
                        ? SizedBox()
                        : Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.email,
                                  size: 16,
                                ),
                                SizedBox(
                                  width: 4,
                                ),
                                Expanded(
                                  child: CustomText(
                                    data.ownerDetails?.isNotEmpty ?? false
                                        ? data.ownerDetails?.first.email ?? ""
                                        : "",
                                    fontSize: SizeConfig.small11,
                                  ),
                                )
                              ],
                            ),
                          ),
                    SizedBox(
                      width: 8,
                    ),
                  ],
                ),
                SizedBox(
                  height: 8,
                ),
                (data.websiteUrl ?? "").isEmpty
                    ? SizedBox()
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.language,
                            size: 16,
                          ),
                          SizedBox(
                            width: 4,
                          ),
                          Expanded(
                            child: CustomText(
                              data.websiteUrl ?? "",
                              fontSize: SizeConfig.small11,
                            ),
                          )
                        ],
                      ),
                SizedBox(
                  height: 8,
                ),
                (data.address ?? "").isEmpty
                    ? SizedBox()
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                          ),
                          SizedBox(
                            width: 4,
                          ),
                          Expanded(
                            child: CustomText(
                              data.address ?? "",
                              maxLines: 2,
                              fontSize: SizeConfig.small11,
                            ),
                          )
                        ],
                      ),
                SizedBox(
                  width: 8,
                ),
              ],
            )),
      ),
      Positioned(
        bottom: 10,
        right: 10,
        child: InkWell(
          onTap: () async => await VisitingCardHelper().shareVisitingCard(_cardKey),
          child: Container(
            decoration: BoxDecoration(
                color: AppColors.primaryColor,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.white,
                      blurRadius: 6,
                      spreadRadius: 2
                  )
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

Widget buildCard3(BusinessProfileDetails data) {
  final GlobalKey _cardKey = GlobalKey();
  Widget card3Row(
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
            SvgPicture.asset(
              imagePath,
              height: 18,
              width: 18,
              color: Colors.black,
            ),
            Icon(
              icon,
              color: Colors.white,
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
          ),
        ),
      ],
    );
  }

  return Stack(
    children: [
      RepaintBoundary(
        key: _cardKey,
        child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                    image: AssetImage("assets/images/card_bg_3.jpeg"),
                    fit: BoxFit.fill)),
            height: 280,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
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
                                  data.logo ?? "",
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset("assets/images/be_logo.png"),
                                ))),
                        SizedBox(height: SizeConfig.size8),
                        (data.businessName ?? "").isEmpty
                            ? SizedBox()
                            : CustomText(
                                data.businessName ?? "",
                                fontWeight: FontWeight.w700,
                                fontSize: SizeConfig.medium,
                                color: AppColors.black,
                              ),
                        SizedBox(height: SizeConfig.size2),
                        (data.natureOfBusiness ?? "").isEmpty
                            ? SizedBox()
                            : CustomText(
                                data.natureOfBusiness ?? "",
                                color: AppColors.black,
                                fontSize: SizeConfig.small11,
                                fontWeight: FontWeight.w500,
                              ),
                        SizedBox(height: SizeConfig.size2),
                        ((data.businessNumber?.officeLandlineNo?.number ?? 0)
                                    .toString())
                                .isEmpty
                            ? SizedBox()
                            : card3Row(
                                icon: Icons.call,
                                title:
                                    (data.businessNumber?.officeLandlineNo?.number ??
                                            0)
                                        .toString(),
                                fontSize: SizeConfig.small11,
                                fontWeight: FontWeight.w500,
                                imagePath: "assets/svg/call_icon.svg",
                              ),
                        SizedBox(height: SizeConfig.size8),
                        (data.businessDescription ?? "").isEmpty
                            ? SizedBox()
                            : CustomText(
                                data.businessDescription ?? "",
                                color: AppColors.black,
                                fontSize: SizeConfig.small11,
                                fontWeight: FontWeight.w500,
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
                          (data.ownerDetails?.isNotEmpty ?? false
                                      ? data.ownerDetails?.first.name ?? ""
                                      : "")
                                  .isEmpty
                              ? SizedBox()
                              : CustomText(
                                  data.ownerDetails?.isNotEmpty ?? false
                                      ? data.ownerDetails?.first.name ?? ""
                                      : "",
                                  fontWeight: FontWeight.w700,
                                  fontSize: SizeConfig.medium,
                                  color: AppColors.black,
                                ),
                          (data.ownerDetails?.isNotEmpty ?? false
                                      ? data.ownerDetails?.first.role_in_business ??
                                          ""
                                      : "")
                                  .isEmpty
                              ? SizedBox()
                              : CustomText(
                                  data.ownerDetails?.isNotEmpty ?? false
                                      ? data.ownerDetails?.first.role_in_business ??
                                          ""
                                      : "",
                                  color: AppColors.black,
                                  fontSize: SizeConfig.medium,
                                  fontWeight: FontWeight.w500,
                                ),
                          SizedBox(height: SizeConfig.size18),
                          ((data.businessNumber?.officeMobNo?.number ?? 0).toString())
                                  .isEmpty
                              ? SizedBox()
                              : card3Row(
                                  icon: Icons.call,
                                  title:
                                      (data.businessNumber?.officeMobNo?.number ?? 0)
                                          .toString(),
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                  imagePath: "assets/svg/call_icon.svg",
                                ),
                          SizedBox(height: SizeConfig.size8),
                          (data.ownerDetails?.isNotEmpty ?? false
                                      ? data.ownerDetails?.first.email ?? ""
                                      : "")
                                  .isEmpty
                              ? SizedBox()
                              : card3Row(
                                  icon: Icons.email,
                                  title: data.ownerDetails?.isNotEmpty ?? false
                                      ? data.ownerDetails?.first.email ?? ""
                                      : "",
                                  fontWeight: FontWeight.w500,
                                  fontSize: SizeConfig.small11,
                                  imagePath: "assets/svg/email_icon.svg",
                                ),
                          SizedBox(height: SizeConfig.size8),
                          (data.websiteUrl ?? "").isEmpty
                              ? SizedBox()
                              : card3Row(
                                  icon: Icons.language,
                                  title: data.websiteUrl ?? "",
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                  imagePath: "assets/svg/website_icon.svg"),
                          SizedBox(height: SizeConfig.size8),
                          (data.address ?? "").isEmpty
                              ? SizedBox()
                              : card3Row(
                                  icon: Icons.location_on,
                                  imagePath: "assets/svg/card_location_icon.svg",
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                  title: data.address ?? "",
                                ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            )),
      ),
      Positioned(
        bottom: 10,
        right: 10,
        child: InkWell(
          onTap: () async => await VisitingCardHelper().shareVisitingCard(_cardKey),
          child: Container(
            decoration: BoxDecoration(
                color: AppColors.primaryColor,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.white,
                      blurRadius: 6,
                      spreadRadius: 2
                  )
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

Widget buildCard4(BusinessProfileDetails data) {
  final GlobalKey _cardKey = GlobalKey();
  Widget card4Row(
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
            color: Colors.yellow,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: Colors.white,
            size: 12,
          ),
        ),
        SizedBox(width: 4),
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

  return Stack(
    children: [
      RepaintBoundary(
        key: _cardKey,
        child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                    image: AssetImage("assets/images/card_bg_4.png"),
                    fit: BoxFit.fill)),
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 20.0, right: 20, top: 12, bottom: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                            radius: 30,
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: Image.network(
                                  data.logo ?? "",
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset("assets/images/be_logo.png"),
                                ))),
                        SizedBox(height: SizeConfig.size8),
                        (data.businessName ?? "").isEmpty
                            ? SizedBox()
                            : CustomText(
                                data.businessName ?? "",
                                fontWeight: FontWeight.w700,
                                fontSize: SizeConfig.medium,
                                color: AppColors.black,
                              ),
                        SizedBox(height: SizeConfig.size2),
                        (data.natureOfBusiness ?? "").isEmpty
                            ? SizedBox()
                            : CustomText(
                                data.natureOfBusiness ?? "",
                                color: AppColors.black,
                                fontSize: SizeConfig.small11,
                                fontWeight: FontWeight.w500,
                              ),
                        SizedBox(height: SizeConfig.size2),
                        ((data.businessNumber?.officeLandlineNo?.number ?? 0)
                                    .toString())
                                .isEmpty
                            ? SizedBox()
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.call,
                                    size: 16,
                                  ),
                                  SizedBox(
                                    width: 4,
                                  ),
                                  CustomText(
                                    (data.businessNumber?.officeLandlineNo?.number ??
                                            0)
                                        .toString(),
                                    color: AppColors.black,
                                    fontSize: SizeConfig.small11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ],
                              ),
                        SizedBox(height: SizeConfig.size8),
                        (data.businessDescription ?? "").isEmpty
                            ? SizedBox()
                            : CustomText(
                                data.businessDescription ?? "",
                                color: AppColors.black,
                                fontSize: SizeConfig.small11,
                                fontWeight: FontWeight.w500,
                                textAlign: TextAlign.center,
                              ),
                      ],
                    ),
                  ),
                  SizedBox(width: 24),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 32,
                                child: Icon(
                                  Icons.person_2,
                                  size: 32,
                                  color: Colors.yellow,
                                ),
                              ),
                              SizedBox(
                                width: 4,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  (data.ownerDetails?.isNotEmpty ?? false
                                              ? data.ownerDetails?.first.name ?? ""
                                              : "")
                                          .isEmpty
                                      ? SizedBox()
                                      : CustomText(
                                          data.ownerDetails?.isNotEmpty ?? false
                                              ? data.ownerDetails?.first.name ?? ""
                                              : "",
                                          fontWeight: FontWeight.w700,
                                          fontSize: SizeConfig.medium,
                                          color: AppColors.black,
                                        ),
                                  (data.ownerDetails?.isNotEmpty ?? false
                                              ? data.ownerDetails?.first
                                                      .role_in_business ??
                                                  ""
                                              : "")
                                          .isEmpty
                                      ? SizedBox()
                                      : CustomText(
                                          data.ownerDetails?.isNotEmpty ?? false
                                              ? data.ownerDetails?.first
                                                      .role_in_business ??
                                                  ""
                                              : "",
                                          color: AppColors.black,
                                          fontSize: SizeConfig.small,
                                          fontWeight: FontWeight.w500,
                                        ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: SizeConfig.size18),
                          ((data.businessNumber?.officeMobNo?.number ?? 0).toString())
                                  .isEmpty
                              ? SizedBox()
                              : card4Row(
                                  icon: Icons.call,
                                  title:
                                      (data.businessNumber?.officeMobNo?.number ?? 0)
                                          .toString(),
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                  imagePath: "assets/svg/call_icon.svg",
                                ),
                          SizedBox(height: SizeConfig.size8),
                          (data.ownerDetails?.isNotEmpty ?? false
                                      ? data.ownerDetails?.first.email ?? ""
                                      : "")
                                  .isEmpty
                              ? SizedBox()
                              : card4Row(
                                  icon: Icons.email,
                                  title: data.ownerDetails?.isNotEmpty ?? false
                                      ? data.ownerDetails?.first.email ?? ""
                                      : "",
                                  fontWeight: FontWeight.w500,
                                  fontSize: SizeConfig.small11,
                                  imagePath: "assets/svg/email_icon.svg",
                                ),
                          SizedBox(height: SizeConfig.size8),
                          (data.websiteUrl ?? "").isEmpty
                              ? SizedBox()
                              : card4Row(
                                  icon: Icons.language,
                                  title: data.websiteUrl ?? "",
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                  imagePath: "assets/svg/website_icon.svg"),
                          SizedBox(height: SizeConfig.size8),
                          (data.address ?? "").isEmpty
                              ? SizedBox()
                              : card4Row(
                                  icon: Icons.location_on,
                                  imagePath: "assets/svg/card_location_icon.svg",
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                  title: data.address ?? ""),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            )),
      ),
      Positioned(
        bottom: 10,
        right: 10,
        child: InkWell(
          onTap: () async => await VisitingCardHelper().shareVisitingCard(_cardKey),
          child: Container(
            decoration: BoxDecoration(
                color: AppColors.primaryColor,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.white,
                      blurRadius: 6,
                      spreadRadius: 2
                  )
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

Widget buildCard5(BusinessProfileDetails data) {
  final GlobalKey _cardKey = GlobalKey();
  Widget card5Row(
      {required IconData icon,
      required String imagePath,
      required String? title,
      Color? textColor,
      double? fontSize,
      FontWeight? fontWeight,
      TextAlign? textAlign,
      Color? iconColor}) {
    return  Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SvgPicture.asset(
              imagePath,
              height: 22,
              width: 22,
              color: Color(0xff184797),
            ),
            Icon(
              icon,
              color: Colors.white,
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
          ),
        ),
      ],
    );
  }

  return Stack(
    children: [
      RepaintBoundary(
        key: _cardKey,
        child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                    image: AssetImage("assets/images/card_bg_5.png"),
                    fit: BoxFit.fill)),
            // height: 280,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12),
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
                                  data.logo ?? "",
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset("assets/images/be_logo.png"),
                                ))),
                        SizedBox(height: SizeConfig.size8),
                        (data.businessName ?? "").isEmpty
                            ? SizedBox()
                            : CustomText(
                                data.businessName ?? "",
                                fontWeight: FontWeight.w700,
                                fontSize: SizeConfig.medium,
                                color: AppColors.white,
                              ),
                        SizedBox(height: SizeConfig.size2),
                        (data.natureOfBusiness ?? "").isEmpty
                            ? SizedBox()
                            : CustomText(
                                data.natureOfBusiness ?? "",
                                color: AppColors.white,
                                fontSize: SizeConfig.small11,
                                fontWeight: FontWeight.w500,
                              ),
                        SizedBox(height: SizeConfig.size2),
                        ((data.businessNumber?.officeLandlineNo?.number ?? 0)
                                    .toString())
                                .isEmpty
                            ? SizedBox()
                            : card5Row(
                                textColor: AppColors.white,
                                icon: Icons.call,
                                title:
                                    (data.businessNumber?.officeLandlineNo?.number ??
                                            0)
                                        .toString(),
                                fontSize: SizeConfig.small11,
                                fontWeight: FontWeight.w500,
                                imagePath: "assets/svg/call_icon.svg",
                              ),
                        SizedBox(height: SizeConfig.size2),
                        (data.businessDescription ?? "").isEmpty
                            ? SizedBox()
                            : CustomText(
                                data.businessDescription ?? "",
                                color: AppColors.white,
                                fontSize: SizeConfig.small11,
                                fontWeight: FontWeight.w500,
                              ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          (data.ownerDetails?.isNotEmpty ?? false
                                      ? data.ownerDetails?.first.name ?? ""
                                      : "")
                                  .isEmpty
                              ? SizedBox()
                              : CustomText(
                                  data.ownerDetails?.isNotEmpty ?? false
                                      ? data.ownerDetails?.first.name ?? ""
                                      : "",
                                  fontWeight: FontWeight.w700,
                                  fontSize: SizeConfig.medium,
                                  color: AppColors.white,
                                ),
                          (data.ownerDetails?.isNotEmpty ?? false
                                      ? data.ownerDetails?.first.role_in_business ??
                                          ""
                                      : "")
                                  .isEmpty
                              ? SizedBox()
                              : CustomText(
                                  data.ownerDetails?.isNotEmpty ?? false
                                      ? data.ownerDetails?.first.role_in_business ??
                                          ""
                                      : "",
                                  color: AppColors.white,
                                  fontSize: SizeConfig.medium,
                                  fontWeight: FontWeight.w500,
                                ),
                          SizedBox(height: SizeConfig.size18),
                          ((data.businessNumber?.officeMobNo?.number ?? 0).toString())
                                  .isEmpty
                              ? SizedBox()
                              : card5Row(
                                  icon: Icons.call,
                                  textColor: AppColors.white,
                                  title:
                                      (data.businessNumber?.officeMobNo?.number ?? 0)
                                          .toString(),
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                  imagePath: "assets/svg/call_icon.svg",
                                ),
                          SizedBox(height: SizeConfig.size8),
                          (data.ownerDetails?.isNotEmpty ?? false
                                      ? data.ownerDetails?.first.email ?? ""
                                      : "")
                                  .isEmpty
                              ? SizedBox()
                              : card5Row(
                                  icon: Icons.email,
                                  textColor: AppColors.white,
                                  title: data.ownerDetails?.isNotEmpty ?? false
                                      ? data.ownerDetails?.first.email ?? ""
                                      : "",
                                  fontWeight: FontWeight.w500,
                                  fontSize: SizeConfig.small11,
                                  imagePath: "assets/svg/email_icon.svg",
                                ),
                          SizedBox(height: SizeConfig.size8),
                          (data.websiteUrl ?? "").isEmpty
                              ? SizedBox()
                              : card5Row(
                                  icon: Icons.language,
                                  title: data.websiteUrl ?? "",
                                  textColor: AppColors.white,
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                  imagePath: "assets/svg/website_icon.svg"),
                          SizedBox(height: SizeConfig.size8),
                          (data.address ?? "").isEmpty
                              ? SizedBox()
                              : card5Row(
                                  icon: Icons.location_on,
                                  textColor: AppColors.white,
                                  imagePath: "assets/svg/card_location_icon.svg",
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                  title: data.address ?? ""),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            )),
      ),
      Positioned(
        bottom: 10,
        right: 10,
        child: InkWell(
          onTap: () async => await VisitingCardHelper().shareVisitingCard(_cardKey),
          child: Container(
            decoration: BoxDecoration(
                color: AppColors.primaryColor,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.white,
                      blurRadius: 6,
                      spreadRadius: 2
                  )
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

Widget buildCard6(BusinessProfileDetails data) {
  final GlobalKey _cardKey = GlobalKey();

  Widget card6Row(
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
            color: Color(0xffFF880D),
            borderRadius: BorderRadius.circular(4),
          ),
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

  return Stack(
    children: [
      RepaintBoundary(
        key: _cardKey,
        child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                    image: AssetImage("assets/images/card_bg_6.png"),
                    fit: BoxFit.fill)),
            // height: 280,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: Get.width * 0.36,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                            radius: 30,
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: Image.network(
                                  data.logo ?? "",
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset("assets/images/be_logo.png"),
                                ))),
                        SizedBox(height: SizeConfig.size8),
                        (data.businessName ?? "").isEmpty
                            ? SizedBox()
                            : CustomText(
                                data.businessName ?? "",
                                textAlign: TextAlign.center,
                                fontWeight: FontWeight.w700,
                                fontSize: SizeConfig.medium,
                                color: AppColors.white,
                              ),
                        SizedBox(height: SizeConfig.size2),
                        (data.natureOfBusiness ?? "").isEmpty
                            ? SizedBox()
                            : CustomText(
                                data.natureOfBusiness ?? "",
                                color: AppColors.white,
                                fontSize: SizeConfig.small11,
                                fontWeight: FontWeight.w500,
                              ),
                        SizedBox(height: SizeConfig.size6),
                        ((data.businessNumber?.officeLandlineNo?.number ?? 0)
                                    .toString())
                                .isEmpty
                            ? SizedBox()
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.call,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(
                                    width: 4,
                                  ),
                                  CustomText(
                                    (data.businessNumber?.officeLandlineNo?.number ??
                                            0)
                                        .toString(),
                                    color: AppColors.white,
                                    fontSize: SizeConfig.small11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ],
                              ),
                        SizedBox(height: SizeConfig.size8),
                        (data.businessDescription ?? "").isEmpty
                            ? SizedBox()
                            : CustomText(
                                data.businessDescription ?? "",
                                color: AppColors.white,
                                fontSize: SizeConfig.small11,
                                fontWeight: FontWeight.w500,
                                textAlign: TextAlign.center,
                              ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
                            height: 50,
                            width: Get.width,
                            decoration: BoxDecoration(
                              color: Color(0xffFF880D),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                (data.ownerDetails?.isNotEmpty ?? false
                                            ? data.ownerDetails?.first.name ?? ""
                                            : "")
                                        .isEmpty
                                    ? SizedBox()
                                    : CustomText(
                                        data.ownerDetails?.isNotEmpty ?? false
                                            ? data.ownerDetails?.first.name ?? ""
                                            : "",
                                        fontWeight: FontWeight.w700,
                                        fontSize: SizeConfig.medium,
                                        color: AppColors.white,
                                      ),
                                (data.ownerDetails?.isNotEmpty ?? false
                                            ? data.ownerDetails?.first
                                                    .role_in_business ??
                                                ""
                                            : "")
                                        .isEmpty
                                    ? SizedBox()
                                    : CustomText(
                                        data.ownerDetails?.isNotEmpty ?? false
                                            ? data.ownerDetails?.first
                                                    .role_in_business ??
                                                ""
                                            : "",
                                        color: AppColors.white,
                                        fontSize: SizeConfig.small,
                                        fontWeight: FontWeight.w500,
                                      ),
                              ],
                            ),
                          ),
                          SizedBox(height: SizeConfig.size24),
                          ((data.businessNumber?.officeMobNo?.number ?? 0).toString())
                                  .isEmpty
                              ? SizedBox()
                              : card6Row(
                                  icon: Icons.call,
                                  title:
                                      (data.businessNumber?.officeMobNo?.number ?? 0)
                                          .toString(),
                                  textColor: Colors.white,
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                  imagePath: "assets/svg/call_icon.svg",
                                ),
                          SizedBox(height: SizeConfig.size8),
                          (data.ownerDetails?.isNotEmpty ?? false
                                      ? data.ownerDetails?.first.email ?? ""
                                      : "")
                                  .isEmpty
                              ? SizedBox()
                              : card6Row(
                                  icon: Icons.email,
                                  textColor: Colors.white,
                                  title: data.ownerDetails?.isNotEmpty ?? false
                                      ? data.ownerDetails?.first.email ?? ""
                                      : "",
                                  fontWeight: FontWeight.w500,
                                  fontSize: SizeConfig.small11,
                                  imagePath: "assets/svg/email_icon.svg",
                                ),
                          SizedBox(height: SizeConfig.size8),
                          (data.websiteUrl ?? "").isEmpty
                              ? SizedBox()
                              : card6Row(
                                  icon: Icons.language,
                                  textColor: Colors.white,
                                  title: data.websiteUrl ?? "",
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                  imagePath: "assets/svg/website_icon.svg"),
                          SizedBox(height: SizeConfig.size8),
                          (data.address ?? "").isEmpty
                              ? SizedBox()
                              : card6Row(
                                  icon: Icons.location_on,
                                  textColor: Colors.white,
                                  imagePath: "assets/svg/card_location_icon.svg",
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                  title: data.address ?? ""),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            )),
      ),
      Positioned(
        bottom: 10,
        right: 10,
        child: InkWell(
          onTap: () async => await VisitingCardHelper().shareVisitingCard(_cardKey),
          child: Container(
            decoration: BoxDecoration(
                color: AppColors.primaryColor,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.white,
                      blurRadius: 6,
                      spreadRadius: 2
                  )
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

Widget buildCard7(BusinessProfileDetails data) {
  final GlobalKey _cardKey = GlobalKey();
  Widget card7Row(
      {required IconData icon,
      required String imagePath,
      required String? title,
      Color? textColor,
      double? fontSize,
      FontWeight? fontWeight,
      TextAlign? textAlign,
      Color? iconColor}) {
    return  Row(
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
          ),
        ),
      ],
    );
  }

  return Stack(
    children: [
      RepaintBoundary(
        key: _cardKey,
        child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Color(0xff067EEC),
                image: DecorationImage(
                    image: AssetImage("assets/images/card_bg_7.png"),
                    fit: BoxFit.fill)),
            // height: 280,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                            radius: 30,
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: Image.network(
                                  data.logo ?? "",
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset("assets/images/be_logo.png"),
                                ))),
                        SizedBox(width: SizeConfig.size8),
                        SizedBox(
                          width: Get.width * 0.3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              (data.businessName ?? "").isEmpty
                                  ? SizedBox()
                                  : CustomText(
                                      data.businessName ?? "",
                                      textAlign: TextAlign.center,
                                      fontWeight: FontWeight.w700,
                                      fontSize: SizeConfig.medium,
                                      color: AppColors.white,
                                    ),
                              SizedBox(height: SizeConfig.size2),
                              (data.natureOfBusiness ?? "").isEmpty
                                  ? SizedBox()
                                  : CustomText(
                                      data.natureOfBusiness ?? "",
                                      color: AppColors.white,
                                      fontSize: SizeConfig.small11,
                                      fontWeight: FontWeight.w500,
                                    ),
                              SizedBox(height: SizeConfig.size6),
                              ((data.businessNumber?.officeLandlineNo?.number ?? 0)
                                          .toString())
                                      .isEmpty
                                  ? SizedBox()
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.call,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        SizedBox(
                                          width: 4,
                                        ),
                                        CustomText(
                                          (data.businessNumber?.officeLandlineNo
                                                      ?.number ??
                                                  0)
                                              .toString(),
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
                        (data.businessDescription ?? "").isEmpty
                            ? SizedBox()
                            : Expanded(
                                child: CustomText(
                                  data.businessDescription ?? "",
                                  color: AppColors.white,
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Divider(
                    color: Color(0xff003DCC),
                    thickness: 10,
                    height: 2,
                  ),
                  Divider(
                    color: Colors.white,
                    thickness: 10,
                    height: 2,
                  ),
                  Divider(
                    color: Color(0xff003DCC),
                    thickness: 2,
                    height: 2,
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ((data.businessNumber?.officeMobNo?.number ?? 0)
                                          .toString())
                                      .isEmpty
                                  ? SizedBox()
                                  : card7Row(
                                      icon: Icons.call,
                                      title:
                                          (data.businessNumber?.officeMobNo?.number ??
                                                  0)
                                              .toString(),
                                      textColor: Colors.white,
                                      fontSize: SizeConfig.small11,
                                      fontWeight: FontWeight.w500,
                                      imagePath: "assets/svg/call_icon.svg",
                                    ),
                              SizedBox(height: SizeConfig.size8),
                              (data.ownerDetails?.isNotEmpty ?? false
                                          ? data.ownerDetails?.first.email ?? ""
                                          : "")
                                      .isEmpty
                                  ? SizedBox()
                                  : card7Row(
                                      icon: Icons.email,
                                      textColor: Colors.white,
                                      title: data.ownerDetails?.isNotEmpty ?? false
                                          ? data.ownerDetails?.first.email ?? ""
                                          : "",
                                      fontWeight: FontWeight.w500,
                                      fontSize: SizeConfig.small11,
                                      imagePath: "assets/svg/email_icon.svg",
                                    ),
                              SizedBox(height: SizeConfig.size8),
                              (data.websiteUrl ?? "").isEmpty
                                  ? SizedBox()
                                  : card7Row(
                                      icon: Icons.language,
                                      textColor: Colors.white,
                                      title: data.websiteUrl ?? "",
                                      fontSize: SizeConfig.small11,
                                      fontWeight: FontWeight.w500,
                                      imagePath: "assets/svg/website_icon.svg"),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 12,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.person_2,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(
                              width: 12,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                (data.ownerDetails?.isNotEmpty ?? false
                                            ? data.ownerDetails?.first.name ?? ""
                                            : "")
                                        .isEmpty
                                    ? SizedBox()
                                    : CustomText(
                                        data.ownerDetails?.isNotEmpty ?? false
                                            ? data.ownerDetails?.first.name ?? ""
                                            : "",
                                        color: Colors.white,
                                        fontSize: SizeConfig.medium15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                (data.ownerDetails?.isNotEmpty ?? false
                                            ? data.ownerDetails?.first
                                                    .role_in_business ??
                                                ""
                                            : "")
                                        .isEmpty
                                    ? SizedBox()
                                    : CustomText(
                                        data.ownerDetails?.isNotEmpty ?? false
                                            ? data.ownerDetails?.first
                                                    .role_in_business ??
                                                ""
                                            : "",
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
                  SizedBox(height: SizeConfig.size8),
                  (data.address ?? "").isEmpty
                      ? SizedBox()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: card7Row(
                              icon: Icons.location_on,
                              textColor: Colors.white,
                              imagePath: "assets/svg/card_location_icon.svg",
                              fontSize: SizeConfig.small11,
                              fontWeight: FontWeight.w500,
                              title: data.address ?? ""),
                        ),
                ],
              ),
            )),
      ),
      Positioned(
        bottom: 10,
        right: 10,
        child: InkWell(
          onTap: () async => await VisitingCardHelper().shareVisitingCard(_cardKey),
          child: Container(
            decoration: BoxDecoration(
                color: AppColors.primaryColor,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.white,
                      blurRadius: 6,
                      spreadRadius: 2
                  )
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

Widget buildCard8(BusinessProfileDetails data) {
  final GlobalKey _cardKey = GlobalKey();
  Widget card8Row(
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
            SvgPicture.asset(
              imagePath,
              height: 18,
              width: 18,
              color: Colors.white,
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
          ),
        ),
      ],
    );
  }

  return Stack(
    children: [
      RepaintBoundary(
        key: _cardKey,
        child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                    image: AssetImage("assets/images/card_bg_8.png"),
                    fit: BoxFit.fill)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: Get.width * 0.299,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                            radius: 30,
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: Image.network(
                                  data.logo ?? "",
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset("assets/images/be_logo.png"),
                                ))),
                        SizedBox(height: SizeConfig.size8),
                        (data.businessName ?? "").isEmpty
                            ? SizedBox()
                            : CustomText(
                                data.businessName ?? "",
                                fontWeight: FontWeight.w700,
                                textAlign: TextAlign.center,
                                fontSize: SizeConfig.small,
                                color: AppColors.black,
                              ),
                        SizedBox(height: SizeConfig.size2),
                        (data.natureOfBusiness ?? "").isEmpty
                            ? SizedBox()
                            : CustomText(
                                data.natureOfBusiness ?? "",
                                color: AppColors.black,
                                fontSize: SizeConfig.small11,
                                fontWeight: FontWeight.w500,
                              ),
                        SizedBox(height: SizeConfig.size2),
                        ((data.businessNumber?.officeLandlineNo?.number ?? 0)
                                    .toString())
                                .isEmpty
                            ? SizedBox()
                            : card8Row(
                                icon: Icons.call,
                                title:
                                    (data.businessNumber?.officeLandlineNo?.number ??
                                            0)
                                        .toString(),
                                fontSize: SizeConfig.small11,
                                fontWeight: FontWeight.w500,
                                imagePath: "assets/svg/call_icon.svg",
                              ),
                        SizedBox(height: SizeConfig.size8),
                        (data.businessDescription ?? "").isEmpty
                            ? SizedBox()
                            : CustomText(
                                textAlign: TextAlign.start,
                                data.businessDescription ?? "",
                                color: AppColors.black,
                                fontSize: SizeConfig.small11,
                                fontWeight: FontWeight.w500,
                              ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Expanded(
                      child: Padding(
                    padding: EdgeInsets.only(top: 10.0, left: Get.width * 0.1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        (data.ownerDetails?.isNotEmpty ?? false
                                    ? data.ownerDetails?.first.name ?? ""
                                    : "")
                                .isEmpty
                            ? SizedBox()
                            : CustomText(
                                data.ownerDetails?.isNotEmpty ?? false
                                    ? data.ownerDetails?.first.name ?? ""
                                    : "",
                                fontWeight: FontWeight.w700,
                                fontSize: SizeConfig.medium,
                                color: AppColors.white,
                              ),
                        (data.ownerDetails?.isNotEmpty ?? false
                                    ? data.ownerDetails?.first.role_in_business ?? ""
                                    : "")
                                .isEmpty
                            ? SizedBox()
                            : CustomText(
                                data.ownerDetails?.isNotEmpty ?? false
                                    ? data.ownerDetails?.first.role_in_business ?? ""
                                    : "",
                                color: AppColors.white,
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w500,
                              ),
                        SizedBox(height: SizeConfig.size18),
                        ((data.businessNumber?.officeMobNo?.number ?? 0).toString())
                                .isEmpty
                            ? SizedBox()
                            : card8Row(
                                icon: Icons.call,
                                title: (data.businessNumber?.officeMobNo?.number ?? 0)
                                    .toString(),
                                textColor: AppColors.white,
                                fontSize: SizeConfig.small11,
                                fontWeight: FontWeight.w500,
                                imagePath: "assets/svg/call_icon.svg",
                              ),
                        SizedBox(height: SizeConfig.size8),
                        (data.ownerDetails?.isNotEmpty ?? false
                                    ? data.ownerDetails?.first.email ?? ""
                                    : "")
                                .isEmpty
                            ? SizedBox()
                            : card8Row(
                                icon: Icons.email,
                                textColor: AppColors.white,
                                title: data.ownerDetails?.isNotEmpty ?? false
                                    ? data.ownerDetails?.first.email ?? ""
                                    : "",
                                fontWeight: FontWeight.w500,
                                fontSize: SizeConfig.small11,
                                imagePath: "assets/svg/email_icon.svg",
                              ),
                        SizedBox(height: SizeConfig.size8),
                        (data.websiteUrl ?? "").isEmpty
                            ? SizedBox()
                            : card8Row(
                                icon: Icons.language,
                                textColor: AppColors.white,
                                title: data.websiteUrl ?? "",
                                fontSize: SizeConfig.small11,
                                fontWeight: FontWeight.w500,
                                imagePath: "assets/svg/website_icon.svg"),
                        SizedBox(height: SizeConfig.size8),
                        (data.websiteUrl ?? "").isEmpty
                            ? SizedBox()
                            : card8Row(
                                icon: Icons.location_on,
                                textColor: AppColors.white,
                                imagePath: "assets/svg/card_location_icon.svg",
                                fontSize: SizeConfig.small11,
                                fontWeight: FontWeight.w500,
                                title: data.address ?? ""),
                      ],
                    ),
                  )),
                ],
              ),
            )),
      ),
      Positioned(
        bottom: 10,
        right: 10,
        child: InkWell(
          onTap: () async => await VisitingCardHelper().shareVisitingCard(_cardKey),
          child: Container(
            decoration: BoxDecoration(
                color: AppColors.primaryColor,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.white,
                      blurRadius: 6,
                      spreadRadius: 2
                  )
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

Widget buildCard9(BusinessProfileDetails data) {
  final GlobalKey _cardKey = GlobalKey();
  Widget card9Row(
      {required IconData icon,
      required String imagePath,
      required String? title,
      Color? textColor,
      double? fontSize,
      FontWeight? fontWeight,
      TextAlign? textAlign,
      Color? iconColor}) {
    return  Row(
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
          ),
        ),
      ],
    );
  }

  return Stack(
    children: [
      RepaintBoundary(
        key: _cardKey,
        child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                    image: AssetImage("assets/images/card_bg_9.png"),
                    fit: BoxFit.fill)),
            // height: 300,
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: Get.width * 0.056, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
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
                                    angle: -.8,
                                    child: Icon(
                                      Icons.person_2,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 4,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  (data.ownerDetails?.isNotEmpty ?? false
                                              ? data.ownerDetails?.first.name ?? ""
                                              : "")
                                          .isEmpty
                                      ? SizedBox()
                                      : CustomText(
                                          data.ownerDetails?.isNotEmpty ?? false
                                              ? data.ownerDetails?.first.name ?? ""
                                              : "",
                                          fontWeight: FontWeight.w700,
                                          fontSize: SizeConfig.medium,
                                          color: AppColors.black,
                                        ),
                                  (data.ownerDetails?.isNotEmpty ?? false
                                              ? data.ownerDetails?.first
                                                      .role_in_business ??
                                                  ""
                                              : "")
                                          .isEmpty
                                      ? SizedBox()
                                      : CustomText(
                                          data.ownerDetails?.isNotEmpty ?? false
                                              ? data.ownerDetails?.first
                                                      .role_in_business ??
                                                  ""
                                              : "",
                                          color: AppColors.black,
                                          fontSize: SizeConfig.small,
                                          fontWeight: FontWeight.w500,
                                        ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: SizeConfig.size18),
                          ((data.businessNumber?.officeMobNo?.number ?? 0).toString())
                                  .isEmpty
                              ? SizedBox()
                              : card9Row(
                                  icon: Icons.call,
                                  title:
                                      (data.businessNumber?.officeMobNo?.number ?? 0)
                                          .toString(),
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                  imagePath: "assets/svg/call_icon.svg",
                                ),
                          SizedBox(height: SizeConfig.size12),
                          (data.ownerDetails?.isNotEmpty ?? false
                                      ? data.ownerDetails?.first.email ?? ""
                                      : "")
                                  .isEmpty
                              ? SizedBox()
                              : card9Row(
                                  icon: Icons.email,
                                  title: data.ownerDetails?.isNotEmpty ?? false
                                      ? data.ownerDetails?.first.email ?? ""
                                      : "",
                                  fontWeight: FontWeight.w500,
                                  fontSize: SizeConfig.small11,
                                  imagePath: "assets/svg/email_icon.svg",
                                ),
                          SizedBox(height: SizeConfig.size12),
                          (data.websiteUrl ?? "").isEmpty
                              ? SizedBox()
                              : card9Row(
                                  icon: Icons.language,
                                  title: data.websiteUrl ?? "",
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                  imagePath: "assets/svg/website_icon.svg"),
                          SizedBox(height: SizeConfig.size12),
                          (data.address ?? "").isEmpty
                              ? SizedBox()
                              : card9Row(
                                  icon: Icons.location_on,
                                  imagePath: "assets/svg/card_location_icon.svg",
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                  title: data.address ?? ""),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 24),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                        decoration: BoxDecoration(color: Colors.white, boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3), // Shadow color
                            spreadRadius: 1,
                            blurRadius: 6,
                            offset: Offset(-4, 0),
                          ),
                          BoxShadow(
                              color: Colors.white,
                              spreadRadius: 1,
                              blurRadius: 2,
                              offset: Offset(0, -4)),
                          BoxShadow(
                              color: Colors.white,
                              spreadRadius: 1,
                              blurRadius: 2,
                              offset: Offset(0, 4)),
                        ]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.transparent,
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(32),
                                    child: Image.network(
                                      data.logo ?? "",
                                      errorBuilder: (context, error, stackTrace) =>
                                          Image.asset(
                                        "assets/images/be_logo.png",
                                        color: AppColors.green39,
                                      ),
                                    ))),
                            SizedBox(height: SizeConfig.size8),
                            (data.businessName ?? "").isEmpty
                                ? SizedBox()
                                : CustomText(
                                    data.businessName ?? "",
                                    fontWeight: FontWeight.w700,
                                    fontSize: SizeConfig.small,
                                    color: AppColors.black,
                                  ),
                            SizedBox(height: SizeConfig.size2),
                            (data.natureOfBusiness ?? "").isEmpty
                                ? SizedBox()
                                : CustomText(
                                    data.natureOfBusiness ?? "",
                                    color: AppColors.black,
                                    fontSize: SizeConfig.small11,
                                    fontWeight: FontWeight.w500,
                                  ),
                            SizedBox(height: SizeConfig.size2),
                            ((data.businessNumber?.officeLandlineNo?.number ?? 0)
                                        .toString())
                                    .isEmpty
                                ? SizedBox()
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.call,
                                        size: 16,
                                      ),
                                      SizedBox(
                                        width: 4,
                                      ),
                                      CustomText(
                                        (data.businessNumber?.officeLandlineNo
                                                    ?.number ??
                                                0)
                                            .toString(),
                                        color: AppColors.black,
                                        fontSize: SizeConfig.small11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ],
                                  ),
                            SizedBox(height: SizeConfig.size8),
                            (data.businessDescription ?? "").isEmpty
                                ? SizedBox()
                                : CustomText(
                                    data.businessDescription ?? "",
                                    color: AppColors.black,
                                    fontSize: SizeConfig.small11,
                                    fontWeight: FontWeight.w500,
                                    textAlign: TextAlign.center,
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ),
      Positioned(
        bottom: 10,
        right: 10,
        child: InkWell(
          onTap: () async => await VisitingCardHelper().shareVisitingCard(_cardKey),
          child: Container(
            decoration: BoxDecoration(
                color: AppColors.primaryColor,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.white,
                      blurRadius: 6,
                      spreadRadius: 2
                  )
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

Widget buildCard10(BusinessProfileDetails data) {
  final GlobalKey _cardKey = GlobalKey();
  return Stack(
    children: [
      RepaintBoundary(
        key: _cardKey,
        child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black,
                    ),
                    child: Stack(
                      children: [
                        Container(
                          margin: EdgeInsets.only(left: 16),
                          decoration: BoxDecoration(color: AppColors.red),
                          width: 3,
                          height: 250,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                      color: AppColors.black,
                                      shape: BoxShape.circle,
                                      border:
                                          Border.all(color: AppColors.red, width: 3)),
                                  child: Icon(
                                    Icons.person_2,
                                    color: AppColors.white,
                                  ),
                                ),
                                SizedBox(
                                  width: 6,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      (data.ownerDetails?.isNotEmpty ?? false
                                                  ? data.ownerDetails?.first.name ??
                                                      ""
                                                  : "")
                                              .isEmpty
                                          ? SizedBox()
                                          : CustomText(
                                              data.ownerDetails?.isNotEmpty ?? false
                                                  ? data.ownerDetails?.first.name ??
                                                      ""
                                                  : "",
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              fontWeight: FontWeight.w700,
                                              fontSize: SizeConfig.medium,
                                              color: AppColors.white,
                                            ),
                                      (data.ownerDetails?.isNotEmpty ?? false
                                                  ? data.ownerDetails?.first
                                                          .role_in_business ??
                                                      ""
                                                  : "")
                                              .isEmpty
                                          ? SizedBox()
                                          : CustomText(
                                              data.ownerDetails?.isNotEmpty ?? false
                                                  ? data.ownerDetails?.first
                                                          .role_in_business ??
                                                      ""
                                                  : "",
                                              color: AppColors.white,
                                              fontSize: SizeConfig.small,
                                              fontWeight: FontWeight.w500,
                                            ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            SizedBox(
                              height: 28,
                            ),
                            ((data.businessNumber?.officeMobNo?.number ?? 0)
                                        .toString())
                                    .isEmpty
                                ? SizedBox()
                                : Row(
                                    children: [
                                      SizedBox(
                                        width: 4,
                                      ),
                                      Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                            color: AppColors.black,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: AppColors.red, width: 3)),
                                        child: Icon(
                                          Icons.call,
                                          color: AppColors.white,
                                          size: 16,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 6,
                                      ),
                                      CustomText(
                                        (data.businessNumber?.officeMobNo?.number ??
                                                0)
                                            .toString(),
                                        fontSize: SizeConfig.small11,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.white,
                                      ),
                                    ],
                                  ),
                            SizedBox(
                              height: 14,
                            ),
                            (data.ownerDetails?.isNotEmpty ?? false
                                        ? data.ownerDetails?.first.email ?? ""
                                        : "")
                                    .isEmpty
                                ? SizedBox()
                                : Row(
                                    children: [
                                      SizedBox(
                                        width: 4,
                                      ),
                                      Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                            color: AppColors.black,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: AppColors.red, width: 3)),
                                        child: Icon(
                                          Icons.email,
                                          color: AppColors.white,
                                          size: 16,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 6,
                                      ),
                                      Expanded(
                                        child: CustomText(
                                          data.ownerDetails?.isNotEmpty ?? false
                                              ? data.ownerDetails?.first.email ?? ""
                                              : "",
                                          fontSize: SizeConfig.small11,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                            SizedBox(
                              height: 14,
                            ),
                            (data.websiteUrl ?? "").isEmpty
                                ? SizedBox()
                                : Row(
                                    children: [
                                      SizedBox(
                                        width: 4,
                                      ),
                                      Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                            color: AppColors.black,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: AppColors.red, width: 3)),
                                        child: Icon(
                                          Icons.language,
                                          color: AppColors.white,
                                          size: 16,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 6,
                                      ),
                                      Expanded(
                                        child: CustomText(
                                          data.websiteUrl ?? "",
                                          fontSize: SizeConfig.small11,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                            SizedBox(
                              height: 14,
                            ),
                            (data.address ?? "").isEmpty
                                ? SizedBox()
                                : Row(
                                    children: [
                                      SizedBox(
                                        width: 4,
                                      ),
                                      Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                            color: AppColors.black,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: AppColors.red, width: 3)),
                                        child: Icon(
                                          Icons.location_on,
                                          color: AppColors.white,
                                          size: 16,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 6,
                                      ),
                                      Expanded(
                                        child: CustomText(
                                          data.address ?? "",
                                          fontSize: SizeConfig.small11,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(12),
                            topRight: Radius.circular(12)),
                        color: AppColors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            spreadRadius: 1,
                            offset: Offset(-4, 0), // Push left
                          ),
                        ]),
                    margin: EdgeInsets.only(right: 20, bottom: 20, top: 20),
                    padding: EdgeInsets.only(left: 20, bottom: 20, top: 20, right: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                            radius: 30,
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: Image.network(
                                  data.logo ?? "",
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset("assets/images/be_logo.png"),
                                ))),
                        SizedBox(
                          height: 8,
                        ),
                        (data.businessName ?? "").isEmpty
                            ? SizedBox()
                            : CustomText(
                                data.businessName ?? "",
                                fontWeight: FontWeight.w700,
                                fontSize: SizeConfig.medium,
                                color: AppColors.black,
                                textAlign: TextAlign.center,
                              ),
                        SizedBox(height: SizeConfig.size1),
                        (data.natureOfBusiness ?? "").isEmpty
                            ? SizedBox()
                            : CustomText(
                                data.natureOfBusiness ?? "",
                                color: AppColors.black,
                                fontSize: SizeConfig.small11,
                                fontWeight: FontWeight.w500,
                              ),
                        ((data.businessNumber?.officeLandlineNo?.number ?? 0)
                                    .toString())
                                .isEmpty
                            ? SizedBox()
                            : Row(
                                children: [
                                  Icon(
                                    Icons.call,
                                    size: 16,
                                  ),
                                  SizedBox(
                                    width: 4,
                                  ),
                                  CustomText(
                                    (data.businessNumber?.officeLandlineNo?.number ??
                                            0)
                                        .toString(),
                                    color: AppColors.black,
                                    fontSize: SizeConfig.small11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ],
                              ),
                        SizedBox(
                          height: 4,
                        ),
                        (data.businessDescription ?? "").isEmpty
                            ? SizedBox()
                            : CustomText(
                                data.businessDescription ?? "",
                                color: AppColors.black,
                                fontSize: SizeConfig.small11,
                                fontWeight: FontWeight.w500,
                                textAlign: TextAlign.center,
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            )),
      ),
      Positioned(
        bottom: 10,
        right: 10,
        child: InkWell(
          onTap: () async => await VisitingCardHelper().shareVisitingCard(_cardKey),
          child: Container(
            decoration: BoxDecoration(
                color: AppColors.primaryColor,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.white,
                      blurRadius: 6,
                      spreadRadius: 2
                  )
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

Widget buildCard11(BusinessProfileDetails data) {
  final GlobalKey _cardKey = GlobalKey();
  Widget card11Row(
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

  return Stack(
    children: [
      RepaintBoundary(
        key: _cardKey,
        child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                    image: AssetImage("assets/images/card_bg_11.png"),
                    fit: BoxFit.fill)),
            // height: 300,
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: Get.width * 0.056, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20.0, left: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  (data.ownerDetails?.isNotEmpty ?? false
                                              ? data.ownerDetails?.first.name ?? ""
                                              : "")
                                          .isEmpty
                                      ? SizedBox()
                                      : CustomText(
                                          data.ownerDetails?.isNotEmpty ?? false
                                              ? data.ownerDetails?.first.name ?? ""
                                              : "",
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
                                  (data.ownerDetails?.isNotEmpty ?? false
                                              ? data.ownerDetails?.first
                                                      .role_in_business ??
                                                  ""
                                              : "")
                                          .isEmpty
                                      ? SizedBox()
                                      : CustomText(
                                          data.ownerDetails?.isNotEmpty ?? false
                                              ? data.ownerDetails?.first
                                                      .role_in_business ??
                                                  ""
                                              : "",
                                          color: AppColors.white,
                                          fontSize: SizeConfig.small,
                                          fontWeight: FontWeight.w500,
                                        ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: SizeConfig.size18),
                          ((data.businessNumber?.officeMobNo?.number ?? 0).toString())
                                  .isEmpty
                              ? SizedBox()
                              : card11Row(
                                  icon: Icons.call,
                                  title:
                                      (data.businessNumber?.officeMobNo?.number ?? 0)
                                          .toString(),
                                  textColor: AppColors.white,
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                  imagePath: "assets/svg/call_icon.svg",
                                ),
                          SizedBox(height: SizeConfig.size12),
                          (data.ownerDetails?.isNotEmpty ?? false
                                      ? data.ownerDetails?.first.email ?? ""
                                      : "")
                                  .isEmpty
                              ? SizedBox()
                              : card11Row(
                                  icon: Icons.email,
                                  title: data.ownerDetails?.isNotEmpty ?? false
                                      ? data.ownerDetails?.first.email ?? ""
                                      : "",
                                  fontWeight: FontWeight.w500,
                                  textColor: AppColors.white,
                                  fontSize: SizeConfig.small11,
                                  imagePath: "assets/svg/email_icon.svg",
                                ),
                          SizedBox(height: SizeConfig.size12),
                          (data.websiteUrl ?? "").isEmpty
                              ? SizedBox()
                              : card11Row(
                                  icon: Icons.language,
                                  title: data.websiteUrl ?? "",
                                  textColor: AppColors.white,
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                  imagePath: "assets/svg/website_icon.svg"),
                          SizedBox(height: SizeConfig.size12),
                          (data.address ?? "").isEmpty
                              ? SizedBox()
                              : card11Row(
                                  icon: Icons.location_on,
                                  textColor: AppColors.white,
                                  imagePath: "assets/svg/card_location_icon.svg",
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                  title: data.address ?? ""),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 30),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40.0, left: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                              radius: 30,
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(32),
                                  child: Image.network(
                                    data.logo ?? "",
                                    errorBuilder: (context, error, stackTrace) =>
                                        Image.asset("assets/images/be_logo.png"),
                                  ))),
                          SizedBox(height: SizeConfig.size8),
                          (data.businessName ?? "").isEmpty
                              ? SizedBox()
                              : CustomText(
                                  data.businessName ?? "",
                                  fontWeight: FontWeight.w700,
                                  fontSize: SizeConfig.small,
                                  color: AppColors.black,
                                  textAlign: TextAlign.center,
                                ),
                          SizedBox(height: SizeConfig.size2),
                          (data.natureOfBusiness ?? "").isEmpty
                              ? SizedBox()
                              : CustomText(
                                  data.natureOfBusiness ?? "",
                                  color: AppColors.black,
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                  textAlign: TextAlign.center,
                                ),
                          SizedBox(height: SizeConfig.size2),
                          ((data.businessNumber?.officeLandlineNo?.number ?? 0)
                                      .toString())
                                  .isEmpty
                              ? SizedBox()
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.call,
                                      size: 16,
                                    ),
                                    SizedBox(
                                      width: 4,
                                    ),
                                    CustomText(
                                      (data.businessNumber?.officeLandlineNo
                                                  ?.number ??
                                              0)
                                          .toString(),
                                      color: AppColors.black,
                                      fontSize: SizeConfig.small11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ],
                                ),
                          SizedBox(height: SizeConfig.size8),
                          (data.businessDescription ?? "").isEmpty
                              ? SizedBox()
                              : CustomText(
                                  data.businessDescription ?? "",
                                  color: AppColors.black,
                                  fontSize: SizeConfig.small11,
                                  fontWeight: FontWeight.w500,
                                  textAlign: TextAlign.center,
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ),
      Positioned(
        bottom: 10,
        right: 10,
        child: InkWell(
          onTap: () async => await VisitingCardHelper().shareVisitingCard(_cardKey),
          child: Container(
            decoration: BoxDecoration(
                color: AppColors.primaryColor,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.white,
                      blurRadius: 6,
                      spreadRadius: 2
                  )
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

void _showVisitingCardDialog(BuildContext context, {required Widget card}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return Dialog(
            backgroundColor: Colors.white,
            insetPadding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size12,
              vertical: SizeConfig.size12,
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              // color: AppColors.pinkE2,
              padding: EdgeInsets.all(SizeConfig.size12),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: SizeConfig.size12),

                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomText(
                          'Visiting Card',
                          fontWeight: FontWeight.w600,
                          fontSize: SizeConfig.size14,
                          color: AppColors.black,
                        ),
                      ],
                    ),

                    SizedBox(height: SizeConfig.size4),

                    Card(
                      elevation: 20,
                      child: card,
                    ),
                    SizedBox(height: SizeConfig.size4),

                    // Footer actions
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder(),
                          // backgroundColor: accentChip, // per theme
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.of(ctx).maybePop();
                        },
                        icon: const Icon(
                          Icons.ios_share,
                          color: AppColors.black,
                        ),
                        label: Text(
                          AppLocalizations.of(context)!.shareVisitingCard,
                          style: TextStyle(color: AppColors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
