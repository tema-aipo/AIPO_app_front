import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../network/api_endpoints.dart';
import '../models/auth_manager.dart';
import '../network/auth_interceptor.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  final Dio _dio = DioClient.instance.dio;

  /// 사용 가능한 아이디인 경우 true, 중복되었거나 사용 불가능한 경우 false 반환
  Future<bool> checkLoginIdAvailability(String loginId) async {
    try {
      final response = await _dio.get(
        '/auth/login-id/availability',
        queryParameters: {'loginId': loginId},
      );
      final data = response.data;
      return data['available'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 성공 시 userId를 반환, 실패 시 에러 메시지 문자열을 throw
  Future<int> register({
    required String loginId,
    required String password,
    required String userName,
    String? email,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.register,
        data: {
          'loginId': loginId,
          'password': password,
          'userName': userName,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );
      return response.data['userId'] as int;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw '이미 사용 중인 아이디 또는 이메일입니다.';
      }
      if (e.response?.statusCode == 400) {
        throw '입력값을 다시 확인해 주세요.';
      }
      throw '회원가입에 실패했습니다. 네트워크를 확인해 주세요.';
    }
  }

  Future<void> login({
    required String loginId,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'loginId': loginId,
          'password': password,
        },
      );

      final data = response.data;
      
      // 토큰 데이터 추출 (중첩 구조 대응)
      final tokenData = data['tokenDto'] ?? data;
      final accessToken = tokenData['accessToken'] as String? ?? '';
      final refreshToken = tokenData['refreshToken'] as String? ?? '';
      
      // 유저 데이터 추출 (중첩 구조 대응)
      final userData = data['userDto'] ?? data;
      final userId = (userData['userId'] ?? userData['id'] ?? 0).toString();
      final responseLoginId = userData['loginId'] as String? ?? loginId;
      final userName = userData['userName'] ?? userData['name'] ?? '사용자';
      final investmentType = userData['investmentType'] ?? '분석대기중';

      // 토큰 저장 + 유저 세팅
      await AuthManager.instance.loginWithToken(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: UserModel(
          id: responseLoginId.isNotEmpty ? responseLoginId : userId,
          name: userName,
          email: userData['email'] as String? ?? data['email'] as String? ?? '',
          investmentType: investmentType.startsWith('#') ? investmentType : '#$investmentType',
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw '비밀번호가 일치하지 않습니다.';
      }
      if (e.response?.statusCode == 403) {
        throw '탈퇴한 계정입니다.';
      }
      if (e.response?.statusCode == 400) {
        throw '아이디와 비밀번호를 입력해 주세요.';
      }
      throw '로그인에 실패했습니다. 네트워크를 확인해 주세요.';
    }
  }

  Future<bool> restoreSession() async {
    final token = await AuthInterceptor.getAccessToken();
    if (token == null) return false;

    try {
      final response = await _dio.get(ApiEndpoints.myProfile);
      final userData = response.data;
      
      final userId = (userData['userId'] ?? userData['id'] ?? 0).toString();
      final loginId = userData['loginId'] as String? ?? '';
      final userName = userData['userName'] ?? userData['name'] ?? '사용자';
      final investmentType = userData['investmentType'] ?? '분석대기중';
      
      AuthManager.instance.currentUser.value = UserModel(
        id: loginId.isNotEmpty ? loginId : userId,
        name: userName,
        email: userData['email'] ?? '',
        investmentType: investmentType.startsWith('#') ? investmentType : '#$investmentType',
      );
      return true;
    } catch (_) {
      await AuthManager.instance.logout();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {
      // 로그아웃 API 실패해도 로컬 토큰은 삭제
    }
    await AuthManager.instance.logout();
  }
}

