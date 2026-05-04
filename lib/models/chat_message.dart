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
}
