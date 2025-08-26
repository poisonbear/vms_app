# Presentation Layer
프레젠테이션 레이어 - UI, 상태관리

## 마이그레이션 매핑
### Screens (Views)
- `LoginView.dart` → `screens/auth/login_screen.dart`
- `Membership.dart` → `screens/auth/register_screen.dart`
- `mainView.dart` → `screens/main/main_screen.dart`
- `MemberInformationView.dart` → `screens/profile/profile_screen.dart`

### ViewModels → Providers
- `NavigationViewModel.dart` → `providers/navigation_provider.dart`
- `VesselSearchViewModel.dart` → `providers/vessel_provider.dart`
- `UserState.dart` → `providers/auth_provider.dart`

### Widgets
- `common_widget.dart` → `widgets/common/`에 분리
