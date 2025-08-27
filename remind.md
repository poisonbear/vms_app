# VMS App 프로젝트 구조 분석

## 📁 프로젝트 개요
Flutter 기반 선박 관리 시스템(VMS - Vessel Management System) 모바일 애플리케이션
- **아키텍처**: Clean Architecture
- **상태관리**: Provider 패턴
- **의존성 주입**: GetIt

---

## 📁 /lib 폴더 구조

### 🔷 /lib/core - 핵심 공통 기능
앱 전체에서 사용되는 핵심 기능과 유틸리티

#### /core/constants
- `api_endpoints.dart` - API 엔드포인트 중앙 관리
- `app_colors.dart` - 색상 상수
- `app_sizes.dart` - 크기 상수
- `app_messages.dart` - 메시지 상수 (에러, 성공, 검증 메시지)
- `env_keys.dart` - 환경 변수 키 상수 관리 (.env 파일 키 값)

#### /core/di
- `injection.dart` - GetIt을 사용한 의존성 주입 설정
    - DataSource, Repository, UseCase 등록
    - 싱글톤 패턴 적용

#### /core/errors
- `app_exceptions.dart` - 커스텀 예외 클래스 정의
- `result.dart` - Result 패턴 구현 (Success/Failure)
- `error_handler.dart` - 에러 처리 유틸리티

#### /core/network
- `dio_client.dart` - HTTP 통신 설정 (Dio 래퍼)
    - 인터셉터 설정
    - 타임아웃 설정
    - 에러 핸들링

#### /core/utils
- `logger.dart` - 로깅 유틸리티
- `permission_manager.dart` - 권한 관리 (위치, 알림, 카메라 등)
- `error_handler.dart` - DioException → AppException 변환

---

### 🔷 /lib/domain - 비즈니스 로직 레이어
순수 비즈니스 로직, 외부 의존성 없음

#### /domain/entities
- `vessel_entity.dart` - 선박 엔티티 (비즈니스 객체)

#### /domain/repositories
인터페이스만 정의 (구현은 data 레이어에서)
- `navigation_repository.dart` - 항행 이력 리포지토리 인터페이스
- `route_search_repository.dart` - 항로 검색 리포지토리 인터페이스
- `terms_repository.dart` - 약관 리포지토리 인터페이스
- `vessel_repository.dart` - 선박 정보 리포지토리 인터페이스
- `weather_repository.dart` - 기상 정보 리포지토리 인터페이스

#### /domain/usecases
비즈니스 로직 구현
- `/auth/get_terms_list.dart` - 약관 목록 조회
- `/navigation/get_navigation_history.dart` - 항행 이력 조회
- `/navigation/get_weather_info.dart` - 날씨 정보 조회
- `/vessel/search_vessel.dart` - 선박 검색

---

### 🔷 /lib/data - 데이터 레이어
API 통신, 모델 정의, 리포지토리 구현

#### /data/datasources/remote
외부 API와 통신하는 데이터 소스
- `navigation_remote_datasource.dart` (RosSource) - 항행 이력 API
- `route_search_remote_datasource.dart` (RouteSearchSource) - 항로 검색 API
- `terms_remote_datasource.dart` (CmdSource) - 약관 API
- `vessel_remote_datasource.dart` (VesselSearchSource) - 선박 검색 API
- `weather_remote_datasource.dart` (WidSource) - 기상 정보 API

#### /data/models
JSON 파싱을 위한 데이터 모델
- `/navigation/`
    - `navigation_model.dart` (RosModel) - 항행 이력 모델
    - `route_search_model.dart` - 항로 검색 모델
    - `vessel_route_model.dart` - 선박 항로 응답 모델
- `/terms/terms_model.dart` (CmdModel) - 약관 모델
- `/vessel/vessel_search_model.dart` - 선박 검색 모델
- `/weather/weather_model.dart` (WidModel) - 기상 정보 모델

#### /data/repositories
리포지토리 인터페이스 구현체
- `navigation_repository_impl.dart` - NavigationRepository 구현
- `navigation_repository_with_result.dart` - Result 패턴 적용 버전
- `route_search_repository_impl.dart` - 항로 검색 리포지토리
- `terms_repository_impl.dart` - TermsRepository 구현
- `vessel_repository_impl.dart` - VesselRepository 구현
- `weather_repository_impl.dart` - WeatherRepository 구현

---

### 🔷 /lib/presentation - UI 레이어
화면, 상태관리, 위젯

#### /presentation/screens

##### /auth - 인증 관련 화면
- `login_screen.dart` - 로그인 화면
- `register_screen.dart` - 회원가입 화면
- `register_complete_screen.dart` - 회원가입 완료 화면
- `terms_agreement_screen.dart` - 약관 동의 화면
- `find_account_screen.dart` - 아이디/비밀번호 찾기 화면
- `/terms/` - 약관 상세 화면들
    - `location_terms_screen.dart` - 위치기반 서비스 약관
    - `marketing_terms_screen.dart` - 마케팅 동의
    - `privacy_policy_screen.dart` - 개인정보 처리방침
    - `service_terms_screen.dart` - 서비스 이용약관

##### /main - 메인 화면
- `main_screen.dart` - 메인 화면 (지도, 선박 표시)
- `/tabs/` - 탭 화면들
    - `navigation_tab.dart` - 항행이력 탭
    - `navigation_calendar.dart` - 항행이력 달력
    - `weather_tab.dart` - 기상정보 탭
    - `weather_calendar.dart` - 기상정보 달력

##### /profile - 프로필 관련
- `profile_screen.dart` - 마이페이지
- `edit_profile_screen.dart` - 프로필 수정

