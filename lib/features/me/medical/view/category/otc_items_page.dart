import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/common_back_app_bar.dart';
import '../../../auth/model/medical_lab_details.dart';
import '../../../laboratory/model/lab_content_list_view_model.dart';
import '../../../laboratory/view/widgets/lab_category_selection_widget.dart';

class OTCItemsPage extends StatefulWidget {
  const OTCItemsPage({
    super.key,
    this.children,
  });

  /// API data (GROUP + LEAF)
  final List<MedicalLabDataListModel>? children;

  @override
  State<OTCItemsPage> createState() => _OTCItemsPageState();
}

class _OTCItemsPageState extends State<OTCItemsPage> {
  /// UI-ready list
  List<LabContentListViewModel> otcItemsList = [];

  @override
  void initState() {
    super.initState();
    loadDynamicOTCData();
  }

  /// Converts MedicalLabDataListModel → LabContentListViewModel
  void loadDynamicOTCData() {
    if (widget.children == null || widget.children!.isEmpty) {
      otcItemsList = [];
      return;
    }

    otcItemsList = widget.children!
    // Only GROUP level items
    //     .where((group) => group.type == 'GROUP')
        .map((group) {
      return LabContentListViewModel(
        name: group.name,
        children: group.children
            // ?.where((child) => child.type == 'LEAF')
            ?.map((leaf) {
          return LabContentListViewChild(
            key: leaf.key,
            name: leaf.name,
          );
        }).toList(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonBackAppBar(title: "OTC Items"),
      body: otcItemsList.isEmpty
          ? const Center(
        child: CustomText(
          "No OTC items available",
          fontSize: 14
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: otcItemsList.length,
        itemBuilder: (context, index) {
          final category = otcItemsList[index];

          if (category.children == null ||
              category.children!.isEmpty) {
            return const SizedBox.shrink();
          }

          return CategorySectionWidget(
            category: category,
          );
        },
      ),
    );
  }
}
