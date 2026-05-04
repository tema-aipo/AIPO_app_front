class ChatMessage {
  final String id;
  final String text; // AI 타이틀 혹은 유저의 일반 텍스트
  final bool isUser;
  // AI 전용 데이터
  final Map<String, String>? aiSummaryData;
  final String? aiSecondaryText;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.aiSummaryData,
    this.aiSecondaryText,
  });

  /// 백엔드 JSON 응답 → ChatMessage 변환
  /// 백엔드의 messages 배열 내 각 아이템에 대응
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as String? ?? 'user';
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      text: json['content'] as String? ?? '',
      isUser: role == 'user',
    );
  }
}
