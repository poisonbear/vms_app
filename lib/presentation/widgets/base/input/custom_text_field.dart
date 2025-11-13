import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/constants.dart';

/// 기본 텍스트 입력 위젯
///
/// [widthsize] : 너비
/// [heightsize] : 높이
/// [controller] : 텍스트 컨트롤러
/// [title] : 힌트 텍스트
/// [color] : 힌트 텍스트 색상
/// [obscureText] : 비밀번호 입력용 마스킹 여부
Widget inputWidget(
  int widthsize,
  int heightsize,
  TextEditingController controller,
  String title,
  Color color, {
  bool obscureText = false,
}) {
  return SizedBox(
    width: widthsize.toDouble(),
    height: heightsize.toDouble(),
    child: TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(
        fontSize: DesignConstants.fontSizeM,
        decorationThickness: 0,
      ),
      decoration: InputDecoration(
        hintText: title,
        hintStyle: TextStyle(color: color),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    ),
  );
}

/// 비활성화된 텍스트 입력 위젯
///
/// [widthsize] : 너비
/// [heightsize] : 높이
/// [controller] : 텍스트 컨트롤러
/// [title] : 힌트 텍스트
/// [color] : 힌트 텍스트 색상
/// [isEnabled] : 활성화 여부
/// [isReadOnly] : 읽기 전용 여부
Widget inputWidget_deactivate(
  int widthsize,
  int heightsize,
  TextEditingController controller,
  String title,
  Color color, {
  bool isEnabled = true,
  bool isReadOnly = false,
}) {
  return SizedBox(
    width: widthsize.toDouble(),
    height: heightsize.toDouble(),
    child: TextField(
      controller: controller,
      style: const TextStyle(
        fontSize: DesignConstants.fontSizeM,
        decorationThickness: 0,
      ),
      enabled: isEnabled,
      readOnly: isReadOnly,
      decoration: InputDecoration(
        hintText: title,
        hintStyle: TextStyle(
          fontSize: DesignConstants.fontSizeM,
          color: color,
        ),
        labelStyle: const TextStyle(fontSize: DesignConstants.fontSizeM),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: color),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
        filled: true,
        fillColor: isEnabled ? Colors.white : Colors.grey.shade100,
      ),
    ),
  );
}

/// 커스텀 텍스트 필드 클래스 - 더 많은 옵션 제공
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const CustomTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    Widget textField = TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      onChanged: onChanged,
      onTap: onTap,
      style: const TextStyle(
        fontSize: DesignConstants.fontSizeM,
        decorationThickness: 0,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.shade100,
      ),
    );

    if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: textField,
      );
    }

    return textField;
  }
}
