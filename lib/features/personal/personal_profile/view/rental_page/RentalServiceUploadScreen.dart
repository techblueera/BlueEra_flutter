import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/commom_textfield.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/common_box_shadow.dart';
import '../../../../../widgets/common_card_widget.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/custom_text_cm.dart';
import 'myproducts.dart';

class RentalServiceUploadScreen extends StatelessWidget {
  const RentalServiceUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CommonBackAppBar(
        title: "Rental Service",
      ),
      // bottomNavigationBar: SafeArea(
      //   child: Padding(
      //     padding: EdgeInsets.only(
      //         left: SizeConfig.size20,
      //         right: SizeConfig.size20,
      //         bottom: SizeConfig.size20),
      //     child: PositiveCustomBtn(
      //       onTap: () {
      //         Navigator.push(context, MaterialPageRoute(builder: (context) => MyProductsScreen(),));
      //
      //       },
      //       title: "Post Now",
      //     ),
      //   ),
      // ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                  color: AppColors.white,

                ),
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.symmetric(horizontal: 16,vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Upload Images
                    CommonCardWidget(
                      padding: 0,
                      cardMargin: 0,

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CustomText("Upload Images",
                                  fontWeight: FontWeight.w400,

                                  fontSize: SizeConfig.size12
                              ),
                              CustomText("Min-2 / Max-5",
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w400,

                                  fontSize: SizeConfig.size12),
                            ],
                          ),
                          SizedBox(height: SizeConfig.size12),
                          SizedBox(
                            height: SizeConfig.size90,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: 5,
                              separatorBuilder: (_, __) =>
                                  SizedBox(width: SizeConfig.size6),
                              itemBuilder: (context, index) {
                                return Container(
                                  width: SizeConfig.size80,
                                  decoration: BoxDecoration(
                                   // color: Colors.grey[200],
                                    borderRadius:
                                    BorderRadius.circular(SizeConfig.size6),
                                    border: Border.all(
                                        color: AppColors.greyE5, width: 1),
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

                    SizedBox(height: SizeConfig.size10),

                    // 🔹 Property Name
                    CustomText("Property Name",
                        fontWeight: FontWeight.w400,

                        fontSize: SizeConfig.size12

                    ),
                    SizedBox(height: SizeConfig.size8),
                    CommonTextField(
                      hintText: "E.g. Taj Hotel...",
                        fontWeight: FontWeight.w400,

                        fontSize: SizeConfig.size16
                    ),

                    SizedBox(height: SizeConfig.size16),

                    // 🔹 Property Location
                    CustomText("Property Location",
                        fontWeight: FontWeight.w400,

                        fontSize: SizeConfig.size12
                    ),
                    SizedBox(height: SizeConfig.size8),
                    CommonTextField(
                      hintText: "E.g. Lucknow, Gomtinagar...",
                        fontWeight: FontWeight.w400,

                        fontSize: SizeConfig.size16
                    ),

                    SizedBox(height: SizeConfig.size16),

                    // 🔹 Property Description
                    CustomText("Property Description",
                        fontWeight: FontWeight.w400,

                        fontSize: SizeConfig.size12
                    ),
                    SizedBox(height: SizeConfig.size8),
                    CommonTextField(
                      hintText: "E.g. 2BHK with swimming pool...",
                        fontWeight: FontWeight.w400,

                        fontSize: SizeConfig.size16
                     // maxLines: 3,
                    ),

                    SizedBox(height: SizeConfig.size16),

                    // 🔹 Contact Number
                    CustomText("Contact Number",
                        fontWeight: FontWeight.w400,

                        fontSize: SizeConfig.size12),
                    SizedBox(height: SizeConfig.size8),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.size12,
                              vertical: SizeConfig.size10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius:
                            BorderRadius.circular(SizeConfig.size10),
                            color: Colors.white,
                          ),
                          child: CustomText("+91",
                              fontWeight: FontWeight.w500,
                              fontSize: SizeConfig.size16
                          ),
                        ),
                        SizedBox(width: SizeConfig.size10),
                        Expanded(
                          child: CommonTextField(
                            hintText: "1234658795",
                              fontWeight: FontWeight.w400,

                              fontSize: SizeConfig.size16
                          //  keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: SizeConfig.size16),

                    // 🔹 Availability
                    CustomText("Availability",
                        fontWeight: FontWeight.w400,

                        fontSize: SizeConfig.size12),
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
                              fontWeight: FontWeight.w400,

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
                        fontWeight: FontWeight.w400,

                        fontSize: SizeConfig.size12),
                    SizedBox(height: SizeConfig.size8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(width: 1,color: AppColors.whiteE5),
                        boxShadow: [AppShadows.textFieldShadow],
                        color: AppColors.whiteFE
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 14,vertical: 4),
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Navigate to Add Highlights
                        },
                        child: CommonCardWidget(
                          padding: 0,cardMargin: 8,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.add_circle_outline,
                                      color: Colors.black, size: 24),
                                  SizedBox(width: SizeConfig.size8),
                                  CustomText("Add Highlights",
                                      fontWeight: FontWeight.w400,

                                      fontSize: SizeConfig.size16),
                                ],
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: SizeConfig.size16),

                    // 🔹 Charges
                    CustomText("Charges",
                        fontWeight: FontWeight.w400,
                        fontSize: SizeConfig.size12),
                    SizedBox(height: SizeConfig.size8),
                    CommonTextField(
                      hintText: "E.g. ₹2000",
                        fontWeight: FontWeight.w400,
                        fontSize: SizeConfig.size16
                      //keyboardType: TextInputType.number,
                    ),

                   // SizedBox(height: SizeConfig.size20),

                    // 🔹 Add More Details + Post Now section


                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0,right: 16,top: 4),
                child: CommonCardWidget(borderRadius: 10,
                  cardMargin: 0,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText("Add More Details",
                              fontWeight: FontWeight.w400,
                              fontSize: SizeConfig.size16),
                          InkWell(
                            onTap: () {
                              // TODO: Add more details logic
                            },
                            child: Container(
                              padding: EdgeInsets.all(SizeConfig.size5),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius:
                                BorderRadius.circular(SizeConfig.size10),
                              ),
                              child: const Icon(Icons.add,
                                  color: Colors.white, size: 24),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30,),
                      PositiveCustomBtn(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => MyProductsScreen(),));
                        },
                        title: "Post Now",
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30,)

            ],
          ),
        ),
      ),
    );
  }
}
