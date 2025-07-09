import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/building.dart';
import 'package:flutter_application_1/inside/building_map_page.dart';
import '../../generated/app_localizations.dart';

/// 건물 도면(안내도) 페이지로 자동 이동하는 다이얼로그 위젯
class FloorPlanDialog extends StatelessWidget {
  final Building building; // 표시할 건물 정보

  const FloorPlanDialog({
    super.key,
    required this.building,
  });

  // 기존 show 함수는 그대로 사용 가능 (다른 곳에서 FloorPlanDialog.show(context, building) 호출)

  @override
  Widget build(BuildContext context) {
    // build가 호출된 직후(BuildContext가 완전히 준비된 뒤)에
    // BuildingMapPage로 바로 이동시킨다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BuildingMapPage(buildingName: building.name),
        ),
      );
    });

    // 로딩 중 UI를 위한 지역화 객체
    final l10n = AppLocalizations.of(context);

    // 실제로는 곧바로 BuildingMapPage로 이동하지만,
    // 이동 전 잠깐 보여줄 로딩 스피너와 상단바를 구성한다.
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context), // 뒤로가기 버튼
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black87,
            size: 24,
          ),
        ),
        title: Text(
          '${building.name} ${l10n?.floor_plan ?? '도면보기'}', // 건물명 + "도면보기" (지역화 지원)
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: const Center(
        child: CircularProgressIndicator(), // 이동 전 잠깐 보여줄 로딩 인디케이터
      ),
    );
  }
}
