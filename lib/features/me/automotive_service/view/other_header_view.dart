import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/me/automotive_service/controller/business_profile_full_controller.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_header_title_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class OtherHeaderView extends StatefulWidget {
  final AutomotiveBusinessProfileFullController schoolAboutUsController;

  const OtherHeaderView({
    super.key,
    required this.schoolAboutUsController,
  });

  @override
  State<OtherHeaderView> createState() => _OtherHeaderViewState();
}

class _OtherHeaderViewState extends State<OtherHeaderView> {
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
    final profile =
        widget.schoolAboutUsController.businessProfile.value?.profile;

    return Container(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER SECTION (Banner & Logo) ---
          SizedBox(
            height: size.height * 0.22,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner Image
                Container(
                  width: double.infinity,
                  height: size.height * 0.17,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[50],
                  ),
                  child: _bannerImage != null
                      ? Image.file(_bannerImage!, fit: BoxFit.cover)
                      : (profile?.coverUrl?.isNotEmpty ?? false)
                          ? CachedNetworkImage(
                              imageUrl: profile!.coverUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                              errorWidget: (context, url, error) => const Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: Colors.grey),
                            )
                          : const Center(
                              child: Icon(Icons.image,
                                  color: Colors.grey, size: 40)),
                ),

                // Edit Banner Button
                Positioned(
                  right: 12,
                  top: 12,
                  child: InkWell(
                    onTap: () => _pickImage(true),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4)
                        ],
                      ),
                      child: const LocalAssets(
                        imagePath: AppIconAssets.edit_banner_icon,
                        height: 20,
                        width: 20,
                      ),
                    ),
                  ),
                ),

                // Logo Image
                Positioned(
                  bottom: 0,
                  left: 20,
                  child: GestureDetector(
                    onTap: () => _pickImage(false),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              spreadRadius: 2)
                        ],
                      ),
                      child: ClipOval(
                        child: _logoImage != null
                            ? Image.file(_logoImage!, fit: BoxFit.cover)
                            : (profile?.logoUrl?.isNotEmpty ?? false)
                                ? CachedNetworkImage(
                                    imageUrl: profile!.logoUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2)),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.business,
                                            size: 40, color: Colors.grey),
                                  )
                                : const Center(
                                    child: Icon(Icons.add_a_photo,
                                        color: Colors.grey, size: 30)),
                      ),
                    ),
                  ),
                ),

                // Edit Logo Button
                Positioned(
                  bottom: 5,
                  left: 85,
                  child: InkWell(
                    onTap: () => _pickImage(false),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryColor,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          ServiceHomeHeaderTitleWidget(
            title: profile?.profileName ?? "",
            description: profile?.description ??
                widget.schoolAboutUsController.businessProfile.value
                    ?.aboutOrganisation?.firstOrNull?.description ??
                "N/A",
          ),
        ],
      ),
    );
  }
}