#### /presentation/providers
Provider 패턴을 사용한 상태 관리
- `auth_provider.dart` (UserState) - 인증 상태 관리
- `navigation_provider.dart` - 항행 데이터 상태 관리
- `route_search_provider.dart` - 항로 검색 상태 관리
- `vessel_provider.dart` - 선박 정보 상태 관리
- `weather_provider.dart` - 기상 정보 상태 관리
- `/terms/` - 약관 관련
    - `location_terms_provider.dart`
    - `marketing_terms_provider.dart`
    - `privacy_policy_provider.dart`
    - `service_terms_provider.dart`

#### /presentation/widgets/common
공통 위젯
- `common_widgets.dart` - 공통 UI 컴포넌트
    - svgload() - SVG 파일 로더
    - TextWidgetString() - 텍스트 위젯
    - inputWidget() - 입력 필드
- `custom_app_bar.dart` (AppBarLayerView) - 커스텀 앱바

---

## 📁 /assets 폴더 구조

### /assets/kdn
KDN 프로젝트 리소스
- `/font/woff2/` - PretendardVariable.woff2 폰트
- `/usm/img/` - 회원 관련 이미지 (arrow-left.svg, close.svg 등)
- `/ros/img/` - 항행이력 관련 이미지
- `/home/img/` - 홈 화면 이미지
- `/wid/img/` - 기상 관련 이미지

### /assets/js
- `ajv.js` - JavaScript 파일

---

## 🔑 주요 API 엔드포인트 (.env)

### 회원 관련 (usm)
- `kdn_usm_select_cmd_key` - 이용약관 조회
- `kdn_usm_insert_membership_key` - 회원가입
- `kdn_usm_update_membership_key` - 회원정보 수정
- `kdn_loginForm_key` - 로그인

### 항행 이력 (ros)
- `kdn_ros_select_navigation_Info` - 항행이력 조회
- `kdn_ros_select_visibility_Info` - 파고/시정 정보
- `kdn_ros_select_navigation_warn_Info` - 항행경보

### 선박 정보 (gis)
- `kdn_gis_select_vessel_List` - 선박 목록
- `kdn_gis_select_vessel_Route` - 선박 항로

### 기상 정보 (wid)
- `kdn_wid_select_weather_Info` - 기상정보 (예측 포함)

### GeoServer
- `GEOSERVER_URL` - WMS 서비스

---

## 🔧 주요 기술 스택

### 상태 관리
- **Provider**: 상태 관리 패턴
- **ChangeNotifier**: 상태 변경 알림

### 네트워크
- **Dio**: HTTP 클라이언트
- **flutter_dotenv**: 환경변수 관리

### 의존성 주입
- **GetIt**: 서비스 로케이터 패턴

### 인증 & 백엔드
- **Firebase Auth**: 사용자 인증
- **Firebase Messaging**: 푸시 알림
- **Firestore**: 클라우드 데이터베이스

### UI & 지도
- **flutter_map**: 지도 표시
- **latlong2**: 좌표 처리
- **flutter_svg**: SVG 이미지

### 기타
- **shared_preferences**: 로컬 저장소
- **permission_handler**: 권한 관리
- **geolocator**: 위치 서비스
- **intl**: 국제화/날짜 포맷

---

## 📱 주요 기능

1. **인증 시스템**
    - 로그인/로그아웃
    - 회원가입 (약관 동의 포함)
    - 자동 로그인
    - 회원정보 수정

2. **항행 관리**
    - 항행 이력 조회 (날짜별)
    - 과거 항적 표시
    - 예측 항로 표시
    - 퇴각 항로 표시

3. **선박 모니터링**
    - 실시간 선박 위치
    - 선박 검색 (MMSI, 선박명)
    - 선박 상세 정보
    - 권한별 조회 (ROLE_USER: 자기 선박만, 관리자: 모든 선박)

4. **기상 정보**
    - 실시간 기상 데이터
    - 파고/시정 정보
    - 풍향/풍속
    - 항행 경보

5. **지도 기능**
    - Flutter Map 기반
    - WMS 레이어 (해도, 터빈 위치 등)
    - 선박 마커 표시
    - 항로 표시 (Polyline)

---

## 🏗️ 아키텍처 특징

### Clean Architecture 적용
- **계층 분리**: Presentation → Domain → Data
- **의존성 역전**: 내부 레이어는 외부 레이어를 모름
- **테스트 용이성**: 각 레이어 독립적 테스트 가능

### Repository 패턴
- 데이터 소스 추상화
- 인터페이스와 구현체 분리
- Result 패턴 적용 (성공/실패 명시적 처리)

### 에러 처리
- 커스텀 Exception 클래스
- 중앙화된 에러 핸들링
- 사용자 친화적 메시지 변환

---

## 📝 네이밍 컨벤션

### 기존 네이밍 (레거시)
- Cmd* - 약관 관련
- Ros* - 항행 이력 관련
- Wid* - 기상 정보 관련

### 새 네이밍 (Clean Architecture)
- *Entity - 도메인 엔티티
- *Repository - 리포지토리
- *Provider - 상태 관리
- *Screen - 화면
- *Widget - 위젯

---

## 🔄 마이그레이션 이력

기존 구조(kdn 폴더 기반)에서 Clean Architecture로 완전 마이그레이션 완료:
- `kdn/cmm` → `core/`
- `kdn/usm/view` → `presentation/screens/auth/`
- `kdn/usm/viewModel` → `presentation/providers/`
- `kdn/ros/view` → `presentation/screens/main/`

---

## 📌 빌드 & 배포

### APK 빌드
```bash
flutter build apk --release --obfuscate --split-debug-info=/<debug-symbols-directory>
```

### JDK 설정
```bash
flutter config --jdk-dir="C:\Program Files\Java\jdk-11"
```