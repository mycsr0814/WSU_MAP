// lib/config/api_config.dart
class ApiConfig {
  static const String baseHost = 'http://16.176.5.144';
  static const int buildingPort = 3000;
  static const int userPort = 3001;

  static String get buildingBase => '$baseHost:$buildingPort/building';
  static String get categoryBase => '$baseHost:$buildingPort/category';
  static String get pathBase => '$baseHost:$buildingPort';
  static String get userBase => '$baseHost:$userPort/user';
  static String get friendBase => '$baseHost:$userPort/friend';
  static String get timetableBase =>
      '$baseHost:$userPort/timetable'; // 시간표 CRUD
  static String get timetableUploadUrl =>
      '$baseHost:$userPort/timetable/upload'; // 엑셀 업로드
  static String get timetableUploadBase => '$baseHost:$userPort/timetable';
  static String get floorBase => '$baseHost:$buildingPort/floor';
  static String get roomBase => '$baseHost:$buildingPort/room';
}
