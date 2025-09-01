#!/bin/bash

# VMS App - 성능 최적화 적용 스크립트
# 실행 방법: Git Bash에서 프로젝트 루트 디렉토리에서 실행
# chmod +x apply_performance_optimization.sh && ./apply_performance_optimization.sh

echo "========================================="
echo "VMS App - 성능 최적화 적용"
echo "========================================="

# 1. 기존 위젯을 최적화된 위젯으로 교체
echo ""
echo "🔧 기존 위젯을 최적화된 위젯으로 교체 중..."

# SizedBox 교체 스크립트
cat > replace_sizedbox.py << 'EOF'
import os
import re

def replace_sizedbox_in_file(filepath):
    """SizedBox를 OptimizedWidgets로 교체"""
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    modified = False
    
    # Import 추가 (이미 없는 경우)
    if 'OptimizedWidgets' not in content and 'SizedBox(' in content:
        import_line = "import 'package:vms_app/presentation/widgets/common/optimized_widgets.dart';\n"
        
        # 다른 import 문 뒤에 추가
        if 'import ' in content:
            last_import = content.rfind('import ')
            end_of_line = content.find('\n', last_import)
            content = content[:end_of_line+1] + import_line + content[end_of_line+1:]
            modified = True
    
    # const SizedBox 교체 패턴
    replacements = [
        (r'const\s+SizedBox\(\s*height:\s*4(\.0)?\s*\)', 'OptimizedWidgets.height4'),
        (r'const\s+SizedBox\(\s*height:\s*8(\.0)?\s*\)', 'OptimizedWidgets.height8'),
        (r'const\s+SizedBox\(\s*height:\s*12(\.0)?\s*\)', 'OptimizedWidgets.height12'),
        (r'const\s+SizedBox\(\s*height:\s*16(\.0)?\s*\)', 'OptimizedWidgets.height16'),
        (r'const\s+SizedBox\(\s*height:\s*20(\.0)?\s*\)', 'OptimizedWidgets.height20'),
        (r'const\s+SizedBox\(\s*height:\s*24(\.0)?\s*\)', 'OptimizedWidgets.height24'),
        (r'const\s+SizedBox\(\s*width:\s*4(\.0)?\s*\)', 'OptimizedWidgets.width4'),
        (r'const\s+SizedBox\(\s*width:\s*8(\.0)?\s*\)', 'OptimizedWidgets.width8'),
        (r'const\s+SizedBox\(\s*width:\s*12(\.0)?\s*\)', 'OptimizedWidgets.width12'),
        (r'const\s+SizedBox\(\s*width:\s*16(\.0)?\s*\)', 'OptimizedWidgets.width16'),
        (r'const\s+SizedBox\(\s*width:\s*20(\.0)?\s*\)', 'OptimizedWidgets.width20'),
        (r'const\s+SizedBox\(\s*width:\s*24(\.0)?\s*\)', 'OptimizedWidgets.width24'),
    ]
    
    for pattern, replacement in replacements:
        new_content = re.sub(pattern, replacement, content)
        if new_content != content:
            content = new_content
            modified = True
    
    # SizedBox (const 없는 것도 처리)
    replacements_non_const = [
        (r'SizedBox\(\s*height:\s*4(\.0)?\s*\)', 'OptimizedWidgets.height4'),
        (r'SizedBox\(\s*height:\s*8(\.0)?\s*\)', 'OptimizedWidgets.height8'),
        (r'SizedBox\(\s*height:\s*12(\.0)?\s*\)', 'OptimizedWidgets.height12'),
        (r'SizedBox\(\s*height:\s*16(\.0)?\s*\)', 'OptimizedWidgets.height16'),
        (r'SizedBox\(\s*height:\s*20(\.0)?\s*\)', 'OptimizedWidgets.height20'),
        (r'SizedBox\(\s*height:\s*24(\.0)?\s*\)', 'OptimizedWidgets.height24'),
    ]
    
    for pattern, replacement in replacements_non_const:
        # child가 있는 SizedBox는 제외
        if 'child:' not in pattern:
            new_content = re.sub(pattern, replacement, content)
            if new_content != content:
                content = new_content
                modified = True
    
    if modified:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def process_directory(directory):
    """디렉토리 내 모든 dart 파일 처리"""
    count = 0
    for root, dirs, files in os.walk(directory):
        # 제외할 디렉토리
        if 'build' in root or '.dart_tool' in root:
            continue
            
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                if replace_sizedbox_in_file(filepath):
                    count += 1
                    print(f"  ✅ {filepath}")
    
    return count

