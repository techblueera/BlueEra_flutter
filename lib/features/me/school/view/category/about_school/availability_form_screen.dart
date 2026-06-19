import 'package:BlueEra/core/api/model/school_details_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_availability_view.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AvailabilityFormScreen extends StatefulWidget {
  const AvailabilityFormScreen({super.key});

  @override
  State<AvailabilityFormScreen> createState() => _AvailabilityFormScreenState();
}

class _AvailabilityFormScreenState extends State<AvailabilityFormScreen> {
  final SchoolAboutUsController _controller = Get.find<SchoolAboutUsController>();

  late final List<Availability> _slots;

  @override
  void initState() {
    super.initState();
    final existing = _controller.schoolDetailsData?.value.availability ?? const [];
    _slots = kSchoolWeekDays.map((day) {
      final match = existing.firstWhereOrNull(
        (a) => (a.day ?? '').toLowerCase() == day.toLowerCase(),
      );
      return Availability(
        day: day,
        isOpen: match?.isOpen ?? false,
        openTime: match?.openTime ?? '10:00',
        closeTime: match?.closeTime ?? '10:00',
      );
    }).toList();
  }

  Future<void> _pickTime(int index, {required bool isOpenTime}) async {
    final current = isOpenTime ? _slots[index].openTime : _slots[index].closeTime;
    final parts = (current ?? '10:00').split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 10,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;
    final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (isOpenTime) {
        _slots[index].openTime = formatted;
      } else {
        _slots[index].closeTime = formatted;
      }
    });
  }

  void _onSave() {
    _controller.schoolDetailsData?.value.availability = _slots;
    _controller.schoolDetailsData?.refresh();
    Get.back(result: _slots);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
        title: "Set Your School Timing",
        isShadowShow: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(SizeConfig.size12),
                child: CommonCardWidget(
                  padding: 14,
                  cardMargin: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        "Set Your School Timing",
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      SizedBox(height: SizeConfig.size12),
                      for (int i = 0; i < _slots.length; i++)
                        _DayEditRow(
                          slot: _slots[i],
                          onToggle: (v) => setState(() => _slots[i].isOpen = v),
                          onPickOpen: () => _pickTime(i, isOpenTime: true),
                          onPickClose: () => _pickTime(i, isOpenTime: false),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(SizeConfig.size12),
              child: CustomBtn(
                onTap: _onSave,
                title: AppStrings.save.tr,
                bgColor: AppColors.primaryColor,
                textColor: AppColors.white,
                radius: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayEditRow extends StatelessWidget {
  final Availability slot;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickOpen;
  final VoidCallback onPickClose;

  const _DayEditRow({
    required this.slot,
    required this.onToggle,
    required this.onPickOpen,
    required this.onPickClose,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = slot.isOpen ?? false;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size6),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: CustomText(
              slot.day ?? '',
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: isOpen,
              activeTrackColor: AppColors.primaryColor,
              activeColor: AppColors.white,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: onToggle,
            ),
          ),
          SizedBox(width: SizeConfig.size4),
          SizedBox(
            width: 50,
            child: CustomText(
              isOpen ? 'Open' : 'Closed',
              fontSize: 12,
              color: isOpen ? AppColors.greenShade : AppColors.grey83,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          _TimeField(
            time: slot.openTime ?? '10:00',
            enabled: isOpen,
            onTap: onPickOpen,
          ),
          SizedBox(width: SizeConfig.size6),
          _TimeField(
            time: slot.closeTime ?? '10:00',
            enabled: isOpen,
            onTap: onPickClose,
          ),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String time;
  final bool enabled;
  final VoidCallback onTap;

  const _TimeField({
    required this.time,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.fillColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.whiteE0),
        ),
        alignment: Alignment.center,
        child: CustomText(
          time,
          fontSize: 12,
          color: enabled ? AppColors.grey44 : AppColors.greyB4,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
