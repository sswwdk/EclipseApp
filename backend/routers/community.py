from fastapi import APIRouter, HTTPException
from sqlalchemy import text
from database import get_connection
from typing import Optional

router = APIRouter(prefix="/api/community", tags=["community"])

@router.get("")
async def get_all_posts():
    """모든 글 조회 (커뮤니티 메인 접속)"""
    try:
        with get_connection() as conn:
            query = text("""
                SELECT p.*, u.username 
                FROM posts p 
                LEFT JOIN users u ON p.user_id = u.id 
                ORDER BY p.created_at DESC
            """)
            result = conn.execute(query)
            posts = [dict(row) for row in result]
            
            return {
                "success": True,
                "posts": posts
            }
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"글 목록 조회 오류: {str(e)}")

@router.get("/post/{query}")
async def get_specific_post(query: str):
    """특정 글 조회"""
    try:
        with get_connection() as conn:
            query_sql = text("""
                SELECT p.*, u.username 
                FROM posts p 
                LEFT JOIN users u ON p.user_id = u.id 
                WHERE p.id = :post_id OR p.title LIKE :search_query
            """)
            result = conn.execute(query_sql, {
                "post_id": query,
                "search_query": f"%{query}%"
            })
            post = result.fetchone()
            
            if not post:
                raise HTTPException(status_code=404, detail="글을 찾을 수 없습니다")
            
            return {
                "success": True,
                "post": dict(post)
            }
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"글 조회 오류: {str(e)}")

@router.post("/post")
async def create_post(post_data: dict):
    """글 작성"""
    try:
        user_id = post_data.get("user_id")
        title = post_data.get("title")
        content = post_data.get("content")
        
        if not all([user_id, title, content]):
            raise HTTPException(status_code=400, detail="필수 필드가 누락되었습니다")
        
        with get_connection() as conn:
            query = text("""
                INSERT INTO posts (user_id, title, content) 
                VALUES (:user_id, :title, :content)
            """)
            result = conn.execute(query, {
                "user_id": user_id,
                "title": title,
                "content": content
            })
            
            return {
                "success": True,
                "post_id": result.lastrowid,
                "message": "글이 작성되었습니다"
            }
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"글 작성 오류: {str(e)}")

@router.delete("/post/{post_id}")
async def delete_post(post_id: str, request_data: dict):
    """글 삭제"""
    try:
        user_id = request_data.get("user_id")
        
        if not user_id:
            raise HTTPException(status_code=400, detail="사용자 ID가 필요합니다")
        
        with get_connection() as conn:
            # 글 작성자 확인
            check_query = text("SELECT user_id FROM posts WHERE id = :post_id")
            result = conn.execute(check_query, {"post_id": post_id})
            post = result.fetchone()
            
            if not post:
                raise HTTPException(status_code=404, detail="글을 찾을 수 없습니다")
            
            if post.user_id != user_id:
                raise HTTPException(status_code=403, detail="글을 삭제할 권한이 없습니다")
            
            # 글 삭제
            delete_query = text("DELETE FROM posts WHERE id = :post_id")
            conn.execute(delete_query, {"post_id": post_id})
            
            return {
                "success": True,
                "message": "글이 삭제되었습니다"
            }
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"글 삭제 오류: {str(e)}")

@router.get("/post/me")
async def get_my_posts(user_id: str):
    """내글 조회"""
    try:
        with get_connection() as conn:
            query = text("""
                SELECT * FROM posts 
                WHERE user_id = :user_id 
                ORDER BY created_at DESC
            """)
            result = conn.execute(query, {"user_id": user_id})
            posts = [dict(row) for row in result]
            
            return {
                "success": True,
                "posts": posts
            }
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"내글 조회 오류: {str(e)}")

@router.get("/{post_id}/comment")
async def get_comments(post_id: str):
    """댓글 조회"""
    try:
        with get_connection() as conn:
            query = text("""
                SELECT c.*, u.username 
                FROM comments c 
                LEFT JOIN users u ON c.user_id = u.id 
                WHERE c.post_id = :post_id 
                ORDER BY c.created_at ASC
            """)
            result = conn.execute(query, {"post_id": post_id})
            comments = [dict(row) for row in result]
            
            return {
                "success": True,
                "comments": comments
            }
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"댓글 조회 오류: {str(e)}")

