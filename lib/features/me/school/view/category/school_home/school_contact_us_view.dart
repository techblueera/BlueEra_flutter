import 'package:BlueEra/core/api/model/school_details_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/me/school/view/category/school_contact_us/school_contact_us.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/api/model/school_contact_us_res_model.dart';

class ContactUsSection extends StatelessWidget {
  final List<Contacts> contacts;
  final bool isEdit;

  ContactUsSection({super.key, required this.contacts, required this.isEdit});

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
            SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ServiceHomeTitleWidget(
                  title: "Contact Us",
                ),
                if (isEdit)
                  IconButton(
                      onPressed: () {
                        Get.to(SchoolContactUs());
                      },
                      icon: const Icon(Icons.edit_outlined, size: 20)),
              ],
            ),
            const SizedBox(height: 8),
            // Loop through the contact list from JSON
            ...contacts.map((contactData) {
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ExpansionTile(
                  shape: const RoundedRectangleBorder(side: BorderSide.none),
                  title: CustomText(contactData.branch?.name ?? "N/A",
                      fontWeight: FontWeight.bold, fontSize: 15),
                  childrenPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    // Website link
                    _buildContactItem(
                      Icons.language_outlined,
                      contactData.branch?.website ?? "",
                      isLink: true,
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
                          ),

                          // Phone Number
                          _buildContactItem(
                            Icons.phone_outlined,
                            dept.phone ?? "N/A",
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

  Widget _buildContactItem(IconData icon, String text, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon,
              size: 20, color: isLink ? Colors.blue : Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: CustomText(
              text,
              color: isLink ? AppColors.primaryColor : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
