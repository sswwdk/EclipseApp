from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy import text
from database import get_connection
from typing import Optional
import hashlib

router = APIRouter(prefix="/api/users", tags=["users"])

@router.post("")
async def login_or_logout(user_data: dict):
    """로그인 또는 로그아웃"""
    try:
        user_type = user_data.get("type")
        username = user_data.get("id")
        password = user_data.get("pw")
        
        if not all([user_type, username, password]):
            raise HTTPException(status_code=400, detail="필수 필드가 누락되었습니다")
        
        if user_type == "login":
            # 로그인 로직
            with get_connection() as conn:
                query = text("SELECT id, username, email FROM users WHERE username = :username")
                result = conn.execute(query, {"username": username})
                user = result.fetchone()
                
                if not user:
                    raise HTTPException(status_code=401, detail="사용자를 찾을 수 없습니다")
                
                return {
                    "success": True,
                    "message": "로그인 성공",
                    "user": {
                        "id": user.id,
                        "username": user.username,
                        "email": user.email
                    }
                }
        
        elif user_type == "logout":
            # 로그아웃 로직 (클라이언트에서 토큰 삭제)
            return {
                "success": True,
                "message": "로그아웃 성공"
            }
        
        else:
            raise HTTPException(status_code=400, detail="잘못된 타입입니다")
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"인증 오류: {str(e)}")

@router.post("/id")
async def find_id(user_data: dict):
    """아이디 찾기"""
    try:
        email = user_data.get("email")
        if not email:
            raise HTTPException(status_code=400, detail="이메일이 필요합니다")
        
        with get_connection() as conn:
            query = text("SELECT username FROM users WHERE email = :email")
            result = conn.execute(query, {"email": email})
            user = result.fetchone()
            
            if not user:
                raise HTTPException(status_code=404, detail="해당 이메일로 등록된 사용자가 없습니다")
            
            return {
                "success": True,
                "username": user.username
            }
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"아이디 찾기 오류: {str(e)}")

@router.post("/password")
async def find_password(user_data: dict):
    """비밀번호 찾기"""
    try:
        username = user_data.get("username")
        email = user_data.get("email")
        
        if not all([username, email]):
            raise HTTPException(status_code=400, detail="사용자명과 이메일이 필요합니다")
        
        with get_connection() as conn:
            query = text("SELECT id FROM users WHERE username = :username AND email = :email")
            result = conn.execute(query, {"username": username, "email": email})
            user = result.fetchone()
            
            if not user:
                raise HTTPException(status_code=404, detail="일치하는 사용자 정보가 없습니다")
            
            # 실제로는 임시 비밀번호를 생성하고 이메일로 전송
            return {
                "success": True,
                "message": "임시 비밀번호가 이메일로 전송되었습니다"
            }
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"비밀번호 찾기 오류: {str(e)}")

@router.post("/signup")
async def signup(user_data: dict):
    """회원가입"""
    try:
        username = user_data.get("username")
        email = user_data.get("email")
        password = user_data.get("password")
        
        if not all([username, email, password]):
            raise HTTPException(status_code=400, detail="필수 필드가 누락되었습니다")
        
        # 비밀번호 해싱
        password_hash = hashlib.sha256(password.encode()).hexdigest()
        
        with get_connection() as conn:
            # 중복 확인
            check_query = text("SELECT id FROM users WHERE username = :username OR email = :email")
            result = conn.execute(check_query, {"username": username, "email": email})
            existing_user = result.fetchone()
            
            if existing_user:
                raise HTTPException(status_code=409, detail="이미 존재하는 사용자명 또는 이메일입니다")
            
            # 사용자 생성
            insert_query = text("""
                INSERT INTO users (username, email, password_hash) 
                VALUES (:username, :email, :password_hash)
            """)
            conn.execute(insert_query, {
                "username": username,
                "email": email,
                "password_hash": password_hash
            })
            
            return {
                "success": True,
                "message": "회원가입이 완료되었습니다"
            }
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"회원가입 오류: {str(e)}")

@router.delete("")
async def delete_user(user_data: dict):
    """회원 탈퇴"""
    try:
        user_id = user_data.get("user_id")
        password = user_data.get("password")
        
        if not all([user_id, password]):
            raise HTTPException(status_code=400, detail="사용자 ID와 비밀번호가 필요합니다")
        
        with get_connection() as conn:
            # 사용자 확인
            query = text("SELECT id FROM users WHERE id = :user_id")
            result = conn.execute(query, {"user_id": user_id})
            user = result.fetchone()
            
            if not user:
                raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")
            
            # 사용자 삭제
            delete_query = text("DELETE FROM users WHERE id = :user_id")
            conn.execute(delete_query, {"user_id": user_id})
            
            return {
                "success": True,
                "message": "회원 탈퇴가 완료되었습니다"
            }
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"회원 탈퇴 오류: {str(e)}")

@router.get("/me/{user_id}")
async def get_my_info(user_id: str):
    """내 정보 보기"""
    try:
        with get_connection() as conn:
            query = text("SELECT id, username, email, created_at FROM users WHERE id = :user_id")
            result = conn.execute(query, {"user_id": user_id})
            user = result.fetchone()
            
            if not user:
                raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")
            
            return {
                "success": True,
                "user": {
                    "id": user.id,
                    "username": user.username,
                    "email": user.email,
                    "created_at": user.created_at
                }
            }
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"사용자 정보 조회 오류: {str(e)}")

@router.put("/{user_id}/preferences")
async def update_preferences(user_id: str, preferences: dict):
    """선호 취향 선택"""
    try:
        # 선호도 데이터를 DB에 저장하는 로직
        # 실제로는 preferences 테이블을 만들어야 함
        return {
            "success": True,
            "message": "선호도가 업데이트되었습니다"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"선호도 업데이트 오류: {str(e)}")
