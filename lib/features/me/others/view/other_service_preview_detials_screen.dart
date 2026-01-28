import 'package:BlueEra/features/me/others/controller/business_profile_full_controller.dart';
import 'package:BlueEra/features/me/others/model/ai_other_service_res_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
// Import your model and custom text widget paths here
// import 'path_to_your_model/ai_other_service_res_model.dart';
// import 'path_to_your_custom_text/custom_text.dart';

class OtherServicePreviewDetailsScreen extends StatelessWidget {
  final AiOtherServiceResData? data = Get.find<BusinessProfileFullController>().aiOtherServiceRes?.value.data;

  @override
  Widget build(BuildContext context) {
    if (data == null) return const Scaffold(body: Center(child: Text("No Data Available")));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar:CommonBackAppBar(title: "Service Preview",),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(right: 20.0,left: 20,bottom: 30,top: 10),
          child: PositiveCustomBtn(onTap: () async {
            await Get.find<BusinessProfileFullController>().createOtherProfileController();
          }, title: "Create Profile"),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Section ---
            CustomText(data?.name ?? "", fontSize: 24, fontWeight: FontWeight.bold),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                CustomText("${data?.rating} • Professional", fontSize: 16, fontWeight: FontWeight.w500),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoTile(Icons.location_on, data?.address ?? ""),
            _buildInfoTile(Icons.access_time, data?.timing ?? ""),
            _buildInfoTile(Icons.language, data?.websiteUrl ?? ""),

            const Divider(height: 32),

            // --- Announcements Section ---
            if (data?.announcements?.isNotEmpty ?? false) ...[
              _buildSectionTitle("Special Offers"),
              ...data!.announcements!.map((offer) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(offer.title ?? "", fontSize: 16, fontWeight: FontWeight.bold),
                    Text(offer.content ?? "", style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              )).toList(),
            ],

            // --- Services List ---
            _buildSectionTitle("Our Services"),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data?.services?.length ?? 0,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final service = data!.services![index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(service.title ?? "", fontSize: 16, fontWeight: FontWeight.bold),
                              const SizedBox(height: 4),
                              Text(service.description ?? "", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                        ),
                        CustomText(service.price ?? "", fontSize: 16, fontWeight: FontWeight.bold),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // --- Gallery Section ---
            _buildSectionTitle("Gallery"),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: data?.gallery?.length ?? 0,
                itemBuilder: (context, index) {
                  return Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      data!.gallery![index], // Displaying string description since it's not a URL
                      style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // --- About Us ---
            _buildSectionTitle("About Us"),
            CustomText(data?.aboutUs?.organisation ?? "", ),
            const SizedBox(height: 16),
            CustomText("Facilities:", fontSize: 16, fontWeight: FontWeight.bold),
            Wrap(
              spacing: 8,
              children: (data?.aboutUs?.officeFacility ?? [])
                  .map((e) => Chip(label: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
            ),

            const SizedBox(height: 32),

            // --- Careers ---
            if (data?.careers?.isNotEmpty ?? false) ...[
              _buildSectionTitle("Join Our Team"),
              ...data!.careers!.map((job) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: CustomText(job.title ?? "", fontSize: 16, fontWeight: FontWeight.bold),
                subtitle: Text("${job.type} • ${job.description}"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              )).toList(),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: CustomText(title, fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoTile(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}