@router.post("/{post_id}/comment")
async def create_comment(post_id: str, comment_data: dict):
    """댓글 작성"""
    try:
        user_id = comment_data.get("user_id")
        content = comment_data.get("content")
        
        if not all([user_id, content]):
            raise HTTPException(status_code=400, detail="필수 필드가 누락되었습니다")
        
        with get_connection() as conn:
            query = text("""
                INSERT INTO comments (post_id, user_id, content) 
                VALUES (:post_id, :user_id, :content)
            """)
            result = conn.execute(query, {
                "post_id": post_id,
                "user_id": user_id,
                "content": content
            })
            
            return {
                "success": True,
                "comment_id": result.lastrowid,
                "message": "댓글이 작성되었습니다"
            }
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"댓글 작성 오류: {str(e)}")

@router.delete("/{post_id}/comment")
async def delete_comment(post_id: str, comment_data: dict):
    """댓글 삭제"""
    try:
        user_id = comment_data.get("user_id")
        comment_id = comment_data.get("comment_id")
        
        if not all([user_id, comment_id]):
            raise HTTPException(status_code=400, detail="필수 필드가 누락되었습니다")
        
        with get_connection() as conn:
            # 댓글 작성자 확인
            check_query = text("SELECT user_id FROM comments WHERE id = :comment_id")
            result = conn.execute(check_query, {"comment_id": comment_id})
            comment = result.fetchone()
            
            if not comment:
                raise HTTPException(status_code=404, detail="댓글을 찾을 수 없습니다")
            
            if comment.user_id != user_id:
                raise HTTPException(status_code=403, detail="댓글을 삭제할 권한이 없습니다")
            
            # 댓글 삭제
            delete_query = text("DELETE FROM comments WHERE id = :comment_id")
            conn.execute(delete_query, {"comment_id": comment_id})
            
            return {
                "success": True,
                "message": "댓글이 삭제되었습니다"
            }
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"댓글 삭제 오류: {str(e)}")

@router.get("/comment/me")
async def get_my_comments(user_id: str):
    """내 댓글 조회"""
    try:
        with get_connection() as conn:
            query = text("""
                SELECT c.*, p.title as post_title 
                FROM comments c 
                LEFT JOIN posts p ON c.post_id = p.id 
                WHERE c.user_id = :user_id 
                ORDER BY c.created_at DESC
            """)
            result = conn.execute(query, {"user_id": user_id})
            comments = [dict(row) for row in result]
            
            return {
                "success": True,
                "comments": comments
            }
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"내 댓글 조회 오류: {str(e)}")

@router.post("/report")
async def report_content(report_data: dict):
    """신고하기"""
    try:
        user_id = report_data.get("user_id")
        content_type = report_data.get("content_type")  # post, comment
        content_id = report_data.get("content_id")
        reason = report_data.get("reason")
        
        if not all([user_id, content_type, content_id, reason]):
            raise HTTPException(status_code=400, detail="필수 필드가 누락되었습니다")
        
        with get_connection() as conn:
            query = text("""
                INSERT INTO reports (user_id, content_type, content_id, reason) 
                VALUES (:user_id, :content_type, :content_id, :reason)
            """)
            conn.execute(query, {
                "user_id": user_id,
                "content_type": content_type,
                "content_id": content_id,
                "reason": reason
            })
            
            return {
                "success": True,
                "message": "신고가 접수되었습니다"
            }
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"신고 오류: {str(e)}")

@router.get("/report")
async def get_report_history(user_id: str):
    """신고 내역 조회"""
    try:
        with get_connection() as conn:
            query = text("""
                SELECT * FROM reports 
                WHERE user_id = :user_id 
                ORDER BY created_at DESC
            """)
            result = conn.execute(query, {"user_id": user_id})
            reports = [dict(row) for row in result]
            
            return {
                "success": True,
                "reports": reports
            }
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"신고 내역 조회 오류: {str(e)}")
