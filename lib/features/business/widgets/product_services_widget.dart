import 'package:flutter/material.dart';

import '../../personal/personal_profile/view/visit_personal_profile/visit_personal_profile.dart';

class ProductServicesWidget extends StatefulWidget {
  const ProductServicesWidget({super.key});

  @override
  State<ProductServicesWidget> createState() => _ProductServicesWidgetState();
}

class _ProductServicesWidgetState extends State<ProductServicesWidget> with TickerProviderStateMixin{
  @override
  Widget build(BuildContext context) {
    TabController _tabController=TabController(length: 2, vsync: this);
    List<String> tabs=[
      "Product",
      "Services"
    ];


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: VisitPersonalProfileTabs(
            tabs: tabs,
            tabController: _tabController,
          ),
        ),

        const SizedBox(height: 25),
        SizedBox(
          height: 200,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List<Widget>.generate(6, (index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: SizedBox(
                        height: 185,
                        // width: 210,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Image.asset(
                                'assets/images/product.png',
                                height: 130,
                                width: 156,
                                fit: BoxFit.fill,
                              ),
                            ),
                            const SizedBox(height: 9,),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset(
                                          'assets/images/burgerking.png',
                                          width: 35,
                                          height: 35,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.start,
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Burger King",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Row(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                            children: [
                                              Row(
                                                children: List<Widget>.generate(5, (
                                                    starIndex,
                                                    ) {
                                                  return Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.star,
                                                        size: 10,
                                                        color: Colors.amber,
                                                      ),
                                                    ],
                                                  );
                                                }),
                                              ),
                                              Text(
                                                "5.0",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
