#!/bin/bash

echo "=== 안전한 타입 오류 수정 (파일 보존) ==="
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 백업 생성
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💾 백업 생성"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

cp lib/core/utils/load_location.dart "$BACKUP_DIR/load_location.dart.backup"
cp lib/presentation/screens/auth/login_screen.dart "$BACKUP_DIR/login_screen.dart.backup"

echo -e "${GREEN}✅ 백업 완료: $BACKUP_DIR${NC}"

# 1. load_location.dart의 특정 라인만 수정
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 load_location.dart 타입 오류 수정"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Python으로 안전하게 수정
cat > fix_load_location.py << 'EOF'
#!/usr/bin/env python3
import re

# 파일 읽기
with open('lib/core/utils/load_location.dart', 'r') as f:
    lines = f.readlines()

# 수정할 패턴들
replacements = [
    # Position 객체를 문자열로
    (r'AppLogger\.d\(position\);?$', 
     'AppLogger.d("Position: lat=${position.latitude}, lng=${position.longitude}");'),
    
    # Stream 객체를 문자열로
    (r'AppLogger\.d\(_geolocatorPlatform\.getPositionStream\(\)\);?$',
     'AppLogger.d("Position stream started");'),
     
    # print 버전도 함께 처리
    (r'print\(position\);?$',
     'print("Position: lat=${position.latitude}, lng=${position.longitude}");'),
     
    (r'print\(_geolocatorPlatform\.getPositionStream\(\)\);?$',
     'print("Position stream started");')
]

# 각 라인 처리
modified = False
for i, line in enumerate(lines):
    for pattern, replacement in replacements:
        if re.search(pattern, line.strip()):
            # 들여쓰기 유지
            indent = len(line) - len(line.lstrip())
            lines[i] = ' ' * indent + replacement + '\n'
            print(f"✅ Line {i+1}: 타입 오류 수정됨")
            modified = True

# 파일 저장
if modified:
    with open('lib/core/utils/load_location.dart', 'w') as f:
        f.writelines(lines)
    print("✅ load_location.dart 수정 완료")
else:
    print("ℹ️ 수정할 타입 오류를 찾지 못했습니다")
EOF

python3 fix_load_location.py
rm fix_load_location.py

# 2. login_screen.dart 수정
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 login_screen.dart 타입 오류 수정"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat > fix_login_screen.py << 'EOF'
#!/usr/bin/env python3
import re

# 파일 읽기
with open('lib/presentation/screens/auth/login_screen.dart', 'r') as f:
    lines = f.readlines()

# 수정할 패턴들
replacements = [
    # statusCode를 문자열로
    (r'AppLogger\.d\(response\.statusCode\);?$',
     'AppLogger.d("Response status code: ${response.statusCode}");'),
     
    # response.data도 안전하게 처리
    (r'AppLogger\.d\(response\.data\);?$',
     'AppLogger.d("Response data: ${response.data}");'),
     
    # roleResponse 처리
    (r'AppLogger\.d\(\$roleResponse\);?$',
     'AppLogger.d("Role response: $roleResponse");')
]

# 각 라인 처리
modified = False
for i, line in enumerate(lines):
    for pattern, replacement in replacements:
        if re.search(pattern, line.strip()):
            # 들여쓰기 유지
            indent = len(line) - len(line.lstrip())
            lines[i] = ' ' * indent + replacement + '\n'
            print(f"✅ Line {i+1}: 타입 오류 수정됨")
            modified = True

# 파일 저장
if modified:
    with open('lib/presentation/screens/auth/login_screen.dart', 'w') as f:
        f.writelines(lines)
    print("✅ login_screen.dart 수정 완료")
else:
    print("ℹ️ 수정할 타입 오류를 찾지 못했습니다")
EOF

python3 fix_login_screen.py
rm fix_login_screen.py

# 3. 중복 import 제거
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧹 중복 import 제거"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# login_screen.dart의 중복 import 제거
echo "login_screen.dart 중복 import 확인..."
IMPORT_COUNT=$(grep -c "import.*app_logger.dart" lib/presentation/screens/auth/login_screen.dart)
echo "app_logger import 개수: $IMPORT_COUNT"

if [ "$IMPORT_COUNT" -gt 1 ]; then
    echo "중복 import 제거 중..."
    
    # Python으로 안전하게 제거
    cat > remove_dup_imports.py << 'EOF'
import re

with open('lib/presentation/screens/auth/login_screen.dart', 'r') as f:
    lines = f.readlines()

seen_app_logger = False
new_lines = []

for line in lines:
    if 'app_logger.dart' in line and 'import' in line:
        if not seen_app_logger:
            new_lines.append(line)
            seen_app_logger = True
        else:
            print(f"제거: {line.strip()}")
    else:
        new_lines.append(line)

with open('lib/presentation/screens/auth/login_screen.dart', 'w') as f:
    f.writelines(new_lines)

print("✅ 중복 import 제거 완료")
EOF
    
    python3 remove_dup_imports.py
    rm remove_dup_imports.py
fi

# 4. 파일 검증
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 파일 검증"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 파일 크기 확인
LOCATION_LINES=$(wc -l < lib/core/utils/load_location.dart)
LOGIN_LINES=$(wc -l < lib/presentation/screens/auth/login_screen.dart)

echo "load_location.dart: $LOCATION_LINES 줄"
echo "login_screen.dart: $LOGIN_LINES 줄"

if [ "$LOCATION_LINES" -lt 100 ]; then
    echo -e "${RED}⚠️ 경고: load_location.dart가 손상되었을 수 있습니다!${NC}"
    echo "백업에서 복구: cp $BACKUP_DIR/load_location.dart.backup lib/core/utils/load_location.dart"
else
    echo -e "${GREEN}✅ 파일 크기 정상${NC}"
fi

# 5. Flutter 분석
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 오류 확인"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 타입 오류만 확인
flutter analyze --no-fatal-warnings 2>&1 | grep "argument_type_not_assignable" | head -10

TYPE_ERRORS=$(flutter analyze --no-fatal-warnings 2>&1 | grep -c "argument_type_not_assignable")

if [ "$TYPE_ERRORS" -eq 0 ]; then
    echo -e "${GREEN}✅ 모든 타입 오류 해결!${NC}"
else
    echo -e "${YELLOW}⚠️ 남은 타입 오류: $TYPE_ERRORS건${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 안전한 수정 완료"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "백업 위치: $BACKUP_DIR"
echo ""
echo "문제 발생 시 복구 명령:"
echo "cp $BACKUP_DIR/load_location.dart.backup lib/core/utils/load_location.dart"
echo "cp $BACKUP_DIR/login_screen.dart.backup lib/presentation/screens/auth/login_screen.dart"
echo ""
