from pydantic import BaseModel, Field
from typing import Optional

class Review(BaseModel):
    username: str
    score: float = Field(..., ge=0.0, le=5.0)
    comment: Optional[str] = None

class ReviewResponse(Review):
    pass
