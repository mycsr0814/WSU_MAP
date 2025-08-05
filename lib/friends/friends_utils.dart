import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// 친구 화면에서 사용되는 유틸리티 함수들
class FriendsUtils {
  /// 사용자 ID 마스킹 함수
  static String maskUserId(String userId) {
    if (userId.length <= 4) return userId;
    return userId.substring(0, 4) + '*' * (userId.length - 4);
  }

  /// 성공 메시지 표시
  static void showSuccessMessage(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 에러 메시지 표시
  static void showErrorMessage(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// 전화번호 처리 함수
  static Future<void> handlePhone(BuildContext context, String phone) async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(child: Text('전화앱을 열 수 없습니다.')),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  /// 친구 추가 에러 메시지 처리
  static String getAddFriendErrorMessage(dynamic error) {
    String errorMsg = '친구 추가 중 오류가 발생했습니다';
    final errorString = error.toString();

    if (errorString.contains('존재하지 않는 사용자')) {
      errorMsg = '존재하지 않는 사용자입니다';
    } else if (errorString.contains('이미 친구')) {
      errorMsg = '이미 친구인 사용자입니다';
    } else if (errorString.contains('이미 요청')) {
      errorMsg = '이미 친구 요청을 보낸 사용자입니다';
    } else if (errorString.contains('자기 자신')) {
      errorMsg = '자기 자신을 친구로 추가할 수 없습니다';
    } else if (errorString.contains('잘못된')) {
      errorMsg = '잘못된 사용자 ID입니다';
    } else if (errorString.contains('서버 오류')) {
      errorMsg = '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요';
    } else {
      errorMsg = errorString.replaceAll('Exception: ', '');
    }

    return errorMsg;
  }
}
