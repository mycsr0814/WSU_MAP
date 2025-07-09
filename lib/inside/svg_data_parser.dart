// lib/svg_data_parser.dart (병합된 최종 코드)

import 'dart:ui';
import 'package:xml/xml.dart';

class SvgDataParser {
  /// SVG에서 클릭 가능한 영역('rect' 태그)을 파싱하여 버튼 데이터를 추출합니다.
  /// 이 메서드는 UI에서 사용자의 터치 영역을 감지하는 데 사용됩니다. (Rect 객체 반환)
  static List<Map<String, dynamic>> parseButtonData(String svgContent) {
    final List<Map<String, dynamic>> buttons = [];
    final document = XmlDocument.parse(svgContent);

    final rects = document.findAllElements('rect');
    for (var rect in rects) {
      // [개선] Inkscape의 'label' 속성을 먼저 확인하고, 없으면 'id' 속성을 사용합니다.
      String? id = rect.getAttribute('inkscape:label');
      id ??= rect.getAttribute('id');

      if (id != null) {
        // [개선] 첫 번째 파일의 유연한 ID 조건('R'로 시작하거나 숫자인 경우)을 적용하여
        // 강의실('R101')과 숫자 ID('1', '2'...)를 모두 버튼으로 인식합니다.
        final isRoom = id.startsWith('R');
        final isNumericId = int.tryParse(id) != null;

        if (isRoom || isNumericId) {
          final x = double.tryParse(rect.getAttribute('x') ?? '');
          final y = double.tryParse(rect.getAttribute('y') ?? '');
          final width = double.tryParse(rect.getAttribute('width') ?? '');
          final height = double.tryParse(rect.getAttribute('height') ?? '');
          
          if (x != null && y != null && width != null && height != null) {
            buttons.add({
              'id': id,
              'rect': Rect.fromLTWH(x, y, width, height),
            });
          }
        }
      }
    }
    return buttons;
  }

  /// SVG의 모든 노드(rect, path, circle 등)를 파싱하여 길찾기 및 위치 표시에 사용할 좌표 맵을 생성합니다.
  /// 이 메서드는 길찾기 그래프를 구성하는 데 사용됩니다. (Offset 객체 반환)
  static Map<String, Offset> parseAllNodes(String svgContent) {
    final Map<String, Offset> nodes = {};
    final document = XmlDocument.parse(svgContent);

    // Helper: 노드 ID와 좌표를 맵에 추가하는 내부 함수
    void addNode(String id, Offset offset) {
      // 'R'로 시작하는 강의실 ID의 경우, 'R'을 제거하여 다른 데이터와 일치시키기 용이하게 만듭니다. (예: 'R101' -> '101')
      // 이 로직이 필요 없다면 `nodes[id] = offset;` 으로 간단히 수정할 수 있습니다.
      if (id.startsWith('R')) {
        nodes[id.substring(1)] = offset;
      } else {
        nodes[id] = offset;
      }
    }

    // [핵심 개선] SVG 내의 모든 요소를 한 번만 순회하여 효율적으로 파싱합니다.
    document.descendants.whereType<XmlElement>().forEach((element) {
      // [핵심 개선] Inkscape의 'label' 속성을 먼저 확인하고, 없으면 'id'를 사용합니다.
      String? id = element.getAttribute('inkscape:label');
      id ??= element.getAttribute('id');

      if (id == null) return; // ID가 없으면 처리하지 않음

      // 태그 종류에 따라 좌표 추출
      if (element.name.local == 'rect') {
        final x = double.tryParse(element.getAttribute('x') ?? '');
        final y = double.tryParse(element.getAttribute('y') ?? '');
        final width = double.tryParse(element.getAttribute('width') ?? '');
        final height = double.tryParse(element.getAttribute('height') ?? '');
        if (x != null && y != null && width != null && height != null) {
          // 사각형의 중심점을 노드 좌표로 사용
          addNode(id, Offset(x + width / 2, y + height / 2));
        }
      } else if (element.name.local == 'path') {
        final d = element.getAttribute('d');
        if (d != null) {
          // 'd' 속성에서 이동(Move) 좌표 'M x y'를 추출
          final parts = d.replaceAll('M', '').trim().split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            final x = double.tryParse(parts[0]);
            final y = double.tryParse(parts[1]);
            if (x != null && y != null) {
              addNode(id, Offset(x, y));
            }
          }
        }
      } else if (element.name.local == 'circle' || element.name.local == 'ellipse') {
        final cx = double.tryParse(element.getAttribute('cx') ?? '');
        final cy = double.tryParse(element.getAttribute('cy') ?? '');
        if (cx != null && cy != null) {
          // 원의 중심점을 노드 좌표로 사용
          addNode(id, Offset(cx, cy));
        }
      }
    });

    return nodes;
  }
}
