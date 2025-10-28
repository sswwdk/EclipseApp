"""
환경 설정
"""

import os
import sys
import io
from dotenv import load_dotenv

# 환경 설정
load_dotenv()
openai_api_key = os.getenv("OPENAI_API_KEY")

# 한글 인코딩 설정 (Windows 환경에서 한글 출력 문제 해결)
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

