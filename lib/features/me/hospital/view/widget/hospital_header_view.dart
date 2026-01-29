import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/getx_utils.dart';
import '../../../../common/auth/views/dialogs/select_profile_picture_dialog.dart';
import '../../controller/hospital_model_controller.dart';
import '../../model/hospital_home_page_details_model.dart';

class HospitalHeaderView extends StatefulWidget {

  const HospitalHeaderView({
    super.key, this.details,
  });
  final HospitalInfoModel? details;

  @override
  State<HospitalHeaderView> createState() => _HospitalHeaderViewState();
}

class _HospitalHeaderViewState extends State<HospitalHeaderView> {
  final controller = getOrPut(() => HospitalModelController());

  Future<void> _pickImage(bool isBanner) async {
    final String? image =
    await  SelectProfilePictureDialog.showLogoDialog(context, isBanner?"Hospital Banner":"Hospital Logo");
    if(image!=null){
      setState(() {
        if (isBanner) {
          controller.pickDoctorImage(File(image));
          controller.addCoverImage();
        } else {
          controller.pickedHospitalLogo.value = File(image);
          controller.addLogoImage();
        }
      });
    }

  }
  // Future<void> _pickLogoImage() async {
  //   final String? image =
  //   await  SelectProfilePictureDialog.showLogoDialog(context, "Hospital Logo");
  //   if(image!=null){
  //
  //
  //         controller.pickedHospitalLogo.value = File(image);
  //         controller.addLogoImage();
  //     });
  //   }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return CommonCardWidget(
      padding: 0,
      cardMargin: 10,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // --- HEADER SECTION (Banner & Logo) ---
          SizedBox(
            height: size.height * 0.22,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner Image
                GestureDetector(
                  onTap: () => _pickImage(true),
                  child: Container(
                    width: double.infinity,
                    height: size.height * 0.17,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[100],
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10)),
                      image:
                      // _bannerImage != null
                      //     ?
                      (controller.pickedDoctorImage.value==null)?
                      (widget.details?.coverImage != null &&
                          widget.details!.coverImage!.isNotEmpty)
                          ? DecorationImage(
                        image: NetworkImage(widget.details!.coverImage!),
                        fit: BoxFit.cover,
                        onError: (_, __) {}, // prevents crash
                      )
                          : null:
                      DecorationImage(
                          image:
                          FileImage(controller.pickedDoctorImage.value ?? File("")),
                          fit: BoxFit.cover
                      )

                    ),
                  ),
                ),
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
                        image:
                        (controller.pickedHospitalLogo.value==null)?
                        (widget.details?.logo != null &&
                            widget.details!.logo!.isNotEmpty)
                            ? DecorationImage(
                          image: NetworkImage(widget.details!.logo!),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        )
                            : null:
                        DecorationImage(
                            image:
                            FileImage(controller.pickedHospitalLogo.value ?? File("")),
                            fit: BoxFit.cover
                        )
                      ),
                    ),
                  ),
                ),
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
                CustomText(
                    "${widget.details?.name}",
                    fontSize: 18,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.bold),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.star,color: AppColors.yellow,),
                    CustomText("4.8",color:AppColors.yellow,),
                    CustomText(" (48 reviews)"),
                    SizedBox(width: 4,),
                    LocalAssets(imagePath: AppIconAssets.location_new),
                    CustomText(" 2.7 Km"),

                  ],
                ),
                SizedBox(height: SizeConfig.size10),
                ExpandableText(
                  text:"${widget.details?.tagline}",
                  trimLines: 3,
                  isReadMoreNewLine: false,
                  expandMode: ExpandMode.dialog,
                  style: TextStyle(
                    color: AppColors.secondaryTextColor,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppConstants.OpenSans,
                  ),
                ),
                SizedBox(height: SizeConfig.size10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
