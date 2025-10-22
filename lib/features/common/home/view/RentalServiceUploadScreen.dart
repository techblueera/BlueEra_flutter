import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/commom_textfield.dart';
import '../../../../widgets/common_back_app_bar.dart';
import '../../../../widgets/common_card_widget.dart';
import '../../../../widgets/custom_btn.dart';
import '../../../../widgets/custom_text_cm.dart';

class RentalServiceUploadScreen extends StatelessWidget {
  const RentalServiceUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CommonBackAppBar(
        title: "Rental Service",
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
              left: SizeConfig.size20,
              right: SizeConfig.size20,
              bottom: SizeConfig.size20),
          child: PositiveCustomBtn(
            onTap: () {
              // TODO: Handle post now
            },
            title: "Post Now",
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
                left: SizeConfig.large,
                right: SizeConfig.large,
                bottom: SizeConfig.size30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Upload Images
                CommonCardWidget(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText("Upload Images",
                              fontWeight: FontWeight.w600,
                              fontSize: SizeConfig.size16),
                          CustomText("Min-2 / Max-5",
                              color: Colors.grey,
                              fontSize: SizeConfig.small),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size12),
                      SizedBox(
                        height: SizeConfig.size90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 5,
                          separatorBuilder: (_, __) =>
                              SizedBox(width: SizeConfig.size12),
                          itemBuilder: (context, index) {
                            return Container(
                              width: SizeConfig.size90,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius:
                                BorderRadius.circular(SizeConfig.size12),
                                border: Border.all(
                                    color: Colors.grey.shade300, width: 1),
                              ),
                              child: const Icon(Icons.image_outlined,
                                  color: Colors.grey, size: 32),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size20),

                // 🔹 Property Name
                CustomText("Property Name",
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.size16),
                SizedBox(height: SizeConfig.size8),
                CommonTextField(
                  hintText: "E.g. Taj Hotel...",
                ),

                SizedBox(height: SizeConfig.size16),

                // 🔹 Property Location
                CustomText("Property Location",
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.size16),
                SizedBox(height: SizeConfig.size8),
                CommonTextField(
                  hintText: "E.g. Lucknow, Gomtinagar...",
                ),

                SizedBox(height: SizeConfig.size16),

                // 🔹 Property Description
                CustomText("Property Description",
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.size16),
                SizedBox(height: SizeConfig.size8),
                CommonTextField(
                  hintText: "E.g. 2BHK with swimming pool...",
                 // maxLines: 3,
                ),

                SizedBox(height: SizeConfig.size16),

                // 🔹 Contact Number
                CustomText("Contact Number",
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.size16),
                SizedBox(height: SizeConfig.size8),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size12,
                          vertical: SizeConfig.size14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius:
                        BorderRadius.circular(SizeConfig.size10),
                        color: Colors.white,
                      ),
                      child: CustomText("+91",
                          fontWeight: FontWeight.w500,
                          fontSize: SizeConfig.size16),
                    ),
                    SizedBox(width: SizeConfig.size10),
                    Expanded(
                      child: CommonTextField(
                        hintText: "1234658795",
                      //  keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: SizeConfig.size16),

                // 🔹 Availability
                CustomText("Availability",
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.size16),
                SizedBox(height: SizeConfig.size8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(SizeConfig.size10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: null,
                      hint: CustomText(
                        "E.g. Available",
                        color: Colors.grey,
                        fontSize: SizeConfig.size16,
                      ),
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: const [
                        DropdownMenuItem(value: "Available", child: Text("Available")),
                        DropdownMenuItem(value: "Not Available", child: Text("Not Available")),
                      ],
                      onChanged: (value) {
                        // TODO: handle value
                      },
                    ),
                  ),
                ),


                SizedBox(height: SizeConfig.size16),

                // 🔹 Property Highlights
                CustomText("Property Highlights",
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.size16),
                SizedBox(height: SizeConfig.size8),
                GestureDetector(
                  onTap: () {
                    // TODO: Navigate to Add Highlights
                  },
                  child: CommonCardWidget(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.add_circle_outline,
                                color: Colors.black, size: 24),
                            SizedBox(width: SizeConfig.size8),
                            CustomText("Add Highlights",
                                fontSize: SizeConfig.size16,
                                fontWeight: FontWeight.w500),
                          ],
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: SizeConfig.size16),

                // 🔹 Charges
                CustomText("Charges",
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.size16),
                SizedBox(height: SizeConfig.size8),
                CommonTextField(
                  hintText: "E.g. ₹2000",
                  //keyboardType: TextInputType.number,
                ),

                SizedBox(height: SizeConfig.size20),

                // 🔹 Add More Details + Post Now section
                CommonCardWidget(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText("Add More Details",
                          fontWeight: FontWeight.bold,
                          fontSize: SizeConfig.size16),
                      InkWell(
                        onTap: () {
                          // TODO: Add more details logic
                        },
                        child: Container(
                          padding: EdgeInsets.all(SizeConfig.size6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius:
                            BorderRadius.circular(SizeConfig.size10),
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.blue, size: 24),
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
      ),
    );
  }
}
