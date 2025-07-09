// lib/painters/path_painter.dart (요청사항만 반영하여 수정한 코드)

import 'dart:math' as math; // 화살표 각도 계산을 위해 추가
import 'package:flutter/material.dart';

class PathPainter extends CustomPainter {
  final List<Offset> pathPoints;
  final double scale;

  PathPainter({
    required this.pathPoints,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // [유지] 원본 코드의 경로 유효성 검사
    if (pathPoints.length < 2) return;

    // [유지] 원본 코드의 페인트 설정
    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    
    // [유지] 원본 코드의 좌표 스케일링 및 경로 생성
    final startPoint = pathPoints.first.scale(scale, scale);
    path.moveTo(startPoint.dx, startPoint.dy);

    for (int i = 1; i < pathPoints.length; i++) {
      final nextPoint = pathPoints[i].scale(scale, scale);
      path.lineTo(nextPoint.dx, nextPoint.dy);
    }

    // [유지] 원본 코드의 기본 경로 그리기
    canvas.drawPath(path, paint);

    // =======================================================
    // [추가] 출발점과 도착점 장식을 그리는 코드
    // =======================================================

    // 1. 출발점에 초록색 원 그리기
    final startCirclePaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;
    // 원의 반지름은 5.0으로 설정
    canvas.drawCircle(startPoint, 5.0, startCirclePaint);

    // 2. 도착점에 화살표 그리기
    final arrowPaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 3.0 // 경로와 동일한 두께
      ..style = PaintingStyle.stroke;
    
    // 마지막 경로 선분의 두 점 (스케일링 전)
    final p1 = pathPoints[pathPoints.length - 2];
    final p2 = pathPoints.last;

    // 두 점 사이의 각도를 계산
    final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
    
    const arrowSize = 10.0; // 화살표 날개의 길이
    const arrowAngle = 35 * math.pi / 180; // 화살표 날개의 각도

    // 마지막 점의 스케일링된 좌표
    final scaledP2 = p2.scale(scale, scale);

    // 화살표의 양 날개 끝점 좌표 계산
    final p3 = Offset(
      scaledP2.dx - arrowSize * math.cos(angle - arrowAngle),
      scaledP2.dy - arrowSize * math.sin(angle - arrowAngle),
    );
    final p4 = Offset(
      scaledP2.dx - arrowSize * math.cos(angle + arrowAngle),
      scaledP2.dy - arrowSize * math.sin(angle + arrowAngle),
    );

    // 화살표 그리기
    canvas.drawLine(scaledP2, p3, arrowPaint);
    canvas.drawLine(scaledP2, p4, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant PathPainter oldDelegate) {
    // [유지] 원본 코드의 효율적인 리페인트 로직
    return oldDelegate.pathPoints != pathPoints || oldDelegate.scale != scale;
  }
}
