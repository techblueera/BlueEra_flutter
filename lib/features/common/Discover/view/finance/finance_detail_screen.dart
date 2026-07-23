import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/common/Discover/controller/finance_discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/finance_search_res_model.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_profile_navigation.dart';
import 'package:BlueEra/features/common/Discover/view/finance/finance_job_listing_screen.dart';
import 'package:BlueEra/features/common/Discover/view/finance/widget/finance_enquiry_sheet.dart';
import 'package:BlueEra/features/me/others/controller/other_enquiry_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:BlueEra/widgets/website_preview_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class FinanceDetailScreen extends StatefulWidget {
  const FinanceDetailScreen({super.key});

  @override
  State<FinanceDetailScreen> createState() => _FinanceDetailScreenState();
}

class _FinanceDetailScreenState extends State<FinanceDetailScreen> {
  final controller = Get.find<FinanceDiscoverController>();
  Worker? _prefetchWorker;

  @override
  void initState() {
    super.initState();
    final id = controller.selectedDetail.value?.id;
    if (id != null && id.isNotEmpty) {
      controller.fetchDetail(id);
    }
    // Prefetch the server-driven enquiry chip catalog for this listing's
    // category so tapping "Book Inquiry" opens the sheet instantly. Fires
    // for both the initial selectedDetail (if set) and any post-fetch
    // update. Per-category cache in [OtherEnquiryController] makes
    // repeated calls cheap. See
    // lib/docs/predefined-enquiry-ui-integration.md §2 "Prefetch + cache".
    final enquiryCtrl = getOrPut(() => OtherEnquiryController());
    void prefetch(String? category) {
      final c = (category ?? '').trim();
      if (c.isEmpty) return;
      // ignore: unawaited_futures
      enquiryCtrl.loadPredefinedEnquiryOptions(c);
    }

    prefetch(controller.selectedDetail.value?.category);
    _prefetchWorker = ever<FinanceBusinessItem?>(
      controller.selectedDetail,
      (item) => prefetch(item?.category),
    );
  }

  @override
  void dispose() {
    _prefetchWorker?.dispose();
    super.dispose();
  }

  /// Open the finance-specific enquiry sheet. Same `/other-enquiries`
  /// wire contract as [BusinessEnquirySheet] (see
  /// `lib/docs/other-enquiry-ui-integration.md` §2) but a finance-tailored
  /// form UX with category-specific defaults. [FinanceEnquirySheet]
  /// resolves `listingId` (`data.id` → `business_id`) and `ownerId`
  /// (`data.userId`) internally.
  void _openEnquirySheet(FinanceBusinessItem data) {
    FinanceEnquirySheet.open(context, data: data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: controller.selectedDetail.value?.profileName ?? AppStrings.financeService.tr,
      ),
      bottomNavigationBar: Obx(() {
        final data = controller.selectedDetail.value;
        if (data == null || data.userId == userId) {
          return const SizedBox.shrink();
        }
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: SizeConfig.paddingS,
              right: SizeConfig.paddingS,
              bottom: 15,
              top: 10,
            ),
            child: Row(
              children: [
                // Expanded(
                //   child: PositiveCustomBtn(
                //     onTap: () {
                //       final chatViewController =
                //           Get.find<ChatViewController>();
                //       chatViewController.checkChatConnectionAndOpenChat(
                //         userId: data.userId ?? '',
                //         route: AppConstants.route_discover,
                //       );
                //     },
                //     title: AppStrings.chat,
                //   ),
                // ),
                const SizedBox(width: 10),
                Expanded(
                  child: PositiveCustomBtn(
                    onTap: () => _openEnquirySheet(data),
                    title: AppStrings.inquiry,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      body: Obx(() {
        final data = controller.selectedDetail.value;
        if (data == null) {
          if (controller.isDetailLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(child: CustomText(AppStrings.noDataFound.tr));
        }
        return SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.size12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ───
              _buildHeader(data),
              SizedBox(height: SizeConfig.size16),

              // ─── Organisation ───
              if (data.aboutOrganisation?.isNotEmpty ?? false) ...[
                _buildOrganisationSection(data.aboutOrganisation!),
                SizedBox(height: SizeConfig.size16),
              ],

              // ─── Management ───
              if (data.management?.isNotEmpty ?? false) ...[
                _buildManagementSection(data.management!),
                SizedBox(height: SizeConfig.size16),
              ],

              // ─── Our Team / Staff ───
              if (data.staff?.isNotEmpty ?? false) ...[
                _buildStaffSection(data.staff!),
                SizedBox(height: SizeConfig.size16),
              ],

              // ─── Jobs ───
              _buildJobsSection(),
              SizedBox(height: SizeConfig.size16),

              // ─── Blogs ───
              if (data.blogs?.isNotEmpty ?? false) ...[
                _buildBlogsSection(data.blogs!),
                SizedBox(height: SizeConfig.size16),
              ],

              // ─── Gallery ───
              _buildGallerySection(data.gallery),
              SizedBox(height: SizeConfig.size16),

              // ─── Contact Us ───
              _buildContactSection(data),
              SizedBox(height: SizeConfig.size16),

              // ─── Website preview ───
              WebsitePreviewCard(url: data.effectiveWebsite ?? ''),

              SizedBox(height: SizeConfig.size16),

              // ─── Location Map ───
              _buildLocationSection(data),

              SizedBox(height: kBottomNavigationBarHeight + 30),
            ],
          ),
        );
      }),
    );
  }

  // ─── HEADER ────────────────────────────────────────────────────────
  Widget _buildHeader(FinanceBusinessItem data) {
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
                  child: (data.coverUrl?.isNotEmpty ?? false)
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: data.coverUrl ?? '',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: size.height * 0.17,
                            placeholder: (ctx, _) => Container(color: Colors.blueGrey[100]),
                            errorWidget: (ctx, _, __) => Container(
                              color: Colors.blueGrey[100],
                              child: Icon(Icons.business_outlined, color: Colors.blueGrey[300], size: 40),
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(Icons.business_outlined, color: Colors.blueGrey[300], size: 40),
                        ),
                ),
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
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),
                    // Logo opens the owning business profile.
                    child: DiscoverProfileTap(
                      accountType: AppConstants.business,
                      businessId: data.businessProfileId,
                      userId: data.userId,
                      child: ClipOval(
                        child: (data.logoUrl?.isNotEmpty ?? false)
                            ? CachedNetworkImage(
                                imageUrl: data.logoUrl ?? '',
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
                ),
              ],
            ),
          ),

