// lib/config/api_config.dart
class ApiConfig {
  static const String baseHost = 'http://52.63.165.133';
  static const int buildingPort = 3000;
  static const int userPort = 3001;

  static String get buildingBase => '$baseHost:$buildingPort/building';
  static String get categoryBase => '$baseHost:$buildingPort/category';
  static String get pathBase => '$baseHost:$buildingPort';
  static String get userBase => '$baseHost:$userPort/user';
  static String get friendBase => '$baseHost:$userPort/friend';
  static String get timetableBase => '$baseHost:$userPort/timetable';
  static String get floorBase => '$baseHost:$buildingPort/floor';
  static String get roomBase => '$baseHost:$buildingPort/room';
}
