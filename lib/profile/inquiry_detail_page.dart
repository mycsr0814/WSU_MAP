import 'package:flutter/material.dart';
import '../services/inquiry_service.dart';
import '../generated/app_localizations.dart';

class InquiryDetailPage extends StatelessWidget {
  final InquiryItem inquiry;

  const InquiryDetailPage({required this.inquiry, super.key});

String getLocalizedCategory(BuildContext context, String category) {
  final l10n = AppLocalizations.of(context)!;
  
  // 🔥 디버깅 로그 추가
  debugPrint('=== getLocalizedCategory 디버깅 ===');
  debugPrint('입력된 category: "$category"');
  debugPrint('category 길이: ${category.length}');
  debugPrint('category 타입: ${category.runtimeType}');
  
  // 🔥 정규화: 공백 제거 및 소문자 변환
  final normalizedCategory = category.trim().toLowerCase();
  debugPrint('정규화된 category: "$normalizedCategory"');
  
  switch (normalizedCategory) {
    case 'place_error':
      debugPrint('매치됨: place_error -> ${l10n.inquiry_category_place_error}');
      return l10n.inquiry_category_place_error;
    case 'bug':
      debugPrint('매치됨: bug -> ${l10n.inquiry_category_bug}');
      return l10n.inquiry_category_bug;
    case 'feature':
      debugPrint('매치됨: feature -> ${l10n.inquiry_category_feature}');
      return l10n.inquiry_category_feature;
    case 'route_error':
      debugPrint('매치됨: route_error -> ${l10n.inquiry_category_route_error}');
      return l10n.inquiry_category_route_error;
    case 'other':
      debugPrint('매치됨: other -> ${l10n.inquiry_category_other}');
      return l10n.inquiry_category_other;
    default:
      // 🔥 매치되지 않는 경우 모든 가능한 값들 체크
      debugPrint('❌ 매치되지 않음! 가능한 값들:');
      debugPrint('  - place_error');
      debugPrint('  - bug'); 
      debugPrint('  - feature');
      debugPrint('  - route_error');
      debugPrint('  - other');
      debugPrint('기본값으로 "기타" 반환');
      return l10n.inquiry_category_other; // 🔥 기본값을 "기타"로 설정
  }
}
  @override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    appBar: AppBar(
      title: Text(
        l10n.inquiry_detail,
        style: TextStyle(
          color: Colors.grey[800],
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 수정된 카테고리 및 상태 태그
          Row(
            children: [
              // 첫 번째: 카테고리 태그
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getCategoryColor(inquiry.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  getLocalizedCategory(context, inquiry.category),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getCategoryColor(inquiry.category),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 두 번째: 상태 태그
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(inquiry.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _localizedStatus(context, inquiry.status),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(inquiry.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 제목
          Text(
            inquiry.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 16),

          // 작성일
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Text(
                inquiry.createdAt,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              if (inquiry.hasImage) ...[
                const SizedBox(width: 24),
                Icon(Icons.image, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Text(
                  l10n.image_attachment,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // 문의 내용
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.inquiry_content,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  inquiry.content,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 이미지 표시 (있는 경우)
          if (inquiry.hasImage && inquiry.imagePath != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.attached_image,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      inquiry.imagePath!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 답변 섹션
          if (_isAnsweredStatus(inquiry.status)) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.answer_section_title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    inquiry.answer ??
                        l10n.inquiry_default_answer,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[800],
                      height: 1.6,
                    ),
                  ),
                  if (inquiry.answeredAt != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Colors.green[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${l10n.answer_date_prefix} ${inquiry.answeredAt}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: Colors.orange[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.waiting_answer_status,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.waiting_answer_message,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange[800],
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

// 🔥 추가해야 할 카테고리 색상 함수
Color _getCategoryColor(String category) {
  switch (category) {
    case 'place_error':
      return Colors.red;
    case 'bug':
      return Colors.orange;
    case 'feature':
      return Colors.blue;
    case 'route_error':
      return Colors.purple;
    case 'other':
      return Colors.grey;
    default:
      return Colors.blue;
  }
}

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
      case '답변 대기':
        return Colors.orange;
      case 'answered':
      case '답변 완료':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  bool _isAnsweredStatus(String status) {
    return status == 'answered' || status == '답변 완료';
  }

  String _localizedStatus(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'pending':
      case '답변 대기':
        return l10n.status_pending;
      case 'answered':
      case '답변 완료':
        return l10n.status_answered;
      default:
        return status;
    }
  }
}
