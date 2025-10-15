import 'package:flutter/material.dart';

/// 채팅 메시지 데이터 모델
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? selectedCategories;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.selectedCategories,
  });
}

/// 선택한 내용 요약과 질문을 보여주는 간단한 채팅 화면
class ChatScreen extends StatefulWidget {
  /// 인원 수 (추후 프롬프트에 활용 가능)
  final int peopleCount;
  /// 사용자가 선택한 카테고리 목록
  final List<String> selectedCategories;

  const ChatScreen({super.key, required this.peopleCount, required this.selectedCategories});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 초기 메시지들 추가
    _messages.addAll([
      ChatMessage(
        text: '오늘 어떻게 놀고 싶어?',
        isUser: false,
        timestamp: DateTime.now(),
        selectedCategories: widget.selectedCategories,
      ),
    ]);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    setState(() {
      _messages.add(ChatMessage(
        text: _messageController.text.trim(),
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });
    
    _messageController.clear();
    _scrollToBottom();
    
    // AI 응답 시뮬레이션 (실제로는 API 호출)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: '좋은 아이디어네요! 더 자세히 알려주세요.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 헤더 (뒤로가기, 타이틀, 서브타이틀)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: const [
                  BackButton(),
                  SizedBox(width: 4),
                  Text('하루와 할 일 찾기',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 56),
              child: Text('상세하게 알려줘!',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
            ),
            const SizedBox(height: 8),

            // 메시지 리스트
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildMessageWidget(message),
                  );
                },
              ),
            ),

            // 하단 입력창
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 4)),
                        ],
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: '메시지를 입력하세요...',
                          hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF7A21),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0x19000000), blurRadius: 8, offset: Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMessageWidget(ChatMessage message) {
    if (message.isUser) {
      if (message.selectedCategories != null) {
        // 사용자 선택 카테고리 카드
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 280,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.text,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: message.selectedCategories!.map((name) {
                    return _ChipTag(label: name);
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      } else {
        // 일반 사용자 메시지
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF7A21),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Color(0x19000000), blurRadius: 8, offset: Offset(0, 4)),
              ],
            ),
            child: Text(
              message.text,
              style: const TextStyle(color: Colors.white, height: 1.4),
            ),
          ),
        );
      }
    } else {
      // AI 메시지
      if (message.selectedCategories != null) {
        // AI가 선택한 카테고리를 보여주는 메시지
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 280,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Color(0x19000000), blurRadius: 12, offset: Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  children: message.selectedCategories!.map((name) {
                    return _ChipTag(label: name, isOrange: false);
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Text(
                  message.text,
                  style: const TextStyle(
                    color: Color(0xFFFF7A21),
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // 일반 AI 메시지
        return Align(
          alignment: Alignment.centerLeft,
          child: _ChatBubble(text: message.text),
        );
      }
    }
  }
}

/// 단순 텍스트 채팅 말풍선 (좌측 정렬)
class _ChatBubble extends StatelessWidget {
  final String text;
  const _ChatBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFFF7A21),
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
    );
  }
}

/// 선택한 카테고리를 보여주는 칩 형태의 태그
class _ChipTag extends StatelessWidget {
  final String label;
  final bool isOrange;
  const _ChipTag({required this.label, this.isOrange = false});

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFFFF7A21);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOrange ? Colors.white.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isOrange ? Colors.white : accent, width: 1.6),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(label), color: isOrange ? Colors.white : accent, size: 18),
          const SizedBox(width: 6),
          Text(
            label, 
            style: TextStyle(
              color: isOrange ? Colors.white : accent, 
              fontWeight: FontWeight.w700
            ),
          ),
        ],
      ),
    );
  }

  // 라벨에 맞는 기본 아이콘 연결 (간단 매핑)
  static IconData _iconFor(String name) {
    switch (name) {
      case '음식점':
        return Icons.restaurant;
      case '카페':
        return Icons.local_cafe;
      case '콘텐츠':
        return Icons.movie_filter;
      default:
        return Icons.check_circle_outline;
    }
  }
}