          // Name + category chip + location + description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DiscoverProfileTap(
                  accountType: AppConstants.business,
                  businessId: data.businessProfileId,
                  userId: data.userId,
                  child: CustomText(
                    data.profileName ?? AppStrings.unknown.tr,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (data.category?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: CustomText(
                      (data.category ?? '').replaceAll('_', ' ').capitalize ?? '',
                      fontSize: 11,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (data.location?.name?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: AppColors.secondaryTextColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: CustomText(
                          data.location!.name!,
                          fontSize: 12,
                          color: AppColors.secondaryTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (data.description?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  ExpandableText(
                    text: data.description ?? '',
                    trimLines: 2,
                    expandMode: ExpandMode.dialog,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── ORGANISATION ──────────────────────────────────────────────────
  Widget _buildOrganisationSection(List<FinanceAboutOrganisation> items) {
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.ourOrganisation),
          SizedBox(height: SizeConfig.size12),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _gradientImageCard(
                  imageUrl: item.imageUrl ?? '',
                  title: item.title ?? '',
                  subtitle: item.description ?? '',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── MANAGEMENT ────────────────────────────────────────────────────
  Widget _buildManagementSection(List<FinanceManagement> members) {
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.managementLabel),
          SizedBox(height: SizeConfig.size12),
          // Skip the bottom margin on the LAST card. Applying it to every
          // row (including the last) stacks on top of the `CommonCardWidget`'s
          // own 10px bottom padding, leaving ~20px of dead space inside
          // the card that pushed the seam to the next section to ~36px.
          ...members.asMap().entries.map((entry) {
            final isLast = entry.key == members.length - 1;
            final m = entry.value;
            return Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: m.imageUrl ?? '',
                        height: 64,
                        width: 64,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          height: 64,
                          width: 64,
                          color: Colors.grey[200],
                          child: Icon(Icons.person, color: AppColors.secondaryTextColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            m.name ?? '',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.mainTextColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((m.position ?? '').isNotEmpty || (m.qualification ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: CustomText(
                                [m.position, m.qualification].where((e) => (e ?? '').isNotEmpty).join(' • '),
                                fontSize: 12,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if ((m.message ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: CustomText(
                                m.message ?? '',
                                fontSize: 12,
                                color: AppColors.secondaryTextColor,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
          }),
        ],
      ),
    );
  }

  // ─── STAFF ─────────────────────────────────────────────────────────
  Widget _buildStaffSection(List<FinanceStaff> staffList) {
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.ourTeam),
          SizedBox(height: SizeConfig.size12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: staffList.length,
              itemBuilder: (context, index) {
                final s = staffList[index];
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.whiteE5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: s.imageUrl ?? '',
                            width: 160,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: Icon(Icons.person, size: 40, color: AppColors.secondaryTextColor),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      CustomText(
                        s.name ?? '',
                        fontWeight: FontWeight.bold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        color: AppColors.mainTextColor,
                      ),
                      CustomText(
                        s.position ?? '',
                        color: AppColors.secondaryTextColor,
                        fontSize: 12,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
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

  // ─── BLOGS ─────────────────────────────────────────────────────────
  Widget _buildBlogsSection(List<FinanceBlog> blogs) {
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.blogs),
          SizedBox(height: SizeConfig.size12),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: blogs.length,
              itemBuilder: (context, index) {
                final b = blogs[index];
                return _gradientImageCard(
                  imageUrl: b.imageUrl ?? '',
                  title: b.title ?? '',
                  subtitle: b.blog ?? '',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── GALLERY ───────────────────────────────────────────────────────
  Widget _buildGallerySection(List<FinanceGallery>? galleryList) {
    final allImages = <String>[];
    for (final g in galleryList ?? const <FinanceGallery>[]) {
      if (g.imageUrls != null) allImages.addAll(g.imageUrls!);
    }
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.gallery),
          SizedBox(height: SizeConfig.size12),
          if (allImages.isEmpty)
            EmptyStateWidget(
              message: AppStrings.noPhotosAvailableMsg.tr,
              imageSize: 60,
            )
          else
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: allImages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: allImages[index],
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[300],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ─── CONTACT US ────────────────────────────────────────────────────
  Widget _buildContactSection(FinanceBusinessItem data) {
    final contacts = data.contactUs ?? const <FinanceContactUs>[];
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.contactUs),
          SizedBox(height: SizeConfig.size12),
          if (contacts.isEmpty)
            EmptyStateWidget(
              message: AppStrings.noContactDetailsMsg.tr,
              imageSize: 60,
            )
          else
            // Skip the bottom margin on the last branch — same fix as
            // Management above: the trailing 10 stacked with the card's
            // own bottom padding, leaving dead space inside the card.
            ...contacts.asMap().entries.map((entry) => _contactBranchCard(
                  entry.value,
                  data,
                  isLast: entry.key == contacts.length - 1,
                )),
        ],
      ),
    );
  }

  Widget _contactBranchCard(
    FinanceContactUs contact,
    FinanceBusinessItem data, {
    bool isLast = false,
  }) {
    final branch = contact.branch;
    final firstDept = (contact.departments?.isNotEmpty ?? false) ? contact.departments!.first : null;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (data.logoUrl?.isNotEmpty ?? false)
                Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(right: 12),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: data.logoUrl ?? '',
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => LocalAssets(
                        imagePath: AppIconAssets.place_holder_image,
                        boxFix: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: CustomText(
                  branch?.name ?? data.profileName ?? '',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          // Branch website if set; otherwise fall back to the profile-level
          // website_url so the row still appears when the branch has none.
          Builder(builder: (_) {
            final branchWebsite = branch?.website?.trim() ?? '';
            final website = branchWebsite.isNotEmpty ? branchWebsite : (data.websiteUrl?.trim() ?? '');
            if (website.isEmpty) return const SizedBox.shrink();
            return _contactItemClickable(
              icon: AppIconAssets.website_click,
              label: website,
              iconColor: AppColors.primaryColor,
              onTap: () => _launchUrl(website),
            );
          }),
          if (firstDept?.email?.isNotEmpty ?? false)
            _contactItemClickable(
              icon: AppIconAssets.email,
              label: firstDept?.email ?? '',
              iconColor: AppColors.secondaryTextColor,
              onTap: () => _launchEmail(firstDept?.email ?? ''),
            ),
          if (firstDept?.phone?.isNotEmpty ?? false)
            _contactItemClickable(
              icon: AppIconAssets.phone_outline,
              label: firstDept?.phone ?? '',
              iconColor: AppColors.secondaryTextColor,
              onTap: () => _launchCaller(firstDept?.phone ?? ''),
            ),
          if (branch?.location?.name?.isNotEmpty ?? false)
            _contactItemClickable(
              icon: AppIconAssets.location_new,
              label: branch?.location?.name ?? '',
              iconColor: Colors.grey[700]!,
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
                  color: onTap != null ? AppColors.primaryColor : AppColors.mainTextColor,
                  fontSize: SizeConfig.medium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null)
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  // ─── LOCATION ──────────────────────────────────────────────────────
  Widget _buildLocationSection(FinanceBusinessItem data) {
    final coords = data.location?.coordinates;
    if (coords == null || coords.length < 2 || (coords[0] == 0.0 && coords[1] == 0.0)) {
      return const SizedBox.shrink();
    }
    return BusinessLocationWidget(
      locationText: data.location?.name,
      latitude: double.tryParse(coords[0].toString()) ?? 0.0,
      longitude: double.tryParse(coords[1].toString()) ?? 0.0,
      businessName: data.profileName ?? '',
      padding: 0,
      isTitleShow: true,
    );
  }

  // ─── SHARED CARD ───────────────────────────────────────────────────
  Widget _gradientImageCard({
    required String imageUrl,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 180,
              width: 250,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                height: 180,
                width: 250,
                color: Colors.grey[300],
              ),
            ),
          ),
          Container(
            height: 180,
            width: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  title,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                CustomText(
                  subtitle,
                  color: AppColors.whiteE5,
                  fontSize: 12,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── JOBS ──────────────────────────────────────────────────────────
  Widget _buildJobsSection() {
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.jobVacancy.tr),
          SizedBox(height: SizeConfig.size12),
          InkWell(
            onTap: () => Get.to(() => const FinanceJobListingScreen()),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.work_outline, size: 20, color: AppColors.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomText(
                      AppStrings.jobVacancy.tr,
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── LAUNCHERS ─────────────────────────────────────────────────────
  void _launchCaller(String number) async {
    final cleanNumber = number.replaceAll(RegExp(r'\s+\b|\b\s+'), '');
    final uri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        commonSnackBar(message: AppStrings.couldNotOpenDialer.tr);
      }
    } catch (e) {
      debugPrint("Error launching dialer: $e");
    }
  }

  void _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
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
