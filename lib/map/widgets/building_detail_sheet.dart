// building_detail_sheet.dart - 개선된 버전

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/building.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:convert';

class BuildingDetailSheet extends StatelessWidget {
  final Building building;

  const BuildingDetailSheet({
    super.key,
    required this.building,
  });

  static void show(BuildContext context, Building building) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => BuildingDetailSheet(building: building),
    );
  }

  @override
  Widget build(BuildContext context) {
    final floorInfos = _parseFloorInfo(building.info);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHandle(),
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 24),
              _buildFloorList(context, floorInfos, controller),
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 서버 연결 테스트 함수
  Future<void> _testServerConnection(BuildContext context, String floor) async {
    final floorNumber = _extractFloorNumber(floor);
    final buildingCode = _extractBuildingCode(building.name);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('서버 연결 테스트'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('서버 연결을 확인하는 중...'),
          ],
        ),
      ),
    );

    try {
      // 1단계: 기본 서버 연결 테스트
      debugPrint('🔍 1단계: 기본 서버 연결 테스트');
      final baseResponse = await http.get(
        Uri.parse('http://13.55.76.216:3000/'),
      ).timeout(const Duration(seconds: 5));
      
      debugPrint('✅ 기본 서버 응답: ${baseResponse.statusCode}');

      // 2단계: 특정 도면 URL 테스트
      final testUrl = 'http://13.55.76.216:3000/floor/$floorNumber/$buildingCode';
      debugPrint('🔍 2단계: 도면 URL 테스트 - $testUrl');
      
      final response = await http.head(Uri.parse(testUrl)).timeout(const Duration(seconds: 5));
      debugPrint('✅ 도면 URL 응답: ${response.statusCode}');
      debugPrint('📋 헤더 정보: ${response.headers}');

      if (context.mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('연결 테스트 결과'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🌐 서버 기본 연결: ${baseResponse.statusCode == 200 ? "성공" : "실패 (${baseResponse.statusCode})"}'),
                  const SizedBox(height: 8),
                  Text('🎯 도면 URL 상태: ${response.statusCode}'),
                  const SizedBox(height: 8),
                  Text('📍 요청 URL: $testUrl'),
                  const SizedBox(height: 8),
                  Text('📋 Content-Type: ${response.headers['content-type'] ?? "없음"}'),
                  const SizedBox(height: 8),
                  Text('📦 Content-Length: ${response.headers['content-length'] ?? "없음"}'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('해석:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        if (response.statusCode == 200)
                          Text('✅ 도면이 존재합니다. 정상적으로 로드되어야 합니다.', style: TextStyle(color: Colors.green))
                        else if (response.statusCode == 404)
                          Text('❌ 해당 층의 도면이 서버에 없습니다.', style: TextStyle(color: Colors.red))
                        else
                          Text('⚠️ 서버 오류가 발생했습니다. (${response.statusCode})', style: TextStyle(color: Colors.orange)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
              if (response.statusCode == 200)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showFloorPlan(context, floor, '');
                  },
                  child: const Text('도면 다시 시도'),
                ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ 연결 테스트 실패: $e');
      if (context.mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('연결 테스트 실패'),
            content: Text('서버에 연결할 수 없습니다.\n\n오류: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    }
  }

  // 층 정보 파싱 개선
  List<Map<String, String>> _parseFloorInfo(String info) {
    final floorInfos = <Map<String, String>>[];
    final lines = info.split('\n');
    
    for (String line in lines) {
      if (line.trim().isEmpty) continue;
      
      final parts = line.split('\t');
      if (parts.length >= 2) {
        floorInfos.add({
          'floor': parts[0].trim(),
          'detail': parts[1].trim(),
        });
      } else if (parts.length == 1 && parts[0].trim().isNotEmpty) {
        // 탭이 없는 경우도 처리
        floorInfos.add({
          'floor': parts[0].trim(),
          'detail': '',
        });
      }
    }
    
    // 층 정렬 (지하층을 아래로, 일반층을 위로)
    floorInfos.sort((a, b) {
      final floorA = a['floor']!;
      final floorB = b['floor']!;
      
      final numA = _extractFloorNumber(floorA);
      final numB = _extractFloorNumber(floorB);
      
      // 지하층과 일반층 구분
      final isBasementA = floorA.toUpperCase().startsWith('B');
      final isBasementB = floorB.toUpperCase().startsWith('B');
      
      if (isBasementA && !isBasementB) return -1;
      if (!isBasementA && isBasementB) return 1;
      
      if (isBasementA && isBasementB) {
        // 지하층끼리는 숫자가 큰 것이 아래 (B2가 B1보다 아래)
        return int.tryParse(numB)?.compareTo(int.tryParse(numA) ?? 0) ?? 0;
      } else {
        // 일반층끼리는 숫자가 작은 것이 아래
        return int.tryParse(numA)?.compareTo(int.tryParse(numB) ?? 0) ?? 0;
      }
    });
    
    return floorInfos;
  }

  Widget _buildHandle() {
    return Container(
      width: 50,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.apartment,
                color: Colors.blue.shade700,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    building.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${building.category} • 우송대학교',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.indigo.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '층별 도면 보기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '각 층을 선택하여 상세 도면을 확인하세요',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloorList(
    BuildContext context,
    List<Map<String, String>> floorInfos,
    ScrollController controller,
  ) {
    if (floorInfos.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                '층 정보가 없습니다',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        controller: controller,
        itemCount: floorInfos.length,
        itemBuilder: (context, index) {
          final floorInfo = floorInfos[index];
          final floor = floorInfo['floor']!;
          final detail = floorInfo['detail']!;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildFloorCard(context, floor, detail),
          );
        },
      ),
    );
  }

  Widget _buildFloorCard(BuildContext context, String floor, String detail) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showFloorDetail(context, floor, detail),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade400, Colors.blue.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.shade200,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.layers,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        floor,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (detail.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          detail,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '도면보기',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.architecture,
                        size: 12,
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFloorDetail(BuildContext context, String floor, String detail) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade600, Colors.blue.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$floor 정보',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            building.name,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              // 컨텐츠
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 층 정보
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.apartment,
                                  color: Colors.indigo.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '층 정보',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.indigo.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              detail.isNotEmpty ? detail : '상세 정보가 없습니다.',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 도면 보기 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // 현재 다이얼로그 닫기
                            _showFloorPlan(context, floor, detail); // 도면 보기
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade600,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.architecture, size: 22),
                          label: const Text(
                            '층 도면 보기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 🆕 디버그 테스트 버튼 추가
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _testServerConnection(context, floor);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.bug_report, size: 18),
                          label: const Text(
                            '연결 테스트',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFloorPlan(BuildContext context, String floor, String detail) async {
    final floorNumber = _extractFloorNumber(floor);
    final buildingCode = _extractBuildingCode(building.name);
    final apiUrl = 'http://13.55.76.216:3000/floor/$floorNumber/$buildingCode';
    
    debugPrint('🚀 도면 로딩 시작');
    debugPrint('📍 층: $floor → $floorNumber');
    debugPrint('🏢 건물: ${building.name} → $buildingCode');
    debugPrint('🌐 API URL: $apiUrl');

    // 로딩 다이얼로그 표시 (더 빠른 취소 가능)
    bool isLoading = true;
    DateTime startTime = DateTime.now();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Container(
          color: Colors.black54,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    '$floor 도면을 불러오는 중...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '서버: $buildingCode/$floorNumber',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 🆕 실시간 타이머 추가
                  StreamBuilder<int>(
                    stream: Stream.periodic(const Duration(seconds: 1), (i) => i + 1),
                    builder: (context, snapshot) {
                      final seconds = snapshot.data ?? 0;
                      return Text(
                        '경과 시간: $seconds초',
                        style: TextStyle(
                          fontSize: 11,
                          color: seconds > 5 ? Colors.red : Colors.grey.shade500,
                          fontWeight: seconds > 5 ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // 취소 버튼 (5초 후 더 눈에 띄게)
                  ElevatedButton(
                    onPressed: () {
                      if (context.mounted && isLoading) {
                        Navigator.pop(context);
                        isLoading = false;
                        debugPrint('⏹️ 사용자가 로딩을 취소함');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('취소'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      debugPrint('🌐 HTTP 요청 시작: $apiUrl');
      final requestStartTime = DateTime.now();
      
      // 🆕 청크 단위로 데이터 수신 (스트리밍 방식)
      final request = http.Request('GET', Uri.parse(apiUrl));
      request.headers.addAll({
        'Accept': 'image/*',
        'User-Agent': 'Flutter-App/1.0',
        'Cache-Control': 'no-cache',
        'Connection': 'close',
        'Accept-Encoding': 'identity', // 압축 비활성화
      });
      
      debugPrint('📤 요청 헤더: ${request.headers}');
      
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          final elapsed = DateTime.now().difference(requestStartTime).inSeconds;
          debugPrint('⏰ 스트림 요청 타임아웃 ($elapsed초 경과)');
          throw Exception('서버 응답 시간 초과 (10초)\n스트리밍 요청이 실패했습니다.');
        },
      );
      
      debugPrint('📡 스트림 응답 시작 - 상태: ${streamedResponse.statusCode}');
      debugPrint('📡 응답 헤더: ${streamedResponse.headers}');
      
      if (streamedResponse.statusCode != 200) {
        final responseTime = DateTime.now().difference(requestStartTime).inMilliseconds;
        debugPrint('❌ HTTP 오류: ${streamedResponse.statusCode} (${responseTime}ms)');
        
        // 로딩 다이얼로그 닫기
        if (context.mounted && isLoading) {
          Navigator.pop(context);
          isLoading = false;
        }
        
        if (context.mounted) {
          _showErrorDialog(context, 'HTTP 오류가 발생했습니다.\n\n'
              '상태 코드: ${streamedResponse.statusCode}\n'
              'URL: $apiUrl\n'
              '응답 시간: ${responseTime}ms');
        }
        return;
      }
      
      // 🆕 스트림에서 바이트 데이터 수집
      final bytes = <int>[];
      int receivedBytes = 0;
      final contentLength = int.tryParse(streamedResponse.headers['content-length'] ?? '0') ?? 0;
      
      debugPrint('📦 예상 파일 크기: $contentLength bytes (${(contentLength / 1024).toStringAsFixed(1)} KB)');
      
      await for (List<int> chunk in streamedResponse.stream) {
        bytes.addAll(chunk);
        receivedBytes += chunk.length;
        
        // 진행률 로깅 (10KB마다)
        if (receivedBytes % 10240 == 0 || receivedBytes == contentLength) {
          final progress = contentLength > 0 ? (receivedBytes / contentLength * 100) : 0;
          debugPrint('📥 수신 중: $receivedBytes/$contentLength bytes (${progress.toStringAsFixed(1)}%)');
        }
      }
      
      final responseTime = DateTime.now().difference(requestStartTime).inMilliseconds;
      debugPrint('📊 스트림 완료 (${responseTime}ms)');
      debugPrint('📊 총 수신: ${bytes.length} bytes');
      
      // Uint8List로 변환
      final response = http.Response.bytes(Uint8List.fromList(bytes), streamedResponse.statusCode, 
          headers: streamedResponse.headers);

      // 🆕 응답 속도 분석
      if (responseTime > 5000) {
        debugPrint('🐌 느린 응답: ${responseTime}ms (5초 이상)');
      } else if (responseTime > 2000) {
        debugPrint('⚠️ 보통 응답: ${responseTime}ms (2-5초)');
      } else {
        debugPrint('⚡ 빠른 응답: ${responseTime}ms (2초 미만)');
      }

      // 로딩 다이얼로그 닫기
      if (context.mounted && isLoading) {
        Navigator.pop(context);
        isLoading = false;
      }

      if (response.statusCode == 200) {
        if (response.bodyBytes.isEmpty) {
          debugPrint('❌ 응답 데이터가 비어있음');
          if (context.mounted) {
            _showErrorDialog(context, '서버에서 빈 응답을 받았습니다.\n해당 층의 도면이 없을 수 있습니다.');
          }
          return;
        }

        // 🆕 파일 크기 체크
        final sizeInKB = response.bodyBytes.length / 1024;
        debugPrint('📏 실제 파일 크기: ${sizeInKB.toStringAsFixed(1)} KB');
        
        // 🆕 이미지 헤더 검증 (PNG/JPEG 매직 바이트)
        bool isValidImage = false;
        if (response.bodyBytes.length >= 8) {
          final header = response.bodyBytes.take(8).toList();
          // PNG: 89 50 4E 47 0D 0A 1A 0A
          if (header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47) {
            debugPrint('✅ 유효한 PNG 파일 확인');
            isValidImage = true;
          }
          // JPEG: FF D8 FF
          else if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF) {
            debugPrint('✅ 유효한 JPEG 파일 확인');
            isValidImage = true;
          } else {
            debugPrint('⚠️ 알 수 없는 이미지 형식: ${header.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
          }
        }

        // Content-Type도 확인
        final contentType = response.headers['content-type'] ?? '';
        debugPrint('🖼️ Content-Type: $contentType');
        
        if (isValidImage || contentType.startsWith('image/') || contentType.contains('jpeg') || contentType.contains('png')) {
          debugPrint('✅ 이미지 데이터 확인됨, 다이얼로그 표시 시작');
          if (context.mounted) {
            try {
              debugPrint('🖼️ 다이얼로그 생성 시작...');
              _showFloorPlanDialog(context, floor, detail, response.bodyBytes);
              debugPrint('🖼️ 다이얼로그 생성 완료');
            } catch (e, stackTrace) {
              debugPrint('❌ 다이얼로그 생성 실패: $e');
              debugPrint('📍 스택 트레이스: $stackTrace');
              _showErrorDialog(context, '이미지 표시 중 오류가 발생했습니다.\n\n오류: $e');
            }
          }
        } else {
          // 이미지가 아닌 경우
          String responseText;
          try {
            responseText = utf8.decode(response.bodyBytes);
          } catch (e) {
            try {
              responseText = String.fromCharCodes(response.bodyBytes);
            } catch (e2) {
              responseText = 'Binary data (${response.bodyBytes.length} bytes)';
            }
          }
          
          debugPrint('❌ 이미지가 아닌 응답: $contentType');
          debugPrint('📄 응답 내용 (첫 200자): ${responseText.length > 200 ? responseText.substring(0, 200) : responseText}');
          
          if (context.mounted) {
            _showErrorDialog(context, '서버에서 이미지가 아닌 데이터를 반환했습니다.\n'
                'Content-Type: $contentType\n'
                'URL: $apiUrl\n'
                '응답 크기: ${response.bodyBytes.length} bytes\n'
                '응답 시간: ${responseTime}ms\n'
                '유효한 이미지: ${isValidImage ? "예" : "아니오"}');
          }
        }
      } else if (response.statusCode == 404) {
        debugPrint('❌ 404 오류: 도면을 찾을 수 없음');
        if (context.mounted) {
          _showErrorDialog(context, '해당 층의 도면을 찾을 수 없습니다.\n\n'
              '건물: ${building.name} ($buildingCode)\n'
              '층: $floor ($floorNumber)\n'
              'URL: $apiUrl\n'
              '응답 시간: ${responseTime}ms');
        }
      } else {
        debugPrint('❌ HTTP 오류: ${response.statusCode}');
        
        String responseText;
        try {
          responseText = utf8.decode(response.bodyBytes);
        } catch (e) {
          try {
            responseText = String.fromCharCodes(response.bodyBytes);
          } catch (e2) {
            responseText = 'Binary data (${response.bodyBytes.length} bytes)';
          }
        }
        
        debugPrint('📄 오류 응답: ${responseText.length > 100 ? responseText.substring(0, 100) : responseText}');
        
        if (context.mounted) {
          _showErrorDialog(context, '서버 오류가 발생했습니다.\n\n'
              '상태 코드: ${response.statusCode}\n'
              'URL: $apiUrl\n'
              '응답 시간: ${responseTime}ms\n'
              '응답: ${responseText.length > 50 ? "${responseText.substring(0, 50)}..." : responseText}');
        }
      }
    } catch (e, stackTrace) {
      final totalTime = DateTime.now().difference(startTime).inSeconds;
      debugPrint('❌ 예외 발생 ($totalTime초 후): $e');
      debugPrint('📍 스택 트레이스: $stackTrace');
      
      // 로딩 다이얼로그 닫기
      if (context.mounted && isLoading) {
        Navigator.pop(context);
        isLoading = false;
      }
      
      if (context.mounted) {
        String errorMessage = '네트워크 오류가 발생했습니다.\n\n';
        
        if (e.toString().contains('시간 초과') || e.toString().contains('timeout')) {
          errorMessage += '⏰ 서버 응답 시간이 초과되었습니다 (10초).\n'
              '가능한 원인:\n'
              '• 서버가 느리거나 과부하 상태\n'
              '• 도면 파일이 너무 큼\n'
              '• 네트워크 연결이 불안정\n\n'
              '해결 방법:\n'
              '• 잠시 후 다시 시도\n'
              '• 다른 층의 도면 먼저 시도\n'
              '• 네트워크 연결 확인';
        } else if (e.toString().contains('SocketException') || e.toString().contains('Network')) {
          errorMessage += '🌐 네트워크 연결 문제가 발생했습니다.\n'
              '• 인터넷 연결을 확인해주세요\n'
              '• Wi-Fi 또는 모바일 데이터 상태 확인\n'
              '• 서버에 연결할 수 없습니다';
        } else if (e.toString().contains('HandshakeException')) {
          errorMessage += '🔒 SSL 연결 오류가 발생했습니다.\n'
              '서버 보안 설정을 확인해주세요.';
        } else {
          errorMessage += '❓ 알 수 없는 오류: ${e.toString()}';
        }
        
        errorMessage += '\n\nURL: $apiUrl\n총 소요 시간: $totalTime초';
        
        _showErrorDialog(context, errorMessage);
      }
    }
  }

  String _extractBuildingCode(String buildingName) {
    // 건물명에서 코드 부분 추출 (예: "우송도서관(W1)" -> "W1")
    final RegExp regex = RegExp(r'\(([^)]+)\)');
    final match = regex.firstMatch(buildingName);
    if (match != null) {
      return match.group(1)!;
    }
    
    // 괄호가 없는 경우 건물명 그대로 사용
    return buildingName.replaceAll(' ', '');
  }

  String _extractFloorNumber(String floor) {
    // 다양한 층 형식을 처리: "1F", "2F", "B1F", "B2F", "3층" 등
    floor = floor.trim().toUpperCase();
    
    // 지하층 처리 (B1F, B2F 등)
    if (floor.startsWith('B')) {
      final RegExp regex = RegExp(r'B(\d+)');
      final match = regex.firstMatch(floor);
      if (match != null) {
        return 'B${match.group(1)}'; // B1, B2 형태로 반환
      }
    }
    
    // 일반층 처리 (1F, 2F, 3층 등)
    final RegExp regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(floor);
    return match?.group(1) ?? '1';
  }

  void _showFloorPlanDialog(BuildContext context, String floor, String detail, Uint8List imageBytes) {
    debugPrint('🎨 _showFloorPlanDialog 시작 - 이미지 크기: ${imageBytes.length} bytes');
    
    try {
      debugPrint('🎨 다이얼로그 showDialog 호출...');
      showDialog(
        context: context,
        builder: (context) {
          debugPrint('🎨 다이얼로그 builder 실행됨');
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
                maxWidth: MediaQuery.of(context).size.width * 0.95,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 헤더
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo.shade600, Colors.blue.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.architecture,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$floor 도면',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                building.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            debugPrint('🎨 닫기 버튼 클릭됨');
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 도면 이미지
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildImageWidget(imageBytes),
                      ),
                    ),
                  ),
                  // 하단 안내
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '핀치하여 확대/축소, 드래그하여 이동',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      debugPrint('🎨 showDialog 완료');
    } catch (e, stackTrace) {
      debugPrint('❌ showDialog 실패: $e');
      debugPrint('📍 스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  // 🆕 이미지 위젯을 별도 함수로 분리
  Widget _buildImageWidget(Uint8List imageBytes) {
    debugPrint('🖼️ 이미지 위젯 생성 시작...');
    
    return InteractiveViewer(
      panEnabled: true,
      boundaryMargin: const EdgeInsets.all(20),
      minScale: 0.5,
      maxScale: 4.0,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Image.memory(
          imageBytes,
          fit: BoxFit.contain,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            debugPrint('🖼️ 이미지 프레임 로드: frame=$frame, sync=$wasSynchronouslyLoaded');
            if (wasSynchronouslyLoaded) {
              debugPrint('✅ 이미지 동기 렌더링 성공');
              return child;
            }
            if (frame != null) {
              debugPrint('✅ 이미지 비동기 렌더링 성공 (프레임: $frame)');
              return child;
            }
            debugPrint('⏳ 이미지 로딩 중... (프레임 대기)');
            return Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('이미지 로딩 중...'),
                  ],
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ 이미지 렌더링 오류: $error');
            debugPrint('📍 이미지 오류 스택: $stackTrace');
            return Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '이미지를 표시할 수 없습니다',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        error.toString(),
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade400,
            ),
            const SizedBox(width: 8),
            const Text('도면 로딩 실패'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '문제 해결 방법:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 네트워크 연결을 확인해주세요\n'
                      '• 잠시 후 다시 시도해주세요\n'
                      '• 다른 층의 도면을 먼저 시도해보세요\n'
                      '• 문제가 지속되면 관리자에게 문의하세요',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // 디버그 정보 복사하기 위한 스낵바 표시
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('개발자 도구에서 상세 로그를 확인하세요'),
                  action: SnackBarAction(
                    label: '확인',
                    onPressed: () {},
                  ),
                ),
              );
            },
            child: const Text('재시도'),
          ),
        ],
      ),
    );
  }
}