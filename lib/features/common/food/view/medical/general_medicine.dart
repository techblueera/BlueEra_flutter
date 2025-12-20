import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
class DoctorItem {
  final String name;
  final String qualification;
  final String specialty;
  final String timing;
  final String fees;
  final String image;

  DoctorItem({
    required this.name,
    required this.qualification,
    required this.specialty,
    required this.timing,
    required this.fees,
    required this.image,
  });
}

class DoctorListCard extends StatelessWidget {
  final DoctorItem item;
  final VoidCallback? onMenuTap;
  final VoidCallback? onManageLeave;

  const DoctorListCard({
    super.key,
    required this.item,
    this.onMenuTap,
    this.onManageLeave,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Doctor Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                item.image,
                height: 90,
                width: 90,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 12),

            /// Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Name + Menu
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style:  TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mainTextColor
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: onMenuTap,
                        child: const Icon(Icons.more_vert, size: 20,
                            color: AppColors.mainTextColor
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),

                      border: Border.all(color: AppColors.greyE5,width: 1)
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          item.qualification,
                          style: const TextStyle(fontSize: 10,  fontWeight: FontWeight.w600,
                              color: AppColors.secondaryTextColor),
                        ),
                        const SizedBox(height: 2),

                        Text(
                          item.specialty,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 8),

                        /// Availability
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Available: ${item.timing}",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const Icon(Icons.edit, size: 14),
                          ],
                        ),

                        const SizedBox(height: 4),

                        /// Fees
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Fees: ${item.fees}",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const Icon(Icons.edit, size: 14),
                          ],
                        ),

                        const SizedBox(height: 10),

                        /// Manage Leave Button
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton(
                            onPressed: onManageLeave,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              "Manage Leave",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),


                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class DoctorListView extends StatelessWidget {
  DoctorListView({super.key});

  final List<DoctorItem> doctors = [
    DoctorItem(
      name: "Dr. Ramesh Gupta",
      qualification: "MBBS",
      specialty: "Child Special",
      timing: "10:00 am - 05:00 pm (Mon-Fri)",
      fees: "₹1000",
      image: "assets/category/medical/otc.png",
    ),
    DoctorItem(
      name: "Dr. Sarmista Roy",
      qualification: "MBBS",
      specialty: "Child Special",
      timing: "10:00 am - 05:00 pm (Mon-Fri)",
      fees: "₹1000",
      image: "assets/category/medical/otc.png",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: doctors.length,
        itemBuilder: (context, index) {
          return DoctorListCard(
            item: doctors[index],
            onMenuTap: () {
              _showMenu(context);
            },
            onManageLeave: () {},
          );
        },
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              ListTile(
                leading: Icon(Icons.edit),
                title: Text("Edit"),
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text("Delete"),
              ),
            ],
          ),
        );
      },
    );
  }
}

