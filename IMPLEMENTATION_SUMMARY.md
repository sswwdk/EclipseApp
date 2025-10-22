# 구현 요약 및 상세 설명

## 📋 전체 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter App                            │
├─────────────────────────────────────────────────────────────┤
│  1. make_todo.dart (인원 수 + 카테고리 선택)                │
│      ↓                                                       │
│  2. make_todo_chat.dart (채팅 화면)                         │
│      ↓ HTTP 통신                                             │
│  3. openai_service.dart (API 통신)                          │
└─────────────────────────────────────────────────────────────┘
                          ↕ HTTP (JSON)
┌─────────────────────────────────────────────────────────────┐
│                   FastAPI Server                            │
│                  (haru_gpt_api.py)                          │
├─────────────────────────────────────────────────────────────┤
│  • POST /api/start  (대화 초기화)                           │
│  • POST /api/chat   (메시지 송수신)                         │
│  • LangChain + OpenAI (태그 추출, 추천 생성)                │
└─────────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────────┐
│                   OpenAI API                                │
│                 (gpt-4o-mini)                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🆕 새로 추가된 파일

### 1. `haru_gpt_api.py` (FastAPI 서버)

#### 주요 구성 요소:

##### **A. 데이터 모델 (Pydantic)**
```python
class StartRequest(BaseModel):
    peopleCount: int
    selectedCategories: List[str]

class ChatRequest(BaseModel):
    sessionId: str
    message: str
```
- 타입 안정성 보장
- 자동 JSON 검증 및 변환

##### **B. 세션 관리**
```python
sessions: Dict[str, Dict] = {}
```
- **메모리 기반** 저장소 (개발용)
- 각 세션은 UUID로 식별
- 세션 데이터 구조:
  ```python
  {
    "peopleCount": 2,
    "selectedCategories": ["카페", "음식점"],
    "collectedTags": {},  # 카테고리별 태그 저장
    "currentCategoryIndex": 0,  # 현재 질문 중인 카테고리
    "conversationHistory": [],  # 대화 히스토리
    "stage": "collecting_details"  # 현재 단계
  }
  ```

##### **C. LangChain 체인 설정**
```python
def setup_chain():
    llm = ChatOpenAI(
        model="gpt-4o-mini",
        openai_api_key=openai_api_key,
        temperature=0.1  # 안정적인 응답
    )
    
    prompt_template = ChatPromptTemplate.from_messages([
        ("system", system_prompt),
        ("user", "{user_input}")
    ])
    
    return prompt_template | llm | StrOutputParser()
```
- **temperature=0.1**: 일관된 태그 추출
- **파이프라인 구조**: prompt → LLM → parser

##### **D. API 엔드포인트**

###### **`POST /api/start`** - 대화 시작
```python
@app.post("/api/start", response_model=StartResponse)
async def start_conversation(request: StartRequest):
    # 1. 세션 ID 생성 (UUID)
    session_id = str(uuid.uuid4())
    
    # 2. 세션 데이터 초기화
    sessions[session_id] = {...}
    
    # 3. 첫 번째 카테고리 질문 생성
    first_category = request.selectedCategories[0]
    first_message = f"좋아! '{first_category}' 활동에 대해..."
    
    # 4. 응답 반환
    return StartResponse(
        sessionId=session_id,
        message=first_message,
        ...
    )
```

**처리 흐름:**
1. UUID로 고유 세션 ID 생성
2. 인원 수와 카테고리 저장
3. 첫 번째 카테고리에 대한 질문 생성
4. 세션 ID와 첫 메시지 반환

###### **`POST /api/chat`** - 메시지 처리
```python
@app.post("/api/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    # 1. 세션 조회
    session = sessions[request.sessionId]
    
    # 2. 태그 추출
    tags = extract_tags(request.message)
    
    # 3. 현재 카테고리에 태그 저장
    session["collectedTags"][current_category] = tags
    
    # 4. 다음 카테고리 확인
    if has_more_categories:
        # 다음 질문 반환
        return ChatResponse(...)
    else:
        # 추천 생성
        recommendations = generate_recommendations(...)
        return ChatResponse(stage="completed", ...)
```

**처리 흐름:**
1. 세션 ID로 세션 조회
2. LangChain으로 사용자 메시지에서 태그 추출
3. 현재 카테고리에 태그 저장
4. **분기 처리**:
   - 더 질문할 카테고리 있으면 → 다음 질문 생성
   - 모든 카테고리 완료 → 추천 생성 및 반환

##### **E. 핵심 함수**

