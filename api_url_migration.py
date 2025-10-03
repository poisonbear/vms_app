#!/usr/bin/env python3
"""
API URL 마이그레이션 스크립트 (개선 버전)
dotenv.env['키'] -> ApiConfig.xxx 형식으로 일괄 변경
+ import 문 자동 추가
+ 불필요한 import 정리
+ 백업 파일 생성

실행 방법:
  python api_url_migration.py              # 실제 변경
  python api_url_migration.py --dry-run    # 미리보기만
  python api_url_migration.py --check      # 변경 대상 파일만 확인
  python api_url_migration.py --backup     # 백업 폴더 생성
"""

import os
import re
import sys
import shutil
from pathlib import Path
from typing import Dict, List, Tuple, Set
from datetime import datetime


class ApiUrlMigration:
    """API URL 마이그레이션 도구 (개선 버전)"""

    # dotenv 키 -> ApiConfig getter 매핑
    API_MAPPINGS = {
        # Auth
        'kdn_loginForm_key': 'ApiConfig.authLogin',
        'kdn_usm_select_role_data_key': 'ApiConfig.authRole',
        'kdn_usm_insert_membership_key': 'ApiConfig.authRegister',
        
        # Member
        'kdn_usm_select_member_info_data': 'ApiConfig.memberInfo',
        'kdn_usm_update_membership_key': 'ApiConfig.updateMember',
        'kdn_usm_select_membership_search_key': 'ApiConfig.memberSearch',
        
        # Terms
        'kdn_usm_select_cmd_key': 'ApiConfig.termsList',
        
        # Vessel
        'kdn_gis_select_vessel_List': 'ApiConfig.vesselList',
        'kdn_gis_select_vessel_Route': 'ApiConfig.vesselRoute',
        
        # Weather
        'kdn_wid_select_weather_Info': 'ApiConfig.weatherInfo',
        
        # Navigation
        'kdn_ros_select_navigation_Info': 'ApiConfig.navigationHistory',
        'kdn_ros_select_visibility_Info': 'ApiConfig.navigationVisibility',
        'kdn_ros_select_navigation_warn_Info': 'ApiConfig.navigationWarnings',
        
        # Public Data
        'kdn_load_date': 'ApiConfig.holidayInfo',
        
        # Base URLs
        'BASE_URL': 'ApiConfig.baseUrl',
        'GEOSERVER_URL': 'ApiConfig.geoserverUrl',
    }

    # 필수 import 문
    CONSTANTS_IMPORT = "import 'package:vms_app/core/constants/constants.dart';"
    DOTENV_IMPORT_PATTERN = r"import\s+['\"]package:flutter_dotenv/flutter_dotenv\.dart['\"];"

    # 제외할 파일
    EXCLUDE_FILES = [
        'lib/core/constants/api_config.dart',
    ]

    def __init__(self, project_root: str = '.', dry_run: bool = False, 
                 check_only: bool = False, create_backup: bool = False):
        self.project_root = Path(project_root)
        self.dry_run = dry_run
        self.check_only = check_only
        self.create_backup = create_backup
        self.backup_dir = None
        
        self.stats = {
            'files_scanned': 0,
            'files_changed': 0,
            'total_replacements': 0,
            'imports_added': 0,
            'imports_removed': 0,
            'by_mapping': {},
        }
        self.changes: List[Dict] = []
        self.issues: List[Dict] = []

    def run(self):
        """마이그레이션 실행"""
        print("=" * 70)
        print("🔄 API URL 마이그레이션 시작 (개선 버전)")
        if self.dry_run:
            print("📋 DRY RUN 모드 - 실제 파일은 변경되지 않습니다")
        elif self.check_only:
            print("🔍 CHECK 모드 - 변경 대상 파일만 확인합니다")
        print("=" * 70)
        print()

        # 0. 백업 생성 (실제 변경 모드일 때만)
        if not self.dry_run and not self.check_only and self.create_backup:
            self._create_backup()

        # 1. 대상 파일 수집
        dart_files = self._collect_dart_files()
        print(f"📂 스캔할 Dart 파일: {len(dart_files)}개\n")

        # 2. 각 파일 처리
        for file_path in dart_files:
            self._process_file(file_path)

        # 3. 결과 출력
        self._print_summary()

        # 4. 변경사항 상세 출력
        if self.changes and not self.check_only:
            self._print_changes()

        # 5. 이슈 출력
        if self.issues:
            self._print_issues()

        return self.stats['files_changed'] > 0

    def _create_backup(self):
        """백업 폴더 생성"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        self.backup_dir = self.project_root / f'backup_before_migration_{timestamp}'
        
        try:
            lib_src = self.project_root / 'lib'
            lib_dst = self.backup_dir / 'lib'
            
            shutil.copytree(lib_src, lib_dst)
            print(f"✅ 백업 생성됨: {self.backup_dir}\n")
        except Exception as e:
            print(f"⚠️  백업 생성 실패: {e}")
            print("   계속하시겠습니까? (yes/no): ", end='')
            response = input()
            if response.lower() not in ['yes', 'y']:
                print("취소되었습니다.")
                sys.exit(0)
            print()

    def _collect_dart_files(self) -> List[Path]:
        """변경 대상 Dart 파일 수집"""
        files = []
        lib_dir = self.project_root / 'lib'
        
        if not lib_dir.exists():
            print(f"❌ lib 디렉토리를 찾을 수 없습니다: {lib_dir}")
            return files

        for dart_file in lib_dir.rglob('*.dart'):
            relative_path = str(dart_file.relative_to(self.project_root))
            if any(relative_path == exclude for exclude in self.EXCLUDE_FILES):
                continue
            files.append(dart_file)
        
        return sorted(files)

    def _process_file(self, file_path: Path):
        """단일 파일 처리"""
        self.stats['files_scanned'] += 1
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            replacements = []
            needs_constants_import = False
            has_constants_import = False
            can_remove_dotenv_import = True

            # 1. 현재 import 상태 확인
            has_constants_import = self.CONSTANTS_IMPORT in content
            has_dotenv_import = bool(re.search(self.DOTENV_IMPORT_PATTERN, content))

            # 2. dotenv.env 패턴 찾기 및 변경
            for env_key, api_config_getter in self.API_MAPPINGS.items():
                patterns = [
                    # dotenv.env['키'] ?? ''
                    (rf"dotenv\.env\['{env_key}'\]\s*\?\?\s*''", api_config_getter),
                    # dotenv.env['키'] ?? ""
                    (rf'dotenv\.env\["{env_key}"\]\s*\?\?\s*""', api_config_getter),
                    # dotenv.env['키'] ?? StringConstants.emptyString
                    (rf"dotenv\.env\['{env_key}'\]\s*\?\?\s*StringConstants\.emptyString", api_config_getter),
                    # dotenv.env['키']
                    (rf"dotenv\.env\['{env_key}'\]", api_config_getter),
                    # dotenv.env["키"]
                    (rf'dotenv\.env\["{env_key}"\]', api_config_getter),
                ]

                for pattern, replacement in patterns:
                    matches = list(re.finditer(pattern, content))
                    if matches:
                        needs_constants_import = True
                        for match in matches:
                            replacements.append({
                                'line': content[:match.start()].count('\n') + 1,
                                'original': match.group(),
                                'replacement': replacement,
                                'key': env_key,
                            })
                        content = re.sub(pattern, replacement, content)

            # 3. main.dart의 잘못된 패턴 수정
            if file_path.name == 'main.dart':
                wrong_patterns = [
                    (r'dotenv\.env\[ApiConfig\.loginUrl\]\s*\?\?\s*StringConstants\.emptyString', 'ApiConfig.authLogin'),
                    (r'dotenv\.env\[ApiConfig\.userRoleUrl\]\s*\?\?\s*StringConstants\.emptyString', 'ApiConfig.authRole'),
                    (r'dotenv\.env\[ApiConfig\.\w+\]', r'ApiConfig.\1'),
                ]
                
                for pattern, replacement in wrong_patterns:
                    matches = list(re.finditer(pattern, content))
                    if matches:
                        needs_constants_import = True
                        for match in matches:
                            replacements.append({
                                'line': content[:match.start()].count('\n') + 1,
                                'original': match.group(),
                                'replacement': re.sub(pattern, replacement, match.group()) if '\\1' in replacement else replacement,
                                'key': 'main.dart_fix',
                            })
                        content = re.sub(pattern, replacement, content)

            # 4. dotenv 사용이 남아있는지 확인
            remaining_dotenv = re.findall(r'dotenv\.env\[', content)
            if remaining_dotenv:
                can_remove_dotenv_import = False
                self.issues.append({
                    'file': str(file_path.relative_to(self.project_root)),
                    'issue': f'dotenv 사용이 남아있음 ({len(remaining_dotenv)}개)',
                    'examples': remaining_dotenv[:3]
                })

            # 5. import 문 추가/제거
            import_changes = []
            
            # constants import 추가
            if needs_constants_import and not has_constants_import:
                # import 섹션 찾기
                import_section_match = re.search(r'(import\s+[^\n]+;\n)+', content)
                if import_section_match:
                    # 마지막 import 뒤에 추가
                    insert_pos = import_section_match.end()
                    content = content[:insert_pos] + f"\n{self.CONSTANTS_IMPORT}\n" + content[insert_pos:]
                    import_changes.append('added constants import')
                    self.stats['imports_added'] += 1
                else:
                    # import가 없으면 파일 상단에 추가
                    content = f"{self.CONSTANTS_IMPORT}\n\n{content}"
                    import_changes.append('added constants import (at top)')
                    self.stats['imports_added'] += 1

            # dotenv import 제거
            if can_remove_dotenv_import and has_dotenv_import and needs_constants_import:
                # flutter_dotenv import 찾아서 제거
                content = re.sub(self.DOTENV_IMPORT_PATTERN + r'\n?', '', content)
                import_changes.append('removed dotenv import')
                self.stats['imports_removed'] += 1

            # 6. 변경사항이 있으면 저장
            if content != original_content:
                self.stats['files_changed'] += 1
                self.stats['total_replacements'] += len(replacements)
                
                for repl in replacements:
                    key = repl['key']
                    self.stats['by_mapping'][key] = self.stats['by_mapping'].get(key, 0) + 1

                relative_path = file_path.relative_to(self.project_root)
                self.changes.append({
                    'file': str(relative_path),
                    'replacements': replacements,
                    'import_changes': import_changes,
                })

                if self.check_only:
                    print(f"📝 {relative_path}")
                    if import_changes:
                        print(f"   [Import] {', '.join(import_changes)}")
                    for repl in replacements:
                        print(f"   L{repl['line']}: {repl['original']}")
                        print(f"           → {repl['replacement']}")
                    print()
                elif not self.dry_run:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    status = f"✅ {relative_path} ({len(replacements)}개"
                    if import_changes:
                        status += f", import: {len(import_changes)})"
                    else:
                        status += ")"
                    print(status)
                else:
                    print(f"🔍 {relative_path} (변경: {len(replacements)}개, import: {len(import_changes)})")

        except Exception as e:
            print(f"❌ 파일 처리 실패: {file_path}")
            print(f"   오류: {e}")
            self.issues.append({
                'file': str(file_path.relative_to(self.project_root)),
                'issue': f'처리 중 오류: {e}',
                'examples': []
            })

    def _print_summary(self):
        """결과 요약 출력"""
        print("\n" + "=" * 70)
        if self.check_only:
            print("🔍 변경 대상 파일 확인 완료")
        elif self.dry_run:
            print("📊 마이그레이션 미리보기 완료 (DRY RUN)")
        else:
            print("✅ 마이그레이션 완료!")
        print("=" * 70)
        print(f"스캔한 파일:     {self.stats['files_scanned']}개")
        print(f"변경된 파일:     {self.stats['files_changed']}개")
        print(f"총 변경사항:     {self.stats['total_replacements']}개")
        print(f"Import 추가:     {self.stats['imports_added']}개")
        print(f"Import 제거:     {self.stats['imports_removed']}개")
        
        if self.stats['by_mapping']:
            print("\n📋 API 키별 변경 통계:")
            sorted_mappings = sorted(self.stats['by_mapping'].items(), key=lambda x: -x[1])
            for key, count in sorted_mappings[:10]:  # 상위 10개만
                api_config = self.API_MAPPINGS.get(key, key)
                print(f"  • {key}")
                print(f"    → {api_config}: {count}개")
            
            if len(sorted_mappings) > 10:
                print(f"  ... 외 {len(sorted_mappings) - 10}개")
        
        print("=" * 70)
        
        if self.backup_dir and not self.dry_run:
            print(f"\n💾 백업 위치: {self.backup_dir}")
        
        if self.check_only:
            print("\n💡 실제 마이그레이션을 실행하려면:")
            print("   python api_url_migration.py")
        elif self.dry_run:
            print("\n💡 실제 마이그레이션을 실행하려면:")
            print("   python api_url_migration.py")
            print("\n⚠️  백업과 함께 실행하려면:")
            print("   python api_url_migration.py --backup")
        else:
            print("\n✅ 다음 단계:")
            print("1. flutter analyze 실행하여 오류 확인")
            print("2. 앱 빌드 테스트:")
            print("   flutter build apk --debug")
            print("3. 남은 dotenv 사용 확인:")
            print("   grep -r \"dotenv.env\\[\" lib/")
            print("4. 문제 없으면 커밋")

    def _print_changes(self):
        """변경사항 상세 출력"""
        if not self.changes:
            return
            
        print("\n" + "=" * 70)
        print("📝 변경사항 상세")
        print("=" * 70)
        
        for change in self.changes[:20]:  # 처음 20개만
            print(f"\n📄 {change['file']}")
            
            if change.get('import_changes'):
                print(f"   [Import] {', '.join(change['import_changes'])}")
            
            for repl in change['replacements'][:5]:  # 파일당 처음 5개만
                print(f"  L{repl['line']:4d} | {repl['original']}")
                print(f"         → {repl['replacement']}")
            
            if len(change['replacements']) > 5:
                print(f"         ... 외 {len(change['replacements']) - 5}개")
        
        if len(self.changes) > 20:
            print(f"\n... 외 {len(self.changes) - 20}개 파일")
        print()

    def _print_issues(self):
        """이슈 출력"""
        print("\n" + "=" * 70)
        print("⚠️  확인이 필요한 항목")
        print("=" * 70)
        
        for issue in self.issues:
            print(f"\n📄 {issue['file']}")
            print(f"   {issue['issue']}")
            if issue.get('examples'):
                for example in issue['examples']:
                    print(f"   예: {example}")
        print()


def main():
    """메인 함수"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description='API URL 마이그레이션: dotenv.env → ApiConfig (개선 버전)',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
