import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_home_screen.dart';
import 'package:BlueEra/features/me/me_tab_registry.dart';
import 'package:BlueEra/features/me/school/view/coming_soon.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HospitalMain extends StatefulWidget {
  const HospitalMain({super.key});

  @override
  State<HospitalMain> createState() => _HospitalMainState();
}

class _HospitalMainState extends State<HospitalMain>
    with TickerProviderStateMixin, RouteAware {
  late TabController _tabController;
  final hospitalServiceAiController =
      getOrPut(() => HospitalServiceAiController());

  bool _hasWebsite = false;

  String get _websiteUrl =>
      hospitalServiceAiController
          .hospitalDataResModel
          ?.value
          .data
          ?.contacts
          ?.firstOrNull
          ?.branch
          ?.website ??
      '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    MeTabRegistry.register(_tabController);
    hospitalServiceAiController.getHospitalFullDetailsController();

    ever(hospitalServiceAiController.hospitalDataResModel!, (_) {
      final newHasWebsite = _websiteUrl.isNotEmpty;
      if (newHasWebsite != _hasWebsite) {
        _hasWebsite = newHasWebsite;
        final currentIndex = _tabController.index;
        MeTabRegistry.unregister(_tabController);
        _tabController.dispose();
        _tabController = TabController(
          length: _hasWebsite ? 3 : 2,
          vsync: this,
          initialIndex: currentIndex.clamp(0, _hasWebsite ? 2 : 1),
        );
        MeTabRegistry.register(_tabController);
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    MeTabRegistry.unregister(_tabController);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showElevation: 0,
        isDrawerMenu: true,
        isLeading: false,
        isMore: true,
        isProfile: false,
        isNotification: !isGuestUser(),
        bellIconNotEmpty: true,
        isGuestLogout: isGuestUser(),
        onNotificationTap: () {
          Navigator.pushNamed(
            context,
            RouteHelper.getNotificationScreenRoute(),
          );
        },
      ),
      backgroundColor: AppColors.white,
      body: SafeArea(
          child: Column(
            children: [
              SizedBox(height: SizeConfig.size12),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryColor,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: AppColors.primaryColor,
                indicatorWeight: 4,
                tabAlignment: TabAlignment.fill,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle:
                const TextStyle(fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: AppStrings.home.tr),
                  if (_hasWebsite) const Tab(text: 'Website'),
                  Tab(text: AppStrings.statistics.tr),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    HospitalHomeScreen(),
                    if (_hasWebsite) CommonWebView( urlLink: _websiteUrl, urlTitle: '',hideAppBar: true,),
                    ComingSoon(),
                  ],
                ),
              ),
            ],
          )
      ),
    );
  }
}

class _HospitalWebView extends StatefulWidget {
  final String url;
  const _HospitalWebView({required this.url});

  @override
  State<_HospitalWebView> createState() => _HospitalWebViewState();
}

class _HospitalWebViewState extends State<_HospitalWebView>
    with AutomaticKeepAliveClientMixin {
  late final WebViewController _webController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final uri = Uri.tryParse(widget.url.startsWith('http')
        ? widget.url
        : 'https://${widget.url}');
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _isLoading = false),
          onPageStarted: (_) => setState(() => _isLoading = true),
        ),
      )
      ..loadRequest(uri ?? Uri.parse('about:blank'));
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        WebViewWidget(controller: _webController),
        if (_isLoading)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
