import 'package:flutter/material.dart';

import '../../../../../widgets/common_back_app_bar.dart';
import '../../../laboratory/model/lab_content_list_view_model.dart';
import '../../../laboratory/view/widgets/lab_category_selection_widget.dart';
class OTCItemsPage extends StatefulWidget {
  const OTCItemsPage({super.key});

  @override
  State<OTCItemsPage> createState() => _OTCItemsPageState();
}

class _OTCItemsPageState extends State<OTCItemsPage> {
  List<LabContentListViewModel> otcItemsList = [];
  final List<Map<String, dynamic>> otcItemsStaticList = [
    {
      "name": "Pain, Fever & Cold Relief",
      "children": [
        {"key": "pain_relief", "name": "Pain Relief Tablets"},
        {"key": "fever", "name": "Fever Tablets"},
        {"key": "headache", "name": "Headache Tablets"},
        {"key": "body_pain", "name": "Body Pain Tablets"},
        {"key": "beans_peas", "name": "Beans & Peas"},
        {"key": "cabbage", "name": "Cabbage, Cauli & Broccoli"},
        {"key": "capsicum", "name": "Capsicum, Chilli & Corn"},
        {"key": "exotic_veg", "name": "Exotic Vegetables"},
      ]
    },
    {
      "name": "Green & Leafy",
      "children": [
        {"key": "spinach", "name": "Spinach (Palak)"},
        {"key": "fenugreek", "name": "Fenugreek (Methi)"},
        {"key": "coriander", "name": "Coriander & Mint"},
        {"key": "lettuce", "name": "Lettuce & Salad Greens"},
        {"key": "spring_onion", "name": "Spring Onion"},
      ]
    },
    {
      "name": "Seasonal Vegetables",
      "children": [
        {"key": "summer", "name": "Summer Vegetables"},
        {"key": "winter", "name": "Winter Vegetables"},
        {"key": "monsoon", "name": "Monsoon Vegetables"},
      ]
    },
  ];

  void loadStaticData() {
    otcItemsList = otcItemsStaticList
        .map((e) => LabContentListViewModel.fromJson(e))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    loadStaticData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonBackAppBar(title: "OTC Items"),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: otcItemsList.length,
        itemBuilder: (context, index) {
          final category = otcItemsList[index];
          if (category.children == null || category.children!.isEmpty) {
            return const SizedBox.shrink();
          }
          return CategorySectionWidget(category: category);
        },
      ),
    );
  }
}
