import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_full_details_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/new_lab_full_details_res_model.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class LabHeaderView extends StatefulWidget {
  final LabFullDetailsController schoolAboutUsController;
  final bool isOwnProfile;

  const LabHeaderView({
    super.key,
    required this.schoolAboutUsController,
    this.isOwnProfile = true,
  });

  @override
  State<LabHeaderView> createState() => _LabHeaderViewState();
}

class _LabHeaderViewState extends State<LabHeaderView> {
  File? _bannerImage;
  File? _logoImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isBanner) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isBanner) {
          _bannerImage = File(image.path);
        } else {
          _logoImage = File(image.path);
        }
      });
      if (isBanner) {
        await widget.schoolAboutUsController.uploadSchoolLogoOrBannerImage(
            uploadFile: File(image.path), uploadVia: 'coverUrl');
      } else {
        await widget.schoolAboutUsController.uploadSchoolLogoOrBannerImage(
            uploadFile: File(image.path), uploadVia: 'logoUrl');
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;
    return CommonCardWidget(
      padding: 0,
      cardMargin: 0,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // --- HEADER SECTION (Banner & Logo) ---
          SizedBox(
            height: size.height * 0.21,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner Image
                if(widget
                    .schoolAboutUsController
                    .details
                    .value
                    ?.profile
                    ?.coverUrl?.isNotEmpty??false)
                GestureDetector(
                  onTap: () => null,
                  // onTap: () => _pickImage(true),
                  child: Container(
                    width: double.infinity,
                    height: size.height * 0.17,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[100],
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10)),
                      image: _bannerImage != null
                          ? DecorationImage(
                              image: FileImage(_bannerImage ?? File("")),
                              fit: BoxFit.cover)
                          : DecorationImage(
                              image: NetworkImage((widget
                                          .schoolAboutUsController
                                          .details
                                          .value
                                          ?.profile
                                          ?.coverUrl
                                          ?.isNotEmpty ??
                                      false)
                                  ? (widget.schoolAboutUsController.details
                                          .value?.profile?.coverUrl ??
                                      "")
                                  : widget
                                          .schoolAboutUsController
                                          .details
                                          .value
                                          ?.profile
                                          ?.coverUrl
                                           ??
                                      ""),
                              fit: BoxFit.cover),
                    ),
                  ),
                ),
                if (widget.isOwnProfile)
                Positioned(
                  right: 20,
                  top: 10,
                  child: InkWell(
                    onTap: () => _pickImage(true),
                    child: Container(
                        width: 30,
                        height: 30,
                        child: LocalAssets(
                          imagePath: AppIconAssets.edit_banner_icon,
                        )),
                  ),
                ),

                // Logo Image
                Positioned(
                  bottom: 0,
                  left: 20,
                  child: GestureDetector(
                    onTap: widget.isOwnProfile ? () => _pickImage(false) : null,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 10)
                        ],
                        image: _logoImage != null
                            ? DecorationImage(
                                image: FileImage(_logoImage ?? File("")),
                                fit: BoxFit.cover)
                            : DecorationImage(
                                image: NetworkImage((widget
                                            .schoolAboutUsController
                                            .details
                                            .value
                                            ?.profile
                                            ?.coverUrl
                                            ?.isNotEmpty ??
                                        false)
                                    ? (widget.schoolAboutUsController.details
                                            .value?.profile?.coverUrl ??
                                        "")
                                    : widget
                                            .schoolAboutUsController
                                            .details
                                            .value
                                            ?.profile
                                            ?.coverUrl
                                             ??
                                        ""),
                                fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
                if (widget.isOwnProfile)
                Positioned(
                    bottom: 10,
                    left: 90,
                    child: InkWell(
                      onTap: () => _pickImage(false),
                      child: Container(
                          width: 25,
                          height: 25,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.secondaryTextColor
                                .withValues(alpha: 0.3),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 15,
                          )),
                    ))
              ],
            ),
          ),

          // --- FORM SECTION ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                CustomText(
                    widget
                        .schoolAboutUsController.details.value?.profile?.name,
                    fontSize: 18,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.bold),
                const SizedBox(height: 10),
                allServices(widget.schoolAboutUsController.details.value?.facility, context),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }


}
Widget allServices(Facility? facility, BuildContext context) {
  final chips = <String>[];
  if (facility?.wheelchairAssistance == true)
    chips.add(AppStrings.wheelchairAssistance.tr);
  if (facility?.doctorConsultationTieUp == true)
    chips.add(AppStrings.doctorConsultationTieUp.tr);
  if (facility?.insuranceCashlessSupport == true)
    chips.add(AppStrings.insuranceCashlessSupport.tr);
  if (facility?.homeSampleCollection == true)
    chips.add(AppStrings.homeSampleCollection.tr);
  if (facility?.digitalReport == true)
    chips.add(AppStrings.digitalReport.tr);
  final other = (facility?.other ?? [])
      .map((e) => e.label ?? '')
      .where((e) => e.isNotEmpty)
      .toList();
  final allChips = [...chips, ...other];

  if (allChips.isEmpty) return const SizedBox.shrink();

  final displayChips = allChips.take(2).toList();
  final hasMore = allChips.length > 2;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...displayChips.map((c) => chip(c)),
          if (hasMore)
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: CustomText(
                      AppStrings.ourAllServices.tr,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    content: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allChips.map((c) => chip(c)).toList(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: CustomText('Close', color: AppColors.primaryColor),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xffEAF2FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.1)),
                ),
                child: CustomText(
                  '+${allChips.length - 2} View More',
                  fontSize: SizeConfig.small,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
        ],
      ),
    ],
  );
}

Widget chip(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xffEAF2FF),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.1)),
    ),
    child: CustomText(text, fontSize: SizeConfig.small),
  );
}
