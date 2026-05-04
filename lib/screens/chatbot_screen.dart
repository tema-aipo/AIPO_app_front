import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/chatbot_drawer.dart';
import '../widgets/chat_message_bubble.dart';
import '../models/chat_message.dart';
import '../models/auth_manager.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  void _handleSend(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: query.trim(),
        isUser: true,
      ));
    });
    
    _textController.clear();
    _scrollToBottom();

    // Mock AI response
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        if (query.contains('스페이스테크놀로지')) {
          _messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: '스페이스테크놀로지 수요예측 결과입니다.',
            isUser: false,
            aiSummaryData: {
              '기관 경쟁률': '850:1',
              '의무보유 확약률': '12.5%',
              '공모가': '25,000원 (상단 초과)',
            },
            aiSecondaryText: '경쟁률은 다소 높으나, 확약률이 평균 수준입니다. 사용자 님의 안정형 성향을 고려할 때, 단기 변동성에 주의가 필요합니다.',
          ));
        } else {
          _messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: '제가 아직 해당 정보는 준비하지 못했어요!',
            isUser: false,
          ));
        }
      });
      _scrollToBottom();
    });
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 시간차를 둔 요소 생성기 (Staggered Animation)
  Widget _buildStaggeredItem(Widget child, double start, double end) {
    // 메모리 누수(Memory Leak)를 방지하기 위해 build 내에서 CurvedAnimation 생성 대신 CurveTween 사용
    final curve = CurveTween(curve: Interval(start, end, curve: Curves.easeOutCubic));
    final animation = _controller.drive(curve);

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
    final user = AuthManager.instance.currentUser.value;
    final userName = user?.name ?? '사용자';
    // 만약 성향 문자열이 '#안정형' 이라면 앞자리 '#' 기호를 떼고 조립하여 자연스럽게 표기
    final userTypeRaw = user?.investmentType ?? '#안정형';
    final userTypeStr = userTypeRaw.startsWith('#') ? userTypeRaw.substring(1) : userTypeRaw;

    return Scaffold(
      backgroundColor: AppColors.white,
      drawer: ChatbotDrawer(
        onNewChat: () {
          setState(() {
            _messages.clear();
          });
          _controller.reset();
          _controller.forward();
        },
        onLoadChat: (chatId) {
          setState(() {
            _messages.clear(); // 기존 메시지 비우기
            if (chatId == '1') {
              // '1'은 "스페이스테크놀로지 수요예측 결과" 목업용 ID
              _messages.add(ChatMessage(
                id: '${DateTime.now().millisecondsSinceEpoch}_user',
                text: '스페이스테크놀로지 수요예측 결과 요약해줘',
                isUser: true,
              ));
              _messages.add(ChatMessage(
                id: '${DateTime.now().millisecondsSinceEpoch}_ai',
                text: '스페이스테크놀로지 수요예측 결과입니다.',
                isUser: false,
                aiSummaryData: {
                  '기관 경쟁률': '850:1',
                  '의무보유 확약률': '12.5%',
                  '공모가': '25,000원 (상단 초과)',
                },
                aiSecondaryText: '경쟁률은 다소 높으나, 확약률이 평균 수준입니다. 사용자 님의 안정형 성향을 고려할 때, 단기 변동성에 주의가 필요합니다.',
              ));
            } else {
               // 다른 목록 클릭 시 안내 문구
               _messages.add(ChatMessage(
                id: '${DateTime.now().millisecondsSinceEpoch}_user',
                text: '과거 대화 기록 불러오기',
                isUser: true,
              ));
              _messages.add(ChatMessage(
                id: '${DateTime.now().millisecondsSinceEpoch}_ai',
                text: '해당 기록 데이터가 존재하지 않습니다.',
                isUser: false,
              ));
            }
          });
          _scrollToBottom();
        },
      ),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textDark),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text(
          'AIPO',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStaggeredItem(
                            Text(
                              '안녕하세요, $userName 님!\n공모주에 대해 무엇이든 물어보세요.',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                                height: 1.4,
                              ),
                            ),
                            0.0, 0.3,
                          ),
                          const SizedBox(height: 44),
                          _buildStaggeredItem(
                            const Text(
                              '추천 질문',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            0.1, 0.4,
                          ),
                          const SizedBox(height: 16),
                          _buildStaggeredItem(
                            _buildQuestionCard('스페이스테크놀로지 수요예측 결과 요약해줘'),
                            0.2, 0.5,
                          ),
                          const SizedBox(height: 12),
                          _buildStaggeredItem(
                            _buildQuestionCard('나의 \'$userTypeStr\' 성향에 맞는 이번 주 공모주는?'),
                            0.3, 0.6,
                          ),
                          const SizedBox(height: 12),
                          _buildStaggeredItem(
                            _buildQuestionCard('바이오메디컬 상장 일정 알려줘'),
                            0.4, 0.7,
                          ),
                          const SizedBox(height: 12),
                          _buildStaggeredItem(
                            _buildQuestionCard('공모주 청약하는 방법 알려줘'),
                            0.5, 0.8,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return ChatMessageBubble(message: _messages[index]);
                      },
                    ),
            ),
            // Bottom Input Base
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.borderGray.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        onSubmitted: _handleSend,
                        decoration: const InputDecoration(
                          hintText: '공모주 이름이나 일정을 물어보세요',
                          hintStyle: TextStyle(
                            color: AppColors.textGray,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: AppColors.white, size: 20),
                          onPressed: () {
                            _handleSend(_textController.text);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(String text) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.borderGray.withOpacity(0.8)),
      ),
      child: InkWell(
        onTap: () {
          _handleSend(text);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}
