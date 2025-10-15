import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  final String apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final String apiUrl = 'https://api.openai.com/v1/chat/completions';
  
  // 대화 히스토리를 저장 (컨텍스트 유지용)
  List<Map<String, String>> conversationHistory = [];

  OpenAIService() {
    if (apiKey.isEmpty) {
      throw Exception('OpenAI API 키가 설정되지 않았습니다.');
    }
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

  /// OpenAI API 호출하여 응답 받기
  Future<String> sendMessage(String userMessage) async {
    try {
      // 사용자 메시지를 히스토리에 추가
      conversationHistory.add({
        'role': 'user',
        'content': userMessage,
      });

      // API 요청 본문
      final requestBody = {
        'model': 'gpt-4o-mini', // 또는 'gpt-4', 'gpt-3.5-turbo' 등
        'messages': conversationHistory,
        'temperature': 0.7,
        'max_tokens': 500,
      };

      // HTTP POST 요청
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final aiMessage = data['choices'][0]['message']['content'] as String;
        
        // AI 응답을 히스토리에 추가 (다음 대화 컨텍스트 유지)
        conversationHistory.add({
          'role': 'assistant',
          'content': aiMessage,
        });
        
        return aiMessage.trim();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('API 오류: ${errorData['error']['message']}');
      }
    } catch (e) {
      return 'Error: 응답을 가져오는 중 오류가 발생했습니다. ($e)';
    }
  }

  /// 대화 히스토리 초기화
  void clearHistory() {
    conversationHistory.clear();
  }
}