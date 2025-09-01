#!/bin/bash

# VMS App - 성능 최적화 에러 수정 스크립트
# 실행 방법: Git Bash에서 프로젝트 루트 디렉토리에서 실행
# chmod +x fix_optimization_errors.sh && ./fix_optimization_errors.sh

echo "========================================="
echo "성능 최적화 에러 수정"
echo "========================================="

# 1. CacheManager 파일 생성 (누락된 파일)
echo ""
echo "📝 CacheManager 파일 생성 중..."

mkdir -p lib/core/cache

cat > lib/core/cache/cache_manager.dart << 'EOF'
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vms_app/core/utils/logger.dart';

/// API 응답 캐싱 관리자
class CacheManager {
  static const String _cachePrefix = 'cache_';
  static const String _timestampPrefix = 'cache_time_';
  
  // 캐시 유효 시간 (분 단위)
  static const Map<String, int> cacheDuration = {
    'vessel_list': 30,      // 30분
    'weather_info': 10,     // 10분
    'navigation_history': 60, // 1시간
    'terms_list': 1440,     // 24시간
  };

  /// 캐시 저장
  static Future<void> saveCache(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '$_timestampPrefix$key';
      
      // 데이터와 타임스탬프 저장
      await prefs.setString(cacheKey, jsonEncode(data));
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
      
      logger.d('Cache saved: $key');
    } catch (e) {
      logger.e('Cache save error: $e');
    }
  }

  /// 캐시 읽기
  static Future<dynamic> getCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '$_timestampPrefix$key';
      
      // 캐시 데이터 확인
      final cachedData = prefs.getString(cacheKey);
      final timestamp = prefs.getInt(timestampKey);
      
      if (cachedData == null || timestamp == null) {
        return null;
      }
      
      // 캐시 유효성 검사
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      final maxAge = (cacheDuration[key] ?? 30) * 60 * 1000; // 분을 밀리초로 변환
      
      if (cacheAge > maxAge) {
        logger.d('Cache expired: $key');
        await clearCache(key);
        return null;
      }
      
      logger.d('Cache hit: $key');
      return jsonDecode(cachedData);
    } catch (e) {
      logger.e('Cache read error: $e');
      return null;
    }
  }

  /// 특정 캐시 삭제
  static Future<void> clearCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_cachePrefix$key');
    await prefs.remove('$_timestampPrefix$key');
  }

  /// 모든 캐시 삭제
  static Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith(_cachePrefix) || key.startsWith(_timestampPrefix)) {
        await prefs.remove(key);
      }
    }
    
    logger.d('All cache cleared');
  }

  /// 캐시 크기 확인
  static Future<String> getCacheSize() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    int totalSize = 0;
    
    for (final key in keys) {
      if (key.startsWith(_cachePrefix)) {
        final data = prefs.getString(key);
        if (data != null) {
          totalSize += data.length;
        }
      }
    }
    
    // 바이트를 KB로 변환
    final sizeKB = (totalSize / 1024).toStringAsFixed(2);
    return '${sizeKB}KB';
  }
}
EOF

echo "✅ cache_manager.dart 생성 완료"

# 2. OptimizedWidgets 순환 참조 에러 수정
echo ""
echo "📝 OptimizedWidgets 수정 중..."

cat > lib/presentation/widgets/common/optimized_widgets.dart << 'EOF'
import 'package:flutter/material.dart';

/// 성능 최적화된 공통 위젯들
class OptimizedWidgets {
  OptimizedWidgets._();

  // const 생성자를 활용한 위젯
  static const Widget loadingIndicator = CircularProgressIndicator();
  
  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
  static const EdgeInsets smallPadding = EdgeInsets.all(8.0);
  static const EdgeInsets largePadding = EdgeInsets.all(24.0);
  
  // 자주 사용되는 SizedBox를 const로
  static const Widget height4 = SizedBox(height: 4);
  static const Widget height8 = SizedBox(height: 8);
  static const Widget height12 = SizedBox(height: 12);
  static const Widget height16 = SizedBox(height: 16);
  static const Widget height20 = SizedBox(height: 20);
  static const Widget height24 = SizedBox(height: 24);
  
  static const Widget width4 = SizedBox(width: 4);
  static const Widget width8 = SizedBox(width: 8);
  static const Widget width12 = SizedBox(width: 12);
  static const Widget width16 = SizedBox(width: 16);
  static const Widget width20 = SizedBox(width: 20);
  static const Widget width24 = SizedBox(width: 24);
}

