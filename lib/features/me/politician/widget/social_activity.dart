import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/common_back_app_bar.dart';
import '../../../../widgets/custom_text_cm.dart';

class SocialActivityListPage extends StatelessWidget {
  const SocialActivityListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
        title: "Social Activity",
        isShadowShow: false,
        isCreateButton: true,

      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 1,
        itemBuilder: (context, index) {
          return _activityCard();
        },
      ),
    );
  }



  Widget _activityCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(
                  "https://i.pravatar.cc/150",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      "Free Health Check-up Camp",
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding:EdgeInsets.symmetric(horizontal: 8,vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.boxBg,
                            borderRadius: BorderRadius.circular(100),

                          ),
                          child: CustomText(
                            "20 April, 2025",
                            fontSize: 10,
                            fontWeight: FontWeight.w600,

                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding:EdgeInsets.symmetric(horizontal: 8,vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.boxBg,
                            borderRadius: BorderRadius.circular(100),

                          ),
                          child: CustomText(
                            "@Mahesh Kumar",
                            fontSize: 10,
                            fontWeight: FontWeight.w600,

                            color: AppColors.secondaryTextColor,                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppColors.primaryColor),
              const SizedBox(width: 4),
              Expanded(
                child: CustomText(
                  "Sorem ipsum dolor sit amet, consectetur adipiscing elit...",
                  fontSize: 10,
                  fontWeight: FontWeight.w400,

                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          RichText(
            text: TextSpan(
              text:
              "Borem ipsum dolor sit amet, consectetur adipis elit. Nunc vulputate libero et velit interdum, ac aliqu...",
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mainTextColor,
                fontWeight: FontWeight.w400,

                height: 1.4,
              ),
              children: const [
                TextSpan(
                  text: " Read More",
                  style: TextStyle(

                    fontSize: 12,
                    color: AppColors.mainTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 12),

          _imageGrid(),
        ],
      ),
    );
  }

  Widget _imageGrid() {
    return SizedBox(
      height: 160,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ClipRRect(
              child: Image.network(
                "https://images.unsplash.com/photo-1550831107-1553da8c8464",
                fit: BoxFit.cover,
                height: double.infinity,
              ),
            ),
          ),
          const SizedBox(width: 2),

          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    child: Image.network(
                      "https://images.unsplash.com/photo-1550831107-1553da8c8464",
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        child: Image.network(
                          "https://images.unsplash.com/photo-1576765607924-3f7b8410a787",
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                        ),
                        alignment: Alignment.center,
                        child: CustomText(
                          "+10",
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
