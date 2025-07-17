// timetable_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../generated/app_localizations.dart';
import 'timetable_item.dart';
import 'timetable_api_service.dart';
import '../map/widgets/directions_screen.dart'; // 폴더 구조에 맞게 경로 수정!

class ScheduleScreen extends StatefulWidget {
  final String userId;
  const ScheduleScreen({required this.userId, super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late String _currentSemester;
  List<ScheduleItem> _scheduleItems = [];
  bool _isInitialized = false;
  bool _isLoading = false;
  final TimetableApiService _apiService = TimetableApiService();

  @override
  void initState() {
    super.initState();
    _loadScheduleItems();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _currentSemester = _getCurrentSemester();
    }
  }

  String _getCurrentSemester() {
    final now = DateTime.now();
    final month = now.month;
    final l10n = AppLocalizations.of(context);

    if (month >= 12 || month <= 2) {
      return l10n?.winter_semester ?? 'Winter';
    } else if (month >= 3 && month <= 5) {
      return l10n?.spring_semester ?? 'Spring';
    } else if (month >= 6 && month <= 8) {
      return l10n?.summer_semester ?? 'Summer';
    } else {
      return l10n?.fall_semester ?? 'Fall';
    }
  }

  int _getCurrentYear() => DateTime.now().year;

  Future<void> _loadScheduleItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _apiService.fetchScheduleItems(widget.userId);
      if (mounted) setState(() => _scheduleItems = items);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('시간표를 불러오지 못했습니다.')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addScheduleItem(ScheduleItem item) async {
    await _apiService.addScheduleItem(item, widget.userId);
    await _loadScheduleItems();
  }

  Future<void> _updateScheduleItem(
    ScheduleItem originItem,
    ScheduleItem newItem,
  ) async {
    await _apiService.updateScheduleItem(
      userId: widget.userId,
      originTitle: originItem.title,
      originDayOfWeek: originItem.dayOfWeekText,
      newItem: newItem,
    );
    await _loadScheduleItems();
  }

  Future<void> _deleteScheduleItem(ScheduleItem item) async {
    await _apiService.deleteScheduleItem(
      userId: widget.userId,
      title: item.title,
      dayOfWeek: item.dayOfWeekText,
    );
    await _loadScheduleItems();
  }

  bool _isOverlapped(ScheduleItem newItem, {String? ignoreId}) {
    final newStart = _parseTime(newItem.startTime);
    final newEnd = _parseTime(newItem.endTime);

    for (final item in _scheduleItems) {
      print('item.id="${item.id}" ignoreId="$ignoreId"');
      if (ignoreId != null &&
          item.id != null &&
          item.id!.trim() == ignoreId.trim())
        continue;
      if (item.dayOfWeek != newItem.dayOfWeek) continue;

      final existStart = _parseTime(item.startTime);
      final existEnd = _parseTime(item.endTime);

      // 걸치면 무조건 중복(에브리타임, 네이버캘린더식)
      if (newStart < existEnd && newEnd > existStart) {
        // 디버그 로깅(실전 문제 추적용)
        print(
          '중복! 비교중 item.id=${item.id} vs ignoreId=$ignoreId / '
          'start=$existStart, end=$existEnd <-> newStart=$newStart, newEnd=$newEnd',
        );
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildScheduleView()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.schedule,
              color: Color(0xFF1E3A8A),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.timetable ?? 'Timetable',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      l10n?.current_year(_getCurrentYear()) ??
                          '${_getCurrentYear()}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currentSemester,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showAddScheduleDialog,
            icon: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFF1E3A8A),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDayHeaders(),
          Expanded(child: _buildTimeTable()),
        ],
      ),
    );
  }

  Widget _buildDayHeaders() {
    final l10n = AppLocalizations.of(context);
    final days = [
      l10n?.time ?? 'Time',
      l10n?.monday ?? 'Mon',
      l10n?.tuesday ?? 'Tue',
      l10n?.wednesday ?? 'Wed',
      l10n?.thursday ?? 'Thu',
      l10n?.friday ?? 'Fri',
    ];

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: days
            .map(
              (day) => Expanded(
                child: Container(
                  alignment: Alignment.center,
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTimeTable() {
    final timeSlots = _generateTimeSlots();

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: timeSlots.length,
      itemBuilder: (context, index) {
        final timeSlot = timeSlots[index];
        return _buildTimeRow(timeSlot, index);
      },
    );
  }

  Widget _buildTimeRow(String timeSlot, int index) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                timeSlot,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
          ...List.generate(5, (dayIndex) {
            final scheduleItem = _getScheduleForTimeAndDay(
              timeSlot,
              dayIndex + 1,
            );
            return Expanded(
              child: Container(
                margin: const EdgeInsets.all(2),
                child: scheduleItem != null
                    ? _buildScheduleCard(scheduleItem)
                    : const SizedBox(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(ScheduleItem item) {
    return GestureDetector(
      onTap: () => _showScheduleDetail(item),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: item.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: item.color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: item.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${item.buildingName} ${item.floorNumber} ${item.roomName}',
              style: TextStyle(fontSize: 9, color: item.color.withOpacity(0.8)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  List<String> _generateTimeSlots() {
    final slots = <String>[];
    for (int hour = 9; hour <= 18; hour++) {
      slots.add('${hour.toString().padLeft(2, '0')}:00');
      if (hour < 18) {
        slots.add('${hour.toString().padLeft(2, '0')}:30');
      }
    }
    return slots;
  }

  ScheduleItem? _getScheduleForTimeAndDay(String timeSlot, int dayOfWeek) {
    for (final item in _scheduleItems) {
      if (item.dayOfWeek == dayOfWeek &&
          _isTimeInRange(timeSlot, item.startTime, item.endTime)) {
        return item;
      }
    }
    return null;
  }

  bool _isTimeInRange(String timeSlot, String startTime, String endTime) {
    final slotTime = _parseTime(timeSlot);
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);

    return slotTime >= start && slotTime < end;
  }

  int _parseTime(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _getDayName(int dayOfWeek) {
    final l10n = AppLocalizations.of(context);

    switch (dayOfWeek) {
      case 1:
        return l10n?.monday_full ?? 'Monday';
      case 2:
        return l10n?.tuesday_full ?? 'Tuesday';
      case 3:
        return l10n?.wednesday_full ?? 'Wednesday';
      case 4:
        return l10n?.thursday_full ?? 'Thursday';
      case 5:
        return l10n?.friday_full ?? 'Friday';
      default:
        return '';
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1E3A8A)),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Future<void> _showScheduleFormDialog({
    ScheduleItem? initialItem,
    required Future<void> Function(ScheduleItem) onSubmit,
  }) async {
    final l10n = AppLocalizations.of(context);

    final titleController = TextEditingController(
      text: initialItem?.title ?? '',
    );
    final professorController = TextEditingController(
      text: initialItem?.professor ?? '',
    );

    String? selectedBuilding = initialItem?.buildingName;
    String? selectedFloor = initialItem?.floorNumber;
    String? selectedRoom = initialItem?.roomName;

    List<String> floorList = [];
    List<String> roomList = [];

    int selectedDay = initialItem?.dayOfWeek ?? 1;
    String startTime = initialItem?.startTime.length == 5
        ? initialItem!.startTime
        : '09:00';
    String endTime = initialItem?.endTime.length == 5
        ? initialItem!.endTime
        : '10:30';
    Color selectedColor = initialItem?.color ?? const Color(0xFF3B82F6);

    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFF06B6D4),
      const Color(0xFFEC4899),
      const Color(0xFF84CC16),
    ];

    final List<String> buildingCodes = [
      'W1',
      'W2',
      'W2-1',
      'W3',
      'W4',
      'W5',
      'W6',
      'W7',
      'W8',
      'W9',
      'W10',
      'W11',
      'W12',
      'W13',
      'W14',
      'W15',
      'W16',
      'W17-동관',
      'W17-서관',
      'W18',
      'W19',
    ];

    final memoController = TextEditingController(text: initialItem?.memo ?? '');

    // 컨트롤러 변수 선언 (builder 컨트롤러 저장용)
    TextEditingController? buildingFieldController;
    TextEditingController? floorFieldController;
    TextEditingController? roomFieldController;

    if (initialItem != null) {
      floorList = await _apiService.fetchFloors(initialItem.buildingName);
      roomList = await _apiService.fetchRooms(
        initialItem.buildingName,
        initialItem.floorNumber,
      );
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                initialItem == null
                    ? l10n?.add_class ?? 'Add Class'
                    : l10n?.edit_class ?? 'Edit Class',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: l10n?.class_name ?? 'Class Name',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: professorController,
                      decoration: InputDecoration(
                        labelText: l10n?.professor_name ?? 'Professor',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ----------- [ 건물명 자동완성 입력창 ] -----------
                    TypeAheadField<String>(
                      suggestionsCallback: (pattern) async => buildingCodes
                          .where(
                            (code) => code.toLowerCase().contains(
                              pattern.toLowerCase(),
                            ),
                          )
                          .toList(),
                      itemBuilder: (context, suggestion) =>
                          ListTile(title: Text(suggestion)),
                      builder: (context, controller, focusNode) {
                        buildingFieldController = controller;
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: l10n?.building_name ?? 'Building',
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (value) async {
                            selectedBuilding = value;
                            setState(() {
                              // 👇 아래 5줄 추가 ※※
                              selectedFloor = null;
                              selectedRoom = null;
                              floorFieldController?.text = '';
                              roomFieldController?.text = '';
                              floorList = [];
                              roomList = [];
                            });
                            if (buildingCodes.contains(value)) {
                              final fetchedFloors = await _apiService
                                  .fetchFloors(value);
                              setState(() {
                                floorList = fetchedFloors;
                              });
                            }
                          },
                        );
                      },
                      // onSelected 아래처럼 수정!
                      onSelected: (suggestion) async {
                        selectedBuilding = suggestion;
                        setState(() {
                          buildingFieldController?.text = suggestion;
                          selectedFloor = null;
                          selectedRoom = null;
                          floorFieldController?.text = '';
                          roomFieldController?.text = '';
                          floorList = [];
                          roomList = [];
                        });
                        final fetchedFloors = await _apiService.fetchFloors(
                          suggestion,
                        );
                        setState(() {
                          floorList = fetchedFloors;
                        });
                      },
                    ),

                    // ----------- [ 층 자동완성 입력창 ] -----------
                    const SizedBox(height: 8),
                    TypeAheadField<String>(
                      key: ValueKey(selectedBuilding), // 👈👈👈 중요!!
                      suggestionsCallback: (pattern) async {
                        if (pattern.trim().isEmpty) return floorList;
                        return floorList
                            .where(
                              (floor) => floor.toLowerCase().contains(
                                pattern.toLowerCase(),
                              ),
                            )
                            .toList();
                      },
                      itemBuilder: (context, suggestion) =>
                          ListTile(title: Text(suggestion)),
                      builder: (context, controller, focusNode) {
                        floorFieldController = controller;
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          enabled: selectedBuilding != null,
                          decoration: InputDecoration(
                            labelText: l10n?.floor_number ?? 'Floor',
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (value) async {
                            selectedFloor = value;
                            selectedRoom = null;
                            roomFieldController?.text = '';
                            setState(() => roomList = []);
                            if (floorList.contains(value)) {
                              final fetchedRooms = await _apiService.fetchRooms(
                                selectedBuilding!,
                                value,
                              );
                              setState(() {
                                roomList = fetchedRooms;
                              });
                            }
                          },
                        );
                      },
                      onSelected: (suggestion) async {
                        selectedFloor = suggestion;
                        floorFieldController?.text = suggestion;
                        selectedRoom = null;
                        roomFieldController?.text = '';
                        final fetchedRooms = await _apiService.fetchRooms(
                          selectedBuilding!,
                          suggestion,
                        );
                        setState(() {
                          roomList = fetchedRooms;
                        });
                      },
                    ),

                    // ----------- [ 강의실 자동완성 입력창 ] -----------
                    const SizedBox(height: 8),
                    TypeAheadField<String>(
                      suggestionsCallback: (pattern) async {
                        if (pattern.trim().isEmpty) return roomList;
                        return roomList
                            .where(
                              (room) => room.toLowerCase().contains(
                                pattern.toLowerCase(),
                              ),
                            )
                            .toList();
                      },
                      itemBuilder: (context, suggestion) =>
                          ListTile(title: Text(suggestion)),
                      builder: (context, controller, focusNode) {
                        roomFieldController = controller;
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          enabled: selectedFloor != null,
                          decoration: InputDecoration(
                            labelText: l10n?.room_name ?? 'Room',
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (value) => selectedRoom = value,
                        );
                      },
                      onSelected: (suggestion) {
                        selectedRoom = suggestion;
                        roomFieldController?.text = suggestion;
                        setState(() {});
                      },
                    ),

                    // -------------------- 이하 생략(동일) --------------------
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: l10n?.day_of_week ?? 'Day',
                        border: const OutlineInputBorder(),
                      ),
                      value: selectedDay,
                      items: [
                        DropdownMenuItem(
                          value: 1,
                          child: Text(l10n?.monday_full ?? 'Monday'),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text(l10n?.tuesday_full ?? 'Tuesday'),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text(l10n?.wednesday_full ?? 'Wednesday'),
                        ),
                        DropdownMenuItem(
                          value: 4,
                          child: Text(l10n?.thursday_full ?? 'Thursday'),
                        ),
                        DropdownMenuItem(
                          value: 5,
                          child: Text(l10n?.friday_full ?? 'Friday'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => selectedDay = value!),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: l10n?.start_time ?? 'Start Time',
                              border: const OutlineInputBorder(),
                            ),
                            value: startTime,
                            items: _generateTimeSlots()
                                .map(
                                  (time) => DropdownMenuItem(
                                    value: time,
                                    child: Text(time),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                startTime = value!;
                                var slotList = _generateTimeSlots();
                                int idx = slotList.indexOf(startTime);
                                if (_parseTime(endTime) <=
                                    _parseTime(startTime)) {
                                  endTime = (idx + 1 < slotList.length)
                                      ? slotList[idx + 1]
                                      : slotList[idx];
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: l10n?.end_time ?? 'End Time',
                              border: const OutlineInputBorder(),
                            ),
                            value: endTime,
                            items: _generateTimeSlots()
                                .where(
                                  (time) =>
                                      _parseTime(time) > _parseTime(startTime),
                                )
                                .map(
                                  (time) => DropdownMenuItem(
                                    value: time,
                                    child: Text(time),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => endTime = value!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n?.color_selection ?? 'Select Color',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: colors.map((color) {
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = color),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selectedColor == color
                                    ? Colors.black54
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: selectedColor == color
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    // 👇👇👇 메모 입력란 추가 (여기가 핵심 추가 부분입니다!)
                    const SizedBox(height: 16),
                    TextField(
                      controller: memoController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n?.memo ?? 'Memo',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n?.cancel ?? 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty &&
                        selectedBuilding?.isNotEmpty == true &&
                        selectedFloor?.isNotEmpty == true &&
                        selectedRoom?.isNotEmpty == true) {
                      final newItem = ScheduleItem(
                        id: initialItem?.id,
                        title: titleController.text,
                        professor: professorController.text,
                        buildingName: selectedBuilding!,
                        floorNumber: selectedFloor!,
                        roomName: selectedRoom!,
                        dayOfWeek: selectedDay,
                        startTime: startTime,
                        endTime: endTime,
                        color: selectedColor,
                        memo: memoController.text,
                      );
                      if (_isOverlapped(newItem, ignoreId: initialItem?.id)) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n?.overlap_message ??
                                  '이미 같은 시간에 등록된 수업이 있습니다.',
                            ),
                          ),
                        );
                        return;
                      }
                      await onSubmit(newItem);
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    initialItem == null
                        ? l10n?.add ?? 'Add'
                        : l10n?.save ?? 'Save',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddScheduleDialog() {
    _showScheduleFormDialog(
      onSubmit: (item) async => await _addScheduleItem(item),
    );
  }

  void _showEditScheduleDialog(ScheduleItem item) {
    _showScheduleFormDialog(
      initialItem: item,
      onSubmit: (newItem) async => await _updateScheduleItem(item, newItem),
    );
  }

  void _showRecommendRoute(ScheduleItem item) {
    // DirectionsScreen에 도착지 정보를 전달하면서 이동 (예시는 roomData 파라미터 사용)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DirectionsScreen(
          // 아래처럼 강의실 정보를 도착지로 전달합니다.
          // DirectionsScreen 쪽에서 roomData, presetEnd 등 파라미터명 확인 필요!
          roomData: {
            "type": "end", // 도착지 역할로
            "buildingName": item.buildingName,
            "floorNumber": item.floorNumber,
            "roomName": item.roomName,
          },
        ),
      ),
    );
  }

  void _showScheduleDetail(ScheduleItem item) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.only(
          top: 16,
          left: 24,
          right: 8,
          bottom: 0,
        ),
        title: Row(
          children: [
            Expanded(child: Text(item.title)),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              splashRadius: 20,
              tooltip: '닫기',
            ),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(
              Icons.person,
              l10n?.professor_name ?? 'Professor',
              item.professor,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              Icons.location_city,
              l10n?.building_name ?? 'Building',
              item.buildingName,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              Icons.layers,
              l10n?.floor_number ?? 'Floor',
              item.floorNumber,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              Icons.meeting_room,
              l10n?.room_name ?? 'Room',
              item.roomName,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              Icons.calendar_today,
              l10n?.day_of_week ?? 'Day',
              _getDayName(item.dayOfWeek),
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              Icons.access_time,
              l10n?.time ?? 'Time',
              '${item.startTime} - ${item.endTime}',
            ),
            const SizedBox(height: 10),
            if (item.memo.isNotEmpty)
              _buildDetailRow(
                Icons.sticky_note_2,
                l10n?.memo ?? 'Memo',
                item.memo,
              ),
          ],
        ),
        // ====== 요 아래만 바꿔주면 됩니다!! ======
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // 추천경로 보기 (왼쪽)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showRecommendRoute(item);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                child: const Text('추천경로 보기'),
              ),
              const SizedBox(width: 8),
              // 편집 (가운데)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showEditScheduleDialog(item);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                child: Text(l10n?.edit ?? 'Edit'),
              ),
              const SizedBox(width: 8),
              // 삭제 (오른쪽/빨강)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await _deleteScheduleItem(item);
                },
                child: Text(l10n?.delete ?? 'Delete'),
              ),
            ],
          ),
        ],
        actionsAlignment: MainAxisAlignment.start, // Row 사용시 이 옵션은 무시될 수 있습니다
      ),
    );
  }
}
