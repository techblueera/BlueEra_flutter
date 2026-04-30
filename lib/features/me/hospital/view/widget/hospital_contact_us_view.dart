import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_contact_us/hospital_contact_us.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';


class HospitalContactUsView extends StatelessWidget {
  final List<HospitalContacts> contacts;
  final bool isReadOnly;
  final String? description;

  const HospitalContactUsView(
      {super.key, required this.contacts, required this.isReadOnly, this.description});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: ServiceHomeTitleWidget(
                    title: AppStrings.contactUs,
                  ),
                ),
                if (!isReadOnly)
                  IconButton(
                      onPressed: () {
                        Get.to(HospitalContactUs());
                      },
                      icon: const Icon(Icons.edit_outlined, size: 20)),
              ],
            ),
            SizedBox(height: SizeConfig.paddingXSL),

            // About / Description
            if (description != null && description!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(SizeConfig.paddingS),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: SizeConfig.size16,
                            color: AppColors.primaryColor),
                        SizedBox(width: SizeConfig.paddingXS),
                        CustomText(
                          AppStrings.aboutUs,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.paddingXS),
                    ExpandableText(
                      text: description!,
                      trimLines: 3,
                      isReadMoreNewLine: false,
                      expandMode: ExpandMode.dialog,
                      style: TextStyle(
                        color: AppColors.secondaryTextColor,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        fontFamily: AppConstants.OpenSans,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: SizeConfig.paddingS),
            ],

            // Loop through the contact list from JSON
            ...contacts.map((contactData) {
              return Container(

                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  shape: const RoundedRectangleBorder(side: BorderSide.none),
                  title: CustomText(contactData.branch?.location?.name ?? "N/A",
                      fontWeight: FontWeight.bold, fontSize: 14),
                  childrenPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    // Website link
                    _buildContactItem(
                      Icons.language_outlined,
                      contactData.branch?.website ?? "",
                      isLink: true,
                      onTap: () => _launchUrl(contactData.branch?.website),
                    ),
                    // Departments loop
                    ...((contactData.departments ?? []).map((Departments dept) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Department Name/Role
                          _buildContactItem(
                              Icons.badge_outlined, dept.department ?? "N/A"),

                          // Email
                          _buildContactItem(
                            Icons.email_outlined,
                            dept.email ?? "N/A",
                            isLink: true,
                            onTap: () => _launchEmail(dept.email),
                          ),

                          // Phone Number
                          _buildContactItem(
                            Icons.phone_outlined,
                            dept.phone ?? "N/A",
                            isLink: true,
                            onTap: () => _launchPhone(dept.phone),
                          ),

                          // Add a subtle divider between departments, but not after the last one
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(
                              height: 1,
                              thickness: 0.5,
                              color: AppColors.secondaryTextColor,
                            ),
                          ),
                        ],
                      );
                    })).toList(),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text,
      {bool isLink = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: (isLink && onTap != null) ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: isLink
                    ? AppColors.primaryColor
                    : AppColors.secondaryTextColor),
            const SizedBox(width: 12),
            Expanded(
              child: CustomText(
                text,
                color:
                    isLink ? AppColors.primaryColor : AppColors.mainTextColor,
                decoration:
                    isLink ? TextDecoration.underline : TextDecoration.none,
                decorationColor:
                    isLink ? AppColors.primaryColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    String finalUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      finalUrl = 'https://$url';
    }
    try {
      await launchUrl(Uri.parse(finalUrl), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _launchEmail(String? email) async {
    if (email == null || email.isEmpty) return;
    try {
      await launchUrl(Uri(scheme: 'mailto', path: email));
    } catch (_) {}
  }

  void _launchPhone(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    try {
      await launchUrl(Uri(scheme: 'tel', path: clean));
    } catch (_) {}
  }
}
