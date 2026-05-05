import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_interceptor.dart';

/// 앱 전역에서 사용하는 Dio HTTP 클라이언트 싱글톤
class DioClient {
  DioClient._();
  static final DioClient _instance = DioClient._();
  static DioClient get instance => _instance;

  late final Dio _dio;

  /// 앱 시작 시 main.dart에서 반드시 호출해야 합니다.
  void initialize() {
    final baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8080/api/v1';

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 인터셉터 등록
    _dio.interceptors.add(AuthInterceptor(_dio));

    // 개발 중 네트워크 로그 출력 (배포 시 제거)
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  Dio get dio => _dio;
}
