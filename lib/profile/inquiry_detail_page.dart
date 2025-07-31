import 'package:flutter/material.dart';
import '../services/inquiry_service.dart';

// 문의 상세 페이지
class InquiryDetailPage extends StatelessWidget {
  final InquiryItem inquiry;

  const InquiryDetailPage({
    required this.inquiry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          '문의 상세',
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
            // 상태 및 카테고리 태그
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(inquiry.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    inquiry.category,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(inquiry.status),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(inquiry.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    inquiry.status,
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
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 8),
                Text(
                  inquiry.createdAt,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                if (inquiry.hasImage) ...[
                  const SizedBox(width: 24),
                  Icon(
                    Icons.image,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '이미지 첨부',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
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
                    '문의 내용',
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
                      '첨부 이미지',
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
            if (inquiry.status == '답변 완료') ...[
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
                          '답변',
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
                      inquiry.answer ?? '문의해주신 내용에 대한 답변입니다. 추가 문의사항이 있으시면 언제든 연락주세요.',
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
                            '답변일: ${inquiry.answeredAt}',
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
                          '답변 대기 중',
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
                      '문의해주신 내용을 검토하고 있습니다. 빠른 시일 내에 답변드리겠습니다.',
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
} 