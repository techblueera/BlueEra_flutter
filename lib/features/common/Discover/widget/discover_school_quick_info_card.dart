import 'package:BlueEra/core/api/model/school_details_res_model.dart';
import 'package:BlueEra/core/api/model/school_quick_info_field.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Read-only Quick Info card for the school Discover detail screen.
///
/// Visually mirrors `SchoolQuickInfoCard` (the owner overview widget) but
/// sources every value from the main `GET /schools/:id` response
/// ([SchoolDetailsData.quickInfoRaw]) instead of the dedicated
/// `/schools/:id/quick-info` + `/schools/options?category=` round-trips.
/// Category (and therefore field ordering) is inferred from whichever
/// canonical whitelist has the best overlap with the returned keys, so
/// the card behaves the same for School Education, College/University,
/// Sports & Hobby, Professional Learn and Skill Training.
class DiscoverSchoolQuickInfoCard extends StatelessWidget {
  final SchoolDetailsData? data;

  const DiscoverSchoolQuickInfoCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final raw = data?.quickInfoRaw ?? const <String, dynamic>{};

    // Ordering: prefer the whitelist for whichever canonical category
    // has the most overlap with the returned keys — that mirrors the
    // per-category layout the owner widget uses. When no category
    // overlaps (unknown/new category from the backend) fall back to
    // whichever raw keys we have a display label for, in insertion
    // order.
    final rawKeys = raw.keys.toSet();
    final categoryKey = _detectCategoryFromKeys(rawKeys);
    final orderedKeys = categoryKey != null
        ? (kQuickInfoFieldsByCategory[categoryKey] ?? const <String>[])
            .where((k) => raw.containsKey(k) && _hasValue(raw[k]))
            .toList(growable: false)
        : raw.keys
            .where((k) => _kLabels.containsKey(k) && _hasValue(raw[k]))
            .toList(growable: false);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: SizedBox(
        width: Get.width,
        child: CommonCardWidget(
          padding: 12,
          cardMargin: 0,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                'Highlights',
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              SizedBox(height: SizeConfig.size12),
              if (orderedKeys.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
                  child: Center(
                    child: CustomText(
                      'No highlights found',
                      fontSize: 12,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                )
              else
                _ChipsGrid(orderedKeys: orderedKeys, values: raw),
            ],
          ),
        ),
      ),
    );
  }

  static bool _hasValue(dynamic v) {
    if (v == null) return false;
    if (v is String) return v.trim().isNotEmpty;
    if (v is List) return v.isNotEmpty;
    if (v is num) return true;
    if (v is Map) return v.isNotEmpty;
    return false;
  }

  static String? _detectCategoryFromKeys(Set<String> rawKeys) {
    String? bestKey;
    int bestScore = 0;
    for (final entry in kQuickInfoFieldsByCategory.entries) {
      final score = entry.value.where(rawKeys.contains).length;
      if (score > bestScore) {
        bestScore = score;
        bestKey = entry.key;
      }
    }
    return bestKey;
  }
}

class _ChipsGrid extends StatelessWidget {
  final List<String> orderedKeys;
  final Map<String, dynamic> values;

  const _ChipsGrid({required this.orderedKeys, required this.values});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 2-per-row grid; extra chips wrap onto subsequent rows.
        const spacing = 8.0;
        final chipWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final key in orderedKeys)
              SizedBox(
                width: chipWidth,
                child: _InfoChip(
                  icon: _iconFor(key),
                  label: _labelFor(key, values[key]),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Same compression rules as `SchoolQuickInfoCard._FilledChipsGrid`:
  /// list of one → "ICSE Boards", list of many → "2 Boards", numbers →
  /// "200 Students", strings → the raw string.
  static String _labelFor(String key, dynamic value) {
    final label = _kLabels[key] ?? _humanise(key);
    if (value is List) {
      if (value.isEmpty) return label;
      if (value.length == 1) return '${value.first} $label';
      return '${value.length} $label';
    }
    if (value is num) return '$value $label';
    final str = value?.toString() ?? '';
    return str.trim().isEmpty ? label : str;
  }
}

class _InfoChip extends StatelessWidget {
  final String icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffDDE2EE), width: 1),
      ),
      child: Column(
        children: [
          LocalAssets(
            imagePath: icon,
            imgColor: AppColors.primaryColor,
            height: 20,
            width: 20,
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            label,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.grey7E,
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

// Display labels + icons per Quick Info key. Kept aligned with
// `kQuickInfoFieldsByCategory` so every whitelisted key across the six
// education categories has a matching chip label + glyph.
const Map<String, String> _kLabels = {
  'classRange': 'Class Range',
  'studentTeacherRatio': 'Student:Teacher Ratio',
  'board': 'Boards',
  'mediumOfInstruction': 'Medium',
  'numberOfStudents': 'Students',
  'coursesOffered': 'Courses',
  'affiliatedUniversity': 'University',
  'streams': 'Streams',
  'sportsOffered': 'Sports',
  'sportsFacilities': 'Facilities',
  'achievements': 'Achievements',
  'skillPrograms': 'Programs',
  'industryPartnerships': 'Partnerships',
  'certifications': 'Certifications',
};

String _iconFor(String key) {
  switch (key) {
    case 'classRange':
      return AppIconAssets.classIcon;
    case 'board':
      return AppIconAssets.standardIcon;
    case 'mediumOfInstruction':
      return AppIconAssets.mediumIcon;
    case 'numberOfStudents':
      return AppIconAssets.multiPersonsIcon;
    case 'studentTeacherRatio':
      return AppIconAssets.personProfileIcon;
    case 'coursesOffered':
      return AppIconAssets.academic_calendar;
    case 'affiliatedUniversity':
      return AppIconAssets.affiliatedUniversityIcon;
    case 'streams':
      return AppIconAssets.streamsIcon;
    case 'sportsOffered':
      return AppIconAssets.sportsOfferedIcon;
    case 'sportsFacilities':
      return AppIconAssets.sportsFacilitiesIcon;
    case 'achievements':
      return AppIconAssets.achievementsIcon;
    case 'skillPrograms':
      return AppIconAssets.skillsIcon;
    case 'industryPartnerships':
      return AppIconAssets.industryPartnershipsIcon;
    case 'certifications':
      return AppIconAssets.certificationsIcon;
    default:
      return AppIconAssets.outlinedDocument;
  }
}

String _humanise(String key) {
  final spaced = key.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (m) => '${m[1]} ${m[2]}',
  );
  if (spaced.isEmpty) return key;
  return spaced[0].toUpperCase() + spaced.substring(1);
}
