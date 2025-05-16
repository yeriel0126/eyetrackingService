from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse
from perfume_backend.schemas.base import BaseResponse
import json, os

router = APIRouter(prefix="/perfumes", tags=["Perfume"])

# JSON 파일 경로 설정
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
perfume_path = os.path.join(BASE_DIR, "../data/perfume_data.json")

with open(perfume_path, "r", encoding="utf-8") as f:
    perfume_data = json.load(f)

# 전체 향수 목록 조회
@router.get(
    "/",
    response_model=BaseResponse,
    summary="전체 향수 목록 조회",
    description="저장된 전체 향수 데이터를 리스트로 반환합니다.",
    response_description="향수 목록 리스트 반환"
)
async def get_all_perfumes():
    return BaseResponse(
        code=200,
        message="전체 향수 목록입니다.",
        data={"perfumes": perfume_data}
    )

# 특정 향수 상세 조회
@router.get(
    "/{name}",
    response_model=BaseResponse,
    summary="향수 상세 정보 조회",
    description="지정한 이름에 해당하는 향수의 상세 정보를 반환합니다.",
    response_description="향수 상세 데이터 반환"
)
async def get_perfume_detail(name: str):
    result = next((p for p in perfume_data if p["name"] == name), None)

    if not result:
        raise HTTPException(status_code=404, detail="해당 이름의 향수를 찾을 수 없습니다.")

    return BaseResponse(
        code=200,
        message=f"{name} 향수의 상세 정보입니다.",
        data=result
    )
