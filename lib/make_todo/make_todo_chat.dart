import 'package:flutter/material.dart';
import 'package:whattodo/services/openai_service.dart'; // 위에서 만든 서비스 import

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
  final FocusNode _messageFocusNode = FocusNode();
  
  // OpenAI 서비스 인스턴스
  late OpenAIService _openAIService;
  
  // 로딩 상태
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // OpenAI 서비스 초기화
    _openAIService = OpenAIService();
    _openAIService.initializeWithContext(
      peopleCount: widget.peopleCount,
      selectedCategories: widget.selectedCategories,
    );
    
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
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final userMessage = _messageController.text.trim();
    
    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true; // 로딩 시작
    });
    
    _messageController.clear();
    _scrollToBottom();
    
    // 메시지 전송 후 텍스트 필드에 포커스 유지
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messageFocusNode.requestFocus();
    });
    
    try {
      // OpenAI API 호출
      final aiResponse = await _openAIService.sendMessage(userMessage);
      
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: aiResponse,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false; // 로딩 종료
        });
        _scrollToBottom();
        
        // AI 응답 후에도 텍스트 필드에 포커스 유지
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _messageFocusNode.requestFocus();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: '죄송합니다. 응답을 가져오는 중 오류가 발생했습니다.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
        
        // 에러 발생 후에도 텍스트 필드에 포커스 유지
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _messageFocusNode.requestFocus();
        });
      }
    }
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
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  // 로딩 인디케이터 표시
                  if (index == _messages.length && _isLoading) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7A21)),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                '생각 중...',
                                style: TextStyle(color: Color(0xFFFF7A21), fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  
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
                        focusNode: _messageFocusNode,
                        enabled: !_isLoading, // 로딩 중에는 입력 불가
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
                    onTap: _isLoading ? null : _sendMessage, // 로딩 중에는 버튼 비활성화
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isLoading ? Colors.grey : const Color(0xFFFF7A21),
                        shape: BoxShape.circle,
                        boxShadow: const [
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