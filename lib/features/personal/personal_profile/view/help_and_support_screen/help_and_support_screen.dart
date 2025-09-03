import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/api/model/support_model.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../../widgets/common_search_bar.dart';
import '../../../../../widgets/horizontal_tab_selector.dart';
import 'help_and_support_controller.dart';


class HelpAndSupportScreen extends StatefulWidget {
  const HelpAndSupportScreen({super.key});

  @override
  State<HelpAndSupportScreen> createState() => _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends State<HelpAndSupportScreen> { 
  List<SupportCase> allList = [];

  

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HelpAndSupportController>(
      init: HelpAndSupportController(),
      builder: (helpController) {
     return  Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: CommonBackAppBar(
          onBackTap: () {
            if (helpController.index == '0') {
              Navigator.pop(context);
            } else {
              helpController.setIndex("0");
              helpController.setTitle("Help & Support");
            }
          },
          title: helpController.title,
          isLeading: true,
        ),
        body: Padding(
          padding: EdgeInsets.all(SizeConfig.size16),
          child: Column(
                children: [
                  if (helpController.index == '1') ...[
                    SizedBox(height: SizeConfig.size20),
                    _buildContactUsSection(helpController),
                  ] else if (helpController.index == '2') ...[
                    SizedBox(height: SizeConfig.size20),
                    _buildHelpFormSection(helpController),
                  ] else if (helpController.index == '3') ...[
                    QueriesCard(),
                  ] else if (helpController.index == '4') ...[
                    _FAQCard(),
                  ] else ...[
                    Column(
                      children: [
                        SizedBox(height: SizeConfig.size20),
                        _helpServiceCard(
                          AppIconAssets.helpIcon,
                          'Customer Support',
                          () {
                            helpController.setIndex("1");
                            helpController.setTitle("Customer Support");
                          },
                        ),
                        SizedBox(height: SizeConfig.size20),
                        _helpServiceCard(
                          AppIconAssets.mailIcon,
                          'Mail Us',
                          () {
                            helpController.setIndex("2");
                            helpController.setTitle("Mail Us");
                          },
                        ),
                        SizedBox(height: SizeConfig.size20),
                        _helpServiceCard(
                          AppIconAssets.queriIcon,
                          'Queries',
                          () {
                            helpController.setIndex("3");
                            helpController.setTitle("Queries");
                          },
                        ),
                        SizedBox(height: SizeConfig.size20),
                        _helpServiceCard(
                          AppIconAssets.FAQIcon,
                          'FAQ',
                          () {
                            helpController.setIndex("4");
                            helpController.setTitle("FAQ");
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              )
        ),
      );
    },);
  }
}

Widget _helpServiceCard(String value1, value2, GestureTapCallback? onTap) {
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(
          vertical: SizeConfig.size4, horizontal: SizeConfig.size4),
      margin: EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                margin: EdgeInsets.all(SizeConfig.size10),
                padding: EdgeInsets.all(SizeConfig.size10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: AppColors.primaryColor.withOpacity(0.3),
                ),
                child: SvgPicture.asset(
                  value1,
                  height: 18,
                  width: 18,
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              CustomText(
                value2,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(SizeConfig.size10),
            child: InkWell(
              onTap: onTap,
              child: SvgPicture.asset(
                AppIconAssets.frontArrow,
                height: 18,
                width: 18,
                color: Colors.black,
              ),
            ),
          )
        ],
      ),
    ),
  );
}

Widget _FAQCard() {
  List<String> FAQList = [
    "How can I list my business on the app?",
    "Can I sell physical and digital products on the app?",
    "What are the different ways I can earn through this app?",
    "How does business verification work, and why is it important?",
    "Forem ipsum dolor sit amet, consectetur adipiscing elit.",
    "Forem ipsum dolor sit amet, consectetur adipiscing elit."
  ];
  return Flexible(
      child: Container(
          padding: EdgeInsets.symmetric(
              vertical: SizeConfig.size4, horizontal: SizeConfig.size4),
          margin: EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListView.builder(
            itemCount: FAQList.length,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: SizeConfig.size6, horizontal: SizeConfig.size6),
                  child: Column(
                    children: [
                      SizedBox(height: SizeConfig.size8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: CustomText(
                              FAQList[index].toString(),
                              fontSize: SizeConfig.large,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              maxLines: 2,
                            ),
                          ),
                          InkWell(
                            onTap: () {},
                            child: SvgPicture.asset(
                              AppIconAssets.add,
                              height: 18,
                              width: 18,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Divider(
                        thickness: 0.1,
                        color: Colors.grey,
                      ),
                    ],
                  ));
            },
          )));
}

class QueriesCard extends StatefulWidget {
  @override
  _QueriesCardState createState() => _QueriesCardState();
}

class _QueriesCardState extends State<QueriesCard> {
  List<SupportCase> list = [];
  final HelpAndSupportController helpController =
      Get.put(HelpAndSupportController());

  int selectedIndex = 0;

  final List<String> postTab = [
    "All",
    "Resolved",
    "In Progress",
    "Needs Attention"
  ];

  final ValueNotifier<String> _searchTextNotifier = ValueNotifier('');
  final TextEditingController _searchController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDataForTab(0); // Initial load
  }

  Future<void> _performSearch(String caseId) async {
    setState(() {
      isLoading = true;
      list.clear();
    });

    await helpController.getSearchById(caseId);

    setState(() {
      list = helpController.allList;
      isLoading = false;
    });
  }

