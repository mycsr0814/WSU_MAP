// lib/map/widgets/floor_plan_dialog.dart - 전체 페이지로 변경

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/building.dart';
import '../../generated/app_localizations.dart';

class FloorPlanDialog extends StatelessWidget {
  final Building building;

  const FloorPlanDialog({
    super.key,
    required this.building,
  });

  // 새로운 페이지로 네비게이션
  static void show(BuildContext context, Building building) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FloorPlanDialog(building: building),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black87,
            size: 24,
          ),
        ),
        title: Text(
          '${building.name} ${l10n?.floor_plan ?? '도면보기'}',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          // 도면 이미지 영역 (전체 화면)
          Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(16),
            child: _buildFloorPlanImage(building),
          ),
          
          // 왼쪽 아래 층 선택 버튼들
          Positioned(
            left: 16,
            bottom: 16,
            child: _buildFloorSelector(),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorPlanImage(Building building) {
    String imagePath = _getFloorPlanImagePath(building);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '도면 이미지를 불러올 수 없습니다',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${building.name} 내부 도면',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 예시 층별 표시 (세로로 배치)
                    Container(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: _getAvailableFloors(building).map((floor) =>
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: _buildFloorIndicator(floor, floor == '4'),
                          ),
                        ).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFloorIndicator(String floor, bool isSelected) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: isSelected ? Colors.red.shade100 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isSelected ? Colors.red.shade300 : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          floor,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.red.shade700 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  // 층 정보를 자동으로 가져와서 버튼 생성
  List<String> _getAvailableFloors(Building building) {
    // 건물별로 사용 가능한 층 정보를 반환
    // 실제로는 building 객체나 API에서 층 정보를 가져와야 함
    switch (building.name) {
      case '본관':
        return ['B1', '1', '2', '3', '4', '5'];
      case '공학관':
        return ['1', '2', '3', '4'];
      case '도서관':
        return ['1', '2', '3'];
      case '학생회관':
        return ['B1', '1', '2'];
      default:
        return ['1', '2', '3', '4']; // 기본값
    }
  }

  Widget _buildFloorSelector() {
    final availableFloors = _getAvailableFloors(building);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: availableFloors.map((floor) => 
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: _buildFloorButton(floor, isSelected: floor == '4'), // 기본 선택층
          ),
        ).toList(),
      ),
    );
  }

  Widget _buildFloorButton(String floor, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () {
        print('$floor층 선택됨');
        // 층 선택 로직 추가 - 여기서 해당 층의 도면을 로드
      },
      child: Container(
        width: 50,
        height: 50,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.red.shade300 : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.red.shade200,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Center(
          child: Text(
            floor,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.red.shade700 : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  // 건물별 도면 이미지 경로 반환
  static String _getFloorPlanImagePath(Building building) {
    switch (building.name) {
      case '본관':
        return 'assets/W19_1.svg';
      case '공학관':
        return 'assets/W19_2.svg';
      case '도서관':
        return 'assets/W19_3.svg';
      default:
        return 'assets/W19_1.svg';
    }
  }
}