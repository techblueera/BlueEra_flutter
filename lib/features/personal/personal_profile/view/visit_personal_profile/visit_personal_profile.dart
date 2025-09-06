import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/view_achivements_tab.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/view_comments_tab.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/view_personal_post_tab.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/view_testimonial_tab.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/common_back_app_bar.dart';

class VisitPersonalProfileTabs extends StatelessWidget {
  final List<String> tabs;
  final TabController tabController;
  final Function(int Index)? onTab;

  const VisitPersonalProfileTabs({
    super.key,
    required this.tabs,
    required this.tabController, this.onTab,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom Tab UI
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 0),
            itemCount: tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final selected = tabController.index == index;
              return GestureDetector(
                onTap: (){
                  tabController.animateTo(index);
                  if(onTab!=null){
                    onTab!(index);
                  }
                },
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 1, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.skyBlueDF
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: selected
                        ? null
                        : Border.all(
                            color: const Color.fromRGBO(153, 153, 153, 0.75),
                          ),
                  ),
                  child: Center(
                    child: Text(
                      tabs[index],
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color.fromRGBO(110, 109, 109, 1),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class VisitPersonalProfile extends StatefulWidget {
  const VisitPersonalProfile({super.key});

  @override
  State<VisitPersonalProfile> createState() => _VisitPersonalProfileState();
}

class _VisitPersonalProfileState extends State<VisitPersonalProfile> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> tabs = [
    'My Services',
    'Posts',
    'Achievements',
    'Testimonials',
    'Comments'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Update tab selection state
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isLeading: true,
        title: '',
        isShareButton: true,
        isQrCodeButton: true,
        onShareTap: () {},
        onQrCodeTap: () {},
      ),
      backgroundColor: const Color(0xFFF9F9F9),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 18.0, top: 4),
                        child: Container(
                          padding: EdgeInsets.all(3), // border thickness
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: Colors.grey,
                            child: Text("BE"), // Use NetworkImage if needed
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CustomText(
                                      "Alex John",
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    SizedBox(width: 4),
                                    SvgPicture.asset(
                                        AppIconAssets.verify_v_profile),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    SvgPicture.asset(
                                        AppIconAssets.chat_info_pop),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const CustomText("UI/UX Designer",
                                fontSize: 13,
                                color: Color.fromRGBO(107, 124, 147, 1)),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.only(right: 38.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: const [
                                  _StatBlock(count: "20", label: "Posts"),
                                  _StatBlock(count: "10k", label: "Followers"),
                                  _StatBlock(count: "500K", label: "Following"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CustomText(
                  "UI/UX Designer with a passion for clean, user-focused design. Currently crafting seamless experiences at BlueEra.",
                  textAlign: TextAlign.start,
                  fontSize: 13,
                  color: Colors.black,
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  children: [
                    SvgPicture.asset(
                      AppIconAssets.link_pref_profile,
                      width: 25,
                      height: 25,
                    ),
                    _SocialLink(text: "Instagram"),
                    _SocialLink(text: "YouTube"),
                    _SocialLink(text: "LinkedIn"),
                    _SocialLink(text: "Website"),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  8), // Set your desired radius here
                            ),
                            side: BorderSide(color: AppColors.primaryColor),
                            backgroundColor: AppColors.primaryColor),
                        onPressed: () async {

                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomText(
                                "Follow",
                                color: AppColors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              SvgPicture.asset(
                                  AppIconAssets.profile_orders_view_icon),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: SizeConfig.size12,
                    ),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  8), // Set your desired radius here
                            ),
                            side: BorderSide(
                              color: AppColors.primaryColor,
                            )),
                        onPressed: () {},
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomText(
                                "Request Chat",
                                color: AppColors.primaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              SvgPicture.asset(
                                  AppIconAssets.profile_request_chat)
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CustomText("Bio",
                              fontWeight: FontWeight.w800, fontSize: 15),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        children: [
                          Text(
                            "I'm a passionate UI/UX Designer with 3+ years of experience in creating intuitive and user-friendly digital products. I focus on clean layouts good jood, attention to detail, and designing with purpose.",
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                          Text(
                            "Read more",
                            style: const TextStyle(
                                fontSize: 13, height: 1.4, color: Colors.blue),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: VisitPersonalProfileTabs(
                    tabs: tabs,
                    tabController: _tabController,
                  ),
                ),
                SizedBox(
                    height: 1800,
                    child: TabBarView(
                        physics: NeverScrollableScrollPhysics(),
                        controller: _tabController,
                        children: [
                          SizedBox(),
                          ViewPersonalPostTab(),
                          ViewAchivementsTab(),
                          TestimonialPage(),
                          ViewCommentsTab()
                        ]))
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String count;
  final String label;

  const _StatBlock({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          count,
          fontSize: 14,
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
        CustomText(
          label,
          fontSize: 14,
          color: Color.fromRGBO(107, 124, 147, 1),
          fontWeight: FontWeight.w400,
        ),
      ],
    );
  }
}

class _SocialLink extends StatelessWidget {
  final String text;

  const _SocialLink({required this.text});

  @override
  Widget build(BuildContext context) {
    return CustomText(text,
        fontSize: 13, color: Color(0xFF0085FF), fontWeight: FontWeight.w900);
  }
}
