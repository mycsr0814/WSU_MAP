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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '시간표를 불러오지 못했습니다.',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
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
      if (ignoreId != null &&
          item.id != null &&
          item.id!.trim() == ignoreId.trim()) {
        continue;
      }
      if (item.dayOfWeek != newItem.dayOfWeek) continue;

      final existStart = _parseTime(item.startTime);
      final existEnd = _parseTime(item.endTime);

      if (newStart < existEnd && newEnd > existStart) {
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
        // 시간표(시계) 아이콘 부분 삭제됨
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Expanded(
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: _buildOptimizedTimeTable(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizedTimeTable() {
    final timeSlots = _generateOptimizedTimeSlots();
    final currentTime = DateTime.now();
    final currentHour = currentTime.hour;
    final currentMinute = currentTime.minute;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 패딩을 고려해 사용 가능한 높이 계산
        const containerPadding = 8.0;
        final maxAvailableHeight =
            constraints.maxHeight - (containerPadding * 2);
        final rowHeight = maxAvailableHeight / timeSlots.length; // 동적 높이 계산
        final calculatedHeight = maxAvailableHeight; // 스크롤 없이 전체 높이 사용

        return Container(
          height: calculatedHeight, // 전체 높이를 명시적으로 제한
          padding: const EdgeInsets.all(containerPadding),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Column(
                children: timeSlots.asMap().entries.map((entry) {
                  final timeSlot = entry.value;
                  final isCurrentTime = _isCurrentTimeSlot(
                    timeSlot,
                    currentHour,
                    currentMinute,
                  );
                  return _buildTimeGridRow(timeSlot, isCurrentTime, rowHeight);
                }).toList(),
              ),
              ..._buildFloatingScheduleCards(constraints, rowHeight),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeGridRow(
    String timeSlot,
    bool isCurrentTime,
    double rowHeight,
  ) {
    return Container(
      height: rowHeight, // 동적 높이 적용
      decoration: BoxDecoration(
        color: isCurrentTime ? const Color(0xFF1E3A8A).withOpacity(0.05) : null,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCurrentTime
                  ? const Color(0xFF1E3A8A).withOpacity(0.1)
                  : Colors.grey.shade50,
              border: Border(
                right: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Text(
              timeSlot,
              style: TextStyle(
                fontSize: 10 * (rowHeight / 45.0).clamp(0.7, 1.0), // 동적 폰트 크기
                fontWeight: isCurrentTime ? FontWeight.w700 : FontWeight.w500,
                color: isCurrentTime
                    ? const Color(0xFF1E3A8A)
                    : Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: List.generate(5, (dayIndex) {
                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: dayIndex < 4
                            ? BorderSide(
                                color: Colors.grey.shade200,
                                width: 0.5,
                              )
                            : BorderSide.none,
                      ),
                    ),
                    height: rowHeight,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingScheduleCards(
    BoxConstraints constraints,
    double rowHeight,
  ) {
    final List<Widget> cards = [];

    for (int dayIndex = 0; dayIndex < 5; dayIndex++) {
      final daySchedules = _scheduleItems
          .where((item) => item.dayOfWeek == dayIndex + 1)
          .toList();

      for (final schedule in daySchedules) {
        final card = _buildAbsolutePositionedCard(
          schedule,
          dayIndex,
          constraints,
          rowHeight,
        );
        if (card != null) {
          cards.add(card);
        }
      }
    }

    return cards;
  }

  Widget? _buildAbsolutePositionedCard(
    ScheduleItem item,
    int dayIndex,
    BoxConstraints constraints,
    double rowHeight,
  ) {
    final startHour = int.parse(item.startTime.split(':')[0]);
    final startMinute = int.parse(item.startTime.split(':')[1]);
    final endHour = int.parse(item.endTime.split(':')[0]);
    final endMinute = int.parse(item.endTime.split(':')[1]);

    if (startHour < 9 || startHour > 18) return null;

    const timeColumnWidth = 60.0;
    const containerPadding = 8.0;

    final availableWidth =
        constraints.maxWidth - timeColumnWidth - (containerPadding * 2);
    final dayColumnWidth = availableWidth / 5;

    // 동적 높이에 맞춰 위치 계산
    final startRowIndex = startHour - 9;
    final startPixelOffset = startMinute / 60.0 * rowHeight;
    final top = (startRowIndex * rowHeight) + startPixelOffset;

    final endRowIndex = endHour - 9;
    final endPixelOffset = endMinute / 60.0 * rowHeight;
    final cardHeight = (endRowIndex * rowHeight + endPixelOffset) - top;

    return Positioned(
      top: top,
      left: timeColumnWidth + (dayIndex * dayColumnWidth),
      width: dayColumnWidth,
      height: cardHeight.clamp(
        rowHeight * 0.5,
        constraints.maxHeight - top,
      ), // 오버플로우 방지
      child: GestureDetector(
        onTap: () => _showScheduleDetail(item),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0.5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                item.color.withOpacity(0.9),
                item.color.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: item.color.withOpacity(0.2),
                blurRadius: 1,
                offset: const Offset(0, 0.5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 8 * (rowHeight / 45.0).clamp(0.7, 1.0),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (cardHeight > rowHeight * 0.6) ...[
                  const SizedBox(height: 1),
                  Text(
                    '${item.startTime}-${item.endTime}',
                    style: TextStyle(
                      fontSize: 6 * (rowHeight / 45.0).clamp(0.7, 1.0),
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (cardHeight > rowHeight && item.roomName.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    '${item.buildingName} ${item.roomName}',
                    style: TextStyle(
                      fontSize: 6 * (rowHeight / 45.0).clamp(0.7, 1.0),
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
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

  List<String> _generateOptimizedTimeSlots() {
    final slots = <String>[];
    for (int hour = 9; hour <= 18; hour++) {
      slots.add('${hour.toString().padLeft(2, '0')}:00');
    }
    return slots;
  }

  bool _isCurrentTimeSlot(String timeSlot, int currentHour, int currentMinute) {
    final slotHour = int.parse(timeSlot.split(':')[0]);
    return currentHour == slotHour;
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

  Future<void> _showDeleteConfirmDialog(ScheduleItem item) async {
  final l10n = AppLocalizations.of(context)!; // null 체크 위해 '!' 추가

  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_outlined,
                      color: Colors.red,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.scheduleDeleteTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.scheduleDeleteSubtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.scheduleDeleteLabel,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.scheduleDeleteDescription(item.title),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.cancelButton,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          l10n.deleteButton,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  if (result == true) {
    await _deleteScheduleItem(item);
  }
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
    final memoController = TextEditingController(text: initialItem?.memo ?? '');

    final buildingFieldController = TextEditingController(
      text: initialItem?.buildingName ?? '',
    );
    final floorFieldController = TextEditingController(
      text: initialItem?.floorNumber ?? '',
    );
    final roomFieldController = TextEditingController(
      text: initialItem?.roomName ?? '',
    );

    String? selectedBuilding = initialItem?.buildingName;
    String? selectedFloor = initialItem?.floorNumber;
    String? selectedRoom = initialItem?.roomName;

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

    List<String> floorList = [];
    List<String> roomList = [];

    if (initialItem != null) {
      floorList = await _apiService.fetchFloors(initialItem.buildingName);
      roomList = await _apiService.fetchRooms(
        initialItem.buildingName,
        initialItem.floorNumber,
      );
    }

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => SafeArea(
        child: StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.schedule,
                              color: Color(0xFF1E3A8A),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              initialItem == null
                                  ? l10n?.add_class ?? 'Add Class'
                                  : l10n?.edit_class ?? 'Edit Class',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _buildStyledInputField(
                              controller: titleController,
                              labelText: l10n?.class_name ?? 'Class Name',
                              icon: Icons.book,
                              autofocus: true,
                            ),
                            const SizedBox(height: 16),
                            _buildStyledInputField(
                              controller: professorController,
                              labelText: l10n?.professor_name ?? 'Professor',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 16),
                            _buildStyledTypeAheadField(
                              controller: buildingFieldController,
                              labelText: l10n?.building_name ?? 'Building',
                              icon: Icons.business,
                              suggestionsCallback: (pattern) async =>
                                  buildingCodes
                                      .where(
                                        (code) => code.toLowerCase().contains(
                                          pattern.toLowerCase(),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) async {
                                selectedBuilding = value;
                                setState(() {
                                  selectedFloor = null;
                                  selectedRoom = null;
                                  floorFieldController.text = '';
                                  roomFieldController.text = '';
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
                              onSelected: (suggestion) async {
                                selectedBuilding = suggestion;
                                setState(() {
                                  buildingFieldController.text = suggestion;
                                  selectedFloor = null;
                                  selectedRoom = null;
                                  floorFieldController.text = '';
                                  roomFieldController.text = '';
                                  floorList = [];
                                  roomList = [];
                                });
                                final fetchedFloors = await _apiService
                                    .fetchFloors(suggestion);
                                setState(() {
                                  floorList = fetchedFloors;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildStyledTypeAheadField(
                              key: ValueKey(selectedBuilding),
                              controller: floorFieldController,
                              labelText: l10n?.floor_number ?? 'Floor',
                              icon: Icons.layers,
                              enabled: selectedBuilding != null,
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
                              onChanged: (value) async {
                                selectedFloor = value;
                                selectedRoom = null;
                                roomFieldController.text = '';
                                setState(() => roomList = []);
                                if (floorList.contains(value)) {
                                  final fetchedRooms = await _apiService
                                      .fetchRooms(selectedBuilding!, value);
                                  setState(() {
                                    roomList = fetchedRooms;
                                  });
                                }
                              },
                              onSelected: (suggestion) async {
                                selectedFloor = suggestion;
                                setState(() {
                                  floorFieldController.text = suggestion;
                                  selectedRoom = null;
                                  roomFieldController.text = '';
                                });
                                final fetchedRooms = await _apiService
                                    .fetchRooms(selectedBuilding!, suggestion);
                                setState(() {
                                  roomList = fetchedRooms;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildStyledTypeAheadField(
                              key: ValueKey(
                                '${selectedBuilding}_$selectedFloor',
                              ),
                              controller: roomFieldController,
                              labelText: l10n?.room_name ?? 'Room',
                              icon: Icons.meeting_room,
                              enabled: selectedFloor != null,
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
                              onChanged: (value) => selectedRoom = value,
                              onSelected: (suggestion) {
                                selectedRoom = suggestion;
                                setState(() {
                                  roomFieldController.text = suggestion;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildStyledDropdownField<int>(
                              value: selectedDay,
                              labelText: l10n?.day_of_week ?? 'Day',
                              icon: Icons.calendar_today,
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
                                  child: Text(
                                    l10n?.wednesday_full ?? 'Wednesday',
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 4,
                                  child: Text(
                                    l10n?.thursday_full ?? 'Thursday',
                                  ),
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
                                  child: _buildStyledDropdownField<String>(
                                    value: startTime,
                                    labelText: l10n?.start_time ?? 'Start Time',
                                    icon: Icons.access_time,
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
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStyledDropdownField<String>(
                                    value: endTime,
                                    labelText: l10n?.end_time ?? 'End Time',
                                    icon: Icons.access_time_filled,
                                    items: _generateTimeSlots()
                                        .where(
                                          (time) =>
                                              _parseTime(time) >
                                              _parseTime(startTime),
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
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.palette,
                                        color: Color(0xFF1E3A8A),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n?.color_selection ?? 'Select Color',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: colors.map((color) {
                                      return GestureDetector(
                                        onTap: () => setState(
                                          () => selectedColor = color,
                                        ),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: color,
                                            borderRadius: BorderRadius.circular(
                                              22,
                                            ),
                                            border: Border.all(
                                              color: selectedColor == color
                                                  ? const Color(0xFF1E3A8A)
                                                  : Colors.transparent,
                                              width: 3,
                                            ),
                                            boxShadow: selectedColor == color
                                                ? [
                                                    BoxShadow(
                                                      color: color.withOpacity(
                                                        0.3,
                                                      ),
                                                      blurRadius: 8,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ]
                                                : [],
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
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildStyledInputField(
                              controller: memoController,
                              labelText: l10n?.memo ?? 'Memo',
                              icon: Icons.note_alt_outlined,
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          // 🔥 반응형 버튼 레이아웃
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isSmallScreen = constraints.maxWidth < 400;
                              
                              if (isSmallScreen) {
                                // 작은 화면: 세로로 배치
                                return Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: ElevatedButton(
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
                                            if (_isOverlapped(
                                              newItem,
                                              ignoreId: initialItem?.id,
                                            )) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    l10n?.overlap_message ??
                                                        '이미 같은 시간에 등록된 수업이 있습니다.',
                                                  ),
                                                  backgroundColor: const Color(
                                                    0xFFEF4444,
                                                  ),
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(
                                                      10,
                                                    ),
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            await onSubmit(newItem);
                                            Navigator.pop(context);
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1E3A8A),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 2,
                                        ),
                                        child: Text(
                                          initialItem == null
                                              ? l10n?.add ?? 'Add'
                                              : l10n?.save ?? 'Save',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Color(0xFFE2E8F0),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          l10n?.cancel ?? 'Cancel',
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                // 큰 화면: 가로로 배치
                                return Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 48,
                                        child: OutlinedButton(
                                          onPressed: () => Navigator.pop(context),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: Color(0xFFE2E8F0),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(
                                            l10n?.cancel ?? 'Cancel',
                                            style: const TextStyle(
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: SizedBox(
                                        height: 48,
                                        child: ElevatedButton(
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
                                              if (_isOverlapped(
                                                newItem,
                                                ignoreId: initialItem?.id,
                                              )) {
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      l10n?.overlap_message ??
                                                          '이미 같은 시간에 등록된 수업이 있습니다.',
                                                    ),
                                                    backgroundColor: const Color(
                                                      0xFFEF4444,
                                                    ),
                                                    behavior: SnackBarBehavior.floating,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(
                                                        10,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }
                                              await onSubmit(newItem);
                                              Navigator.pop(context);
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF1E3A8A),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 2,
                                          ),
                                          child: Text(
                                            initialItem == null
                                                ? l10n?.add ?? 'Add'
                                                : l10n?.save ?? 'Save',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
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

  Widget _buildStyledInputField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool autofocus = false,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        autofocus: autofocus,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 16, color: Color(0xFF1E3A8A)),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.never,
        ),
      ),
    );
  }

  Widget _buildStyledTypeAheadField({
    Key? key,
    TextEditingController? controller,
    required String labelText,
    required IconData icon,
    bool enabled = true,
    required Future<List<String>> Function(String) suggestionsCallback,
    Function(String)? onChanged,
    Function(String)? onSelected,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled
              ? const Color(0xFFE2E8F0)
              : const Color(0xFFE2E8F0).withOpacity(0.5),
        ),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: TypeAheadField<String>(
        key: key,
        suggestionsCallback: suggestionsCallback,
        itemBuilder: (context, suggestion) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            suggestion,
            style: const TextStyle(fontSize: 16, color: Color(0xFF1E3A8A)),
          ),
        ),
        builder: (context, fieldController, focusNode) {
          return TextFormField(
            controller: controller ?? fieldController,
            focusNode: focusNode,
            enabled: enabled,
            style: TextStyle(
              fontSize: 16,
              color: enabled
                  ? const Color(0xFF1E3A8A)
                  : const Color(0xFF64748B),
            ),
            decoration: InputDecoration(
              labelText: labelText,
              labelStyle: TextStyle(
                color: enabled
                    ? const Color(0xFF64748B)
                    : const Color(0xFF64748B).withOpacity(0.5),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                icon,
                color: enabled
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFF64748B).withOpacity(0.5),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.never,
            ),
            onChanged: onChanged,
          );
        },
        onSelected: onSelected,
      ),
    );
  }

  Widget _buildStyledDropdownField<T>({
    required T? value,
    required String labelText,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 16, color: Color(0xFF1E3A8A)),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.never,
        ),
        dropdownColor: Colors.white,
        icon: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFF1E3A8A),
            size: 20,
          ),
        ),
        iconSize: 24,
        elevation: 8,
        menuMaxHeight: 200,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildStyledDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
        ),
      ],
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DirectionsScreen(
          roomData: {
            "type": "end",
            "buildingName": item.buildingName,
            "floorNumber": item.floorNumber,
            "roomName": item.roomName,
          },
        ),
      ),
    );
  }

  void _showBuildingLocation(ScheduleItem item) {
    debugPrint('🏢 시간표에서 위치 보기 버튼 클릭됨');
    debugPrint('🏢 건물 이름: ${item.buildingName}');
    debugPrint('🏢 층수: ${item.floorNumber}');
    debugPrint('🏢 호실: ${item.roomName}');
    debugPrint('🏢 전체 아이템 정보: $item');
    
    // 메인 지도 화면으로 이동하면서 건물 정보를 전달
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/map',
      (route) => false, // 모든 이전 화면 제거
      arguments: {
        'showBuilding': item.buildingName,
        'buildingInfo': {
          'name': item.buildingName,
          'floorNumber': item.floorNumber,
          'roomName': item.roomName,
        }
      },
    );
    
    debugPrint('🏢 네비게이션 완료');
  }

  void _showScheduleDetail(ScheduleItem item) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.schedule, color: item.color, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: item.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_getDayName(item.dayOfWeek)} ${item.startTime} - ${item.endTime}',
                            style: TextStyle(
                              fontSize: 14,
                              color: item.color.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildStyledDetailRow(
                      Icons.person,
                      l10n?.professor_name ?? 'Professor',
                      item.professor,
                    ),
                    const SizedBox(height: 16),
                    _buildStyledDetailRow(
                      Icons.business,
                      l10n?.building_name ?? 'Building',
                      item.buildingName,
                    ),
                    const SizedBox(height: 16),
                    _buildStyledDetailRow(
                      Icons.layers,
                      l10n?.floor_number ?? 'Floor',
                      item.floorNumber,
                    ),
                    const SizedBox(height: 16),
                    _buildStyledDetailRow(
                      Icons.meeting_room,
                      l10n?.room_name ?? 'Room',
                      item.roomName,
                    ),
                    const SizedBox(height: 16),
                    _buildStyledDetailRow(
                      Icons.calendar_today,
                      l10n?.day_of_week ?? 'Day',
                      _getDayName(item.dayOfWeek),
                    ),
                    const SizedBox(height: 16),
                    _buildStyledDetailRow(
                      Icons.access_time,
                      l10n?.time ?? 'Time',
                      '${item.startTime} - ${item.endTime}',
                    ),
                    if (item.memo.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildStyledDetailRow(
                        Icons.note_alt_outlined,
                        l10n?.memo ?? 'Memo',
                        item.memo,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // 🔥 반응형 버튼 레이아웃
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmallScreen = constraints.maxWidth < 350;
                        
                        if (isSmallScreen) {
                          // 작은 화면: 세로로 배치
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 44,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _showRecommendRoute(item);
                                        },
                                        icon: const Icon(Icons.directions, size: 18),
                                        label: const Text('추천경로'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF10B981),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SizedBox(
                                      height: 44,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          debugPrint('🔘 위치 보기 버튼 클릭됨!');
                                          Navigator.pop(context);
                                          _showBuildingLocation(item);
                                        },
                                        icon: const Icon(Icons.location_on, size: 18),
                                        label: const Text('위치 보기'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF8B5CF6),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 44,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _showEditScheduleDialog(item);
                                        },
                                        icon: const Icon(Icons.edit, size: 18),
                                        label: Text(l10n?.edit ?? 'Edit'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1E3A8A),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await _showDeleteConfirmDialog(item);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFEF4444),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Icon(Icons.delete, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        } else {
                          // 큰 화면: 가로로 배치
                          return Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showRecommendRoute(item);
                                    },
                                    icon: const Icon(Icons.directions, size: 18),
                                    label: const Text('추천경로'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      debugPrint('🔘 위치 보기 버튼 클릭됨!');
                                      Navigator.pop(context);
                                      _showBuildingLocation(item);
                                    },
                                    icon: const Icon(Icons.location_on, size: 18),
                                    label: const Text('위치 보기'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF8B5CF6),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showEditScheduleDialog(item);
                                    },
                                    icon: const Icon(Icons.edit, size: 18),
                                    label: Text(l10n?.edit ?? 'Edit'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E3A8A),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await _showDeleteConfirmDialog(item);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Icon(Icons.delete, size: 18),
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          '닫기',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
