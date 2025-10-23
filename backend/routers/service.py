from fastapi import APIRouter, HTTPException
from sqlalchemy import text
from database import get_connection
from typing import Optional

router = APIRouter(prefix="/api/service", tags=["service"])

@router.post("/start")
async def start_main_logic(request_data: dict):
    """메인 로직 시작 (하루랑 채팅 시작 시)"""
    try:
        num_people = request_data.get("인원수")
        category = request_data.get("카테고리")
        
        if not all([num_people, category]):
            raise HTTPException(status_code=400, detail="인원수와 카테고리가 필요합니다")
        
        # 메인 로직 처리
        # 실제로는 AI 서비스와 연동하여 추천 로직 실행
        
        return {
            "success": True,
            "status": "STARTED",
            "message": "메인 로직이 시작되었습니다",
            "data": {
                "num_people": num_people,
                "category": category
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"메인 로직 시작 오류: {str(e)}")

@router.post("/chat")
async def chat_with_haru(request_data: dict):
    """하루랑 채팅 (사용자의 프롬프트 받기)"""
    try:
        user_prompt = request_data.get("prompt")
        user_id = request_data.get("user_id")
        
        if not user_prompt:
            raise HTTPException(status_code=400, detail="프롬프트가 필요합니다")
        
        # AI 서비스와 연동하여 응답 생성
        # 실제로는 OpenAI API 등을 사용
        
        return {
            "success": True,
            "response": f"하루가 응답: {user_prompt}에 대한 답변입니다",
            "user_id": user_id
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"채팅 오류: {str(e)}")

@router.post("/community")
async def share_to_community(request_data: dict):
    """커뮤니티 공유"""
    try:
        content = request_data.get("content")
        user_id = request_data.get("user_id")
        
        if not content:
            raise HTTPException(status_code=400, detail="공유할 내용이 필요합니다")
        
        # 커뮤니티에 공유하는 로직
        return {
            "success": True,
            "message": "커뮤니티에 공유되었습니다"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"커뮤니티 공유 오류: {str(e)}")

@router.post("/person")
async def share_with_friend(request_data: dict):
    """친구에게 공유"""
    try:
        content = request_data.get("content")
        friend_id = request_data.get("friend_id")
        
        if not all([content, friend_id]):
            raise HTTPException(status_code=400, detail="공유할 내용과 친구 ID가 필요합니다")
        
        # 친구에게 공유하는 로직 (링크 생성)
        share_link = f"https://app.whattodo.com/share/{friend_id}"
        
        return {
            "success": True,
            "link": share_link,
            "message": "친구에게 공유 링크가 생성되었습니다"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"친구 공유 오류: {str(e)}")

@router.post("/like/{store_id}")
async def like_store(store_id: str, request_data: dict):
    """찜하기"""
    try:
        user_id = request_data.get("user_id")
        
        if not user_id:
            raise HTTPException(status_code=400, detail="사용자 ID가 필요합니다")
        
        with get_connection() as conn:
            # 찜 목록에 추가
            query = text("""
                INSERT INTO likes (user_id, store_id) 
                VALUES (:user_id, :store_id)
                ON DUPLICATE KEY UPDATE created_at = CURRENT_TIMESTAMP
            """)
            conn.execute(query, {"user_id": user_id, "store_id": store_id})
            
            return {
                "success": True,
                "status": "LIKED",
                "message": "찜 목록에 추가되었습니다"
            }
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"찜하기 오류: {str(e)}")

@router.delete("/like/{store_id}")
async def unlike_store(store_id: str, request_data: dict):
    """찜 취소"""
    try:
        user_id = request_data.get("user_id")
        
        if not user_id:
            raise HTTPException(status_code=400, detail="사용자 ID가 필요합니다")
        
        with get_connection() as conn:
            # 찜 목록에서 제거
            query = text("DELETE FROM likes WHERE user_id = :user_id AND store_id = :store_id")
            result = conn.execute(query, {"user_id": user_id, "store_id": store_id})
            
            if result.rowcount == 0:
                raise HTTPException(status_code=404, detail="찜 목록에 없는 항목입니다")
            
            return {
                "success": True,
                "status": "UNLIKED",
                "message": "찜이 취소되었습니다"
            }
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"찜 취소 오류: {str(e)}")

@router.post("/templates")
async def select_template(request_data: dict):
    """템플릿 선택"""
    try:
        template_id = request_data.get("template_id")
        user_id = request_data.get("user_id")
        
        if not template_id:
            raise HTTPException(status_code=400, detail="템플릿 ID가 필요합니다")
        
        # 템플릿 선택 로직
        # 실제로는 템플릿 데이터를 반환
        
        return {
            "success": True,
            "schedule": {
                "template_id": template_id,
                "schedule_data": "일정표 데이터"
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"템플릿 선택 오류: {str(e)}")

@router.get("/templates/{template_id}")
async def get_template(template_id: str):
    """템플릿 조회"""
    try:
        # 템플릿 데이터 조회
        return {
            "success": True,
            "template": {
                "id": template_id,
                "name": "템플릿 이름",
                "data": "템플릿 데이터"
            }
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"템플릿 조회 오류: {str(e)}")

@router.get("/main")
async def get_main_data():
    """메인 페이지 데이터 조회 (category 테이블에서)"""
    try:
        with get_connection() as conn:
            query = text("SELECT * FROM category ORDER BY last_crawl DESC")
            result = conn.execute(query)
            data = [dict(row) for row in result]
        return {"success": True, "data": data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

@router.get("/restaurants")
async def get_restaurants():
    """모든 레스토랑 목록 조회 (category 테이블에서)"""
    try:
        with get_connection() as conn:
            query = text("SELECT * FROM category ORDER BY last_crawl DESC")
            result = conn.execute(query)
            data = [dict(row) for row in result]
        return {"success": True, "data": data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

@router.get("/restaurants/{restaurant_id}")
async def get_restaurant(restaurant_id: str):
    """특정 레스토랑 상세 정보 조회 (category 테이블에서)"""
    try:
        with get_connection() as conn:
            query = text("SELECT * FROM category WHERE id = :id")
            result = conn.execute(query, {"id": restaurant_id})
            row = result.fetchone()

            if not row:
                raise HTTPException(status_code=404, detail="레스토랑을 찾을 수 없습니다")

            data = dict(row)
        return {"success": True, "data": data}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")
