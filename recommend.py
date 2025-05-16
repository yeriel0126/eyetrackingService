from pydantic import BaseModel
from typing import List, Literal

# 추천 요청 스키마
class RecommendRequest(BaseModel):
    gender: Literal["male", "female", "unisex"]
    emotion: Literal["energetic", "sensual", "romantic", "cozy"]
    season: Literal["spring", "summer", "fall", "winter"]
    time: Literal["day", "night"]

# 추천 응답 향수 항목
class RecommendedPerfume(BaseModel):
    id: int
    name: str
    brand: str
    image_url: str

# 추천 결과 응답 구조
class RecommendResponse(BaseModel):
    recommended_perfumes: List[RecommendedPerfume]
