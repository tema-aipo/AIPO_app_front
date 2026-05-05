import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'ipo_detail_screen.dart';
import '../services/ipo_service.dart';

class CalendarEvent {
  final String ipoId;
  final String name;
  final EventType type;
  final int? score;
  final String? leadManager;
  
  CalendarEvent({
    required this.ipoId,
    required this.name, 
    required this.type,
    this.score,
    this.leadManager,
  });
}

enum EventType {
  demandForecast, // 수요예측
  subscription,   // 청약
  listing,        // 상장
  refund,         // 환불
  favorite        // 관심
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
  final IpoService _ipoService = IpoService();
  late DateTime _currentDate;
  late DateTime _selectedDate;
  bool _isLoading = true;

  final Set<EventType> _activeFilters = EventType.values.toSet();
  Map<String, List<CalendarEvent>> _eventsMap = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentDate = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _fetchCalendarData();
  }

  Future<void> _fetchCalendarData() async {
    setState(() => _isLoading = true);
    try {
      final monthStr = "${_currentDate.year}-${_currentDate.month.toString().padLeft(2, '0')}";
      final rawData = await _ipoService.getCalendarData(monthStr);
      
      final Map<String, List<CalendarEvent>> newMap = {};
      
      for (var item in rawData) {
        final String date = item['date']; // YYYY-MM-DD
        final typeStr = item['eventType']; // SUBSCRIPTION, REFUND, etc.
        
        EventType? type;
        switch (typeStr) {
          case 'DEMAND_FORECAST': type = EventType.demandForecast; break;
          case 'SUBSCRIPTION': type = EventType.subscription; break;
          case 'REFUND': type = EventType.refund; break;
          case 'LISTING': type = EventType.listing; break;
        }
        
        if (type != null) {
          final event = CalendarEvent(
            ipoId: item['ipoId'].toString(),
            name: item['ipoName'],
            type: type,
            score: item['attractionScore'],
            leadManager: item['leadManager'],
          );
          
          if (newMap[date] == null) newMap[date] = [];
          newMap[date]!.add(event);
        }
      }

      setState(() {
        _eventsMap = newMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정을 불러오지 못했습니다: $e')),
        );
      }
    }
  }

  String _getDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  void _nextMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
    });
    _fetchCalendarData();
  }

  void _prevMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
    });
    _fetchCalendarData();
  }

  List<CalendarCell> _generateMonthCells() {
    List<CalendarCell> cells = [];
    DateTime firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    int daysToSubtract = firstDayOfMonth.weekday - 1; 
    if (firstDayOfMonth.weekday >= 6) daysToSubtract = -(8 - firstDayOfMonth.weekday);
    
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
      if (currentDateIterator.isAfter(lastDayOfMonth) && cells.length % 5 == 0) break; 
    }
    return cells;
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
          children: [
            IconButton(icon: const Icon(Icons.chevron_left, color: AppColors.textDark), onPressed: _prevMonth),
            Text('${_currentDate.year}년 ${_currentDate.month}월', style: const TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w800)),
            IconButton(icon: const Icon(Icons.chevron_right, color: AppColors.textDark), onPressed: _nextMonth),
          ],
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildLegend(),
                  const SizedBox(height: 16),
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

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: EventType.values.where((t) => t != EventType.favorite).map((type) {
          final bool isActive = _activeFilters.contains(type);
          return GestureDetector(
            onTap: () => setState(() => isActive ? _activeFilters.remove(type) : _activeFilters.add(type)),
            child: Text(
              type.label,
              style: TextStyle(
                color: isActive ? type.textColor : AppColors.textGray.withOpacity(0.5),
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayHeaders() {
    const headers = ['월', '화', '수', '목', '금'];
    return Row(
      children: headers.map((day) => Expanded(child: Center(child: Text(day, style: const TextStyle(color: AppColors.textGray, fontSize: 14))))).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final cells = _generateMonthCells();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cells.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 0.75, mainAxisSpacing: 12, crossAxisSpacing: 4),
        itemBuilder: (context, index) {
          final cell = cells[index];
          final dateKey = _getDateKey(cell.date);
          final isSelected = dateKey == _getDateKey(_selectedDate);
          final events = (_eventsMap[dateKey] ?? []).where((e) => _activeFilters.contains(e.type)).toList();

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = cell.date),
            child: Column(
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(color: isSelected ? AppColors.primary : Colors.transparent, shape: BoxShape.circle),
                  child: Center(child: Text(cell.date.day.toString(), style: TextStyle(color: isSelected ? AppColors.white : (cell.isCurrentMonth ? AppColors.textDark : AppColors.textGray.withOpacity(0.3)), fontWeight: FontWeight.bold))),
                ),
                const SizedBox(height: 4),
                ...events.take(2).map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  decoration: BoxDecoration(color: e.type.bgColor, borderRadius: BorderRadius.circular(2)),
                  child: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: e.type.textColor, fontSize: 8, fontWeight: FontWeight.bold)),
                )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskList() {
    final dateKey = _getDateKey(_selectedDate);
    final tasks = (_eventsMap[dateKey] ?? []).where((t) => _activeFilters.contains(t.type)).toList();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_selectedDate.month}/${_selectedDate.day} 일정', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (tasks.isEmpty) const Center(child: Text('일정이 없습니다.'))
          else ...tasks.map((task) => GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IpoDetailScreen(ipoId: task.ipoId, ipoName: task.name))),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderGray.withOpacity(0.5))),
              child: Row(
                children: [
                  Text('${task.score ?? '-'}점', style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(task.name, style: const TextStyle(fontWeight: FontWeight.bold)), Text(task.leadManager ?? '-', style: const TextStyle(color: AppColors.textGray, fontSize: 12))])),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: task.type.bgColor, borderRadius: BorderRadius.circular(8)), child: Text(task.type.label, style: TextStyle(color: task.type.textColor, fontSize: 11, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}
