import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/chatbot_drawer.dart';
import '../widgets/chat_message_bubble.dart';
import '../models/chat_message.dart';
import '../models/auth_manager.dart';
import '../services/chat_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late AnimationController _animationController;
  final List<ChatMessage> _messages = [];
  String? _currentSessionId;
  bool _isTyping = false;

  // 백엔드에서 가져온 추천 질문
  List<String> _recommendedQuestions = [];
  bool _isLoadingRecommendations = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animationController.forward();
    
    // 세션 생성 → 추천 질문 로드
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    try {
      final sessionData = await _chatService.createSession(title: '새 대화');
      if (!mounted) return;
      setState(() {
        _currentSessionId = sessionData['sessionId'].toString();
        
        // 추천 질문 파싱
        final List<dynamic> rawQuestions = sessionData['recommendedQuestions'] ?? [];
        _recommendedQuestions = rawQuestions
            .map((q) => (q as Map<String, dynamic>)['questionText'] as String? ?? '')
            .where((text) => text.isNotEmpty)
            .toList();
        
        _isLoadingRecommendations = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingRecommendations = false);
      // 세션 생성 실패 시 기본 추천 질문 (fallback)
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend(String query) async {
    if (query.trim().isEmpty || _isTyping) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: query.trim(),
      isUser: true,
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    
    _textController.clear();
    _scrollToBottom();

    try {
      // 1. 세션이 없으면 생성
      if (_currentSessionId == null) {
        final session = await _chatService.createSession(title: query.trim());
        _currentSessionId = session['sessionId'].toString();
      }

      // 2. 메시지 전송
      final response = await _chatService.sendMessage(
        sessionId: _currentSessionId!,
        message: query.trim(),
      );

      // 3. 응답 처리
      final assistantMsg = response['assistantMessage'];
      final aiMessage = ChatMessage(
        id: (assistantMsg?['messageId'] ?? '').toString(),
        text: assistantMsg?['content'] ?? '',
        isUser: false,
        aiSummaryData: assistantMsg?['summaryData'] != null ? Map<String, String>.from(assistantMsg['summaryData']) : null,
        aiSecondaryText: assistantMsg?['recommendationText'],
      );

      if (!mounted) return;
      setState(() {
        _messages.add(aiMessage);
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isTyping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI 응답을 가져오지 못했습니다: $e')),
      );
    }
  }

  Future<void> _loadSessionMessages(String sessionId) async {
    setState(() {
      _messages.clear();
      _currentSessionId = sessionId;
      _isTyping = true;
    });

    try {
      final history = await _chatService.getMessages(sessionId);
      final List<ChatMessage> loadedMessages = history.map((m) {
        return ChatMessage(
          id: m['messageId'].toString(),
          text: m['content'] ?? '',
          isUser: m['role'] == 'USER',
          aiSummaryData: m['summaryData'] != null ? Map<String, String>.from(m['summaryData']) : null,
          aiSecondaryText: m['recommendationText'],
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _messages.addAll(loadedMessages);
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isTyping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('대화 기록을 불러오지 못했습니다: $e')),
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildStaggeredItem(Widget child, double start, double end) {
    final curve = CurveTween(curve: Interval(start, end, curve: Curves.easeOutCubic));
    final animation = _animationController.drive(curve);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: animation.drive(Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthManager.instance.user;
    final userName = user?.name ?? '사용자';
    final userTypeRaw = user?.investmentType ?? '#안정형';
    final userTypeStr = userTypeRaw.startsWith('#') ? userTypeRaw.substring(1) : userTypeRaw;

    return Scaffold(
      backgroundColor: AppColors.white,
      drawer: ChatbotDrawer(
        onNewChat: () {
          setState(() {
            _messages.clear();
            _currentSessionId = null;
          });
          _animationController.reset();
          _animationController.forward();
          // 새 대화 시작 → 새 세션 + 추천 질문 재로드
          _initializeSession();
        },
        onLoadChat: (chatId) {
          _loadSessionMessages(chatId);
        },
      ),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textDark),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'AIPO',
          style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty && !_isTyping
                  ? _buildWelcomeScreen(userName, userTypeStr)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      itemCount: _messages.length + (_isTyping && _messages.isNotEmpty && _messages.last.isUser ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length) {
                          return _buildTypingIndicator();
                        }
                        return ChatMessageBubble(message: _messages[index]);
                      },
                    ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen(String userName, String userTypeStr) {
    // 백엔드에서 가져온 추천 질문 사용
    final List<String> questions = _recommendedQuestions.isNotEmpty
        ? _recommendedQuestions
        : [
            // Fallback: 로딩 실패 시 기본 추천 질문
            '이번 주 청약 가능한 공모주 알려줘',
            '내 \'$userTypeStr\' 성향에 맞는 종목 추천해줘',
            '공모주 투자 시 주의할 점이 뭐야?',
          ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStaggeredItem(
            Text(
              '안녕하세요, $userName 님!\n공모주에 대해 무엇이든 물어보세요.',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textDark, height: 1.4),
            ),
            0.0, 0.3,
          ),
          const SizedBox(height: 44),
          _buildStaggeredItem(
            const Text('추천 질문', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            0.1, 0.4,
          ),
          const SizedBox(height: 16),
          if (_isLoadingRecommendations)
            _buildStaggeredItem(
              const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppColors.primary),
              )),
              0.2, 0.5,
            )
          else
            ...List.generate(questions.length, (index) {
              final double start = 0.2 + (index * 0.1);
              final double end = start + 0.3;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildStaggeredItem(
                  _buildQuestionCard(questions[index]),
                  start.clamp(0.0, 0.7),
                  end.clamp(0.3, 1.0),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.borderGray.withOpacity(0.5)),
          boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSend,
                enabled: !_isTyping,
                decoration: const InputDecoration(
                  hintText: '궁금한 점을 물어보세요',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send_rounded, color: _isTyping ? AppColors.textGray : AppColors.primary),
              onPressed: () => _handleSend(_textController.text),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: AppColors.bgLightBlue, radius: 16, child: Icon(Icons.smart_toy_outlined, color: AppColors.primary, size: 20)),
          SizedBox(width: 12),
          Text('AIPO가 생각 중입니다...', style: TextStyle(color: AppColors.textGray, fontSize: 13, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(String text) {
    return GestureDetector(
      onTap: () => _handleSend(text),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderGray.withOpacity(0.8))),
        child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      ),
    );
  }
}
