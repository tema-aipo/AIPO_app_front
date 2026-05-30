import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../network/api_endpoints.dart';

class ChatService {
  static final ChatService instance = ChatService._();
  ChatService._();

  final Dio _dio = DioClient.instance.dio;

  Future<Map<String, dynamic>> createSession({String? title}) async {
    final response = await _dio.post(
      ApiEndpoints.chatSessions,
      data: {
        if (title != null) 'title': title,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getSessions() async {
    final response = await _dio.get(ApiEndpoints.chatSessions);
    final data = response.data as Map<String, dynamic>;

    final pinned = data['pinnedSessions'] as List<dynamic>? ?? [];
    final recent = data['recentSessions'] as List<dynamic>? ?? [];

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

    return [
      ...pinned.map(translate),
      ...recent.map(translate),
    ];
  }

  Future<Map<String, dynamic>> sendMessage({
    required String sessionId,
    required String message,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.chatMessages(sessionId),
      data: {'question': message},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMessages(String sessionId) async {
    final response = await _dio.get('/chat/sessions/$sessionId');
    return response.data['messages'] as List<dynamic>;
  }

  /// [feedbackType] : 'LIKE' or 'DISLIKE'
  /// [reasonCode]   : 'INACCURATE_INFO', 'TOO_COMPLEX', 'IRRELEVANT_ANSWER'
  Future<void> submitFeedback({
    required String messageId,
    required String feedbackType,
    String? reasonCode,
    String? reasonDetail,
  }) async {
    await _dio.post(
      ApiEndpoints.messageFeedback(messageId),
      data: {
        'feedbackType': feedbackType,
        if (reasonCode != null) 'reasonCode': reasonCode,
        if (reasonDetail != null) 'reasonDetail': reasonDetail,
      },
    );
  }

  Future<void> pinSession(String sessionId, bool pinned) async {
    await _dio.patch(
      '/chat/sessions/$sessionId/pin',
      data: {'pinned': pinned},
    );
  }

  Future<void> deleteSession(String sessionId) async {
    await _dio.delete('/chat/sessions/$sessionId');
  }
}
