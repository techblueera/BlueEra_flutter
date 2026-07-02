/// Models for `GET /earn-service/creator` — the Content-Creator tab.
/// One call returns the program (bonus + rules), the user's progress, and the
/// list of videos they've submitted.

int _int(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

List<String> _strList(dynamic v) => (v as List?)
        ?.map((e) => e?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList() ??
    const [];

class CreatorData {
  final CreatorProgram program;
  final CreatorProgress progress;
  final List<CreatorVideo> videos;

  const CreatorData({
    this.program = const CreatorProgram(),
    this.progress = const CreatorProgress(),
    this.videos = const [],
  });

  factory CreatorData.fromJson(Map<String, dynamic> j) => CreatorData(
        program: CreatorProgram.fromJson(
            (j['program'] as Map?)?.cast<String, dynamic>() ?? const {}),
        progress: CreatorProgress.fromJson(
            (j['progress'] as Map?)?.cast<String, dynamic>() ?? const {}),
        videos: ((j['videos'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => CreatorVideo.fromJson(e.cast<String, dynamic>()))
            .toList(),
      );
}

class CreatorProgram {
  final int totalAmount;
  final int perApprovalAmount;
  final List<String> termsAndConditions;
  final List<String> requirements;
  final bool isActive;

  const CreatorProgram({
    this.totalAmount = 0,
    this.perApprovalAmount = 0,
    this.termsAndConditions = const [],
    this.requirements = const [],
    this.isActive = false,
  });

  factory CreatorProgram.fromJson(Map<String, dynamic> j) => CreatorProgram(
        totalAmount: _int(j['totalAmount']),
        perApprovalAmount: _int(j['perApprovalAmount']),
        termsAndConditions: _strList(j['termsAndConditions']),
        requirements: _strList(j['requirements']),
        isActive: j['isActive'] == true,
      );
}

class CreatorProgress {
  final int totalCredited;
  final int remaining;
  final int approvedCount;
  final int pendingCount;
  final int rejectedCount;

  const CreatorProgress({
    this.totalCredited = 0,
    this.remaining = 0,
    this.approvedCount = 0,
    this.pendingCount = 0,
    this.rejectedCount = 0,
  });

  factory CreatorProgress.fromJson(Map<String, dynamic> j) => CreatorProgress(
        totalCredited: _int(j['totalCredited']),
        remaining: _int(j['remaining']),
        approvedCount: _int(j['approvedCount']),
        pendingCount: _int(j['pendingCount']),
        rejectedCount: _int(j['rejectedCount']),
      );
}

class CreatorVideo {
  final String id;
  final String platform;
  final String url;
  final String title;
  final String thumbnail;
  final String status; // pending | approved | rejected
  final String? reviewNote;
  final int creditedAmount;
  final DateTime? createdAt;

  const CreatorVideo({
    this.id = '',
    this.platform = '',
    this.url = '',
    this.title = '',
    this.thumbnail = '',
    this.status = '',
    this.reviewNote,
    this.creditedAmount = 0,
    this.createdAt,
  });

  factory CreatorVideo.fromJson(Map<String, dynamic> j) {
    final meta = (j['metaData'] as Map?)?.cast<String, dynamic>() ?? const {};
    return CreatorVideo(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      platform: (j['platform'] ?? meta['provider'] ?? '').toString(),
      url: (j['url'] ?? meta['webpageUrl'] ?? '').toString(),
      title: (meta['title'] ?? j['title'] ?? '').toString(),
      thumbnail: (meta['thumbnail'] ?? '').toString(),
      status: (j['status'] ?? '').toString(),
      reviewNote: j['reviewNote']?.toString(),
      creditedAmount: _int(j['creditedAmount']),
      createdAt: j['createdAt'] != null
          ? DateTime.tryParse(j['createdAt'].toString())
          : null,
    );
  }
}
