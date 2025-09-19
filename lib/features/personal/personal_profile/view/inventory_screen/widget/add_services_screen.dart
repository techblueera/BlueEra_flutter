import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import '../../../../../../core/constants/app_icon_assets.dart';
import '../../../../../../widgets/local_assets.dart';

class AddServicesScreen extends StatefulWidget {
  const AddServicesScreen({Key? key}) : super(key: key);

  @override
  State<AddServicesScreen> createState() => _AddServicesScreenState();
}

class _AddServicesScreenState extends State<AddServicesScreen> {
  final TextEditingController serviceNameCtrl = TextEditingController();
  final TextEditingController facilitiesCtrl = TextEditingController();
  final TextEditingController descriptionCtrl = TextEditingController();
  final TextEditingController minPriceCtrl = TextEditingController();
  final TextEditingController maxPriceCtrl = TextEditingController();
  final TextEditingController perUnitCtrl = TextEditingController();
  final TextEditingController minBookingCtrl = TextEditingController();

  bool isRange = true;

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
        title: 'Service',

      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Upload Images Section
              Container(
                padding: EdgeInsets.all(SizeConfig.size16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  // boxShadow: [AppShadows.textFieldShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const CustomText(
                            "Upload Images",
                            fontWeight: FontWeight.w400
                        ),
                        const CustomText(
                            "Min 2 / Max 5",
                            fontWeight: FontWeight.w400),
                      ],
                    ),
                    SizedBox(height: SizeConfig.paddingS),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          5,
                              (index) => Container(
                                height: 80,
                                width: 80,
                                margin: EdgeInsets.symmetric(horizontal: index==0?0:6),
                                decoration: BoxDecoration(
                                  color: AppColors.whiteFE,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.whiteE5
                                  )
                                ),
                                child: const Icon(
                                  CupertinoIcons.photo,
                                  color: AppColors.greyAF,
                                ),
                              ),
                        ),
                      ),
                    ),
                    SizedBox(height: SizeConfig.size10),
                    CommonTextField(
                      contentPadding: EdgeInsets.symmetric(vertical: 14,horizontal: 12),
                      title: "Service Name",
                      hintText: "E.g. Hospital OPD Consultation...",
                      textEditController: serviceNameCtrl,
                    ),
                    SizedBox(height: SizeConfig.size10),
                    CommonTextField(
                      contentPadding: EdgeInsets.symmetric(vertical: 14,horizontal: 12),
                      title: "Facilities",
                      hintText: "E.g. Parking, Pharmacy, Home Visit, etc.",
                      textEditController: facilitiesCtrl,
                    ),
                    SizedBox(height: SizeConfig.size10),
                    CommonTextField(
                      title: "Service Description",
                      hintText: "Horem ipsum dolor sit amet, consectetur adipiscing...",
                      textEditController: descriptionCtrl,
                      maxLine: 4,
                    ),
                    SizedBox(height: SizeConfig.size10),
                    _timingSection(),


                  ],
                ),
              ),
              SizedBox(height: SizeConfig.size10),
              _priceSection(),

              SizedBox(height: SizeConfig.size10),

              // Demo Video
              _demoVideoSection(),

              SizedBox(height: SizeConfig.size10),

              // Minimum Booking
              Container(
                padding: EdgeInsets.all(SizeConfig.size16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  // boxShadow: [AppShadows.textFieldShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:  [
                    CommonTextField(
                      contentPadding: EdgeInsets.symmetric(vertical: 14,horizontal: 12),
                      title: "Minimum booking Amount",
                      hintText: "E.g. ₹300",
                      textEditController: minBookingCtrl,
                      keyBoardType: TextInputType.number,
                    ),
                    SizedBox(height: SizeConfig.size30,),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText("Add More Details",
                        fontWeight: FontWeight.w600,),
                        GestureDetector(
                          onTap: () {
                            showAddMoreDetailsDialog(context);
                          },
                          child: Container(
                            height: 28,
                              width: 28,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              color: Colors.blue
                              ),
                              child: Center(child: const Icon(CupertinoIcons.add,
                                color: Colors.white,size: 21,))),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size30,),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                              vertical: SizeConfig.paddingM),
                        ),
                        onPressed: () {},
                        child: const CustomText(
                          "Post Service",
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _timingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const CustomText("Timing", fontWeight: FontWeight.w500),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: RadioListTile<bool>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    value: false,
                    groupValue: true,
                    onChanged: (_) {},
                    title: const CustomText(
                      "Default",
                      fontSize: 12, // optional: make text smaller
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: RadioListTile<bool>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    value: true,
                    groupValue: true,
                    onChanged: (_) {},
                    title: const CustomText(
                      "Special",
                      fontSize: 12, // optional
                    ),
                  ),
                ),
              ],
            )

          ],
        ),
         SizedBox(height:SizeConfig.size8,),
        Row(
          children: [
            Expanded(
              child: CommonTextField(
                contentPadding: EdgeInsets.symmetric(vertical: 14,horizontal: 12),
                hintText: "E.g. 10:00 AM",
              ),
            ),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: CommonTextField(
                contentPadding: EdgeInsets.symmetric(vertical: 14,horizontal: 12),
                hintText: "E.g. 12:00 PM",
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget   _priceSection() {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        // boxShadow: [AppShadows.textFieldShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CustomText("Price", fontWeight: FontWeight.w500),
              Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: RadioListTile<bool>(
                      contentPadding: EdgeInsets.zero,
                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                      value: false,
                      groupValue: isRange,
                      onChanged: (val) {
                        setState(() => isRange = val!);
                      },
                      title:  CustomText("Fixed",
                        fontSize: 12,),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: RadioListTile<bool>(
                      contentPadding: EdgeInsets.zero,
                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                      value: true,
                      groupValue: isRange,
                      onChanged: (val) {
                        setState(() => isRange = val!);
                      },
                      title:  CustomText("Range",
                        fontSize: 12,),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  contentPadding: EdgeInsets.symmetric(vertical: 14,horizontal: 12),

                  hintText: "Min - ₹300",
                  textEditController: minPriceCtrl,
                  keyBoardType: TextInputType.number,
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: CommonTextField(
                  contentPadding: EdgeInsets.symmetric(vertical: 14,horizontal: 12),
                  hintText: "Max - ₹800",
                  textEditController: maxPriceCtrl,
                  keyBoardType: TextInputType.number,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomText("Per (Unit)",

              fontWeight: FontWeight.w400,)
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          CommonTextField(
            contentPadding: EdgeInsets.symmetric(vertical: 14,horizontal: 12),

            hintText: "E.g. ₹-Per Service, Hours, Course...",
            textEditController: perUnitCtrl,
          ),
          SizedBox(
            height: SizeConfig.size10,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomText("Discount", fontWeight: FontWeight.w400),
              SizedBox(
                height: SizeConfig.size8,
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.whiteE5
                  )
                ),
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size14),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title:  CustomText("Discount Coupon",
                  fontFamily: "Arial",
                  ),
                  trailing: const Icon(CupertinoIcons.chevron_forward),
                  onTap: () {},
                ),
              ),
              SizedBox(
                height: SizeConfig.size8,
              ),
              Row(mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      showDiscountCouponDialog(context);
                    },
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.add, color: Colors.blue,size: 20,),
                        SizedBox(width: 6),
                        const CustomText(
                          "Add More Coupon",
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }


  Widget _demoVideoSection() {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        // boxShadow: [AppShadows.textFieldShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:  [
          CustomText("Add Demo Video", fontWeight: FontWeight.w500),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.whiteE5
              )
            ),
            child: Center(
              child: Column(
                children: [
                  LocalAssets(imagePath: AppIconAssets
                      .upload_video_service),
                  SizedBox(height: 6),
                  Center(
                    child: CustomText(
                      "Upload your Demo Video",
                      color: Colors.grey,
                    ),
                  )
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }

}
void showAddMoreDetailsDialog(BuildContext context) {
  final titleCtrl = TextEditingController();
  final detailsCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomText(
                "Add More Details",
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              const SizedBox(height: 20),

              // Title Field
              CommonTextField(
                contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                title: "Title",
                hintText: "e.g. Size",
                textEditController: titleCtrl,
              ),
              const SizedBox(height: 16),

              // Details Field
              CommonTextField(
                contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                title: "Details",
                hintText: "e.g. Wireless Earbuds Box",
                textEditController: detailsCtrl,

              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: SizeConfig.paddingM,
                    ),
                  ),
                  onPressed: () {
                    // handle save
                    Navigator.pop(context);
                  },
                  child: const CustomText(
                    "Save",
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
void showDiscountCouponDialog(BuildContext context) {
  final couponNameCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final codeNameCtrl = TextEditingController();
  final totalOffCtrl = TextEditingController();
  String selectedType = "percentage"; // or "rupees"

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomText(
                      "Discount Coupon",
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    const SizedBox(height: 20),

                    // Coupon Name
                    CommonTextField(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 12),
                      title: "Coupon Name",
                      hintText: "e.g. Size",
                      textEditController: couponNameCtrl,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    CommonTextField(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 12),
                      title: "Description / Terms And Condition",
                      hintText:
                      "Horem ipsum dolor sit amet, consectetur adipiscing...",
                      textEditController: descriptionCtrl,

                    ),
                    const SizedBox(height: 16),

                    // Code Name
                    CommonTextField(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 12),
                      title: "Code Name (Optional)",
                      hintText: "e.g. 4526525",
                      textEditController: codeNameCtrl,
                    ),
                    const SizedBox(height: 16),

                    // Total Off with radio
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const CustomText(
                          "Total Off",
                          fontWeight: FontWeight.w500,
                        ),
                        Row(
                          children: [
                            Row(
                              children: [
                                Radio<String>(
                                  value: "rupees",
                                  groupValue: selectedType,
                                  onChanged: (val) {
                                    setState(() {
                                      selectedType = val!;
                                    });
                                  },
                                  visualDensity: const VisualDensity(
                                      horizontal: -4, vertical: -4),
                                ),
                                const CustomText(
                                  "In Rupees",
                                  fontSize: 12,
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                Radio<String>(
                                  value: "percentage",
                                  groupValue: selectedType,
                                  onChanged: (val) {
                                    setState(() {
                                      selectedType = val!;
                                    });
                                  },
                                  visualDensity: const VisualDensity(
                                      horizontal: -4, vertical: -4),
                                ),
                                const CustomText(
                                  "In Percentage",
                                  fontSize: 12,
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Total Off input
                    CommonTextField(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 12),
                      hintText: "e.g. 10% Off",
                      textEditController: totalOffCtrl,
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: SizeConfig.paddingM,
                          ),
                        ),
                        onPressed: () {
                          // handle save
                          Navigator.pop(context);
                        },
                        child: const CustomText(
                          "Save",
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
