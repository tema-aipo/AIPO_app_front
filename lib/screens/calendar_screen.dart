import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'ipo_detail_screen.dart';
import '../services/ipo_service.dart';
import '../services/user_service.dart';

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
      case EventType.demandForecast: return const Color(0xFFD32F2F);
      case EventType.subscription: return AppColors.primary;
      case EventType.listing: return const Color(0xFF107C41);
      case EventType.refund: return const Color(0xFFFF5E00);
      case EventType.favorite: return const Color(0xFF9E00FF);
    }
  }

  Color get bgColor {
    switch (this) {
      case EventType.demandForecast: return const Color(0xFFFFEAEA);
      case EventType.subscription: return AppColors.bgLightBlue;
      case EventType.listing: return const Color(0xFFE2F6EA);
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
  State<CalendarScreen> createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  final IpoService _ipoService = IpoService();
  final UserService _userService = UserService();
  late DateTime _currentDate;
  DateTime? _selectedDate;
  bool _isLoading = true;

  final Set<EventType> _activeFilters = EventType.values.toSet();
  Map<String, List<CalendarEvent>> _eventsMap = {};
  final Set<String> _favoriteIpoIds = {};
  final GlobalKey _taskListKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentDate = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _fetchCalendarData();
  }

  void refresh() {
    _fetchCalendarData(showLoading: false);
  }

  Future<void> _fetchCalendarData({DateTime? targetSelectedDate, bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }
    try {
      // 관심종목 조회
      try {
        final favs = await _userService.getFavorites();
        _favoriteIpoIds.clear();
        for (var f in favs) {
          final id = f['ipoId']?.toString();
          if (id != null) {
            _favoriteIpoIds.add(id);
          }
        }
      } catch (e) {
        debugPrint('[Calendar] Failed to fetch favorites: $e');
      }

      final monthStr = "${_currentDate.year}-${_currentDate.month.toString().padLeft(2, '0')}";
      
      String? selectedDateParam;
      if (targetSelectedDate != null) {
        selectedDateParam = "${targetSelectedDate.year}-${targetSelectedDate.month.toString().padLeft(2, '0')}-${targetSelectedDate.day.toString().padLeft(2, '0')}";
      } else if (_selectedDate != null && _selectedDate!.year == _currentDate.year && _selectedDate!.month == _currentDate.month) {
        selectedDateParam = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
      }

      final rawData = await _ipoService.getCalendarData(monthStr, selectedDate: selectedDateParam);

      final Map<String, List<CalendarEvent>> newMap = {};

      void mergeCells(List<dynamic> cells) {
        for (var cell in cells) {
          final String date = cell['date']; // YYYY-MM-DD
          final List<dynamic> items = cell['items'] ?? [];

          for (var item in items) {
            final String typeStr = item['scheduleType'] ?? '';

            EventType? type;
            if (typeStr.contains('DEMAND_FORECAST')) {
              type = EventType.demandForecast;
            } else if (typeStr.contains('SUBSCRIPTION')) {
              type = EventType.subscription;
            } else if (typeStr.contains('REFUND')) {
              type = EventType.refund;
            } else if (typeStr.contains('LISTING')) {
              type = EventType.listing;
            }

            if (type != null) {
              final String ipoId = item['ipoId'].toString();
              final event = CalendarEvent(
                ipoId: ipoId,
                name: item['companyName'] ?? '',
                type: _favoriteIpoIds.contains(ipoId) ? EventType.favorite : type,
                score: null,
                leadManager: null,
              );

              final existing = newMap[date] ??= [];
              final key = '${event.ipoId}_${event.type}';
              if (!existing.any((e) => '${e.ipoId}_${e.type}' == key)) {
                existing.add(event);
              }
            }
          }
        }
      }

      // 1. 달력 칸 정보(calendarCells) 파싱
      mergeCells(rawData['calendarCells'] ?? []);

      // 1-1. 표시 grid에 걸친 이전/다음 달의 cells도 병렬로 가져와 머지
      final overflowMonths = <String>{};
      for (final c in _generateMonthCells()) {
        if (!c.isCurrentMonth) {
          overflowMonths.add(
            "${c.date.year}-${c.date.month.toString().padLeft(2, '0')}",
          );
        }
      }
      if (overflowMonths.isNotEmpty) {
        final extras = await Future.wait(overflowMonths.map((m) async {
          try {
            final extra = await _ipoService.getCalendarData(m);
            return (extra['calendarCells'] as List<dynamic>?) ?? const [];
          } catch (_) {
            return const <dynamic>[];
          }
        }));
        for (final cells in extras) {
          mergeCells(cells);
        }
      }
      
      // 2. 선택된 날짜 상세 섹션(selectedDateSection) 파싱하여 덮어쓰기 (상세 점수 및 주관사 정보 추가)
      final selectedDateSection = rawData['selectedDateSection'];
      DateTime? resolvedSelectedDate;
      if (selectedDateSection != null) {
        final String? selDateStr = selectedDateSection['selectedDate']; // YYYY-MM-DD
        if (selDateStr != null) {
          final dateParts = selDateStr.split('-');
          resolvedSelectedDate = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
          );
          
          final List<dynamic> companies = selectedDateSection['companies'] ?? [];
          final List<CalendarEvent> selectedEvents = [];
          
          for (var comp in companies) {
            final String typeStr = comp['scheduleType'] ?? '';
            EventType? type;
            if (typeStr.contains('DEMAND_FORECAST')) {
              type = EventType.demandForecast;
            } else if (typeStr.contains('SUBSCRIPTION')) {
              type = EventType.subscription;
            } else if (typeStr.contains('REFUND')) {
              type = EventType.refund;
            } else if (typeStr.contains('LISTING')) {
              type = EventType.listing;
            }
            
            if (type != null) {
              final double? scoreDouble = comp['attractionScore'] != null 
                  ? (comp['attractionScore'] as num).toDouble() 
                  : null;
              final int? scoreInt = scoreDouble?.toInt();
              final String ipoId = comp['ipoId'].toString();

              selectedEvents.add(CalendarEvent(
                ipoId: ipoId,
                name: comp['companyName'] ?? '',
                type: _favoriteIpoIds.contains(ipoId) ? EventType.favorite : type,
                score: scoreInt,
                leadManager: comp['securitiesCompanyName'],
              ));
            }
          }
          
          if (selectedEvents.isNotEmpty) {
            final existing = newMap[selDateStr] ?? [];
            final mergedKeys = selectedEvents.map((e) => '${e.ipoId}_${e.type}').toSet();
            final filtered = existing.where((e) => !mergedKeys.contains('${e.ipoId}_${e.type}')).toList();
            newMap[selDateStr] = [...filtered, ...selectedEvents];
          }
        }
      }

      setState(() {
        _eventsMap = newMap;
        if (resolvedSelectedDate != null) {
          if (targetSelectedDate != null) {
            _selectedDate = targetSelectedDate;
          } else if (_selectedDate != null) {
            _selectedDate = resolvedSelectedDate;
          }
        }
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
      final today = DateTime.now();
      if (_currentDate.year == today.year && _currentDate.month == today.month) {
        _selectedDate = DateTime(today.year, today.month, today.day);
      } else {
        _selectedDate = null;
      }
    });
    _fetchCalendarData();
  }

  void _prevMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
      final today = DateTime.now();
      if (_currentDate.year == today.year && _currentDate.month == today.month) {
        _selectedDate = DateTime(today.year, today.month, today.day);
      } else {
        _selectedDate = null;
      }
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
          : Column(
              children: [
                const SizedBox(height: 8),
                _buildLegend(),
                const SizedBox(height: 12),
                const Divider(color: AppColors.borderGray, height: 1, thickness: 0.5),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
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
                ),
              ],
            ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: EventType.values.map((type) {
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
          
          final today = DateTime.now();
          final isToday = cell.date.year == today.year &&
              cell.date.month == today.month &&
              cell.date.day == today.day;
          final isSelected = _selectedDate != null && dateKey == _getDateKey(_selectedDate!);
          
          final events = (_eventsMap[dateKey] ?? []).where((e) => _activeFilters.contains(e.type)).toList();

          Widget dateWidget;
          if (isToday) {
            dateWidget = Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '오늘',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            );
          } else if (isSelected) {
            dateWidget = Container(
              width: 30, height: 30,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  cell.date.day.toString(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            );
          } else {
            dateWidget = Text(
              cell.date.day.toString(),
              style: TextStyle(
                color: cell.isCurrentMonth
                    ? AppColors.textDark
                    : AppColors.textGray.withOpacity(0.3),
                fontWeight: FontWeight.bold,
              ),
            );
          }

          return GestureDetector(
            onTap: () {
              final bool jumpToOtherMonth = !cell.isCurrentMonth;
              setState(() {
                if (jumpToOtherMonth) {
                  _currentDate = DateTime(cell.date.year, cell.date.month, 1);
                }
                _selectedDate = cell.date;
              });
              _fetchCalendarData(
                targetSelectedDate: cell.date,
                showLoading: jumpToOtherMonth,
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final ctx = _taskListKey.currentContext;
                if (ctx != null) {
                  Scrollable.ensureVisible(
                    ctx,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    alignment: 0.0,
                  );
                }
              });
            },
            child: Column(
              children: [
                SizedBox(
                  height: 30,
                  child: Center(child: dateWidget),
                ),
                const SizedBox(height: 4),
                ...events.take(2).map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  decoration: BoxDecoration(color: e.type.bgColor, borderRadius: BorderRadius.circular(2)),
                  child: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: e.type.textColor, fontSize: 8, fontWeight: FontWeight.bold)),
                )),
                if (events.length > 2)
                  Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.bgGray,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      '+${events.length - 2}',
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskList() {
    if (_selectedDate == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: Text(
            '일정을 확인하려면 날짜를 선택해주세요.',
            style: TextStyle(color: AppColors.textGray, fontSize: 14),
          ),
        ),
      );
    }

    final dateKey = _getDateKey(_selectedDate!);
    final tasks = (_eventsMap[dateKey] ?? []).where((t) => _activeFilters.contains(t.type)).toList();

    return Padding(
      key: _taskListKey,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_selectedDate!.month}/${_selectedDate!.day} 일정', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (tasks.isEmpty) 
            const Center(child: Text('일정이 없습니다.'))
          else 
            ...tasks.map((task) => _buildIpoCard(
              score: task.score ?? 0,
              ipoName: task.name,
              leadManager: task.leadManager ?? '-',
              dateLabel: '${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.day.toString().padLeft(2, '0')}',
              status: task.type.label,
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.borderGray),
              onTap: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => IpoDetailScreen(ipoId: task.ipoId, ipoName: task.name))
              ).then((_) => _fetchCalendarData(showLoading: false)),
            )),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    switch (status) {
      case '수요예측':
        bg = const Color(0xFFFFEAEA); text = const Color(0xFFD32F2F);
        break;
      case '상장':
        bg = const Color(0xFFE2F6EA); text = const Color(0xFF107C41);
        break;
      case '청약종료':
        bg = const Color(0xFFF3F3F3); text = AppColors.textGray;
        break;
      case '환불':
        bg = const Color(0xFFFFF0E6); text = const Color(0xFFFF5E00);
        break;
      case '관심':
        bg = const Color(0xFFF5E6FF); text = const Color(0xFF9E00FF);
        break;
      default: // 청약
        bg = AppColors.bgLightBlue; text = AppColors.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildIpoCard({
    required int score,
    required String ipoName,
    required String leadManager,
    required String dateLabel,
    String? status,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderGray.withOpacity(0.5)),
          boxShadow: [BoxShadow(
            color: AppColors.black.withOpacity(0.015),
            blurRadius: 10, offset: const Offset(0, 4),
          )],
        ),
        child: Row(
          children: [
            // 좌측: 점수 + 상태뱃지
            SizedBox(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• $score점',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (status != null) ...[
                    const SizedBox(height: 6),
                    _buildStatusBadge(status),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 중앙: 종목명 + 주관사 + 날짜
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ipoName,
                    style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    leadManager,
                    style: const TextStyle(
                      color: AppColors.textGray, fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      color: AppColors.textGray, fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // 우측: 액션 영역
            trailing,
          ],
        ),
      ),
    );
  }
}