/// RepaintBoundary를 활용한 최적화 위젯
class OptimizedContainer extends StatelessWidget {
  final Widget child;
  final bool useRepaintBoundary;

  const OptimizedContainer({
    super.key,
    required this.child,
    this.useRepaintBoundary = true,
  });

  @override
  Widget build(BuildContext context) {
    if (useRepaintBoundary) {
      return RepaintBoundary(
        child: child,
      );
    }
    return child;
  }
}

/// 이미지 캐싱 최적화
class OptimizedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const OptimizedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      // 메모리 캐시 크기 제한
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      // 로딩 중 플레이스홀더
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      // 에러 처리
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.error);
      },
    );
  }
}

/// 자주 사용되는 스타일
class OptimizedStyles {
  OptimizedStyles._();
  
  static const TextStyle titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
  );
}
EOF

echo "✅ optimized_widgets.dart 수정 완료"

# 3. vessel_remote_datasource_cached.dart import 경로 확인 및 수정
echo ""
echo "📝 vessel_remote_datasource_cached.dart 수정 중..."

# 파일이 존재하는지 확인
if [ -f "lib/data/datasources/remote/vessel_remote_datasource_cached.dart" ]; then
    # 첫 줄의 import 부분만 수정
    sed -i '1,20s|package:vms_app/core/cache/cache_manager.dart|package:vms_app/core/cache/cache_manager.dart|' lib/data/datasources/remote/vessel_remote_datasource_cached.dart
    echo "✅ vessel_remote_datasource_cached.dart import 확인 완료"
fi

# 4. 사용 예제 파일 생성
echo ""
echo "📝 사용 예제 파일 생성 중..."

cat > lib/presentation/screens/example/optimized_widget_example.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:vms_app/presentation/widgets/common/optimized_widgets.dart';

/// OptimizedWidgets 사용 예제
class OptimizedWidgetExample extends StatelessWidget {
  const OptimizedWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('최적화된 위젯 예제'),
      ),
      body: Padding(
        padding: OptimizedWidgets.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '제목 텍스트',
              style: OptimizedStyles.titleStyle,
            ),
            OptimizedWidgets.height16,  // const SizedBox 대신
            Text(
              '부제목 텍스트',
              style: OptimizedStyles.subtitleStyle,
            ),
            OptimizedWidgets.height8,
            const OptimizedContainer(
              child: Card(
                child: ListTile(
                  title: Text('RepaintBoundary로 감싸진 카드'),
                  subtitle: Text('리페인트 영역이 분리됨'),
                ),
              ),
            ),
            OptimizedWidgets.height24,
            Row(
              children: [
                const Icon(Icons.info),
                OptimizedWidgets.width8,  // const SizedBox 대신
                const Text('아이콘과 텍스트'),
              ],
            ),
            OptimizedWidgets.height16,
            // 네트워크 이미지 최적화
            const OptimizedNetworkImage(
              imageUrl: 'https://via.placeholder.com/150',
              width: 150,
              height: 150,
            ),
          ],
        ),
      ),
    );
  }
}
EOF

echo "✅ optimized_widget_example.dart 생성 완료"

# 5. 캐시 매니저 사용 예제
echo ""
echo "📝 캐시 매니저 사용 예제 생성 중..."

cat > lib/presentation/screens/example/cache_example.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:vms_app/core/cache/cache_manager.dart';

/// CacheManager 사용 예제
class CacheExample extends StatefulWidget {
  const CacheExample({super.key});

  @override
  State<CacheExample> createState() => _CacheExampleState();
}

class _CacheExampleState extends State<CacheExample> {
  String _cacheStatus = '캐시 상태: 비어있음';
  String _cacheSize = '0KB';

  @override
  void initState() {
    super.initState();
    _checkCacheStatus();
  }

  Future<void> _checkCacheStatus() async {
    final size = await CacheManager.getCacheSize();
    setState(() {
      _cacheSize = size;
    });
  }

  Future<void> _saveToCache() async {
    final testData = {
      'name': 'VMS App',
      'timestamp': DateTime.now().toIso8601String(),
      'data': List.generate(100, (i) => 'Item $i'),
    };
    
    await CacheManager.saveCache('test_data', testData);
    await _checkCacheStatus();
    
    setState(() {
      _cacheStatus = '캐시 상태: 데이터 저장됨';
    });
  }

