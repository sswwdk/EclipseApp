import 'dart:async';

import 'package:flutter/material.dart';
import '../../../data/services/service_api.dart'; // 통합된 서비스 import (OpenAIService 포함)
import '../../widgets/dialogs/common_dialogs.dart';
import 'loading_screan.dart';
import 'schedule_screen.dart';

/// 카테고리 아이콘 매핑 헬퍼 함수
IconData _getCategoryIcon(String category) {
  switch (category) {
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

const String TAG_ACTION_PREFIX = "__TAG_ACTION__";
const String TAG_ACTION_SEPARATOR = "::";
const String TAG_ACTION_REMOVE = "remove";
const String TAG_ACTION_CLEAR = "clear";

/// 채팅 메시지 데이터 모델
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? selectedCategories;
  final bool showYesNoButtons;
  final String? yesNoQuestion;
  final List<String>? availableCategories;
  bool isButtonActive; // 버튼 활성화 상태
  String? selectedButton; // 선택된 버튼 ('yes' 또는 'no', null이면 선택 안 됨)

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.selectedCategories,
    this.showYesNoButtons = false,
    this.yesNoQuestion,
    this.availableCategories,
    this.isButtonActive = true, // 기본값은 활성화
    this.selectedButton, // 기본값은 null (선택 안 됨)
  });
}

/// 선택한 내용 요약과 질문을 보여주는 간단한 채팅 화면
class ChatScreen extends StatefulWidget {
  /// 위치
  final String location;
  /// 인원 수 (추후 프롬프트에 활용 가능)
  final int peopleCount;
  /// 사용자가 선택한 카테고리 목록
  final List<String> selectedCategories;

  const ChatScreen({super.key, required this.location, required this.peopleCount, required this.selectedCategories});

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
  bool _isFinalLoading = false;
  
  // 현재 대화 단계 (입력창 제어를 위해)
  String _currentStage = "collecting_details";
  
  // 후보지 출력 완료 상태
  bool _showRecommendationButton = false;
  Map<String, dynamic>? _recommendations;
  Completer<Map<String, dynamic>>? _recommendationCompleter;
  List<String> _activeTags = [];
  String? _activeCategory;

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
        playAddress: widget.location,
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

