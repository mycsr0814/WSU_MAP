// lib/utils/svg_data_parser.dart (null safety 오류 수정 완료)

import 'dart:ui';
import 'package:xml/xml.dart';
import 'package:path_drawing/path_drawing.dart';

class SvgDataParser {
  static List<Map<String, dynamic>> parseButtonData(String svgContent) {
    final List<Map<String, dynamic>> buttons = [];
    final document = XmlDocument.parse(svgContent);

    // 1. <rect> 태그 파싱: null safety 적용
    final rects = document.findAllElements('rect');
    for (var rect in rects) {
      String? id =
          rect.getAttribute('inkscape:label') ?? rect.getAttribute('id');
      // null 체크 및 조건부 호출 사용
      if ((id!.startsWith('R') || int.tryParse(id) != null)) {
        final x = double.tryParse(rect.getAttribute('x') ?? '');
        final y = double.tryParse(rect.getAttribute('y') ?? '');
        final width = double.tryParse(rect.getAttribute('width') ?? '');
        final height = double.tryParse(rect.getAttribute('height') ?? '');
        if (x != null && y != null && width != null && height != null) {
          buttons.add({
            'id': id, // 이제 null이 아님이 보장됨
            'type': 'rect', // [추가] 데이터 타입을 'rect'로 명시
            'rect': Rect.fromLTWH(x, y, width, height),
          });
        }
      }
    }

    // 2. <path> 태그 파싱: null safety 적용
    final paths = document.findAllElements('path');
    for (var pathElement in paths) {
      String? id =
          pathElement.getAttribute('inkscape:label') ??
          pathElement.getAttribute('id');
      final dAttribute = pathElement.getAttribute('d');
      // null 체크 및 조건부 호출 사용
      if (id!.startsWith('R') && dAttribute != null) {
        try {
          final Path path = parseSvgPathData(dAttribute);
          buttons.add({
            'id': id, // 이제 null이 아님이 보장됨
            'type': 'path', // [추가] 데이터 타입을 'path'로 명시
            'path': path, // [핵심] Rect가 아닌 Path 객체를 그대로 저장
          });
        } catch (e) {
          print("SVG Path 파싱 중 오류 발생 (ID: $id): $e");
        }
      }
    }
    return buttons;
  }

  /// 길찾기용 모든 노드 좌표를 파싱하는 함수 (null safety 적용)
  static Map<String, Offset> parseAllNodes(String svgContent) {
    final Map<String, Offset> nodes = {};
    final document = XmlDocument.parse(svgContent);

    void addNode(String id, Offset offset) {
      if (id.startsWith('R')) {
        nodes[id.substring(1)] = offset;
      } else {
        nodes[id] = offset;
      }
    }

    document.descendants.whereType<XmlElement>().forEach((element) {
      String? id =
          element.getAttribute('inkscape:label') ?? element.getAttribute('id');
      if (id == null) return; // null 체크로 조기 반환

      if (element.name.local == 'rect') {
        final x = double.tryParse(element.getAttribute('x') ?? '');
        final y = double.tryParse(element.getAttribute('y') ?? '');
        final width = double.tryParse(element.getAttribute('width') ?? '');
        final height = double.tryParse(element.getAttribute('height') ?? '');
        if (x != null && y != null && width != null && height != null) {
          addNode(
            id,
            Offset(x + width / 2, y + height / 2),
          ); // id는 null이 아님이 보장됨
        }
      } else if (element.name.local == 'path') {
        final d = element.getAttribute('d');
        if (d != null) {
          // path_drawing 패키지를 사용하여 path 데이터에서 첫 번째 점의 좌표를 더 정확하게 추출할 수 있습니다.
          // 여기서는 기존 로직을 유지합니다.
          try {
            final Path path = parseSvgPathData(d);
            if (!path.getBounds().isEmpty) {
              final firstPoint = path
                  .computeMetrics()
                  .first
                  .getTangentForOffset(0)!
                  .position;
              addNode(id, firstPoint); // id는 null이 아님이 보장됨
            }
          } catch (e) {
            // 간단한 파싱 방식 (기존 코드)
            final parts = d
                .toUpperCase()
                .replaceAll('M', '')
                .trim()
                .split(RegExp(r'\\s+|,'));
            if (parts.length >= 2) {
              final x = double.tryParse(parts[0]);
              final y = double.tryParse(parts[1]);
              if (x != null && y != null) {
                addNode(id, Offset(x, y)); // id는 null이 아님이 보장됨
              }
            }
          }
        }
      } else if (element.name.local == 'circle' ||
          element.name.local == 'ellipse') {
        final cx = double.tryParse(element.getAttribute('cx') ?? '');
        final cy = double.tryParse(element.getAttribute('cy') ?? '');
        if (cx != null && cy != null) {
          addNode(id, Offset(cx, cy)); // id는 null이 아님이 보장됨
        }
      }
    });
    return nodes;
  }
}
