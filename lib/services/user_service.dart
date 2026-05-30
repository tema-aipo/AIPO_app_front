import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../network/api_endpoints.dart';

class UserService {
  static final UserService instance = UserService._();
  UserService._();

  final Dio _dio = DioClient.instance.dio;

  Future<Map<String, dynamic>> getMyProfile() async {
    final response = await _dio.get(ApiEndpoints.myProfile);
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getFavorites() async {
    final response = await _dio.get('/users/me/favorites');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getNotificationSettings() async {
    final response = await _dio.get('/users/me/notifications');
    return response.data as Map<String, dynamic>;
  }

  Future<void> updateNotificationSettings({
    required bool subscriptionAlarm,
    required bool listingAlarm,
  }) async {
    await _dio.patch(
      '/users/me/notifications',
      data: {
        'subscriptionAlarm': subscriptionAlarm,
        'listingAlarm': listingAlarm,
      },
    );
  }

  Future<void> withdraw(String password) async {
    await _dio.post(
      '/users/me/withdraw',
      data: {'password': password},
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.patch(
      '/users/me/password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }
}
