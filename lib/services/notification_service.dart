import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ipo_notification.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  static const String _notificationsKey = 'ipo_notifications_v1';
  static const String _dismissedIdsKey = 'dismissed_notification_ids_v1';

  List<IpoNotification> _notifications = [];
  Set<String> _dismissedIds = {};

  // initialize()가 여러 번 호출돼도 내부 작업은 한 번만 실행
  Future<void>? _initFuture;
  // 팝업이 이미 이번 세션에서 표시 예약됐는지 여부
  bool _popupConsumed = false;

  List<IpoNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  List<IpoNotification> get subscriptionNotifications =>
      _notifications.where((n) => n.type == 'subscription').toList();

  List<IpoNotification> get listingNotifications =>
      _notifications.where((n) => n.type == 'listing').toList();

  /// 팝업에 보여줄 알림 (아직 dismiss하지 않은 항목)
  List<IpoNotification> get popupNotifications =>
      _notifications.where((n) => !_dismissedIds.contains(n.id)).toList();

  /// 앱 시작 시 호출 — 동일 세션에서 중복 호출해도 안전
  Future<void> initialize() {
    _initFuture ??= _doInitialize();
    return _initFuture!;
  }

  /// 팝업 표시 여부를 원자적으로 확인 후 소비.
  /// 여러 MainScreen 인스턴스가 동시에 호출해도 한 번만 true를 반환.
  bool consumeAndCheckPopup() {
    if (_popupConsumed || popupNotifications.isEmpty) return false;
    _popupConsumed = true;
    return true;
  }

  Future<void> _doInitialize() async {
    await _loadFromPrefs();
    _mergeDummyNotifications();
    await _saveToPrefs();
    notifyListeners();
  }

  /// 팝업 확인 버튼 처리
  Future<void> confirmPopup({required bool dontShowAgain}) async {
    if (dontShowAgain) {
      final ids = popupNotifications.map((n) => n.id).toList();
      _dismissedIds.addAll(ids);
    }
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    _notifications[idx].isRead = true;
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    for (final n in _notifications) {
      n.isRead = true;
    }
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> deleteAll() async {
    _notifications.clear();
    _dismissedIds.clear();
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    _dismissedIds.remove(id);
    await _saveToPrefs();
    notifyListeners();
  }

  // ── Private ──────────────────────────────────────────

  void _mergeDummyNotifications() {
    for (final dummy in _dummyNotifications()) {
      final exists = _notifications.any((n) => n.id == dummy.id);
      if (!exists) _notifications.add(dummy);
    }
    // 날짜순 정렬 (가까운 날짜 먼저)
    _notifications.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
  }

  // ── 임시 하드코딩 더미 데이터 (백엔드 연동 전) ──────────────
  // 실제 연동 시 이 메서드를 API 호출로 교체
  List<IpoNotification> _dummyNotifications() {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    return [
      IpoNotification(
        id: 'dummy_sub_1',
        ipoId: 'dummy_1',
        companyName: '에이아이소프트',
        type: 'subscription',
        scheduledDate: base.add(const Duration(days: 2)),
      ),
      IpoNotification(
        id: 'dummy_sub_2',
        ipoId: 'dummy_2',
        companyName: '클라우드테크',
        type: 'subscription',
        scheduledDate: base.add(const Duration(days: 5)),
      ),
      IpoNotification(
        id: 'dummy_lst_1',
        ipoId: 'dummy_3',
        companyName: '스마트모빌리티',
        type: 'listing',
        scheduledDate: base.add(const Duration(days: 4)),
      ),
      IpoNotification(
        id: 'dummy_lst_2',
        ipoId: 'dummy_4',
        companyName: '바이오넥스트',
        type: 'listing',
        scheduledDate: base.add(const Duration(days: 6)),
      ),
    ];
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final notifJson = prefs.getString(_notificationsKey);
    if (notifJson != null) {
      try {
        _notifications = IpoNotification.decodeList(notifJson);
      } catch (_) {
        _notifications = [];
      }
    }

    final dismissed = prefs.getStringList(_dismissedIdsKey);
    if (dismissed != null) {
      _dismissedIds = dismissed.toSet();
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _notificationsKey, IpoNotification.encodeList(_notifications));
    await prefs.setStringList(_dismissedIdsKey, _dismissedIds.toList());
  }
}
