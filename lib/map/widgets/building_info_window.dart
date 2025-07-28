// lib/map/widgets/building_info_window.dart - 내부도면보기 버튼으로 수정

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/building.dart';
import '../../generated/app_localizations.dart';
import 'package:flutter_application_1/map/widgets/directions_screen.dart';
import 'package:flutter_application_1/inside/building_map_page.dart';



bool containsExactWord(String text, String word) {
  final pattern = RegExp(r'\b' + RegExp.escape(word) + r'\b');
  return pattern.hasMatch(text);
}


String getImageForBuilding(String name) {
  final lower = name.toLowerCase();
if (lower.contains('w17-서관')) return 'lib/asset/w17-서관.jpeg';
  if (lower.contains('w17-동관')) return 'lib/asset/w17-동관.jpeg';
  if (containsExactWord(lower, 'w19')) return 'lib/asset/w19.jpeg';
  if (containsExactWord(lower, 'w18')) return 'lib/asset/w18.jpeg';
  if (containsExactWord(lower, 'w16')) return 'lib/asset/w16.jpeg';
  if (containsExactWord(lower, 'w15')) return 'lib/asset/w15.jpeg';
  if (containsExactWord(lower, 'w14')) return 'lib/asset/w14.jpeg';
  if (containsExactWord(lower, 'w13')) return 'lib/asset/w13.jpeg';
  if (containsExactWord(lower, 'w12')) return 'lib/asset/w12.jpeg';
  if (containsExactWord(lower, 'w11')) return 'lib/asset/w11.jpeg';
  if (containsExactWord(lower, 'w10')) return 'lib/asset/w10.jpeg';
  if (containsExactWord(lower, 'w9')) return 'lib/asset/w9.jpeg';
  if (containsExactWord(lower, 'w7')) return 'lib/asset/w7.jpeg';
  if (containsExactWord(lower, 'w6')) return 'lib/asset/w6.jpeg';
  if (containsExactWord(lower, 'w1')) return 'lib/asset/w1.jpeg';
  return 'error.jpg'; // 기본 이미지
}



class BuildingInfoWindow extends StatefulWidget {
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
  State<BuildingInfoWindow> createState() => _BuildingInfoWindowState();
}

class _BuildingInfoWindowState extends State<BuildingInfoWindow> {
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
  // 서버 이미지가 있으면 사용, 없으면 로컬 이미지 사용
  String? imagePath;
  bool isNetworkImage = false;
  
