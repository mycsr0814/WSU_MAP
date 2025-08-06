// lib/services/inquiry_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../auth/user_auth.dart';

class InquiryService {
  // 서버 라우터 구조에 맞게 URL 수정
  static String get baseUrl => '${ApiConfig.baseHost}:3001/user/inquiry';

  /// 문의하기 작성
  static Future<bool> createInquiry({
    required String userId,
    required String category,
    required String title,
    required String content,
    File? imageFile,
  }) async {
    try {
      debugPrint('=== 문의하기 작성 시작 ===');
      debugPrint('사용자 ID: $userId');
      debugPrint('카테고리: $category');
      debugPrint('제목: $title');
      debugPrint('내용: $content');
      debugPrint('이미지 파일: ${imageFile?.path ?? "없음"}');

      // 필드 검증
      if (userId.isEmpty) {
        debugPrint('❌ 사용자 ID가 비어있음');
        return false;
      }
      if (category.isEmpty) {
        debugPrint('❌ 카테고리가 비어있음');
        return false;
      }
      if (title.isEmpty) {
        debugPrint('❌ 제목이 비어있음');
        return false;
      }
      if (content.isEmpty) {
        debugPrint('❌ 내용이 비어있음');
        return false;
      }

      // 먼저 multipart 요청 시도
      bool success = await _tryMultipartRequest(userId, category, title, content, imageFile);
      
      if (!success) {
        debugPrint('multipart 요청 실패, JSON 요청 시도...');
        success = await _tryJsonRequest(userId, category, title, content);
      }

      return success;
    } catch (e) {
      debugPrint('❌ 문의하기 작성 오류: $e');
      return false;
    }
  }

