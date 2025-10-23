from fastapi import APIRouter, HTTPException
from sqlalchemy import text
from database import get_connection

router = APIRouter(prefix="/api/chat", tags=["chat"])

@router.get("/{user_id}/{other_id}")
async def get_chat(user_id: str, other_id: str):
    """채팅 보기"""
    try:
        with get_connection() as conn:
            query = text("""
                SELECT c.*, u1.username as sender_name, u2.username as receiver_name
                FROM chats c
                LEFT JOIN users u1 ON c.sender_id = u1.id
                LEFT JOIN users u2 ON c.receiver_id = u2.id
                WHERE (c.sender_id = :user_id AND c.receiver_id = :other_id)
                   OR (c.sender_id = :other_id AND c.receiver_id = :user_id)
                ORDER BY c.created_at ASC
            """)
            result = conn.execute(query, {"user_id": user_id, "other_id": other_id})
            chats = [dict(row) for row in result]
            
            return {
                "success": True,
                "chats": chats
            }
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"채팅 조회 오류: {str(e)}")

@router.get("/{user_id}")
async def get_chat_list(user_id: str):
    """채팅 목록"""
    try:
        with get_connection() as conn:
            query = text("""
                SELECT DISTINCT 
                    CASE 
                        WHEN c.sender_id = :user_id THEN c.receiver_id
                        ELSE c.sender_id
                    END as other_user_id,
                    u.username as other_username,
                    c.message as last_message,
                    c.created_at as last_message_time
                FROM chats c
                LEFT JOIN users u ON (
                    CASE 
                        WHEN c.sender_id = :user_id THEN c.receiver_id
                        ELSE c.sender_id
                    END = u.id
                )
                WHERE c.sender_id = :user_id OR c.receiver_id = :user_id
                ORDER BY c.created_at DESC
            """)
            result = conn.execute(query, {"user_id": user_id})
            chat_list = [dict(row) for row in result]
            
            return {
                "success": True,
                "chat_list": chat_list
            }
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"채팅 목록 조회 오류: {str(e)}")

@router.post("")
async def send_chat(chat_data: dict):
    """채팅 보내기"""
    try:
        sender_id = chat_data.get("sender_id")
        receiver_id = chat_data.get("receiver_id")
        message = chat_data.get("message")
        
        if not all([sender_id, receiver_id, message]):
            raise HTTPException(status_code=400, detail="필수 필드가 누락되었습니다")
        
        with get_connection() as conn:
            query = text("""
                INSERT INTO chats (sender_id, receiver_id, message) 
                VALUES (:sender_id, :receiver_id, :message)
            """)
            result = conn.execute(query, {
                "sender_id": sender_id,
                "receiver_id": receiver_id,
                "message": message
            })
            
            return {
                "success": True,
                "chat_id": result.lastrowid,
                "message": "채팅이 전송되었습니다"
            }
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"채팅 전송 오류: {str(e)}")
