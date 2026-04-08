import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalFaqWidget extends StatelessWidget {
  final FAQController controller = Get.put(FAQController());

  List<Map<String, String>> get faqData => [
        {"q": AppStrings.hospitalViewFaqQ1.tr, "a": AppStrings.hospitalViewFaqA1.tr},
        {"q": AppStrings.hospitalViewFaqQ2.tr, "a": AppStrings.hospitalViewFaqA2.tr},
        {"q": AppStrings.hospitalViewFaqQ3.tr, "a": AppStrings.hospitalViewFaqA3.tr},
        {"q": AppStrings.hospitalViewFaqQ4.tr, "a": AppStrings.hospitalViewFaqA4.tr},
        {"q": AppStrings.hospitalViewFaqQ5.tr, "a": AppStrings.hospitalViewFaqA5.tr},
        {"q": AppStrings.hospitalViewFaqQ6.tr, "a": AppStrings.hospitalViewFaqA6.tr},
        {"q": AppStrings.hospitalViewFaqQ7.tr, "a": AppStrings.hospitalViewFaqA7.tr},
        {"q": AppStrings.hospitalViewFaqQ8.tr, "a": AppStrings.hospitalViewFaqA8.tr},
      ];
  @override
  Widget build(BuildContext context) {
    return CommonCardWidget(
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: faqData.length,
              separatorBuilder: (_, __) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                return Obx(() {
                  bool isExpanded = controller.expandedIndex.value == index;
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isExpanded ? Colors.blue.shade100 : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                            faqData[index]['q']!,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          trailing: Icon(
                            isExpanded ? Icons.keyboard_arrow_up : Icons.add,
                            color: Colors.black54,
                          ),
                          onTap: () => controller.toggle(index),
                        ),
                        if (isExpanded) ...[
                          Divider(height: 1, color: Colors.blue.shade50),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              faqData[index]['a']!,
                              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
                            ),
                          ),
                        ]
                      ],
                    ),
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class FAQController extends GetxController {
  // Track the index of the expanded item. -1 means all are closed.
  var expandedIndex = 0.obs;

  void toggle(int index) {
    if (expandedIndex.value == index) {
      expandedIndex.value = -1; // Close if already open
    } else {
      expandedIndex.value = index; // Open the clicked one
    }
  }
}