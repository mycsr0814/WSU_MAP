// lib/services/auth_service.dart - 서버 API와 연동되는 인증 서비스

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:http/http.dart' as http;

/// 인증 관련 서비스 클래스
class AuthService {
  static final String baseUrl = ApiConfig.userBase;

  /// 회원가입 API 호출
  static Future<AuthResult> register({
    required String id,
    required String pw,
    required String name,
    required String phone,
    String? stuNumber,
    String? email,
  }) async {
    try {
      debugPrint('=== 회원가입 API 요청 ===');
      debugPrint('URL: $baseUrl/register');

      final requestBody = {
        'id': id,
        'pw': pw,
        'name': name,
        'stu_number': stuNumber,
        'phone': phone,
        'email': email,
      };

      debugPrint('요청 데이터: $requestBody');

      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('=== 회원가입 API 응답 ===');
      debugPrint('상태코드: ${response.statusCode}');
      debugPrint('응답 내용: ${response.body}');

      switch (response.statusCode) {
        case 201:
          // 성공
          final data = jsonDecode(response.body);
          return AuthResult.success(
            message: data['message'] ?? '회원가입이 완료되었습니다.',
          );
        case 400:
          return AuthResult.failure('모든 필수 항목을 입력해주세요.');
        case 409:
          return AuthResult.failure('이미 존재하는 아이디입니다.');
        case 500:
          return AuthResult.failure('회원가입 처리 중 서버 오류가 발생했습니다.');
        default:
          return AuthResult.failure(
            '알 수 없는 오류가 발생했습니다. (${response.statusCode})',
          );
      }
    } catch (e) {
      debugPrint('회원가입 네트워크 오류: $e');
      if (e.toString().contains('timeout') ||
          e.toString().contains('TimeoutException')) {
        return AuthResult.failure('서버 응답 시간이 초과되었습니다. 네트워크 연결을 확인해주세요.');
      }
      return AuthResult.failure('네트워크 연결에 실패했습니다. 인터넷 연결을 확인해주세요.');
    }
  }

  /// 로그인 API 호출
  static Future<LoginResult> login({
    required String id,
    required String pw,
  }) async {
    try {
      debugPrint('=== 로그인 API 요청 ===');
      debugPrint('URL: $baseUrl/login');
      debugPrint('아이디: $id');

      final requestBody = {'id': id, 'pw': pw};

      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('=== 로그인 API 응답 ===');
      debugPrint('상태코드: ${response.statusCode}');
      debugPrint('응답 내용: ${response.body}');

      switch (response.statusCode) {
        case 200:
          // 성공
          final data = jsonDecode(response.body);
          return LoginResult.success(
            userId: data['id'],
            userName: data['name'],
            isLogin: data['islogin'] ?? true,
          );
        case 400:
          return LoginResult.failure('아이디와 비밀번호를 입력하세요.');
        case 401:
          return LoginResult.failure('아이디 또는 비밀번호가 일치하지 않습니다.');
        case 500:
          return LoginResult.failure('로그인 처리 중 서버 오류가 발생했습니다.');
        default:
          return LoginResult.failure(
            '알 수 없는 오류가 발생했습니다. (${response.statusCode})',
          );
      }
    } catch (e) {
      debugPrint('로그인 네트워크 오류: $e');
      if (e.toString().contains('timeout') ||
          e.toString().contains('TimeoutException')) {
        return LoginResult.failure('서버 응답 시간이 초과되었습니다. 네트워크 연결을 확인해주세요.');
      }
      return LoginResult.failure('네트워크 연결에 실패했습니다. 인터넷 연결을 확인해주세요.');
    }
  }

