import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_contact_us/hospital_contact_us.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class HospitalContactUsView extends StatelessWidget {
  final List<HospitalContacts> contacts;
  final bool isReadOnly;

  const HospitalContactUsView(
      {super.key, required this.contacts, required this.isReadOnly});

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
                    title: "Contact Us",
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
            SizedBox(height: 10,),
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
              size: 20, color: isLink ? AppColors.mainTextColor : AppColors.secondaryTextColor),
          const SizedBox(width: 12),
          Expanded(
            child: CustomText(
              text,
              color: isLink ? AppColors.primaryColor : AppColors.mainTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
