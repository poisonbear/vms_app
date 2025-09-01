#!/bin/bash

echo "불필요한 주석 제거 중..."

# 주석 처리된 logger 구문 제거
find lib -name "*.dart" -type f -exec sed -i '/^[[:space:]]*\/\/.*logger\./d' {} \;

# 주석 처리된 print 구문 제거
find lib -name "*.dart" -type f -exec sed -i '/^[[:space:]]*\/\/.*print(/d' {} \;

# 연속된 빈 줄 제거 (최대 2줄로 제한)
find lib -name "*.dart" -type f -exec sed -i '/^$/N;/^\n$/d' {} \;

echo "✅ 불필요한 주석 제거 완료"
