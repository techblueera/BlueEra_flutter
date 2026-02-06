import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/common_drop_down_icon_dialoge.dart';

class AddPoliticianActivityEvent extends StatefulWidget {
  const AddPoliticianActivityEvent({super.key});

  @override
  State<AddPoliticianActivityEvent> createState() => _AddPoliticianActivityEventState();
}

class _AddPoliticianActivityEventState extends State<AddPoliticianActivityEvent> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  String? selectedMedia;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   CustomText(
                    "Add More",
                        fontSize: 18, fontWeight: FontWeight.bold
                  ),
                  InkWell(
                      onTap: (){
                        Navigator.pop(context);
                      },
                      child: const Icon(Icons.close))
                ],
              ),

              const SizedBox(height: 12),

              /// Title
              CommonTextField(
                textEditController: titleController,
                title: "Title",
                hintText: "E.g. Finance & Tax",
              ),

              const SizedBox(height: 16),

              /// Upload Dropdown
              const Text("Upload Images or Video"),
              const SizedBox(height: 6),
              // CommonDropdownIconDialog<String>(
              //   items: ["image", "video"],
              //   selectedValue: "image",
              //   hintText: "E.g. Images / Video",
              //   title: "Upload Images or Video",
              //   displayValue: (item) => item,
              //   displayValueSubTitle: (item) => item,
              //   displayValueImagePath: (item) => item,
              //   onChanged: (value) {
              //
              //   },
              // ),
            DropdownButtonFormField<String>(
              value: selectedMedia, // must be null initially
              hint: CustomText(
                "E.g. Images / Video",
               color: AppColors.coloGreyText,
                fontSize: 16,
              ),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "image", child: CustomText("Images")),
                DropdownMenuItem(value: "video", child: CustomText("Video")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedMedia = value;
                });
              },
            ),

            const SizedBox(height: 16),

              /// Description
              CommonTextField(
                textEditController: descController,
                title: "Description",
                maxLine: 4,
                hintText: "Hello Everyone @India User\nNow I am Using https://blueera.ai It's Amazing, I suggest to join Me.",
              ),


              SizedBox(height: SizeConfig.size30),

              /// Save Button
              CustomBtn(
                  isValidate: true,
                  onTap: (){

              }, title: "Save"),
               SizedBox(height: SizeConfig.size30)
            ],
          ),
        ),
      ),
    );
  }
}
