import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vms_app/core/constants/constants.dart';

class TurbineSplashWidget extends StatefulWidget {
  const TurbineSplashWidget({super.key});

  @override
  State<TurbineSplashWidget> createState() => _TurbineSplashWidgetState();
}

class _TurbineSplashWidgetState extends State<TurbineSplashWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 터빈 애니메이션 컨테이너
              SizedBox(
                width: 300,
                height: 400,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 터빈 기둥 (고정)
                    Positioned(
                      bottom: 0,
                      child: SvgPicture.asset(
                        'assets/kdn/home/img/turbine_pole.svg',
                        width: 150,
                        height: 300,
                        fit: BoxFit.contain,
                      ),
                    ),
                    // 터빈 날개 (회전)
                    Positioned(
                      top: 20,
                      child: AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationController.value * 2 * math.pi,
                            child: SvgPicture.asset(
                              'assets/kdn/home/img/turbine_blade.svg',
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // 앱 이름
              const Text(
                'K-VMS',
                style: TextStyle(
                  color: AppColors.whiteType1,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // 로딩 인디케이터
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.whiteType1,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // 로딩 텍스트
              Text(
                '로딩 중...',
                style: TextStyle(
                  color: AppColors.whiteType1.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
