import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/chat_service.dart';

class ChatbotDrawer extends StatefulWidget {
  final VoidCallback onNewChat;
  final Function(String) onLoadChat;

  const ChatbotDrawer({
    super.key,
    required this.onNewChat,
    required this.onLoadChat,
  });

  @override
  State<ChatbotDrawer> createState() => _ChatbotDrawerState();
}

class _ChatbotDrawerState extends State<ChatbotDrawer> {
  final ChatService _chatService = ChatService();
  List<dynamic> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    setState(() => _isLoading = true);
    try {
      final data = await _chatService.getSessions();
      setState(() {
        _sessions = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // 에러 처리는 생략 (또는 로그 출력)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onNewChat();
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('새로운 채팅', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _sessions.isEmpty
                      ? const Center(child: Text('대화 기록이 없습니다.', style: TextStyle(color: AppColors.textGray)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          itemCount: _sessions.length,
                          itemBuilder: (context, index) {
                            final session = _sessions[index];
                            return ListTile(
                              leading: const Icon(Icons.chat_outlined, size: 20, color: AppColors.textGray),
                              title: Text(
                                session['title'] ?? '제목 없는 대화',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                session['updatedAt']?.split('T')[0] ?? '',
                                style: const TextStyle(fontSize: 11, color: AppColors.textLightGray),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                widget.onLoadChat(session['sessionId'].toString());
                              },
                            );
                          },
                        ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.info_outline, size: 20),
              title: const Text('도움말', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
