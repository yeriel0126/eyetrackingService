from pydantic import BaseModel, Field
from typing import List

class SimpleCourseRecommendRequest(BaseModel):
    preferred_perfumes: List[str] = Field(..., example=["탐다오", "상탈 33"])
    latitude: float = Field(..., example=37.5172)
    longitude: float = Field(..., example=127.0473)

class CourseItem(BaseModel):
    store: str = Field(..., example="딥디크 플래그십 스토어")
    address: str = Field(..., example="서울특별시 강남구 도산대로 15길 16")
    latitude: float = Field(..., example=37.5258)
    longitude: float = Field(..., example=127.0347)
    recommended_perfumes: List[str] = Field(..., example=["탐다오", "오 로즈"])
    estimated_time_min: int = Field(..., example=12)
    route_description: str = Field(..., example="도보 약 12분 거리입니다.")
