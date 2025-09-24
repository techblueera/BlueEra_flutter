import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';


import '../widget/add_services_screen.dart';

class FoodPage extends StatefulWidget {
  const FoodPage({Key? key}) : super(key: key);

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  final foodNameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  String selectedCategory = '';
  String selectedSubCategory = '';
  String selectedAvailability = '';
  bool isVeg = true;
  bool isMultipleType = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar:  CommonBackAppBar(
        title: 'Food',
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Upload images
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("Upload Images",
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        Text("Min-2 / Max-5",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 16),

                    _buildTextField("Food Name", "E.g. Paneer Butter Masala...",
                        controller: foodNameCtrl),

                    SizedBox(height: SizeConfig.size10),

                    // Category
                    _buildDropdown("Category tag", "E.g. Main Course...",
                        onChanged: (v) => setState(() => selectedCategory = v!)),

                     SizedBox(height: SizeConfig.size6),

                    // Sub Category with Veg/Non-veg
                     Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         CustomText("Sub Category",),
                         Row(
                           children: [
                             Row(
                               children: [
                                 Radio(
                                   visualDensity: const VisualDensity(
                                       horizontal: -4, vertical: -4),
                                   value: true,
                                   groupValue: isVeg,
                                   onChanged: (v) => setState(() => isVeg = true),
                                 ),
                                 const CustomText("Veg",fontSize: 12,)
                               ],
                             ),
                             const SizedBox(width: 16),
                             Row(
                               children: [
                                 Radio(
                                   visualDensity: const VisualDensity(
                                       horizontal: -4, vertical: -4),
                                   value: false,
                                   groupValue: isVeg,
                                   onChanged: (v) => setState(() => isVeg = false),
                                 ),
                                 const CustomText("Non-Veg",fontSize: 12,)
                               ],
                             ),
                           ],
                         ),
                       ],
                     ),
                    SizedBox(height: SizeConfig.size8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "Sample",
                          child: Text("Sample"),
                        ),
                      ],
                      hint: CustomText("E.g. Veg, North Indian...", color: AppColors.grey9A,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,),
                      onChanged: (val){

                      },

                      // 👇 this changes the selected text color inside the field
                      style: TextStyle(
                        color: AppColors.grey9A,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),


                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.black,
                      ),
                    ),

                     SizedBox(height: SizeConfig.size10),

                    // Description
                    _buildTextField("Food Description",
                        "Horem ipsum dolor sit amet, consectetur adipiscing...",
                        controller: descCtrl,
                        maxLines: 5),

                    const SizedBox(height: 16),

                    // Availability
                    _buildDropdown("Availability", "E.g. Available",
                        onChanged: (v) =>
                            setState(() => selectedAvailability = v ?? '')),

                    const SizedBox(height: 16),

                    // Add Ons
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14,vertical: 0 ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.whiteE5
                        )
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.add_circle_outline),
                        title: const Text("Add ons"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => AddOnsPage()));
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _buildSectionContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText("Price",),
                        Row(
                          children: [
                            Row(
                              children: [
                                Radio(
                                  visualDensity: const VisualDensity(
                                      horizontal: -4, vertical: -4),
                                  value: true,
                                  groupValue: isVeg,
                                  onChanged: (v) => setState(() => isVeg = true),
                                ),
                                const CustomText("Single Product",fontSize: 12,)
                              ],
                            ),
                            const SizedBox(width: 16),
                            Row(
                              children: [
                                Radio(
                                  visualDensity: const VisualDensity(
                                      horizontal: -4, vertical: -4),
                                  value: false,
                                  groupValue: isVeg,
                                  onChanged: (v) => setState(() => isVeg = false),
                                ),
                                const CustomText("Multiple type",fontSize: 12,)
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size10,),

                    // Example size+price fields
                    Row(
                      children: [
                        Expanded(
                          child: CommonTextField(
                            contentPadding: EdgeInsets.symmetric(vertical: 14,horizontal: 12),

                            hintText: "E.g. Small",
                            textEditController: TextEditingController(),
                            keyBoardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: SizeConfig.size10),
                        Expanded(
                          child: CommonTextField(
                            contentPadding: EdgeInsets.symmetric(vertical: 14,horizontal: 12),
                            hintText: "₹300",
                            textEditController: TextEditingController(),
                            keyBoardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                     SizedBox(height: SizeConfig.size10,),
                    Row(
                      children: [
                        Expanded(
                          child: CommonTextField(
                            contentPadding: EdgeInsets.symmetric(vertical: 14,horizontal: 12),

                            hintText: "E.g. Medium",
                            textEditController: TextEditingController(),
                            keyBoardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: SizeConfig.size10),
                        Expanded(
                          child: CommonTextField(
                            contentPadding: EdgeInsets.symmetric(vertical: 14,horizontal: 12),
                            hintText: "₹300",
                            textEditController: TextEditingController(),
                            keyBoardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size10,),
                    Row(
                      children: [
                        Expanded(
                          child: CommonTextField(
                            contentPadding: EdgeInsets.symmetric(vertical: 14,horizontal: 12),

                            hintText: "E.g. Large",
                            textEditController: TextEditingController(),
                            keyBoardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: SizeConfig.size10),
                        Expanded(
                          child: CommonTextField(
                            contentPadding: EdgeInsets.symmetric(vertical: 14,horizontal: 12),
                            hintText: "₹300",
                            textEditController: TextEditingController(),
                            keyBoardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: CustomText("+ Add More",
                             color: Colors.blue),
                    ),

                    const SizedBox(height: 10),


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
              ),

              const SizedBox(height: 16),

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
                          "Post Food",
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

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300)),
      child: child,
    );
  }

  Widget _buildTextField(String label, String hint,
      {TextEditingController? controller,
        int maxLines = 1,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonTextField(maxLine: maxLines,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          title: label,
          hintText: hint,
          textEditController: controller,
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String hint,
      {ValueChanged<String?>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(label),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.white,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: "Sample",
              child: Text("Sample"),
            ),
          ],
          hint: CustomText(hint, color: AppColors.grey9A,
            fontSize: 16,
            fontWeight: FontWeight.w400,),
          onChanged: onChanged,

          // 👇 this changes the selected text color inside the field
          style: TextStyle(
            color: AppColors.grey9A,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),


          icon: Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.black,
          ),
        )

      ],
    );
  }
}



class AddOnsPage extends StatefulWidget {
  const AddOnsPage({Key? key}) : super(key: key);

  @override
  State<AddOnsPage> createState() => _AddOnsPageState();
}

class _AddOnsPageState extends State<AddOnsPage> {
  final extraCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  final List<Map<String, dynamic>> addOns = [];

  void _addAddOn() {
    if (extraCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) return;

    setState(() {
      addOns.add({
        "name": extraCtrl.text.trim(),
        "price": priceCtrl.text.trim(),
      });
      extraCtrl.clear();
      priceCtrl.clear();
    });
  }

  void _removeAddOn(int index) {
    setState(() {
      addOns.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Add Ons',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 👈 Auto adjust height
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Extra Add field
              const Text("Extra Add", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              TextField(
                controller: extraCtrl,
                decoration: InputDecoration(
                  hintText: "e.g. Butter Naan",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Price field
              const Text("Price", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "e.g. ₹30",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Added AddOns Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(addOns.length, (index) {
                  final item = addOns[index];
                  return Chip(
                    label: Text(
                      "${item['name']} (+₹${item['price']})",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    backgroundColor: AppColors.skyBlueDF.withOpacity(0.1),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeAddOn(index),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addAddOn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Save",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

    );
  }

}
