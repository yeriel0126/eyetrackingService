from fastapi import APIRouter
from perfume_backend.schemas.diary import DiaryEntry
from perfume_backend.schemas.base import BaseResponse

router = APIRouter(prefix="/diary", tags=["Diary"])

# 메모리 저장소 (임시)
diary_entries = []

# 일기 저장
@router.post("/", response_model=BaseResponse, summary="시향 일기 저장", description="향수를 시향한 후 일기를 작성해 저장합니다.")
async def save_diary(entry: DiaryEntry):
    diary_entries.append(entry)
    return BaseResponse(
        code=200,
        message="시향 일기가 저장되었습니다.",
        data=None
    )

# 일기 전체 조회
@router.get("/", response_model=BaseResponse, summary="시향 일기 조회", description="저장된 시향 일기들을 조회합니다.")
async def get_all_diaries():
    return BaseResponse(
        code=200,
        message="시향 일기 목록을 반환합니다.",
        data={"entries": diary_entries}
    )
