#!/bin/bash

echo "🔧 Git Bash용 수정 스크립트..."
echo "================================"
echo ""

# Git Bash에서 작동하도록 수정

# 1. 각 파일을 개별적으로 처리
echo "[1/11] permission_manager.dart 수정..."
if [ -f "lib/core/utils/permission_manager.dart" ]; then
    cat lib/core/utils/permission_manager.dart | \
    sed 's/AnimationConstants autoScrollDelay/AnimationConstants.autoScrollDelay/g' \
    > lib/core/utils/permission_manager.dart.tmp
    mv lib/core/utils/permission_manager.dart.tmp lib/core/utils/permission_manager.dart
    echo "✓"
fi

echo "[2/11] main.dart 수정..."
if [ -f "lib/main.dart" ]; then
    cat lib/main.dart | \
    sed 's/AnimationConstants splashDuration/AnimationConstants.splashDuration/g' \
    > lib/main.dart.tmp
    mv lib/main.dart.tmp lib/main.dart
    echo "✓"
fi

echo "[3/11] login_screen.dart 수정..."
if [ -f "lib/presentation/screens/auth/login_screen.dart" ]; then
    cat lib/presentation/screens/auth/login_screen.dart | \
    sed 's/AnimationConstants durationInstant/AnimationConstants.durationInstant/g' \
    > lib/presentation/screens/auth/login_screen.dart.tmp
    mv lib/presentation/screens/auth/login_screen.dart.tmp lib/presentation/screens/auth/login_screen.dart
    echo "✓"
fi

echo "[4/11] main_screen.dart 수정..."
if [ -f "lib/presentation/screens/main/main_screen.dart" ]; then
    cat lib/presentation/screens/main/main_screen.dart | \
    sed 's/AnimationConstants autoScrollDelay/AnimationConstants.autoScrollDelay/g' | \
    sed 's/AnimationConstants durationNormal/AnimationConstants.durationNormal/g' | \
    sed 's/AnimationConstants durationVerySlow/AnimationConstants.durationVerySlow/g' | \
    sed 's/AnimationConstants weatherUpdateInterval/AnimationConstants.weatherUpdateInterval/g' | \
    sed 's/AnimationConstants durationQuick/AnimationConstants.durationQuick/g' \
    > lib/presentation/screens/main/main_screen.dart.tmp
    mv lib/presentation/screens/main/main_screen.dart.tmp lib/presentation/screens/main/main_screen.dart
    echo "✓"
fi

echo "[5/11] navigation_calendar.dart 수정..."
if [ -f "lib/presentation/screens/main/tabs/navigation_calendar.dart" ]; then
    cat lib/presentation/screens/main/tabs/navigation_calendar.dart | \
    sed 's/AnimationConstants durationInstant/AnimationConstants.durationInstant/g' \
    > lib/presentation/screens/main/tabs/navigation_calendar.dart.tmp
    mv lib/presentation/screens/main/tabs/navigation_calendar.dart.tmp lib/presentation/screens/main/tabs/navigation_calendar.dart
    echo "✓"
fi

echo "[6/11] edit_profile_screen.dart 수정..."
if [ -f "lib/presentation/screens/profile/edit_profile_screen.dart" ]; then
    cat lib/presentation/screens/profile/edit_profile_screen.dart | \
    sed 's/AnimationConstants durationInstant/AnimationConstants.durationInstant/g' \
    > lib/presentation/screens/profile/edit_profile_screen.dart.tmp
    mv lib/presentation/screens/profile/edit_profile_screen.dart.tmp lib/presentation/screens/profile/edit_profile_screen.dart
    echo "✓"
fi

echo "[7/11] profile_screen.dart 수정..."
if [ -f "lib/presentation/screens/profile/profile_screen.dart" ]; then
    cat lib/presentation/screens/profile/profile_screen.dart | \
    sed 's/AnimationConstants durationQuick/AnimationConstants.durationQuick/g' | \
    sed 's/AnimationConstants durationFast/AnimationConstants.durationFast/g' \
    > lib/presentation/screens/profile/profile_screen.dart.tmp
    mv lib/presentation/screens/profile/profile_screen.dart.tmp lib/presentation/screens/profile/profile_screen.dart
    echo "✓"
fi

echo "[8/11] common_widgets.dart 수정..."
if [ -f "lib/presentation/widgets/common/common_widgets.dart" ]; then
    cat lib/presentation/widgets/common/common_widgets.dart | \
    sed 's/AnimationConstants splashDuration/AnimationConstants.splashDuration/g' | \
    sed 's/AnimationConstants notificationDuration/AnimationConstants.notificationDuration/g' \
    > lib/presentation/widgets/common/common_widgets.dart.tmp
    mv lib/presentation/widgets/common/common_widgets.dart.tmp lib/presentation/widgets/common/common_widgets.dart
    echo "✓"
fi

echo "[9/11] app_colors.dart 수정..."
if [ -f "lib/core/constants/app_colors.dart" ]; then
    # 160번, 164번 라인의 DesignConstants를 10.0으로 변경
    cat lib/core/constants/app_colors.dart | \
    sed '160s/DesignConstants\.[a-zA-Z0-9_]*/10.0/g' | \
    sed '164s/DesignConstants\.[a-zA-Z0-9_]*/10.0/g' \
    > lib/core/constants/app_colors.dart.tmp
    mv lib/core/constants/app_colors.dart.tmp lib/core/constants/app_colors.dart
    echo "✓"
fi

echo "[10/11] weather_tab.dart 수정..."
if [ -f "lib/presentation/screens/main/tabs/weather_tab.dart" ]; then
    cat lib/presentation/screens/main/tabs/weather_tab.dart | \
    sed 's/DesignConstants\.spacing10\.toDouble()/DesignConstants.spacing10/g' \
    > lib/presentation/screens/main/tabs/weather_tab.dart.tmp
    mv lib/presentation/screens/main/tabs/weather_tab.dart.tmp lib/presentation/screens/main/tabs/weather_tab.dart
    echo "✓"
fi

echo "[11/11] 모든 dart 파일에서 누락된 패턴 수정..."
# 나머지 누락된 패턴들 처리
for pattern in "durationSlow" "durationVerySlow" "notificationDuration"; do
    for file in lib/**/*.dart lib/**/**/*.dart lib/**/**/**/*.dart; do
        if [ -f "$file" ]; then
            if grep -q "AnimationConstants $pattern" "$file" 2>/dev/null; then
                cat "$file" | sed "s/AnimationConstants $pattern/AnimationConstants.$pattern/g" > "$file.tmp"
                mv "$file.tmp" "$file"
            fi
        fi
    done
done

echo ""
echo "================================"
echo "✅ 수정 완료!"
echo ""
echo "🔍 검증 중..."

# 에러 개수 확인
ERROR_COUNT=$(flutter analyze 2>&1 | grep -c "error" || echo "0")
echo "남은 에러: $ERROR_COUNT개"

if [ "$ERROR_COUNT" -eq "0" ]; then
    echo "✨ 모든 에러가 해결되었습니다!"
else
    echo ""
    echo "⚠️ 아직 에러가 있습니다. Android Studio에서 다음을 수행하세요:"
    echo ""
    echo "1. Ctrl+Shift+R (Replace in Path)"
    echo "2. Regex 체크박스 활성화"
    echo "3. Find: AnimationConstants\\s+(\\w+)"
    echo "4. Replace: AnimationConstants.\$1"
    echo "5. Replace All 클릭"
fi
