#!/bin/bash

echo "=== Login Screen 보안 적용 ==="

# 1. login_screen.dart 백업
cp lib/presentation/screens/auth/login_screen.dart lib/presentation/screens/auth/login_screen.dart.backup

# 2. Import 추가
echo "Import 추가 중..."
if ! grep -q "import 'package:vms_app/core/services/secure_api_service.dart';" lib/presentation/screens/auth/login_screen.dart; then
  sed -i "15i import 'package:vms_app/core/services/secure_api_service.dart';" lib/presentation/screens/auth/login_screen.dart
  sed -i "16i import 'package:vms_app/core/utils/app_logger.dart';" lib/presentation/screens/auth/login_screen.dart
fi

# 3. SecureApiService 멤버 추가
echo "SecureApiService 멤버 추가 중..."
if ! grep -q "final _secureApiService = SecureApiService();" lib/presentation/screens/auth/login_screen.dart; then
  sed -i '/class _CmdViewState extends State<LoginView> {/a\  final _secureApiService = SecureApiService();' lib/presentation/screens/auth/login_screen.dart
fi

# 4. print 문을 AppLogger로 변경
echo "로그 변경 중..."
sed -i "s/print('/AppLogger.d('/g" lib/presentation/screens/auth/login_screen.dart
sed -i "s/print(\$/AppLogger.d(\$/g" lib/presentation/screens/auth/login_screen.dart

echo "✅ 보안 적용 완료"
echo "⚠️  submitForm 메서드는 수동으로 수정 필요"
echo "    integration_guide.md 참조"
