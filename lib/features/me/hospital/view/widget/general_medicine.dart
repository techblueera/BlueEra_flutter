import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:intl/intl.dart';

import '../../../../../core/api/apiService/api_response.dart';
import '../../../../../core/constants/app_constant.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../../core/constants/size_config.dart';
import '../../controller/hospital_model_controller.dart';
import '../../model/docters_details_model.dart';
import 'add_doctors_dialoge.dart';


class DoctorListView extends StatefulWidget {
  DoctorListView({super.key, required this.documentId, required this.title});
  final String documentId;
  final String title;

  @override
  State<DoctorListView> createState() => _DoctorListViewState();
}

class _DoctorListViewState extends State<DoctorListView> {

  final controller = getOrPut(() => HospitalModelController());

  @override
  void initState() {
    // TODO: implement initState
    controller.getAllDoctors(widget.documentId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "${widget.title}",
      ),
      body: SingleChildScrollView(
        child: Obx(() {
          if(controller.getDoctorsResponse.value.status==Status.COMPLETE){
            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  if(controller.staffList.isEmpty)
                    Center(
                      child: CustomText("No Doctors Added Yet in ${widget.title} Department"),
                    )
                  else
                  ...controller.staffList.map((e) =>
                      DoctorListCard(
                        item: e,
                        onMenuTap: (){

                        },
                        onManageLeave: () {},
                      )).toList(),
                  SizedBox(height: SizeConfig.size20,),
                  InkWell(
                    onTap: () {
                      HospitalStaffDialog.showAddDoctor(
                        context: context,
                        departmentId: widget.documentId,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primaryColor),
                        color: AppColors.primaryColor.withOpacity(0.1),
                      ),
                      padding: EdgeInsets.symmetric(
                          horizontal: 14, vertical: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline,
                            color: AppColors.primaryColor,),
                          SizedBox(width: SizeConfig.size6,),
                          CustomText(
                            "Add Doctors",
                            fontSize: 14,
                            textAlign: TextAlign.center,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.size20,)
                ],
              ),
            );
          }else{
            return Center(
              child: CircularProgressIndicator(),
            );
          }

        }),
      ),
    );
  }
  void showMenuItems(BuildContext context) {
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
      },);
  }
}


