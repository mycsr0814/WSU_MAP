import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter_application_1/managers/location_manager.dart';
import 'package:flutter/material.dart';

class LocationResult {
  final NLatLng? location;
  final loc.PermissionStatus? permissionStatus;

  LocationResult({this.location, this.permissionStatus});
}

class LocationService {
  LocationManager? _locationManager;

  void setLocationManager(LocationManager manager) {
    _locationManager = manager;
  }

  Future<LocationResult> requestLocation() async {
    try {
      if (_locationManager == null) {
        debugPrint('LocationManager가 설정되지 않았습니다.');
        return LocationResult();
      }

      await _locationManager!.requestLocation();
      final locData = _locationManager!.currentLocation;
      final status = _locationManager!.permissionStatus;
      
      if (locData != null && locData.latitude != null && locData.longitude != null) {
        return LocationResult(
          location: NLatLng(locData.latitude!, locData.longitude!),
          permissionStatus: status,
        );
      }
      
      return LocationResult(permissionStatus: status);
    } catch (e) {
      debugPrint('위치 서비스 오류: $e');
      return LocationResult();
    }
  }
}