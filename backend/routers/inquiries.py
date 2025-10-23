from fastapi import APIRouter, HTTPException
from sqlalchemy import text
from database import get_connection

router = APIRouter(prefix="/api/inquiries", tags=["inquiries"])

@router.get("/{user_id}")
async def get_inquiries(user_id: str):
    """문의 목록"""
    try:
        with get_connection() as conn:
            query = text("""
                SELECT * FROM inquiries 
                WHERE user_id = :user_id 
                ORDER BY created_at DESC
            """)
            result = conn.execute(query, {"user_id": user_id})
            inquiries = [dict(row) for row in result]
            
            return {
                "success": True,
                "inquiries": inquiries
            }
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"문의 목록 조회 오류: {str(e)}")

@router.get("/detail/{inquiry_id}")
async def get_inquiry_detail(inquiry_id: str):
    """문의 상세"""
    try:
        with get_connection() as conn:
            query = text("""
                SELECT i.*, u.username 
                FROM inquiries i
                LEFT JOIN users u ON i.user_id = u.id
                WHERE i.id = :inquiry_id
            """)
            result = conn.execute(query, {"inquiry_id": inquiry_id})
            inquiry = result.fetchone()
            
            if not inquiry:
                raise HTTPException(status_code=404, detail="문의를 찾을 수 없습니다")
            
            return {
                "success": True,
                "inquiry": dict(inquiry)
            }
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"문의 상세 조회 오류: {str(e)}")

@router.post("")
async def create_inquiry(inquiry_data: dict):
    """문의하기"""
    try:
        user_id = inquiry_data.get("user_id")
        title = inquiry_data.get("title")
        content = inquiry_data.get("content")
        category = inquiry_data.get("category", "기타")
        
        if not all([user_id, title, content]):
            raise HTTPException(status_code=400, detail="필수 필드가 누락되었습니다")
        
        with get_connection() as conn:
            query = text("""
                INSERT INTO inquiries (user_id, title, content, category) 
                VALUES (:user_id, :title, :content, :category)
            """)
            result = conn.execute(query, {
                "user_id": user_id,
                "title": title,
                "content": content,
                "category": category
            })
            
            return {
                "success": True,
                "inquiry_id": result.lastrowid,
                "message": "문의가 접수되었습니다"
            }
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"문의 작성 오류: {str(e)}")
