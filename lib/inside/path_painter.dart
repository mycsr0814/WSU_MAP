// lib/inside/path_painter.dart - 디버깅 개선 버전

import 'package:flutter/material.dart';
import 'dart:math' as math;

class PathPainter extends CustomPainter {
  final List<Offset> pathPoints;
  final double scale;
  final Color? pathColor;
  final double? strokeWidth;
  final bool isNavigationMode;
  final bool showDirectionArrows;

  PathPainter({
    required this.pathPoints,
    required this.scale,
    this.pathColor,
    this.strokeWidth,
    this.isNavigationMode = false,
    this.showDirectionArrows = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 🔥 강화된 디버깅 로그
    debugPrint('🎨 === PathPainter.paint 시작 ===');
    debugPrint('   pathPoints: ${pathPoints.length}개');
    debugPrint('   scale: $scale');
    debugPrint('   pathColor: $pathColor');
    debugPrint('   isNavigationMode: $isNavigationMode');
    debugPrint('   Canvas size: ${size.width} x ${size.height}');
    
    if (pathPoints.isEmpty) {
      debugPrint('❌ pathPoints가 비어있음');
      return;
    }
    
    if (pathPoints.length == 1) {
      debugPrint('⚠️ pathPoints가 1개뿐임: ${pathPoints.first}');
      // 단일 점은 원으로 표시
      _drawSinglePoint(canvas);
      return;
    }

    // 🔥 경로 점들의 상세 정보 출력
    debugPrint('   시작점: ${pathPoints.first}');
    debugPrint('   끝점: ${pathPoints.last}');
    debugPrint('   중간점들: ${pathPoints.skip(1).take(pathPoints.length - 2).toList()}');
    
    // 🔥 스케일 적용 후 좌표들 확인
    final scaledPoints = pathPoints.map((p) => p * scale).toList();
    debugPrint('   스케일 적용 후 시작점: ${scaledPoints.first}');
    debugPrint('   스케일 적용 후 끝점: ${scaledPoints.last}');

    // 경로 스타일 설정
    final Paint pathPaint = Paint()
      ..color = pathColor ?? (isNavigationMode ? Colors.blue : Colors.red)
      ..strokeWidth = strokeWidth ?? (isNavigationMode ? 6.0 : 4.0)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 🔥 네비게이션 모드에서는 그라디언트 효과
    if (isNavigationMode) {
      pathPaint.shader = LinearGradient(
        colors: [
          Colors.blue.withOpacity(0.8),
          Colors.blue,
          Colors.blueAccent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromPoints(
        scaledPoints.first,
        scaledPoints.last,
      ));
    }

    // 경로 그리기
    if (isNavigationMode && pathPoints.length > 2) {
      _drawSmoothPath(canvas, pathPaint, scaledPoints);
    } else {
      _drawStraightPath(canvas, pathPaint, scaledPoints);
    }

    debugPrint('✅ 경로 그리기 완료');

    // 시작점과 끝점 마커
    _drawStartEndMarkers(canvas, scaledPoints);

    // 방향 화살표 (옵션)
    if (showDirectionArrows && pathPoints.length > 1) {
      _drawDirectionArrows(canvas, scaledPoints);
    }

    // 네비게이션 모드에서 진행 상황 표시
    if (isNavigationMode) {
      _drawProgressIndicator(canvas, scaledPoints);
    }
    
    debugPrint('🎨 === PathPainter.paint 완료 ===');
  }

  /// 🔥 단일 점 표시
  void _drawSinglePoint(Canvas canvas) {
    final point = pathPoints.first * scale;
    final paint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(point, 12.0, paint);
    
    // 테두리
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawCircle(point, 12.0, borderPaint);
    
    debugPrint('✅ 단일 점 표시: $point');
  }

  /// 🔥 직선 경로 그리기
  void _drawStraightPath(Canvas canvas, Paint pathPaint, List<Offset> scaledPoints) {
    final Path path = Path();
    path.moveTo(scaledPoints.first.dx, scaledPoints.first.dy);

    for (int i = 1; i < scaledPoints.length; i++) {
      path.lineTo(scaledPoints[i].dx, scaledPoints[i].dy);
      debugPrint('   직선 연결: ${scaledPoints[i-1]} -> ${scaledPoints[i]}');
    }

    canvas.drawPath(path, pathPaint);
    debugPrint('✅ 직선 경로 그리기 완료');
  }

  /// 🔥 부드러운 곡선 경로 그리기
  void _drawSmoothPath(Canvas canvas, Paint pathPaint, List<Offset> scaledPoints) {
    final Path smoothPath = Path();
    
    if (scaledPoints.isEmpty) return;
    
    smoothPath.moveTo(scaledPoints[0].dx, scaledPoints[0].dy);

    // 베지어 곡선으로 부드러운 경로 생성
    for (int i = 1; i < scaledPoints.length; i++) {
      final current = scaledPoints[i - 1];
      final next = scaledPoints[i];
      
      if (i == scaledPoints.length - 1) {
        // 마지막 점은 직선으로
        smoothPath.lineTo(next.dx, next.dy);
      } else {
        // 중간 점들은 베지어 곡선으로
        final controlPoint1 = Offset(
          current.dx + (next.dx - current.dx) * 0.5,
          current.dy,
        );
        final controlPoint2 = Offset(
          current.dx + (next.dx - current.dx) * 0.5,
          next.dy,
        );
        
        smoothPath.cubicTo(
          controlPoint1.dx, controlPoint1.dy,
          controlPoint2.dx, controlPoint2.dy,
          next.dx, next.dy,
        );
      }
    }

    canvas.drawPath(smoothPath, pathPaint);
    debugPrint('✅ 부드러운 경로 그리기 완료');
  }

  /// 🔥 시작점과 끝점 마커 그리기
  void _drawStartEndMarkers(Canvas canvas, List<Offset> scaledPoints) {
    if (scaledPoints.isEmpty) return;

    // 시작점 마커 (파란색 원 + 출발 아이콘)
    final startPoint = scaledPoints.first;
    final startPaint = Paint()
      ..color = const Color(0xFF3B82F6) // 파란색으로 변경
      ..style = PaintingStyle.fill;
    
    final startRadius = isNavigationMode ? 12.0 : 10.0;
    canvas.drawCircle(startPoint, startRadius, startPaint);
    
    // 시작점 테두리
    final startBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(startPoint, startRadius, startBorderPaint);

    // 시작점 아이콘 (출발 표시)
    final startIconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // 출발 아이콘 그리기 (화살표 모양)
    final startIconPath = Path()
      ..moveTo(startPoint.dx - 4, startPoint.dy + 2)
      ..lineTo(startPoint.dx + 4, startPoint.dy)
      ..lineTo(startPoint.dx - 4, startPoint.dy - 2)
      ..close();
    
    canvas.drawPath(startIconPath, startIconPaint);

    // 끝점 마커 (빨간색 원 + 도착 아이콘)
    final endPoint = scaledPoints.last;
    final endPaint = Paint()
      ..color = const Color(0xFFEF4444) // 빨간색 유지
      ..style = PaintingStyle.fill;
    
    final endRadius = isNavigationMode ? 14.0 : 12.0;
    canvas.drawCircle(endPoint, endRadius, endPaint);
    
    // 끝점 테두리
    final endBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(endPoint, endRadius, endBorderPaint);

    // 끝점 아이콘 (도착 표시 - 깃발 모양)
    final endIconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // 깃발 아이콘 그리기
    final flagPolePath = Path()
      ..moveTo(endPoint.dx - 1, endPoint.dy - 6)
      ..lineTo(endPoint.dx - 1, endPoint.dy + 6);
    
    final flagPolePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawPath(flagPolePath, flagPolePaint);
    
    // 깃발 부분
    final flagPath = Path()
      ..moveTo(endPoint.dx - 1, endPoint.dy - 6)
      ..lineTo(endPoint.dx + 5, endPoint.dy - 4)
      ..lineTo(endPoint.dx - 1, endPoint.dy - 2)
      ..close();
    
    canvas.drawPath(flagPath, endIconPaint);
    
    debugPrint('✅ 시작/끝점 마커 그리기 완료 (개선된 버전)');
  }

  /// 목적지 깃발 그리기
  void _drawDestinationFlag(Canvas canvas, Offset position) {
    final flagPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // 깃발 폴
    canvas.drawLine(
      position + const Offset(0, -15),
      position + const Offset(0, 15),
      Paint()
        ..color = Colors.brown
        ..strokeWidth = 2.0,
    );

    // 깃발
    final flagPath = Path()
      ..moveTo(position.dx, position.dy - 15)
      ..lineTo(position.dx + 12, position.dy - 10)
      ..lineTo(position.dx, position.dy - 5)
      ..close();

    canvas.drawPath(flagPath, flagPaint);
  }

  /// 방향 화살표 그리기
  void _drawDirectionArrows(Canvas canvas, List<Offset> scaledPoints) {
    if (scaledPoints.length < 2) return;

    final arrowPaint = Paint()
      ..color = (pathColor ?? Colors.red).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // 경로 중간 지점들에 화살표 그리기
    for (int i = 1; i < scaledPoints.length - 1; i += 2) {
      final current = scaledPoints[i];
      final next = scaledPoints[i + 1];
      
      // 방향 벡터 계산
      final direction = next - current;
      if (direction.distance < 10) continue; // 너무 가까운 점들은 스킵
      
      final normalizedDirection = direction / direction.distance;
      final arrowSize = isNavigationMode ? 8.0 : 6.0;
      
      // 화살표 머리 그리기
      final arrowHead = current + normalizedDirection * 20;
      final arrowLeft = arrowHead + _rotateVector(normalizedDirection, 150) * arrowSize;
      final arrowRight = arrowHead + _rotateVector(normalizedDirection, -150) * arrowSize;
      
      final arrowPath = Path()
        ..moveTo(arrowHead.dx, arrowHead.dy)
        ..lineTo(arrowLeft.dx, arrowLeft.dy)
        ..lineTo(arrowRight.dx, arrowRight.dy)
        ..close();
      
      canvas.drawPath(arrowPath, arrowPaint);
    }
    
    debugPrint('✅ 방향 화살표 그리기 완료');
  }

  /// 진행 상황 표시기 (네비게이션 모드)
  void _drawProgressIndicator(Canvas canvas, List<Offset> scaledPoints) {
    if (scaledPoints.length < 2) return;

    final progressPaint = Paint()
      ..color = Colors.lightBlue.withOpacity(0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 점선 효과를 위한 패턴
    final dashWidth = 10.0;
    final dashSpace = 5.0;
    
    for (int i = 0; i < scaledPoints.length - 1; i++) {
      final start = scaledPoints[i];
      final end = scaledPoints[i + 1];
      
      _drawDashedLine(canvas, start, end, dashWidth, dashSpace, progressPaint);
    }
    
    debugPrint('✅ 진행 상황 표시기 그리기 완료');
  }

  /// 점선 그리기 헬퍼 메서드
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, 
                      double dashWidth, double dashSpace, Paint paint) {
    final distance = (end - start).distance;
    final dashCount = (distance / (dashWidth + dashSpace)).floor();
    
    for (int i = 0; i < dashCount; i++) {
      final dashStart = start + (end - start) * (i * (dashWidth + dashSpace) / distance);
      final dashEnd = start + (end - start) * ((i * (dashWidth + dashSpace) + dashWidth) / distance);
      
      canvas.drawLine(dashStart, dashEnd, paint);
    }
  }

  /// 벡터 회전 헬퍼 메서드
  Offset _rotateVector(Offset vector, double degrees) {
    final radians = degrees * (3.14159 / 180);
    final cos = math.cos(radians);
    final sin = math.sin(radians);
    
    return Offset(
      vector.dx * cos - vector.dy * sin,
      vector.dx * sin + vector.dy * cos,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is PathPainter) {
      return pathPoints != oldDelegate.pathPoints ||
             scale != oldDelegate.scale ||
             pathColor != oldDelegate.pathColor ||
             isNavigationMode != oldDelegate.isNavigationMode;
    }
    return true;
  }
}