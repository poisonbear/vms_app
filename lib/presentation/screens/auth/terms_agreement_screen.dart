// 기존 CmdChoiceView를 새 통합 버전으로 교체
export 'package:vms_app/presentation/screens/auth/terms_agreement_screen_refactored.dart';

// 하위 호환성을 위해 기존 클래스명 유지
import 'package:vms_app/presentation/screens/auth/terms_agreement_screen_refactored.dart';

typedef CmdChoiceView = CmdChoiceViewRefactored;
