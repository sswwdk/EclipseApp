from fastapi import APIRouter, HTTPException
from sqlalchemy import text
from database import get_connection

router = APIRouter(prefix="/api/like", tags=["like"])

@router.get("/{user_id}")
async def get_likes(user_id: str):
    """찜 보기"""
    try:
        with get_connection() as conn:
            query = text("""
                SELECT l.*, c.name as store_name, c.address, c.phone, c.rating
                FROM likes l
                LEFT JOIN category c ON l.store_id = c.id
                WHERE l.user_id = :user_id
                ORDER BY l.created_at DESC
            """)
            result = conn.execute(query, {"user_id": user_id})
            likes = [dict(row) for row in result]
            
            return {
                "success": True,
                "likes": likes
            }
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"찜 목록 조회 오류: {str(e)}")

@router.delete("/{store_id}")
async def unlike_store(store_id: str, request_data: dict):
    """찜 취소"""
    try:
        user_id = request_data.get("user_id")
        
        if not user_id:
            raise HTTPException(status_code=400, detail="사용자 ID가 필요합니다")
        
        with get_connection() as conn:
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