  void _deactivatePreviousButtons() {
    for (var message in _messages) {
      if (message.showYesNoButtons) {
        message.isButtonActive = false;
      }
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final userMessage = _messageController.text.trim();
    
    // confirming_results 단계에서 긍정적 표현 체크
    if (_currentStage == "confirming_results") {
      final isPositive = _isPositiveResponse(userMessage);
      if (isPositive) {
        // 긍정적 표현이면 Yes 버튼을 누른 것처럼 처리
        _handleYesNoResponse(true, userInputMessage: userMessage);
        return;
      }
    }
    
    setState(() {
      _deactivatePreviousButtons();
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true; // 로딩 시작
    });
    
    _messageController.clear();
    _scrollToBottom();
    _maintainFocus();
    
    try {
      // FastAPI /api/chat 호출
      final response = await _openAIService.sendMessage(userMessage);
      
      if (mounted) {
        _processServerResponse(
          response,
          originalUserMessage: userMessage,
          navigateOnComplete: false,
        );
      }
    } catch (e) {
      _addErrorMessage('죄송합니다. 응답을 가져오는 중 오류가 발생했습니다.\n오류: $e');
      _maintainFocus();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 포커스 유지 헬퍼 함수
  void _maintainFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _messageFocusNode.requestFocus();
      }
    });
  }

  /// 에러 메시지 추가 헬퍼 함수
  void _addErrorMessage(String errorText) {
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(
        text: errorText,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _isLoading = false;
      _isFinalLoading = false;
    });
    _scrollToBottom();
  }

  /// 뒤로가기 확인 헬퍼 함수
  void _handleBackNavigation() {
    CommonDialogs.showBackConfirmation(
      context: context,
      onConfirm: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      },
    );
  }


  /// 긍정적 표현 체크
  bool _isPositiveResponse(String message) {
    final lowerMessage = message.toLowerCase().trim();
    final positiveWords = [
      "네", "넹", "넵", "예", "yes", "y", "ok", "좋아", "좋아요", "그래", "맞아", 
      "ㅇㅇ", "ㅇ", "기기", "ㄱㄱ", "고고", "네네", "응", "어", "ㅇㅋ", "오케이",
      "후보지", "후보지 출력", "출력", "보여줘", "보여주세요", "확인"
    ];
    
    return positiveWords.any((word) => lowerMessage.contains(word));
  }


  @override
  Widget build(BuildContext context) {
      return WillPopScope(
      onWillPop: () async {
        _handleBackNavigation();
        return false; // 기본 뒤로가기 동작 방지
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 헤더 (뒤로가기, 타이틀)
            _ChatHeader(onBackPressed: _handleBackNavigation),

            // 메시지 리스트
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount:
                    _messages.length + (_isLoading && !_isFinalLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  // 로딩 인디케이터 표시
                  if (index == _messages.length &&
                    _isLoading &&
                    !_isFinalLoading) {
                    return const LoadingScreanIndicator();
                  }
                  
                  final message = _messages[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildMessageWidget(message),
                  );
                },
              ),
            ),

            // 하단 입력창 또는 후보지 고르러 가기 버튼
            if (_activeTags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _ActiveTagPanel(
                  tags: _activeTags,
                  isLoading: _isLoading,
                  onTagRemove: (_activeCategory != null)
                      ? (tag) => _handleTagRemove(_activeCategory!, tag)
                      : null,
                  onClearAll: (_activeCategory != null)
                      ? () => _handleTagClear(_activeCategory!)
                      : null,
                ),
              ),
            if (_showRecommendationButton)
              // 후보지 고르러 가기 버튼
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_recommendations != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoadingScrean(
                              loadingTask: Future.value(_recommendations!),
                              selectedCategories: widget.selectedCategories,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A21),
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: const Color(0xFFFF7A21).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '후보지 고르러 가기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              )
            else
              // 일반 채팅 입력창
              _ChatInputField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                isLoading: _isLoading,
                isCompleted: _currentStage == "completed",
                onSend: _sendMessage,
              )
          ],
        ),
      ),
      ),
    );
  }

  /// 카테고리 칩 위젯 생성
  Widget _buildCategoryChip(String category) {
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
          Icon(_getCategoryIcon(category), color: const Color(0xFFFF7A21), size: 18),
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
            isButtonActive: message.isButtonActive,
            selectedButton: message.selectedButton,
            onYesPressed: () => _handleYesNoResponse(true),
            onNoPressed: () => _handleYesNoResponse(false),
          ),
        );
      }
    }
  }

  /// Yes/No 버튼 응답 처리
  void _handleYesNoResponse(bool isYes, {String? userInputMessage}) async {
    // 현재 메시지의 yesNoQuestion을 확인하여 결과 확인 단계인지 판단
    final lastMessage = _messages.isNotEmpty ? _messages.last : null;
    final isResultConfirmation = lastMessage?.yesNoQuestion?.contains("후보지를 출력") == true;
    
    // 응답 텍스트 결정
    String response;
    if (userInputMessage != null) {
      // 사용자가 직접 입력한 메시지가 있으면 그것을 사용
      response = userInputMessage;
    } else if (isResultConfirmation) {
      response = "후보지 출력"; // "후보지 출력" 버튼을 눌렀을 때
    } else if (isYes) {
      response = "네"; // "네" 버튼을 눌렀을 때
    } else {
      response = "추가하기"; // "추가하기" 버튼을 눌렀을 때
    }
    
    // 사용자가 입력한 경우 입력창 비우기
    if (userInputMessage != null) {
      _messageController.clear();
    }
    final bool expectsFinalTransition =
        isResultConfirmation && (isYes || response == "후보지 출력");

    if (expectsFinalTransition) {
      if (_recommendationCompleter == null ||
          (_recommendationCompleter?.isCompleted ?? false)) {
        _recommendationCompleter = Completer<Map<String, dynamic>>();
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LoadingScrean(
            loadingTask: _recommendationCompleter!.future,
            selectedCategories: widget.selectedCategories,
          ),
        ),
      );
    }

    setState(() {
      _deactivatePreviousButtons();
      // 현재 메시지에 선택된 버튼 표시
      if (lastMessage != null && lastMessage.showYesNoButtons) {
        lastMessage.selectedButton = isYes ? 'yes' : 'no';
      }
      if (isYes && !isResultConfirmation) {
        _activeTags = [];
        _activeCategory = null;
      }
      
      _messages.add(ChatMessage(
        text: response,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
      _isFinalLoading = expectsFinalTransition;
    });
    
    _scrollToBottom();
    
    try {
      // 서버에는 긍정적 표현을 "네"로 통일하여 전송 (백엔드 호환성)
      String serverMessage;
      if (userInputMessage != null) {
        // 사용자가 직접 입력한 경우, confirming_results 단계에서는 "네"로 전송
        serverMessage = "네";
      } else if (response == "후보지 출력") {
        serverMessage = "네";
      } else {
        serverMessage = response;
      }
      final aiResponse = await _openAIService.sendMessage(serverMessage);
      
      if (mounted) {
        final navigateOnComplete = isYes || response == "후보지 출력";
        _processServerResponse(
          aiResponse,
          originalUserMessage: response,
          navigateOnComplete: navigateOnComplete,
          requestRecommendationsOnEmpty: navigateOnComplete,
        );
      }
    } catch (e) {
      _addErrorMessage('죄송합니다. 응답을 가져오는 중 오류가 발생했습니다.\n오류: $e');
      if (_recommendationCompleter != null &&
          !(_recommendationCompleter?.isCompleted ?? true)) {
        _recommendationCompleter?.completeError(e);
      }
      _recommendationCompleter = null;
      _isFinalLoading = false;
      _maintainFocus();
    }
  }

  void _processServerResponse(
    Map<String, dynamic> response, {
    String? originalUserMessage,
    bool navigateOnComplete = false,
    bool requestRecommendationsOnEmpty = false,
  }) {
    if (!mounted) return;

    final message = response['message'] as String? ?? '';
    final stage = response['stage'] as String?;
    final recommendations = response['recommendations'] as Map<String, dynamic>?;
    final showYesNoButtons = response['showYesNoButtons'] as bool? ?? false;
    final yesNoQuestion = response['yesNoQuestion'] as String?;
    final availableCategories = response['availableCategories'] as List<dynamic>?;
    final rawTags = response['tags'] as List<dynamic>?;
    final tags = rawTags
            ?.map((tag) => tag.toString())
            .where((tag) => tag.trim().isNotEmpty)
            .toList() ??
        <String>[];
    final currentCategory = response['currentCategory'] as String?;

    if (stage != null) {
      _currentStage = stage;
    }

    final bool isTagAction = originalUserMessage?.startsWith(TAG_ACTION_PREFIX) ?? false;

    String? nextCategory = _activeCategory;
    List<String> nextTags = _activeTags;

    if (stage != 'collecting_details') {
      nextTags = [];
      if (currentCategory != null) {
        nextCategory = currentCategory;
      }
    } else {
      if (currentCategory != null) {
        if (nextCategory != currentCategory) {
          nextCategory = currentCategory;
          nextTags = List.from(tags);
        } else if (isTagAction || tags.isNotEmpty) {
          nextTags = List.from(tags);
        }
      } else if (isTagAction || tags.isNotEmpty) {
        nextTags = List.from(tags);
      }
    }

    if (!navigateOnComplete &&
        originalUserMessage == "네" &&
        stage == 'completed' &&
        recommendations != null &&
        recommendations.isNotEmpty) {
      setState(() {
      if (stage != null) {
        _currentStage = stage;
      }
      _activeCategory = nextCategory;
      _activeTags = nextTags;
      _isLoading = false;
      _isFinalLoading = false;
        _showRecommendationButton = true;
        _recommendations = recommendations;
      });
      _scrollToBottom();
      _maintainFocus();
      return;
    }

    if (navigateOnComplete && stage == 'completed') {
      if (recommendations != null && recommendations.isNotEmpty) {
        if (_recommendationCompleter != null &&
            !(_recommendationCompleter?.isCompleted ?? true)) {
          _recommendationCompleter?.complete(recommendations);
        }
        _recommendationCompleter = null;
        setState(() {
          if (stage != null) {
            _currentStage = stage;
          }
          _activeCategory = nextCategory;
          _activeTags = nextTags;
          _isLoading = false;
          _isFinalLoading = false;
          _showRecommendationButton = false;
          _recommendations = recommendations;
        });
        return;
      } else if (requestRecommendationsOnEmpty) {
        setState(() {
          if (stage != null) {
            _currentStage = stage;
          }
          _activeCategory = nextCategory;
          _activeTags = nextTags;
          _isLoading = false;
          _isFinalLoading = false;
          _showRecommendationButton = false;
        });
        _requestRecommendations();
        return;
      } else {
        if (_recommendationCompleter != null &&
            !(_recommendationCompleter?.isCompleted ?? true)) {
          _recommendationCompleter
              ?.completeError(Exception('추천 결과가 없습니다.'));
        }
        _recommendationCompleter = null;
        setState(() {
          if (stage != null) {
            _currentStage = stage;
          }
          _activeCategory = nextCategory;
          _activeTags = nextTags;
          _isLoading = false;
          _isFinalLoading = false;
        });
        return;
      }
    }

    if (originalUserMessage == "추가하기" &&
        availableCategories != null &&
        availableCategories.isNotEmpty) {
      setState(() {
        if (stage != null) {
          _currentStage = stage;
        }
        _activeCategory = nextCategory;
        _activeTags = nextTags;
        _deactivatePreviousButtons();
        _messages.add(ChatMessage(
          text: message,
          isUser: false,
          timestamp: DateTime.now(),
          selectedCategories: availableCategories.cast<String>(),
        ));
        _isLoading = false;
      });
      _scrollToBottom();
      _maintainFocus();
      return;
    }

    setState(() {
      if (stage != null) {
        _currentStage = stage;
      }
      _activeCategory = nextCategory;
      _activeTags = nextTags;
      _deactivatePreviousButtons();
      _messages.add(ChatMessage(
        text: message,
        isUser: false,
        timestamp: DateTime.now(),
        showYesNoButtons: showYesNoButtons,
        yesNoQuestion: yesNoQuestion,
        availableCategories: availableCategories?.cast<String>(),
      ));
      _isLoading = false;
      _isFinalLoading = false;
    });

    _scrollToBottom();
    _maintainFocus();
  }

  Future<void> _handleTagRemove(String category, String tag) async {
    if (_isLoading) return;
    if (category.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카테고리 정보가 없어 태그를 삭제할 수 없어요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final command =
          "$TAG_ACTION_PREFIX:$TAG_ACTION_REMOVE$TAG_ACTION_SEPARATOR$category$TAG_ACTION_SEPARATOR$tag";
      final response = await _openAIService.sendMessage(command);
      if (!mounted) return;
      _processServerResponse(response, originalUserMessage: command);
    } catch (e) {
      _addErrorMessage('태그를 삭제하는 중 오류가 발생했어요.\n오류: $e');
    }
  }

  Future<void> _handleTagClear(String category) async {
    if (_isLoading) return;
    if (category.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카테고리 정보가 없어 태그를 모두 지울 수 없어요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final command =
          "$TAG_ACTION_PREFIX:$TAG_ACTION_CLEAR$TAG_ACTION_SEPARATOR$category";
      final response = await _openAIService.sendMessage(command);
      if (!mounted) return;
      _processServerResponse(response, originalUserMessage: command);
    } catch (e) {
      _addErrorMessage('태그를 모두 삭제하는 중 오류가 발생했어요.\n오류: $e');
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
          if (_recommendationCompleter != null &&
              !(_recommendationCompleter?.isCompleted ?? true)) {
            _recommendationCompleter?.complete(recommendations);
            _recommendationCompleter = null;
            setState(() {
              _isLoading = false;
              _isFinalLoading = false;
              _showRecommendationButton = false;
              _recommendations = recommendations;
            });
          } else {
            setState(() {
              _isLoading = false;
              _showRecommendationButton = true;
              _recommendations = recommendations;
            });
          }
        } else {
          if (_recommendationCompleter != null &&
              !(_recommendationCompleter?.isCompleted ?? true)) {
            _recommendationCompleter
                ?.completeError(Exception('추천 결과를 생성할 수 없습니다.'));
            _recommendationCompleter = null;
          }
          setState(() {
            _messages.add(ChatMessage(
              text: '추천 결과를 생성할 수 없습니다. 다시 시도해주세요.',
              isUser: false,
              timestamp: DateTime.now(),
            ));
            _isLoading = false;
            _isFinalLoading = false;
          });
        }
        
        _scrollToBottom();
      }
    } catch (e) {
      _addErrorMessage('추천 결과 생성 중 오류가 발생했습니다.\n오류: $e');
      if (_recommendationCompleter != null &&
          !(_recommendationCompleter?.isCompleted ?? true)) {
        _recommendationCompleter?.completeError(e);
        _recommendationCompleter = null;
      }
    }
  }
}

