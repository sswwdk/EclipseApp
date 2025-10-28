# 🌳 Haru GPT API 프로젝트 구조

## 📁 전체 디렉토리 트리

```
EclipseApp/
│
├── haru_gpt/                          #  메인 API 모듈 (신규)
│   ├── __init__.py                    # 패키지 초기화 파일
│   ├── config.py                      #  환경 설정
│   ├── models.py                      #  Pydantic 데이터 모델
│   ├── prompts.py                     #  LLM 프롬프트 템플릿 (수정 용이)
│   ├── database.py                    #  추천 데이터베이스 상수
│   ├── utils.py                       #  유틸리티 함수 (태그 추출, 추천 생성)
│   ├── handlers.py                    #  대화 흐름 제어 핸들러
│   ├── main.py                        #  FastAPI 앱 & 엔드포인트
│   └── README.md                      #  상세 사용 설명서
│
├── run_haru_gpt_server.py             # ▶ 서버 실행 스크립트
│
├── haru_gpt_api.py                    #  레거시 파일 (더 이상 사용 안 함)
│
├── backend/                           # 기존 백엔드 (별도)
│   ├── main.py
│   ├── database.py
│   ├── models/
│   └── routers/
│
├── lib/                               # Flutter 앱
├── pubspec.yaml                       # Flutter 설정
└── .env                               # 환경 변수 (OPENAI_API_KEY)
```

---

## 📂 haru_gpt/ 모듈 상세 구조

```
haru_gpt/
│
├── 📄 __init__.py                     (7줄)
│   └── 패키지 초기화 및 버전 정보
│
├── 🔧 config.py                       (16줄)
│   ├── 환경 변수 로드 (dotenv)
│   ├── OpenAI API Key 설정
│   └── 한글 인코딩 설정 (Windows 호환)
│
├── 📝 models.py                       (43줄)
│   ├── StartRequest          → 대화 시작 요청
│   ├── ChatRequest           → 채팅 메시지 요청
│   ├── StartResponse         → 대화 시작 응답
│   └── ChatResponse          → 채팅 응답 (태그, 추천 포함)
│
├── ⭐ prompts.py                      (230줄)
│   ├── SYSTEM_PROMPT                 → 기본 시스템 프롬프트
│   ├── get_category_prompt()         → 카테고리별 맞춤 프롬프트
│   │   ├── 카페 프롬프트
│   │   ├── 음식점 프롬프트
│   │   └── 콘텐츠 프롬프트
│   ├── get_general_tagging_prompt()  → 범용 태그 추출 프롬프트
│   └── RESPONSE_MESSAGES             → 챗봇 응답 메시지 템플릿
│
├── 💾 database.py                     (60줄)
│   └── RECOMMENDATION_DATABASE       → 태그 기반 추천 매핑 테이블
│       ├── 카페 → 키워드별 추천 장소
│       ├── 음식점 → 키워드별 추천 장소
│       └── 콘텐츠 → 키워드별 추천 장소
│
├── 🛠️ utils.py                        (220줄)
│   ├── setup_chain()                            → LangChain LLM 체인 초기화
│   ├── extract_tags_by_category()               → 카테고리별 태그 추출 (LLM)
│   ├── extract_tags()                           → 범용 태그 추출
│   ├── generate_recommendations_by_category()   → 카테고리별 추천 생성
│   ├── generate_recommendations()               → 전체 추천 생성
│   └── parse_recommendations()                  → 추천 결과 파싱
│
├── 🎮 handlers.py                     (240줄)
│   ├── handle_user_message()           → 사용자 메시지 처리 & 태그 생성
│   ├── handle_user_action_response()   → 버튼 액션 처리 (Next/More/Yes)
│   ├── handle_next_category()          → 다음 카테고리로 이동
│   ├── handle_add_more_tags()          → 현재 카테고리 추가 입력
│   └── handle_modification_mode()      → 수정 모드 (미사용)
│
├── 🚀 main.py                         (230줄)
│   ├── FastAPI 앱 생성 및 CORS 설정
│   ├── sessions = {}                   → 세션 저장소 (메모리)
│   │
│   ├── 📍 엔드포인트:
│   │   ├── GET  /                      → 헬스 체크
│   │   ├── POST /api/start             → 대화 시작 (세션 생성)
│   │   ├── POST /api/chat              → 채팅 메시지 처리
│   │   ├── POST /api/confirm-results   → 결과 확인 (레거시)
│   │   ├── GET  /api/sessions          → 세션 목록 (디버깅)
│   │   └── GET  /api/sessions/{id}     → 세션 상세 (디버깅)
│   │
│   └── uvicorn 서버 실행
│
└── 📖 README.md                       (148줄)
    └── 전체 사용 설명서 및 API 문서
```

---

## 🔄 대화 흐름 (Flow Diagram)

