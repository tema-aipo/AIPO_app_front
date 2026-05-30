import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ipo_notification.dart';
import '../network/dio_client.dart';
import '../network/api_endpoints.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final Dio _dio = DioClient.instance.dio;

  // ── SharedPreferences 키 ──────────────────────────────
  static const String _dismissedIdsKey   = 'dismissed_notification_ids_v1';
  static const String _globalAlarmSubKey = 'global_alarm_subscription_v1';
  static const String _globalAlarmLstKey = 'global_alarm_listing_v1';

  // ── 알림 목록 ─────────────────────────────────────────
  List<IpoNotification> _notifications = [];
  Set<String> _dismissedIds = {};

  // ── 전역 알림 설정 ─────────────────────────────────────
  bool _subscriptionAlarmEnabled = true;
  bool _listingAlarmEnabled = true;

  // ── 종목별 알림 설정 (MyPageScreen 페치 후 syncIpoNotificationMap으로 동기화) ──
  Map<String, bool> _ipoNotificationEnabled = {};

  // ── 세션 중복 방지 ────────────────────────────────────
  Future<void>? _initFuture;
  bool _popupConsumed = false;

  // ── Public getters ────────────────────────────────────
  List<IpoNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get subscriptionAlarmEnabled => _subscriptionAlarmEnabled;
  bool get listingAlarmEnabled => _listingAlarmEnabled;
  bool isIpoNotificationEnabled(String ipoId) => _ipoNotificationEnabled[ipoId] ?? true;

  List<IpoNotification> get popupNotifications => _notifications
      .where((n) => !n.isRead && !_dismissedIds.contains(n.id) && _isEnabled(n))
      .toList();

  // ── 초기화 ────────────────────────────────────────────

  Future<void> initialize() {
    _initFuture ??= _doInitialize();
    return _initFuture!;
  }

  /// 로그아웃 시 호출 — 다음 로그인 후 재초기화 가능하도록 상태 초기화
  void reset() {
    _initFuture = null;
    _notifications = [];
    _dismissedIds = {};
    _ipoNotificationEnabled = {};
    _popupConsumed = false;
    notifyListeners();
  }

  Future<void> refreshNotifications() => _fetchNotifications();

  bool consumeAndCheckPopup() {
    if (_popupConsumed || popupNotifications.isEmpty) return false;
    _popupConsumed = true;
    return true;
  }

  // ── 설정 업데이트 ─────────────────────────────────────

  void updateGlobalSettings({
    required bool subscription,
    required bool listing,
  }) {
    _subscriptionAlarmEnabled = subscription;
    _listingAlarmEnabled = listing;
    _saveGlobalSettings();
    notifyListeners();
  }

  /// MyPageScreen에서 favorites 페치 후 호출해 종목별 알림 설정 동기화
  void syncIpoNotificationMap(Map<String, bool> map) {
    _ipoNotificationEnabled = Map.from(map);
    notifyListeners();
  }

  /// 관심공모주 종 버튼 토글 시 호출 — 낙관적 업데이트 후 API 저장
  Future<void> setIpoNotificationEnabled(String ipoId, bool enabled) async {
    _ipoNotificationEnabled[ipoId] = enabled;
    notifyListeners();
    try {
      await _dio.patch(
        ApiEndpoints.favoriteNotification(ipoId),
        data: {'enabled': enabled},
      );
    } catch (_) {
      _ipoNotificationEnabled.remove(ipoId);
      notifyListeners();
      rethrow;
    }
  }

  // ── 알림 조작 ─────────────────────────────────────────

  Future<void> confirmPopup({required bool dontShowAgain}) async {
    if (dontShowAgain) {
      final ids = popupNotifications.map((n) => n.id).toList();
      _dismissedIds.addAll(ids);
      await _saveDismissedIds();
    }
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    _notifications[idx].isRead = true;
    notifyListeners();
    try {
      await _dio.patch(ApiEndpoints.notificationRead(id));
    } catch (_) {
      _notifications[idx].isRead = false;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    final prev = _notifications.map((n) => n.isRead).toList();
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    try {
      await _dio.patch(ApiEndpoints.notificationReadAll);
    } catch (_) {
      for (var i = 0; i < _notifications.length; i++) {
        _notifications[i].isRead = prev[i];
      }
      notifyListeners();
    }
  }

  Future<void> deleteAll() async {
    final ids = _notifications.map((n) => n.id).toList();
    _notifications.clear();
    _dismissedIds.clear();
    notifyListeners();
    await _saveDismissedIds();
    for (final id in ids) {
      () async {
        try {
          await _dio.delete(ApiEndpoints.notificationDelete(id));
        } catch (_) {}
      }();
    }
  }

  Future<void> deleteNotification(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    final backup = _notifications[idx];
    _notifications.removeAt(idx);
    _dismissedIds.remove(id);
    notifyListeners();
    try {
      await _dio.delete(ApiEndpoints.notificationDelete(id));
    } catch (_) {
      _notifications.insert(idx, backup);
      notifyListeners();
    }
  }

  // ── Private ──────────────────────────────────────────

  Future<void> _doInitialize() async {
    await _loadLocalSettings();
    await _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.notificationItems,
        queryParameters: {'page': 0, 'size': 50},
      );
      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>;
      _notifications = items
          .map((e) => IpoNotification.fromApi(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {
      // 비로그인 또는 네트워크 에러 시 빈 목록 유지
    }
  }

  bool _isEnabled(IpoNotification n) {
    if (n.type == 'subscription' && !_subscriptionAlarmEnabled) return false;
    if (n.type == 'listing' && !_listingAlarmEnabled) return false;
    return _ipoNotificationEnabled[n.ipoId] ?? true;
  }

  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getStringList(_dismissedIdsKey);
    if (dismissed != null) _dismissedIds = dismissed.toSet();
    _subscriptionAlarmEnabled = prefs.getBool(_globalAlarmSubKey) ?? true;
    _listingAlarmEnabled = prefs.getBool(_globalAlarmLstKey) ?? true;
  }

  Future<void> _saveDismissedIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_dismissedIdsKey, _dismissedIds.toList());
  }

  Future<void> _saveGlobalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_globalAlarmSubKey, _subscriptionAlarmEnabled);
    await prefs.setBool(_globalAlarmLstKey, _listingAlarmEnabled);
  }
}
