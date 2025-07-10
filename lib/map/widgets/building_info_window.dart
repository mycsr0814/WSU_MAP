// lib/map/widgets/building_info_window.dart - 내부도면보기 버튼으로 수정

import 'package:flutter/material.dart';
import 'package:flutter_application_1/map/widgets/floor_plan_dialog.dart';
import 'package:flutter_application_1/models/building.dart';
import '../../generated/app_localizations.dart';
import 'package:flutter_application_1/map/widgets/directions_screen.dart';
import 'package:flutter_application_1/inside/building_map_page.dart';



String getImageForBuilding(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('w1')) return 'lib/asset/w1.jpeg';
  if (lower.contains('w6')) return 'lib/asset/w6.jpeg';
  if (lower.contains('w7')) return 'lib/asset/w7.jpeg';
  if (lower.contains('w9')) return 'lib/asset/w9.jpeg';
  if (lower.contains('w10')) return 'lib/asset/w10.jpeg';
  if (lower.contains('w11')) return 'lib/asset/w11.jpeg';
  if (lower.contains('w12')) return 'lib/asset/w12.jpeg';
  if (lower.contains('w13')) return 'lib/asset/w13.jpeg';
  if (lower.contains('w14')) return 'lib/asset/w14.jpeg';
  if (lower.contains('w15')) return 'lib/asset/w15.jpeg';
  if (lower.contains('w16')) return 'lib/asset/w16.jpeg';
  if (lower.contains('w17-서관')) return 'lib/asset/w17-서관.png';
  if (lower.contains('w18')) return 'lib/asset/w18.jpeg';
  if (lower.contains('w19')) return 'lib/asset/w19.jpeg';
  
  return 'error.jpg'; // 기본 이미지
}


class BuildingInfoWindow extends StatelessWidget {
  final Building building;
  final VoidCallback onClose;
  final Function(Building) onShowDetails;
  final Function(dynamic)? onSetStart; // Building에서 dynamic으로 변경
  final Function(dynamic)? onSetEnd;   // Building에서 dynamic으로 변경
  final Function(Building)? onShowFloorPlan;

  const BuildingInfoWindow({
    super.key,
    required this.building,
    required this.onClose,
    required this.onShowDetails,
    this.onSetStart,
    this.onSetEnd,
    this.onShowFloorPlan,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDragHandle(),
              _buildContent(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

Widget _buildContent(BuildContext context, AppLocalizations l10n) {
  final imagePath = getImageForBuilding(building.name);
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 이미지 썸네일 + 클릭 시 모달로 원본 보기
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (_) => Dialog(
                insetPadding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                child: Stack(
                  children: [
                    Center(
                      child: InteractiveViewer(
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 32,
                      right: 32,
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.white, size: 32),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              imagePath,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 이하 기존 코드 유지
        _buildHeader(),
        const SizedBox(height: 12),
        _buildLocationInfo(l10n),
        const SizedBox(height: 16),
        _buildStatusAndHours(l10n),
        const SizedBox(height: 20),
        _buildActionIcons(l10n),
        const SizedBox(height: 20),
        _buildFloorPlanButton(l10n, context),
        const SizedBox(height: 16),
        _buildActionButtons(l10n, context),
        const SizedBox(height: 20),
      ],
    ),
  );
}





  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            building.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(
            Icons.close,
            color: Colors.grey,
            size: 24,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildLocationInfo(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${building.category} · ${l10n.woosong_university}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 16,
              color: Colors.grey.shade500,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '대전 동구 동대전로 171 ${l10n.woosong_university}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusAndHours(AppLocalizations l10n) {
    Color statusColor = building.status == l10n.operating ? Colors.green : Colors.red;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            building.status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          building.hours,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => onShowDetails(building),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            l10n.building_details,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcons(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionIcon(
          icon: Icons.local_parking_outlined,
          label: l10n.parking,
          onTap: () {},
        ),
        _buildActionIcon(
          icon: Icons.accessible_outlined,
          label: l10n.accessibility,
          onTap: () {},
        ),
        _buildActionIcon(
          icon: Icons.business_outlined,
          label: l10n.facilities,
          onTap: () {},
        ),
        _buildActionIcon(
          icon: Icons.elevator_outlined,
          label: l10n.elevator,
          onTap: () {},
        ),
        _buildActionIcon(
          icon: Icons.wc_outlined,
          label: l10n.restroom,
          onTap: () {},
        ),
      ],
    );
  }

 Widget _buildActionIcon({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(  // 이 부분이 누락되었을 수 있습니다
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: Colors.indigo.shade400,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    ),
  );
}


  // 내부도면보기 버튼으로 변경
  Widget _buildFloorPlanButton(AppLocalizations l10n, BuildContext context) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      onPressed: () {
        print('🔘 내부도면보기 버튼 클릭됨: ${building.name}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BuildingMapPage(buildingName: building.name),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 20),
          const SizedBox(width: 8),
          Text(
            l10n.view_floor_plan ?? '내부도면보기',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}



 Widget _buildActionButtons(AppLocalizations l10n, BuildContext context) {
  return Row(
    children: [
      // 출발 버튼
      Expanded(
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: onSetStart != null ? () async {
              debugPrint('출발지 버튼 클릭됨: ${building.name}');
              
              // InfoWindow 먼저 닫기
              onClose();
              
              if (!context.mounted) return;
              
              // DirectionsScreen으로 이동하고 결과 받기
              try {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DirectionsScreen(presetStart: building),
                  ),
                );
                
                debugPrint('DirectionsScreen 결과: $result');
                
                // 결과가 있으면 onSetStart 콜백 호출하여 상위로 전달
                if (result != null && onSetStart != null) {
                  // 실제 onSetStart 콜백 호출 (map_screen으로 데이터 전달)
                  onSetStart!(result);
                }
              } catch (e) {
                debugPrint('DirectionsScreen 이동 실패: $e');
              }
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_arrow, size: 18),
                const SizedBox(width: 6),
                Text(
                  l10n.departure,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      // 도착 버튼
      Expanded(
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: onSetEnd != null ? () async {
              debugPrint('도착지 버튼 클릭됨: ${building.name}');
              
              // InfoWindow 먼저 닫기
              onClose();
              
              if (!context.mounted) return;
              
              // DirectionsScreen으로 이동하고 결과 받기
              try {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DirectionsScreen(presetEnd: building),
                  ),
                );
                
                debugPrint('DirectionsScreen 결과: $result');
                
                // 결과가 있으면 onSetEnd 콜백 호출하여 상위로 전달
                if (result != null && onSetEnd != null) {
                  // 실제 onSetEnd 콜백 호출 (map_screen으로 데이터 전달)
                  onSetEnd!(result);
                }
              } catch (e) {
                debugPrint('DirectionsScreen 이동 실패: $e');
              }
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flag, size: 18),
                const SizedBox(width: 6),
                Text(
                  l10n.destination,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
}