  /// 로그아웃 API 호출
  static Future<AuthResult> logout({required String id}) async {
    try {
      debugPrint('=== 로그아웃 API 요청 ===');
      debugPrint('URL: $baseUrl/logout');
      debugPrint('아이디: $id');

      final requestBody = {'id': id};

      final response = await http
          .post(
            Uri.parse('$baseUrl/logout'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('=== 로그아웃 API 응답 ===');
      debugPrint('상태코드: ${response.statusCode}');
      debugPrint('응답 내용: ${response.body}');

      switch (response.statusCode) {
        case 200:
          return AuthResult.success(message: '로그아웃되었습니다.');
        case 404:
          return AuthResult.failure('존재하지 않는 사용자입니다.');
        case 500:
          return AuthResult.failure('로그아웃 처리 중 서버 오류가 발생했습니다.');
        default:
          return AuthResult.failure(
            '알 수 없는 오류가 발생했습니다. (${response.statusCode})',
          );
      }
    } catch (e) {
      debugPrint('로그아웃 네트워크 오류: $e');
      return AuthResult.failure('네트워크 연결에 실패했습니다.');
    }
  }

  /// 회원정보 수정 API 호출
  static Future<AuthResult> updateUserInfo({
    required String id,
    String? pw,
    String? phone,
    String? email,
  }) async {
    try {
      debugPrint('=== 회원정보 수정 API 요청 ===');

      final requestBody = <String, dynamic>{'id': id};

      if (pw != null && pw.isNotEmpty) requestBody['pw'] = pw;
      if (phone != null && phone.isNotEmpty) requestBody['phone'] = phone;
      if (email != null && email.isNotEmpty) requestBody['email'] = email;

      debugPrint('요청 데이터: $requestBody');

      final response = await http
          .put(
            Uri.parse('$baseUrl/update'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('=== 회원정보 수정 API 응답 ===');
      debugPrint('상태코드: ${response.statusCode}');
      debugPrint('응답 내용: ${response.body}');

      switch (response.statusCode) {
        case 200:
          return AuthResult.success(message: '회원정보가 수정되었습니다.');
        case 400:
          final errorMsg = response.body.contains('필수')
              ? 'id는 필수입니다.'
              : '수정할 항목이 없습니다.';
          return AuthResult.failure(errorMsg);
        case 404:
          return AuthResult.failure('해당 id의 사용자가 없습니다.');
        case 500:
          return AuthResult.failure('회원정보 수정 중 서버 오류가 발생했습니다.');
        default:
          return AuthResult.failure(
            '알 수 없는 오류가 발생했습니다. (${response.statusCode})',
          );
      }
    } catch (e) {
      debugPrint('회원정보 수정 네트워크 오류: $e');
      return AuthResult.failure('네트워크 연결에 실패했습니다.');
    }
  }

  /// 회원 삭제(탈퇴) API 호출
  ///
  /// [id] : 삭제할 사용자 아이디
  ///
  /// 서버에 DELETE 요청을 보내 회원탈퇴를 처리합니다.
  /// 성공 시 '회원 삭제가 완료되었습니다.' 메시지를 반환합니다.
  /// 실패 시 상태코드에 따라 적절한 에러 메시지를 반환합니다.
  static Future<AuthResult> deleteUser({required String id}) async {
    try {
      final requestBody = {'id': id};

      final response = await http
          .delete(
            Uri.parse('${ApiConfig.userBase}/delete'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      switch (response.statusCode) {
        case 200:
          return AuthResult.success(message: '회원 삭제가 완료되었습니다.');
        case 404:
          return AuthResult.failure('존재하지 않는 사용자입니다.');
        case 500:
          return AuthResult.failure('회원 삭제 처리 중 서버 오류가 발생했습니다.');
        default:
          return AuthResult.failure(
            '알 수 없는 오류가 발생했습니다. (${response.statusCode})',
          );
      }
    } catch (e) {
      return AuthResult.failure('네트워크 연결에 실패했습니다.');
    }
  }

  /// 서버 연결 테스트
  static Future<bool> testConnection() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 5));

      debugPrint('서버 연결 테스트: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 404;
    } catch (e) {
      debugPrint('서버 연결 테스트 실패: $e');
      return false;
    }
  }

  /// 🔥 위치 공유 설정 업데이트
  Future<bool> updateShareLocation(String userId, bool isEnabled) async {
    try {
      debugPrint('=== 위치 공유 설정 업데이트 시작 ===');
      debugPrint('사용자 ID: $userId');
      debugPrint('위치 공유 상태: $isEnabled');

      final response = await http.put(
        Uri.parse('${ApiConfig.userBase}/update_share_location'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id': userId,
        }),
      );

      debugPrint('서버 응답 상태: ${response.statusCode}');
      debugPrint('서버 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('✅ 위치 공유 설정 업데이트 성공');
        return true;
      } else {
        debugPrint('❌ 위치 공유 설정 업데이트 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ 위치 공유 설정 업데이트 오류: $e');
      return false;
    }
  }

  /// 🔥 사용자 존재 여부 확인
  Future<bool> checkUserExists(String userId) async {
    try {
      debugPrint('=== 사용자 존재 여부 확인 시작 ===');
      debugPrint('확인할 사용자 ID: $userId');

      final response = await http.get(
        Uri.parse('${ApiConfig.userBase}/check_user/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint('서버 응답 상태: ${response.statusCode}');
      debugPrint('서버 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = response.body.toLowerCase();
        // 서버에서 사용자가 존재한다고 응답한 경우
        if (responseBody.contains('true') || responseBody.contains('존재') || responseBody.contains('exists')) {
          debugPrint('✅ 사용자가 존재함');
          return true;
        } else {
          debugPrint('❌ 사용자가 존재하지 않음');
          return false;
        }
      } else {
        debugPrint('❌ 사용자 확인 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ 사용자 확인 오류: $e');
      return false;
    }
  }
}

/// 인증 결과를 나타내는 클래스
class AuthResult {
  final bool isSuccess;
  final String message;

  AuthResult._({required this.isSuccess, required this.message});

  factory AuthResult.success({required String message}) {
    return AuthResult._(isSuccess: true, message: message);
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(isSuccess: false, message: message);
  }
}

/// 로그인 결과를 나타내는 클래스
class LoginResult extends AuthResult {
  final String? userId;
  final String? userName;
  final bool? isLogin;

  LoginResult._({
    required super.isSuccess,
    required super.message,
    this.userId,
    this.userName,
    this.isLogin,
  }) : super._();

  factory LoginResult.success({
    required String userId,
    required String userName,
    required bool isLogin,
  }) {
    return LoginResult._(
      isSuccess: true,
      message: '로그인 성공',
      userId: userId,
      userName: userName,
      isLogin: isLogin,
    );
  }

  factory LoginResult.failure(String message) {
    return LoginResult._(isSuccess: false, message: message);
  }
}
