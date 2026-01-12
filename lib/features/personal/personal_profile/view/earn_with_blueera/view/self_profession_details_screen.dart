import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/earn_service_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../common/service/model/get_service_model.dart';

class ProfessionDetailsScreen extends StatefulWidget {

  const ProfessionDetailsScreen({Key? key}) : super(key: key);

  @override
  State<ProfessionDetailsScreen> createState() => _ProfessionDetailsScreenState();
}

class _ProfessionDetailsScreenState extends State<ProfessionDetailsScreen> {
  final controller = getOrPut(() => EarnServiceController());

  @override
  void initState() {
    controller.fetchSelfProfessionData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    final controller = getOrPut(() => EarnServiceController());

    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: CommonBackAppBar(),
      body: Obx(() {
        // 1. Loading State
        if (controller.isProfessionDataLoading.value) {
          return Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
        }

        // 3. Success State (Your UI)
        final service = controller.professionData.value;

        // Timings
        DateTime parse12HourTime(String timeStr) {
          final format = RegExp(r'(\d+):(\d+)\s*(AM|PM)');
          final match = format.firstMatch(timeStr.trim());

          if (match != null) {
            int hour = int.parse(match.group(1)!);
            int minute = int.parse(match.group(2)!);
            final period = match.group(3);

            if (period == "PM" && hour != 12) hour += 12;
            if (period == "AM" && hour == 12) hour = 0;

            return DateTime(0, 1, 1, hour, minute);
          }

          return DateTime(0); // fallback
        }

        Map<String, String> getMinMaxTimings(List<Timings>? timingsList) {
          if (timingsList == null || timingsList.isEmpty) return {"start": "--", "end": "--"};

          Timings? earliest = timingsList.first;
          Timings? latest = timingsList.first;

          for (final t in timingsList) {
            final startTime = parse12HourTime(t.start ?? "00:00 AM");
            final earliestStart = parse12HourTime(earliest?.start ?? "00:00 AM");
            if (startTime.isBefore(earliestStart)) earliest = t;

            final endTime = parse12HourTime(t.end ?? "00:00 AM");
            final latestEnd = parse12HourTime(latest?.end ?? "00:00 AM");
            if (endTime.isAfter(latestEnd)) latest = t;
          }

          return {
            "start": earliest?.start ?? "--",
            "end": latest?.end ?? "--",
          };
        }

        // final timingMap = getMinMaxTimings(service.service?.timings);


        // Price
        final priceData = service.priceData;
        final isRange = priceData?.priceType == 'range';

        String priceDisplay;
        if (isRange) {
          final min = priceData?.priceRange?.min ?? 0;
          final max = priceData?.priceRange?.max ?? 0;
          priceDisplay = "₹${formatIndianNumber(min)}-${formatIndianNumber(max)}";
        } else {
          priceDisplay = "₹${formatIndianNumber(priceData?.singlePrice ?? 0)}";
        }

        Color badgeColor = isRange ? AppColors.green1A : AppColors.primaryColor;
        String badgeText = priceData?.priceType.toString().capitalizeFirst ?? '';

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              vertical: SizeConfig.size15,
              horizontal: SizeConfig.size8
          ),
          child: SafeArea(
            child: Column(
              children: [
                // --- Profile Card ---
                CustomFormCard(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          // Navigate to details
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(10.0)),
                              child: CachedNetworkImage(
                                // imageUrl: service.profileImage ?? '',
                                imageUrl: 'https://picsum.photos/400',
                                width: SizeConfig.screenWidth,
                                height: SizeConfig.size150,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: SizeConfig.screenWidth,
                                  height: SizeConfig.size150,
                                  color: Colors.grey[300],
                                ),
                                errorWidget: (context, url, error) => Icon(
                                    Icons.person,
                                    size: SizeConfig.size150 / 2),
                              ),
                            ),
                            Positioned(
                                left: 20,
                                bottom: -(SizeConfig.size40),
                                child: Container(
                                  padding: const EdgeInsets.all(3.0),
                                  decoration: BoxDecoration(
                                      color: AppColors.white,
                                      shape: BoxShape.circle),
                                  child: CachedAvatarWidget(
                                    // imageUrl: service.profileImage ?? '',
                                    imageUrl: 'https://picsum.photos/400',
                                    size: SizeConfig.size80,
                                    borderColor: Colors.white,
                                    borderRadius: SizeConfig.size40,
                                  ),
                                ))
                          ],
                        ),
                      ),
                      SizedBox(height: SizeConfig.size60),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: CustomText(
                                  // service.name ?? 'Unknown User',
                                  'Ramesh Bhagat',
                                  fontSize: SizeConfig.large,
                                  color: AppColors.mainTextColor,
                                  fontWeight: FontWeight.w700),
                            ),
                            SizedBox(width: SizeConfig.size8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: SizeConfig.size3,
                                horizontal: SizeConfig.size10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                    color: AppColors.secondaryTextColor, width: 0.5),
                              ),
                              child: CustomText(
                                  // service.profession ?? '',
                                  userWorkTypeGlobal, // Added null check
                                  fontSize: SizeConfig.small,
                                  color: AppColors.secondaryTextColor,
                                  fontWeight: FontWeight.w400),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: SizeConfig.size12),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                        child: ExpandableText(
                          // text: "${service.bio ?? ''}",
                          text: "Norem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattiskljdsnbkjdsnbkndskjlnkdsjnfds,nfjkldsnfj,dshfuiews sa dbasuidfbewbfkljwbn",
                          trimLines: 3,
                          expandMode: ExpandMode.dialog,
                          style: TextStyle(
                            color: AppColors.mainTextColor,
                            fontFamily: AppConstants.OpenSans,
                            fontWeight: FontWeight.w400,
                            fontSize: SizeConfig.medium,
                          ),
                        ),
                      ),
                      SizedBox(height: SizeConfig.size10),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.paddingM),

                // --- Price ---
                CustomFormCard(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _buildTitle('${AppStrings.price.tr}: ')),
                          _editIcon(onTap: () {  })
                        ],
                      ),
                      SizedBox(height: SizeConfig.size8),
                      _buildCommonDivider(),
                      SizedBox(height: SizeConfig.size8),
                      CustomText(
                        '₹1000 - 3000',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.paddingM),

                // --- Timing ---
                CustomFormCard(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _buildTitle('Timing')),
                          _editIcon(onTap: () {  })
                        ],
                      ),
                      SizedBox(height: SizeConfig.size8),
                      _buildCommonDivider(),
                      SizedBox(height: SizeConfig.size8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          children: [
                            CustomText(
                              "${AppStrings.open.tr}: ",
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w400,
                              overflow: TextOverflow.ellipsis,
                              color: AppColors.green00,
                            ),
                            CustomText(
                              // timingMap["start"]!,
                              '9:00 AM',
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w400,
                              overflow: TextOverflow.ellipsis,
                              color: AppColors.secondaryTextColor,
                              maxLines: 1,
                            ),
                            CustomText(
                              ' | ',
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor,
                              overflow: TextOverflow.ellipsis,
                            ),
                            CustomText(
                              "${AppStrings.close.tr}: ",
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w400,
                              overflow: TextOverflow.ellipsis,
                              color: AppColors.redB4,
                              maxLines: 1,
                            ),
                            CustomText(
                              // timingMap["end"]!,
                              '9:00 PM',
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w400,
                              color: AppColors.grayText,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.paddingM),

                // --- Service Description ---
                CustomFormCard(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _buildTitle('Service Description')),
                          _editIcon(onTap: () {  })
                        ],
                      ),
                      SizedBox(height: SizeConfig.size8),
                      _buildCommonDivider(),
                      SizedBox(height: SizeConfig.size8),
                      (service.service != null &&
                          service.service!.facilities != null &&
                          service.service!.facilities!.isNotEmpty)
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          service.service!.facilities!.length,
                              (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin:
                                  const EdgeInsets.only(top: 6.0, right: 8.0),
                                  width: 4.0,
                                  height: 4.0,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryTextColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: CustomText(
                                    service.service!.facilities![index],
                                    fontSize: SizeConfig.medium,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                          : CustomText(
                        'No Description available',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.paddingM),

                // --- Work Experience ---
                CustomFormCard(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _buildTitle('Work Experience')),
                          _editIcon(onTap: () {  })
                        ],
                      ),
                      SizedBox(height: SizeConfig.size8),
                      _buildCommonDivider(),
                      SizedBox(height: SizeConfig.size8),
                      (service.experiences != null && service.experiences!.isNotEmpty)
                          ? CustomText(
                        service.experiences![0],
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                      )
                          : CustomText(
                        'No Experience',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.paddingM),

                // --- Expertise ---
                CustomFormCard(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _buildTitle('Expertise')),
                          _editIcon(onTap: () {  })
                        ],
                      ),
                      SizedBox(height: SizeConfig.size8),
                      _buildCommonDivider(),
                      SizedBox(height: SizeConfig.size8),
                      (service.skills != null && service.skills!.isNotEmpty)
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          service.skills!.length,
                              (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin:
                                  const EdgeInsets.only(top: 6.0, right: 8.0),
                                  width: 4.0,
                                  height: 4.0,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryTextColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: CustomText(
                                    service.skills![index],
                                    fontSize: SizeConfig.medium,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                          : CustomText(
                        'No Skills',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.paddingM),

                // --- Gallery ---
                CustomFormCard(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle('Gallery'),

                      SizedBox(height: SizeConfig.size8),
                      _buildCommonDivider(),
                      SizedBox(height: SizeConfig.size8),
                      LayoutBuilder(
                      builder: (context, constraints) {
                      final spacing = SizeConfig.size8;
                      final containerWidth = (constraints.maxWidth - (spacing * 3)) / 4;

                      return GetBuilder<EarnServiceController>(
                        id: 'professionPhotos',
                        builder: (controller) {
                          // final apiPhotos = controller.professionData?.data?.livePhotos ?? [];
                          final List<String> apiPhotos =  [];

                          final totalCount = apiPhotos.length;
                          final emptySlots = (8 - totalCount).clamp(0, 8);

                          List<Widget> allPhotos = [];

                          // API Photos (Already uploaded)
                          for (int i = 0; i < apiPhotos.length; i++) {
                            allPhotos.add(_buildImageContainer(
                              context,
                              apiPhotos[i],
                              i,
                              controller,
                              containerWidth,
                              apiPhotos,
                            ));
                          }

                          // Empty slots for remaining photos
                          for (int i = 0; i < emptySlots; i++) {
                            allPhotos.add(_buildImageContainer(
                              context,
                              "",
                              apiPhotos.length + i,
                              controller,
                              containerWidth,
                              apiPhotos,
                            ));
                          }

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: allPhotos,
                          );
                        },
                      );
                    },
                  ),
                    ],
                  ),
                ),

              ],
            ),
          ),
        );
      }),
    );
  }

 Widget _buildTitle(String title){
    return CustomText(
    title,
    fontSize: SizeConfig.medium,
    fontWeight: FontWeight.w600,
    color: AppColors.mainTextColor,
    );
 }

  Widget _buildCommonDivider(){
    return Container(
      color: AppColors.greyE5,
      height: 0.5,
      width: SizeConfig.screenWidth,
    );
  }

  Widget _editIcon({
    required VoidCallback onTap
}){
    return InkWell(
      onTap: onTap,
      child: LocalAssets(
        imagePath: AppIconAssets.editIcon,
        width: 14,
        height: 14,
        imgColor: AppColors.secondaryTextColor,
      ),
    );
  }

  Widget _buildImageContainer(
      BuildContext context,
      String? imagePath,
      int index,
      EarnServiceController controller,
      double size,
      List<String> allPhotos,
      ) {
    final isEmpty = imagePath == null || imagePath.isEmpty;

    return Stack(
      children: [
        GestureDetector(
          onTap: () async {
            if (isEmpty) {
              final imgStr = await SelectProfilePictureDialog.showLogoDialog(
                  context,
                  AppStrings.gallery,
                  cropAspectRatio: CropAspectRatio(width: 3, height: 4)
              );
              if (imgStr != null) {
                await controller.saveGalleryImages(imgStr);
                controller.update(['professionPhotos']);
              }
            } else {
              // View full image
              navigatePushTo(
                context,
                ImageViewScreen(
                  subTitle: '',
                  appBarTitle: AppStrings.imageViewer,
                  imageUrls: allPhotos,
                  initialIndex: index,
                ),
              );
            }
          },
          child: Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(
                color: AppColors.greyE5,
                // color: isEmpty ? AppColors.red : AppColors.greyE5,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: isEmpty ? [] : [AppShadows.textFieldShadow],
              image: !isEmpty
                  ? DecorationImage(
                image: NetworkImage(imagePath),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: isEmpty
                ? Center(
              child: LocalAssets(
                  imagePath: AppIconAssets.chat_input_gallery,
                  imgColor: AppColors.greyAF,
                  height: SizeConfig.size20,
                  width: SizeConfig.size20
              ),
            )
                : null,
          ),
        ),
        if (!isEmpty)
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () async {
                await controller.deleteProfessionImage(imagePath);
                // controller.professionData?.data?.livePhotos?.removeAt(index);
                controller.update(['professionPhotos']);
              },
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.white,
                child: Icon(Icons.close, size: 16, color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

}