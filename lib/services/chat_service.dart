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
      final data = response.data as Map<String, dynamic>;
      
      final pinned = data['pinnedSessions'] as List<dynamic>? ?? [];
      final recent = data['recentSessions'] as List<dynamic>? ?? [];
      
      final List<dynamic> merged = [];
      
      Map<String, dynamic> translate(dynamic item) {
        final map = item as Map<String, dynamic>;
        return {
          'sessionId': map['sessionId'],
          'title': map['title'],
          'pinned': map['pinned'],
          'updatedAt': map['lastMessageAt'] ?? '',
          'lastMessagePreview': map['lastMessagePreview'],
        };
      }
      
      for (var p in pinned) {
        merged.add(translate(p));
      }
      for (var r in recent) {
        merged.add(translate(r));
      }
      
      return merged;
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
    required String feedbackType, // 'LIKE' or 'DISLIKE'
    String? reasonCode,           // 'INACCURATE_INFO', 'TOO_COMPLEX', 'IRRELEVANT_ANSWER'
    String? reasonDetail,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.messageFeedback(messageId),
        data: {
          'feedbackType': feedbackType,
          if (reasonCode != null) 'reasonCode': reasonCode,
          if (reasonDetail != null) 'reasonDetail': reasonDetail,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // ── 세션 고정/해제 ─────────────────────────────────────
  /// 특정 대화 세션을 고정하거나 고정 해제합니다.
  Future<void> pinSession(String sessionId, bool pinned) async {
    try {
      await _dio.patch(
        '/chat/sessions/$sessionId/pin',
        data: {'pinned': pinned},
      );
    } catch (e) {
      rethrow;
    }
  }

  // ── 세션 삭제 ──────────────────────────────────────────
  /// 특정 대화 세션을 삭제합니다.
  Future<void> deleteSession(String sessionId) async {
    try {
      await _dio.delete('/chat/sessions/$sessionId');
    } catch (e) {
      rethrow;
    }
  }
}

