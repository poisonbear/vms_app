/// 앱 전체에서 사용하는 사이즈 상수 및 유틸리티
///
/// 사용 예시:
/// - double 필요 시: AppSizes.size16 또는 AppSizes.s16
/// - int 필요 시: AppSizes.size16.toInt() 또는 AppSizes.i16
/// - 함수 호출 방식(레거시): getSize16() 또는 getSizeInt16()
class AppSizes {
  AppSizes._();

  // ============================================
  // 1. 기본 double 상수 (권장)
  // ============================================
  static const double size0 = 0.0;
  static const double size1 = 1.0;
  static const double size2 = 2.0;
  static const double size3 = 3.0;
  static const double size4 = 4.0;
  static const double size5 = 5.0;
  static const double size6 = 6.0;
  static const double size7 = 7.0;
  static const double size8 = 8.0;
  static const double size9 = 9.0;
  static const double size10 = 10.0;
  static const double size11 = 11.0;
  static const double size12 = 12.0;
  static const double size13 = 13.0;
  static const double size14 = 14.0;
  static const double size15 = 15.0;
  static const double size16 = 16.0;
  static const double size18 = 18.0;
  static const double size20 = 20.0;
  static const double size21 = 21.0;
  static const double size24 = 24.0;
  static const double size25 = 25.0;
  static const double size26 = 26.0;
  static const double size28 = 28.0;
  static const double size29 = 29.0;
  static const double size30 = 30.0;
  static const double size32 = 32.0;
  static const double size34 = 34.0;
  static const double size35 = 35.0;
  static const double size36 = 36.0;
  static const double size37 = 37.0;
  static const double size40 = 40.0;
  static const double size41 = 41.0;
  static const double size44 = 44.0;
  static const double size45 = 45.0;
  static const double size48 = 48.0;
  static const double size50 = 50.0;
  static const double size52 = 52.0;
  static const double size54 = 54.0;
  static const double size56 = 56.0;
  static const double size60 = 60.0;
  static const double size65 = 65.0;
  static const double size70 = 70.0;
  static const double size80 = 80.0;
  static const double size92 = 92.0;
  static const double size96 = 96.0;
  static const double size100 = 100.0;
  static const double size120 = 120.0;
  static const double size133 = 133.0;
  static const double size134 = 134.0;
  static const double size150 = 150.0;
  static const double size160 = 160.0;
  static const double size170 = 170.0;
  static const double size180 = 180.0;
  static const double size206 = 206.0;
  static const double size266 = 266.0;
  static const double size300 = 300.0;
  static const double size312 = 312.0;
  static const double size330 = 330.0;
  static const double size350 = 350.0;
  static const double size400 = 400.0;
  static const double size520 = 520.0;
  static const double size550 = 550.0;
  static const double size580 = 580.0;

  // 소수점 사이즈
  static const double size1_333 = 1.333;

  // ============================================
  // 2. int 상수 (int가 필요한 경우 직접 사용)
  // ============================================
  static const int i0 = 0;
  static const int i1 = 1;
  static const int i2 = 2;
  static const int i3 = 3;
  static const int i4 = 4;
  static const int i5 = 5;
  static const int i6 = 6;
  static const int i7 = 7;
  static const int i8 = 8;
  static const int i9 = 9;
  static const int i10 = 10;
  static const int i11 = 11;
  static const int i12 = 12;
  static const int i13 = 13;
  static const int i14 = 14;
  static const int i15 = 15;
  static const int i16 = 16;
  static const int i18 = 18;
  static const int i20 = 20;
  static const int i21 = 21;
  static const int i24 = 24;
  static const int i25 = 25;
  static const int i26 = 26;
  static const int i28 = 28;
  static const int i29 = 29;
  static const int i30 = 30;
  static const int i32 = 32;
  static const int i34 = 34;
  static const int i35 = 35;
  static const int i36 = 36;
  static const int i37 = 37;
  static const int i40 = 40;
  static const int i41 = 41;
  static const int i44 = 44;
  static const int i45 = 45;
  static const int i48 = 48;
  static const int i50 = 50;
  static const int i52 = 52;
  static const int i54 = 54;
  static const int i56 = 56;
  static const int i60 = 60;
  static const int i65 = 65;
  static const int i70 = 70;
  static const int i80 = 80;
  static const int i92 = 92;
  static const int i96 = 96;
  static const int i100 = 100;
  static const int i120 = 120;
  static const int i133 = 133;
  static const int i134 = 134;
  static const int i150 = 150;
  static const int i160 = 160;
  static const int i170 = 170;
  static const int i180 = 180;
  static const int i206 = 206;
  static const int i266 = 266;
  static const int i300 = 300;
  static const int i312 = 312;
  static const int i330 = 330;
  static const int i350 = 350;
  static const int i400 = 400;
  static const int i520 = 520;
  static const int i550 = 550;
  static const int i580 = 580;
}

// ============================================
// 4. 레거시 함수 (하위 호환성 유지)
// ============================================
// 기존 코드와의 호환성을 위해 유지
// 점진적으로 AppSizes.size16 형태로 마이그레이션 권장

