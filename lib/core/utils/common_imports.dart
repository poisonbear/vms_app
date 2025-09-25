library;

// Flutter 기본
export 'package:flutter/material.dart';
export 'package:flutter/services.dart';
export 'dart:async';
export 'dart:io';

// 프로젝트 핵심 유틸리티
export 'package:vms_app/core/utils/app_logger.dart';
export 'package:vms_app/core/utils/validators.dart';
export 'package:vms_app/core/utils/formatters.dart';
export 'package:vms_app/core/utils/extensions.dart';
export 'package:vms_app/core/utils/helpers.dart';
export 'package:vms_app/core/constants/constants.dart';
export 'package:vms_app/core/exceptions/app_exceptions.dart';  // ✅ 수정됨
export 'package:vms_app/core/exceptions/error_handler.dart';   // ✅ 수정됨
export 'package:vms_app/core/exceptions/result.dart';          // ✅ 수정됨

// Firebase
export 'package:firebase_auth/firebase_auth.dart';
export 'package:firebase_messaging/firebase_messaging.dart';
export 'package:cloud_firestore/cloud_firestore.dart';

// 상태 관리
export 'package:provider/provider.dart';

// 권한 관리 - ServiceStatus 충돌 해결
export 'package:geolocator/geolocator.dart';
export 'package:permission_handler/permission_handler.dart' hide ServiceStatus;

// UI 유틸리티
export 'package:flutter_svg/flutter_svg.dart';
