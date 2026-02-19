import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class HospitalHeaderView extends StatefulWidget {
  final bool isReadOnly;

  const HospitalHeaderView({
    super.key,
    required this.isReadOnly,
  });

  @override
  State<HospitalHeaderView> createState() => _HospitalHeaderViewState();
}

class _HospitalHeaderViewState extends State<HospitalHeaderView> {
  final controller = Get.find<HospitalServiceAiController>();
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
        await controller.uploadHospitalLogoOrBannerImage(
            uploadFile: File(image.path), uploadVia: 'coverUrl');
      } else {
        await controller.uploadHospitalLogoOrBannerImage(
            uploadFile: File(image.path), uploadVia: 'logoUrl');
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
                GestureDetector(
                  onTap: () => null,
                  // onTap: () => _pickImage(true),
                  child: Container(
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
                          : DecorationImage(
                              image: NetworkImage(controller
                                      .hospitalDataResModel
                                      ?.value
                                      .data
                                      ?.coverUrl ??
                                  ""),
                              fit: BoxFit.cover),
                    ),
                  ),
                ),
                if (!widget.isReadOnly)
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
                    onTap: () => _pickImage(false),
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
                                image: NetworkImage(controller
                                        .hospitalDataResModel
                                        ?.value
                                        .data
                                        ?.logoUrl ??
                                    ""),
                                fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
                if (!widget.isReadOnly)
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
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                CustomText(controller.hospitalDataResModel?.value.data?.name,
                    fontSize: 20,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.bold),
                const SizedBox(height: 10),
                ExpandableText(
                  text: controller
                          .hospitalDataResModel?.value.data?.description ??
                      "",
                  trimLines: 4,
                  isReadMoreNewLine: false,
                  expandMode: ExpandMode.dialog,
                  style: TextStyle(
                    color: AppColors.secondaryTextColor,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppConstants.OpenSans,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