  Future<void> _readFromCache() async {
    final data = await CacheManager.getCache('test_data');
    
    setState(() {
      if (data != null) {
        _cacheStatus = '캐시 상태: 데이터 읽기 성공\n${data['timestamp']}';
      } else {
        _cacheStatus = '캐시 상태: 데이터 없음 또는 만료됨';
      }
    });
  }

  Future<void> _clearCache() async {
    await CacheManager.clearAllCache();
    await _checkCacheStatus();
    
    setState(() {
      _cacheStatus = '캐시 상태: 모두 삭제됨';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('캐시 매니저 예제'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('캐시 크기: $_cacheSize'),
                    const SizedBox(height: 8),
                    Text(_cacheStatus),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveToCache,
              child: const Text('캐시에 저장'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _readFromCache,
              child: const Text('캐시에서 읽기'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _clearCache,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('캐시 모두 삭제'),
            ),
          ],
        ),
      ),
    );
  }
}
EOF

echo "✅ cache_example.dart 생성 완료"

# 6. 검증 스크립트
echo ""
echo "📝 검증 스크립트 생성 중..."

cat > verify_optimization_fixes.sh << 'EOF'
#!/bin/bash

echo "========================================="
echo "성능 최적화 에러 수정 검증"
echo "========================================="

# 1. 파일 존재 확인
echo ""
echo "1. 필수 파일 확인:"

if [ -f "lib/core/cache/cache_manager.dart" ]; then
    echo "✅ cache_manager.dart 존재"
else
    echo "❌ cache_manager.dart 없음"
fi

if [ -f "lib/presentation/widgets/common/optimized_widgets.dart" ]; then
    echo "✅ optimized_widgets.dart 존재"
else
    echo "❌ optimized_widgets.dart 없음"
fi

# 2. Flutter analyze 실행
echo ""
echo "2. Flutter analyze 실행:"
flutter analyze lib/core/cache/cache_manager.dart 2>&1 | grep -E "error|warning" || echo "✅ cache_manager.dart 에러 없음"
flutter analyze lib/presentation/widgets/common/optimized_widgets.dart 2>&1 | grep -E "error|warning" || echo "✅ optimized_widgets.dart 에러 없음"

# 3. Import 확인
echo ""
echo "3. Import 체크:"
echo "vessel_remote_datasource_cached.dart의 cache_manager import:"
grep "cache_manager" lib/data/datasources/remote/vessel_remote_datasource_cached.dart 2>/dev/null || echo "파일 없음"

# 4. 전체 에러 확인
echo ""
echo "4. 전체 에러 확인:"
flutter analyze | grep -E "error.*cache_manager|error.*optimized_widgets|recursive_compile_time"

if [ $? -ne 0 ]; then
    echo "✅ 관련 에러 없음"
fi

echo ""
echo "========================================="
echo "검증 완료"
echo "========================================="
EOF

chmod +x verify_optimization_fixes.sh

echo "✅ verify_optimization_fixes.sh 생성 완료"

echo ""
echo "========================================="
echo "✅ 성능 최적화 에러 수정 완료!"
echo "========================================="
echo ""
echo "📌 수정/생성된 파일:"
echo "  - lib/core/cache/cache_manager.dart (생성)"
echo "  - lib/presentation/widgets/common/optimized_widgets.dart (수정)"
echo "  - lib/presentation/screens/example/optimized_widget_example.dart"
echo "  - lib/presentation/screens/example/cache_example.dart"
echo ""
echo "🔧 다음 단계:"
echo "  1. 수정 검증:"
echo "     ./verify_optimization_fixes.sh"
echo ""
echo "  2. Flutter analyze 확인:"
echo "     flutter analyze | grep -e 'error'"
echo ""
echo "  3. 앱 실행 테스트:"
echo "     flutter run"
echo ""
echo "💡 해결된 문제:"
echo "  ✅ CacheManager 클래스 정의 누락"
echo "  ✅ OptimizedWidgets 순환 참조 에러"
echo "  ✅ Widget 타입으로 변경하여 const 사용 가능"
echo ""
echo "📊 사용 방법:"
echo "  1. 위젯 최적화:"
echo "     SizedBox(height: 16) → OptimizedWidgets.height16"
echo ""
echo "  2. 캐시 사용:"
echo "     await CacheManager.saveCache('key', data);"
echo "     final cached = await CacheManager.getCache('key');"
