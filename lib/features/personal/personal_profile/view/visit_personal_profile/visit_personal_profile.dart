import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

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
                      width: 1,
                            color:  Color(0xFF505050),
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
