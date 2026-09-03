import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/view/category/about_school/principal_message_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_icon_assets.dart';
import '../../../../../../widgets/local_assets.dart';

class DirectorCard extends StatelessWidget {
  const DirectorCard(
      {super.key, required this.schoolAboutUsController, this.isEdit = false});

  final SchoolAboutUsController schoolAboutUsController;
  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    final pm = schoolAboutUsController
        .schoolDetailsData?.value.aboutId?.principalMessage;
    final isEmpty = pm == null ||
        ((pm.name?.isEmpty ?? true) &&
            (pm.message?.isEmpty ?? true) &&
            (pm.photo?.isEmpty ?? true));

    if (isEmpty) {
      return Card(
        elevation: 0,
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ServiceHomeTitleWidget(title: AppStrings.principalMessage),
                  if (isEdit)
                    IconButton(
                      onPressed: () => Get.to(() => PrincipalMessageScreen()),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.person_outline,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    CustomText(
                      AppStrings.noDataFound.tr,
                      color: AppColors.secondaryTextColor,
                    ),
                    if (isEdit) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => Get.to(() => PrincipalMessageScreen()),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("Add"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryColor,
                          side: BorderSide(color: AppColors.primaryColor),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final photo = pm.photo ?? '';
    final message = pm.message ?? '';
    final name = pm.name ?? '';
    final position = pm.position ?? '';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photo.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 150,
                  height: 150,
                  child: Image.network(
                    photo,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, size: 40),
                    ),
                  ),
                ),
              ),
            if (photo.isNotEmpty) const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DirectorMessage(text: message),
                    const Spacer(),
                    // Divider(
                    //     height: 1, thickness: 1, color: Colors.grey.shade200),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 3,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomText(
                                name,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.black,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              CustomText(
                                position,
                                fontSize: 12,
                                color: AppColors.secondaryTextColor,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        if (isEdit)
                          InkWell(
                            onTap: () => Get.to(() => PrincipalMessageScreen()),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: LocalAssets(
                                imagePath: AppIconAssets.editIcon,
                                imgColor: AppColors.primaryColor,
                                height: 16,
                                width: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectorMessage extends StatelessWidget {
  final String text;
  const _DirectorMessage({required this.text});

  static const _style = TextStyle(
    color: AppColors.secondaryTextColor,
    fontSize: 15,
    fontStyle: FontStyle.italic,
    height: 1.5,
  );

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    // Estimate available width: screen - screen padding (20) - card margin (20)
    // - card padding (24) - image (150) - gap (14).
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth =
        (screenWidth - 20 - 20 - 24 - 150 - 14).clamp(80.0, double.infinity);

    final tp = TextPainter(
      text: TextSpan(text: text, style: _style),
      maxLines: 4,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: availableWidth);

    if (!tp.didExceedMaxLines) {
      return Text(text, style: _style);
    }

    final endOffset =
        tp.getPositionForOffset(Offset(tp.size.width, tp.size.height)).offset;
    final cutIndex = (endOffset - 14).clamp(0, text.length);
    final truncated = text.substring(0, cutIndex);

    return Text.rich(
      TextSpan(children: [
        TextSpan(text: '$truncated... ', style: _style),
        TextSpan(
          text: AppStrings.read_more.tr,
          style: _style.copyWith(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.normal,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  content: SingleChildScrollView(
                    child: Text(text, style: _style),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
        ),
      ]),
      maxLines: 4,
      overflow: TextOverflow.clip,
    );
  }
}
