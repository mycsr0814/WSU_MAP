import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 아이콘 생성
  await createAppIcon();
  
  print('아이콘 생성 완료!');
}

Future<void> createAppIcon() async {
  // 1024x1024 크기의 아이콘 생성
  const size = 1024.0;
  
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // 배경 그라데이션
  final paint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF1E3A8A), // 진한 파란색
        const Color(0xFF3B82F6), // 밝은 파란색
      ],
    ).createShader(Rect.fromLTWH(0, 0, size, size));
  
  // 둥근 배경
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size, size),
      const Radius.circular(200),
    ),
    paint,
  );
  
  // 학교 건물 아이콘 그리기
  final buildingPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  
  // 건물 본체
  canvas.drawRect(
    Rect.fromLTWH(size * 0.25, size * 0.4, size * 0.5, size * 0.4),
    buildingPaint,
  );
  
  // 지붕
  final roofPath = Path()
    ..moveTo(size * 0.2, size * 0.4)
    ..lineTo(size * 0.5, size * 0.25)
    ..lineTo(size * 0.8, size * 0.4)
    ..close();
  canvas.drawPath(roofPath, buildingPaint);
  
  // 창문들
  final windowPaint = Paint()
    ..color = const Color(0xFF1E3A8A)
    ..style = PaintingStyle.fill;
  
  // 1층 창문들
  for (int i = 0; i < 3; i++) {
    canvas.drawRect(
      Rect.fromLTWH(
        size * (0.3 + i * 0.15),
        size * 0.5,
        size * 0.08,
        size * 0.15,
      ),
      windowPaint,
    );
  }
  
  // 2층 창문들
  for (int i = 0; i < 3; i++) {
    canvas.drawRect(
      Rect.fromLTWH(
        size * (0.3 + i * 0.15),
        size * 0.35,
        size * 0.08,
        size * 0.15,
      ),
      windowPaint,
    );
  }
  
  // 입구
  canvas.drawRect(
    Rect.fromLTWH(size * 0.45, size * 0.65, size * 0.1, size * 0.15),
    windowPaint,
  );
  
  // 지도 아이콘 (우상단)
  final mapPaint = Paint()
    ..color = Colors.white.withOpacity(0.9)
    ..style = PaintingStyle.fill;
  
  // 지도 배경
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(size * 0.6, size * 0.1, size * 0.25, size * 0.25),
      const Radius.circular(20),
    ),
    mapPaint,
  );
  
  // 지도 내부 경로
  final pathPaint = Paint()
    ..color = const Color(0xFF1E3A8A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8;
  
  final path = Path()
    ..moveTo(size * 0.7, size * 0.2)
    ..lineTo(size * 0.75, size * 0.25)
    ..lineTo(size * 0.8, size * 0.2)
    ..lineTo(size * 0.75, size * 0.3);
  canvas.drawPath(path, pathPaint);
  
  // 위치 마커
  final markerPaint = Paint()
    ..color = const Color(0xFFEF4444)
    ..style = PaintingStyle.fill;
  
  canvas.drawCircle(
    Offset(size * 0.75, size * 0.3),
    12,
    markerPaint,
  );
  
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();
  
  // 파일로 저장
  final file = File('lib/asset/app_icon.png');
  await file.writeAsBytes(bytes);
  
  print('아이콘이 lib/asset/app_icon.png에 저장되었습니다.');
}
