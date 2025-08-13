import 'package:equatable/equatable.dart';

/// 항행경보 알림 모델
class NavigationWarningModel extends Equatable {
  const NavigationWarningModel({
    required this.warnings,
    required this.data,
  });

  final List<String> warnings;
  final List<Map<String, dynamic>> data;

  factory NavigationWarningModel.fromJson(Map<String, dynamic> json) {
    List<String> messages = [];
    List<Map<String, dynamic>> combinedData = [];

    if (json['messages'] != null) {
      messages = List<String>.from(json['messages']);
    } else if (json['data'] != null) {
      List<Map<String, dynamic>> dataList =
      List<Map<String, dynamic>>.from(json['data']);
      messages = dataList
          .map((item) => item['message']?.toString() ?? '')
          .toList();
    }

    combinedData = json['data'] != null
        ? List<Map<String, dynamic>>.from(json['data'])
        : [];

    return NavigationWarningModel(
      warnings: messages,
      data: combinedData,
    );
  }

  Map<String, dynamic> toJson() => {
    'warnings': warnings,
    'data': data,
  };

  /// 경고 메시지가 있는지 확인
  bool get hasWarnings => warnings.isNotEmpty;

  /// 경고 메시지를 하나의 문자열로 연결 (Marquee용)
  String get combinedWarnings => warnings.isNotEmpty
      ? warnings.join('             ')
      : '금일 항행경보가 없습니다.';

  @override
  List<Object?> get props => [warnings, data];
}