예제:
  python api_url_migration.py                # 실제 마이그레이션 실행
  python api_url_migration.py --dry-run      # 미리보기 (파일 변경 안함)
  python api_url_migration.py --check        # 변경 대상만 확인
  python api_url_migration.py --backup       # 백업 생성하며 실행
  python api_url_migration.py --project-root /path/to/project

개선사항:
  ✓ import 문 자동 추가/제거
  ✓ 백업 파일 생성 옵션
  ✓ main.dart 잘못된 패턴 자동 수정
  ✓ 상세한 이슈 리포트
        """
    )
    
    parser.add_argument('--dry-run', action='store_true',
                       help='실제 변경 없이 미리보기만 실행')
    parser.add_argument('--check', action='store_true',
                       help='변경 대상 파일만 확인 (변경사항 상세 출력)')
    parser.add_argument('--backup', action='store_true',
                       help='백업 폴더 생성 (실제 변경 시에만)')
    parser.add_argument('--project-root', default='.',
                       help='프로젝트 루트 경로 (기본: 현재 디렉토리)')
    
    args = parser.parse_args()
    
    # 프로젝트 루트 확인
    project_root = Path(args.project_root)
    if not project_root.exists():
        print(f"❌ 프로젝트 경로를 찾을 수 없습니다: {project_root}")
        sys.exit(1)
    
    lib_dir = project_root / 'lib'
    if not lib_dir.exists():
        print(f"❌ lib 디렉토리를 찾을 수 없습니다: {lib_dir}")
        print("   올바른 프로젝트 루트 경로를 지정했는지 확인하세요.")
        sys.exit(1)
    
    # 실제 변경 모드일 때 경고
    if not args.dry_run and not args.check:
        print("⚠️  주의: 이 작업은 파일을 직접 수정합니다!")
        if not args.backup:
            print("⚠️  --backup 옵션을 사용하지 않았습니다.")
        print("\n계속하기 전에:")
        print("  • Git으로 커밋하거나")
        print("  • --backup 옵션으로 재실행하세요")
        response = input("\n계속하시겠습니까? (yes/no): ")
        if response.lower() not in ['yes', 'y']:
            print("취소되었습니다.")
            sys.exit(0)
        print()
    
    # 마이그레이션 실행
    migration = ApiUrlMigration(
        project_root=args.project_root,
        dry_run=args.dry_run,
        check_only=args.check,
        create_backup=args.backup
    )
    
    has_changes = migration.run()
    
    sys.exit(0 if has_changes else 1)


if __name__ == '__main__':
    main()
