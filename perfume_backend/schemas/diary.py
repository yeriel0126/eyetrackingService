from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class DiaryCreateRequest(BaseModel):
    user_id: str
    perfume_name: str
    emotion: Optional[str] = None
    memo: Optional[str] = None

class DiaryEntry(BaseModel):
    user_id: str
    perfume_name: str
    emotion: Optional[str] = None
    memo: Optional[str] = None
    created_at: datetime