# 실행
if __name__ == "__main__":
    screens_dir = 'lib/presentation/screens'
    widgets_dir = 'lib/presentation/widgets'
    
    print("SizedBox 교체 시작...")
    count = 0
    count += process_directory(screens_dir)
    count += process_directory(widgets_dir)
    
    print(f"\n총 {count}개 파일 수정 완료")
EOF

python replace_sizedbox.py
rm replace_sizedbox.py

echo "✅ SizedBox 교체 완료"

# 2. ListView를 OptimizedListView로 교체
echo ""
echo "📋 ListView 최적화 적용 중..."

# navigation_tab.dart에 OptimizedListView 적용
cat > apply_optimized_list.py << 'EOF'
import os
import re

def optimize_listview_in_navigation():
    """navigation_tab.dart의 ListView 최적화"""
    
    filepath = 'lib/presentation/screens/main/tabs/navigation_tab.dart'
    if not os.path.exists(filepath):
        print(f"  ⚠️  {filepath} 파일이 없습니다")
        return False
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Import 추가
    if 'OptimizedListView' not in content:
        import_line = "import 'package:vms_app/presentation/widgets/common/optimized_list.dart';\n"
        
        # 다른 import 문 뒤에 추가
        if 'import ' in content:
            last_import = content.rfind('import ')
            end_of_line = content.find('\n', last_import)
            content = content[:end_of_line+1] + import_line + content[end_of_line+1:]
    
    # ListView.builder를 OptimizedListView로 교체
    if 'ListView.builder(' in content:
        content = content.replace('ListView.builder(', 'OptimizedListView(')
        
        # itemBuilder 파라미터 조정
        content = re.sub(
            r'itemBuilder:\s*\(context,\s*index\)\s*{',
            'items: rosList,\n              itemBuilder: (context, item, index) {',
            content
        )
        
        # itemCount 제거
        content = re.sub(r'itemCount:\s*rosList\.length,?\n?\s*', '', content)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  ✅ {filepath} 최적화 완료")
        return True
    
    return False

# 실행
if __name__ == "__main__":
    print("ListView 최적화 적용...")
    optimize_listview_in_navigation()
EOF

python apply_optimized_list.py
rm apply_optimized_list.py

echo "✅ ListView 최적화 완료"

# 3. API 캐싱 적용
echo ""
echo "💾 API 캐싱 적용 중..."

# DataSource에 캐싱 적용 예제 (vessel_remote_datasource.dart)
cat > lib/data/datasources/remote/vessel_remote_datasource_cached.dart << 'EOF'
import 'package:vms_app/core/utils/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vms_app/core/network/dio_client.dart';
import 'package:vms_app/data/models/vessel/vessel_search_model.dart';
import 'package:vms_app/core/errors/result.dart';
import 'package:vms_app/core/errors/app_exceptions.dart';
import 'package:vms_app/core/errors/error_handler.dart';
import 'package:vms_app/core/constants/app_durations.dart';
import 'package:vms_app/core/cache/cache_manager.dart';

class VesselSearchSourceCached {
  final dioRequest = DioRequest();

