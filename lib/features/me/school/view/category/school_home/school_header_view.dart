import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_header_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SchoolHeaderView extends StatefulWidget {
  final SchoolAboutUsController schoolAboutUsController;
  final bool? isEdit;

  SchoolHeaderView({
    super.key,
    required this.schoolAboutUsController,
    this.isEdit = false,
  });

  @override
  State<SchoolHeaderView> createState() => _SchoolHeaderViewState();
}

class _SchoolHeaderViewState extends State<SchoolHeaderView> {
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
            uploadFile: File(image.path), uploadVia: 'bannerUrl');
      } else {
        await widget.schoolAboutUsController.uploadSchoolLogoOrBannerImage(
            uploadFile: File(image.path), uploadVia: 'logo');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return CommonCardWidget(
      padding: 0,
      child: Column(
        children: [
          // --- HEADER SECTION (Banner & Logo) ---
          SizedBox(
            height: size.height * 0.20,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner Image
                Container(
                  width: double.infinity,
                  height: size.height * 0.15,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[100],
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10)),
                    image: _bannerImage != null
                        ? DecorationImage(
                            image: FileImage(_bannerImage ?? File("")),
                            fit: BoxFit.cover)
                        : (widget.schoolAboutUsController.schoolDetailsData?.value.bannerUrl?.isNotEmpty ?? false)
                            ? DecorationImage(
                                image: NetworkImage(widget.schoolAboutUsController
                                    .schoolDetailsData!.value.bannerUrl!),
                                fit: BoxFit.cover)
                            : null,
                  ),
                ),
                if (widget.isEdit ?? false)
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
                    onTap: () =>                 (widget.isEdit ?? false)?_pickImage(false):null,
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
                            : (widget.schoolAboutUsController.schoolDetailsData?.value.logo?.isNotEmpty ?? false)
                                ? DecorationImage(
                                    image: NetworkImage(widget
                                        .schoolAboutUsController
                                        .schoolDetailsData!
                                        .value
                                        .logo!),
                                    fit: BoxFit.cover)
                                : null,
                      ),
                    ),
                  ),
                ),
                if (widget.isEdit ?? false)
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
                              // color: AppColors.red00,
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
          ServiceHomeHeaderTitleWidget(
            title:
                widget.schoolAboutUsController.schoolDetailsData?.value.name ??
                    "",
            description: widget.schoolAboutUsController.schoolDetailsData?.value
                    .aboutId?.visionAndMission ??
                "",
          ),
        ],
      ),
    );
  }
}
