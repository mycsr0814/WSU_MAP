class RoomInfo {
  final String id;
  final String name;
  final String desc;
  final List<String> users;
  final List<String>? phones;
  final List<String>? emails;

  RoomInfo({
    required this.id,
    required this.name,
    required this.desc,
    required this.users,
    this.phones,
    this.emails,
  });

  factory RoomInfo.fromJson(Map<String, dynamic> json) {
    return RoomInfo(
      id: json['Room_Name'] ?? '', // 또는 다른 ID 필드
      name: json['Room_Name'] ?? '',
      desc: json['Room_Description'] ?? '',
      users: _parseStringList(json['Room_User']),
      phones: _parseStringListNullable(json['User_Phone']),
      emails: _parseStringListNullable(json['User_Email']),
    );
  }

  // null이나 빈 문자열을 필터링하는 헬퍼 메서드
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .where((item) => item != null && item.toString().trim().isNotEmpty)
          .map((item) => item.toString().trim())
          .toList();
    }
    return [];
  }

  static List<String>? _parseStringListNullable(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      final filtered = value
          .where((item) => item != null && item.toString().trim().isNotEmpty)
          .map((item) => item.toString().trim())
          .toList();
      return filtered.isEmpty ? null : filtered;
    }
    return null;
  }
}