class OpenAIService {
  // 대화 히스토리를 저장 (컨텍스트 유지용)
  List<Map<String, String>> conversationHistory = [];

  OpenAIService() {
    // 더미 모드에서는 API 키 검증을 하지 않음
  }

  /// 시스템 프롬프트 초기화 (앱의 AI 역할 설정)
  void initializeWithContext({
    required int peopleCount,
    required List<String> selectedCategories,
  }) {
    conversationHistory.clear();
    
    String systemPrompt = '''
당신은 친근하고 도움이 되는 여가 활동 추천 도우미입니다.
사용자는 ${peopleCount}명이 함께 놀 계획이며, 다음 카테고리에 관심이 있습니다: ${selectedCategories.join(', ')}.

사용자의 요구사항을 자세히 듣고, 구체적이고 실용적인 추천을 제공하세요.
답변은 친근하고 간결하게 작성하며, 한국어로 대화하세요.
''';

    conversationHistory.add({
      'role': 'system',
      'content': systemPrompt,
    });
  }

  /// 더미 응답 반환 (API 호출 대신)
  Future<String> sendMessage(String userMessage) async {
    try {
      // 사용자 메시지를 히스토리에 추가
      conversationHistory.add({
        'role': 'user',
        'content': userMessage,
      });

      // 더미 응답 생성
      await Future.delayed(const Duration(seconds: 1)); // 실제 API 호출처럼 딜레이
      
      String dummyResponse = _generateDummyResponse(userMessage);
      
      // AI 응답을 히스토리에 추가 (다음 대화 컨텍스트 유지)
      conversationHistory.add({
        'role': 'assistant',
        'content': dummyResponse,
      });
      
      return dummyResponse.trim();
    } catch (e) {
      return 'Error: 응답을 가져오는 중 오류가 발생했습니다. ($e)';
    }
  }

  /// 더미 응답 생성
  String _generateDummyResponse(String userMessage) {
    List<String> responses = [
      '좋은 아이디어네요! 그런 활동은 정말 재미있을 것 같아요. 혹시 다른 옵션도 고려해보시겠어요?',
      '흥미로운 선택이에요! 이런 활동을 하면 좋은 추억을 만들 수 있을 거예요.',
      '그거 정말 좋은 생각이에요! 더 자세한 계획을 세워보는 것도 좋겠어요.',
      '훌륭한 아이디어네요! 이런 활동은 모두가 즐길 수 있을 것 같아요.',
      '정말 멋진 선택이에요! 이런 경험은 오랫동안 기억에 남을 거예요.',
      '좋은 제안이네요! 이런 활동을 통해 더 가까워질 수 있을 것 같아요.',
      '흥미로운 아이디어예요! 이런 새로운 경험은 정말 좋을 것 같아요.',
      '훌륭한 계획이네요! 이런 활동을 하면 정말 즐거운 시간을 보낼 수 있을 거예요.',
    ];
    
    // 사용자 메시지에 따라 다른 응답 반환
    if (userMessage.toLowerCase().contains('영화')) {
      return '영화 보기 정말 좋은 선택이에요! 최근에 나온 영화 중에서 ${_getRandomMovie()} 같은 영화는 어떠세요?';
    } else if (userMessage.toLowerCase().contains('음식') || userMessage.toLowerCase().contains('맛집')) {
      return '맛집 탐방도 정말 좋은 아이디어네요! ${_getRandomRestaurant()} 같은 곳은 어떠세요?';
    } else if (userMessage.toLowerCase().contains('카페')) {
      return '카페에서 여유로운 시간 보내기 좋은 생각이에요! ${_getRandomCafe()} 같은 카페는 어떠세요?';
    } else if (userMessage.toLowerCase().contains('산책') || userMessage.toLowerCase().contains('공원')) {
      return '산책이나 공원 나들이도 정말 좋은 선택이에요! 날씨가 좋을 때 이런 활동을 하면 기분이 정말 좋아질 거예요.';
    } else {
      return responses[DateTime.now().millisecond % responses.length];
    }
  }

  String _getRandomMovie() {
    List<String> movies = ['기생충', '극한직업', '명량', '신과함께', '어벤져스'];
    return movies[DateTime.now().millisecond % movies.length];
  }

  String _getRandomRestaurant() {
    List<String> restaurants = ['한식당', '일식당', '중식당', '양식당', '분식점'];
    return restaurants[DateTime.now().millisecond % restaurants.length];
  }

  String _getRandomCafe() {
    List<String> cafes = ['스타벅스', '이디야', '투썸플레이스', '커피빈', '로컬카페'];
    return cafes[DateTime.now().millisecond % cafes.length];
  }

  /// 대화 히스토리 초기화
  void clearHistory() {
    conversationHistory.clear();
  }
}