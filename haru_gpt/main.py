"""
FastAPI 앱 & 엔드포인트만
"""

import uuid
from typing import Dict
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from .models import StartRequest, ChatRequest, StartResponse, ChatResponse
from .prompts import RESPONSE_MESSAGES
from .handlers import (
    handle_user_message,
    handle_user_action_response,
    handle_modification_mode
)
from .utils import generate_recommendations, parse_recommendations


# FastAPI 앱 초기화
app = FastAPI(title="Haru GPT API", version="1.0.0")

# CORS 미들웨어 설정 - Flutter 앱에서 API 호출 가능하도록 허용
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: 프로덕션 배포 시 특정 도메인만 허용하도록 수정 필요
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =============================================================================
# 세션 저장소
# =============================================================================
# 현재는 메모리 기반 딕셔너리 사용 (서버 재시작 시 초기화됨)
# 프로덕션에서는 Redis나 데이터베이스 사용 권장
sessions: Dict[str, Dict] = {}


# =============================================================================
# API 엔드포인트
# =============================================================================

@app.get("/")
async def root():
    """
    헬스 체크 엔드포인트
    
    서버 상태 확인용. API 서버가 정상 동작 중인지 체크
    """
    return {
        "status": "ok",
        "message": "Haru GPT API is running!",
        "version": "1.0.0"
    }


@app.post("/api/start", response_model=StartResponse)
async def start_conversation(request: StartRequest):
    """
    대화 시작 엔드포인트
    
    새로운 대화 세션을 생성하고 첫 번째 카테고리에 대한 질문 반환.
    세션 ID를 발급받아 이후 모든 요청에서 사용
    
    Request Body:
        - peopleCount: 함께할 인원 수
        - selectedCategories: 선택한 활동 카테고리 리스트
    
    Response:
        - sessionId: 발급된 세션 ID
        - message: 첫 번째 질문 메시지
        - stage: 현재 대화 단계
        - progress: 진행 상태
    """
    try:
        # 세션 ID 생성
        session_id = str(uuid.uuid4())
        
        # 세션 데이터 초기화
        sessions[session_id] = {
            "peopleCount": request.peopleCount,
            "selectedCategories": request.selectedCategories,
            "collectedTags": {},  # 카테고리별 태그 저장
            "currentCategoryIndex": 0,  # 현재 질문 중인 카테고리
            "conversationHistory": [],  # 대화 히스토리
            "stage": "collecting_details",  # 현재 단계: collecting_details, confirming_results, completed
            "waitingForUserAction": False,  # 사용자 액션(Next/More 또는 Yes) 대기 중인지
            "lastUserMessage": "",  # 마지막 사용자 메시지
            "pendingTags": [],  # 대기 중인 태그들
            "modificationMode": False,  # 수정 모드인지
        }
        
        # 첫 번째 카테고리에 대한 질문 생성 (인원수와 카테고리 정보 포함)
        first_category = request.selectedCategories[0]
        categories_text = ', '.join(request.selectedCategories)
        
        first_message = RESPONSE_MESSAGES["start"]["first_message"].format(
            people_count=request.peopleCount,
            categories_text=categories_text,
            first_category=first_category
        )
        
        return StartResponse(
            status="success",
            sessionId=session_id,
            message=first_message,
            stage="collecting_details",
            progress={
                "current": 0,
                "total": len(request.selectedCategories)
            }
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"세션 시작 중 오류 발생: {str(e)}")


