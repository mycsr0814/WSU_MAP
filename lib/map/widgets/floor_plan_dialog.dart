// lib/map/widgets/floor_plan_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/building.dart';
import 'package:flutter_application_1/inside/building_map_page.dart';
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
          // 상세 안내도 페이지로 이동하는 버튼만 제공
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.map, size: 80, color: Colors.indigo),
                const SizedBox(height: 24),
                Text(
                  '${building.name} 안내도',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('상세 안내도 보기', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 56),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    // building.name을 BuildingMapPage에 넘김
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BuildingMapPage(buildingName: building.name),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