  Future<void> _fetchDataForTab(int index) async {
    setState(() {
      selectedIndex = index;
      isLoading = true;
      list.clear();
    });

    final statusMap = {
      0:'--',
      1: "Resolved",
      2: "In Progress",
      3: "Needs Attention",
    };

    final query = statusMap[index] ?? "--"; // "--" for All tab

    await helpController.getSupportQuery(query);

    setState(() {
      list = helpController.allList;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonSearchBar(
            backgroundColor: Colors.grey[300],
            controller: _searchController,
            onSearchTap: () {
              FocusScope.of(context).unfocus(); // Hide keyboard
              final query = _searchTextNotifier.value.trim();
              if (query.isNotEmpty) {
                _performSearch(query);
              } else {
                _fetchDataForTab(selectedIndex); // fallback to list
              }
            },
            onClearCallback: () {
              _searchController.clear();
              _searchTextNotifier.value = '';
              _fetchDataForTab(selectedIndex); // show default data again
            },
          ),
          SizedBox(height: SizeConfig.size20),
          HorizontalTabSelector(
            tabs: postTab,
            selectedIndex: selectedIndex,
            onTabSelected: (index, value) async {
              _searchController.clear(); // clear previous search
              _searchTextNotifier.value = ''; // reset
              _fetchDataForTab(index);
            },
            labelBuilder: (label) => label,
          ),
          SizedBox(height: SizeConfig.size10),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildSelectedTabContent(list),
          ),
        ],
      ),
    );
  }
}

int selectedIndex = 0;

Widget _buildSelectedTabContent(List<SupportCase> list) {
  switch (selectedIndex) {
    case 0:
      return buildQueryList(list);
    case 1:
      return buildQueryList(list);
    case 2:
      return buildQueryList(list);
    case 3:
      return buildQueryList(list);
    default:
      return SizedBox();
  }
}

Widget buildQueryList(List<SupportCase> list) {
  if (list.isEmpty) {
    return Center(child: Text("No data found."));
  }
  return ListView.builder(
    itemCount: list.length,
    itemBuilder: (context, index) {
      final item = list[index];

      Color statusColor;
      switch (item.status) {
        case 'Resolved':
          statusColor = Colors.green;
          break;
        case 'In Progress':
          statusColor = Colors.orange;
          break;
        case 'Needs Attention':
          statusColor = Colors.red;
          break;
        default:
          statusColor = Colors.grey;
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: CustomText(
                  item.message,
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                )
                    // Text(
                    //   item.message,
                    //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    // ),
                    ),
                CustomText(
                  DateFormat('MMM d')
                      .format(DateTime.parse(item.createdAt.toString())),
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  "Case ID: ${item.caseId}",
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
                CustomText(
                  item.status,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ],
            ),
            Divider(height: 20, thickness: 1),
          ],
        ),
      );
    },
  );
}

Widget _buildContactUsSection(HelpAndSupportController controller) {
  return Container(
    padding: EdgeInsets.symmetric(
        vertical: SizeConfig.size10, horizontal: SizeConfig.size10),
    margin: EdgeInsets.symmetric(horizontal: 1),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'Contact Us',
          fontSize: SizeConfig.large,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        SizedBox(height: SizeConfig.size8),
        CustomText(
          'Morem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate.',
          fontSize: SizeConfig.small,
          color: Colors.grey[600],
        ),
        SizedBox(height: SizeConfig.size16),

        // Phone Number Input with Action Buttons
        Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size16,
                  vertical: SizeConfig.size12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Obx(() => CustomText(
                      controller.phoneNumber.value,
                      fontSize: SizeConfig.medium,
                      color: Colors.black87,
                    )),
              ),
            ),
            SizedBox(width: SizeConfig.size12),

            // Call Button
            GestureDetector(
              onTap: controller.makePhoneCall,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.phone,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            SizedBox(width: SizeConfig.size8),

            // Copy Button
            GestureDetector(
              onTap: controller.copyPhoneNumber,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.copy,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}


Widget _buildHelpFormSection(HelpAndSupportController controller) {
  return Container(
    padding: EdgeInsets.symmetric(
        vertical: SizeConfig.size10, horizontal: SizeConfig.size10),
    margin: EdgeInsets.symmetric(horizontal: 1),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'What Type of Help & Support You Need?',
          fontSize: SizeConfig.large,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        SizedBox(height: SizeConfig.size20),

        // Email Input
        _buildInputField(
          label: 'Email',
          hintText: 'Enter Your Email',
          onChanged: controller.setEmail,
          keyboardType: TextInputType.emailAddress,
          controller: controller.emailController,
        ),
        SizedBox(height: SizeConfig.size16),

        // Message Input
        _buildInputField(
          label: 'Message',
          hintText: 'Type Here What Type of Help & Support You Need.....',
          onChanged: controller.setMessage,
          maxLines: 4,
          keyboardType: TextInputType.multiline,
          controller: controller.messageController,
        ),
        SizedBox(height: SizeConfig.size24),

        // Submit Button
        SizedBox(
          width: double.infinity,
          child: Obx(() => ElevatedButton(
                onPressed:
                    controller.isLoading.value ? null : controller.submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  // padding: EdgeInsets.symmetric(
                  //   vertical: SizeConfig.size16,
                  // ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: controller.isLoading.value
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : CustomText(
                        'Submit',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
              )),
        ),
      ],
    ),
  );
}

Widget _buildInputField({
  required String label,
  required String hintText,
  required Function(String) onChanged,
  int maxLines = 1,
  TextInputType? keyboardType,
  TextEditingController? controller,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CustomText(
        label,
        fontSize: SizeConfig.small,
        color: Colors.grey[600],
      ),
      SizedBox(height: SizeConfig.size8),
      TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: SizeConfig.medium,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: AppColors.primaryColor,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size16,
            vertical: SizeConfig.size12,
          ),
        ),
        style: TextStyle(
          fontSize: SizeConfig.medium,
          color: Colors.black87,
        ),
      ),
    ],
  );
}