###### `extract_tags()` - 태그 추출
```python
def extract_tags(user_detail: str) -> List[str]:
    tagging_prompt = f"""
    사용자가 "{user_detail}"라고 말했어.
    이 문장에서 핵심 키워드를 5~6개만 추출해서...
    """
    
    tag_response = chain.invoke({"user_input": tagging_prompt})
    tag_list = [tag.strip() for tag in tag_response.split(",")]
    return tag_list
```
- LLM에게 키워드 추출 요청
- 쉼표로 구분된 응답 파싱
- 예: "조용하고 와이파이 잘 되는 곳" → ["조용한", "와이파이", "공부하기 좋은"]

###### `generate_recommendations()` - 추천 생성
```python
def generate_recommendations(selected_activities, collected_tags):
    tags_text = ""
    for category, tags in collected_tags.items():
        tags_text += f"\n- {category}: {', '.join(tags)}"
    
    recommend_prompt = f"""
    아래 정보를 바탕으로 추천 장소를 만들어줘.
    [사용자가 선택한 활동] {', '.join(selected_activities)}
    [각 활동별 선호 키워드] {tags_text}
    ...
    """
    
    recommendations = chain.invoke({"user_input": recommend_prompt})
    return recommendations
```
- 수집된 모든 태그를 프롬프트로 조합
- LLM에게 추천 장소 생성 요청
- 예시 출력: "카페: 1. 조용한 북카페 '책과 쉼', 2. ..."

###### `parse_recommendations()` - 추천 파싱
```python
def parse_recommendations(recommendations_text, selected_activities):
    result = {}
    for line in recommendations_text.split('\n'):
        for category in selected_activities:
            if line.startswith(category):
                # "카테고리: 1. 장소1, 2. 장소2" 파싱
                places = [...]
                result[category] = places
    return result
```
- LLM 텍스트 응답을 JSON 구조로 변환
- 숫자와 점 제거하여 장소명만 추출

##### **F. CORS 설정**
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Flutter 앱 접근 허용
    allow_methods=["*"],
    allow_headers=["*"],
)
```
- Flutter 앱에서 API 호출 가능하도록 설정

---

## 🔄 수정된 파일

### 2. `lib/services/openai_service.dart`

#### 변경 전 (더미 모드):
```dart
Future<String> sendMessage(String userMessage) async {
    // 더미 응답 생성
    String dummyResponse = _generateDummyResponse(userMessage);
    return dummyResponse.trim();
}
```

#### 변경 후 (FastAPI 통신):
```dart
// 1. 초기화 메서드 (새로 추가)
Future<String> initialize({
    required int peopleCount,
    required List<String> selectedCategories,
}) async {
    final response = await http.post(
        Uri.parse('$baseUrl/api/start'),
        body: jsonEncode({
            'peopleCount': peopleCount,
            'selectedCategories': selectedCategories,
        }),
    );
    
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    _sessionId = data['sessionId'];  // 세션 ID 저장
    return data['message'];
}

// 2. 메시지 전송 (응답 구조 변경)
Future<Map<String, dynamic>> sendMessage(String userMessage) async {
    final response = await http.post(
        Uri.parse('$baseUrl/api/chat'),
        body: jsonEncode({
            'sessionId': _sessionId,
            'message': userMessage,
        }),
    );
    
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return {
        'message': data['message'],
        'stage': data['stage'],  // 현재 단계
        'tags': data['tags'],  // 추출된 태그
        'recommendations': data['recommendations'],  // 추천 결과
    };
}
```

#### 주요 변경 사항:
1. **더미 응답 제거** → HTTP 통신으로 대체
2. **세션 관리 추가** → `_sessionId` 저장
3. **응답 타입 변경** → `String` → `Map<String, dynamic>`
4. **UTF-8 인코딩** → 한글 처리 보장
5. **baseUrl 설정** → Android 에뮬레이터용 `10.0.2.2:8000`

---

### 3. `lib/make_todo/make_todo_chat.dart`

#### 변경 전 (로컬 초기화):
```dart
@override
void initState() {
    super.initState();
    _openAIService = OpenAIService();
    _openAIService.initializeWithContext(
        peopleCount: widget.peopleCount,
        selectedCategories: widget.selectedCategories,
    );
    
    _messages.addAll([
        ChatMessage(text: '오늘 어떻게 놀고 싶어?', ...)
    ]);
}
```

#### 변경 후 (비동기 초기화):
```dart
@override
void initState() {
    super.initState();
    _openAIService = OpenAIService();
    _initializeChat();  // 비동기 초기화
}

Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    
    try {
        // FastAPI /api/start 호출
        final firstMessage = await _openAIService.initialize(
            peopleCount: widget.peopleCount,
            selectedCategories: widget.selectedCategories,
        );
        
        setState(() {
            _messages.add(ChatMessage(text: firstMessage, ...));
            _isLoading = false;
        });
    } catch (e) {
        setState(() {
            _messages.add(ChatMessage(
                text: '서버 연결에 실패했습니다...',
                ...
            ));
            _isLoading = false;
        });
    }
}
```

#### 메시지 전송 변경:

##### 변경 전 (단순 텍스트 응답):
```dart
final aiResponse = await _openAIService.sendMessage(userMessage);

