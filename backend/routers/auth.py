from fastapi import APIRouter, HTTPException
from sqlalchemy import text
from database import get_connection
import jwt
import datetime
from typing import Optional

router = APIRouter(prefix="/api/auth", tags=["auth"])

# JWT 설정 (실제 환경에서는 환경변수로 관리)
SECRET_KEY = "your-secret-key"
ALGORITHM = "HS256"

@router.post("")
async def issue_token(user_data: dict):
    """JWT 토큰 발급"""
    try:
        # 사용자 인증 로직 (실제로는 DB에서 확인)
        user_id = user_data.get("id")
        password = user_data.get("password")
        
        if not user_id or not password:
            raise HTTPException(status_code=400, detail="ID와 비밀번호가 필요합니다")
        
        # 사용자 정보 조회 (실제로는 DB에서 확인)
        with get_connection() as conn:
            query = text("SELECT id, username FROM users WHERE username = :username")
            result = conn.execute(query, {"username": user_id})
            user = result.fetchone()
            
            if not user:
                raise HTTPException(status_code=401, detail="사용자를 찾을 수 없습니다")
        
        # JWT 토큰 생성
        payload = {
            "user_id": user.id,
            "username": user.username,
            "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=24)
        }
        
        token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
        
        return {
            "success": True,
            "token": token,
            "user_id": user.id,
            "username": user.username
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"토큰 발급 오류: {str(e)}")

@router.delete("")
async def delete_token():
    """JWT 토큰 삭제 (클라이언트에서 처리)"""
    return {
        "success": True,
        "message": "토큰이 삭제되었습니다"
    }
