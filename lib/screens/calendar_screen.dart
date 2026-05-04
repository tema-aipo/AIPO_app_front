import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'ipo_detail_screen.dart';

// Dummy Models
class CalendarEvent {
  final String dateKey; // e.g. "2026-04-08"
  final String name; // e.g. "스페이스테크놀로지"
  final EventType type;
  
  CalendarEvent(this.dateKey, this.name, this.type);
}

enum EventType {
  demandForecast, // 수요예측 (Pink)
  subscription,   // 청약 (Blue)
  listing,        // 상장 (Green)
  refund,         // 환불 (Orange)
  favorite        // 관심 (Purple)
}

extension EventTypeExtension on EventType {
  String get label {
    switch (this) {
      case EventType.demandForecast: return '수요예측';
      case EventType.subscription: return '청약';
      case EventType.listing: return '상장';
      case EventType.refund: return '환불';
      case EventType.favorite: return '관심';
    }
  }

  Color get textColor {
    switch (this) {
      case EventType.demandForecast: return const Color(0xFFFF2E82);
      case EventType.subscription: return AppColors.primary;
      case EventType.listing: return const Color(0xFF00C875);
      case EventType.refund: return const Color(0xFFFF5E00);
      case EventType.favorite: return const Color(0xFF9E00FF);
    }
  }

  Color get bgColor {
    switch (this) {
      case EventType.demandForecast: return const Color(0xFFFFF0F5);
      case EventType.subscription: return AppColors.bgLightBlue;
      case EventType.listing: return const Color(0xFFEFFFF6);
      case EventType.refund: return const Color(0xFFFFF4E8);
      case EventType.favorite: return const Color(0xFFF7F0FF);
    }
  }
}

// Model for detail list
class DailyTask {
  final int score;
  final String name;
  final String broker;
  final EventType type;

  DailyTask({required this.score, required this.name, required this.broker, required this.type});
}

class CalendarCell {
  final DateTime date;
  final bool isCurrentMonth;

  CalendarCell({required this.date, required this.isCurrentMonth});
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentDate = DateTime(2026, 4, 1);
  DateTime _selectedDate = DateTime(2026, 4, 8); // 기본값: 2026년 4월 8일

  final Set<EventType> _activeFilters = EventType.values.toSet();

  // Events dictionary by date key (YYYY-MM-DD)
  final Map<String, List<CalendarEvent>> _eventsMap = {
    "2026-04-08": [
      CalendarEvent("2026-04-08", '스페이스테', EventType.subscription),
      CalendarEvent("2026-04-08", '바이오메디', EventType.demandForecast),
    ],
    "2026-04-10": [
      CalendarEvent("2026-04-10", '바이오메디', EventType.listing),
    ],
    "2026-04-14": [
      CalendarEvent("2026-04-14", 'AI솔루션즈', EventType.demandForecast),
    ],
    "2026-04-15": [
      CalendarEvent("2026-04-15", 'AI솔루션즈', EventType.demandForecast),
    ],
  };

  // Detailed Tasks by date key
  final Map<String, List<DailyTask>> _dailyTasksMap = {
    "2026-04-08": [
      DailyTask(score: 92, name: '스페이스테크놀로지', broker: '미래에셋증권', type: EventType.subscription),
      DailyTask(score: 85, name: '바이오메디컬', broker: '신영증권', type: EventType.demandForecast),
    ],
    "2026-04-10": [
      DailyTask(score: 85, name: '바이오메디컬', broker: '신영증권', type: EventType.listing),
    ],
    "2026-04-14": [
      DailyTask(score: 70, name: 'AI솔루션즈', broker: '한국투자증권', type: EventType.demandForecast),
    ],
    "2026-04-15": [
      DailyTask(score: 70, name: 'AI솔루션즈', broker: '한국투자증권', type: EventType.demandForecast),
    ],
  };

