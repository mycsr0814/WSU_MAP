import 'package:flutter/material.dart';
import 'room_info.dart';

/// 강의실(방) 정보와 출발/도착 버튼을 표시하는 하단 시트 위젯
class RoomInfoSheet extends StatelessWidget {
  final RoomInfo roomInfo;        // 방 정보(이름, 설명 등)
  final VoidCallback? onDeparture; // 출발지로 버튼 콜백 (null이면 버튼 안 보임)
  final VoidCallback? onArrival;   // 도착지로 버튼 콜백 (null이면 버튼 안 보임)
  final String? buildingName;      // 🔥 추가: 건물명
  final dynamic floorNumber;       // 🔥 수정: dynamic 타입으로 변경

  const RoomInfoSheet({
    Key? key,
    required this.roomInfo,
    this.onDeparture,
    this.onArrival,
    this.buildingName,  // 🔥 추가
    this.floorNumber,   // 🔥 추가
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // 하단 시트 스타일: 흰 배경, 위쪽만 둥근 모서리
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 방 이름
          Text(
            roomInfo.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // 방 설명
          Text(
            roomInfo.desc,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // 출발지 버튼
              if (onDeparture != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        // 🔥 디버깅 정보 추가
                        print('=== 출발지 버튼 클릭 ===');
                        print('roomInfo.id: ${roomInfo.id}');
                        print('roomInfo.name: ${roomInfo.name}');
                        print('buildingName: $buildingName');
                        print('floorNumber: $floorNumber (타입: ${floorNumber.runtimeType})');
                        
                        // 🔥 수정: DirectionsScreen으로 방 정보 전달
                        final roomData = {
                          'roomId': roomInfo.id,
                          'roomName': roomInfo.name,
                          'buildingName': buildingName ?? '',
                          'floorNumber': floorNumber?.toString() ?? '', // 🔥 수정: 안전하게 String으로 변환
                          'type': 'start', // 출발지임을 표시
                        };
                        
                        print('전달할 roomData: $roomData');
                        
                        // 현재 모달 닫기
                        Navigator.pop(context);
                        
                        // DirectionsScreen으로 이동하면서 방 정보 전달
                        Navigator.pushNamed(
                          context, 
                          '/directions',
                          arguments: roomData,
                        );
                      } catch (e, stackTrace) {
                        print('❌ 출발지 버튼 오류: $e');
                        print('스택 트레이스: $stackTrace');
                        
                        // 에러 발생 시 사용자에게 알림
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('오류가 발생했습니다: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('출발지'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981), // 초록색 배경
                      foregroundColor: Colors.white,            // 흰색 글자/아이콘
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              if (onDeparture != null && onArrival != null)
                const SizedBox(width: 8),
              // 도착지 버튼
              if (onArrival != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        // 🔥 디버깅 정보 추가
                        print('=== 도착지 버튼 클릭 ===');
                        print('roomInfo.id: ${roomInfo.id}');
                        print('roomInfo.name: ${roomInfo.name}');
                        print('buildingName: $buildingName');
                        print('floorNumber: $floorNumber (타입: ${floorNumber.runtimeType})');
                        
                        // 🔥 수정: DirectionsScreen으로 방 정보 전달
                        final roomData = {
                          'roomId': roomInfo.id,
                          'roomName': roomInfo.name,
                          'buildingName': buildingName ?? '',
                          'floorNumber': floorNumber?.toString() ?? '', // 🔥 수정: 안전하게 String으로 변환
                          'type': 'end', // 도착지임을 표시
                        };
                        
                        print('전달할 roomData: $roomData');
                        
                        // 현재 모달 닫기
                        Navigator.pop(context);
                        
                        // DirectionsScreen으로 이동하면서 방 정보 전달
                        Navigator.pushNamed(
                          context, 
                          '/directions',
                          arguments: roomData,
                        );
                      } catch (e, stackTrace) {
                        print('❌ 도착지 버튼 오류: $e');
                        print('스택 트레이스: $stackTrace');
                        
                        // 에러 발생 시 사용자에게 알림
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('오류가 발생했습니다: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.flag, size: 18),
                    label: const Text('도착지'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444), // 빨간색 배경
                      foregroundColor: Colors.white,            // 흰색 글자/아이콘
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}