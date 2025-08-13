import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// 전역 로거 인스턴스
/// 개발/프로덕션 환경에 따라 다른 로그 레벨과 출력 방식을 사용
final Logger logger = Logger(
  filter: _VmsLogFilter(),
  printer: _VmsLogPrinter(),
  output: _VmsLogOutput(),
);

/// VMS 앱용 커스텀 로그 필터
/// 개발 모드에서는 모든 로그를 표시하고, 릴리즈 모드에서는 경고 이상만 표시
class _VmsLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kDebugMode) {
      // 디버그 모드: 모든 로그 표시
      return true;
    } else {
      // 릴리즈 모드: 경고(Warning) 이상만 표시
      return event.level.index >= Level.warning.index;
    }
  }
}

/// VMS 앱용 커스텀 로그 프린터
/// 로그 출력 형식을 VMS 앱에 맞게 커스터마이징
class _VmsLogPrinter extends LogPrinter {
  static final Map<Level, String> _levelEmojis = {
    Level.trace: '🔍',
    Level.debug: '🐛',
    Level.info: 'ℹ️',
    Level.warning: '⚠️',
    Level.error: '❌',
    Level.fatal: '💥',
  };

  static final Map<Level, String> _levelNames = {
    Level.trace: 'TRACE',
    Level.debug: 'DEBUG',
    Level.info: 'INFO',
    Level.warning: 'WARNING',
    Level.error: 'ERROR',
    Level.fatal: 'FATAL',
  };

  // levelColors를 직접 정의 (PrettyPrinter.levelColors 대신)
  static final Map<Level, AnsiColor> _levelColors = {
    Level.trace: AnsiColor.fg(AnsiColor.grey(0.5)),
    Level.debug: AnsiColor.none(),
    Level.info: AnsiColor.fg(12),
    Level.warning: AnsiColor.fg(208),
    Level.error: AnsiColor.fg(196),
    Level.fatal: AnsiColor.fg(199),
  };

  @override
  List<String> log(LogEvent event) {
    final color = _levelColors[event.level] ?? AnsiColor.none();
    final emoji = _levelEmojis[event.level] ?? '📝';
    final levelName = _levelNames[event.level] ?? 'UNKNOWN';

    final message = event.message;
    final time = DateTime.now().toIso8601String();

    List<String> output = [];

    // 메인 로그 메시지
    if (kDebugMode) {
      // 디버그 모드: 상세한 정보 포함
      output.add(color('$emoji [$levelName] $time'));
      output.add(color('📝 $message'));
    } else {
      // 릴리즈 모드: 간단한 형식
      output.add('[$levelName] $message');
    }

    // 에러 객체가 있는 경우
    if (event.error != null) {
      output.add(color('💥 Error: ${event.error}'));
    }

    // 스택 트레이스가 있는 경우 (디버그 모드에서만)
    if (kDebugMode && event.stackTrace != null) {
      output.add(color('📍 Stack trace:'));
      final stackLines = event.stackTrace.toString().split('\n');
      for (int i = 0; i < stackLines.length && i < 5; i++) {
        output.add(color('   ${stackLines[i]}'));
      }
      if (stackLines.length > 5) {
        output.add(color('   ... (${stackLines.length - 5} more lines)'));
      }
    }

    return output;
  }
}

/// VMS 앱용 커스텀 로그 출력
/// 개발/프로덕션 환경에 따라 다른 출력 방식 사용
class _VmsLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    if (kDebugMode) {
      // 디버그 모드: 콘솔에 출력
      for (final line in event.lines) {
        debugPrint(line);
      }
    } else {
      // 릴리즈 모드: 시스템 로그에만 출력 (필요시 외부 로깅 서비스 연동)
      for (final line in event.lines) {
        print(line); // 시스템 로그
      }
    }
  }
}

/// 로거 유틸리티 클래스
/// 특정 상황에 맞는 로깅 메서드 제공
class LoggerUtils {
  /// API 요청 로그
  static void logApiRequest(String method, String url, {Map<String, dynamic>? data}) {
    logger.d('🌐 API Request: $method $url${data != null ? '\nData: $data' : ''}');
  }

  /// API 응답 로그
  static void logApiResponse(String method, String url, int statusCode, {dynamic data}) {
    final emoji = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
    logger.d('$emoji API Response: $method $url [$statusCode]${data != null ? '\nData: $data' : ''}');
  }

  /// 사용자 액션 로그
  static void logUserAction(String action, {Map<String, dynamic>? context}) {
    logger.i('👤 User Action: $action${context != null ? '\nContext: $context' : ''}');
  }

  /// 네비게이션 로그
  static void logNavigation(String from, String to) {
    logger.i('🧭 Navigation: $from → $to');
  }

