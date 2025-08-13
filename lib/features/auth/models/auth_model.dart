import 'package:equatable/equatable.dart';

/// 사용자 모델
class UserModel extends Equatable {
  const UserModel({
    required this.username,
    required this.role,
    this.mmsi,
    this.uuid,
    this.email,
    this.phone,
  });

  final String username;
  final String role;
  final int? mmsi;
  final String? uuid;
  final String? email;
  final String? phone;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] ?? '',
      role: json['role'] ?? '',
      mmsi: json['mmsi'],
      uuid: json['uuid'],
      email: json['email'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() => {
    'username': username,
    'role': role,
    'mmsi': mmsi,
    'uuid': uuid,
    'email': email,
    'phone': phone,
  };

  UserModel copyWith({
    String? username,
    String? role,
    int? mmsi,
    String? uuid,
    String? email,
    String? phone,
  }) {
    return UserModel(
      username: username ?? this.username,
      role: role ?? this.role,
      mmsi: mmsi ?? this.mmsi,
      uuid: uuid ?? this.uuid,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }

  @override
  List<Object?> get props => [username, role, mmsi, uuid, email, phone];
}

/// 로그인 요청 모델
class LoginRequest extends Equatable {
  const LoginRequest({
    required this.userId,
    required this.password,
    this.autoLogin = false,
    this.fcmToken,
    this.uuid,
  });

  final String userId;
  final String password;
  final bool autoLogin;
  final String? fcmToken;
  final String? uuid;

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'user_pwd': password,
    'auto_login': autoLogin,
    'fcm_tkn': fcmToken,
    'uuid': uuid,
  };

  @override
  List<Object?> get props => [userId, password, autoLogin, fcmToken, uuid];
}

/// 회원가입 요청 모델
class RegisterRequest extends Equatable {
  const RegisterRequest({
    required this.userId,
    required this.password,
    required this.mmsi,
    required this.phone,
    required this.choiceTime,
    required this.firebaseUuid,
    this.email,
  });

  final String userId;
  final String password;
  final String mmsi;
  final String phone;
  final String choiceTime;
  final String firebaseUuid;
  final String? email;

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'user_pwd': password,
    'mmsi': mmsi,
    'mphn_no': phone,
    'choice_time': choiceTime,
    'firebase_uuid': firebaseUuid,
    'email_addr': email ?? '',
  };

  @override
  List<Object?> get props => [
    userId,
    password,
    mmsi,
    phone,
    choiceTime,
    firebaseUuid,
    email,
  ];
}

/// 이용약관 모델
class TermsModel extends Equatable {
  const TermsModel({
    this.termsDt,
    this.termsNm,
    this.id,
    this.termsCtt,
  });

  final int? termsDt;
  final String? termsNm;
  final int? id;
  final String? termsCtt;

  factory TermsModel.fromJson(Map<String, dynamic> json) {
    return TermsModel(
      termsDt: json['terms_dt'],
      termsNm: json['terms_nm'],
      id: json['id'],
      termsCtt: json['terms_ctt'],
    );
  }

  Map<String, dynamic> toJson() => {
    'terms_dt': termsDt,
    'terms_nm': termsNm,
    'id': id,
    'terms_ctt': termsCtt,
  };

  @override
  List<Object?> get props => [termsDt, termsNm, id, termsCtt];
}