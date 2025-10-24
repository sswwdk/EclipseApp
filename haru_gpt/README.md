# Haru GPT API - 대화형 활동 추천 시스템

사용자와 대화하며 원하는 활동(카페, 음식점, 콘텐츠)에 대한 정보를 수집하고,
LLM을 활용해 키워드를 추출한 후 맞춤 추천을 제공하는 FastAPI 서버

## 📁 프로젝트 구조

```
haru_gpt/
├─ __init__.py          # 패키지 초기화
├─ main.py              # FastAPI 앱 & 엔드포인트만
├─ models.py            # Pydantic 모델들
├─ prompts.py           # ⭐ 모든 프롬프트 (수정 용이)
├─ database.py          # 용량 매칭, 추천 생성 등 상수
├─ utils.py             # 태그 추출, 추천 생성 함수
├─ handlers.py          # 대화 흐름 제어 핸들러
└─ config.py            # 환경 설정
```

## 🚀 실행 방법

### 1. 환경 설정

`.env` 파일 생성:
```
OPENAI_API_KEY=your_openai_api_key_here
```

### 2. 의존성 설치

```bash
pip install fastapi uvicorn python-dotenv langchain-openai langchain-core
```

### 3. 서버 실행

프로젝트 루트 디렉토리에서:
```bash
python run_haru_gpt_server.py
```

또는 직접 실행:
```bash
python -m uvicorn haru_gpt.main:app --host 0.0.0.0 --port 8000 --reload
```

## 📄 파일 설명

### config.py
- 환경 변수 로드 (OpenAI API Key)
- 한글 인코딩 설정

### models.py
- Pydantic 데이터 모델 정의
- `StartRequest`, `ChatRequest`, `StartResponse`, `ChatResponse`

### prompts.py
- 시스템 프롬프트
- 카테고리별 맞춤 프롬프트 템플릿
- 챗봇 응답 메시지 템플릿

### database.py
- 추천 데이터베이스 (태그 기반 매핑)
- 카테고리별 키워드 → 장소 매핑 테이블

### utils.py
- LLM 체인 초기화
- 태그 추출 함수 (`extract_tags_by_category`, `extract_tags`)
- 추천 생성 함수 (`generate_recommendations`, `parse_recommendations`)

### handlers.py
- 대화 흐름 제어 핸들러
- `handle_user_message`: 일반 메시지 처리
- `handle_user_action_response`: 버튼 액션 처리 (Next/More/Yes)
- `handle_next_category`: 다음 카테고리로 이동
- `handle_add_more_tags`: 추가 정보 입력
- `handle_modification_mode`: 수정 모드 처리

### main.py
- FastAPI 앱 생성 및 설정
- API 엔드포인트 정의
  - `GET /`: 헬스 체크
  - `POST /api/start`: 대화 시작
  - `POST /api/chat`: 채팅 메시지 처리
  - `GET /api/sessions`: 세션 목록 조회 (디버깅용)
  - `GET /api/sessions/{session_id}`: 세션 상세 조회 (디버깅용)

## 🔄 대화 흐름

1. **대화 시작** (`/api/start`)
   - 인원수 & 카테고리 선택
   - 세션 ID 발급
   - 첫 번째 카테고리 질문

2. **정보 수집** (`/api/chat`)
   - 사용자 메시지 입력
   - LLM으로 태그 추출
   - Next/More 버튼 표시

3. **다음 카테고리** (Next 선택)
   - 다음 카테고리 질문
   - 모든 카테고리 완료 시 → 결과 확인 단계

4. **추가 정보** (More 선택)
   - 같은 카테고리에 대한 추가 입력
   - 태그 병합

5. **결과 출력** (Yes 선택)
   - 모든 태그 기반 추천 생성
   - Flutter에 전달

## 📊 API 사용 예시

### 대화 시작
```json
POST /api/start
{
  "peopleCount": 2,
  "selectedCategories": ["카페", "음식점"]
}
```

### 채팅 메시지
```json
POST /api/chat
{
  "sessionId": "uuid-here",
  "message": "조용하고 와이파이 잘 되는 곳이 좋아"
}
```

## 🔧 커스터마이징

### 프롬프트 수정
`prompts.py` 파일에서 시스템 프롬프트와 카테고리별 프롬프트를 수정할 수 있습니다.

### 추천 데이터베이스 확장
`database.py` 파일에서 `RECOMMENDATION_DATABASE`에 새로운 키워드와 장소를 추가할 수 있습니다.

### 새로운 카테고리 추가
1. `database.py`: 새 카테고리 추가
2. `prompts.py`: 새 카테고리 프롬프트 추가
3. `utils.py`: 태그 추출 로직에 새 카테고리 반영

## 📝 라이선스
MIT License

