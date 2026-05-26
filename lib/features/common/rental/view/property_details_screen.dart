import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> property;

  const PropertyDetailsScreen({super.key, required this.property});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  late final Map<String, dynamic> p;
  int _currentImage = 0;
  bool _showFullDesc = false;

  String get _name => p['propertyName'] ?? '';
  String get _desc => p['description'] ?? '';
  String get _type => p['propertyType'] ?? '';
  String get _listingType => p['listingType'] ?? '';
  double get _rating => (p['rating'] ?? 0).toDouble();
  int get _reviews => (p['reviews'] ?? 0);
  List get _images => p['propertyImages'] ?? [];

  @override
  void initState() {
    super.initState();
    p = widget.property;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: _name,
        isShadowShow: false,
        showElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: SizeConfig.size12),
            _buildTitleCard(),
            SizedBox(height: SizeConfig.size10),
            _buildKeyHighlightsCard(),
            SizedBox(height: SizeConfig.size10),
            _buildPropertyInfoCard(),
            if (_images.length > 1) ...[
              SizedBox(height: SizeConfig.size10),
              _buildGalleryCard(),
            ],
            SizedBox(height: SizeConfig.size24),
          ],
        ),
      ),
    );
  }

  // ── Image Slider ──

  Widget _buildImageSlider() {
    if (_images.isEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        child: Container(
          height: 220,
          color: AppColors.primaryColor.withValues(alpha: 0.06),
          child: Center(
            child: Icon(Icons.holiday_village_outlined,
                size: 60,
                color: AppColors.primaryColor.withValues(alpha: 0.3)),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: _images.length,
              onPageChanged: (i) => setState(() => _currentImage = i),
              itemBuilder: (_, i) => Image.network(
                _images[i],
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.primaryColor.withValues(alpha: 0.06),
                  child: const Center(
                      child: Icon(Icons.broken_image_outlined, size: 40)),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.mainTextColor.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    AppIconAssets.pencilEditIcon,
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
            if (_images.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _images.length,
                    (i) => Container(
                      width: _currentImage == i ? 20 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: _currentImage == i
                            ? AppColors.primaryColor
                            : Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Title + Price + Location Card ──

  Widget _buildTitleCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.size14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            spreadRadius: 0.5,
            offset: const Offset(-5, 0),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            spreadRadius: 0.5,
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageSlider(),
          Padding(
            padding: EdgeInsets.all(SizeConfig.size15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomText(
                        _name,
                        fontSize: SizeConfig.large18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mainTextColor,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _editIcon(),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.secondaryTextColor
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: CustomText(
                        _typeLabel(_type),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.star_rounded,
                        size: 15, color: AppColors.rating),
                    const SizedBox(width: 3),
                    CustomText(
                      '${_rating.toStringAsFixed(1)} ($_reviews reviews)',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
                if (_desc.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  CustomText(
                    _showFullDesc
                        ? _desc
                        : (_desc.length > 120
                            ? '${_desc.substring(0, 120)}...'
                            : _desc),
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor,
                  ),
                  if (_desc.length > 120)
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showFullDesc = !_showFullDesc),
                      child: CustomText(
                        _showFullDesc ? 'Show Less' : 'Read More',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildPrice()),
                    _editIcon(),
                  ],
                ),
                const SizedBox(height: 10),
                _buildLocationStrip(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrice() {
    final priceRange = p['priceRange'];
    final hasRange = priceRange != null &&
        priceRange is Map &&
        (priceRange['min'] ?? 0) > 0;
    final num price = p['price'] ?? 0;

    String priceStr;
    if (hasRange) {
      priceStr =
          '₹${_fmtPrice(priceRange['min'])} - ₹${_fmtPrice(priceRange['max'])}';
    } else {
      priceStr = '₹${_fmtPrice(price)}';
    }
    if (_listingType == 'Rent') priceStr += '/mo';

    return CustomText(
      priceStr,
      fontSize: SizeConfig.extraLarge,
      fontWeight: FontWeight.w800,
      color: AppColors.mainTextColor,
    );
  }

  Widget _buildLocationStrip() {
    final loc = _extractLocation();
    if (loc.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined,
              size: 15, color: AppColors.primaryColor),
          const SizedBox(width: 6),
          Expanded(
            child: CustomText(
              loc,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 6),
          _editIcon(),
        ],
      ),
    );
  }

  // ── Key Highlights Card ──

  Widget _buildKeyHighlightsCard() {
    final highlights = _extractHighlights();
    if (highlights.isEmpty) return const SizedBox.shrink();

    return CustomFormCard(
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.size14),
      isBoxShadowAvail: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Key Highlights',
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                highlights.map((h) => _highlightChip(h.$1, h.$2)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _highlightChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.secondaryTextColor.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryColor),
          const SizedBox(width: 6),
          CustomText(
            label,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
          ),
        ],
      ),
    );
  }

  // ── Property Information Card ──

  Widget _buildPropertyInfoCard() {
    final info = _extractPropertyInfo();
    if (info.isEmpty) return const SizedBox.shrink();

    return CustomFormCard(
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.size14),
      isBoxShadowAvail: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Property Information',
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < info.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: CustomText(
                      info[i].$1,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                  Flexible(
                    child: CustomText(
                      info[i].$2,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
            if (i < info.length - 1)
              Divider(
                height: 1,
                color:
                    AppColors.secondaryTextColor.withValues(alpha: 0.1),
              ),
          ],
        ],
      ),
    );
  }

  // ── Gallery Card ──

  Widget _buildGalleryCard() {
    return CustomFormCard(
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.size14),
      isBoxShadowAvail: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Gallery',
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          ),
          const SizedBox(height: 10),
          _buildStaggeredGallery(),
        ],
      ),
    );
  }

  Widget _buildStaggeredGallery() {
    final imgs = _images;
    final rows = <Widget>[];

    for (var i = 0; i < imgs.length; i += 2) {
      final hasTwo = i + 1 < imgs.length;
      rows.add(
        SizedBox(
          height: 140,
          child: Row(
            children: [
              Expanded(
                flex: hasTwo ? 3 : 1,
                child: _galleryImage(imgs[i]),
              ),
              if (hasTwo) ...[
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _galleryImage(imgs[i + 1]),
                ),
              ],
            ],
          ),
        ),
      );
      if (i + 2 < imgs.length) rows.add(const SizedBox(height: 8));
    }

    return Column(children: rows);
  }

  Widget _galleryImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        height: double.infinity,
        width: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.primaryColor.withValues(alpha: 0.06),
          child: const Center(
              child: Icon(Icons.broken_image_outlined, size: 24)),
        ),
      ),
    );
  }

  // ── Edit Icon ──

  Widget _editIcon() {
    return GestureDetector(
      onTap: () {},
      child: SvgPicture.asset(
        AppIconAssets.pencilEditIcon,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
          AppColors.secondaryTextColor,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  // ── Data Extractors ──

  String _extractLocation() {
    for (final key in [
      'houseAndApartment',
      'landAndPlots',
      'shopAndOffices',
      'newProjectsAndProperties',
      'pgAndGuestHouse',
    ]) {
      final s = p[key];
      if (s != null && s['propertyLocation'] != null) {
        return s['propertyLocation'];
      }
    }
    return '';
  }

  List<(IconData, String)> _extractHighlights() {
    final result = <(IconData, String)>[];
    final ha = p['houseAndApartment'];
    final lp = p['landAndPlots'];
    final so = p['shopAndOffices'];
    final np = p['newProjectsAndProperties'];
    final pg = p['pgAndGuestHouse'];

    if (ha != null) {
      if (ha['areaDetails'] != null && ha['areaDetails'].toString().isNotEmpty)
        result.add((Icons.square_foot, ha['areaDetails']));
      if (ha['bathrooms'] != null)
        result.add((Icons.bathtub_outlined, '${ha['bathrooms']} Bathrooms'));
      if (ha['totalFloors'] != null)
        result.add((Icons.layers_outlined, '${ha['totalFloors']} Floors'));
      if (ha['bhk'] != null)
        result.add((Icons.bed_outlined, '${ha['bhk']} BHK'));
    } else if (lp != null) {
      final plot = lp['plotAreaDetails'];
      if (plot?['totalArea'] != null)
        result.add((Icons.square_foot, plot['totalArea']));
      if (plot?['length'] != null)
        result.add((Icons.straighten, 'L: ${plot['length']}'));
      if (plot?['breadth'] != null)
        result.add((Icons.straighten, 'B: ${plot['breadth']}'));
    } else if (so != null) {
      if (so['superBuiltupArea'] != null)
        result.add((Icons.square_foot, so['superBuiltupArea']));
      if (so['washrooms'] != null)
        result.add((Icons.bathtub_outlined, '${so['washrooms']} Washrooms'));
      if (so['carParkings'] != null)
        result.add((Icons.local_parking, '${so['carParkings']} Parking'));
    } else if (np != null) {
      if (np['area'] != null) result.add((Icons.square_foot, np['area']));
      if (np['noOfTowers'] != null)
        result.add((Icons.apartment_outlined, '${np['noOfTowers']} Towers'));
      if (np['noOfFloors'] != null)
        result.add((Icons.layers_outlined, '${np['noOfFloors']} Floors'));
    } else if (pg != null) {
      if (pg['roomType'] != null)
        result.add((Icons.meeting_room_outlined, pg['roomType']));
      if (pg['furnishing'] != null)
        result.add((Icons.chair_outlined, pg['furnishing']));
    }
    return result;
  }

  List<(String, String)> _extractPropertyInfo() {
    final result = <(String, String)>[];
    final ha = p['houseAndApartment'];
    final lp = p['landAndPlots'];
    final so = p['shopAndOffices'];
    final np = p['newProjectsAndProperties'];
    final pg = p['pgAndGuestHouse'];

    if (ha != null) {
      _add(result, 'Type', ha['houseApartmentType']);
      _add(result, 'BHK', ha['bhk']);
      _add(result, 'Bathrooms', ha['bathrooms']);
      _add(result, 'Availability', ha['availabilityStatus']);
      _add(result, 'Furnishing', ha['furnishing']);
      _add(result, 'Listed By', ha['listedBy']);
      _add(result, 'Bachelors Allowed', ha['bachelorAllowed']);
      _add(result, 'Area Details', ha['areaDetails']);
      _add(result, 'Maintenance (Monthly)', ha['maintenance']);
      _add(result, 'Total Floors', ha['totalFloors']);
      _add(result, 'Car Parking', ha['carParking']);
      _add(result, 'Facing', ha['facing']);
    } else if (lp != null) {
      _add(result, 'Project Type', lp['projectType']);
      _add(result, 'Listed By', lp['listedBy']);
      final plot = lp['plotAreaDetails'];
      if (plot != null) {
        _add(result, 'Plot Area', plot['totalArea']);
        _add(result, 'Length', plot['length']);
        _add(result, 'Breadth', plot['breadth']);
      }
      _add(result, 'Facing', lp['facing']);
    } else if (so != null) {
      _add(result, 'Furnishing', so['furnishing']);
      _add(result, 'Project Status', so['projectStatus']);
      _add(result, 'Listed By', so['listedBy']);
      _add(result, 'Super Built-Up Area', so['superBuiltupArea']);
      _add(result, 'Maintenance (Monthly)', so['maintenance']);
      _add(result, 'Car Parking', so['carParkings']);
      _add(result, 'Washrooms', so['washrooms']);
    } else if (np != null) {
      _add(result, 'Project Type', np['projectType']);
      _add(result, 'Project Status', np['projectStatus']);
      _add(result, 'Property Type', np['typeOfProperty']);
      _add(result, 'Area', np['area']);
      final launch = np['projectLaunchInformation'];
      if (launch != null) {
        _add(result, 'Builder Name', launch['builderName']);
        _add(result, 'RERA No.', launch['reraRegistrationNumber']);
      }
      _add(result, 'No. of Towers', np['noOfTowers']);
      _add(result, 'No. of Floors', np['noOfFloors']);
      _add(result, 'Facing', np['facing']);
      _addAmenities(result, np['keyAmenities']);
    } else if (pg != null) {
      _add(result, 'Subtype', pg['subType']);
      _add(result, 'Room Type', pg['roomType']);
      _add(result, 'Attached Bathroom', pg['attachedBathroom']);
      _add(result, 'Furnishing', pg['furnishing']);
      _add(result, 'Listed By', pg['listedBy']);
      _add(result, 'Car Parking', pg['carParking']);
      _add(result, 'Meals Included', pg['mealsIncluded']);
      _addAmenities(result, pg['keyAmenities']);
    }
    return result;
  }

  void _add(List<(String, String)> list, String label, dynamic value) {
    if (value != null && value.toString().isNotEmpty) {
      list.add((label, value.toString()));
    }
  }

  void _addAmenities(List<(String, String)> list, dynamic amenities) {
    if (amenities == null) return;
    if (amenities is List && amenities.isNotEmpty) {
      list.add(('Key Amenities', amenities.join(', ')));
    } else if (amenities is String && amenities.isNotEmpty) {
      list.add(('Key Amenities', amenities));
    }
  }

  String _fmtPrice(num price) {
    final str = price.toInt().toString();
    if (str.length <= 3) return str;
    final last3 = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    final formatted = rest.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{2})+(?!\d))'), (m) => '${m[1]},');
    return '$formatted,$last3';
  }

  String _typeLabel(String type) {
    const labels = {
      'HouseAndApartment': 'House & Apartment',
      'LandAndPlots': 'Land & Plots',
      'ShopAndOffices': 'Shop & Offices',
      'NewProjectsAndProperties': 'New Projects',
      'PGAndGuestHouse': 'PG & Guest House',
    };
    return labels[type] ?? type;
  }
}
