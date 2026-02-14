import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_profiles_list_controller.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LabProfilesListScreen extends StatefulWidget {
  const LabProfilesListScreen({super.key});

  @override
  State<LabProfilesListScreen> createState() => _LabProfilesListScreenState();
}

class _LabProfilesListScreenState extends State<LabProfilesListScreen> {
  late final LabProfilesListController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => LabProfilesListController());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      controller.fetchMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Material(
      color: AppColors.appBackgroundColor,
      child: Obx(() {
        if (controller.isLoading.value && controller.profiles.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor));
        }
        if (controller.error.value.isNotEmpty && controller.profiles.isEmpty) {
          return Center(
            child: CustomText(
              "Failed to load data",
              fontSize: SizeConfig.medium,
              color: AppColors.red,
            ),
          );
        }
        if (controller.profiles.isEmpty) {
          return Center(
            child: CustomText(
              "No laboratories found",
              fontSize: SizeConfig.medium,
              color: AppColors.grey9B,
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: controller.fetchInitial,
          child: ListView.builder(
            controller: _scrollController,
            // padding: EdgeInsets.all(SizeConfig.paddingM),
            itemCount: controller.profiles.length +
                (controller.isLoadingMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= controller.profiles.length) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
                  child: const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryColor)),
                );
              }
              final item = controller.profiles[index];
              return _LabCard(item: item);
            },
          ),
        );
      }),
    );
  }
}

class _LabCard extends StatelessWidget {
  final LabProfileListItem item;
  const _LabCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => _openDetailsSheet(context, item),
        child: CommonCardWidget(
          cardMargin: 0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(SizeConfig.size12),
                child: Container(
                  width: SizeConfig.size60,
                  height: SizeConfig.size60,
                  color: AppColors.liteWhite,
                  child: item.logoUrl.isNotEmpty
                      ? Image.network(
                          item.logoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Icon(Icons.image,
                              color: AppColors.placeHolder,
                              size: SizeConfig.size32),
                        )
                      : Icon(Icons.image,
                          color: AppColors.placeHolder, size: SizeConfig.size32),
                ),
              ),
              SizedBox(width: SizeConfig.size12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomText(
                            item.name.isNotEmpty ? item.name : "Unknown",
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mainTextColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.more_vert, color: AppColors.grey9B, size: 20),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size6),
                    CustomText(
                      item.description.isNotEmpty
                          ? item.description
                          : "No description available",
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: SizeConfig.size6),
                    CustomText(
                      "Open: 9:00 AM",
                      fontSize: SizeConfig.small,
                      color: AppColors.green00,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetailsSheet(BuildContext context, LabProfileListItem item) {
    final data = item.fullDetails;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.98,
          builder: (context, scrollController) {
            return Material(
              color: AppColors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 8, bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.whiteE5,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  if ((item.coverUrl).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: SizeConfig.size160,
                          width: double.infinity,
                          child: CachedNetworkImage(
                            imageUrl: item.coverUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.logoUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: CachedNetworkImage(
                                imageUrl: item.logoUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        SizedBox(width: SizeConfig.size10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                item.name,
                                fontWeight: FontWeight.w700,
                                fontSize: SizeConfig.large,
                                color: AppColors.mainTextColor,
                              ),
                              SizedBox(height: 4),
                              if (item.description.isNotEmpty)
                                CustomText(
                                  item.description,
                                  color: AppColors.secondaryTextColor,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data?.contactInfo?.location?.name?.isNotEmpty == true ||
                              data?.contactInfo?.phoneNo?.isNotEmpty == true ||
                              data?.contactInfo?.email?.isNotEmpty == true ||
                              data?.contactInfo?.websiteUrl?.isNotEmpty == true)
                            _section(
                              title: "Contact",
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (data?.contactInfo?.location?.name?.isNotEmpty == true)
                                    _kv("Address", data!.contactInfo!.location!.name!),
                                  if (data?.contactInfo?.phoneNo?.isNotEmpty == true)
                                    _kv("Phone", data!.contactInfo!.phoneNo!),
                                  if (data?.contactInfo?.email?.isNotEmpty == true)
                                    _kv("Email", data!.contactInfo!.email!),
                                  if (data?.contactInfo?.websiteUrl?.isNotEmpty == true)
                                    _kv("Website", data!.contactInfo!.websiteUrl!),
                                ],
                              ),
                            ),
                          if ((data?.tests?.isNotEmpty ?? false))
                            _section(
                              title: "Tests",
                              child: Column(
                                children: data!.tests!.map((t) {
                                  final price = t.customerPrice ?? t.testFees;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: CustomText(
                                            t.testName ?? '-',
                                            color: AppColors.mainTextColor,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (price != null)
                                          CustomText(
                                            "₹ $price",
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryColor,
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          if ((data?.facility?.homeSampleCollection ?? false) ||
                              (data?.facility?.digitalReport ?? false) ||
                              (data?.facility?.doctorConsultationTieUp ?? false) ||
                              (data?.facility?.insuranceCashlessSupport ?? false) ||
                              (data?.facility?.wheelchairAssistance ?? false) ||
                              (data?.facility?.other?.isNotEmpty ?? false))
                            _section(
                              title: "Facilities",
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _facility("Home Sample Collection", data?.facility?.homeSampleCollection == true),
                                  _facility("Digital Report", data?.facility?.digitalReport == true),
                                  _facility("Doctor Consultation Tie-up", data?.facility?.doctorConsultationTieUp == true),
                                  _facility("Insurance Cashless Support", data?.facility?.insuranceCashlessSupport == true),
                                  _facility("Wheelchair Assistance", data?.facility?.wheelchairAssistance == true),
                                  if (data?.facility?.other?.isNotEmpty == true) ...[
                                    SizedBox(height: 8),
                                    ...data!.facility!.other!.map((o) => _kv(o.label ?? '-', o.details ?? '')).toList(),
                                  ]
                                ],
                              ),
                            ),
                          if ((data?.galleries?.isNotEmpty ?? false))
                            _section(
                              title: "Gallery",
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final g in data!.galleries!)
                                    for (final url in (g.imageUrls ?? []))
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          width: 80,
                                          height: 80,
                                          child: CachedNetworkImage(
                                            imageUrl: url,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            title,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: CustomText(
              k,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w600,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: CustomText(
              v,
              color: AppColors.mainTextColor,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _facility(String name, bool enabled) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.radio_button_unchecked,
            color: enabled ? AppColors.green00 : AppColors.whiteE5,
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: CustomText(
              name,
              color: AppColors.mainTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
