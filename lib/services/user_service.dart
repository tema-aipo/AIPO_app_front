import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../network/api_endpoints.dart';

/// 사용자 정보 및 설정 관련 API 호출을 담당하는 서비스 클래스
class UserService {
  final Dio _dio = DioClient.instance.dio;

  // ── 내 프로필 조회 ──────────────────────────────────
  /// 현재 로그인한 사용자의 프로필 정보를 가져옵니다.
  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final response = await _dio.get(ApiEndpoints.myProfile);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ── 관심 종목 목록 조회 ──────────────────────────────
  /// 사용자가 즐겨찾기한 공모주 목록을 가져옵니다.
  Future<List<dynamic>> getFavorites() async {
    try {
      final response = await _dio.get('/users/me/favorites');
      return response.data as List<dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ── 알림 설정 조회 ────────────────────────────────────
  /// 사용자의 현재 알림 설정을 가져옵니다.
  Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final response = await _dio.get('/users/me/notifications');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ── 알림 설정 업데이트 ──────────────────────────────
  /// 사용자의 알림 설정을 변경합니다.
  Future<void> updateNotificationSettings({
    required bool subscriptionAlarm,
    required bool listingAlarm,
  }) async {
    try {
      await _dio.patch(
        '/users/me/notifications',
        data: {
          'subscriptionAlarm': subscriptionAlarm,
          'listingAlarm': listingAlarm,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // ── 회원 탈퇴 ────────────────────────────────────────
  /// 현재 계정을 삭제합니다.
  Future<void> withdraw(String password) async {
    try {
      await _dio.post(
        '/users/me/withdraw',
        data: {'password': password},
      );
    } catch (e) {
      rethrow;
    }
  }

  // ── 비밀번호 변경 ─────────────────────────────────────
  /// 현재 비밀번호를 확인하고 새 비밀번호로 변경합니다.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.patch(
        '/users/me/password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}


