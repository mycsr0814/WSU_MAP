// lib/services/map/friend_location_marker_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../../friends/friend.dart';

class FriendLocationMarkerService {
  NaverMapController? _mapController;
  NOverlayImage? _friendLocationIcon;

  // 친구 위치 마커 관리
  final Map<String, NMarker> _friendLocationMarkers = {};

  /// 지도 컨트롤러 설정
  void setMapController(NaverMapController controller) {
    _mapController = controller;
    debugPrint('✅ FriendLocationMarkerService 지도 컨트롤러 설정 완료');
  }

  /// 친구 위치 마커 아이콘 로딩
  Future<void> loadMarkerIcon() async {
    try {
      _friendLocationIcon = const NOverlayImage.fromAssetImage(
        'lib/asset/people_marker_rainbow.png',
      );
      debugPrint('FriendLocationMarkerService: 친구 위치 마커 아이콘 로딩 완료');
    } catch (e) {
      debugPrint('FriendLocationMarkerService: 마커 아이콘 로딩 실패: $e');
      _friendLocationIcon = null;
    }
  }

  /// 친구 위치 마커 추가
  Future<void> addFriendLocationMarker(Friend friend) async {
    if (_mapController == null) {
      debugPrint('❌ 지도 컨트롤러가 없음');
      return;
    }

    // 친구의 위치 정보 파싱
    final location = _parseLocation(friend.lastLocation);
    if (location == null) {
      debugPrint('❌ 친구 위치 정보 파싱 실패: ${friend.lastLocation}');
      return;
    }

    try {
      // 기존 마커 제거
      await _removeFriendLocationMarker(friend.userId);

      final markerId = 'friend_location_${friend.userId}';
      final marker = NMarker(
        id: markerId,
        position: location,
        icon: _friendLocationIcon,
        caption: NOverlayCaption(
          text: friend.userName,
          color: const Color(0xFF1E3A8A),
          textSize: 14,
          haloColor: Colors.white,
        ),
        size: const Size(60, 60),
      );

      await _mapController!.addOverlay(marker);
      _friendLocationMarkers[friend.userId] = marker;

      debugPrint('✅ 친구 위치 마커 추가 완료: ${friend.userName}');

      // 마커 위치로 카메라 이동
      await _moveCameraToLocation(location);
    } catch (e) {
      debugPrint('❌ 친구 위치 마커 추가 실패: $e');
    }
  }

  /// 특정 친구의 위치 마커 제거
  Future<void> _removeFriendLocationMarker(String userId) async {
    if (_friendLocationMarkers.containsKey(userId)) {
      try {
        await _mapController!.deleteOverlay(
          _friendLocationMarkers[userId]!.info,
        );
        _friendLocationMarkers.remove(userId);
        debugPrint('친구 위치 마커 제거: $userId');
      } catch (e) {
        debugPrint('친구 위치 마커 제거 실패: $e');
      }
    }
  }

  /// 모든 친구 위치 마커 제거
  Future<void> clearAllFriendLocationMarkers() async {
    if (_mapController == null) return;

    try {
      debugPrint('모든 친구 위치 마커 제거 시작: ${_friendLocationMarkers.length}개');

      final markersToRemove = Map<String, NMarker>.from(_friendLocationMarkers);

      for (final marker in markersToRemove.values) {
        try {
          await _mapController!.deleteOverlay(marker.info);
        } catch (e) {
          // 이미 제거된 마커는 무시
        }
      }

      _friendLocationMarkers.clear();
      debugPrint('모든 친구 위치 마커 제거 완료');
    } catch (e) {
      debugPrint('친구 위치 마커 제거 중 오류: $e');
      _friendLocationMarkers.clear();
    }
  }

  /// 위치 문자열 파싱 (위도,경도 형태)
  NLatLng? _parseLocation(String locationString) {
    try {
      if (locationString.isEmpty) return null;

      // "36.3370,127.4450" 형태 또는 "lat:36.3370,lng:127.4450" 형태 처리
      final cleanLocation = locationString.replaceAll(RegExp(r'[latLng:]'), '');
      final parts = cleanLocation.split(',');

      if (parts.length >= 2) {
        final lat = double.parse(parts[0].trim());
        final lng = double.parse(parts[1].trim());
        return NLatLng(lat, lng);
      }

      return null;
    } catch (e) {
      debugPrint('위치 파싱 오류: $e');
      return null;
    }
  }

  /// 카메라를 특정 위치로 이동
  Future<void> _moveCameraToLocation(NLatLng location) async {
    try {
      final cameraUpdate = NCameraUpdate.scrollAndZoomTo(
        target: location,
        zoom: 17.0,
      );

      await _mapController!.updateCamera(cameraUpdate);
      debugPrint('✅ 친구 위치로 카메라 이동 완료');
    } catch (e) {
      debugPrint('❌ 카메라 이동 실패: $e');
    }
  }

  /// 서비스 정리
  void dispose() {
    debugPrint('🧹 FriendLocationMarkerService 정리');
    _friendLocationMarkers.clear();
    _mapController = null;
  }
}
