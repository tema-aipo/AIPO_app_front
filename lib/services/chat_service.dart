import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../network/api_endpoints.dart';

/// AI 채팅 관련 API 호출을 담당하는 서비스 클래스
class ChatService {
  final Dio _dio = DioClient.instance.dio;

  // ── 세션 생성 ──────────────────────────────────────────
  /// 새로운 채팅 세션을 생성합니다. (새로운 대화 시작)
  Future<Map<String, dynamic>> createSession({String? title}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.chatSessions,
        data: {
          if (title != null) 'title': title,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ── 세션 목록 조회 ─────────────────────────────────────
  /// 사용자의 채팅 세션 목록을 가져옵니다.
  Future<List<dynamic>> getSessions() async {
    try {
      final response = await _dio.get(ApiEndpoints.chatSessions);
      return response.data as List<dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ── 메시지 전송 ────────────────────────────────────────
  /// 특정 세션에 메시지를 보내고 AI의 답변을 받습니다.
  Future<Map<String, dynamic>> sendMessage({
    required String sessionId,
    required String message,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.chatMessages(sessionId),
        data: {'content': message},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ── 메시지 기록 조회 ──────────────────────────────────
  /// 특정 세션의 과거 대화 기록을 가져옵니다.
  Future<List<dynamic>> getMessages(String sessionId) async {
    try {
      final response = await _dio.get(ApiEndpoints.chatMessages(sessionId));
      return response.data as List<dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ── 피드백 전송 ────────────────────────────────────────
  /// 특정 메시지에 대한 피드백(좋아요/싫어요)을 보냅니다.
  Future<void> submitFeedback({
    required String messageId,
    required bool isPositive,
    String? reason,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.messageFeedback(messageId),
        data: {
          'isPositive': isPositive,
          if (reason != null) 'reason': reason,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}
