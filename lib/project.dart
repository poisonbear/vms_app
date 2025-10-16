// lib/core/project.dart

/// 프로젝트 전체에서 공통으로 사용하는 라이브러리 모음
/// Flutter 기본, Core 모듈, 외부 패키지 등을 통합하여 제공합니다.
library;

// ============================================
// Flutter 기본
// ============================================
export 'package:flutter/material.dart';
export 'package:flutter/services.dart';
export 'dart:async';
export 'dart:io';

// ============================================
// Core 모듈
// ============================================

// Utils (통합)
export 'package:vms_app/core/utils/utils.dart';

// 상수
export 'package:vms_app/core/constants/constants.dart';

// 예외 처리
export 'package:vms_app/core/exceptions/app_exceptions.dart';
export 'package:vms_app/core/exceptions/error_handler.dart';
export 'package:vms_app/core/exceptions/result.dart';

// ============================================
// Firebase
// ============================================
export 'package:firebase_auth/firebase_auth.dart';
export 'package:firebase_messaging/firebase_messaging.dart';
export 'package:cloud_firestore/cloud_firestore.dart';

// ============================================
// 상태 관리
// ============================================
export 'package:provider/provider.dart';

// ============================================
// 권한 관리
// ============================================
// ServiceStatus 충돌 해결: Geolocator와 permission_handler 모두 ServiceStatus를 정의
// permission_handler의 ServiceStatus를 숨기고 Geolocator의 것만 사용
export 'package:geolocator/geolocator.dart';
export 'package:permission_handler/permission_handler.dart' hide ServiceStatus;

// ============================================
// UI 유틸리티
// ============================================
export 'package:flutter_svg/flutter_svg.dart';
