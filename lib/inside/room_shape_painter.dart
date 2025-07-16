// lib/inside/room_shape_painter.dart
// (오류 최종 수정 버전)
import 'package:flutter/material.dart';

class RoomShapePainter extends CustomPainter {
  final bool isSelected;
  final dynamic shape;

  RoomShapePainter({
    required this.isSelected,
    required this.shape,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isSelected || size.isEmpty) return;

    // 선택된 영역을 시각적으로 강조하기 위한 페인트 설정
    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.blue.withOpacity(0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    if (shape is Path) {
      // --- Path(다각형)를 그리는 부분 (이 부분만 수정되었습니다) ---
      final Path path = shape;

      // 1. Path의 원본 경계(source)를 가져옵니다.
      final Rect sourceBounds = path.getBounds();
      if (sourceBounds.isEmpty) return;

      // 2. Path가 그려질 위젯의 전체 영역을 목적지(destination)로 설정합니다.
      final Rect destinationBounds = Offset.zero & size;

      // 3. [핵심 해결책] 원본 Path를 목적지 영역에 맞추기 위한 변환 행렬을 직접 계산합니다.
      // 가로/세로 크기 조절 비율을 계산합니다.
      final double scaleX = destinationBounds.width / sourceBounds.width;
      final double scaleY = destinationBounds.height / sourceBounds.height;

      // 최종 변환 행렬을 생성합니다.
      final Matrix4 matrix = Matrix4.identity()
        // a. 목적지 위치로 이동합니다.
        ..translate(destinationBounds.left, destinationBounds.top)
        // b. 계산된 비율로 크기를 조절합니다.
        ..scale(scaleX, scaleY)
        // c. 원본 Path의 시작점을 (0,0)으로 이동시켜 위치를 보정합니다.
        ..translate(-sourceBounds.left, -sourceBounds.top);

      // 4. 원본 Path에 위 변환을 적용하여 최종 모양을 만듭니다.
      final Path transformedPath = path.transform(matrix.storage);

      // 5. 최종 변환된 Path를 화면에 그립니다.
      canvas.drawPath(transformedPath, fillPaint);
      canvas.drawPath(transformedPath, strokePaint);
    } else if (shape is Rect) {
      // --- Rect(사각형)를 그리는 부분 (기존 로직 유지) ---
      final rect = Offset.zero & size;
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant RoomShapePainter oldDelegate) {
    // isSelected 상태나 shape이 변경될 때만 다시 그리도록 최적화
    return oldDelegate.isSelected != isSelected || oldDelegate.shape != shape;
  }
}