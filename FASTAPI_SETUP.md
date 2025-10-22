# FastAPI 서버 설정 및 실행 가이드

## 📦 필수 패키지 설치

FastAPI 서버를 실행하기 전에 Python 패키지를 설치해야 합니다.

```bash
pip install fastapi uvicorn python-dotenv langchain-openai langchain-core
```

## 🔑 환경 변수 설정

프로젝트 루트에 `.env` 파일을 생성하고 OpenAI API 키를 추가하세요:

```env
OPENAI_API_KEY=sk-your-api-key-here
```

## 🚀 서버 실행

### 방법 1: 직접 실행
```bash
cd C:\llm_test\llm_flutter\EclipseApp
python haru_gpt_api.py
```

### 방법 2: Uvicorn 명령어 사용
```bash
cd C:\llm_test\llm_flutter\EclipseApp
uvicorn haru_gpt_api:app --reload --host 0.0.0.0 --port 8000
```

서버가 정상 실행되면 다음과 같은 메시지가 표시됩니다:
```
==================================================
🚀 Haru GPT API 서버 시작!
📍 서버 주소: http://localhost:8000
📖 API 문서: http://localhost:8000/docs
==================================================
INFO:     Uvicorn running on http://0.0.0.0:8000
```

## 📖 API 문서 확인

서버 실행 후 브라우저에서 다음 주소로 접속하면 Swagger UI를 통해 API를 테스트할 수 있습니다:

```
http://localhost:8000/docs
```

## 🧪 API 테스트 (Postman/curl)

### 1. 대화 시작 (`/api/start`)

```bash
curl -X POST http://localhost:8000/api/start \
  -H "Content-Type: application/json" \
  -d "{\"peopleCount\": 2, \"selectedCategories\": [\"카페\", \"음식점\"]}"
```

**응답 예시:**
```json
{
  "status": "success",
  "sessionId": "abc-123-def-456",
  "message": "좋아! '카페' 활동에 대해 좀 더 자세히 말해줄 수 있을까? 어떤 걸 원해?",
  "stage": "collecting_details",
  "progress": {
    "current": 0,
    "total": 2
  }
}
```

### 2. 메시지 전송 (`/api/chat`)

```bash
curl -X POST http://localhost:8000/api/chat \
  -H "Content-Type: application/json" \
  -d "{\"sessionId\": \"abc-123-def-456\", \"message\": \"조용하고 와이파이 잘 되는 곳\"}"
```

**응답 예시 (다음 질문):**
```json
{
  "status": "success",
  "message": "그렇구나! 그럼 '음식점' 활동은 어떤 걸 원해?",
  "stage": "collecting_details",
  "tags": ["조용한", "와이파이", "공부하기 좋은"],
  "progress": {
    "current": 1,
    "total": 2
  }
}
```

**응답 예시 (추천 완료):**
```json
{
  "status": "success",
  "message": "짜잔! 오늘의 추천 리스트야!",
  "stage": "completed",
  "tags": ["분위기 좋은", "데이트", "프라이빗"],
  "recommendations": {
    "카페": ["조용한 북카페 '책과 쉼'", "스터디카페 '집중'", "루프탑 카페 '하늘정원'"],
    "음식점": ["이탈리안 레스토랑 '아모레'", "한식당 '정갈한 상'", "일식당 '오마카세 미즈'"]
  }
}
```

## 📱 Flutter 앱 연결

### Android 에뮬레이터
Flutter 앱에서 서버 주소를 다음과 같이 설정하세요 (이미 설정되어 있음):
```dart
static const String baseUrl = 'http://10.0.2.2:8000';
```

### iOS 시뮬레이터
`lib/services/openai_service.dart`에서 주소를 변경하세요:
```dart
static const String baseUrl = 'http://localhost:8000';
```

### 실제 기기
컴퓨터의 IP 주소를 확인하고 변경하세요:
```dart
static const String baseUrl = 'http://192.168.0.10:8000';  // 예시
```

**Windows에서 IP 확인:**
```bash
ipconfig
```

## 🔄 전체 테스트 순서

1. **서버 실행**
   ```bash
   python haru_gpt_api.py
   ```

2. **Flutter 앱 실행**
   ```bash
   flutter run
   ```

3. **앱에서 테스트**
   - 인원 수 선택 (예: 2명)
   - 카테고리 선택 (예: 카페, 음식점)
   - 채팅 화면에서 대화 진행
   - 각 카테고리에 대한 질문에 답변
   - 최종 추천 결과 확인

## ⚠️ 문제 해결

### 1. 서버 연결 실패
**증상:** "서버 연결에 실패했습니다" 메시지 표시

**해결 방법:**
- FastAPI 서버가 실행 중인지 확인
- 방화벽에서 8000 포트 허용
- 에뮬레이터/실기기에 맞게 baseUrl 수정

### 2. OpenAI API 오류
**증상:** "채팅 처리 중 오류 발생" 메시지

**해결 방법:**
- `.env` 파일에 올바른 API 키가 설정되었는지 확인
- OpenAI API 크레딧이 있는지 확인

### 3. CORS 오류
**증상:** 브라우저/앱에서 CORS 정책 오류

**해결 방법:**
- `haru_gpt_api.py`의 CORS 설정 확인
- 이미 `allow_origins=["*"]`로 설정되어 있음

## 📊 디버깅 엔드포인트

### 활성 세션 목록 조회
```bash
curl http://localhost:8000/api/sessions
```

### 특정 세션 정보 조회
```bash
curl http://localhost:8000/api/sessions/{sessionId}
```

## 🎯 주요 변경사항

1. **haru_gpt_api.py** (새로 생성)
   - FastAPI 서버 구현
   - LangChain 기반 대화 처리
   - 세션 관리 기능

2. **lib/services/openai_service.dart** (수정)
   - 더미 응답 → FastAPI 호출로 변경
   - HTTP 통신 구현

3. **lib/make_todo/make_todo_chat.dart** (수정)
   - 초기화 로직 변경 (FastAPI /api/start 호출)
   - 응답 처리 로직 변경 (추천 결과 포맷팅)

