import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/business_service/controller/service_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/service_ai_generate_model.dart';

class ServiceDetailScreen extends StatefulWidget {
  final ServiceAiGenerateModel service;

  const ServiceDetailScreen({Key? key, required this.service})
      : super(key: key);

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  // Sample data provided by the user
  final serviceController = Get.find<ServiceController>();

  @override
  Widget build(BuildContext context) {
    final service = widget.service;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(
        title: service.serviceName?.capitalizeFirst,
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        // Use a column with a scrolling body; change layout subtly based on width
        final isWide = constraints.maxWidth > 600;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: isWide ? 900 : double.infinity),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card with image placeholder + quick info
                    _buildHeader(service, isWide),
                    SizedBox(height: SizeConfig.size16),

                    // Description
                    _sectionTitle('About'),
                    SizedBox(height: SizeConfig.size8),
                    CustomText(service.serviceDescription),
                    SizedBox(height: SizeConfig.size16),

                    // Facilities
                    _sectionTitle('Facilities'),
                    SizedBox(height: SizeConfig.size8),
                    _wrapChips(service.serviceFacilities ?? [],
                        icon: Icons.check),
                    SizedBox(height: SizeConfig.size16),

                    // Variants
                    _sectionTitle('Variants'),
                    SizedBox(height: SizeConfig.size8),
                    _buildVariantSelector(service.possibleVariants ?? []),
                    SizedBox(height: SizeConfig.size16),

                    // Add-ons
                    _sectionTitle('Add-ons'),
                    SizedBox(height: SizeConfig.size8),
                    _buildAddOns(service.possibleAddOns ?? []),
                    SizedBox(height: SizeConfig.size16),

                    // User Guide
                    _sectionTitle('How to prepare'),
                    SizedBox(height: SizeConfig.size8),
                    _buildUserGuide(service.userGuide ?? []),
                    SizedBox(height: SizeConfig.size24),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader(ServiceAiGenerateModel service, bool isWide) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image placeholder
            Container(
              width: isWide ? 160 : 96,
              height: isWide ? 120 : 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade200,
              ),
              child: Image.file(
                File(serviceController.selectedImage.value?.path ?? ""),
                fit: BoxFit.cover,
              ),
              // child: const Icon(Icons.directions_bike, size: 40),
            ),
            SizedBox(width: SizeConfig.size12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(service.serviceName?.capitalizeFirst,
                      fontSize: SizeConfig.large18,
                      fontWeight: FontWeight.w600),
                  SizedBox(height: SizeConfig.size6),
                  CustomText(
                    '${service.category} • ${service.subCategory}',
                    color: AppColors.secondaryTextColor,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return CustomText(text,
        fontSize: SizeConfig.large, fontWeight: FontWeight.w600);
  }

  Widget _wrapChips(List<String> items, {IconData? icon}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map((t) => FilterChip(
                label: CustomText(t),
                selected: true,
                onSelected: (bool value) {},
              ))
          .toList(),
    );
  }

  Widget _buildVariantSelector(List<String> variants) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(variants.length, (i) {
              return Padding(
                padding: EdgeInsets.only(right: SizeConfig.size8),
                child: FilterChip(
                  label: CustomText(variants[i]),
                  selected: true,
                  onSelected: (bool value) {},
                ),
              );
            }),
          ),
        ),
        SizedBox(height: SizeConfig.size8),
        PositiveCustomBtn(
            onTap: () {
              ServiceAiGenerateModel service = widget.service;
            },
            title: "Add Service"),
        SizedBox(height: SizeConfig.size8),
        // pricing mockup based on selection
      ],
    );
  }

  Widget _buildAddOns(List<String> addOns) {
    return Wrap(
      spacing: 8,
      children: addOns.map((a) {
        return FilterChip(
          label: CustomText(a),
          selected: true,
          onSelected: (bool value) {},
        );
      }).toList(),
    );
  }

  Widget _buildUserGuide(List<String> guide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: guide
          .asMap()
          .entries
          .map((e) => Padding(
                padding: EdgeInsets.symmetric(vertical: SizeConfig.size6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText('${e.key + 1}. ', fontWeight: FontWeight.bold),
                    Expanded(child: CustomText(e.value)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