class DoctorListCard extends StatelessWidget {
  final DoctorsDetailsModel item;
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
    final controller = getOrPut(() => HospitalModelController());

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
              child: CustomImageSlideshow(
                height: 120,
                width: 120,
               isLoading: false, imagePaths: [item.photo??''],
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
                        child: CustomText(
                            item.name,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mainTextColor

                        ),
                      ),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        onSelected: (value) async {
                          if(value=='Edit'){
                            HospitalStaffDialog.showAddDoctor(
                              context: context,
                              departmentId: '',
                              preDoctorDetails: item
                            );
                          }else{
                            await controller.deleteDoctorDetails(item.id??'');
                          }

                         },
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: "Edit",
                            child: CustomText(
                              AppStrings.edit,
                            ),
                          ),
                          PopupMenuItem(
                            value: "Delete",
                            child: CustomText(
                              AppStrings.delete,
                            ),
                          ),

                        ],
                        child:  const Icon(Icons.more_vert, size: 20,
                            color: AppColors.mainTextColor
                        ),
                      ),

                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.greyE5, width: 1)
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        CustomText(
                            item.qualification,
                            fontSize: 10, fontWeight: FontWeight.w600,
                            color: AppColors.secondaryTextColor
                        ),
                        const SizedBox(height: 4),

                        CustomText(
                          item.specialization,
                          fontSize: 10,
                          color: Colors.grey.shade600,

                        ),

                        const SizedBox(height: 4),

                        /// Availability
                        Row(
                          children: [
                            Expanded(
                              child: CustomText(
                                "Available: ${item.availability}",
                                fontSize: 10,
                              ),
                            ),
                            InkWell(
                              onTap: (){
                                showEditFeeDialog(isEditFee: false,context: context,doctorId:item.id??'',fee: "${item.fees??''}",availability: "${item.availability??''}");
                              },
                              child: LocalAssets(imagePath: AppIconAssets.pen_line
                                , height: 13, width: 13,),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),
                        if(item.leaveFrom!=null&&item.leaveFrom!=''&&item.leaveFrom!='null')
                          Row(
                            children: [
                              CustomText(
                                  "Doctor on Leave : \n${DateFormat("dd-MM-yy").format(DateTime.parse(item.leaveFrom!)
                                      .toLocal())}  To  ${DateFormat("dd-MM-yy").format(DateTime.parse(item.leaveTo!)
                                      .toLocal())}  (${DateTime.parse(item.leaveTo!)
                                      .toLocal()
                                      .difference(
                                    DateTime.parse(item.leaveFrom!).toLocal(),
                                  )
                                      .inDays +
                                      1} Days ) ",
                                  fontSize: 10
                              ),
                            ],
                          ),
                        /// Fees
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  CustomText(
                                      "Fees: ${item.fees}",
                                      fontSize: 10
                                  ),
                                  SizedBox(width: 8,),
                                  InkWell(
                                    onTap: (){
                                      showEditFeeDialog(isEditFee: true,context: context,doctorId:item.id??'',fee: "${item.fees??''}");
                                    },
                                    child: LocalAssets(imagePath: AppIconAssets.pen_line
                                      , height: 13, width: 13,),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: (){
                                if(item.leaveFrom!=null&&item.leaveFrom!=''&&item.leaveFrom!='null'){
                                  controller.setLeaveDatesFromResponse(leaveFrom: item.leaveFrom??'', leaveTo: item.leaveTo??'');
                                }else{
                                  controller.fromDate.value=null;
                                  controller.toDate.value=null;
                                }
                                showDoctorLeaveDialog(context,item.id??'');
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5
                                ),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                        color: AppColors.primaryColor
                                    )
                                ),
                                child: Center(
                                  child: CustomText(
                                    "Manage Leave",
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,),
                                ),
                              ),
                            )
                          ],
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



  void showEditFeeDialog({required  bool isEditFee,required BuildContext context, required String doctorId,String? fee,String? availability}) {
    final controller = getOrPut(() => HospitalModelController());
    if(isEditFee) {
      controller.feesController.text = fee!;
    }else{
      controller.availabilityController.text=availability!;
    }
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(isEditFee?"Edit Consultation Fees":"Edit Doctor Availability",fontSize: 18,fontWeight: FontWeight.bold,),
                SizedBox(
                  height: SizeConfig.size18,
                ),
                CommonTextField(
                  title: isEditFee?"Consultation Fees":"Availability",
                  hintText: isEditFee?"E.g. 500":"E.g. 10pm to 5pm (Mon to Sat)",
                  keyBoardType: TextInputType.number,
                  textEditController: isEditFee?controller.feesController:controller.availabilityController,
                ),
                SizedBox(
                  height: SizeConfig.size30,
                ),
                Row(
                  children: [
                    Expanded(
                      child: CustomBtn(
                          isValidate:  false,
                          onTap: (){
                          Get.back();
                          }, title: "Cancel"),
                    ),
                    SizedBox(width: SizeConfig.size12,),
                    Expanded(
                      child: CustomBtn(
                        isLoading: controller.editFeeSubmitLoading.value,
                          isValidate: true,
                          onTap: (){
                           controller.updateDoctorsFeesDetails(doctorId,isEditFee);
                          }, title: "Submit"),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
  void showDoctorLeaveDialog(BuildContext context,String doctorId) {
    final controller = getOrPut(() => HospitalModelController());
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const CustomText(
                      "Doctor On Leave",
                        fontSize: 16,
                        fontWeight: FontWeight.w700,

                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: const Icon(Icons.close),
                    )
                  ],
                ),
                const SizedBox(height: 16),

                /// From - To
                Row(
                  children: [
                    Expanded(
                      child: _dateBox(
                        title: "From",
                        value: controller.formattedFrom,
                        onTap: () =>
                            controller.pickDate(context, true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dateBox(
                        title: "To",
                        value: controller.formattedTo,
                        onTap: () =>
                            controller.pickDate(context, false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                /// Leave Days
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (controller.leaveDays > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: CustomText(
                          "${controller.leaveDays} Days Leave",
                          fontSize: 12,
                        ),
                      ),
                    SizedBox(
                      width: SizeConfig.size100,
                      child: CustomBtn(
                          isValidate:  controller.leaveDays == 0?false:true,
                          onTap: (){
                            /// API CALL
                            if(controller.fromDate.value!=null&&controller.toDate.value!=null){
                              controller.updateLeaveStatusToDoctor(doctorId);
                            }
                            /// call your API here
                          }, title: "Submit"),
                    ),
                  ],
                ),

                /// Submit


              ],
            );
          }),
        ),
      ),
    );
  }
  Widget _dateBox({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title,
            fontSize: 12,
            fontWeight: FontWeight.w500,
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border:
              Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomText(
              value.isEmpty ? 'DD/MM/YYYY' : value,

                color: value.isEmpty
                    ? Colors.grey
                    : Colors.black,

            ),
          ),
        ),
      ],
    );
  }

}
