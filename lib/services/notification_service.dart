import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ipo_notification.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  // ── SharedPreferences 키 ──────────────────────────────
  static const String _notificationsKey     = 'ipo_notifications_v1';
  static const String _dismissedIdsKey      = 'dismissed_notification_ids_v1';
  static const String _ipoNotifMapKey       = 'ipo_notification_enabled_map_v1';
  static const String _globalAlarmSubKey    = 'global_alarm_subscription_v1';
  static const String _globalAlarmLstKey    = 'global_alarm_listing_v1';

  // ── 알림 목록 ─────────────────────────────────────────
  List<IpoNotification> _notifications = [];
  Set<String> _dismissedIds = {};

  // ── 전역 알림 설정 (마이페이지 알림 설정 바텀시트) ──────
  // 백엔드 API 연동 시 MyPageScreen._fetchData()에서
  // updateGlobalSettings()를 호출해 여기에 미러링
  bool _subscriptionAlarmEnabled = true;
  bool _listingAlarmEnabled = true;

  // ── 종목별 알림 설정 (관심공모주 종 버튼) ───────────────
  // 백엔드 API 연동 시 setIpoNotificationEnabled()에서
  // API 호출을 추가하고 로컬 캐시로 이 Map을 유지
  Map<String, bool> _ipoNotificationEnabled = {};

  // ── 세션 중복 방지 ────────────────────────────────────
  Future<void>? _initFuture;
  bool _popupConsumed = false;

  // ── Public getters ────────────────────────────────────
  List<IpoNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  bool get subscriptionAlarmEnabled => _subscriptionAlarmEnabled;
  bool get listingAlarmEnabled => _listingAlarmEnabled;

  /// 특정 종목의 알림 활성 여부 (기본값: true)
  bool isIpoNotificationEnabled(String ipoId) =>
      _ipoNotificationEnabled[ipoId] ?? true;

  /// 팝업에 표시할 알림: dismiss 안됐고 + 현재 설정에서 활성 상태인 것만
  List<IpoNotification> get popupNotifications => _notifications
      .where((n) => !_dismissedIds.contains(n.id) && _isEnabled(n))
      .toList();

  // ── 초기화 ────────────────────────────────────────────

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

  // ── 설정 업데이트 API (MyPageScreen에서 호출) ─────────

  /// 마이페이지 알림 설정 토글 변경 시 호출.
  /// 백엔드 저장은 MyPageScreen에서 직접 처리하고, 이쪽은 로컬 반영만 담당.
  void updateGlobalSettings({
    required bool subscription,
    required bool listing,
  }) {
    _subscriptionAlarmEnabled = subscription;
    _listingAlarmEnabled = listing;
    _saveGlobalSettings(); // fire-and-forget
    notifyListeners();
  }

  /// 관심공모주 종 버튼 토글 시 호출.
  /// 로컬(SharedPreferences)에 즉시 저장.
  ///
  /// [백엔드 연동 시] MyPageScreen에서 아래를 추가:
  ///   await _userService.updateIpoNotificationSetting(ipoId: ipoId, enabled: enabled);
  Future<void> setIpoNotificationEnabled(String ipoId, bool enabled) async {
    _ipoNotificationEnabled[ipoId] = enabled;
    await _saveIpoNotifMap();
    notifyListeners();
  }

  // ── 알림 조작 ─────────────────────────────────────────

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

  Future<void> _doInitialize() async {
    await _loadFromPrefs();
    _mergeDummyNotifications();
    await _saveToPrefs();
    notifyListeners();
  }

  /// 전역 설정 + 종목별 설정 양쪽을 모두 고려해 알림 포함 여부 결정
  bool _isEnabled(IpoNotification n) {
    if (n.type == 'subscription' && !_subscriptionAlarmEnabled) return false;
    if (n.type == 'listing' && !_listingAlarmEnabled) return false;
    return _ipoNotificationEnabled[n.ipoId] ?? true;
  }

  void _mergeDummyNotifications() {
    for (final dummy in _dummyNotifications()) {
      final exists = _notifications.any((n) => n.id == dummy.id);
      if (!exists) _notifications.add(dummy);
    }
    _notifications.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
  }

  // ── 임시 하드코딩 더미 데이터 (백엔드 연동 전) ──────────
  // 연동 시 이 메서드를 관심공모주 API 호출 결과로 교체:
  //   final favs = await _userService.getFavorites();
  //   return favs.where(날짜 D-7 이내).map(IpoNotification.fromApi).toList();
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

  // ── SharedPreferences ────────────────────────────────

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // 알림 목록
    final notifJson = prefs.getString(_notificationsKey);
    if (notifJson != null) {
      try {
        _notifications = IpoNotification.decodeList(notifJson);
      } catch (_) {
        _notifications = [];
      }
    }

    // dismiss된 ID 목록
    final dismissed = prefs.getStringList(_dismissedIdsKey);
    if (dismissed != null) {
      _dismissedIds = dismissed.toSet();
    }

    // 종목별 알림 설정
    final ipoNotifJson = prefs.getString(_ipoNotifMapKey);
    if (ipoNotifJson != null) {
      try {
        final raw = jsonDecode(ipoNotifJson) as Map<String, dynamic>;
        _ipoNotificationEnabled = raw.map((k, v) => MapEntry(k, v as bool));
      } catch (_) {
        _ipoNotificationEnabled = {};
      }
    }

    // 전역 알림 설정 (마지막으로 백엔드에서 받아온 값의 로컬 캐시)
    _subscriptionAlarmEnabled = prefs.getBool(_globalAlarmSubKey) ?? true;
    _listingAlarmEnabled = prefs.getBool(_globalAlarmLstKey) ?? true;
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _notificationsKey, IpoNotification.encodeList(_notifications));
    await prefs.setStringList(_dismissedIdsKey, _dismissedIds.toList());
  }

  Future<void> _saveIpoNotifMap() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ipoNotifMapKey, jsonEncode(_ipoNotificationEnabled));
  }

  Future<void> _saveGlobalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_globalAlarmSubKey, _subscriptionAlarmEnabled);
    await prefs.setBool(_globalAlarmLstKey, _listingAlarmEnabled);
  }
}
