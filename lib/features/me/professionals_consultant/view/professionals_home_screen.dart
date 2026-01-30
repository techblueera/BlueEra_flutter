import 'dart:math';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/ai_professionals_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/model/professional_profile_res_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfessionalsHomeScreen extends StatelessWidget {
  ProfessionalsHomeScreen({super.key});

  final controller = Get.find<AiProfessionalsController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final data = controller.getProfessionalServiceRes?.value.data;
      if (data == null) {
        return const Center(child: CustomText("No Profile Data Found"));
      }
      final headerImage = _resolveHeaderImage(data);
      final videos = _extractPortfolioMedia(data, type: "video");
      final images = _extractPortfolioMedia(data, type: "image");
      return CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (headerImage != null)
                    CachedNetworkImage(
                      imageUrl: headerImage,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(color: Colors.blueGrey),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Get.back(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(SizeConfig.paddingXS),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(data),
                  SizedBox(height: SizeConfig.size12),
                  _buildChipsRow(),
                  SizedBox(height: SizeConfig.size20),
                  if (data.about?.description != null)
                    _buildSectionTitle("Overview"),
                  if (data.about?.description != null)
                    CustomText(
                      data.about?.description,
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor,
                    ),
                  SizedBox(height: SizeConfig.size20),
                  _buildSectionTitle("Our Services"),
                  _buildServicesFromAbout(data),
                  SizedBox(height: SizeConfig.size20),

                  if (videos.isNotEmpty) _buildSectionTitle("Project Videos"),
                  if (videos.isNotEmpty) _buildMediaHorizontal(videos, isVideo: true),
                  SizedBox(height: SizeConfig.size20),
                  if (images.isNotEmpty) _buildSectionTitle("Project Images"),
                  if (images.isNotEmpty) _buildMediaHorizontal(images),
                  SizedBox(height: SizeConfig.size20),
                  if ((data.certificates ?? []).isNotEmpty)
                    _buildSectionTitle("Certificate & Awards"),
                  if ((data.certificates ?? []).isNotEmpty)
                    _buildCertificates(data.certificates!),
                  SizedBox(height: SizeConfig.size20),
                  if ((data.gallery?.signedUrls ?? []).isNotEmpty)
                    _buildSectionTitle("Gallery"),
                  if ((data.gallery?.signedUrls ?? []).isNotEmpty)
                    _buildGallery(data.gallery!.signedUrls!),
                  SizedBox(height: SizeConfig.size20),
                  _buildSectionTitle("Contact Us"),
                  _buildContact(data),
                  SizedBox(height: SizeConfig.size24),
                  _buildSectionTitle("Working Hours"),
                  _buildTimings(data.timings),
                  SizedBox(height: SizeConfig.size40),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  String? _resolveHeaderImage(ProfessionalProfileData data) {
    final g = data.gallery?.signedUrls ?? [];
    if (g.isNotEmpty) return g.first;
    final certs = data.certificates ?? [];
    if (certs.isNotEmpty) return certs.first.fileUrl;
    final imgs = _extractPortfolioMedia(data, type: "image");
    if (imgs.isNotEmpty) return imgs.first;
    return null;
  }

  Widget _buildHeaderInfo(ProfessionalProfileData data) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primaryColor.withOpacity(0.1),
          child: const Icon(Icons.business, color: AppColors.primaryColor),
        ),
        SizedBox(width: SizeConfig.size12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                data.basicDetails?.professionalTitle ?? "Professional Consultant",
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: SizeConfig.size4),
              CustomText(
                data.basicDetails?.shortTagline ?? "",
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChipsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip("Home", selected: true),
          _chip("Services"),
          _chip("Projects"),
          _chip("Certificates"),
        ],
      ),
    );
  }

  Widget _chip(String label, {bool selected = false}) {
    return Container(
      margin: EdgeInsets.only(right: SizeConfig.size8),
      child: Chip(
        label: CustomText(
          label,
          color: selected ? Colors.white : AppColors.black,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
        backgroundColor: selected ? AppColors.primaryColor : AppColors.white,
        side: selected
            ? BorderSide.none
            : const BorderSide(color: Colors.grey, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
      child: CustomText(title,  fontWeight: FontWeight.w600),
    );
  }

  Widget _buildServicesFromAbout(ProfessionalProfileData data) {
    final desc = data.about?.majorProjectsDescription ?? data.about?.description ?? "";
    if (desc.isEmpty) return const SizedBox();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: CustomText(
        desc,
        color: AppColors.secondaryTextColor,
      ),
    );
  }

  List<String> _extractPortfolioMedia(ProfessionalProfileData data, {required String type}) {
    final list = <String>[];
    for (final p in data.portfolio ?? []) {
      for (final m in p.media ?? []) {
        if ((m.type ?? "").toLowerCase() == type && (m.url ?? "").isNotEmpty) {
          list.add(m.url!);
        }
      }
    }
    return list;
  }

  Widget _buildMediaHorizontal(List<String> urls, {bool isVideo = false}) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        itemBuilder: (context, index) {
          final url = urls[index];
          return Container(
            width: 260,
            margin: EdgeInsets.only(right: SizeConfig.size12),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    height: 180,
                    width: 260,
                    fit: BoxFit.cover,
                  ),
                ),
                if (isVideo)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.play_circle_fill, color: Colors.white, size: 38),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCertificates(List<Certificates> certs) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: certs.length,
        itemBuilder: (context, index) {
          final c = certs[index];
          return Container(
            width: 160,
            margin: EdgeInsets.only(right: SizeConfig.size12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: CachedNetworkImage(
                    imageUrl: c.fileUrl ?? "",
                    height: 140,
                    width: 160,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(SizeConfig.size8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        c.title ?? "",
                        fontWeight: FontWeight.w600,
                      ),
                      SizedBox(height: SizeConfig.size4),
                      CustomText(
                        c.issuedBy ?? "",
                        color: AppColors.secondaryTextColor,
                        fontSize: SizeConfig.small,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGallery(List<String> signedUrls) {
    final all = List<String>.from(signedUrls);
    all.shuffle(Random());
    final display = all.length > 6 ? all.sublist(0, 6) : all;
    return MasonryGridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      itemCount: display.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: display[index],
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  Widget _buildContact(ProfessionalProfileData data) {
    final contact = data.contact;
    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((contact?.website ?? "").isNotEmpty)
            _contactRow(Icons.language, contact!.website!, isLink: true),
          if ((contact?.phone ?? "").isNotEmpty)
            _contactRow(Icons.phone, contact!.phone!),
          if ((contact?.email ?? "").isNotEmpty)
            _contactRow(Icons.email, contact!.email!),
          if ((contact?.address ?? "").isNotEmpty)
            _contactRow(Icons.location_on, contact!.address!, color: AppColors.secondaryTextColor),
          SizedBox(height: SizeConfig.size12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Center(child: CustomText("Map View")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text, {bool isLink = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: InkWell(
              onTap: isLink ? () => launchUrl(Uri.parse(text)) : null,
              child: CustomText(
                text,
                color: color ?? AppColors.black,
                decoration: isLink ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimings(Timings? timings) {
    final monday = timings?.schedule?.monday;
    final tuesday = timings?.schedule?.tuesday;
    final wednesday = timings?.schedule?.wednesday;
    final thursday = timings?.schedule?.thursday;
    final friday = timings?.schedule?.friday;
    final saturday = timings?.schedule?.saturday;
    final sunday = timings?.schedule?.sunday;

    Widget item(String day, bool? open, String? openTime, String? closeTime) {
      final isOpen = open == true;
      final text = isOpen ? "$openTime - $closeTime" : "Closed";
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(day, fontWeight: FontWeight.w500),
          CustomText(
            text,
            color: isOpen ? Colors.green : Colors.red,
          ),
        ],
      );
    }

    return Column(
      children: [
        item("Monday", monday?.isOpen, monday?.openTime, monday?.closeTime),
        item("Tuesday", tuesday?.isOpen, tuesday?.openTime, tuesday?.closeTime),
        item("Wednesday", wednesday?.isOpen, wednesday?.openTime, wednesday?.closeTime),
        item("Thursday", thursday?.isOpen, thursday?.openTime, thursday?.closeTime),
        item("Friday", friday?.isOpen, friday?.openTime, friday?.closeTime),
        item("Saturday", saturday?.isOpen, saturday?.openTime, saturday?.closeTime),
        item("Sunday", sunday?.isOpen, sunday?.openTime, sunday?.closeTime),
      ],
    );
  }
}