  /// 에러 로그 (상세 정보 포함)
  static void logError(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? context}) {
    final contextInfo = context != null ? '\nContext: $context' : '';
    logger.e('$message$contextInfo', error: error, stackTrace: stackTrace);
  }

  /// 성능 로그
  static void logPerformance(String operation, Duration duration, {Map<String, dynamic>? metrics}) {
    final emoji = duration.inMilliseconds > 1000 ? '🐌' : '⚡';
    logger.i('$emoji Performance: $operation took ${duration.inMilliseconds}ms${metrics != null ? '\nMetrics: $metrics' : ''}');
  }

  /// Firebase 이벤트 로그
  static void logFirebaseEvent(String eventName, {Map<String, dynamic>? parameters}) {
    logger.d('🔥 Firebase Event: $eventName${parameters != null ? '\nParameters: $parameters' : ''}');
  }

  /// 위치 관련 로그
  static void logLocation(String action, {double? latitude, double? longitude, String? address}) {
    final location = latitude != null && longitude != null ? '($latitude, $longitude)' : '';
    final addressInfo = address != null ? ' - $address' : '';
    logger.d('📍 Location: $action$location$addressInfo');
  }

  /// 권한 관련 로그
  static void logPermission(String permission, String status, {String? reason}) {
    final emoji = status == 'granted' ? '✅' : '❌';
    logger.i('$emoji Permission: $permission - $status${reason != null ? ' ($reason)' : ''}');
  }

  /// 앱 생명주기 로그
  static void logAppLifecycle(String state, {Map<String, dynamic>? details}) {
    logger.i('🔄 App Lifecycle: $state${details != null ? '\nDetails: $details' : ''}');
  }

  /// 메모리 사용량 로그
  static void logMemoryUsage(String context, {int? usedMB, int? totalMB}) {
    final memoryInfo = usedMB != null && totalMB != null ? ' ($usedMB MB / $totalMB MB)' : '';
    logger.d('🧠 Memory Usage: $context$memoryInfo');
  }

  /// 데이터베이스 작업 로그
  static void logDatabaseOperation(String operation, String table, {Map<String, dynamic>? data, Duration? duration}) {
    final durationInfo = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
    final dataInfo = data != null ? '\nData: $data' : '';
    logger.d('🗄️ DB Operation: $operation on $table$durationInfo$dataInfo');
  }

  /// 캐시 작업 로그
  static void logCacheOperation(String operation, String key, {bool hit = false, Duration? duration}) {
    final emoji = hit ? '🎯' : '❌';
    final durationInfo = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
    logger.d('$emoji Cache: $operation [$key]$durationInfo');
  }
}

/// 성능 측정용 스톱워치 유틸리티
class PerformanceLogger {
  final String _operation;
  final Stopwatch _stopwatch;
  final Map<String, dynamic>? _context;

  PerformanceLogger(this._operation, {Map<String, dynamic>? context})
      : _context = context,
        _stopwatch = Stopwatch()..start();

  /// 측정 완료 및 로그 출력
  void finish({Map<String, dynamic>? additionalMetrics}) {
    _stopwatch.stop();
    final metrics = <String, dynamic>{
      'duration_ms': _stopwatch.elapsedMilliseconds,
      ...?_context,
      ...?additionalMetrics,
    };

    LoggerUtils.logPerformance(_operation, _stopwatch.elapsed, metrics: metrics);
  }

  /// 중간 체크포인트 로그
  void checkpoint(String checkpointName) {
    logger.d('⏱️ Checkpoint [$_operation]: $checkpointName at ${_stopwatch.elapsedMilliseconds}ms');
  }

  /// 현재 경과 시간 반환
  Duration get elapsed => _stopwatch.elapsed;

  /// 현재 경과 시간(밀리초) 반환
  int get elapsedMilliseconds => _stopwatch.elapsedMilliseconds;
}

/// 로그 레벨 관리
class LogLevel {
  static Level _currentLevel = Level.debug;

  /// 현재 로그 레벨 가져오기
  static Level get current => _currentLevel;

  /// 로그 레벨 설정
  static void setLevel(Level level) {
    // 프로덕션에서는 Warning 이상만 허용
    if (!kDebugMode && level.index < Level.warning.index) {
      return;
    }

    _currentLevel = level;

    if (kDebugMode) {
      logger.i('🔧 Log level changed to: ${level.name}');
    }
  }

  /// 특정 레벨이 활성화되어 있는지 확인
  static bool isEnabled(Level level) {
    return level.index >= _currentLevel.index;
  }
}

/// 로그 버퍼 (메모리에 로그를 저장하여 나중에 전송)
class LogBuffer {
  static final List<String> _buffer = [];
  static const int _maxBufferSize = 1000;

  /// 로그를 버퍼에 추가
  static void addLog(String log) {
    _buffer.add('[${DateTime.now().toIso8601String()}] $log');

    // 버퍼 크기 제한
    if (_buffer.length > _maxBufferSize) {
      _buffer.removeAt(0);
    }
  }

  /// 버퍼의 모든 로그 가져오기
  static List<String> getAllLogs() {
    return List<String>.from(_buffer);
  }

  /// 최근 N개의 로그 가져오기
  static List<String> getRecentLogs(int count) {
    final startIndex = (_buffer.length - count).clamp(0, _buffer.length);
    return _buffer.sublist(startIndex);
  }

  /// 버퍼 비우기
  static void clear() {
    _buffer.clear();
  }

  /// 버퍼 크기 반환
  static int get size => _buffer.length;

  /// 버퍼가 가득 찼는지 확인
  static bool get isFull => _buffer.length >= _maxBufferSize;
}

/// 로그 전송용 유틸리티 (원격 로깅 서비스 연동)
class LogSender {
  /// 로그를 원격 서버로 전송 (구현 예시)
  static Future<bool> sendLogs(List<String> logs) async {
    try {
      // TODO: 실제 로그 전송 로직 구현
      // 예: HTTP POST 요청으로 로그 서버에 전송

      if (kDebugMode) {
        logger.d('📤 Sending ${logs.length} logs to remote server');
      }

      // 시뮬레이션: 1초 후 성공
      await Future.delayed(const Duration(seconds: 1));

      return true;
    } catch (e) {
      if (kDebugMode) {
        logger.e('Failed to send logs', error: e);
      }
      return false;
    }
  }

  /// 버퍼의 로그를 모두 전송
  static Future<bool> sendBufferedLogs() async {
    final logs = LogBuffer.getAllLogs();
    if (logs.isEmpty) return true;

    final success = await sendLogs(logs);
    if (success) {
      LogBuffer.clear();
    }

    return success;
  }
}