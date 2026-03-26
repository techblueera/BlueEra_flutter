import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/ai_professionals_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/model/ai_professionals_res_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfilePreviewScreen extends StatelessWidget {
  final controller = Get.find<AiProfessionalsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Professional Profile",
      ),
      bottomNavigationBar: SafeArea(
          child: Padding(
        padding:
            const EdgeInsets.only(bottom: 20.0, right: 20, left: 20, top: 10),
        child: PositiveCustomBtn(
            onTap: () async {
              // await controller.createServiceController();
            },
            title: "Create"),
      )),
      body: Obx(() {
        AiProfessionalsData data =
            controller.aiServiceRes?.value.data ?? AiProfessionalsData();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              // Better for Tablets/Web
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(data.basicDetails),
                  const Divider(height: 32),
                  _buildSectionTitle("About"),
                  _buildAboutSection(data.about),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Pricing & Consultation"),
                  _buildPricingCard(data.pricing),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Portfolio"),
                  ...data.portfolio!
                      .map((p) => _buildPortfolioItem(p))
                      .toList(),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader(AiProfessionalsDataBasicDetails? details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          details?.professionalTitle ?? "N/A",
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
          fontSize: SizeConfig.size25,
        ),
        const SizedBox(height: 8),
        CustomText(details?.shortTagline ?? "",
            fontStyle: FontStyle.italic, color: AppColors.secondaryTextColor),
      ],
    );
  }

  Widget _buildAboutSection(AiProfessionalsDataAbout? about) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText("Experience: ${about?.totalExperience?.years} Years",
                fontWeight: FontWeight.bold),
            const SizedBox(height: 10),
            CustomText(about?.description ?? ""),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard(AiProfessionalsDataPricing? pricing) {
    return Card(
      color: Colors.indigo[50],
      child: ListTile(
        leading: const Icon(Icons.payments, color: Colors.indigo),
        title: CustomText("₹${pricing?.amount} / ${pricing?.type}"),
        subtitle: CustomText("Mode: ${pricing?.consultationMode}"),
      ),
    );
  }

  Widget _buildPortfolioItem(AiProfessionalsDataPortfolio p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomText(p.projectTitle ?? "",
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Chip(label: CustomText(p.category ?? "", fontSize: 10)),
              ],
            ),
            const SizedBox(height: 8),
            CustomText(p.description ?? ""),
            const SizedBox(height: 8),
            CustomText("Team Size: ${p.teamSize}",
                color: AppColors.secondaryTextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: CustomText(
        title,
        fontWeight: FontWeight.bold,
        fontSize: 22,
      ),
    );
  }
}
