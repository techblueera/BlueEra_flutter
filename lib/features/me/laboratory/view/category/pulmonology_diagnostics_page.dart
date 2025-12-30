import 'package:flutter/material.dart';

import '../../../../../widgets/common_back_app_bar.dart';
import '../../model/lab_content_list_view_model.dart';
import '../widgets/lab_category_selection_widget.dart';
class PulmonologyDiagnosticsPage extends StatefulWidget {
  const PulmonologyDiagnosticsPage({super.key});

  @override
  State<PulmonologyDiagnosticsPage> createState() => _PulmonologyDiagnosticsPageState();
}

class _PulmonologyDiagnosticsPageState extends State<PulmonologyDiagnosticsPage> {
  List<LabContentListViewModel> radiologyStaticDataList =[];
  final List<Map<String, dynamic>> radiologyStaticList = [
    {
      "name": "Spirometry – Asthma, COPD",
      "children": [
        {"key": "peak_flowMeter", "name": "Peak FlowMeter"},
        {"key": "lung_volumes", "name": "Lung Volumes"},
        {"key": "DLCO", "name": "DLCO"},
      ]
    },

  ];

  @override
  void initState() {
    super.initState();
    radiologyStaticDataList = radiologyStaticList
        .map((e) => LabContentListViewModel.fromJson(e))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonBackAppBar(title: "Pulmonology Diagnostics"),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: radiologyStaticDataList.length,
        itemBuilder: (context, index) {
          final category = radiologyStaticDataList[index];
          return CategorySectionWidget(category: category);
        },
      ),
    );
  }
}