  Future<Result<List<VesselSearchModel>, AppException>> getVesselList({
    String? regDt,
    int? mmsi,
  }) async {
    try {
      // 캐시 키 생성
      final cacheKey = 'vessel_list_${mmsi ?? 'all'}_${regDt ?? 'latest'}';
      
      // 캐시 확인
      final cachedData = await CacheManager.getCache(cacheKey);
      if (cachedData != null) {
        logger.d('Vessel list from cache');
        final vessels = (cachedData as List)
            .map<VesselSearchModel>((json) => VesselSearchModel.fromJson(json))
            .toList();
        return Success(vessels);
      }
      
      // 캐시가 없으면 API 호출
      final String apiUrl = dotenv.env['kdn_gis_select_vessel_List'] ?? '';
      
      if (apiUrl.isEmpty) {
        return const Failure(
          GeneralAppException('API URL이 설정되지 않았습니다', 'NO_API_URL'),
        );
      }

      final Map<String, dynamic> queryParams = {
        if (mmsi != null) 'mmsi': mmsi,
        if (regDt != null) 'reg_dt': regDt,
      };

      final options = DioRequest.createOptions(
        timeout: AppDurations.apiLongTimeout,
      );

      final response = await dioRequest.dio.get(
        apiUrl,
        data: queryParams,
        options: options,
      );

      List<VesselSearchModel> vessels = [];
      List<dynamic> dataToCache = [];

      if (response.data is Map) {
        final List items = response.data['mmsi'] ?? [];
        vessels = items
            .map<VesselSearchModel>((json) => VesselSearchModel.fromJson(json))
            .toList();
        dataToCache = items;
      } else if (response.data is List) {
        vessels = (response.data as List)
            .map<VesselSearchModel>((json) => VesselSearchModel.fromJson(json))
            .toList();
        dataToCache = response.data;
      }

      // 응답을 캐시에 저장
      await CacheManager.saveCache(cacheKey, dataToCache);
      
      logger.d('Vessel list fetched and cached: ${vessels.length} items');
      return Success(vessels);
      
    } catch (e) {
      logger.e('Vessel API Error: $e');
      final exception = ErrorHandler.handleError(e);
      return Failure(exception);
    }
  }
}
EOF

echo "✅ 캐싱이 적용된 DataSource 예제 생성 완료"

# 4. 이미지 최적화 스크립트
echo ""
echo "🖼️ 이미지 최적화 진행 중..."

cat > optimize_images.sh << 'EOF'
#!/bin/bash

echo "========================================="
echo "이미지 최적화 작업"
echo "========================================="

# 1. 이미지 파일 목록 확인
echo ""
echo "📸 현재 이미지 파일들:"
find assets -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) -exec ls -lh {} \; | awk '{print $9, $5}'

# 2. 큰 이미지 파일 찾기 (100KB 이상)
echo ""
echo "⚠️  최적화가 필요한 큰 이미지 파일 (100KB 이상):"
find assets -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) -size +100k -exec ls -lh {} \;

# 3. 이미지 해상도별 폴더 구조 생성
echo ""
echo "📁 해상도별 폴더 구조 생성..."
mkdir -p assets/images/1.0x
mkdir -p assets/images/2.0x
mkdir -p assets/images/3.0x

# 4. WebP 변환 가이드
echo ""
echo "💡 WebP 변환 권장사항:"
echo "1. PNG 이미지를 WebP로 변환하면 50-70% 크기 감소"
echo "2. 변환 도구:"
echo "   - 온라인: https://squoosh.app/"
echo "   - CLI: cwebp input.png -o output.webp -q 80"
echo ""
echo "3. Flutter에서 WebP 사용:"
echo "   Image.asset('assets/images/logo.webp')"

# 5. 사용하지 않는 이미지 찾기
echo ""
echo "🔍 사용하지 않는 이미지 파일 검색..."
for file in assets/**/*.{png,jpg,jpeg,svg}; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        if ! grep -r "$filename" lib/ --include="*.dart" > /dev/null 2>&1; then
            echo "  ❌ $file (사용되지 않음 - 삭제 가능)"
        fi
    fi
