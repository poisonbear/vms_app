import 'package:logger/logger.dart';

/// 전역 로거 인스턴스
final Logger logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 100,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
);