_messages.add(ChatMessage(text: aiResponse, ...));
```

##### 변경 후 (구조화된 응답 처리):
```dart
final response = await _openAIService.sendMessage(userMessage);

final stage = response['stage'];
final message = response['message'];
final tags = response['tags'];
final recommendations = response['recommendations'];

if (stage == 'completed' && recommendations != null) {
    // 추천 결과 포맷팅 및 표시
    String recommendationText = '\n📍 추천 장소:\n\n';
    recommendations.forEach((category, places) {
        recommendationText += '[$category]\n';
        for (var i = 0; i < places.length; i++) {
            recommendationText += '${i + 1}. ${places[i]}\n';
        }
    });
    
    _messages.add(ChatMessage(text: message, ...));
    _messages.add(ChatMessage(text: recommendationText, ...));
} else {
    // 태그 표시 (있는 경우)
    if (tags != null && tags.isNotEmpty) {
        _messages.add(ChatMessage(
            text: '🏷️ 추출된 키워드: ${tags.join(', ')}',
            ...
        ));
    }
    
    // 다음 질문 표시
    _messages.add(ChatMessage(text: message, ...));
}
```

#### 주요 변경 사항:
1. **비동기 초기화** → 서버에서 첫 메시지 받아오기
2. **응답 분기 처리**:
   - `stage == 'collecting_details'` → 태그 + 다음 질문 표시
   - `stage == 'completed'` → 추천 결과 포맷팅 및 표시
3. **태그 시각화** → 🏷️ 이모지와 함께 표시
4. **추천 결과 포맷팅** → 카테고리별 구조화된 표시
5. **에러 처리 강화** → 서버 연결 실패 시 안내 메시지

---

## 🔄 데이터 흐름 상세

### **시나리오: 사용자가 "2명, 카페+음식점" 선택**

#### **1단계: 앱 시작 → 채팅 화면 진입**
```
[Flutter] make_todo.dart
  → 인원: 2명 선택
  → 카테고리: ["카페", "음식점"] 선택
  → Navigator.push(ChatScreen(...))

[Flutter] make_todo_chat.dart - initState()
  → _initializeChat() 호출

[Flutter] openai_service.dart - initialize()
  → POST http://10.0.2.2:8000/api/start
  → Body: {"peopleCount": 2, "selectedCategories": ["카페", "음식점"]}

[FastAPI] /api/start
  → 세션 ID 생성: "abc-123-def"
  → 세션 데이터 저장
  → 첫 질문 생성: "좋아! '카페' 활동에 대해..."
  → Response: {"sessionId": "abc-123-def", "message": "...", ...}

[Flutter] make_todo_chat.dart
  → 첫 메시지를 채팅창에 표시
```

#### **2단계: 첫 번째 카테고리 답변**
```
[사용자] "조용하고 와이파이 잘 되는 곳" 입력

[Flutter] make_todo_chat.dart - _sendMessage()
  → 사용자 메시지 추가 (오른쪽 말풍선)
  → openai_service.sendMessage() 호출

[Flutter] openai_service.dart
  → POST http://10.0.2.2:8000/api/chat
  → Body: {"sessionId": "abc-123-def", "message": "조용하고..."}

[FastAPI] /api/chat
  → 세션 조회
  → extract_tags() 호출
    → LangChain → OpenAI GPT-4o-mini
    → 태그 추출: ["조용한", "와이파이", "공부하기 좋은", ...]
  → collectedTags["카페"] = ["조용한", "와이파이", ...]
  → currentCategoryIndex: 0 → 1
  → 다음 질문: "그렇구나! 그럼 '음식점' 활동은?"
  → Response: {
      "message": "그렇구나! 그럼 '음식점' 활동은?",
      "stage": "collecting_details",
      "tags": ["조용한", "와이파이", ...],
      "progress": {"current": 1, "total": 2}
    }

[Flutter] make_todo_chat.dart
  → 태그 메시지 추가: "🏷️ 추출된 키워드: 조용한, 와이파이, ..."
  → 다음 질문 추가: "그렇구나! 그럼 '음식점' 활동은?"
```

#### **3단계: 두 번째 카테고리 답변**
```
[사용자] "분위기 좋고 데이트하기 좋은" 입력

[Flutter] → [FastAPI] (동일한 흐름)