```
[Flutter 앱]
    │
    ├─ POST /api/start
    │  └─→ [main.py: start_conversation()]
    │      └─→ 세션 생성 & 첫 질문 반환
    │
    ├─ POST /api/chat (사용자 메시지)
    │  └─→ [main.py: chat()]
    │      │
    │      ├─→ [handlers.py: handle_user_message()]
    │      │   └─→ [utils.py: extract_tags_by_category()]
    │      │       └─→ [utils.py: chain.invoke()] → LLM 호출
    │      │           └─→ 태그 추출 & Next/More 버튼 표시
    │      │
    │      ├─→ [handlers.py: handle_user_action_response()]
    │      │   │
    │      │   ├─ Next 선택
    │      │   │  └─→ [handlers.py: handle_next_category()]
    │      │   │      └─→ 다음 카테고리 질문
    │      │   │
    │      │   ├─ More 선택
    │      │   │  └─→ [handlers.py: handle_add_more_tags()]
    │      │   │      └─→ 추가 입력 요청
    │      │   │
    │      │   └─ Yes 선택 (모든 카테고리 완료 후)
    │      │      └─→ [utils.py: generate_recommendations()]
    │      │          └─→ [utils.py: parse_recommendations()]
    │      │              └─→ 최종 추천 결과 반환
    │      │
    │      └─→ ChatResponse 반환
    │
    └─ [Flutter 앱에 결과 표시]
```

---

## 🎯 모듈 간 의존성

```
main.py
  ├─ import models.py       (데이터 모델)
  ├─ import prompts.py      (응답 메시지)
  ├─ import handlers.py     (대화 흐름)
  └─ import utils.py        (추천 생성)

handlers.py
  ├─ import models.py       (응답 모델)
  ├─ import prompts.py      (메시지 템플릿)
  └─ import utils.py        (태그 추출, 추천)

utils.py
  ├─ import config.py       (API Key)
  ├─ import prompts.py      (LLM 프롬프트)
  └─ import database.py     (추천 DB)

config.py
  └─ (독립적, 최상위)
```

---

## 📊 코드 라인 수 비교

| 구분 | 기존 | 신규 | 비고 |
|------|------|------|------|
| **전체** | 1073줄 | 1073줄 | 동일한 기능 |
| **파일 수** | 1개 | 8개 | 모듈화 |
| **가독성** | ⭐⭐ | ⭐⭐⭐⭐⭐ | 대폭 개선 |
| **유지보수** | 어려움 | 쉬움 | 기능별 분리 |
| **확장성** | 낮음 | 높음 | 새 기능 추가 용이 |

---

## 🚀 실행 방법

### 방법 1: 실행 스크립트 사용 (권장)
```bash
python run_haru_gpt_server.py
```

### 방법 2: 직접 실행
```bash
python -m uvicorn haru_gpt.main:app --host 0.0.0.0 --port 8000 --reload
```

### 방법 3: 모듈 내부에서 실행
```bash
cd haru_gpt
python main.py
```

---

## 🔐 환경 변수 설정

프로젝트 루트에 `.env` 파일 생성:
```env
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxxxxxx
```

---

## 📝 주요 API 엔드포인트

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/` | 헬스 체크 |
| POST | `/api/start` | 대화 시작 (세션 생성) |
| POST | `/api/chat` | 채팅 메시지 처리 |
| GET | `/api/sessions` | 활성 세션 목록 (디버깅) |
| GET | `/api/sessions/{id}` | 세션 상세 정보 (디버깅) |

---

## ✨ 주요 개선 사항

1. ✅ **모듈화**: 기능별로 파일 분리
2. ✅ **유지보수성**: 프롬프트 수정이 용이함 (`prompts.py`)
3. ✅ **확장성**: 새로운 카테고리 추가 쉬움
4. ✅ **가독성**: 코드 구조가 명확함
5. ✅ **재사용성**: 각 모듈을 독립적으로 사용 가능
6. ✅ **테스트 용이성**: 각 함수를 개별적으로 테스트 가능

---

## 📌 담당자 참고 사항

- **레거시 파일**: `haru_gpt_api.py`는 더 이상 사용하지 않음 (삭제 가능)
- **세션 관리**: 현재 메모리 기반 → 프로덕션에서는 Redis 권장
- **보안**: CORS 설정이 `allow_origins=["*"]`로 되어 있음 → 프로덕션에서는 특정 도메인만 허용 필요
- **디버깅 엔드포인트**: `/api/sessions/*` 엔드포인트는 프로덕션에서 제거 또는 인증 추가 필요
- **에러 처리**: 모든 엔드포인트에 try-except 구문으로 에러 처리 구현됨

---

📅 **생성일**: 2025-10-24  
📝 **버전**: 1.0.0  
👤 **작성자**: Haru GPT API Team

