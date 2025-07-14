// lib/inside/path_models.dart (새로 만드는 파일)

/// API 응답 전체를 감싸는 최상위 모델 클래스
class PathResponse {
  final String type;
  final PathResult? result;

  PathResponse({required this.type, this.result});

  /// JSON 데이터를 PathResponse 객체로 변환하는 팩토리 생성자
  factory PathResponse.fromJson(Map<String, dynamic> json) {
    return PathResponse(
      type: json['type'],
      result: json['result'] != null ? PathResult.fromJson(json['result']) : null,
    );
  }
}

/// "result" 필드에 해당하는 모델 클래스
class PathResult {
  final IndoorPath? departureIndoor;
  final OutdoorPath? outdoor;
  final IndoorPath? arrivalIndoor;

  PathResult({this.departureIndoor, this.outdoor, this.arrivalIndoor});

  factory PathResult.fromJson(Map<String, dynamic> json) {
    return PathResult(
      departureIndoor: json['departure_indoor'] != null
          ? IndoorPath.fromJson(json['departure_indoor'])
          : null,
      outdoor: json['outdoor'] != null ? OutdoorPath.fromJson(json['outdoor']) : null,
      arrivalIndoor: json['arrival_indoor'] != null
          ? IndoorPath.fromJson(json['arrival_indoor'])
          : null,
    );
  }
}

/// 실내 경로(Indoor) 정보를 담는 모델 클래스
class IndoorPath {
  final PathInfo path;

  IndoorPath({required this.path});

  factory IndoorPath.fromJson(Map<String, dynamic> json) {
    return IndoorPath(
      path: PathInfo.fromJson(json['path']),
    );
  }
}

/// 실외 경로(Outdoor) 정보를 담는 모델 클래스
class OutdoorPath {
  final PathInfo path;

  OutdoorPath({required this.path});

  factory OutdoorPath.fromJson(Map<String, dynamic> json) {
    return OutdoorPath(
      path: PathInfo.fromJson(json['path']),
    );
  }
}

/// 경로의 거리(distance)와 실제 노드 리스트(path)를 담는 모델 클래스
class PathInfo {
  final double distance;
  final List<IndoorPathNode> path; // 실내 경로는 ID 리스트를 담습니다.

  PathInfo({required this.distance, required this.path});

  factory PathInfo.fromJson(Map<String, dynamic> json) {
    var pathList = json['path'] as List;
    List<IndoorPathNode> nodes = pathList.map((i) => IndoorPathNode.fromJson(i)).toList();
    return PathInfo(
      distance: (json['distance'] as num).toDouble(),
      path: nodes,
    );
  }
}

/// 실내 경로를 구성하는 각 노드의 ID 정보를 담는 모델 클래스
/// API가 좌표가 아닌 ID를 반환하므로, 이를 담기 위해 사용합니다.
class IndoorPathNode {
  final String id; // 예: "R101@2" 또는 "NODE5@2"
  final String? name; // "계단" 등의 추가 정보를 위해 유지

  IndoorPathNode({required this.id, this.name});

  /// API 응답의 경로 리스트 요소가 단순 문자열("R101@2")일 경우를 처리합니다.
  factory IndoorPathNode.fromJson(dynamic json) {
    if (json is String) {
      return IndoorPathNode(id: json, name: json.contains('계단') ? '계단' : null);
    }
    // 만약 API가 {"id": "...", "name": "..."} 객체 형태라면 이 로직이 사용됩니다.
    return IndoorPathNode(id: json['id'], name: json['name']);
  }
}
