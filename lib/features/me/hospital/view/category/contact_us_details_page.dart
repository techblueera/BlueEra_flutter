import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../../../../core/constants/getx_utils.dart';
import '../../controller/hospital_model_controller.dart';

class ContactUsDetailsPage extends StatefulWidget {
  const ContactUsDetailsPage({super.key, this.data, this.title});

  final Map<String, dynamic>? data;
  final String? title;

  @override
  State<ContactUsDetailsPage> createState() => _ContactUsDetailsPageState();
}

class _ContactUsDetailsPageState extends State<ContactUsDetailsPage> {
  final controller = getOrPut(() => HospitalModelController());

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    List<dynamic>? coordinates = widget.data?['location']["coordinates"];
    controller.fetchAddressByLatLng(
        lat: coordinates?.last, lng: coordinates?.first);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.title,
      ),
      body: Obx(() {
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.data?.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// KEY
                      CustomText(
                        _formatKey(entry.key),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),

                      /// VALUE
                      CustomText(
                      (entry.key=='location')?controller.hospitalCurrentAddress.value:entry.value?.toString() ?? '-',
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ],
                  ),
                );
              }).toList() ??
                  [
                    const CustomText("No data available"),
                  ],
            ),
          ),
        );
      }),
    );
  }

  /// 🔥 Converts `emergencyPhone` → `Emergency Phone`
  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAllMapped(
      RegExp(r'[A-Z]'),
          (match) => ' ${match.group(0)}',
    )
        .split(' ')
        .map((e) =>
    e.isEmpty ? '' : e[0].toUpperCase() + e.substring(1))
        .join(' ')
        .trim();
  }
}
