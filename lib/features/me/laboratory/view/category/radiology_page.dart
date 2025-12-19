import 'package:flutter/material.dart';

import '../../../../../widgets/common_back_app_bar.dart';
import '../../model/lab_content_list_view_model.dart';
import '../widgets/lab_category_selection_widget.dart';
class RadiologyPage extends StatefulWidget {
  const RadiologyPage({super.key});

  @override
  State<RadiologyPage> createState() => _RadiologyPageState();
}

class _RadiologyPageState extends State<RadiologyPage> {
  List<LabContentListViewModel> radiologyStaticDataList =[];
  final List<Map<String, dynamic>> radiologyStaticList = [
    {
      "name": "XRay",
      "children": [
        {"key": "general_xray", "name": "General X-Ray"},
        {"key": "orthopedic_xray", "name": "Orthopedic X-Ray"},
        {"key": "dental_xray", "name": "Dental X-Ray"},
      ]
    },
    {
      "name": "MRI",
      "children": [
        {"key": "mri_brain", "name": "MRI Brain"},
        {"key": "mri_brain_contrast", "name": "MRI Brain with Contrast"},
        {"key": "mri_spine", "name": "MRI Spine"},
        {"key": "mri_knee", "name": "MRI Knee"},
        {"key": "mri_shoulder", "name": "MRI Shoulder"},
        {"key": "mri_hip", "name": "MRI Hip"},
        {"key": "mri_abdomen", "name": "MRI Abdomen"},
        {"key": "mri_pelvis", "name": "MRI Pelvis"},
        {"key": "mri_whole_spine", "name": "MRI Whole Spine"},
        {"key": "mr_angiography", "name": "MR Angiography"},
        {"key": "mr_venography", "name": "MR Venography"},
        {"key": "functional_mri", "name": "Functional MRI"},
      ]
    },
    {
      "name": "CT Scan",
      "children": [
        {"key": "ct_brain", "name": "CT Brain"},
        {"key": "ct_chest", "name": "CT Chest"},
        {"key": "ct_abdomen", "name": "CT Abdomen"},
        {"key": "ct_pelvis", "name": "CT Pelvis"},
        {"key": "ct_kub", "name": "CT KUB"},
        {"key": "ct_whole_abdomen", "name": "CT Whole Abdomen"},
        {"key": "ct_spine", "name": "CT Spine"},
        {"key": "ct_angiography", "name": "CT Angiography"},
        {"key": "hrct_chest", "name": "HRCT Chest"},
        {"key": "ct_sinus", "name": "CT Sinus"},
        {"key": "ct_temporal_bone", "name": "CT Temporal Bone"},
      ]
    },
    {
      "name": "Ultrasound",
      "children": [
        {"key": "usg_whole_abdomen", "name": "USG Whole Abdomen"},
        {"key": "usg_pelvis", "name": "USG Pelvis"},
        {"key": "usg_kub", "name": "USG KUB"},
        {"key": "usg_thyroid", "name": "USG Thyroid"},
        {"key": "usg_breast", "name": "USG Breast"},
        {"key": "usg_scrotum", "name": "USG Scrotum"},
        {"key": "usg_pregnancy", "name": "USG Pregnancy"},
        {"key": "usg_nt_scan", "name": "USG NT Scan"},
        {"key": "doppler_ultrasound", "name": "Doppler Ultrasound"},
      ]
    },
    {
      "name": "Doppler Studies",
      "children": [
        {"key": "colour_doppler", "name": "Colour Doppler"},
        {"key": "carotid_doppler", "name": "Carotid Doppler"},
        {"key": "venous_doppler", "name": "Venous Doppler"},
        {"key": "renal_doppler", "name": "Renal Doppler"},
        {"key": "obstetric_doppler", "name": "Obstetric Doppler"},
        {"key": "peripheral_vascular", "name": "Peripheral Vascular"},
      ]
    },
    {
      "name": "Pulmonary / Lung Imaging",
      "children": [
        {"key": "chest_xray", "name": "Chest X-Ray"},
        {"key": "hrct_chest", "name": "HRCT Chest"},
        {"key": "ct_pulmonary_angiography", "name": "CT Pulmonary Angiography"},
      ]
    },
    {
      "name": "Neuro Imaging",
      "children": [
        {"key": "mri_brain", "name": "MRI Brain"},
        {"key": "ct_brain", "name": "CT Brain"},
        {"key": "fmri", "name": "FMRI"},
        {"key": "mra_mrv", "name": "MRA / MRV"},
        {"key": "eeg", "name": "EEG"},
      ]
    },
    {
      "name": "Cardiac Imaging",
      "children": [
        {"key": "2d_echo", "name": "2D Echo"},
        {"key": "stress_echo", "name": "Stress Echo"},
        {"key": "tmt", "name": "TMT"},
        {"key": "cardiac_mri", "name": "Cardiac MRI"},
        {"key": "ct_coronary_angiography", "name": "CT Coronary Angiography"},
      ]
    },
    {
      "name": "Advanced / Special Imaging",
      "children": [
        {"key": "whole_body_mri", "name": "Whole Body MRI"},
        {"key": "whole_body_pet_ct", "name": "Whole Body PET-CT"},
        {"key": "functional_mri", "name": "Functional MRI"},
        {"key": "spectroscopy_mri", "name": "Spectroscopy MRI"},
        {"key": "ct_virtual_colonoscopy", "name": "CT Virtual Colonoscopy"},
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
      appBar: const CommonBackAppBar(title: "Radiology"),
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
