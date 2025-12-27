import 'package:flutter/material.dart';

import '../../../../../widgets/common_back_app_bar.dart';
import '../../model/lab_content_list_view_model.dart';
import '../widgets/lab_category_selection_widget.dart';
class OphthalmologyENTPage extends StatefulWidget {
  const OphthalmologyENTPage({super.key});

  @override
  State<OphthalmologyENTPage> createState() => _OphthalmologyENTPageState();
}

class _OphthalmologyENTPageState extends State<OphthalmologyENTPage> {
  List<LabContentListViewModel> ophthalmologyENTDataList =[];

  final List<Map<String, dynamic>> ophthalmologyENTList = [
    {
      "name": "Refraction Test",
      "children": [
        {"key": "retinoscopy", "name": "Retinoscopy", "image": "assets/images/retinoscopy.png"},
        {"key": "auto_refraction", "name": "Auto-Refraction", "image": "assets/images/auto_refraction.png"},
      ]
    },
    {
      "name": "Fundus Examination",
      "children": [
        {"key": "direct_opthalmoscopy", "name": "Direct Ophthalmoscopy", "image": "assets/images/direct_opthalmoscopy.png"},
        {"key": "indirect_opthalmoscopy", "name": "Indirect Ophthalmoscopy", "image": "assets/images/indirect_opthalmoscopy.png"},
        {"key": "slit_lamp", "name": "Slit-Lamp Method", "image": "assets/images/slit_lamp.png"},
        {"key": "fundus_photography", "name": "Fundus Photography", "image": "assets/images/fundus_photography.png"},
      ]
    },
    {
      "name": "OCT",
      "children": [
        {"key": "onh_oct", "name": "(ONH) OCT", "image": "assets/images/onh_oct.png"},
        {"key": "rnfl_oct", "name": "RNFL OCT", "image": "assets/images/rnfl_oct.png"},
        {"key": "gca", "name": "GCA", "image": "assets/images/gca.png"},
        {"key": "anterior_segment_oct", "name": "Anterior Segment OCT", "image": "assets/images/anterior_segment_oct.png"},
      ]
    },
    {
      "name": "Visual Field Test",
      "children": [
        {"key": "humphrey_visual_field", "name": "Humphrey Visual Field (HVF)", "image": "assets/images/hvf.png"},
      ]
    },
    {
      "name": "Audiometry",
      "children": [
        {"key": "impedance_audiometry", "name": "Impedance Audiometry", "image": "assets/images/impedance.png"},
        {"key": "special_audiometric", "name": "Special Audiometric", "image": "assets/images/special_audiometric.png"},
        {"key": "objective_audiometry", "name": "Objective Audiometry", "image": "assets/images/objective_audiometry.png"},
        {"key": "screening_audiometry", "name": "Screening Audiometry", "image": "assets/images/screening.png"},
        {"key": "functional_field", "name": "Functional / Free Field Audiometry", "image": "assets/images/functional_field.png"},
        {"key": "occupational_audiometry", "name": "Occupational Audiometry", "image": "assets/images/occupational.png"},
        {"key": "speech_audiometry", "name": "Speech Audiometry", "image": "assets/images/speech.png"},
      ]
    },
    {
      "name": "Tympanometry",
      "children": [
        {"key": "type_a", "name": "Type A", "image": "assets/images/type_a.png"},
        {"key": "type_as", "name": "Type As", "image": "assets/images/type_as.png"},
        {"key": "type_ad", "name": "Type Ad", "image": "assets/images/type_ad.png"},
        {"key": "type_b", "name": "Type B", "image": "assets/images/type_b.png"},
        {"key": "type_c", "name": "Type C", "image": "assets/images/type_c.png"},
      ]
    },
    {
      "name": "Endoscopy (Nasal/Laryngeal)",
      "children": [
        {"key": "upper_gastrointestinal", "name": "Upper Gastrointestinal", "image": "assets/images/upper_gi.png"},
        {"key": "lower_gastrointestinal", "name": "Lower Gastrointestinal", "image": "assets/images/lower_gi.png"},
        {"key": "respiratory_endoscopy", "name": "Respiratory Endoscopy", "image": "assets/images/respiratory.png"},
        {"key": "urogenital_endoscopy", "name": "Urogenital Endoscopy", "image": "assets/images/urogenital.png"},
        {"key": "gynecological_endoscopy", "name": "Gynecological Endoscopy", "image": "assets/images/gynecological.png"},
        {"key": "musculoskeletal_endoscopy", "name": "Musculoskeletal Endoscopy", "image": "assets/images/musculoskeletal.png"},
        {"key": "abdominal_surgical", "name": "Abdominal / Surgical", "image": "assets/images/abdominal.png"},
      ]
    },
  ];
  void loadStaticData() {
    ophthalmologyENTDataList = ophthalmologyENTList
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
    final list = ophthalmologyENTDataList;
    return Scaffold(
      appBar: const CommonBackAppBar(title: "Ophthalmology & ENT"),
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