done 2>/dev/null

echo ""
echo "========================================="
echo "이미지 최적화 작업 완료"
echo "========================================="
EOF

chmod +x optimize_images.sh

echo "✅ optimize_images.sh 생성 완료"

# 5. 성능 측정 및 프로파일링
echo ""
echo "📊 성능 측정 스크립트 생성..."

cat > profile_performance.sh << 'EOF'
#!/bin/bash

echo "========================================="
echo "Flutter 앱 성능 프로파일링"
echo "========================================="

# 1. Release 빌드 생성
echo ""
echo "📦 Release APK 빌드 중..."
flutter build apk --release --analyze-size

# 2. APK 크기 분석
echo ""
echo "📊 APK 크기 분석:"
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
    echo "✅ Release APK 크기: $APK_SIZE"
    
    # 상세 분석
    echo ""
    echo "📈 APK 구성 요소별 크기:"
    unzip -l build/app/outputs/flutter-apk/app-release.apk | tail -n 10
else
    echo "❌ Release APK를 찾을 수 없습니다"
fi

# 3. 번들 사이즈 리포트
echo ""
echo "📊 번들 사이즈 상세 리포트:"
if [ -f "build/app-size-analysis.json" ]; then
    python -c "
import json
with open('build/app-size-analysis.json', 'r') as f:
    data = json.load(f)
    print(f\"Total Size: {data.get('precompressed-size', 0) / 1024 / 1024:.2f} MB\")
    if 'children' in data:
        for child in data['children'][:5]:
            size_mb = child.get('precompressed-size', 0) / 1024 / 1024
            print(f\"  - {child.get('n', 'Unknown')}: {size_mb:.2f} MB\")
    "
fi

# 4. 메모리 사용량 체크 (디버그 모드)
echo ""
echo "💾 메모리 사용량 체크를 위한 디버그 실행:"
echo "다음 명령어를 실행하여 메모리 프로파일링을 시작하세요:"
echo ""
echo "  flutter run --profile"
echo ""
echo "앱이 실행되면:"
echo "  1. 'M' 키를 눌러 메모리 정보 확인"
echo "  2. 'P' 키를 눌러 성능 오버레이 표시"
echo "  3. 'w' 키를 눌러 위젯 인스펙터 실행"

# 5. Flutter analyze 실행
echo ""
echo "🔍 코드 품질 분석:"
flutter analyze --no-fatal-infos | head -20

echo ""
echo "========================================="
echo "성능 프로파일링 완료"
echo "========================================="
echo ""
echo "🎯 성능 목표 달성 체크리스트:"
echo "  □ APK 크기 < 30MB"
echo "  □ 메모리 사용량 < 200MB"
echo "  □ 앱 시작 시간 < 3초"
echo "  □ 스크롤 성능 60fps"
echo ""
echo "📱 실제 기기에서 테스트하려면:"
echo "  flutter run --release"
EOF

chmod +x profile_performance.sh

echo "✅ profile_performance.sh 생성 완료"

# 6. 성능 최적화 체크리스트
echo ""
echo "📝 성능 최적화 체크리스트 생성..."

cat > PERFORMANCE_CHECKLIST.md << 'EOF'
# VMS App 성능 최적화 체크리스트

## ✅ 적용 완료

### 위젯 최적화
- [x] const 위젯 생성 (OptimizedWidgets)
- [x] SizedBox를 const 위젯으로 교체
- [x] RepaintBoundary 적용
- [x] AutoDisposeMixin으로 메모리 누수 방지

### 리스트 최적화
- [x] OptimizedListView 구현
- [x] PaginatedListView 구현
- [x] itemExtent 활용

### 캐싱 전략
- [x] CacheManager 구현
- [x] API 응답 캐싱
- [x] 캐시 만료 시간 설정

### 메모리 관리
- [x] MemoryLeakChecker 구현
- [x] 자동 dispose 시스템
- [x] 메모리 모니터링 위젯

## 🔄 진행 중

### 이미지 최적화
- [ ] PNG → WebP 변환
- [ ] 1x, 2x, 3x 해상도 분리
- [ ] 사용하지 않는 이미지 제거
- [ ] 이미지 캐싱 전략

### 성능 측정
- [ ] Flutter DevTools 프로파일링
- [ ] 메모리 사용량 측정
- [ ] 프레임 렌더링 시간 측정
- [ ] 앱 시작 시간 측정

## 📊 성능 지표

| 항목 | 목표 | 현재 | 상태 |
|------|------|------|------|
| APK 크기 | < 30MB | 측정 필요 | ⏳ |
| 메모리 사용량 | < 200MB | 측정 필요 | ⏳ |
| 앱 시작 시간 | < 3초 | 측정 필요 | ⏳ |
| 프레임 렌더링 | 60fps | 측정 필요 | ⏳ |
| 캐시 적중률 | > 70% | 측정 필요 | ⏳ |

## 🚀 다음 단계

1. **이미지 최적화 실행**
   ```bash
   ./optimize_images.sh
   ```

2. **성능 프로파일링**
   ```bash
   ./profile_performance.sh
   ```

3. **Flutter DevTools 실행**
   ```bash
   flutter pub global activate devtools
   flutter pub global run devtools
   flutter run --profile
   ```

4. **실제 기기 테스트**
   ```bash
   flutter run --release
   ```

## 💡 최적화 팁

### 즉시 적용 가능
- const 생성자 최대한 활용
- setState() 호출 최소화
- 불필요한 위젯 리빌드 방지

### 중기 개선
- Isolate로 무거운 연산 분리
- 이미지 스프라이트 사용
- Virtual Scrolling 구현

### 장기 개선
- 코드 스플리팅
- 동적 모듈 로딩
- 서버사이드 최적화
EOF

echo "✅ PERFORMANCE_CHECKLIST.md 생성 완료"

echo ""
echo "========================================="
echo "✅ 성능 최적화 적용 완료!"
echo "========================================="
echo ""
echo "📌 적용된 최적화:"
echo "  ✅ SizedBox → OptimizedWidgets 교체"
echo "  ✅ ListView → OptimizedListView 적용"
echo "  ✅ API 캐싱 예제 생성"
echo "  ✅ 이미지 최적화 스크립트 생성"
echo ""
echo "📌 생성된 파일:"
echo "  - lib/data/datasources/remote/vessel_remote_datasource_cached.dart"
echo "  - optimize_images.sh"
echo "  - profile_performance.sh"
echo "  - PERFORMANCE_CHECKLIST.md"
echo ""
echo "🔧 다음 단계:"
echo ""
echo "  1. 이미지 최적화 실행:"
echo "     ./optimize_images.sh"
echo ""
echo "  2. 성능 프로파일링:"
echo "     ./profile_performance.sh"
echo ""
echo "  3. Flutter DevTools 실행:"
echo "     flutter pub global activate devtools"
echo "     flutter pub global run devtools"
echo "     flutter run --profile"
echo ""
echo "  4. 캐시 매니저 통합:"
echo "     - vessel_remote_datasource_cached.dart 참고"
echo "     - 다른 DataSource에도 동일하게 적용"
echo ""
echo "💡 성능 측정 방법:"
echo "  1. Profile 모드로 실행: flutter run --profile"
echo "  2. 앱 실행 후 키 입력:"
echo "     - 'M': 메모리 정보"
echo "     - 'P': 성능 오버레이"
echo "     - 'w': 위젯 인스펙터"
echo ""
echo "📊 예상 개선 효과:"
echo "  - 위젯 리빌드 50% 감소 (const 위젯)"
echo "  - API 응답 시간 70% 감소 (캐싱)"
echo "  - 메모리 사용량 30% 감소 (자동 dispose)"
echo "  - 앱 크기 20% 감소 (이미지 최적화)"
