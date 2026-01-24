import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';

import '../../model/lab_content_list_view_model.dart';
import '../widgets/lab_category_selection_widget.dart';


class PathologyTestsPage extends StatefulWidget {
  const PathologyTestsPage({super.key});

  @override
  State<PathologyTestsPage> createState() => _PathologyTestsPageState();
}

class _PathologyTestsPageState extends State<PathologyTestsPage> {
  List<LabContentListViewModel> pathologyCategoryList = [];

  final List<Map<String, dynamic>> pathologyStaticList = [
    {
      "name": "Liver Function Tests (LFT)",
      "children": [
        {"key": "sgot", "name": "SGOT (AST)"},
        {"key": "sgpt", "name": "SGPT (ALT)"},
        {"key": "alp", "name": "ALP"},
        {"key": "bilirubin", "name": "Bilirubin"},
        {"key": "total_protein", "name": "Total Protein"},
        {"key": "albumin_globulin", "name": "Albumin/Globulin"},
        {"key": "lft_panel", "name": "LFT - Complete Panel"},
      ]
    },
    {
      "name": "Kidney / Renal Function Tests (RFT)",
      "children": [
        {"key": "serum_creatinine", "name": "Serum Creatinine"},
        {"key": "blood_urea", "name": "Blood Urea"},
        {"key": "uric_acid", "name": "Uric Acid"},
        {"key": "bun", "name": "BUN"},
        {"key": "sodium", "name": "Sodium"},
        {"key": "potassium", "name": "Potassium"},
        {"key": "chloride", "name": "Chloride"},
        {"key": "rft_panel", "name": "KFT / RFT - Complete"},
      ]
    },
    {
      "name": "Thyroid Tests",
      "children": [
        {"key": "t3", "name": "T3"},
        {"key": "t4", "name": "T4"},
        {"key": "tsh", "name": "TSH"},
        {"key": "free_t3", "name": "Free T3"},
        {"key": "free_t4", "name": "Free T4"},
        {"key": "thyroid_profile", "name": "Thyroid Profile"},
      ]
    },
    {
      "name": "Infection & Fever Tests",
      "children": [
        {"key": "dengue", "name": "Dengue"},
        {"key": "malaria", "name": "Malaria"},
        {"key": "typhoid", "name": "Typhoid"},
        {"key": "chikungunya", "name": "Chikungunya"},
        {"key": "covid_rt_pcr", "name": "COVID-19 RT-PCR"},
        {"key": "covid_antigen", "name": "COVID Rapid Antigen"},
        {"key": "crp", "name": "CRP"},
        {"key": "procalcitonin", "name": "Procalcitonin"},
      ]
    },
    {
      "name": "Vitamin & Nutrition Tests",
      "children": [
        {"key": "vitamin_d", "name": "Vitamin D (25-OH)"},
        {"key": "vitamin_b12", "name": "Vitamin B12"},
        {"key": "iron_studies", "name": "Iron Studies"},
        {"key": "ferritin", "name": "Ferritin"},
        {"key": "calcium", "name": "Calcium"},
        {"key": "phosphorus", "name": "Phosphorus"},
        {"key": "magnesium", "name": "Magnesium"},
      ]
    },
    {
      "name": "Hormone Tests",
      "children": [
        {"key": "testosterone", "name": "Testosterone"},
        {"key": "estrogen", "name": "Estrogen"},
        {"key": "progesterone", "name": "Progesterone"},
        {"key": "lh", "name": "LH"},
        {"key": "fsh", "name": "FSH"},
        {"key": "prolactin", "name": "Prolactin"},
        {"key": "cortisol", "name": "Cortisol"},
        {"key": "amh", "name": "AMH"},
        {"key": "dheas", "name": "DHEA-S"},
      ]
    },
    {
      "name": "Pregnancy & Fertility Tests",
      "children": [
        {"key": "pregnancy_test", "name": "Pregnancy Test"},
        {"key": "double_marker", "name": "Double Marker"},
        {"key": "triple_marker", "name": "Triple Marker"},
        {"key": "quadruple_marker", "name": "Quadruple Marker"},
        {"key": "torch", "name": "TORCH Profile"},
        {"key": "amh_test", "name": "AMH Test"},
        {"key": "semen_analysis", "name": "Semen Analysis"},
      ]
    },
    {
      "name": "Urine Tests (मूत्र जाँच)",
      "children": [
        {"key": "urine_routine", "name": "Urine Routine"},
        {"key": "urine_microscopy", "name": "Urine Microscopy"},
        {"key": "urine_culture", "name": "Urine Culture"},
        {"key": "urine_sugar", "name": "Urine Sugar"},
        {"key": "urine_ketone", "name": "Urine Ketone"},
        {"key": "pregnancy_urine", "name": "Pregnancy Test"},
        {"key": "urine_24h_protein", "name": "24 Hours Urine Protein"},
        {"key": "microalbumin", "name": "Microalbumin"},
      ]
    },
    {
      "name": "Stool Tests",
      "children": [
        {"key": "stool_routine", "name": "Stool Routine"},
        {"key": "stool_occult_blood", "name": "Stool Occult Blood"},
        {"key": "stool_culture", "name": "Stool Culture"},
        {"key": "ova_parasite", "name": "Ova & Parasite"},
        {"key": "h_pylori", "name": "H. Pylori (Stool)"},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    pathologyCategoryList = pathologyStaticList
        .map((e) => LabContentListViewModel.fromJson(e))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonBackAppBar(title: "Pathology"),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: pathologyCategoryList.length,
        itemBuilder: (context, index) {
          final category = pathologyCategoryList[index];
          return CategorySectionWidget(category: category);
        },
      ),
    );
  }
}
