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
