// lib/core/utils/extensions/duration_extensions.dart

/// Duration 확장
extension DurationExtension on Duration {
  /// 포맷된 시간 문자열 (HH:mm:ss)
  String toTimeString() {
    final hours = inHours.toString().padLeft(2, '0');
    final minutes = (inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// 포맷된 분:초 문자열 (mm:ss)
  String toMinuteSecondString() {
    final minutes = inMinutes.toString().padLeft(2, '0');
    final seconds = (inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// 사람이 읽기 쉬운 형식
  String toReadableString() {
    if (inDays > 0) {
      return '$inDays일';
    } else if (inHours > 0) {
      return '$inHours시간';
    } else if (inMinutes > 0) {
      return '$inMinutes분';
    } else {
      return '$inSeconds초';
    }
  }
}