/// 채팅 헤더 위젯
class _ChatHeader extends StatelessWidget {
  final VoidCallback onBackPressed;

  const _ChatHeader({required this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          height: 44,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: onBackPressed,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                  iconSize: 24,
                ),
              ),
              const Center(
                child: Text(
                  '하루와 할 일 찾기',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 채팅 입력창 위젯
class _ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final bool isCompleted;
  final VoidCallback onSend;

  const _ChatInputField({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.isCompleted,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = isLoading || isCompleted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: const InputDecorationTheme(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                  ),
                ),
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
                    controller: controller,
                    focusNode: focusNode,
                    enabled: !isDisabled,
                    style: const TextStyle(color: Colors.black87),
                    decoration: const InputDecoration(
                      hintText: '메시지를 입력하세요...',
                      hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                      isDense: true,
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isDisabled ? null : onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDisabled ? Colors.grey : const Color(0xFFFF7A21),
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
    );
  }
}

/// 단순 텍스트 채팅 말풍선 (좌측 정렬) - Yes/No 버튼 포함
class _ChatBubble extends StatelessWidget {
  final String text;
  final bool showYesNoButtons;
  final String? yesNoQuestion;
  final bool isButtonActive;
  final String? selectedButton;
  final VoidCallback? onYesPressed;
  final VoidCallback? onNoPressed;
  
  const _ChatBubble({
    required this.text,
    this.showYesNoButtons = false,
    this.yesNoQuestion,
    this.isButtonActive = true,
    this.selectedButton,
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
            // 결과 확인 단계인지 확인 (yesNoQuestion이 "후보지를 출력하시겠습니까?"인 경우)
            if (yesNoQuestion?.contains("후보지를 출력") == true) ...[
              // 결과 확인 단계: "후보지 출력" 버튼만 표시
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isButtonActive ? onYesPressed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isButtonActive 
                      ? const Color(0xFFFF7A21) 
                      : (selectedButton == 'yes' ? Colors.white : Colors.grey[400]),
                    foregroundColor: isButtonActive 
                      ? Colors.white 
                      : (selectedButton == 'yes' ? const Color(0xFFFF7A21) : Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: !isButtonActive && selectedButton == 'yes'
                        ? const BorderSide(color: Color(0xFFFF7A21), width: 2)
                        : BorderSide.none,
                    ),
                    disabledBackgroundColor: selectedButton == 'yes' ? Colors.white : Colors.grey[400],
                    disabledForegroundColor: selectedButton == 'yes' ? const Color(0xFFFF7A21) : Colors.white,
                  ),
                  child: const Text(
                    '후보지 출력',
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
                      onPressed: isButtonActive ? onYesPressed : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isButtonActive 
                          ? const Color(0xFFFF7A21) 
                          : (selectedButton == 'yes' ? Colors.white : Colors.grey[400]),
                        foregroundColor: isButtonActive 
                          ? Colors.white 
                          : (selectedButton == 'yes' ? const Color(0xFFFF7A21) : Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: !isButtonActive && selectedButton == 'yes'
                            ? const BorderSide(color: Color(0xFFFF7A21), width: 2)
                            : BorderSide.none,
                        ),
                        disabledBackgroundColor: selectedButton == 'yes' ? Colors.white : Colors.grey[400],
                        disabledForegroundColor: selectedButton == 'yes' ? const Color(0xFFFF7A21) : Colors.white,
                      ),
                      child: const Text(
                        '다음 질문',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isButtonActive ? onNoPressed : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isButtonActive 
                          ? Colors.grey[300] 
                          : (selectedButton == 'no' ? Colors.white : Colors.grey[400]),
                        foregroundColor: isButtonActive 
                          ? Colors.black87 
                          : (selectedButton == 'no' ? const Color(0xFFFF7A21) : Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: !isButtonActive && selectedButton == 'no'
                            ? const BorderSide(color: Color(0xFFFF7A21), width: 2)
                            : BorderSide.none,
                        ),
                        disabledBackgroundColor: selectedButton == 'no' ? Colors.white : Colors.grey[400],
                        disabledForegroundColor: selectedButton == 'no' ? const Color(0xFFFF7A21) : Colors.white,
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

/// 현재 태그를 보여주는 패널
class _ActiveTagPanel extends StatelessWidget {
  final List<String> tags;
  final bool isLoading;
  final void Function(String tag)? onTagRemove;
  final VoidCallback? onClearAll;

  const _ActiveTagPanel({
    required this.tags,
    required this.isLoading,
    this.onTagRemove,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    const accent = Color(0xFFFF7A21);
    final canModify = onTagRemove != null && !isLoading;
    final canClearAll = onClearAll != null && !isLoading && tags.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.2)),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '현재 키워드',
            style: const TextStyle(
              color: Color(0xFFFF7A21),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) => _TagChip(
                  label: tag,
                  canModify: canModify,
                  onRemove: canModify ? () => onTagRemove?.call(tag) : null,
                )).toList(),
          ),
          if (canClearAll) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onClearAll,
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFFF7A21)),
                label: const Text(
                  '전체 삭제',
                  style: TextStyle(
                    color: Color(0xFFFF7A21),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool canModify;
  final VoidCallback? onRemove;

  const _TagChip({
    required this.label,
    required this.canModify,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF7A21);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4A4A4A),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: canModify ? onRemove : null,
            child: Icon(
              Icons.close,
              size: 16,
              color: canModify ? accent : accent.withOpacity(0.3),
            ),
          ),
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
          Icon(_getCategoryIcon(label), color: accent, size: 18),
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

}