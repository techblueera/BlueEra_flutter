import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';

class CampusLifePage extends StatelessWidget {
  CampusLifePage({super.key});

  final infrastructure = [
    CampusMediaItem(title: "Classrooms", image: "assets/category/medical/statium.png"),
    CampusMediaItem(title: "Auditorium", image: "assets/category/medical/campus.png"),
    CampusMediaItem(title: "Seminar Halls", image: "assets/category/medical/campus.png"),
    CampusMediaItem(title: "Science Labs", image: "assets/category/medical/campus.png"),
    CampusMediaItem(title: "Computer Labs", image: "assets/category/medical/campus.png"),
    CampusMediaItem(title: "Language Labs", image: "assets/category/medical/campus.png"),
  ];

  final sports = [
    CampusMediaItem(title: "Indoor", image: "assets/category/medical/campus.png"),
    CampusMediaItem(title: "Outdoor", image: "assets/category/medical/campus.png"),
  ];

  final hostel = [
    CampusMediaItem(title: "Boys Hostel", image: "assets/category/medical/campus.png"),
    CampusMediaItem(title: "Girl’s Hostel", image: "assets/category/medical/campus.png"),
  ];

  final events = [
    CampusMediaItem(title: "Annual Fest", image: "assets/category/medical/campus.png"),
    CampusMediaItem(title: "Cultural Event", image: "assets/category/medical/campus.png"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: CommonBackAppBar(

        title:  "Campus Life",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            CampusSection(
              title: "Infrastructure",
              items: infrastructure,
              onAdd: () {},
            ),
            CampusSection(
              title: "Sports",
              items: sports,
              onAdd: () {},
            ),
            CampusSection(
              title: "Hostel",
              items: hostel,
              onAdd: () {},
            ),
            CampusSection(
              title: "Events",
              items: events,
              onAdd: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class CampusMediaItem {
  final String title;
  final String image;
  bool selected;

  CampusMediaItem({
    required this.title,
    required this.image,
    this.selected = false,
  });
}
class CampusSection extends StatelessWidget {
  final String title;
  final List<CampusMediaItem> items;
  final VoidCallback onAdd;

  const CampusSection({
    super.key,
    required this.title,
    required this.items,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Header
        Row(
          children: [
            Text(
              title,
              style:  TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onAdd,
              icon: Container(
                  decoration: BoxDecoration(shape:BoxShape.circle,
                      border: Border.all(color: AppColors.primaryColor,)
                  ),

                  child: const Icon(Icons.add, size: 16)),
              label: const Text("Add Media",
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,

                ),

              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,

              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        /// Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemBuilder: (context, index) {
            return CampusMediaCard(
              item: items[index],
              onTap: () {
                items[index].selected = !items[index].selected;
                (context as Element).markNeedsBuild();
              },
            );
          },
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}

class CampusMediaCard extends StatelessWidget {
  final CampusMediaItem item;
  final VoidCallback onTap;

  const CampusMediaCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Image + Checkbox
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.asset(
                    item.image,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                /// Checkbox (rounded square like image)
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0x991C1C1C),
                    child: Container(
                      height: 22,
                      width: 22,
                      decoration: BoxDecoration(
                        // color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: item.selected
                              ? Colors.blue
                              : Colors.grey.shade400,
                        ),
                      ),
                      child: item.selected
                          ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.blue,
                      )
                          : null,
                    ),
                  ),
                ),
              ],
            ),

            /// Title
            Padding(
              padding: const EdgeInsets.all(10),
              child: Center(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: AppColors.mainTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}