// double 반환 (기본 - Flutter 위젯용)
double getSize0() => AppSizes.size0;
double getSize1() => AppSizes.size1;
double getSize2() => AppSizes.size2;
double getSize3() => AppSizes.size3;
double getSize4() => AppSizes.size4;
double getSize5() => AppSizes.size5;
double getSize6() => AppSizes.size6;
double getSize7() => AppSizes.size7;
double getSize8() => AppSizes.size8;
double getSize9() => AppSizes.size9;
double getSize10() => AppSizes.size10;
double getSize11() => AppSizes.size11;
double getSize12() => AppSizes.size12;
double getSize13() => AppSizes.size13;
double getSize14() => AppSizes.size14;
double getSize15() => AppSizes.size15;
double getSize16() => AppSizes.size16;
double getSize18() => AppSizes.size18;
double getSize20() => AppSizes.size20;
double getSize21() => AppSizes.size21;
double getSize24() => AppSizes.size24;
double getSize25() => AppSizes.size25;
double getSize26() => AppSizes.size26;
double getSize28() => AppSizes.size28;
double getSize29() => AppSizes.size29;
double getSize30() => AppSizes.size30;
double getSize32() => AppSizes.size32;
double getSize34() => AppSizes.size34;
double getSize35() => AppSizes.size35;
double getSize36() => AppSizes.size36;
double getSize37() => AppSizes.size37;
double getSize40() => AppSizes.size40;
double getSize41() => AppSizes.size41;
double getSize44() => AppSizes.size44;
double getSize45() => AppSizes.size45;
double getSize48() => AppSizes.size48;
double getSize50() => AppSizes.size50;
double getSize52() => AppSizes.size52;
double getSize54() => AppSizes.size54;
double getSize56() => AppSizes.size56;
double getSize60() => AppSizes.size60;
double getSize65() => AppSizes.size65;
double getSize70() => AppSizes.size70;
double getSize80() => AppSizes.size80;
double getSize92() => AppSizes.size92;
double getSize96() => AppSizes.size96;
double getSize100() => AppSizes.size100;
double getSize120() => AppSizes.size120;
double getSize133() => AppSizes.size133;
double getSize134() => AppSizes.size134;
double getSize150() => AppSizes.size150;
double getSize160() => AppSizes.size160;
double getSize170() => AppSizes.size170;
double getSize180() => AppSizes.size180;
double getSize206() => AppSizes.size206;
double getSize266() => AppSizes.size266;
double getSize300() => AppSizes.size300;
double getSize312() => AppSizes.size312;
double getSize330() => AppSizes.size330;
double getSize350() => AppSizes.size350;
double getSize400() => AppSizes.size400;
double getSize520() => AppSizes.size520;
double getSize550() => AppSizes.size550;
double getSize580() => AppSizes.size580;
double getSize1_333() => AppSizes.size1_333;

// int 반환 (특별히 int가 필요한 경우)
int getSizeInt0() => AppSizes.i0;
int getSizeInt1() => AppSizes.i1;
int getSizeInt2() => AppSizes.i2;
int getSizeInt3() => AppSizes.i3;
int getSizeInt4() => AppSizes.i4;
int getSizeInt5() => AppSizes.i5;
int getSizeInt6() => AppSizes.i6;
int getSizeInt7() => AppSizes.i7;
int getSizeInt8() => AppSizes.i8;
int getSizeInt9() => AppSizes.i9;
int getSizeInt10() => AppSizes.i10;
int getSizeInt11() => AppSizes.i11;
int getSizeInt12() => AppSizes.i12;
int getSizeInt13() => AppSizes.i13;
int getSizeInt14() => AppSizes.i14;
int getSizeInt15() => AppSizes.i15;
int getSizeInt16() => AppSizes.i16;
int getSizeInt18() => AppSizes.i18;
int getSizeInt20() => AppSizes.i20;
int getSizeInt21() => AppSizes.i21;
int getSizeInt24() => AppSizes.i24;
int getSizeInt25() => AppSizes.i25;
int getSizeInt26() => AppSizes.i26;
int getSizeInt28() => AppSizes.i28;
int getSizeInt29() => AppSizes.i29;
int getSizeInt30() => AppSizes.i30;
int getSizeInt32() => AppSizes.i32;
int getSizeInt34() => AppSizes.i34;
int getSizeInt35() => AppSizes.i35;
int getSizeInt36() => AppSizes.i36;
int getSizeInt37() => AppSizes.i37;
int getSizeInt40() => AppSizes.i40;
int getSizeInt41() => AppSizes.i41;
int getSizeInt44() => AppSizes.i44;
int getSizeInt45() => AppSizes.i45;
int getSizeInt48() => AppSizes.i48;
int getSizeInt50() => AppSizes.i50;
int getSizeInt52() => AppSizes.i52;
int getSizeInt54() => AppSizes.i54;
int getSizeInt56() => AppSizes.i56;
int getSizeInt60() => AppSizes.i60;
int getSizeInt65() => AppSizes.i65;
int getSizeInt70() => AppSizes.i70;
int getSizeInt80() => AppSizes.i80;
int getSizeInt92() => AppSizes.i92;
int getSizeInt96() => AppSizes.i96;
int getSizeInt100() => AppSizes.i100;
int getSizeInt120() => AppSizes.i120;
int getSizeInt133() => AppSizes.i133;
int getSizeInt134() => AppSizes.i134;
int getSizeInt150() => AppSizes.i150;
int getSizeInt160() => AppSizes.i160;
int getSizeInt170() => AppSizes.i170;
int getSizeInt180() => AppSizes.i180;
int getSizeInt206() => AppSizes.i206;
int getSizeInt266() => AppSizes.i266;
int getSizeInt300() => AppSizes.i300;
int getSizeInt312() => AppSizes.i312;
int getSizeInt330() => AppSizes.i330;
int getSizeInt350() => AppSizes.i350;
int getSizeInt400() => AppSizes.i400;
int getSizeInt520() => AppSizes.i520;
int getSizeInt550() => AppSizes.i550;
int getSizeInt580() => AppSizes.i580;
