import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/common_card_widget.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/custom_text_cm.dart';

class RentalDetailsScreen extends StatelessWidget {
  const RentalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: Container(
                  height: SizeConfig.size40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(SizeConfig.size10),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Search here...",
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: SizeConfig.size14,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              const Icon(CupertinoIcons.location_solid, color: Colors.black, size: 20),
              SizedBox(width: SizeConfig.size4),
              CustomText(
                "Lucknow",
                color: Colors.blue,
                fontWeight: FontWeight.w500,
                fontSize: SizeConfig.size14,
              ),
            ],
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: SizeConfig.size12),

              // 🔹 Hotel Image (with indicator)
              ClipRRect(
                borderRadius: BorderRadius.circular(SizeConfig.size12),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Image.asset(
                      "assets/diwali_card/rentalhome.png",
                      height: SizeConfig.size200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      bottom: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          bool isActive = index == 0;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: 6,
                            width: 6,
                            decoration: BoxDecoration(
                              color: isActive ? Colors.blue : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white),
                            ),
                          );
                        }),
                      ),
                    )
                  ],
                ),
              ),

              SizedBox(height: SizeConfig.size16),

              // 🔹 Hotel Details Section
              CommonCardWidget(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      "Hotel details",
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.size16,
                    ),
                    SizedBox(height: SizeConfig.size12),

                    CustomText(
                      "Banerjee Inn- City Centre",
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.size15,
                    ),
                    SizedBox(height: SizeConfig.size4),

                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        SizedBox(width: SizeConfig.size4),
                        CustomText(
                          "4.8",
                          fontWeight: FontWeight.w500,
                          fontSize: SizeConfig.size13,
                        ),
                        SizedBox(width: SizeConfig.size4),
                        CustomText(
                          "(48 reviews)",
                          color: Colors.grey,
                          fontSize: SizeConfig.size13,
                        ),
                        SizedBox(width: SizeConfig.size10),
                        const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
                        CustomText(
                          "1.2 km",
                          color: Colors.black54,
                          fontSize: SizeConfig.size13,
                        ),
                      ],
                    ),

                    SizedBox(height: SizeConfig.size10),

                    CustomText(
                      "Sorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis. Class aptent taciti sociosqu ad litora torquent per conubia n...Read More",
                      color: Colors.black87,
                      fontSize: SizeConfig.size13,
                      maxLines: 4,
                    ),

                    SizedBox(height: SizeConfig.size12),

                    CustomText(
                      "₹4999",
                      fontWeight: FontWeight.bold,
                      fontSize: SizeConfig.size18,
                      color: Colors.black,
                    ),

                    SizedBox(height: SizeConfig.size8),

                    Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.blue, size: 18),
                        SizedBox(width: SizeConfig.size6),
                        CustomText(
                          "+91 1234567990",
                          color: Colors.blue,
                          fontSize: SizeConfig.size14,
                        ),
                      ],
                    ),

                    SizedBox(height: SizeConfig.size8),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue, size: 18),
                        SizedBox(width: SizeConfig.size6),
                        Expanded(
                          child: CustomText(
                            "Morem ipsum dolor sit amet, consectetur adipiscing elit...",
                            color: Colors.blue,
                            fontSize: SizeConfig.size14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: SizeConfig.size16),

              // 🔹 Highlights Section
              CommonCardWidget(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      "Highlights",
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.size16,
                    ),
                    SizedBox(height: SizeConfig.size12),
                    ...List.generate(
                      4,
                          (index) => Padding(
                        padding: EdgeInsets.only(bottom: SizeConfig.size6),
                        child: CustomText(
                          "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                          color: Colors.black87,
                          fontSize: SizeConfig.size14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: SizeConfig.size30),
            ],
          ),
        ),
      ),

      // 🔹 Bottom Buttons
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.large, vertical: SizeConfig.size12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey, width: 0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SizeConfig.size10)),
                    padding: EdgeInsets.symmetric(vertical: SizeConfig.size14),
                  ),
                  child: CustomText(
                    "Back",
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                    fontSize: SizeConfig.size15,
                  ),
                ),
              ),
              SizedBox(width: SizeConfig.size12),
              Expanded(
                child: PositiveCustomBtn(
                  title: "Book Now",
                  onTap: () {
                    // TODO: handle booking logic
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
