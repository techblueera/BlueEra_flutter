import 'package:flutter/material.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';

import '../../model/lab_content_list_view_model.dart';
import '../widgets/lab_category_selection_widget.dart';

class BasicBloodTestPage extends StatefulWidget {
  BasicBloodTestPage({super.key});

  @override
  State<BasicBloodTestPage> createState() => _BasicBloodTestPageState();
}

class _BasicBloodTestPageState extends State<BasicBloodTestPage> {
  List<LabContentListViewModel> basicBloodTestDataList =[];
  final List<Map<String, dynamic>> basicBloodTestStaticList = [
    {
      "name": "CBC",
      "children": [
        {"key": "hb", "name": "Hemoglobin (Hb)"},
        {"key": "blood_group", "name": "Blood Group & Rh"},
        {"key": "cbc", "name": "Complete Blood Count (CBC)"},
        {"key": "smear", "name": "Peripheral Smear"},
        {"key": "esr", "name": "ESR"},
        {"key": "pcv", "name": "PCV"},
      ]
    },
    {
      "name": "Sugar / Diabetes",
      "children": [
        {"key": "fbs", "name": "Fasting Blood Sugar (FBS)"},
        {"key": "ppbs", "name": "Post Prandial (PPBS)"},
        {"key": "rbs", "name": "Random Blood Sugar (RBS)"},
        {"key": "insulin", "name": "Insulin (Fasting / PP)"},
        {"key": "hba1c", "name": "HbA1c"},
      ]
    },
    {
      "name": "Lipid Profile (Cholesterol)",
      "children": [
        {"key": "hdl", "name": "HDL"},
        {"key": "ldl", "name": "LDL"},
        {"key": "triglycerides", "name": "Triglycerides"},
        {"key": "vldl", "name": "VLDL"},
        {"key": "total_cholesterol", "name": "Total Cholesterol"},
        {"key": "lipid_profile", "name": "Lipid Profile (Full)"},
      ]
    }
  ];
  void loadStaticData() {
    basicBloodTestDataList = basicBloodTestStaticList
        .map((e) => LabContentListViewModel.fromJson(e))
        .toList();
  }
@override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadStaticData();
  }
  @override
  Widget build(BuildContext context) {
    final list = basicBloodTestDataList;
    return Scaffold(
      appBar: const CommonBackAppBar(title: "Basic Blood Test"),
      body:  ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final category = list[index];
          if (category.children == null || category.children!.isEmpty) {
            return const SizedBox.shrink();
          }
          return CategorySectionWidget(category: category,);
        },
      ),
    );
  }

}
