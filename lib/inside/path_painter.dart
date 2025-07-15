// lib/inside/path_painter.dart - 네비게이션 모드 지원 업데이트

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
    if (pathPoints.length < 2) return;

    // 🔥 경로 타입에 따른 스타일 설정
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
        pathPoints.first * scale,
        pathPoints.last * scale,
      ));
    }

    final Path path = Path();
    
    // 첫 번째 점으로 이동
    final firstPoint = pathPoints.first * scale;
    path.moveTo(firstPoint.dx, firstPoint.dy);

    // 🔥 부드러운 곡선 경로 생성 (네비게이션 모드)
    if (isNavigationMode && pathPoints.length > 2) {
      _drawSmoothPath(canvas, pathPaint);
    } else {
      // 기존 직선 경로
      for (int i = 1; i < pathPoints.length; i++) {
        final point = pathPoints[i] * scale;
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, pathPaint);
    }

    // 🔥 시작점과 끝점 마커
    _drawStartEndMarkers(canvas);

    // 🔥 방향 화살표 (옵션)
    if (showDirectionArrows) {
      _drawDirectionArrows(canvas);
    }

    // 🔥 네비게이션 모드에서 진행 상황 표시
    if (isNavigationMode) {
      _drawProgressIndicator(canvas);
    }
  }

  /// 🔥 부드러운 곡선 경로 그리기
  void _drawSmoothPath(Canvas canvas, Paint pathPaint) {
    final Path smoothPath = Path();
    final scaledPoints = pathPoints.map((p) => p * scale).toList();
    
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
  }

  /// 🔥 시작점과 끝점 마커 그리기
  void _drawStartEndMarkers(Canvas canvas) {
    if (pathPoints.isEmpty) return;

    // 시작점 마커 (초록색 원)
    final startPoint = pathPoints.first * scale;
    final startPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(startPoint, isNavigationMode ? 8.0 : 6.0, startPaint);
    
    // 시작점 테두리
    final startBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(startPoint, isNavigationMode ? 8.0 : 6.0, startBorderPaint);

    // 끝점 마커 (빨간색 원)
    final endPoint = pathPoints.last * scale;
    final endPaint = Paint()
      ..color = isNavigationMode ? Colors.orange : Colors.red
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(endPoint, isNavigationMode ? 10.0 : 8.0, endPaint);
    
    // 끝점 테두리
    final endBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(endPoint, isNavigationMode ? 10.0 : 8.0, endBorderPaint);

    // 🔥 네비게이션 모드에서는 목적지에 깃발 아이콘
    if (isNavigationMode) {
      _drawDestinationFlag(canvas, endPoint);
    }
  }

  /// 🔥 목적지 깃발 그리기
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

  /// 🔥 방향 화살표 그리기
  void _drawDirectionArrows(Canvas canvas) {
    if (pathPoints.length < 2) return;

    final arrowPaint = Paint()
      ..color = (pathColor ?? Colors.red).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // 경로 중간 지점들에 화살표 그리기
    for (int i = 1; i < pathPoints.length - 1; i += 2) {
      final current = pathPoints[i] * scale;
      final next = pathPoints[i + 1] * scale;
      
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
  }

  /// 🔥 진행 상황 표시기 (네비게이션 모드)
  void _drawProgressIndicator(Canvas canvas) {
    // 현재는 간단한 점선 효과로 구현
    // 실제로는 GPS 위치나 진행 상황에 따라 동적으로 변경 가능
    
    if (pathPoints.length < 2) return;

    final progressPaint = Paint()
      ..color = Colors.lightBlue.withOpacity(0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 점선 효과를 위한 패턴
    final dashWidth = 10.0;
    final dashSpace = 5.0;
    
    for (int i = 0; i < pathPoints.length - 1; i++) {
      final start = pathPoints[i] * scale;
      final end = pathPoints[i + 1] * scale;
      
      _drawDashedLine(canvas, start, end, dashWidth, dashSpace, progressPaint);
    }
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

// 🔥 애니메이션을 지원하는 PathPainter
class AnimatedPathPainter extends PathPainter {
  final double animationProgress;
  final bool showProgress;

  AnimatedPathPainter({
    required List<Offset> pathPoints,
    required double scale,
    Color? pathColor,
    double? strokeWidth,
    bool isNavigationMode = false,
    bool showDirectionArrows = true,
    this.animationProgress = 1.0,
    this.showProgress = false,
  }) : super(
         pathPoints: pathPoints,
         scale: scale,
         pathColor: pathColor,
         strokeWidth: strokeWidth,
         isNavigationMode: isNavigationMode,
         showDirectionArrows: showDirectionArrows,
       );

  @override
  void paint(Canvas canvas, Size size) {
    if (pathPoints.length < 2) return;

    // 애니메이션 진행률에 따라 표시할 점들 계산
    final int pointsToShow = (pathPoints.length * animationProgress).round();
    final animatedPoints = pathPoints.take(pointsToShow).toList();
    
    if (animatedPoints.length < 2) return;

    // 기본 경로 그리기
    final Paint pathPaint = Paint()
      ..color = pathColor ?? (isNavigationMode ? Colors.blue : Colors.red)
      ..strokeWidth = strokeWidth ?? (isNavigationMode ? 6.0 : 4.0)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path path = Path();
    final firstPoint = animatedPoints.first * scale;
    path.moveTo(firstPoint.dx, firstPoint.dy);

    for (int i = 1; i < animatedPoints.length; i++) {
      final point = animatedPoints[i] * scale;
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(path, pathPaint);

    // 진행 상황 표시
    if (showProgress && animatedPoints.isNotEmpty) {
      _drawAnimationProgress(canvas, animatedPoints);
    }

    // 시작점과 현재 위치 마커
    _drawAnimationMarkers(canvas, animatedPoints);
  }

  void _drawAnimationProgress(Canvas canvas, List<Offset> animatedPoints) {
    // 현재 위치에 펄스 효과
    if (animatedPoints.isNotEmpty) {
      final currentPosition = animatedPoints.last * scale;
      
      // 펄스 링 그리기
      for (int i = 0; i < 3; i++) {
        final radius = 15.0 + (i * 10.0);
        final opacity = 0.3 - (i * 0.1);
        
        final pulsePaint = Paint()
          ..color = Colors.blue.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        
        canvas.drawCircle(currentPosition, radius, pulsePaint);
      }
    }
  }

  void _drawAnimationMarkers(Canvas canvas, List<Offset> animatedPoints) {
    if (animatedPoints.isEmpty) return;

    // 시작점 (초록색)
    final startPoint = animatedPoints.first * scale;
    final startPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(startPoint, 8.0, startPaint);

    // 현재 위치 (파란색, 더 큰 원)
    if (animatedPoints.length > 1) {
      final currentPoint = animatedPoints.last * scale;
      final currentPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(currentPoint, 10.0, currentPaint);
      
      // 현재 위치 테두리
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      canvas.drawCircle(currentPoint, 10.0, borderPaint);
    }

    // 목적지 (원래 경로의 마지막 점)
    if (pathPoints.isNotEmpty) {
      final endPoint = pathPoints.last * scale;
      final endPaint = Paint()
        ..color = animationProgress >= 1.0 ? Colors.green : Colors.red.withOpacity(0.5)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(endPoint, 8.0, endPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is AnimatedPathPainter) {
      return super.shouldRepaint(oldDelegate) ||
             animationProgress != oldDelegate.animationProgress ||
             showProgress != oldDelegate.showProgress;
    }
    return true;
  }
}

