/// 약관 도메인 엔티티
class TermsEntity {
  final String id;
  final String title;
  final String content;
  final bool isRequired;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String version;

  TermsEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.isRequired,
    required this.createdAt,
    this.updatedAt,
    required this.version,
  });

  /// 만료 여부 (1년 이상 된 약관)
  bool get isExpired => DateTime.now().difference(createdAt).inDays > 365;

  /// 최근 업데이트 여부 (30일 이내)
  bool get isRecentlyUpdated {
    if (updatedAt == null) return false;
    return DateTime.now().difference(updatedAt!).inDays <= 30;
  }

  /// 약관 타입
  TermsType get type {
    if (title.contains('서비스')) return TermsType.service;
    if (title.contains('개인정보')) return TermsType.privacy;
    if (title.contains('위치')) return TermsType.location;
    if (title.contains('마케팅')) return TermsType.marketing;
    return TermsType.other;
  }
}

enum TermsType { service, privacy, location, marketing, other }
