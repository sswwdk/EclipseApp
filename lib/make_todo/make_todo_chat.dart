import 'package:flutter/material.dart';
import 'package:whattodo/services/openai_service.dart'; // 위에서 만든 서비스 import
import 'package:whattodo/make_todo/recommendation_result_screen.dart';

/// 채팅 메시지 데이터 모델
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? selectedCategories;
  final bool showYesNoButtons;
  final String? yesNoQuestion;
  final String? currentCategory;
  final List<String>? availableCategories;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.selectedCategories,
    this.showYesNoButtons = false,
    this.yesNoQuestion,
    this.currentCategory,
    this.availableCategories,
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
    
    // FastAPI 서버와 연결하여 초기화
    _initializeChat();
  }

  /// FastAPI 서버와 연결하여 대화 초기화
  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // FastAPI /api/start 호출
      final firstMessage = await _openAIService.initialize(
        peopleCount: widget.peopleCount,
        selectedCategories: widget.selectedCategories,
      );

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: firstMessage,
            isUser: false,
            timestamp: DateTime.now(),
            selectedCategories: widget.selectedCategories,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: '서버 연결에 실패했습니다. FastAPI 서버가 실행 중인지 확인해주세요.\n오류: $e',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
      }
    }
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
      // FastAPI /api/chat 호출
      final response = await _openAIService.sendMessage(userMessage);
      
      if (mounted) {
        // 응답 데이터 파싱
        final message = response['message'] as String? ?? '';
        final stage = response['stage'] as String?;
        final recommendations = response['recommendations'] as Map<String, dynamic>?;
        final showYesNoButtons = response['showYesNoButtons'] as bool? ?? false;
        final yesNoQuestion = response['yesNoQuestion'] as String?;
        final currentCategory = response['currentCategory'] as String?;
        final availableCategories = response['availableCategories'] as List<dynamic>?;
        
        // "네"를 입력했고 completed 단계이며 추천 결과가 있으면 결과 화면으로 이동
        if (userMessage == "네" && stage == 'completed' && recommendations != null && recommendations.isNotEmpty) {
          setState(() {
            _isLoading = false;
          });
          
          // 추천 결과 화면으로 이동
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecommendationResultScreen(
                  recommendations: recommendations,
                  selectedCategories: widget.selectedCategories,
                ),
              ),
            );
          }
        } else if (userMessage == "추가하기" && availableCategories != null && availableCategories.isNotEmpty) {
          // "추가하기"를 입력했을 때 추가 활동 선택 UI 표시
          setState(() {
            _messages.add(ChatMessage(
              text: message,
              isUser: false,
              timestamp: DateTime.now(),
              selectedCategories: availableCategories.cast<String>(),
            ));
            _isLoading = false;
          });
        } else {
          // 일반 메시지 표시 (Yes/No 버튼 포함)
          setState(() {
            _messages.add(ChatMessage(
              text: message,
              isUser: false,
              timestamp: DateTime.now(),
              showYesNoButtons: showYesNoButtons,
              yesNoQuestion: yesNoQuestion,
              currentCategory: currentCategory,
              availableCategories: availableCategories?.cast<String>(),
            ));
            _isLoading = false;
          });
        }
        
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
            text: '죄송합니다. 응답을 가져오는 중 오류가 발생했습니다.\n오류: $e',
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

  /// 나가기 확인 다이얼로그 표시
  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '채팅을 나가시겠습니까?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '지금까지 대화가 삭제됩니다.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: const Text(
                '취소',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
                // 홈 화면으로 이동 (모든 이전 화면 제거)
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A21),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                '나가기',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 헤더 (뒤로가기, 타이틀, 나가기 버튼)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.black.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Stack(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: BackButton(),
                    ),
                    const Center(
                      child: Text('하루와 할 일 찾기',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: _showExitDialog,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: const BorderSide(
                            color: Colors.black38,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '나가기',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

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

  /// 카테고리 칩 위젯 생성
  Widget _buildCategoryChip(String category) {
    IconData icon;
    switch (category) {
      case '음식점':
        icon = Icons.restaurant;
        break;
      case '카페':
        icon = Icons.local_cafe;
        break;
      case '콘텐츠':
        icon = Icons.movie_filter;
        break;
      default:
        icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF7A21),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFFF7A21), size: 18),
          const SizedBox(width: 6),
          Text(
            category,
            style: const TextStyle(
              color: Color(0xFFFF7A21),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
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
        // AI가 선택한 카테고리를 보여주는 메시지 (맨 처음에 아이콘 표시)
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
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
                  spacing: 8,
                  runSpacing: 8,
                  children: message.selectedCategories!.map((category) {
                    return _buildCategoryChip(category);
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
        // 일반 AI 메시지 (Yes/No 버튼 포함)
        return Align(
          alignment: Alignment.centerLeft,
          child: _ChatBubble(
            text: message.text,
            showYesNoButtons: message.showYesNoButtons,
            yesNoQuestion: message.yesNoQuestion,
            onYesPressed: () => _handleYesNoResponse(true),
            onNoPressed: () => _handleYesNoResponse(false),
          ),
        );
      }
    }
  }

  /// Yes/No 버튼 응답 처리
  void _handleYesNoResponse(bool isYes) async {
    // 현재 메시지의 yesNoQuestion을 확인하여 결과 확인 단계인지 판단
    final lastMessage = _messages.isNotEmpty ? _messages.last : null;
    final isResultConfirmation = lastMessage?.yesNoQuestion?.contains("결과물을 출력") == true;
    
    final response = isResultConfirmation ? "네" : (isYes ? "네" : "추가하기");
    
    setState(() {
      _messages.add(ChatMessage(
        text: response,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });
    
    _scrollToBottom();
    
    try {
      final aiResponse = await _openAIService.sendMessage(response);
      
      if (mounted) {
        final stage = aiResponse['stage'] as String?;
        final message = aiResponse['message'] as String? ?? '';
        final recommendations = aiResponse['recommendations'] as Map<String, dynamic>?;
        final showYesNoButtons = aiResponse['showYesNoButtons'] as bool? ?? false;
        final yesNoQuestion = aiResponse['yesNoQuestion'] as String?;
        final currentCategory = aiResponse['currentCategory'] as String?;
        final availableCategories = aiResponse['availableCategories'] as List<dynamic>?;
        
        // "네"를 눌렀을 때 결과 화면으로 이동 (completed 단계에서만)
        if (isYes && stage == 'completed') {
          setState(() {
            _isLoading = false;
          });
          
          // 추천 결과가 있으면 결과 화면으로 이동
          if (recommendations != null && recommendations.isNotEmpty) {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecommendationResultScreen(
                    recommendations: recommendations,
                    selectedCategories: widget.selectedCategories,
                  ),
                ),
              );
            }
          } else {
            // 추천 결과가 없으면 서버에 다시 요청
            _requestRecommendations();
            return; // 함수 종료
          }
        } else if (!isYes && availableCategories != null && availableCategories.isNotEmpty) {
          // "아니오"를 눌렀을 때 추가 활동 선택 UI 표시
          setState(() {
            _messages.add(ChatMessage(
              text: message,
              isUser: false,
              timestamp: DateTime.now(),
              selectedCategories: availableCategories.cast<String>(),
            ));
            _isLoading = false;
          });
        } else {
          // 일반 메시지 표시 (Yes/No 버튼 포함)
          setState(() {
            _messages.add(ChatMessage(
              text: message,
              isUser: false,
              timestamp: DateTime.now(),
              showYesNoButtons: showYesNoButtons,
              yesNoQuestion: yesNoQuestion,
              currentCategory: currentCategory,
              availableCategories: availableCategories?.cast<String>(),
            ));
            _isLoading = false;
          });
        }
        
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: '죄송합니다. 응답을 가져오는 중 오류가 발생했습니다.\n오류: $e',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  /// 추천 결과 요청
  void _requestRecommendations() async {
    try {
      final aiResponse = await _openAIService.requestRecommendations();
      
      if (mounted) {
        final stage = aiResponse['stage'] as String?;
        final recommendations = aiResponse['recommendations'] as Map<String, dynamic>?;
        
        if (stage == 'completed' && recommendations != null && recommendations.isNotEmpty) {
          setState(() {
            _isLoading = false;
          });
          
          // 추천 결과 화면으로 이동
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecommendationResultScreen(
                  recommendations: recommendations,
                  selectedCategories: widget.selectedCategories,
                ),
              ),
            );
          }
        } else {
          setState(() {
            _messages.add(ChatMessage(
              text: '추천 결과를 생성할 수 없습니다. 다시 시도해주세요.',
              isUser: false,
              timestamp: DateTime.now(),
            ));
            _isLoading = false;
          });
        }
        
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: '추천 결과 생성 중 오류가 발생했습니다.\n오류: $e',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }
}

/// 단순 텍스트 채팅 말풍선 (좌측 정렬) - Yes/No 버튼 포함
class _ChatBubble extends StatelessWidget {
  final String text;
  final bool showYesNoButtons;
  final String? yesNoQuestion;
  final VoidCallback? onYesPressed;
  final VoidCallback? onNoPressed;
  
  const _ChatBubble({
    required this.text,
    this.showYesNoButtons = false,
    this.yesNoQuestion,
    this.onYesPressed,
    this.onNoPressed,
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFFFF7A21),
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          if (showYesNoButtons) ...[
            const SizedBox(height: 12),
            Text(
              yesNoQuestion ?? "선택해주세요:",
              style: const TextStyle(
                color: Color(0xFFFF7A21),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            // 결과 확인 단계인지 확인 (yesNoQuestion이 "결과물을 출력하시겠습니까?"인 경우)
            if (yesNoQuestion?.contains("결과물을 출력") == true) ...[
              // 결과 확인 단계: "네" 버튼만 표시
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onYesPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A21),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '네',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ] else ...[
              // 일반 질문 단계: "네"와 "추가하기" 버튼 표시
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onYesPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A21),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '네',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onNoPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '추가하기',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// 선택한 카테고리를 보여주는 칩 형태의 태그
class _ChipTag extends StatelessWidget {
  final String label;
  const _ChipTag({required this.label});

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFFFF7A21);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accent, 
          width: 1.6
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000), 
            blurRadius: 8, 
            offset: Offset(0, 4)
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(label), color: accent, size: 18),
          const SizedBox(width: 6),
          Text(
            label, 
            style: const TextStyle(
              color: accent, 
              fontWeight: FontWeight.w700,
              fontSize: 12,
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