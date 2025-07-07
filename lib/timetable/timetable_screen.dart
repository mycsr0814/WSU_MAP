// lib/schedule/schedule_screen.dart - 수정된 버전

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../generated/app_localizations.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late String _currentSemester;
  List<ScheduleItem> _scheduleItems = [];
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    // context 관련 코드는 여기서 제거
    _loadScheduleItems();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 한 번만 초기화되도록 플래그 사용
    if (!_isInitialized) {
      _isInitialized = true;
      _currentSemester = _getCurrentSemester();
    }
  }
  
  // 현재 학기 자동 계산 - context 안전하게 사용
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
  
  // 현재 연도 자동 계산
  int _getCurrentYear() {
    return DateTime.now().year;
  }

  // 스케줄 저장
  Future<void> _saveScheduleItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _scheduleItems.map((item) => item.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString('schedule_items', jsonString);
  }

  // 스케줄 불러오기
  Future<void> _loadScheduleItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('schedule_items');
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      if (mounted) {
        setState(() {
          _scheduleItems = jsonList.map((json) => ScheduleItem.fromJson(json)).toList();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 초기화가 완료되지 않았으면 로딩 표시
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildScheduleView(),
            ),
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
                      l10n?.current_year(_getCurrentYear()) ?? '${_getCurrentYear()}',
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
          Expanded(
            child: _buildTimeTable(),
          ),
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
      l10n?.friday ?? 'Fri'
    ];
    
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: days.map((day) => Expanded(
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
        )).toList(),
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
          bottom: BorderSide(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 시간 컬럼
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
          // 요일별 컬럼 (월~금)
          ...List.generate(5, (dayIndex) {
            final scheduleItem = _getScheduleForTimeAndDay(timeSlot, dayIndex + 1);
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
          border: Border.all(
            color: item.color.withOpacity(0.3),
            width: 1,
          ),
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
              item.location,
              style: TextStyle(
                fontSize: 9,
                color: item.color.withOpacity(0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // 헬퍼 메서드들
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
      case 1: return l10n?.monday_full ?? 'Monday';
      case 2: return l10n?.tuesday_full ?? 'Tuesday';
      case 3: return l10n?.wednesday_full ?? 'Wednesday';
      case 4: return l10n?.thursday_full ?? 'Thursday';
      case 5: return l10n?.friday_full ?? 'Friday';
      default: return '';
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF1E3A8A),
        ),
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
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddScheduleDialog() {
    final l10n = AppLocalizations.of(context);
    final TextEditingController titleController = TextEditingController();
    final TextEditingController professorController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    int selectedDay = 1;
    String startTime = '09:00';
    String endTime = '10:30';
    Color selectedColor = const Color(0xFF3B82F6);
    
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n?.add_class ?? 'Add Class'),
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
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: l10n?.classroom ?? 'Classroom',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: l10n?.day_of_week ?? 'Day',
                    border: const OutlineInputBorder(),
                  ),
                  value: selectedDay,
                  items: [
                    DropdownMenuItem(value: 1, child: Text(l10n?.monday_full ?? 'Monday')),
                    DropdownMenuItem(value: 2, child: Text(l10n?.tuesday_full ?? 'Tuesday')),
                    DropdownMenuItem(value: 3, child: Text(l10n?.wednesday_full ?? 'Wednesday')),
                    DropdownMenuItem(value: 4, child: Text(l10n?.thursday_full ?? 'Thursday')),
                    DropdownMenuItem(value: 5, child: Text(l10n?.friday_full ?? 'Friday')),
                  ],
                  onChanged: (value) {
                    setState(() => selectedDay = value!);
                  },
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
                        items: _generateTimeSlots().map((time) =>
                          DropdownMenuItem(value: time, child: Text(time))
                        ).toList(),
                        onChanged: (value) {
                          setState(() => startTime = value!);
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
                        items: _generateTimeSlots().map((time) =>
                          DropdownMenuItem(value: time, child: Text(time))
                        ).toList(),
                        onChanged: (value) {
                          setState(() => endTime = value!);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n?.color_selection ?? 'Select Color',
                  style: const TextStyle(fontWeight: FontWeight.w600)
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && locationController.text.isNotEmpty) {
                  final newItem = ScheduleItem(
                    title: titleController.text,
                    professor: professorController.text,
                    location: locationController.text,
                    dayOfWeek: selectedDay,
                    startTime: startTime,
                    endTime: endTime,
                    color: selectedColor,
                  );
                  
                  setState(() {
                    _scheduleItems.add(newItem);
                  });
                  
                  _saveScheduleItems();
                  Navigator.pop(context);
                }
              },
              child: Text(l10n?.add ?? 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleDetail(ScheduleItem item) {
    final l10n = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(Icons.person, l10n?.professor_name ?? 'Professor', item.professor),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.location_on, l10n?.classroom ?? 'Classroom', item.location),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.calendar_today, l10n?.day_of_week ?? 'Day', _getDayName(item.dayOfWeek)),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.access_time, l10n?.time ?? 'Time', '${item.startTime} - ${item.endTime}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.close ?? 'Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditScheduleDialog(item);
            },
            child: Text(l10n?.edit ?? 'Edit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteScheduleItem(item);
            },
            child: Text(
              l10n?.delete ?? 'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditScheduleDialog(ScheduleItem item) {
    final l10n = AppLocalizations.of(context);
    final TextEditingController titleController = TextEditingController(text: item.title);
    final TextEditingController professorController = TextEditingController(text: item.professor);
    final TextEditingController locationController = TextEditingController(text: item.location);
    int selectedDay = item.dayOfWeek;
    String startTime = item.startTime;
    String endTime = item.endTime;
    Color selectedColor = item.color;
    
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n?.edit_class ?? 'Edit Class'),
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
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: l10n?.classroom ?? 'Classroom',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: l10n?.day_of_week ?? 'Day',
                    border: const OutlineInputBorder(),
                  ),
                  value: selectedDay,
                  items: [
                    DropdownMenuItem(value: 1, child: Text(l10n?.monday_full ?? 'Monday')),
                    DropdownMenuItem(value: 2, child: Text(l10n?.tuesday_full ?? 'Tuesday')),
                    DropdownMenuItem(value: 3, child: Text(l10n?.wednesday_full ?? 'Wednesday')),
                    DropdownMenuItem(value: 4, child: Text(l10n?.thursday_full ?? 'Thursday')),
                    DropdownMenuItem(value: 5, child: Text(l10n?.friday_full ?? 'Friday')),
                  ],
                  onChanged: (value) {
                    setState(() => selectedDay = value!);
                  },
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
                        items: _generateTimeSlots().map((time) =>
                          DropdownMenuItem(value: time, child: Text(time))
                        ).toList(),
                        onChanged: (value) {
                          setState(() => startTime = value!);
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
                        items: _generateTimeSlots().map((time) =>
                          DropdownMenuItem(value: time, child: Text(time))
                        ).toList(),
                        onChanged: (value) {
                          setState(() => endTime = value!);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n?.color_selection ?? 'Select Color',
                  style: const TextStyle(fontWeight: FontWeight.w600)
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && locationController.text.isNotEmpty) {
                  final updatedItem = ScheduleItem(
                    title: titleController.text,
                    professor: professorController.text,
                    location: locationController.text,
                    dayOfWeek: selectedDay,
                    startTime: startTime,
                    endTime: endTime,
                    color: selectedColor,
                  );
                  
                  setState(() {
                    final index = _scheduleItems.indexOf(item);
                    _scheduleItems[index] = updatedItem;
                  });
                  
                  _saveScheduleItems();
                  Navigator.pop(context);
                }
              },
              child: Text(l10n?.save ?? 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteScheduleItem(ScheduleItem item) {
    setState(() {
      _scheduleItems.remove(item);
    });
    _saveScheduleItems();
  }
}

// ScheduleItem 클래스 정의
class ScheduleItem {
  final String title;
  final String professor;
  final String location;
  final int dayOfWeek; // 1: 월, 2: 화, 3: 수, 4: 목, 5: 금
  final String startTime;
  final String endTime;
  final Color color;

  ScheduleItem({
    required this.title,
    required this.professor,
    required this.location,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'professor': professor,
      'location': location,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'color': color.value,
    };
  }

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      title: json['title'],
      professor: json['professor'],
      location: json['location'],
      dayOfWeek: json['dayOfWeek'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      color: Color(json['color']),
    );
  }
}
