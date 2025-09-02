import 'package:flutter_test/flutter_test.dart';
import 'package:vms_app/core/constants/validation_patterns.dart';

void main() {
  group('ValidationPatterns 테스트', () {
    group('아이디 검증', () {
      test('유효한 아이디', () {
        expect(ValidationPatterns.isValidId('test1234'), true);
        expect(ValidationPatterns.isValidId('abcdefgh'), true);
        expect(ValidationPatterns.isValidId('12345678'), true);
        expect(ValidationPatterns.isValidId('Test123456'), true);
      });

      test('무효한 아이디', () {
        expect(ValidationPatterns.isValidId('test'), false); // 너무 짧음
        expect(ValidationPatterns.isValidId('toolongusername'), false); // 너무 긺
        expect(ValidationPatterns.isValidId('test@123'), false); // 특수문자 포함
        expect(ValidationPatterns.isValidId(''), false); // 빈 문자열
        expect(ValidationPatterns.isValidId('test 123'), false); // 공백 포함
      });
    });

    group('MMSI 검증', () {
      test('유효한 MMSI', () {
        expect(ValidationPatterns.isValidMmsi('123456789'), true);
        expect(ValidationPatterns.isValidMmsi('987654321'), true);
      });

      test('무효한 MMSI', () {
        expect(ValidationPatterns.isValidMmsi('12345678'), false); // 8자리
        expect(ValidationPatterns.isValidMmsi('1234567890'), false); // 10자리
        expect(ValidationPatterns.isValidMmsi('12345678a'), false); // 문자 포함
        expect(ValidationPatterns.isValidMmsi(''), false); // 빈 문자열
      });
    });

    group('전화번호 검증', () {
      test('유효한 전화번호 (11자리)', () {
        expect(ValidationPatterns.isValidPhone('01012345678'), true);
        expect(ValidationPatterns.isValidPhone('01987654321'), true);
      });

      test('무효한 전화번호', () {
        expect(ValidationPatterns.isValidPhone('0101234567'), false); // 10자리
        expect(ValidationPatterns.isValidPhone('010123456789'), false); // 12자리
        expect(ValidationPatterns.isValidPhone('010-1234-5678'), false); // 하이픈 포함
      });
    });

    group('비밀번호 검증', () {
      test('유효한 비밀번호', () {
        expect(ValidationPatterns.isValidPassword('Test123!'), true);
        expect(ValidationPatterns.isValidPassword('abc123@#'), true);
        expect(ValidationPatterns.isValidPassword('Hello1234!@'), true);
      });

      test('무효한 비밀번호', () {
        expect(ValidationPatterns.isValidPassword('test'), false); // 너무 짧음
        expect(ValidationPatterns.isValidPassword('testpassword'), false); // 숫자/특수문자 없음
        expect(ValidationPatterns.isValidPassword('12345678'), false); // 문자/특수문자 없음
        expect(ValidationPatterns.isValidPassword('Test1234'), false); // 특수문자 없음
        expect(ValidationPatterns.isValidPassword('Test123456789!'), false); // 너무 김
      });
    });

    group('이메일 검증', () {
      test('유효한 이메일', () {
        expect(ValidationPatterns.isValidEmail('test@example.com'), true);
        expect(ValidationPatterns.isValidEmail('user.name@domain.co.kr'), true);
        expect(ValidationPatterns.isValidEmail('test123@gmail.com'), true);
      });

      test('무효한 이메일', () {
        expect(ValidationPatterns.isValidEmail('test'), false);
        expect(ValidationPatterns.isValidEmail('test@'), false);
        expect(ValidationPatterns.isValidEmail('@example.com'), false);
        expect(ValidationPatterns.isValidEmail('test@example'), false);
      });
    });

    group('비밀번호 구성 요소 검증', () {
      test('영문자 포함 검증', () {
        expect(ValidationPatterns.hasLetter('test123!'), true);
        expect(ValidationPatterns.hasLetter('123456!'), false);
      });

      test('숫자 포함 검증', () {
        expect(ValidationPatterns.hasNumber('test123!'), true);
        expect(ValidationPatterns.hasNumber('testonly!'), false);
      });

      test('특수문자 포함 검증', () {
        expect(ValidationPatterns.hasSpecialChar('test123!'), true);
        expect(ValidationPatterns.hasSpecialChar('test123'), false);
      });
    });

    group('상세 검증 결과', () {
      test('비밀번호 상세 검증', () {
        final result = ValidationPatterns.validatePasswordDetails('Test123!');
        expect(result['hasValidLength'], true);
        expect(result['hasLetter'], true);
        expect(result['hasNumber'], true);
        expect(result['hasSpecialChar'], true);
        expect(result['isValid'], true);

        final invalidResult = ValidationPatterns.validatePasswordDetails('test');
        expect(invalidResult['hasValidLength'], false);
        expect(invalidResult['isValid'], false);
      });
    });
  });

  group('ValidationHelper 테스트', () {
    test('빈 문자열 처리', () {
      expect(ValidationHelper.validateIfNotEmpty('', ValidationPatterns.isValidId), true);
      expect(ValidationHelper.validateIfNotEmpty('test1234', ValidationPatterns.isValidId), true);
      expect(ValidationHelper.validateIfNotEmpty('test', ValidationPatterns.isValidId), false);
    });

    test('아이디 상세 검증', () {
      final result = ValidationHelper.validateIdDetailed('test1234');
      expect(result['hasValidLength'], true);
      expect(result['hasOnlyAlphanumeric'], true);
      expect(result['isValid'], true);
    });
  });
}
