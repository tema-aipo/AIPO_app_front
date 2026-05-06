import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_endpoints.dart';

/// JWT 토큰을 자동으로 헤더에 삽입하고,
/// 만료 시 자동으로 토큰을 갱신(Refresh)하는 인터셉터
class AuthInterceptor extends Interceptor {
  final Dio _dio;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  AuthInterceptor(this._dio);

  // ── 토큰 저장/조회/삭제 헬퍼 ─────────────────────────
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  // ── 요청 전처리: Access Token 삽입 ───────────────────
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 로그인, 회원가입, 재발급 요청은 토큰을 삽입하지 않음
    if (options.path.contains(ApiEndpoints.login) ||
        options.path.contains(ApiEndpoints.register) ||
        options.path.contains(ApiEndpoints.reissue)) {
      return handler.next(options);
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  // ── 에러 처리: 401이면 토큰 갱신 후 재시도 ──────────
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 1. 이미 reissue 요청인데 401이 난 경우 (무한 루프 방지)
    // 2. 로그인 요청인데 401이 난 경우 (단순 비밀번호 틀림)
    if (err.requestOptions.path.contains(ApiEndpoints.reissue) ||
        err.requestOptions.path.contains(ApiEndpoints.login)) {
      return handler.next(err);
    }

    if (err.response?.statusCode == 401) {
      // 3. 비밀번호 불일치 등 비즈니스적 401 에러인 경우 토큰 재발급을 실행하지 않음
      if (err.response?.data != null && err.response?.data is Map) {
        final data = err.response!.data as Map;
        if (data['code'] == 'INVALID_PASSWORD') {
          return handler.next(err);
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey);
      if (refreshToken == null) {
        // 리프레시 토큰도 없으면 로그아웃 처리
        await clearTokens();
        return handler.next(err);
      }

      try {
        // 새 Access Token 요청
        final response = await _dio.post(
          ApiEndpoints.reissue,
          data: {'refreshToken': refreshToken},
        );

        final newAccessToken = response.data['accessToken'] as String;
        final newRefreshToken =
            response.data['refreshToken'] as String? ?? refreshToken;

        await saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        // 실패했던 원본 요청을 새 토큰으로 재시도
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(retryOptions);
        return handler.resolve(retryResponse);
      } catch (_) {
        // 갱신마저 실패하면 모든 토큰 삭제 후 에러 전달
        await clearTokens();
        return handler.next(err);
      }
    }
    handler.next(err);
  }
}
