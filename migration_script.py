#!/usr/bin/env python3
"""
Constants 마이그레이션 스크립트 (개선된 버전)
사용법: python migration_script.py [--dry-run]

⚠️  주의: 실행 전 반드시 Git 커밋 또는 수동 백업을 하세요!
"""

import os
import re
from pathlib import Path
import sys

class ConstantsMigration:
    def __init__(self, project_root='.', dry_run=False):
        self.project_root = Path(project_root)
        self.lib_path = self.project_root / 'lib'
        self.dry_run = dry_run
        self.stats = {
            'files_processed': 0,
            'replacements': 0,
            'colors': 0,
            'sizes': 0,
            'validation': 0,
            'api': 0,
            'font_weights': 0,
            'text_aligns': 0,
            'borders': 0,
        }

    def run(self):
        """전체 마이그레이션 실행"""
        mode = "DRY RUN" if self.dry_run else "LIVE"
        print(f"🚀 Constants 마이그레이션 시작... ({mode})")
        print(f"프로젝트 경로: {self.project_root.absolute()}")
        
        if not self.dry_run:
            print("\n⚠️  경고: 파일이 실제로 변경됩니다!")
            print("   Git 커밋 또는 백업을 완료했는지 확인하세요.\n")
        
        # Dart 파일 찾기
        dart_files = list(self.lib_path.rglob('*.dart'))
        print(f"📁 발견된 Dart 파일: {len(dart_files)}개\n")
        
        # 파일별 마이그레이션
        for dart_file in dart_files:
            self.migrate_file(dart_file)
        
        # 결과 출력
        self.print_summary()

    def migrate_file(self, file_path):
        """개별 파일 마이그레이션"""
        try:
            # UTF-8 BOM 처리
            try:
                with open(file_path, 'r', encoding='utf-8-sig') as f:
                    content = f.read()
            except UnicodeDecodeError:
                # Fallback to cp949 (Windows Korean)
                with open(file_path, 'r', encoding='cp949') as f:
                    content = f.read()
            
            original_content = content
            
            # 1. Colors 마이그레이션
            content, color_count = self.migrate_colors(content)
            self.stats['colors'] += color_count
            
            # 2. Font/Text 마이그레이션
            content, font_count = self.migrate_font_text(content)
            self.stats['font_weights'] += font_count
            
            # 3. Sizes 마이그레이션
            content, size_count = self.migrate_sizes(content)
            self.stats['sizes'] += size_count
            
            # 4. Validation 마이그레이션
            content, validation_count = self.migrate_validation(content)
            self.stats['validation'] += validation_count
            
            # 5. API Config 마이그레이션
            content, api_count = self.migrate_api(content)
            self.stats['api'] += api_count
            
            # 변경사항이 있으면 저장
            if content != original_content:
                total_replacements = (color_count + font_count + size_count + 
                                    validation_count + api_count)
                
                if self.dry_run:
                    print(f"[DRY RUN] {file_path.relative_to(self.project_root)} "
                          f"({total_replacements}개 변경 예정)")
                else:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    
                    print(f"✅ {file_path.relative_to(self.project_root)} "
                          f"({total_replacements}개 변경)")
                
                self.stats['files_processed'] += 1
                self.stats['replacements'] += total_replacements
        
        except Exception as e:
            print(f"❌ {file_path.relative_to(self.project_root)}: {e}")

    def migrate_colors(self, content):
        """Colors 마이그레이션"""
        replacements = [
            # White Type
            (r'getColorWhiteType1\(\)', 'AppColors.whiteType1'),
            
            # Black Types
            (r'getColorBlackType1\(\)', 'AppColors.blackType1'),
            (r'getColorBlackType2\(\)', 'AppColors.blackType2'),
            (r'getColorBlackType3\(\)', 'AppColors.blackType3'),
            (r'getColorBlackType4\(\)', 'AppColors.blackType4'),
            
            # Gray Types (14개) - 긴 것부터 먼저!
            (r'getColorGrayType14\(\)', 'AppColors.grayType14'),
            (r'getColorGrayType13\(\)', 'AppColors.grayType13'),
            (r'getColorGrayType12\(\)', 'AppColors.grayType12'),
            (r'getColorGrayType11\(\)', 'AppColors.grayType11'),
            (r'getColorGrayType10\(\)', 'AppColors.grayType10'),
            (r'getColorGrayType9\(\)', 'AppColors.grayType9'),
            (r'getColorGrayType8\(\)', 'AppColors.grayType8'),
            (r'getColorGrayType7\(\)', 'AppColors.grayType7'),
            (r'getColorGrayType6\(\)', 'AppColors.grayType6'),
            (r'getColorGrayType5\(\)', 'AppColors.grayType5'),
            (r'getColorGrayType4\(\)', 'AppColors.grayType4'),
            (r'getColorGrayType3\(\)', 'AppColors.grayType3'),
            (r'getColorGrayType2\(\)', 'AppColors.grayType2'),
            (r'getColorGrayType1\(\)', 'AppColors.grayType1'),
            
            # Red Types
            (r'getColorRedType3\(\)', 'AppColors.redType3'),
            (r'getColorRedType2\(\)', 'AppColors.redType2'),
            (r'getColorRedType1\(\)', 'AppColors.redType1'),
            
            # Sky Types
            (r'getColorSkyType3\(\)', 'AppColors.skyType3'),
            (r'getColorSkyType2\(\)', 'AppColors.skyType2'),
            (r'getColorSkyType1\(\)', 'AppColors.skyType1'),
            
            # Main Type
            (r'getColorMainType1\(\)', 'AppColors.mainType1'),
            
            # Green Type
            (r'getColorGreenType1\(\)', 'AppColors.greenType1'),
            
            # Yellow Types
            (r'getColorYellowType2\(\)', 'AppColors.yellowType2'),
            (r'getColorYellowType1\(\)', 'AppColors.yellowType1'),
            
            # Emergency Red Shades - 긴 것부터!
            (r'getColorEmergencyRed700\(\)', 'AppColors.emergencyRed700'),
            (r'getColorEmergencyRed600\(\)', 'AppColors.emergencyRed600'),
            (r'getColorEmergencyRed500\(\)', 'AppColors.emergencyRed500'),
            (r'getColorEmergencyRed400\(\)', 'AppColors.emergencyRed400'),
            (r'getColorEmergencyRed200\(\)', 'AppColors.emergencyRed200'),
            (r'getColorEmergencyRed100\(\)', 'AppColors.emergencyRed100'),
            (r'getColorEmergencyRed50\(\)', 'AppColors.emergencyRed50'),
            (r'getColorEmergencyRed\(\)', 'AppColors.emergencyRed'),
            
            # Emergency Blue Shades
            (r'getColorEmergencyBlue200\(\)', 'AppColors.emergencyBlue200'),
            (r'getColorEmergencyBlue50\(\)', 'AppColors.emergencyBlue50'),
            
            # Emergency Other
            (r'getColorEmergencyOrange\(\)', 'AppColors.emergencyOrange'),
            (r'getColorEmergencyGreenAccent\(\)', 'AppColors.emergencyGreenAccent'),
            (r'getColorEmergencyGreen\(\)', 'AppColors.emergencyGreen'),
            
            # Emergency Opacity - 긴 것부터!
            (r'getColorEmergencyWhite80\(\)', 'AppColors.white80'),
            (r'getColorEmergencyWhite70\(\)', 'AppColors.white70'),
            (r'getColorEmergencyRedOpacity40\(\)', 'AppColors.emergencyRed40'),
            (r'getColorEmergencyRedOpacity30\(\)', 'AppColors.emergencyRed30'),
            (r'getColorEmergencyBlackOpacity30\(\)', 'AppColors.black30'),
            (r'getColorEmergencyBlackOpacity05\(\)', 'AppColors.black05'),
        ]
        
        count = 0
        for pattern, replacement in replacements:
            new_content, n = re.subn(pattern, replacement, content)
            content = new_content
            count += n
        
        return content, count

    def migrate_font_text(self, content):
        """Font weights, Text aligns, Borders 마이그레이션"""
        replacements = [
            # Font weights
            (r'getTextbold\(\)', 'FontWeights.bold'),
            (r'getText700\(\)', 'FontWeights.w700'),
            (r'getText600\(\)', 'FontWeights.w600'),
            (r'getText500\(\)', 'FontWeights.w500'),
            (r'getText400\(\)', 'FontWeights.w400'),
            (r'getTextnormal\(\)', 'FontWeights.normal'),
            
            # Text alignment
            (r'getTextcenter\(\)', 'TextAligns.center'),
            (r'getTextright\(\)', 'TextAligns.right'),
            (r'getTextleft\(\)', 'TextAligns.left'),
            
            # Borders
            (r'getTextradius6\(\)', 'Borders.rounded10'),
            (r'getTextRadius6Direct\(\)', 'Borders.radius10'),
        ]
        
        count = 0
        for pattern, replacement in replacements:
            new_content, n = re.subn(pattern, replacement, content)
            content = new_content
            count += n
        
        return content, count

    def migrate_sizes(self, content):
        """Sizes 마이그레이션"""
        count = 0
        
        # 숫자 리스트 (중복 없이 정렬)
        sizes = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 18, 20, 21, 
                 24, 25, 26, 28, 29, 30, 32, 34, 35, 36, 37, 40, 41, 44, 45, 48, 50, 
                 52, 54, 56, 60, 65, 70, 80, 92, 96, 100, 120, 133, 134, 150, 160, 
                 170, 180, 206, 266, 300, 312, 330, 350, 400, 520, 550, 580]
        
        # 큰 숫자부터 처리 (580 -> 0 순서)
        for i in reversed(sizes):
            # getSize{i}() → AppSizes.s{i}
            pattern = rf'getSize{i}\(\)'
            replacement = f'AppSizes.s{i}'
            new_content, n = re.subn(pattern, replacement, content)
            content = new_content
            count += n
            
            # getSizeInt{i}() → AppSizes.i{i}
            pattern = rf'getSizeInt{i}\(\)'
            replacement = f'AppSizes.i{i}'
            new_content, n = re.subn(pattern, replacement, content)
            content = new_content
            count += n
        
        # 특수값 (소수점)
        new_content, n = re.subn(r'getSize1_333\(\)', 'AppSizes.s1_333', content)
        content = new_content
        count += n
        
        return content, count

    def migrate_validation(self, content):
        """Validation 마이그레이션"""
        replacements = [
            # Import 변경
            (r"import 'package:vms_app/core/constants/validation_constants\.dart'", 
             "import 'package:vms_app/core/constants/validation_rules.dart'"),
            (r"import 'package:vms_app/core/constants/validation_patterns\.dart'", 
             "import 'package:vms_app/core/constants/validation_rules.dart'"),
            
            # 클래스명 변경
            (r'ValidationConstants\.', 'ValidationRules.'),
            (r'ValidationPatterns\.', 'ValidationRules.'),
        ]
        
        count = 0
        for pattern, replacement in replacements:
            new_content, n = re.subn(pattern, replacement, content)
            content = new_content
            count += n
        
        return content, count

    def migrate_api(self, content):
        """API Config 마이그레이션"""
        replacements = [
            # Import 변경
            (r"import 'package:vms_app/core/constants/env_keys\.dart'", 
             "import 'package:vms_app/core/constants/api_config.dart'"),
            (r"import 'package:vms_app/core/constants/api_endpoints\.dart'", 
             "import 'package:vms_app/core/constants/api_config.dart'"),
            
            # 클래스명 변경
            (r'EnvKeys\.', 'ApiConfig.'),
            (r'ApiEndpoints\.', 'ApiConfig.'),
        ]
        
        count = 0
        for pattern, replacement in replacements:
            new_content, n = re.subn(pattern, replacement, content)
            content = new_content
            count += n
        
        return content, count

    def print_summary(self):
        """마이그레이션 결과 출력"""
        print("\n" + "="*60)
        if self.dry_run:
            print("📊 마이그레이션 미리보기 (DRY RUN)")
        else:
            print("📊 마이그레이션 완료!")
        print("="*60)
        print(f"처리된 파일: {self.stats['files_processed']}개")
        print(f"총 변경사항: {self.stats['replacements']}개")
        print(f"  - Colors: {self.stats['colors']}개")
        print(f"  - Font/Text: {self.stats['font_weights']}개")
        print(f"  - Sizes: {self.stats['sizes']}개")
        print(f"  - Validation: {self.stats['validation']}개")
        print(f"  - API Config: {self.stats['api']}개")
        print("="*60)
        
        if self.dry_run:
            print("\n💡 실제 마이그레이션을 실행하려면:")
            print("   python migration_script.py")
            print("\n⚠️  실행 전 반드시 Git 커밋하세요!")
        else:
            print("\n✅ 다음 단계:")
            print("1. flutter pub get")
            print("2. flutter analyze")
            print("3. ⚠️  수동 작업 필요:")
            print("   grep -r \"dotenv.env\\[\" lib/")
            print("   (dotenv.env 직접 사용을 ApiConfig로 변경)")
            print("4. 앱 실행 및 테스트")
            print("5. 문제 없으면 이전 파일 삭제:")
            print("   - validation_constants.dart")
            print("   - validation_patterns.dart")
            print("   - env_keys.dart")
            print("   - api_endpoints.dart")


def main():
    """메인 함수"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Constants 마이그레이션 스크립트')
    parser.add_argument('--dry-run', action='store_true', 
                       help='실제 변경 없이 미리보기만 실행')
    parser.add_argument('--project-root', default='.', 
                       help='프로젝트 루트 경로 (기본: 현재 디렉토리)')
    
    args = parser.parse_args()
    
    migration = ConstantsMigration(
        project_root=args.project_root,
        dry_run=args.dry_run
    )
    migration.run()


if __name__ == '__main__':
    main()
