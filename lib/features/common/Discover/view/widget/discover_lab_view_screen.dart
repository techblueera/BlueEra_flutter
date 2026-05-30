import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/store/controller/store_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/Discover/view/widget/discover_lab_gallery_widget.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_profiles_list_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/new_lab_full_details_res_model.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/category_selector_widget.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/empty_health_camp_widget.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/widgets/visit_business_stats_card.dart';
import 'package:BlueEra/widgets/service_home_header_title_widget.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:BlueEra/widgets/common_rating_row.dart';
import 'package:BlueEra/widgets/website_preview_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class DiscoverLabViewScreen extends StatefulWidget {
  final LabProfileListItem detailsData;

  const DiscoverLabViewScreen({super.key, required this.detailsData});

  @override
  State<DiscoverLabViewScreen> createState() => _DiscoverLabViewScreenState();
}

class _DiscoverLabViewScreenState extends State<DiscoverLabViewScreen> {
  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();
  final storeController = getOrPut(() => StoreController());

  @override
  void initState() {
    super.initState();
    final id = widget.detailsData.id;
    if (id.isNotEmpty) {
      viewBusinessDetailsController.viewBusinessProfileById(id);
      storeController.trackStoreDetailView(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.detailsData;
    final profile = d.fullDetails?.profile;
    final tests = d.fullDetails?.tests ?? <Tests>[];
    final galleries = d.fullDetails?.galleries ?? <Galleries>[];
    final contact = d.fullDetails?.contactInfo;
    final facility = d.fullDetails?.facility;

    return Scaffold(
      appBar: CommonBackAppBar(
        title: d.name,
      ),
      bottomNavigationBar: d.fullDetails?.profile?.userId != userId
          ? SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: SizeConfig.paddingS,
                  right: SizeConfig.paddingS,
                  bottom: 15,
                  top: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: PositiveCustomBtn(
                        onTap: () async {
                          final chatViewController =
                              Get.find<ChatViewController>();
                          chatViewController.checkChatConnectionAndOpenChat(
                            userId: d.fullDetails?.profile?.userId ?? '',
                            route: AppConstants.route_discover,
                          );
                        },
                        title: AppStrings.chat,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PositiveCustomBtn(
                        onTap: () {
                          commonSnackBar(message: AppStrings.medicalComingSoonDots);
                        },
                        title: AppStrings.bookInquiry,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Section ---
            _buildHeader(d),
            SizedBox(height: SizeConfig.paddingXSL),

            Obx(() {
              // Touch profileVersion so the card rebuilds when the
              // visited profile is refreshed silently.
              viewBusinessDetailsController.profileVersion.value;
              return VisitBusinessStatsCard(
                details: viewBusinessDetailsController
                    .visitedBusinessProfileDetails
                    ?.data,
              );
            }),
            // SizedBox(height: SizeConfig.paddingXS),

            SizedBox(height: SizeConfig.paddingXSL),
            CategorySelector(labID: d.id),

            SizedBox(height: SizeConfig.paddingXSL),
            EmptyHealthCampWidget(
              isOwnProfile: false,
              labId: d.id,
            ),

            // --- Popular Services ---
            SizedBox(height: SizeConfig.paddingXSL),
            _buildPopularServices(tests),

            // --- Our All Services / Facilities ---
            SizedBox(height: SizeConfig.paddingXSL),
            _buildAllServices(facility),

            // --- Gallery ---
            SizedBox(height: SizeConfig.paddingXSL),
            DiscoverLabGalleryWidget(galleries: galleries),

            // --- Contact Us ---
            SizedBox(height: SizeConfig.paddingXSL),
            _buildContactCard(contact, profile),
            SizedBox(height: SizeConfig.paddingXS),

            /// WEBSITE PREVIEW
            WebsitePreviewCard(
              url: contact?.websiteUrl ?? '',
            ),

            // --- Location Map ---
            SizedBox(height: SizeConfig.paddingXS),
            _buildLocationSection(contact, d.fullDetails?.profile),

            SizedBox(height: kBottomNavigationBarHeight + 30),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────────────────────────────

  Widget _buildHeader(LabProfileListItem data) {
    final profile = data.fullDetails?.profile;
    final size = MediaQuery.of(context).size;

    return CommonCardWidget(
      padding: 0,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner + Logo
          SizedBox(
            height: size.height * 0.21,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner
                Container(
                  width: double.infinity,
                  height: size.height * 0.17,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[100],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: (profile?.coverUrl?.isNotEmpty ?? false)
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: profile?.coverUrl ?? "",
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: size.height * 0.17,
                            placeholder: (ctx, _) => Container(
                              color: Colors.blueGrey[100],
                            ),
                            errorWidget: (ctx, _, __) => Container(
                              color: Colors.blueGrey[100],
                              child: Icon(Icons.image_outlined,
                                  color: Colors.blueGrey[300], size: 40),
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(Icons.image_outlined,
                              color: Colors.blueGrey[300], size: 40),
                        ),
                ),

                // Logo
                Positioned(
                  bottom: 0,
                  left: 20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10)
                      ],
                    ),
                    child: ClipOval(
                      child: (profile?.logoUrl?.isNotEmpty ?? false)
                          ? CachedNetworkImage(
                              imageUrl: profile?.logoUrl ?? "",
                              fit: BoxFit.cover,
                              placeholder: (ctx, _) => LocalAssets(
                                imagePath: AppIconAssets.place_holder_image,
                                boxFix: BoxFit.cover,
                              ),
                              errorWidget: (ctx, _, __) => LocalAssets(
                                imagePath: AppIconAssets.place_holder_image,
                                boxFix: BoxFit.cover,
                              ),
                            )
                          : LocalAssets(
                              imagePath: AppIconAssets.place_holder_image,
                              boxFix: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Name & Description
          ServiceHomeHeaderTitleWidget(
            title: profile?.name ?? "",
            description:  "",
          ),

          // Rating, Reviews & Distance
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
            child: _buildRatingDistanceRow(data),
          ),
        ],
      ),
    );
  }

  // ─── RATING & DISTANCE ROW ──────────────────────────────────────────

  Widget _buildRatingDistanceRow(LabProfileListItem data) {
    final loc = data.fullDetails?.contactInfo?.location;
    String? distanceText;

    if (loc?.coordinates != null &&
        (loc?.coordinates?.length ?? 0) >= 2 &&
        LocationService.lat != 0.0 &&
        LocationService.lng != 0.0) {
      final labLat =
          double.tryParse(loc!.coordinates![1].toString()) ?? 0.0;
      final labLng =
          double.tryParse(loc.coordinates![0].toString()) ?? 0.0;
      if (labLat != 0.0 && labLng != 0.0) {
        final km = calculateDistanceKm(
          LocationService.lat,
          LocationService.lng,
          labLat,
          labLng,
        );
        distanceText = '${km.toStringAsFixed(1)} Km Away';
      }
    }

    return CommonRatingRow(
      rating: 0.0,
      reviews: 0,
      distance: distanceText,
    );
  }

  // ─── POPULAR SERVICES ───────────────────────────────────────────────

  Widget _buildPopularServices(List<Tests> tests) {
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.ourPopularServices),
          SizedBox(height: SizeConfig.size8),
          if (tests.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: EmptyStateWidget(
                message: AppStrings.noPopularServicesAvailable.tr,
                imageSize: 60,
              ),
            )
          else
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tests.length.clamp(0, 10),
                separatorBuilder: (_, __) =>
                    SizedBox(width: SizeConfig.size10),
                itemBuilder: (_, i) {
                  final t = tests[i];
                  return Container(
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: EdgeInsets.all(SizeConfig.size10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomText(
                          t.testName ?? "",
                          fontSize: SizeConfig.small,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          fontWeight: FontWeight.w500,
                        ),
                        if ((t.customerPrice ?? 0) > 0) ...[
                          const SizedBox(height: 4),
                          CustomText(
                            '\u20B9${t.customerPrice}',
                            fontSize: SizeConfig.small,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ─── ALL SERVICES / FACILITIES ──────────────────────────────────────

  Widget _buildAllServices(Facility? facility) {
    final chips = <String>[];
    if (facility?.wheelchairAssistance == true)
      chips.add(AppStrings.wheelchairAssistance.tr);
    if (facility?.doctorConsultationTieUp == true)
      chips.add(AppStrings.doctorConsultationTieUp.tr);
    if (facility?.insuranceCashlessSupport == true)
      chips.add(AppStrings.insuranceCashlessSupport.tr);
    if (facility?.homeSampleCollection == true)
      chips.add(AppStrings.homeSampleCollection.tr);
    if (facility?.digitalReport == true) chips.add(AppStrings.digitalReport.tr);

    final other = (facility?.other ?? [])
        .map((e) => e.label ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    final allChips = [...chips, ...other];

    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.ourAllServices),
          SizedBox(height: SizeConfig.size8),
          if (allChips.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: EmptyStateWidget(
                message: AppStrings.noServicesListedMsg.tr,
                imageSize: 60,
              ),
            )
          else
            _buildChipsWithViewMore(allChips),
        ],
      ),
    );
  }

  Widget _buildChipsWithViewMore(List<String> allChips) {
    final displayChips = allChips.length > 5 ? allChips.sublist(0, 5) : allChips;
    final hasMore = allChips.length > 5;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...displayChips.map((c) => _serviceChip(c)),
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
                    children: allChips.map((c) => _serviceChip(c)).toList(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: CustomText(AppStrings.medicalCloseLabel,
                          color: AppColors.primaryColor),
                    ),
                  ],
                ),
              );
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xffEAF2FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.1)),
              ),
              child: CustomText(
                '+${allChips.length - 5} View More',
                fontSize: SizeConfig.small,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _serviceChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffEAF2FF),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.primaryColor.withValues(alpha: 0.1)),
      ),
      child: CustomText(text, fontSize: SizeConfig.small),
    );
  }

  // ─── CONTACT US (clickable) ─────────────────────────────────────────

  Widget _buildContactCard(ContactInfo? contact, Profile? profile) {
    final hasContact = (contact?.email?.isNotEmpty ?? false) ||
        (contact?.phoneNo?.isNotEmpty ?? false) ||
        (contact?.websiteUrl?.isNotEmpty ?? false) ||
        (contact?.location?.name?.isNotEmpty ?? false);

    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.contactUs),
          const SizedBox(height: 12),
          if (!hasContact && (profile?.name?.isEmpty ?? true))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: EmptyStateWidget(
                message: AppStrings.noContactDetailsMsg.tr,
                imageSize: 60,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lab Logo & Name
                  Row(
                    children: [
                      if (profile?.coverUrl?.isNotEmpty ?? false)
                        Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.only(right: 12),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: profile?.coverUrl ?? '',
                              fit: BoxFit.cover,
                              placeholder: (ctx, _) => LocalAssets(
                                imagePath: AppIconAssets.place_holder_image,
                                boxFix: BoxFit.cover,
                              ),
                              errorWidget: (ctx, _, __) => LocalAssets(
                                imagePath: AppIconAssets.place_holder_image,
                                boxFix: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              profile?.name ?? '',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (profile?.description?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 8),
                    ExpandableText(text: profile?.description ?? ""),
                  ],
                  const Divider(height: 20),

                  // Clickable contact items
                  if (contact?.websiteUrl?.isNotEmpty ?? false)
                    _contactItemClickable(
                      icon: AppIconAssets.website_click,
                      label: contact?.websiteUrl ?? "",
                      iconColor: AppColors.primaryColor,
                      onTap: () => _launchUrl(contact?.websiteUrl ?? ""),
                    ),
                  if (contact?.email?.isNotEmpty ?? false)
                    _contactItemClickable(
                      icon: AppIconAssets.email,
                      label: contact?.email ?? "",
                      iconColor: AppColors.secondaryTextColor,
                      onTap: () => _launchEmail(contact?.email ?? ""),
                    ),
                  if (contact?.phoneNo?.isNotEmpty ?? false)
                    _contactItemClickable(
                      icon: AppIconAssets.phone_outline,
                      label: contact?.phoneNo ?? "",
                      iconColor: AppColors.secondaryTextColor,
                      onTap: () => _launchCaller(contact?.phoneNo ?? ""),
                    ),
                  if (contact?.location?.name?.isNotEmpty ?? false)
                    _contactItemClickable(
                      icon: AppIconAssets.location_new,
                      label: contact?.location?.name ?? "",
                      iconColor: Colors.grey[700]!,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _contactItemClickable({
    required String icon,
    required String label,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              LocalAssets(
                imagePath: icon,
                imgColor: iconColor,
                height: 20,
                width: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomText(
                  label,
                  color: onTap != null
                      ? AppColors.primaryColor
                      : AppColors.mainTextColor,
                  fontSize: SizeConfig.medium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  // ─── LOCATION ───────────────────────────────────────────────────────

  Widget _buildLocationSection(ContactInfo? contact, Profile? profile) {
    final loc = contact?.location;
    final coordinates = loc?.coordinates;

    if (coordinates == null ||
        coordinates.length < 2 ||
        coordinates[0] == 0.0 ||
        coordinates[1] == 0.0) {
      return const SizedBox.shrink();
    }

    return BusinessLocationWidget(
      locationText: "",
      latitude: double.tryParse(coordinates[1].toString()) ?? 0.0,
      longitude: double.tryParse(coordinates[0].toString()) ?? 0.0,
      businessName: loc?.name ?? "",
      padding: 0,
      isTitleShow: true,
    );
  }

  // ─── LAUNCHERS ──────────────────────────────────────────────────────

  void _launchCaller(String number) async {
    final cleanNumber = number.replaceAll(RegExp(r'\s+\b|\b\s+'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        commonSnackBar(message: AppStrings.couldNotOpenDialer.tr);
      }
    } catch (e) {
      debugPrint("Error launching dialer: $e");
    }
  }

  void _launchEmail(String email) async {
    final Uri launchUri = Uri(scheme: 'mailto', path: email);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        commonSnackBar(message: AppStrings.couldNotOpenEmail.tr);
      }
    } catch (e) {
      debugPrint("Error launching email: $e");
    }
  }

  void _launchUrl(String url) async {
    try {
      String finalUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        finalUrl = 'https://$url';
      }
      final uri = Uri.parse(finalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        commonSnackBar(message: AppStrings.couldNotOpenLink.tr);
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
    }
  }
}
