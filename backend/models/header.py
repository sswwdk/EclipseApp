from pydantic import BaseModel
from typing import Optional

class JsonHeader(BaseModel):
    content: str
    jwt: Optional[str] = None
