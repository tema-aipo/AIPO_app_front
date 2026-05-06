import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../network/api_endpoints.dart';

/// 투자성향 검사 관련 API 호출을 담당하는 서비스 클래스
class InvestmentProfileService {
  final Dio _dio = DioClient.instance.dio;

  // ── 투자성향 문항 조회 ─────────────────────────────────
  /// 투자성향 검사에 필요한 질문과 선택지를 백엔드 DB에서 가져옵니다.
  /// 반환값: { version: int, questions: [ { questionId, questionOrder, questionText, options: [...] } ] }
  Future<Map<String, dynamic>> getQuestions() async {
    try {
      final response = await _dio.get(ApiEndpoints.investmentProfileQuestions);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ── 회원가입 시 투자성향 결과 제출 ────────────────────
  /// 회원가입 과정에서 답변을 제출하고 투자성향 결과를 반환받습니다.
  Future<Map<String, dynamic>> submitResult({
    required int userId,
    required int version,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.investmentProfileResults,
        data: {
          'userId': userId,
          'version': version,
          'answers': answers,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ── 회원가입 시 투자성향 검사 스킵 ────────────────────
  /// 회원가입 과정에서 투자성향 검사를 건너뜁니다.
  Future<Map<String, dynamic>> skipProfile({
    required int userId,
    required int version,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.investmentProfileSkip,
        data: {
          'userId': userId,
          'version': version,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ── 로그인 사용자 재검사 ──────────────────────────────
  /// 마이페이지에서 투자 성향 재검사를 제출합니다.
  Future<Map<String, dynamic>> retestProfile({
    required int version,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.investmentProfileRetest,
        data: {
          'version': version,
          'answers': answers,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
