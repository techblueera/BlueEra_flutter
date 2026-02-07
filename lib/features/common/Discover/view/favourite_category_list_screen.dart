import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';

class FavouriteCategoryListScreen extends StatefulWidget {

  const FavouriteCategoryListScreen({super.key});

  @override
  State<FavouriteCategoryListScreen> createState() => _FavouriteCategoryListScreenState();
}

class _FavouriteCategoryListScreenState extends State<FavouriteCategoryListScreen> {
  final List<String> favouriteCategories = [
  "Professionals",
  "Shopping",
  "Essential",
  "Services"
  ];
   int selectedFavouriteIndex = 0;

  final List<Map<String, dynamic>> favouriteItems = [
    {
      "name": "Ritesh Kumar Mahato",
      "category": "Plumber",
      "rating": 4.8,
      "reviews": 15,
      "distance": "1.2 km"
    },
    {
      "name": "Amit Sharma",
      "category": "Electrician",
      "rating": 4.5,
      "reviews": 22,
      "distance": "2.5 km"
    },
    {
      "name": "Gupta General Store",
      "category": "Fashion",
      "rating": 4.2,
      "reviews": 10,
      "distance": "0.8 km"
    },
    {
      "name": "City Services",
      "category": "Cleaning",
      "rating": 4.9,
      "reviews": 50,
      "distance": "3.0 km"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(
            vertical: SizeConfig.size15,
            horizontal: SizeConfig.size8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             HorizontalTabSelector(
              tabs: favouriteCategories,
              selectedIndex: selectedFavouriteIndex,
              isFilterIconShow: false,
              onTabSelected: (index, value) {
               setState(() {
                 selectedFavouriteIndex = index;
               });
              },
              labelBuilder: (label) => label,
            ),
             Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                    vertical: SizeConfig.size15, horizontal: SizeConfig.size8),
                itemCount: favouriteItems.length,
                itemBuilder: (context, index) {
                  final item = favouriteItems[index];

                  return FavouriteCard(
                    name: item["name"],
                    category: item["category"],
                    rating: item["rating"],
                    reviews: item["reviews"],
                    distance: item["distance"],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class FavouriteCard extends StatelessWidget {
  final String name;
  final String category;
  final double rating;
  final int reviews;
  final String distance;

  const FavouriteCard({
    super.key,
    required this.name,
    required this.category,
    required this.rating,
    required this.reviews,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedAvatarWidget(
            imageUrl: 'https://picsum.photos/200',
            size: SizeConfig.size70,
            borderColor: Colors.white,
            borderRadius: 8.0,
          ),

          SizedBox(width: SizeConfig.size10),

          // 2. Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CustomText(
                        name,
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.more_vert, size: 20, color: AppColors.mainTextColor),
                  ],
                ),
                const SizedBox(height: 4),

                // Category (e.g. Plumber)
                CustomText(
                  category,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryTextColor,
                ),
                const SizedBox(height: 6),

                // Tags Row (Rating & Distance)
                Row(
                  children: [
                    // Rating Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.greyE4,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          CustomText(
                            "$rating",
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            color: AppColors.rating,
                          ),
                          CustomText(
                            "  •  $reviews Reviews",
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryTextColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Distance Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.greyE4,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          CustomText(
                            distance,
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryTextColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
