import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widget/no_product_profile.dart';
import '../../controller/hospital_model_controller.dart';

class HospitalPreviewPage extends StatelessWidget {
  HospitalPreviewPage({super.key});

  final controller = Get.put(HospitalModelController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isAiBtnLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final hospital = controller.hospitalData.value;

      if (hospital == null) {
        return const NoProfileDetailsFound(
          content: "You have not uploaded hospital details",
        );
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: hospital.rawData.entries
              .map((entry) =>
              buildDynamicSection(context, entry.key, entry.value))
              .toList(),
        ),
      );
    });
  }
}

//////////////////////////////////////////////////////////////
/// DYNAMIC SECTION BUILDER
//////////////////////////////////////////////////////////////

Widget buildDynamicSection(
    BuildContext context, String sectionKey, dynamic sectionData) {
  final title = formatTitle(sectionKey);

  if (sectionData == null) return const SizedBox();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 10),

      if (sectionData is Map)
        ...sectionData.entries
            .map((e) => buildDynamicCard(e.key, e.value))
            .toList(),

      if (sectionData is List)
        ...sectionData.map((e) => buildDynamicCard(null, e)).toList(),

      if (sectionData is String || sectionData is num)
        buildDynamicCard(null, sectionData),

      const SizedBox(height: 20),
    ],
  );
}

//////////////////////////////////////////////////////////////
/// DYNAMIC CARD
//////////////////////////////////////////////////////////////

Widget buildDynamicCard(String? key, dynamic value) {
  return Card(
    margin: const EdgeInsets.only(bottom: 8),
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (key != null)
            Text(
              formatTitle(key),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

          if (key != null) const SizedBox(height: 6),

          if (value is Map)
            ...value.entries.map(
                  (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  "${formatTitle(e.key)} : ${formatValue(e.value)}",
                ),
              ),
            ),

          if (value is List)
            Text(value.map(formatValue).join(", ")),

          if (value is String || value is num)
            Text(value.toString()),
        ],
      ),
    ),
  );
}

//////////////////////////////////////////////////////////////
/// HELPERS
//////////////////////////////////////////////////////////////

String formatTitle(String key) {
  return key
      .replaceAll("_", " ")
      .replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
        (m) => '${m[1]} ${m[2]}',
  )
      .toUpperCase();
}

String formatValue(dynamic value) {
  if (value == null) return "-";
  if (value is String || value is num) return value.toString();
  if (value is List) return value.join(", ");
  if (value is Map) return value.toString();
  return value.toString();
}
