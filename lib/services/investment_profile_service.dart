import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../network/api_endpoints.dart';

class InvestmentProfileService {
  static final InvestmentProfileService instance = InvestmentProfileService._();
  InvestmentProfileService._();

  final Dio _dio = DioClient.instance.dio;

  /// 반환값: { version: int, questions: [ { questionId, questionOrder, questionText, options: [...] } ] }
  Future<Map<String, dynamic>> getQuestions() async {
    final response = await _dio.get(ApiEndpoints.investmentProfileQuestions);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitResult({
    required int userId,
    required int version,
    required List<Map<String, dynamic>> answers,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.investmentProfileResults,
      data: {
        'userId': userId,
        'version': version,
        'answers': answers,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> skipProfile({
    required int userId,
    required int version,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.investmentProfileSkip,
      data: {
        'userId': userId,
        'version': version,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> retestProfile({
    required int version,
    required List<Map<String, dynamic>> answers,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.investmentProfileRetest,
      data: {
        'version': version,
        'answers': answers,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
