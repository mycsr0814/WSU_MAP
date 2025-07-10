// room_shape_painter.dart (정밀 테두리 그리기 최종 적용)

import 'package:flutter/material.dart';

class RoomShapePainter extends CustomPainter {
  final bool isSelected;
  // [핵심 추가] 어떤 모양이든(Path 또는 Rect) 받을 수 있도록 dynamic 타입의 변수 추가
  final dynamic shape;

  RoomShapePainter({
    required this.isSelected,
    required this.shape, // 생성자를 통해 실제 모양 데이터를 전달받음
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 선택되지 않았으면 아무것도 그리지 않음
    if (!isSelected) return;

    // [개선] 더 잘 보이도록 채우기와 테두리를 둘 다 그림
    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3) // 반투명 파란색으로 채우기
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = Colors.blue.withOpacity(0.8) // 진한 파란색 테두리
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // [핵심] 전달받은 shape의 타입에 따라 다르게 그리는 로직
    if (shape is Path) {
      // 1. 모양이 Path(다각형)인 경우
      final Path path = shape;
      final Rect bounds = path.getBounds(); // 원본 Path의 경계 정보

      // Path의 좌표는 SVG 원본 기준이므로, 현재 위젯의 크기(size)에 맞게
      // 스케일과 위치를 동적으로 변환하는 Matrix를 생성합니다.
      final Matrix4 matrix = Matrix4.identity()
        ..translate(-bounds.left, -bounds.top) // Path의 시작점을 (0,0)으로 이동
        ..scale(size.width / bounds.width, size.height / bounds.height); // 위젯 크기에 맞게 확대/축소
      
      // 변환된 Path를 가져옵니다.
      final transformedPath = path.transform(matrix.storage);
      
      // 실제 모양 그대로 채우기와 테두리를 모두 그립니다.
      canvas.drawPath(transformedPath, fillPaint);
      canvas.drawPath(transformedPath, strokePaint);

    } else if (shape is Rect) {
      // 2. 모양이 Rect(사각형)인 경우
      // 이 위젯이 차지하는 영역(size) 그대로 사각형을 그립니다.
      final rect = Offset.zero & size;
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant RoomShapePainter oldDelegate) {
    // isSelected 상태나 모양(shape)이 변경될 때만 다시 그리도록 최적화
    return oldDelegate.isSelected != isSelected || oldDelegate.shape != shape;
  }
}
