from fastapi import APIRouter, HTTPException
from sqlalchemy import text
from database import get_connection

router = APIRouter(prefix="/api/notice", tags=["notice"])

@router.get("/all")
async def get_all_notices():
    """공지사항 목록"""
    try:
        with get_connection() as conn:
            query = text("""
                SELECT * FROM notices 
                ORDER BY created_at DESC
            """)
            result = conn.execute(query)
            notices = [dict(row) for row in result]
            
            return {
                "success": True,
                "notices": notices
            }
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"공지사항 목록 조회 오류: {str(e)}")

@router.get("/{post_id}")
async def get_notice_detail(post_id: str):
    """공지사항 상세"""
    try:
        with get_connection() as conn:
            query = text("""
                SELECT * FROM notices 
                WHERE id = :post_id
            """)
            result = conn.execute(query, {"post_id": post_id})
            notice = result.fetchone()
            
            if not notice:
                raise HTTPException(status_code=404, detail="공지사항을 찾을 수 없습니다")
            
            return {
                "success": True,
                "notice": dict(notice)
            }
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"공지사항 상세 조회 오류: {str(e)}")
