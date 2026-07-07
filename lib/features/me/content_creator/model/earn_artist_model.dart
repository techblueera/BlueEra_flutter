// Data models for the Earn-Artist (content-creator) vertical.
//
// Every `fromJson` here is deliberately tolerant: the earn-service returns
// money and ids as strings, nested objects may be null, and list fields may be
// absent. Nothing throws on a missing/oddly-typed field — the Overview tab is
// read-only and must render whatever the backend hands back.

/// Safely coerces any JSON scalar into a trimmed String ('' when null).
String _asString(dynamic v) => v == null ? '' : v.toString().trim();

/// Coerces a String/num into a nullable double (money/ids arrive as strings).
double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().trim());
}

List<String> _asStringList(dynamic v) {
  if (v is List) {
    return v
        .map((e) => _asString(e))
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }
  return const <String>[];
}

Map<String, dynamic> _asMap(dynamic v) =>
    v is Map ? v.map((k, val) => MapEntry(k.toString(), val)) : <String, dynamic>{};

class EarnArtist {
  final String id;
  final String userId;
  final ArtistUser? user;
  final String title;
  final String type;
  final String category;
  final String description;
  final List<String> expertise;
  final List<ArtistBrand> brandCollaborations;
  final List<ArtistChannel> channels;
  final ArtistContactUs? contactUs;
  final ArtistBooking? booking;
  final List<ArtistGallery> gallery;
  final List<ArtistCertificate> certificatesAndAwards;
  final String serviceLogo;

  /// ISO timestamp when the profile was created — not in the documented shape,
  /// but read defensively so the "Joined – …" pill can render if present.
  final String createdAt;

  const EarnArtist({
    required this.id,
    required this.userId,
    required this.user,
    required this.title,
    required this.type,
    required this.category,
    required this.description,
    required this.expertise,
    required this.brandCollaborations,
    required this.channels,
    required this.contactUs,
    required this.booking,
    required this.gallery,
    required this.certificatesAndAwards,
    required this.serviceLogo,
    required this.createdAt,
  });

  factory EarnArtist.fromJson(Map<String, dynamic> json) {
    List<T> mapList<T>(dynamic raw, T Function(Map<String, dynamic>) f) {
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => f(e.map((k, v) => MapEntry(k.toString(), v))))
            .toList(growable: false);
      }
      return <T>[];
    }

    return EarnArtist(
      id: _asString(json['_id'] ?? json['id']),
      userId: _asString(json['userId']),
      user: json['user'] is Map ? ArtistUser.fromJson(_asMap(json['user'])) : null,
      title: _asString(json['title']),
      type: _asString(json['type']),
      category: _asString(json['category']),
      description: _asString(json['description']),
      expertise: _asStringList(json['expertise']),
      // Kept when EITHER an id or display fields are present: the artist GET
      // returns `brandCollaborations` as bare Business-id strings (name/logo
      // empty), so filtering on name/logo alone would silently drop every
      // saved brand. The id is resolved to logo/name client-side for display.
      brandCollaborations: json['brandCollaborations'] is List
          ? (json['brandCollaborations'] as List)
              .map(ArtistBrand.fromDynamic)
              .where(
                  (b) => b.id.isNotEmpty || b.name.isNotEmpty || b.logo.isNotEmpty)
              .toList(growable: false)
          : <ArtistBrand>[],
      channels: mapList(json['channels'], ArtistChannel.fromJson),
      contactUs: json['contactUs'] is Map
          ? ArtistContactUs.fromJson(_asMap(json['contactUs']))
          : null,
      booking: json['booking'] is Map
          ? ArtistBooking.fromJson(_asMap(json['booking']))
          : null,
      gallery: mapList(json['gallery'], ArtistGallery.fromJson),
      certificatesAndAwards:
          mapList(json['certificatesAndAwards'], ArtistCertificate.fromJson),
      serviceLogo: _asString(json['serviceLogo']),
      createdAt: _asString(json['createdAt'] ?? json['created_at']),
    );
  }

  /// Best display name for the profile — falls back through user name.
  String get displayName {
    if (title.isNotEmpty) return title;
    if (user?.name.isNotEmpty ?? false) return user!.name;
    return '';
  }
}

class ArtistUser {
  final String id;
  final String name;
  final String profileImage;

  const ArtistUser({
    required this.id,
    required this.name,
    required this.profileImage,
  });

  factory ArtistUser.fromJson(Map<String, dynamic> json) => ArtistUser(
        id: _asString(json['id'] ?? json['_id']),
        name: _asString(json['name']),
        profileImage: _asString(json['profile_image'] ?? json['profileImage']),
      );
}