  if (widget.building.imageUrls != null && widget.building.imageUrls!.isNotEmpty) {
    // 서버에서 받아온 이미지 사용
    imagePath = widget.building.imageUrls![0]; // 첫 번째 이미지 사용
    isNetworkImage = true;
  } else if (widget.building.imageUrl != null && widget.building.imageUrl!.isNotEmpty) {
    // 단일 서버 이미지 사용
    imagePath = widget.building.imageUrl!;
    isNetworkImage = true;
  } else {
    // 로컬 이미지 사용
    imagePath = getImageForBuilding(widget.building.name);
    isNetworkImage = false;
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                        child: isNetworkImage
                            ? Image.network(
                                imagePath!,
                                fit: BoxFit.contain,
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.height,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.error, size: 48, color: Colors.grey),
                                        SizedBox(height: 16),
                                        Text('이미지를 불러올 수 없습니다', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : Image.asset(
                                imagePath!,
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
            child: isNetworkImage
                ? Image.network(
                    imagePath!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.error, color: Colors.grey),
                      );
                    },
                  )
                : Image.asset(
                    imagePath!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        const SizedBox(height: 12),
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
            widget.building.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        IconButton(
          onPressed: widget.onClose,
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
          '${widget.building.category} · ${l10n.woosong_university}',
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
    Color statusColor = widget.building.status == l10n.operating ? Colors.green : Colors.red;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            widget.building.status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          widget.building.hours,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
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
        print('🔘 내부도면보기 버튼 클릭됨: ${widget.building.name}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BuildingMapPage(buildingName: widget.building.name),
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
            l10n.view_floor_plan,
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
            onPressed: widget.onSetStart != null ? () async {
              print('출발지 버튼 클릭됨: ${widget.building.name}');
              print('onSetStart 콜백 존재: ${widget.onSetStart != null}');
              
              print('다이얼로그 표시 시도...');
              try {
                final result = await _showLocationSettingDialog(context, widget.building.name, '출발지');
                print('다이얼로그 결과: $result');
                
                if (result == 'room_selection') {
                  // 호실 선택하기 - 내부 도면으로 이동
                  print('호실 선택하기 선택됨');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BuildingMapPage(buildingName: widget.building.name),
                    ),
                  );
                } else if (result == 'confirm') {
                  // 확인 - 바로 출발지로 설정
                  print('확인 선택됨');
                  widget.onClose();
                  if (!context.mounted) return;
                  
                  try {
                    final directionsResult = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DirectionsScreen(presetStart: widget.building),
                      ),
                    );
                    
                    print('DirectionsScreen 결과: $directionsResult');
                    
                    if (directionsResult != null && widget.onSetStart != null) {
                      widget.onSetStart!(directionsResult);
                    }
                  } catch (e) {
                    print('DirectionsScreen 이동 실패: $e');
                  }
                } else {
                  print('취소 또는 null 결과: $result');
                }
              } catch (e) {
                print('다이얼로그 표시 실패: $e');
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
            onPressed: widget.onSetEnd != null ? () async {
              print('도착지 버튼 클릭됨: ${widget.building.name}');
              print('onSetEnd 콜백 존재: ${widget.onSetEnd != null}');
              
              print('다이얼로그 표시 시도...');
              try {
                final result = await _showLocationSettingDialog(context, widget.building.name, '도착지');
                print('다이얼로그 결과: $result');
                
                if (result == 'room_selection') {
                  // 호실 선택하기 - 내부 도면으로 이동
                  print('호실 선택하기 선택됨');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BuildingMapPage(buildingName: widget.building.name),
                    ),
                  );
                } else if (result == 'confirm') {
                  // 확인 - 바로 도착지로 설정
                  print('확인 선택됨');
                  widget.onClose();
                  if (!context.mounted) return;
                  
                  try {
                    final directionsResult = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DirectionsScreen(presetEnd: widget.building),
                      ),
                    );
                    
                    print('DirectionsScreen 결과: $directionsResult');
                    
                    if (directionsResult != null && widget.onSetEnd != null) {
                      widget.onSetEnd!(directionsResult);
                    }
                  } catch (e) {
                    print('DirectionsScreen 이동 실패: $e');
                  }
                } else {
                  print('취소 또는 null 결과: $result');
                }
              } catch (e) {
                print('다이얼로그 표시 실패: $e');
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

  /// 위치 설정 다이얼로그 표시
  Future<String?> _showLocationSettingDialog(BuildContext context, String buildingName, String locationType) {
    print('_showLocationSettingDialog 호출됨');
    print('건물명: $buildingName');
    print('위치 타입: $locationType');
    
    return Navigator.of(context).push<String>(
      PageRouteBuilder<String>(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        pageBuilder: (BuildContext context, _, __) {
          return _LocationSettingDialog(
            buildingName: buildingName,
            locationType: locationType,
          );
        },
      ),
    );
  }
}

/// 위치 설정 다이얼로그 위젯
class _LocationSettingDialog extends StatelessWidget {
  final String buildingName;
  final String locationType;

  const _LocationSettingDialog({
    required this.buildingName,
    required this.locationType,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 제목
                Row(
                  children: [
                    Icon(
                      locationType == '출발지' ? Icons.play_arrow : Icons.flag,
                      color: locationType == '출발지' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$locationType 설정',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 내용
                Text(
                  '$buildingName을 $locationType로 설정하시겠습니까?',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // 버튼들
                Row(
                  children: [
                    // 호실 선택하기 버튼
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          print('호실 선택하기 버튼 클릭됨');
                          Navigator.of(context).pop('room_selection');
                        },
                        icon: const Icon(Icons.room, size: 18),
                        label: const Text('호실 선택하기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 확인 버튼
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          print('확인 버튼 클릭됨');
                          Navigator.of(context).pop('confirm');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: locationType == '출발지' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('확인'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 취소 버튼
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          print('취소 버튼 클릭됨');
                          Navigator.of(context).pop('cancel');
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('취소'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}