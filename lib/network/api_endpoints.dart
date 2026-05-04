/// 백엔드 API 엔드포인트 상수 모음
/// 서버 주소 변경 시 .env 파일의 BASE_URL만 바꾸면 됩니다.
class ApiEndpoints {
  ApiEndpoints._(); // 인스턴스 생성 방지

  // ── Auth ──────────────────────────────────────────────
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String reissue = '/auth/reissue';
  static const String logout = '/auth/logout';

  // ── User ──────────────────────────────────────────────
  static const String myProfile = '/user/me';

  // ── Home (대시보드) ────────────────────────────────────
  static const String home = '/home';

  // ── IPO ───────────────────────────────────────────────
  static const String ipos = '/ipos';
  static String ipoDetail(String id) => '/ipos/$id';

  // ── Calendar ──────────────────────────────────────────
  static const String calendar = '/calendar';

  // ── Chat ──────────────────────────────────────────────
  static const String chatSessions = '/chat/sessions';
  static String chatMessages(String sessionId) =>
      '/chat/sessions/$sessionId/messages';
  static String messageFeedback(String messageId) =>
      '/chat/messages/$messageId/feedback';

  // ── Investment Profile ────────────────────────────────
  static const String investmentProfile = '/investment-profile';
}
