from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse
from perfume_backend.schemas.base import BaseResponse
import json
import os

router = APIRouter(prefix="/stores", tags=["Store"])

# JSON 경로 설정
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
data_path = os.path.join(BASE_DIR, "../data/store_data.json")

# 전체 매장 조회
@router.get("/", response_model=BaseResponse, summary="전체 매장 목록 조회", description="전체 매장 목록을 반환합니다.")
async def get_all_stores():
    with open(data_path, "r", encoding="utf-8") as f:
        stores = json.load(f)

    return BaseResponse(
        code=200,
        message="전체 매장 목록을 반환합니다.",
        data={"stores": stores}
    )

# 브랜드별 매장 조회
@router.get("/{brand}", response_model=BaseResponse, summary="브랜드별 매장 조회", description="해당 브랜드의 매장 목록을 반환합니다.")
async def get_store_by_brand(brand: str):
    with open(data_path, "r", encoding="utf-8") as f:
        stores = json.load(f)

    matched = [s for s in stores if brand.lower() in [b.lower() for b in s.get("brands", [])]]

    if not matched:
        return JSONResponse(
            status_code=404,
            content={
                "code": 404,
                "message": f"브랜드 '{brand}'에 해당하는 매장이 없습니다.",
                "data": None
            }
        )

    return BaseResponse(
        code=200,
        message=f"브랜드 '{brand}'의 매장 목록을 반환합니다.",
        data={"stores": matched}
    )
