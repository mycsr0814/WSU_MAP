import 'package:flutter/material.dart';
import 'package:flutter_application_1/inside/building_map_page.dart';

class BuildingFloorSheet extends StatelessWidget {
  final String buildingName;
  final List<String> floors;

  const BuildingFloorSheet({
    Key? key,
    required this.buildingName,
    required this.floors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('BuildingFloorSheet floors: $floors');
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.2,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.apartment, color: Colors.blue.shade700, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        buildingName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  '해당 건물의 층',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              if (floors.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    '층 정보가 없습니다.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade500,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: floors.length,
                    itemBuilder: (context, idx) {
                      final floor = floors[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                        child: Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Icon(Icons.layers, color: Colors.blue.shade400),
                            title: Text('${floor}층', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            onTap: () {
                              debugPrint('🏢 층 선택: ${buildingName} ${floor}층');
                              // 바텀시트 닫기
                              Navigator.pop(context);
                              // BuildingMapPage로 이동 (해당 층으로)
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BuildingMapPage(
                                    buildingName: buildingName,
                                    targetFloorNumber: int.tryParse(floor),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
} 