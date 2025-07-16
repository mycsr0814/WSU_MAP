// lib/config/api_config.dart
class ApiConfig {
  static const String baseHost = 'http://3.27.162.178';
  static const int buildingPort = 3000;
  static const int userPort = 3001;

  static String get buildingBase => '$baseHost:$buildingPort/building';
  static String get categoryBase => '$baseHost:$buildingPort/category';
  static String get pathBase => '$baseHost:$buildingPort';
  static String get userBase => '$baseHost:$userPort/user';
  static String get friendBase => '$baseHost:$userPort/friend';
}
