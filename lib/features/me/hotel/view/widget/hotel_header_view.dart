import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_home_detail_controller.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_header_title_widget.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Header section of the hotel home screen: banner (16:9), circular logo
/// overlay, and the name/description block. Both banner and logo are
/// editable — picking a new image shows it optimistically before the upload
/// to S3 completes and the controller reloads the profile.
class HotelHeaderView extends StatefulWidget {
  final HotelDetailController controller;

  const HotelHeaderView({
    super.key,
    required this.controller,
  });

  @override
  State<HotelHeaderView> createState() => _HotelHeaderViewState();
}

class _HotelHeaderViewState extends State<HotelHeaderView> {
  File? _bannerImage;
  File? _logoImage;

  Future<void> _pickImage({required bool isBanner}) async {
    final String? imagePath = await PhotoPickerService.pickSinglePhoto(
      context,
      isBanner
          ? AppStrings.editCoverPicture.tr
          : AppStrings.uploadProfilePicture.tr,
      cropAspectRatio: isBanner
          ? const CropAspectRatio(width: 16, height: 9)
          : const CropAspectRatio(width: 1, height: 1),
    );

    if (imagePath == null || imagePath.isEmpty) return;

    final picked = File(imagePath);
    setState(() {
      if (isBanner) {
        _bannerImage = picked;
      } else {
        _logoImage = picked;
      }
    });

    await widget.controller.uploadSchoolLogoOrBannerImage(
      uploadFile: picked,
      uploadVia: isBanner ? 'coverUrl' : 'logoUrl',
    );
  }

  /// First non-empty image source for the banner: local pick > profile
  /// `coverUrl` > first uploaded property photo. Returns `null` when nothing
  /// is available so the caller can show a blank placeholder background.
  DecorationImage? _bannerDecoration() {
    if (_bannerImage != null) {
      return DecorationImage(image: FileImage(_bannerImage!), fit: BoxFit.cover);
    }
    final url = _coverOrFirstPhotoUrl();
    if (url == null) return null;
    return DecorationImage(image: NetworkImage(url), fit: BoxFit.cover);
  }

  /// Same fallback chain as the banner but ending in the in-app placeholder
  /// asset, so the logo circle is never empty.
  DecorationImage _logoDecoration() {
    if (_logoImage != null) {
      return DecorationImage(image: FileImage(_logoImage!), fit: BoxFit.cover);
    }
    final logoUrl = widget.controller.hotelData.value?.profile?.logoUrl;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover);
    }
    final firstPhoto = _firstPropertyPhotoUrl();
    if (firstPhoto != null) {
      return DecorationImage(image: NetworkImage(firstPhoto), fit: BoxFit.cover);
    }
    return DecorationImage(
      image: AssetImage(AppIconAssets.place_holder_image),
      fit: BoxFit.cover,
    );
  }

  String? _coverOrFirstPhotoUrl() {
    final cover = widget.controller.hotelData.value?.profile?.coverUrl;
    if (cover != null && cover.isNotEmpty) return cover;
    return _firstPropertyPhotoUrl();
  }

  String? _firstPropertyPhotoUrl() {
    final photos = widget.controller.hotelData.value?.profile?.photos;
    if (photos == null || photos.isEmpty) return null;
    final refs = photos.first.imageReferences;
    if (refs == null || refs.isEmpty) return null;
    return refs.first;
  }

  String _hotelDisplayName() {
    final name = widget.controller.hotelData.value?.profile?.name;
    return (name != null && name.isNotEmpty) ? name : businessNameGlobal;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final profile = widget.controller.hotelData.value?.profile;

    return CommonCardWidget(
      padding: 0,
      cardMargin: 10,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: size.height * 0.21,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _banner(size),
                _bannerEditButton(),
                _logo(),
                _logoEditButton(),
              ],
            ),
          ),
          ServiceHomeHeaderTitleWidget(
            title: _hotelDisplayName(),
            description: profile?.description ?? '',
          ),
        ],
      ),
    );
  }

  // ---- Banner ---------------------------------------------------------------

  Widget _banner(Size size) {
    return Container(
      width: double.infinity,
      height: size.height * 0.17,
      decoration: BoxDecoration(
        color: Colors.blueGrey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        image: _bannerDecoration(),
      ),
    );
  }

  Widget _bannerEditButton() {
    return Positioned(
      right: 20,
      top: 10,
      child: InkWell(
        onTap: () => _pickImage(isBanner: true),
        child: const SizedBox(
          width: 30,
          height: 30,
          child: LocalAssets(imagePath: AppIconAssets.edit_banner_icon),
        ),
      ),
    );
  }

  // ---- Logo -----------------------------------------------------------------

  Widget _logo() {
    return Positioned(
      bottom: 0,
      left: 20,
      child: GestureDetector(
        onTap: () => _pickImage(isBanner: false),
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
            image: _logoDecoration(),
          ),
        ),
      ),
    );
  }

  Widget _logoEditButton() {
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
