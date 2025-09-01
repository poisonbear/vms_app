#!/bin/bash

# VMS App - warningPopdetail 매개변수 수정 스크립트
# 실행 방법: Git Bash에서 프로젝트 루트 디렉토리에서 실행
# chmod +x fix_warning_pop_detail.sh && ./fix_warning_pop_detail.sh

echo "========================================="
echo "VMS App - warningPopdetail 에러 수정"
echo "========================================="

# 1. main_screen.dart에서 warningPopdetail 호출 부분 찾기
echo ""
echo "📝 main_screen.dart에서 warningPopdetail 호출 부분 확인 중..."

# main_screen.dart 백업
if [ -f "lib/presentation/screens/main/main_screen.dart" ]; then
    cp lib/presentation/screens/main/main_screen.dart lib/presentation/screens/main/main_screen.dart.backup
    echo "✅ main_screen.dart 백업 완료"
fi

# warningPopdetail 호출 부분 찾아서 수정
echo ""
echo "📝 warningPopdetail 호출 수정 중..."

# Python 스크립트로 정확한 수정 (라인 2075 근처)
cat > fix_warning_pop_call.py << 'EOF'
import re

# main_screen.dart 파일 읽기
with open('lib/presentation/screens/main/main_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 2075번 라인 근처에서 warningPopdetail 호출 찾기 및 수정
modified = False
for i in range(2070, min(2080, len(lines))):
    if 'warningPopdetail(' in lines[i]:
        # 함수 호출 전체 찾기 (여러 줄에 걸쳐 있을 수 있음)
        call_start = i
        paren_count = 0
        call_end = i
        
        # 괄호 짝 맞추기로 함수 호출 끝 찾기
        for j in range(i, min(i+20, len(lines))):
            for char in lines[j]:
                if char == '(':
                    paren_count += 1
                elif char == ')':
                    paren_count -= 1
                    if paren_count == 0:
                        call_end = j
                        break
            if paren_count == 0:
                break
        
        # 함수 호출 부분 추출
        call_text = ''.join(lines[call_start:call_end+1])
        
        # 매개변수 개수 확인
        # warningPopdetail은 8개 매개변수 필요:
        # context, title, titleColor, detail, detailColor, additionalInfo, alarmIcon, shadowColor
        
        # 매개변수 분석
        params = []
        temp_param = ''
        paren_depth = 0
        in_string = False
        string_char = None
        
        # 첫 번째 '(' 이후부터 파싱
        start_parsing = False
        for char in call_text:
            if char == '(' and not start_parsing:
                start_parsing = True
                continue
            
            if not start_parsing:
                continue
                
            # 문자열 처리
            if char in ['"', "'"] and not in_string:
                in_string = True
                string_char = char
                temp_param += char
            elif in_string and char == string_char and temp_param[-1] != '\\':
                in_string = False
                temp_param += char
            elif in_string:
                temp_param += char
            # 괄호 깊이 처리
            elif char == '(' and not in_string:
                paren_depth += 1
                temp_param += char
            elif char == ')' and not in_string:
                if paren_depth > 0:
                    paren_depth -= 1
                    temp_param += char
                else:
                    # 함수 호출 끝
                    if temp_param.strip():
                        params.append(temp_param.strip())
                    break
            elif char == ',' and paren_depth == 0 and not in_string:
                params.append(temp_param.strip())
                temp_param = ''
            else:
                temp_param += char
        
        print(f"발견된 매개변수 개수: {len(params)}")
        print("매개변수 목록:")
        for idx, param in enumerate(params):
            print(f"  {idx+1}: {param[:50]}...")  # 처음 50자만 표시
        
        # 7개 매개변수를 8개로 수정 (additionalInfo 추가)
        if len(params) == 7:
            # additionalInfo 매개변수 추가 (6번째 위치에 빈 문자열)
            params.insert(5, "''")  # detail 다음, alarmIcon 전에 추가
            
            # 새로운 함수 호출 생성
            new_call = f"warningPopdetail(\n"
            for idx, param in enumerate(params):
                if idx == len(params) - 1:
                    new_call += f"          {param}"
                else:
                    new_call += f"          {param},\n"
            new_call += ");"
            
            # 원본 텍스트 교체
            lines[call_start] = new_call + '\n'
            
            # 원래 여러 줄이었다면 나머지 줄 제거
            for k in range(call_start + 1, call_end + 1):
                lines[k] = ''
            
            modified = True
            print(f"\n✅ 라인 {call_start + 1}의 warningPopdetail 호출 수정 완료")
            break

if not modified:
    print("⚠️  warningPopdetail 호출을 찾을 수 없거나 이미 올바른 매개변수 개수입니다.")
else:
    # 파일 저장
    with open('lib/presentation/screens/main/main_screen.dart', 'w', encoding='utf-8') as f:
        f.writelines(lines)
    print("✅ 파일 저장 완료")
EOF

# Python 스크립트 실행
python fix_warning_pop_call.py

# Python 스크립트 삭제
rm fix_warning_pop_call.py

echo ""
echo "📝 warningPopdetail 함수 정의 확인 중..."

# dio_client.dart의 warningPopdetail 함수 시그니처 확인
if grep -q "warningPopdetail" lib/core/network/dio_client.dart; then
    echo "✅ warningPopdetail 함수 정의 확인됨"
else
    echo "⚠️  warningPopdetail 함수가 정의되지 않았습니다. 다시 추가합니다..."
    
    # warningPopdetail 함수 추가 (dio_client.dart 끝에)
    cat >> lib/core/network/dio_client.dart << 'EOF'

/// 상세 경고 팝업 (8개 매개변수)
Future<void> warningPopdetail(
  BuildContext context,
  String title,
  Color titleColor,
  String detail,
  Color detailColor,
  String additionalInfo,  // 추가 정보
  String alarmIcon,
  Color shadowColor,
) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      return Stack(
        children: [
          // 배경
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    shadowColor.withOpacity(0.1),
                    shadowColor.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ),
          // 팝업 내용
          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 아이콘
                    if (alarmIcon.isNotEmpty)
                      SvgPicture.asset(
                        alarmIcon,
                        width: 48,
                        height: 48,
                        colorFilter: ColorFilter.mode(titleColor, BlendMode.srcIn),
                      ),
                    const SizedBox(height: 16),
                    // 제목
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // 상세 내용
                    Text(
                      detail,
                      style: TextStyle(
                        fontSize: 14,
                        color: detailColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // 추가 정보 (있는 경우에만 표시)
                    if (additionalInfo.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          additionalInfo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    // 버튼들
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            '취소',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: titleColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '확인',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
EOF
fi

# 2. 간단한 수정 방법 (sed 사용) - 백업용
echo ""
echo "📝 추가 검증 및 수정..."

# warningPopdetail 호출 찾아서 수정하는 대체 방법
cat > alternative_fix.sh << 'EOF'
#!/bin/bash

# main_screen.dart에서 warningPopdetail 호출 라인 찾기
LINE_NUM=$(grep -n "warningPopdetail(" lib/presentation/screens/main/main_screen.dart | head -1 | cut -d: -f1)

if [ ! -z "$LINE_NUM" ]; then
    echo "warningPopdetail 호출이 라인 $LINE_NUM 에서 발견됨"
    
    # 해당 라인 근처 내용 확인
    echo "호출 부분 확인:"
    sed -n "$((LINE_NUM-2)),$((LINE_NUM+10))p" lib/presentation/screens/main/main_screen.dart
    
    # 매개변수 개수 확인을 위한 간단한 방법
    # 콤마 개수를 세어 매개변수 개수 추정
    COMMA_COUNT=$(sed -n "${LINE_NUM}p" lib/presentation/screens/main/main_screen.dart | grep -o "," | wc -l)
    echo "발견된 콤마 개수: $COMMA_COUNT (예상 매개변수: $((COMMA_COUNT+1)))"
fi
EOF

chmod +x alternative_fix.sh

# 3. 검증 스크립트
echo ""
echo "📝 검증 스크립트 생성 중..."

cat > verify_warning_pop.sh << 'EOF'
#!/bin/bash

echo "========================================="
echo "warningPopdetail 수정 검증"
echo "========================================="

# 1. 함수 정의 확인
echo ""
echo "1. warningPopdetail 함수 정의 확인:"
if grep -q "Future<void> warningPopdetail(" lib/core/network/dio_client.dart; then
    echo "✅ 함수 정의 있음"
    # 매개변수 개수 확인
    PARAMS=$(grep -A 8 "Future<void> warningPopdetail(" lib/core/network/dio_client.dart | grep -c "^\s*[A-Z]")
    echo "   매개변수 개수: $PARAMS"
else
    echo "❌ 함수 정의 없음"
fi

# 2. 함수 호출 확인
echo ""
echo "2. main_screen.dart에서 warningPopdetail 호출:"
grep -n "warningPopdetail(" lib/presentation/screens/main/main_screen.dart | head -3

# 3. Flutter analyze 실행
echo ""
echo "3. Flutter analyze 결과:"
flutter analyze | grep -e "warningPopdetail" -e "not_enough_positional_arguments"

if [ $? -ne 0 ]; then
    echo "✅ warningPopdetail 관련 에러 없음"
else
    echo "⚠️  아직 에러가 있습니다"
fi

echo ""
echo "========================================="
EOF

chmod +x verify_warning_pop.sh

echo ""
echo "========================================="
echo "✅ warningPopdetail 수정 완료!"
echo "========================================="
echo ""
echo "📌 수정 내용:"
echo "  - warningPopdetail 호출 시 8번째 매개변수(additionalInfo) 추가"
echo "  - 빈 문자열('')로 추가하여 기존 동작 유지"
echo ""
echo "📌 생성된 스크립트:"
echo "  - alternative_fix.sh (대체 수정 방법)"
echo "  - verify_warning_pop.sh (검증 스크립트)"
echo ""
echo "🔧 다음 단계:"
echo "  1. 수정 검증:"
echo "     ./verify_warning_pop.sh"
echo ""
echo "  2. Flutter analyze 확인:"
echo "     flutter analyze | grep -e 'error'"
echo ""
echo "  3. 프로젝트 재빌드:"
echo "     flutter pub get"
echo "     flutter run"
echo ""
echo "💡 수정 사항:"
echo "  - warningPopdetail 함수는 8개 매개변수 필요"
echo "  - 호출 시 additionalInfo 매개변수 추가 (빈 문자열)"
