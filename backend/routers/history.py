from fastapi import APIRouter, HTTPException
from sqlalchemy import text
from database import get_connection

router = APIRouter(prefix="/api/history", tags=["history"])

@router.get("/me/{user_id}")
async def get_my_history(user_id: str):
    """내 히스토리 보기"""
    try:
        with get_connection() as conn:
            query = text("""
                SELECT h.*, c.name as category_name 
                FROM history h 
                LEFT JOIN category c ON h.category_id = c.id 
                WHERE h.user_id = :user_id 
                ORDER BY h.created_at DESC
            """)
            result = conn.execute(query, {"user_id": user_id})
            history = [dict(row) for row in result]
            
            return {
                "success": True,
                "history": history
            }
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"히스토리 조회 오류: {str(e)}")

@router.delete("/me/{user_id}")
async def delete_history(user_id: str, request_data: dict):
    """히스토리 삭제"""
    try:
        history_id = request_data.get("history_id")
        
        if not history_id:
            raise HTTPException(status_code=400, detail="히스토리 ID가 필요합니다")
        
        with get_connection() as conn:
            # 히스토리 소유자 확인
            check_query = text("SELECT user_id FROM history WHERE id = :history_id")
            result = conn.execute(check_query, {"history_id": history_id})
            history = result.fetchone()
            
            if not history:
                raise HTTPException(status_code=404, detail="히스토리를 찾을 수 없습니다")
            
            if history.user_id != user_id:
                raise HTTPException(status_code=403, detail="히스토리를 삭제할 권한이 없습니다")
            
            # 히스토리 삭제
            delete_query = text("DELETE FROM history WHERE id = :history_id")
            conn.execute(delete_query, {"history_id": history_id})
            
            return {
                "success": True,
                "message": "히스토리가 삭제되었습니다"
            }
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"히스토리 삭제 오류: {str(e)}")