@app.post("/api/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    채팅 메시지 처리 엔드포인트
    
    사용자 메시지를 받아서:
    1. 일반 메시지 → LLM으로 태그 추출 후 Next/More 버튼 표시
    2. Next/More 응답 → 다음 카테고리로 이동 또는 추가 입력 요청
    3. 결과 확인 Yes 응답 → 최종 추천 생성
    
    Request Body:
        - sessionId: 세션 ID
        - message: 사용자 메시지
    
    Response:
        - message: 챗봇 응답
        - tags: 추출된 태그 (있는 경우)
        - showYesNoButtons: 버튼 표시 여부
        - recommendations: 최종 추천 (있는 경우)
    """
    try:
        # 세션 확인
        if request.sessionId not in sessions:
            raise HTTPException(status_code=404, detail="세션을 찾을 수 없습니다.")
        
        session = sessions[request.sessionId]
        
        # completed 상태 처리 - 대화 완료 후 추가 메시지
        if session.get("stage") == "completed":
            return ChatResponse(
                status="success",
                message="대화가 완료되었습니다. 새로운 대화를 시작하려면 처음부터 다시 시작해주세요.",
                stage="completed"
            )
        
        # modification_mode 처리
        if session.get("stage") == "modification_mode":
            return handle_modification_mode(session, request.message)
        
        # 사용자 액션(Next/More 또는 Yes) 응답 처리
        if session.get("waitingForUserAction", False):
            return handle_user_action_response(session, request.message)
        
        # 일반 메시지 처리 (태그 생성)
        return handle_user_message(session, request.message)
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"채팅 처리 중 오류 발생: {str(e)}")


@app.post("/api/confirm-results", response_model=ChatResponse)
async def confirm_results(request: ChatRequest):
    """
    결과 출력 확인 엔드포인트 (레거시)
    
    현재는 /api/chat에서 모두 처리하므로 사용하지 않음.
    하위 호환성 유지를 위해 남겨둠
    """
    try:
        if request.sessionId not in sessions:
            raise HTTPException(status_code=404, detail="세션을 찾을 수 없습니다.")
        
        session = sessions[request.sessionId]
        
        # Yes/No 응답 파싱
        is_yes = any(word in request.message.lower() for word in ["yes", "네", "넵", "예", "좋아", "좋아요", "그래", "맞아", "ㅇㅇ", "기기", "ㄱㄱ", "고고", "네네", "다음"])
        
        if is_yes:
            # 추천 생성
            recommendations_text = generate_recommendations(
                session["selectedCategories"],
                session["collectedTags"]
            )
            
            recommendations_dict = parse_recommendations(
                recommendations_text,
                session["selectedCategories"]
            )
            
            session["stage"] = "completed"
            
            return ChatResponse(
                status="success",
                message=RESPONSE_MESSAGES["start"]["final_result"],
                stage="completed",
                recommendations=recommendations_dict
            )
        else:
            # 명확하지 않은 응답
            return ChatResponse(
                status="success",
                message=RESPONSE_MESSAGES["start"]["unclear_result_response"],
                stage="confirming_results",
                showYesNoButtons=True,
                yesNoQuestion=RESPONSE_MESSAGES["buttons"]["result_question"]
            )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"결과 확인 처리 중 오류 발생: {str(e)}")


# =============================================================================
# 디버깅용 엔드포인트
# =============================================================================

@app.get("/api/sessions")
async def list_sessions():
    """
    현재 활성 세션 목록 조회
    
    개발 및 디버깅 용도. 메모리에 저장된 모든 세션 ID 확인 가능
    프로덕션 배포 시 제거하거나 인증 필요
    """
    return {
        "total": len(sessions),
        "sessions": list(sessions.keys())
    }


@app.get("/api/sessions/{session_id}")
async def get_session(session_id: str):
    """
    특정 세션 상세 정보 조회
    
    세션의 모든 데이터를 반환. 디버깅 시 대화 흐름 추적에 유용
    프로덕션 배포 시 제거하거나 인증 필요
    
    Path Parameter:
        session_id: 조회할 세션 ID
    """
    if session_id not in sessions:
        raise HTTPException(status_code=404, detail="세션을 찾을 수 없습니다.")
    return sessions[session_id]


# =============================================================================
# 서버 실행
# =============================================================================

if __name__ == "__main__":
    import uvicorn
    # 개발 서버 실행 (Hot Reload 활성화)
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)

