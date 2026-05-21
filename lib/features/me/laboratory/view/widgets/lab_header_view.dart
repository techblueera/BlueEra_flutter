import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_full_details_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/new_lab_full_details_res_model.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Profile header for a lab: banner + circular logo + name + facility chips.
/// Tapping the camera affordances (own-profile only) opens the cover/logo
/// picker which uploads through [LabFullDetailsController].
class LabHeaderView extends StatefulWidget {
  final LabFullDetailsController controller;
  final bool isOwnProfile;

  const LabHeaderView({
    super.key,
    required this.controller,
    this.isOwnProfile = true,
  });

  @override
  State<LabHeaderView> createState() => _LabHeaderViewState();
}

class _LabHeaderViewState extends State<LabHeaderView> {
  File? _bannerImage;
  File? _logoImage;

  Future<void> _pickImage({required bool isBanner}) async {
    final imagePath = await PhotoPickerService.pickSinglePhoto(
      context,
      isBanner
          ? AppStrings.editCoverPicture.tr
          : AppStrings.uploadProfilePicture.tr,
      cropAspectRatio: isBanner
          ? const CropAspectRatio(width: 16, height: 9)
          : const CropAspectRatio(width: 1, height: 1),
    );
    if (imagePath == null || imagePath.isEmpty) return;

    final file = File(imagePath);
    setState(() {
      if (isBanner) {
        _bannerImage = file;
      } else {
        _logoImage = file;
      }
    });
    await widget.controller.uploadSchoolLogoOrBannerImage(
      uploadFile: file,
      uploadVia: isBanner ? 'coverUrl' : 'logoUrl',
    );
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
          SizedBox(
            height: size.height * 0.21,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildBanner(size),
                if (widget.isOwnProfile) _buildBannerEditButton(),
                _buildLogo(),
                if (widget.isOwnProfile) _buildLogoEditButton(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                CustomText(
                  widget.controller.details.value?.profile?.name,
                  fontSize: 18,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 10),
                _FacilityChipList(
                  facility: widget.controller.details.value?.facility,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(Size size) {
    final coverUrl =
        widget.controller.details.value?.profile?.coverUrl ?? '';
    final DecorationImage? image = _bannerImage != null
        ? DecorationImage(image: FileImage(_bannerImage!), fit: BoxFit.cover)
        : (coverUrl.isNotEmpty
            ? DecorationImage(image: NetworkImage(coverUrl), fit: BoxFit.cover)
            : null);

    // Banner area itself is non-interactive — edits go through the explicit
    // pencil button overlay so tapping the banner doesn't accidentally
    // trigger an upload.
    return Container(
      width: double.infinity,
      height: size.height * 0.17,
      decoration: BoxDecoration(
        color: Colors.blueGrey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        image: image,
      ),
    );
  }

  Widget _buildBannerEditButton() {
    return Positioned(
      right: 20,
      top: 10,
      child: InkWell(
        onTap: () => _pickImage(isBanner: true),
        child: SizedBox(
          width: 30,
          height: 30,
          child: LocalAssets(imagePath: AppIconAssets.edit_banner_icon),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final logoUrl = widget.controller.details.value?.profile?.logoUrl ?? '';
    final DecorationImage logoImage = _logoImage != null
        ? DecorationImage(image: FileImage(_logoImage!), fit: BoxFit.cover)
        : (logoUrl.isNotEmpty
            ? DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover)
            : DecorationImage(
                image: AssetImage(AppIconAssets.place_holder_image),
                fit: BoxFit.cover,
              ));

    return Positioned(
      bottom: 0,
      left: 20,
      child: GestureDetector(
        onTap: widget.isOwnProfile ? () => _pickImage(isBanner: false) : null,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 10),
            ],
            image: logoImage,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoEditButton() {
    return Positioned(
      bottom: 10,
      left: 90,
      child: InkWell(
        onTap: () => _pickImage(isBanner: false),
        child: Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.secondaryTextColor.withValues(alpha: 0.3),
          ),
          child: const Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: 15,
          ),
        ),
      ),
    );
  }
}

/// Wraps the lab's facility booleans and `other` list into chips, showing the
/// first two inline and a `+N View More` pill that opens an "all services"
/// dialog.
class _FacilityChipList extends StatelessWidget {
  const _FacilityChipList({required this.facility});

  final Facility? facility;

  static const int _previewCount = 2;

  List<String> _collectChips() {
    final chips = <String>[];
    if (facility?.wheelchairAssistance == true) {
      chips.add(AppStrings.wheelchairAssistance.tr);
    }
    if (facility?.doctorConsultationTieUp == true) {
      chips.add(AppStrings.doctorConsultationTieUp.tr);
    }
    if (facility?.insuranceCashlessSupport == true) {
      chips.add(AppStrings.insuranceCashlessSupport.tr);
    }
    if (facility?.homeSampleCollection == true) {
      chips.add(AppStrings.homeSampleCollection.tr);
    }
    if (facility?.digitalReport == true) {
      chips.add(AppStrings.digitalReport.tr);
    }
    final other = (facility?.other ?? const [])
        .map((e) => e.label ?? '')
        .where((e) => e.isNotEmpty);
    return [...chips, ...other];
  }

  @override
  Widget build(BuildContext context) {
    final allChips = _collectChips();
    if (allChips.isEmpty) return const SizedBox.shrink();

    final preview = allChips.take(_previewCount).toList();
    final hiddenCount = allChips.length - preview.length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...preview.map(_FacilityChip.new),
        if (hiddenCount > 0)
          GestureDetector(
            onTap: () => _showAllServices(context, allChips),
            child: _FacilityChip(
              '+$hiddenCount ${AppStrings.labViewMore.tr}',
              color: AppColors.primaryColor,
            ),
          ),
      ],
    );
  }

  void _showAllServices(BuildContext context, List<String> chips) {
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
          children: chips.map(_FacilityChip.new).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: CustomText(
              AppStrings.labClose.tr,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityChip extends StatelessWidget {
  const _FacilityChip(this.text, {this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffEAF2FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.1)),
      ),
      child: CustomText(text, fontSize: SizeConfig.small, color: color),
    );
  }
}
