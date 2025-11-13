/// 약관 정보 모델
class TermsModel {
  final int? id;
  final String? terms_nm;
  final int? terms_dt;
  final String? terms_ctt;

  // 추가 필드 (호환성)
  final String? code;
  final String? name;
  final String? content;
  final bool? required;
  final int? displayOrder;

  TermsModel({
    this.id,
    this.terms_nm,
    this.terms_dt,
    this.terms_ctt,
    this.code,
    this.name,
    this.content,
    this.required,
    this.displayOrder,
  });

  factory TermsModel.fromJson(Map<String, dynamic> json) {
    return TermsModel(
      // 실제 API 필드명
      id: json['id'],
      terms_nm: json['terms_nm'],
      terms_dt: json['terms_dt'],
      terms_ctt: json['terms_ctt'],

      // 대체 필드명 (하위 호환)
      code: json['code'],
      name: json['name'],
      content: json['content'],
      required: json['required'],
      displayOrder: json['display_order'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'terms_nm': terms_nm,
      'terms_dt': terms_dt,
      'terms_ctt': terms_ctt,
      'code': code,
      'name': name,
      'content': content,
      'required': required,
      'display_order': displayOrder,
    };
  }
}

// ===== 하위 호환성을 위한 Type Alias =====
typedef CmdModel = TermsModel;
