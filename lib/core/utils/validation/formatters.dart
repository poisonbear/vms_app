import 'package:intl/intl.dart';

/// 포맷터 유틸리티
class Formatters {
  Formatters._();

  // Date Formatters
  static final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');
  static final DateFormat dateTimeFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat timeFormatter = DateFormat('HH:mm:ss');
  static final DateFormat koreanDateFormatter = DateFormat('yyyy년 MM월 dd일');
  static final DateFormat koreanDateTimeFormatter =
      DateFormat('yyyy년 MM월 dd일 HH시 mm분');

  // Number Formatters
  static final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'ko_KR',
    symbol: '₩',
    decimalDigits: 0,
  );
  static final NumberFormat decimalFormatter = NumberFormat('#,##0.##');
  static final NumberFormat percentFormatter =
      NumberFormat.percentPattern('ko_KR');

  /// 전화번호 포맷팅
  static String formatPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.length == 11) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 7)}-${cleaned.substring(7)}';
    } else if (cleaned.length == 10) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    }

    return phone;
  }

  /// 날짜 포맷팅
  static String formatDate(DateTime date, {String? format}) {
    if (format != null) {
      return DateFormat(format).format(date);
    }
    return dateFormatter.format(date);
  }

  /// 상대 시간 포맷팅
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}년 전';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}개월 전';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  /// 파일 크기 포맷팅
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// 거리 포맷팅
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }
}