[FastAPI] /api/chat
  → 태그 추출: ["분위기 좋은", "데이트", "로맨틱", ...]
  → collectedTags["음식점"] = ["분위기 좋은", ...]
  → currentCategoryIndex: 1 → 2
  → 2 >= len(selectedCategories) → 모든 카테고리 완료!
  → generate_recommendations() 호출
    → 프롬프트 생성:
      """
      [사용자가 선택한 활동] 카페, 음식점
      [각 활동별 선호 키워드]
      - 카페: 조용한, 와이파이, ...
      - 음식점: 분위기 좋은, 데이트, ...
      """
    → LangChain → OpenAI GPT-4o-mini
    → 추천 생성:
      """
      카페: 1. 조용한 북카페 '책과 쉼', 2. 스터디카페 '집중', ...
      음식점: 1. 이탈리안 '아모레', 2. 한식당 '정갈한 상', ...
      """
  → parse_recommendations() 호출
    → 텍스트 파싱 → JSON 구조
  → Response: {
      "message": "짜잔! 오늘의 추천 리스트야!",
      "stage": "completed",
      "recommendations": {
        "카페": ["조용한 북카페 '책과 쉼'", ...],
        "음식점": ["이탈리안 '아모레'", ...]
      }
    }

[Flutter] make_todo_chat.dart
  → 완료 메시지 추가: "짜잔! 오늘의 추천 리스트야!"
  → 추천 결과 포맷팅:
    """
    📍 추천 장소:
    
    [카페]
    1. 조용한 북카페 '책과 쉼'
    2. 스터디카페 '집중'
    3. 루프탑 카페 '하늘정원'
    
    [음식점]
    1. 이탈리안 '아모레'
    2. 한식당 '정갈한 상'
    3. 일식당 '오마카세 미즈'
    """
  → 추천 메시지 추가 (화면에 표시)
```

---

## 🎯 핵심 개선 사항

### 1. **아키텍처 분리**
- **Before**: 모든 로직이 Flutter에 있음 (더미 데이터)
- **After**: 백엔드(FastAPI) / 프론트엔드(Flutter) 분리
- **장점**: 
  - 로직 재사용 가능 (웹, 다른 앱에서도 사용)
  - 보안 강화 (API 키가 서버에만 존재)
  - 유지보수 용이

### 2. **실제 AI 통합**
- **Before**: 하드코딩된 응답
- **After**: LangChain + OpenAI GPT-4o-mini
- **장점**:
  - 실제 자연어 처리
  - 맥락 이해 및 개인화된 추천
  - 태그 추출 자동화

### 3. **세션 관리**
- **Before**: 상태 관리 없음
- **After**: UUID 기반 세션 관리
- **장점**:
  - 여러 사용자 동시 지원
  - 대화 컨텍스트 유지
  - 중단 후 재개 가능 (향후 확장)

### 4. **구조화된 데이터**
- **Before**: 단순 문자열 응답
- **After**: JSON 기반 구조화된 응답
- **장점**:
  - 타입 안정성
  - 확장 가능한 데이터 구조
  - UI 커스터마이징 용이

---

## 🚀 실행 방법

### 1. FastAPI 서버 실행
```bash
cd C:\llm_test\llm_flutter\EclipseApp
python haru_gpt_api.py
```

### 2. Flutter 앱 실행
```bash
flutter run
```

### 3. 테스트
1. 인원 수 선택 (예: 2명)
2. 카테고리 선택 (예: 카페, 음식점)
3. 각 카테고리에 대한 선호 사항 입력
4. 최종 추천 결과 확인

---

## 📊 응답 시간 예상

- **초기화**: ~1-2초 (세션 생성)
- **태그 추출**: ~2-3초 (GPT-4o-mini 호출)
- **추천 생성**: ~3-5초 (GPT-4o-mini 호출, 더 긴 프롬프트)

---

## 🔧 향후 개선 가능 사항

1. **세션 영속성**: Redis, PostgreSQL 등 사용
2. **스트리밍 응답**: 실시간으로 토큰 표시
3. **추천 알고리즘**: 벡터 DB + 실제 장소 데이터
4. **사용자 피드백**: 추천 평가 및 학습
5. **캐싱**: 자주 사용되는 태그/추천 캐싱
6. **에러 리트라이**: 네트워크 오류 시 재시도
7. **로깅**: 대화 로그 저장 및 분석

---

## ✅ 완료된 작업

- ✅ FastAPI 서버 구현 (`haru_gpt_api.py`)
- ✅ LangChain + OpenAI 통합
- ✅ 세션 관리 시스템
- ✅ 태그 추출 기능
- ✅ 추천 생성 기능
- ✅ Flutter HTTP 통신 (`openai_service.dart`)
- ✅ 채팅 화면 응답 처리 (`make_todo_chat.dart`)
- ✅ UTF-8 한글 인코딩 처리
- ✅ CORS 설정
- ✅ 에러 처리
- ✅ API 문서 (Swagger UI)
- ✅ 실행 가이드 문서