  /// multipart 요청 시도
  static Future<bool> _tryMultipartRequest(
    String userId,
    String category,
    String title,
    String content,
    File? imageFile,
  ) async {
    try {
      debugPrint('=== multipart 요청 시도 ===');
      
      // 서버 라우트: router.post('/:id', inquiryController.createInquiry)
      final List<String> possibleUrls = [
        '${ApiConfig.baseHost}:3001/user/inquiry/$userId',  // /user/inquiry/:id (서버 라우트에 맞는 경로)
        '${ApiConfig.baseHost}:3001/inquiry/$userId',       // 대안 경로
        '${ApiConfig.baseHost}:3001/user/inquiry',          // /user/inquiry (body에 id 포함)
        '${ApiConfig.baseHost}:3001/inquiry',               // /inquiry (body에 id 포함)
      ];

      for (int i = 0; i < possibleUrls.length; i++) {
        final url = possibleUrls[i];
        debugPrint('URL 시도 ${i + 1}: $url');
        
        // multipart 요청 생성
        final request = http.MultipartRequest('POST', Uri.parse(url));

        // 헤더 추가
        request.headers['Content-Type'] = 'multipart/form-data';

        // 텍스트 필드 추가
        request.fields['category'] = category;
        request.fields['title'] = title;
        request.fields['content'] = content;
        
        // URL이 /user/inquiry 또는 /inquiry로 끝나는 경우 body에 id 추가
        if (url.endsWith('/user/inquiry') || url.endsWith('/inquiry')) {
          request.fields['id'] = userId;
        }

        debugPrint('요청 필드 확인:');
        debugPrint('  category: ${request.fields['category']}');
        debugPrint('  title: ${request.fields['title']}');
        debugPrint('  content: ${request.fields['content']}');
        if (request.fields.containsKey('id')) {
          debugPrint('  id: ${request.fields['id']}');
        }

        // 이미지 파일이 있는 경우 추가
        if (imageFile != null) {
          try {
            final imageStream = http.ByteStream(imageFile.openRead());
            final imageLength = await imageFile.length();
            
            final multipartFile = http.MultipartFile(
              'image',
              imageStream,
              imageLength,
              filename: 'inquiry_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
            
            request.files.add(multipartFile);
            debugPrint('이미지 파일 추가됨: ${imageFile.path}');
            debugPrint('이미지 파일 크기: $imageLength bytes');
          } catch (e) {
            debugPrint('이미지 파일 처리 중 오류: $e');
          }
        }

        debugPrint('요청 URL: ${request.url}');
        debugPrint('요청 헤더: ${request.headers}');
        debugPrint('요청 필드 수: ${request.fields.length}');
        debugPrint('요청 파일 수: ${request.files.length}');

        // 요청 전송
        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        debugPrint('multipart 응답 상태: ${response.statusCode}');
        debugPrint('multipart 응답 헤더: ${response.headers}');
        debugPrint('multipart 응답 내용: $responseBody');

        if (response.statusCode == 201 || response.statusCode == 200) {
          debugPrint('✅ multipart 문의하기 작성 성공 (URL: $url)');
          return true;
        } else if (response.statusCode == 500) {
          debugPrint('⚠️ 서버 내부 오류 (URL: $url): $responseBody');
          debugPrint('⚠️ 서버 로그를 확인해주세요. 필수 필드 누락 또는 형식 오류일 수 있습니다.');
          // 500 에러는 서버 문제이므로 다음 URL 시도
          if (i < possibleUrls.length - 1) {
            debugPrint('다음 URL 시도...');
          } else {
            debugPrint('❌ 모든 multipart URL 시도 실패');
          }
        } else {
          debugPrint('❌ multipart 문의하기 작성 실패 (URL: $url): ${response.statusCode}');
          if (i < possibleUrls.length - 1) {
            debugPrint('다음 URL 시도...');
          } else {
            debugPrint('❌ 모든 multipart URL 시도 실패');
          }
        }
      }
      
      debugPrint('❌ 모든 multipart URL 시도 실패');
      return false;
    } catch (e) {
      debugPrint('❌ multipart 요청 오류: $e');
      return false;
    }
  }

  /// JSON 요청 시도 (이미지 없이)
  static Future<bool> _tryJsonRequest(
    String userId,
    String category,
    String title,
    String content,
  ) async {
    try {
      debugPrint('=== JSON 요청 시도 ===');
      
      // 서버 라우트: router.post('/:id', inquiryController.createInquiry)
      final List<String> possibleUrls = [
        '${ApiConfig.baseHost}:3001/user/inquiry/$userId',  // /user/inquiry/:id (서버 라우트에 맞는 경로)
        '${ApiConfig.baseHost}:3001/inquiry/$userId',       // 대안 경로
        '${ApiConfig.baseHost}:3001/user/inquiry',          // /user/inquiry (body에 id 포함)
        '${ApiConfig.baseHost}:3001/inquiry',               // /inquiry (body에 id 포함)
      ];

      for (int i = 0; i < possibleUrls.length; i++) {
        final url = possibleUrls[i];
        debugPrint('JSON URL 시도 ${i + 1}: $url');
        
        // 요청 바디 준비
        Map<String, dynamic> requestBody = {
          'category': category,
          'title': title,
          'content': content,
        };
        
        // URL이 /user/inquiry 또는 /inquiry로 끝나는 경우 body에 id 추가
        if (url.endsWith('/user/inquiry') || url.endsWith('/inquiry')) {
          requestBody['id'] = userId;
        }
        
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody),
        );

        debugPrint('JSON 요청 URL: ${response.request?.url}');
        debugPrint('JSON 요청 헤더: ${response.request?.headers}');
        debugPrint('JSON 요청 바디: ${jsonEncode(requestBody)}');

        debugPrint('JSON 응답 상태: ${response.statusCode}');
        debugPrint('JSON 응답 헤더: ${response.headers}');
        debugPrint('JSON 응답 내용: ${response.body}');

        if (response.statusCode == 201 || response.statusCode == 200) {
          debugPrint('✅ JSON 문의하기 작성 성공 (URL: $url)');
          return true;
        } else if (response.statusCode == 500) {
          debugPrint('⚠️ 서버 내부 오류 (URL: $url): ${response.body}');
          debugPrint('⚠️ 서버 로그를 확인해주세요. 필수 필드 누락 또는 형식 오류일 수 있습니다.');
          if (i < possibleUrls.length - 1) {
            debugPrint('다음 JSON URL 시도...');
          }
        } else {
          debugPrint('❌ JSON 문의하기 작성 실패 (URL: $url): ${response.statusCode}');
          if (i < possibleUrls.length - 1) {
            debugPrint('다음 JSON URL 시도...');
          }
        }
      }
      
      debugPrint('❌ 모든 JSON URL 시도 실패');
      return false;
    } catch (e) {
      debugPrint('❌ JSON 요청 오류: $e');
      return false;
    }
  }

  /// 문의하기 목록 조회 (필요시 구현)
  static Future<List<Map<String, dynamic>>> getInquiryList(String userId) async {
    try {
      debugPrint('=== 문의하기 목록 조회 시작 ===');
      debugPrint('사용자 ID: $userId');

      final response = await http.get(
        Uri.parse('$baseUrl/list/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint('응답 상태: ${response.statusCode}');
      debugPrint('응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('✅ 문의하기 목록 조회 성공: ${data.length}개');
        return data.cast<Map<String, dynamic>>();
      } else {
        debugPrint('❌ 문의하기 목록 조회 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ 문의하기 목록 조회 오류: $e');
      return [];
    }
  }

  /// 문의하기 상세 조회 (필요시 구현)
  static Future<Map<String, dynamic>?> getInquiryDetail(String inquiryId) async {
    try {
      debugPrint('=== 문의하기 상세 조회 시작 ===');
      debugPrint('문의 ID: $inquiryId');

      final response = await http.get(
        Uri.parse('$baseUrl/detail/$inquiryId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint('응답 상태: ${response.statusCode}');
      debugPrint('응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ 문의하기 상세 조회 성공');
        return data;
      } else {
        debugPrint('❌ 문의하기 상세 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ 문의하기 상세 조회 오류: $e');
      return null;
    }
  }

  /// 서버에서 사용 가능한 경로 테스트
  static Future<void> testServerRoutes(String userId) async {
    debugPrint('=== 서버 경로 테스트 시작 ===');
    
    final List<String> testUrls = [
      '${ApiConfig.baseHost}:3001/user/inquiry',
      '${ApiConfig.baseHost}:3001/inquiry/$userId',
      '${ApiConfig.baseHost}:3001/user/inquiry/$userId',
      '${ApiConfig.baseHost}:3001/inquiry',
    ];

    for (int i = 0; i < testUrls.length; i++) {
      final url = testUrls[i];
      debugPrint('테스트 URL ${i + 1}: $url');
      
      try {
        final response = await http.get(Uri.parse(url));
        debugPrint('GET ${url}: ${response.statusCode}');
        
        final postResponse = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'test': 'test'}),
        );
        debugPrint('POST ${url}: ${postResponse.statusCode}');
      } catch (e) {
        debugPrint('오류 ${url}: $e');
      }
    }
  }

  /// 문의 목록 조회
  static Future<List<InquiryItem>> getInquiries(String userId) async {
    try {
      debugPrint('=== 문의 목록 조회 시작 ===');
      debugPrint('사용자 ID: $userId');
      debugPrint('API 기본 URL: ${ApiConfig.baseHost}:3001');

      final List<String> possibleUrls = [
        '${ApiConfig.baseHost}:3001/inquiry/$userId',       // 서버 라우트: router.get('/:id', inquiryController.getInquiry)
        '${ApiConfig.baseHost}:3001/user/inquiry/$userId',  // 대안 경로
        '${ApiConfig.baseHost}:3001/user/inquiry?userId=$userId',
        '${ApiConfig.baseHost}:3001/inquiry?userId=$userId',
      ];

      for (int i = 0; i < possibleUrls.length; i++) {
        final url = possibleUrls[i];
        debugPrint('URL 시도 ${i + 1}: $url');

        try {
          final response = await http.get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
            },
          );

          debugPrint('응답 상태: ${response.statusCode}');
          debugPrint('응답 내용: ${response.body}');

          if (response.statusCode == 200) {
            debugPrint('✅ 200 응답 받음');
            final List<dynamic> data = jsonDecode(response.body);
            debugPrint('파싱된 데이터 개수: ${data.length}');
            debugPrint('데이터 내용: $data');

            // 서버에서 빈 배열이 반환되는 경우 빈 리스트 반환 (테스트 데이터 비활성화)
            if (data.isEmpty) {
              debugPrint('⚠️ 서버에서 빈 배열이 반환되었습니다. 빈 리스트를 반환합니다.');
              return [];
            }

            final List<InquiryItem> inquiries = data.map((item) {
              debugPrint('=== 개별 문의 파싱 시작 ===');
              debugPrint('원본 데이터: $item');
              
              // 서버 상태값을 한국어로 변환
              String status = item['Status']?.toString() ?? 'pending';
              String displayStatus = _convertStatusToKorean(status);
              debugPrint('상태 변환: $status → $displayStatus');
              
              // 날짜 포맷팅
              String createdAt = '';
              if (item['Created_At'] != null) {
                try {
                  DateTime date = DateTime.parse(item['Created_At']);
                  createdAt = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                } catch (e) {
                  createdAt = item['Created_At'].toString();
                }
              }
              
              // 답변일 포맷팅
              String? answeredAt;
              if (item['Answered_At'] != null) {
                try {
                  DateTime date = DateTime.parse(item['Answered_At']);
                  answeredAt = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                } catch (e) {
                  answeredAt = item['Answered_At'].toString();
                }
              }
              
              final inquiryItem = InquiryItem(
                id: item['Inquiry_Code']?.toString() ?? '',
                category: item['Category']?.toString() ?? '',
                title: item['Title']?.toString() ?? '',
                content: item['Content']?.toString() ?? '',
                status: displayStatus,
                createdAt: createdAt,
                hasImage: item['Image_Path'] != null && item['Image_Path'].toString().isNotEmpty,
                inquiryCode: item['Inquiry_Code']?.toString() ?? '',
                answer: item['Answer']?.toString(),
                answeredAt: answeredAt,
                imagePath: item['Image_Path']?.toString(),
              );
              
              debugPrint('파싱된 문의: ${inquiryItem.title} (${inquiryItem.status})');
              debugPrint('  - Image_Path: ${item['Image_Path']}');
              debugPrint('  - hasImage: ${inquiryItem.hasImage}');
              debugPrint('  - inquiryCode: ${inquiryItem.inquiryCode}');
              return inquiryItem;
            }).toList();

            debugPrint('✅ 문의 목록 조회 성공: ${inquiries.length}개');
            return inquiries;
          } else {
            debugPrint('❌ 문의 목록 조회 실패: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('❌ URL 시도 ${i + 1} 실패: $e');
        }
      }

      // 모든 URL 시도가 실패한 경우 빈 리스트 반환 (테스트 데이터 비활성화)
      debugPrint('⚠️ 모든 API URL 시도가 실패했습니다. 빈 리스트를 반환합니다.');
      return [];
      
      return [];
    } catch (e) {
      debugPrint('❌ 문의 목록 조회 오류: $e');
      return [];
    }
  }

  /// 서버 상태값을 한국어로 변환
  static String _convertStatusToKorean(String serverStatus) {
    switch (serverStatus.toLowerCase()) {
      case 'pending':
        return '답변 대기';
      case 'answered':
        return '답변 완료';
      default:
        return '답변 대기';
    }
  }

  /// 문의 삭제
  static Future<bool> deleteInquiry(String userId, String inquiryCode) async {
    try {
      debugPrint('=== 문의 삭제 시작 ===');
      debugPrint('사용자 ID: $userId');
      debugPrint('문의 코드: $inquiryCode');

      final List<String> possibleUrls = [
        '${ApiConfig.baseHost}:3001/user/inquiry/$userId',
        '${ApiConfig.baseHost}:3001/inquiry/$userId',
      ];

      for (int i = 0; i < possibleUrls.length; i++) {
        final url = possibleUrls[i];
        debugPrint('URL 시도 ${i + 1}: $url');

        try {
          final requestBody = {
            'inquiry_code': inquiryCode,
          };
          debugPrint('요청 본문: $requestBody');
          
          final response = await http.delete(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          );

          debugPrint('응답 상태: ${response.statusCode}');
          debugPrint('응답 내용: ${response.body}');

          if (response.statusCode == 200) {
            debugPrint('✅ 문의 삭제 성공');
            return true;
          } else {
            debugPrint('❌ 문의 삭제 실패: ${response.statusCode}');
            debugPrint('❌ 실패 응답: ${response.body}');
          }
        } catch (e) {
          debugPrint('❌ URL 시도 ${i + 1} 실패: $e');
        }
      }

      debugPrint('❌ 모든 URL 시도 실패');
      return false;
    } catch (e) {
      debugPrint('❌ 문의 삭제 오류: $e');
      return false;
    }
  }
}

// 문의 아이템 모델
class InquiryItem {
  final String id;
  final String category;
  final String title;
  final String content;
  final String status;
  final String createdAt;
  final bool hasImage;
  final String inquiryCode;
  final String? answer;
  final String? answeredAt;
  final String? imagePath;

  InquiryItem({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    required this.status,
    required this.createdAt,
    required this.hasImage,
    required this.inquiryCode,
    this.answer,
    this.answeredAt,
    this.imagePath,
  });
} 