class ArtistChannel {
  final String name;
  final String url;
  final String channelId;

  const ArtistChannel({
    required this.name,
    required this.url,
    required this.channelId,
  });

  factory ArtistChannel.fromJson(Map<String, dynamic> json) => ArtistChannel(
        name: _asString(json['name']),
        url: _asString(json['url']),
        channelId: _asString(json['channelId']),
      );
}

class ArtistContactUs {
  final String description;
  final String website;
  final String email;
  final String number;

  const ArtistContactUs({
    required this.description,
    required this.website,
    required this.email,
    required this.number,
  });

  factory ArtistContactUs.fromJson(Map<String, dynamic> json) =>
      ArtistContactUs(
        description: _asString(json['description']),
        website: _asString(json['website']),
        email: _asString(json['email']),
        number: _asString(json['number']),
      );

  bool get isEmpty =>
      description.isEmpty &&
      website.isEmpty &&
      email.isEmpty &&
      number.isEmpty;
}

class ArtistBooking {
  final double? minimumPrice;
  final double? price;
  final String bookingType;
  final String priceType;

  const ArtistBooking({
    required this.minimumPrice,
    required this.price,
    required this.bookingType,
    required this.priceType,
  });

  factory ArtistBooking.fromJson(Map<String, dynamic> json) => ArtistBooking(
        minimumPrice: _asDouble(json['minimumPrice']),
        price: _asDouble(json['price']),
        bookingType: _asString(json['bookingType']),
        priceType: _asString(json['priceType']),
      );

  /// Human label for the price cadence (`perHour` → `Hour`, `perVisit` →
  /// `Visit`); falls back to the raw value for anything unexpected.
  String get priceTypeLabel {
    switch (priceType) {
      case 'perHour':
        return 'Hour';
      case 'perVisit':
        return 'Visit';
      default:
        return priceType;
    }
  }

  /// Whole-number price when it's integral (₹600 not ₹600.0), else the double.
  String get priceLabel {
    final p = price;
    if (p == null) return '';
    return p == p.roundToDouble() ? p.toInt().toString() : p.toString();
  }
}

class ArtistGallery {
  final String name;
  final List<String> images;

  const ArtistGallery({required this.name, required this.images});

  factory ArtistGallery.fromJson(Map<String, dynamic> json) => ArtistGallery(
        name: _asString(json['name']),
        images: _asStringList(json['images']),
      );
}

/// A media item on a certificate — the backend returns presigned download
/// URLs under `url`/`key` alongside a `type` (image/video). Only the URL is
/// needed for display.
class ArtistCertificate {
  final String name;
  final String description;
  final List<String> media;

  const ArtistCertificate({
    required this.name,
    required this.description,
    required this.media,
  });

  factory ArtistCertificate.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'];
    final media = <String>[];
    if (rawMedia is List) {
      for (final m in rawMedia) {
        if (m is Map) {
          final url = _asString(m['url'] ?? m['key'] ?? m['media']);
          if (url.isNotEmpty) media.add(url);
        } else {
          final url = _asString(m);
          if (url.isNotEmpty) media.add(url);
        }
      }
    }
    return ArtistCertificate(
      name: _asString(json['name']),
      description: _asString(json['description']),
      media: media,
    );
  }

  String get firstMedia => media.isNotEmpty ? media.first : '';
}

/// A brand collaboration. On create these are sent as bare id strings; on GET
/// the backend may populate `{ name, logo, ... }`. Tolerant to both shapes.
class ArtistBrand {
  final String id;
  final String name;
  final String logo;
  final String subLabel;

  const ArtistBrand({
    required this.id,
    required this.name,
    required this.logo,
    required this.subLabel,
  });

  factory ArtistBrand.fromJson(Map<String, dynamic> json) => ArtistBrand(
        id: _asString(json['_id'] ?? json['id']),
        name: _asString(json['name'] ?? json['brandName'] ?? json['title']),
        logo: _asString(
            json['logo'] ?? json['brandLogo'] ?? json['image'] ?? json['serviceLogo']),
        subLabel: _asString(
            json['subLabel'] ?? json['location'] ?? json['city'] ?? json['category']),
      );

  /// Tolerates a plain id string in the collaborations array (unpopulated).
  factory ArtistBrand.fromDynamic(dynamic v) {
    if (v is Map) {
      return ArtistBrand.fromJson(
          v.map((k, val) => MapEntry(k.toString(), val)));
    }
    return ArtistBrand(id: _asString(v), name: '', logo: '', subLabel: '');
  }
}
