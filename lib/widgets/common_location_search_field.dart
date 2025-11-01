import 'dart:async';
import 'dart:developer';
import 'package:BlueEra/core/api/model/place_prediction.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';

class CommonLocationSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String title;
  final String hintText;
  final Function(double lat, double lng, String address)? onSelected;

  const CommonLocationSearchField({
    super.key,
    required this.controller,
    this.title = 'Property Location',
    this.hintText = 'E.g. Lucknow, Gomti Nagar...',
    this.onSelected,
  });

  @override
  State<CommonLocationSearchField> createState() =>
      _CommonLocationSearchFieldState();
}

class _CommonLocationSearchFieldState extends State<CommonLocationSearchField> {
  final layerLink = LayerLink();
  final textFieldKey = GlobalKey();
  final scrollController = ScrollController();

  OverlayEntry? overlayEntry;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final predictions = <PlacePrediction>[].obs;
  RxString currentAddress = ''.obs;

  Timer? debounce;
  double latitude = 0.0;
  double longitude = 0.0;

  @override
  void dispose() {
    scrollController.dispose();
    debounce?.cancel();
    overlayEntry?.remove();
    super.dispose();
  }

  void onSearchChanged(String query) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchPredictions(query);
      _updateOverlay();
    });
  }

  /// API CALL
  Future<void> _fetchPredictions(String query) async {
    if (query.trim().isEmpty) {
      predictions.clear();
      _removeOverlay();
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await PlaceRepo().autoCompleteSearch(query: query);
      if (response.statusCode == 200) {
        final data = response.response?.data;
        final list = data?['predictions'] as List? ?? [];
        predictions.assignAll(PlacePrediction.fromList(list));
        log('Predictions found: ${predictions.length}');
      } else {
        errorMessage.value =
            response.data['error_message'] ?? 'Something went wrong';
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void _updateOverlay() {
    if (widget.controller.text.isNotEmpty ||
        isLoading.value ||
        predictions.isNotEmpty ||
        errorMessage.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    final renderBox =
    textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    overlayEntry ??= OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 10,
        width: size.width,
        child: CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 10),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            child: Obx(
                  () => Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _buildOverlayBody(),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry!);
  }

  Widget _buildOverlayBody() {
    if (isLoading.value) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (errorMessage.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: CustomText(
          errorMessage.value,
          color: Colors.red,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w600,
        ),
      );
    } else if (predictions.isEmpty &&
        widget.controller.text.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: CustomText(
          "No results found",
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w600,
        ),
      );
    } else if (predictions.isNotEmpty) {
      return Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        radius: const Radius.circular(4),
        child: ListView.builder(
          controller: scrollController,
          itemCount: predictions.length,
          itemBuilder: (context, index) {
            final item = predictions[index];
            return ListTile(
              leading: const Icon(Icons.location_on_outlined,
                  color: AppColors.mainTextColor),
              title: CustomText(
                item.description ?? '',
                color: AppColors.mainTextColor,
                fontWeight: FontWeight.w700,
              ),
              onTap: () {
                widget.controller.text = item.description ?? '';
                currentAddress.value = item.description ?? '';
                latitude = item.lat ?? 0.0;
                longitude = item.lng ?? 0.0;
                predictions.clear();
                widget.onSelected?.call(latitude, longitude, currentAddress.value);
                _removeOverlay();
              },
            );
          },
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  void _removeOverlay() {
    overlayEntry?.remove();
    overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: layerLink,
      child: CommonTextField(
        key: textFieldKey,
        title: widget.title,
        hintText: widget.hintText,
        pIcon: Icon(Icons.search, color: AppColors.primaryColor),
        textEditController: widget.controller,
        onChange: onSearchChanged,
        sIcon: Obx(() => currentAddress.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            widget.controller.clear();
            currentAddress.value = '';
            predictions.clear();
            _removeOverlay();
          },
        )
            : SizedBox.shrink()),
      ),
    );
  }
}