  String _getDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  void _nextMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
      _selectedDate = _currentDate; // select 1st of new month
    });
  }

  void _prevMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
      _selectedDate = _currentDate; // select 1st of new month
    });
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('공모주 일정 검색', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
          content: const Text(
            '지금은 기능 연동 대기중입니다.\n향후 백엔드 데이터 연결 시 상세 검색 화면이 열립니다.',
            style: TextStyle(color: AppColors.textGray, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }

  List<CalendarCell> _generateMonthCells() {
    List<CalendarCell> cells = [];
    DateTime firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    
    // Find the Monday of the week containing the 1st
    // If 1st is Sat or Sun, we don't need to show the previous Mon-Fri week.
    int daysToSubtract;
    if (firstDayOfMonth.weekday >= 6) {
      daysToSubtract = -(8 - firstDayOfMonth.weekday);
    } else {
      daysToSubtract = firstDayOfMonth.weekday - 1; 
    }
    
    DateTime currentDateIterator = firstDayOfMonth.subtract(Duration(days: daysToSubtract));

    DateTime lastDayOfMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0);

    while (true) {
      if (currentDateIterator.weekday <= 5) {
        cells.add(CalendarCell(
          date: currentDateIterator,
          isCurrentMonth: currentDateIterator.month == _currentDate.month && currentDateIterator.year == _currentDate.year,
        ));
      }
      currentDateIterator = currentDateIterator.add(const Duration(days: 1));
      
      bool isNextMonth = currentDateIterator.isAfter(lastDayOfMonth);
      
      if (isNextMonth && cells.length % 5 == 0) {
        break; 
      }
    }
    
    return cells;
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: EventType.values.map((type) {
          final bool isActive = _activeFilters.contains(type);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isActive) {
                  _activeFilters.remove(type);
                } else {
                  _activeFilters.add(type);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                type.label,
                style: TextStyle(
                  color: isActive ? type.textColor : AppColors.textGray.withOpacity(0.5),
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayHeaders() {
    const headers = ['월', '화', '수', '목', '금'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: headers.map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    List<CalendarCell> cells = _generateMonthCells();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cells.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 0.82,
          mainAxisSpacing: 16,
          crossAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          final cell = cells[index];
          final String dateKey = _getDateKey(cell.date);
          final bool isSelected = dateKey == _getDateKey(_selectedDate);
          
          List<CalendarEvent> allEvents = _eventsMap[dateKey] ?? [];
          List<CalendarEvent> visibleEvents = allEvents.where((e) => _activeFilters.contains(e.type)).toList();

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = cell.date;
                // Update current month if tapping a grayed out date from previous/next month!
                if (!cell.isCurrentMonth) {
                  _currentDate = DateTime(cell.date.year, cell.date.month, 1);
                }
              });
            },
            child: Container(
              color: Colors.transparent, 
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        cell.date.day.toString(),
                        style: TextStyle(
                          color: isSelected ? AppColors.white : (cell.isCurrentMonth ? AppColors.textDark : AppColors.textGray.withOpacity(0.4)),
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...visibleEvents.take(2).map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                      decoration: BoxDecoration(
                        color: e.type.bgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        e.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: e.type.textColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskList() {
    final String dateKey = _getDateKey(_selectedDate);
    final allTasks = _dailyTasksMap[dateKey] ?? [];
    final tasks = allTasks.where((t) => _activeFilters.contains(t.type)).toList();
    
    const weekdayLabels = {1: '월', 2: '화', 3: '수', 4: '목', 5: '금', 6: '토', 7: '일'};
    String weekdayStr = weekdayLabels[_selectedDate.weekday] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.day.toString().padLeft(2, '0')} ($weekdayStr)', 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
          const SizedBox(height: 16),
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('해당 날짜에는 특이 일정이 없습니다.', style: TextStyle(color: AppColors.textGray))),
            ),
          ...tasks.map((task) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => IpoDetailScreen(ipoName: task.name),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderGray.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(color: AppColors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${task.score}점',
                      style: const TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.name,
                            style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            task.broker,
                            style: const TextStyle(color: AppColors.textGray, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: task.type.bgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        task.type.label,
                        style: TextStyle(color: task.type.textColor, fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.chevron_right, color: AppColors.textGray, size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InkWell(
              onTap: _prevMonth,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Icon(Icons.chevron_left, color: AppColors.textDark, size: 22),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_currentDate.year}년 ${_currentDate.month}월',
              style: const TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _nextMonth,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Icon(Icons.chevron_right, color: AppColors.textDark, size: 22),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textDark),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildLegend(),
            const SizedBox(height: 24),
            _buildDayHeaders(),
            const SizedBox(height: 16),
            _buildCalendarGrid(),
            const SizedBox(height: 24),
            const Divider(color: AppColors.borderGray, thickness: 0.5),
            const SizedBox(height: 24),
            _buildTaskList(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
