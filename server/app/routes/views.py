import os

from fastapi import APIRouter
from fastapi.responses import FileResponse

router = APIRouter()


def get_latest(base_path: str):
    file_name_and_time_lst = []

    for f_name in os.listdir(f"{base_path}"):
        written_time = os.path.getctime(os.path.join(base_path, f_name))
        file_name_and_time_lst.append((f_name, written_time))

    sorted_file_lst = sorted(file_name_and_time_lst, key=lambda x: x[1], reverse=True)

    recent_file = sorted_file_lst[0]
    recent_file_name = recent_file[0]

    file_path = os.path.join(base_path, recent_file_name)
    return file_path, recent_file_name


def get_path():
    return os.path.join(
        "tffile",
    )


@router.get("/update")
def update_file():
    base_path = get_path()
    file_path, recent_file_name = get_latest(base_path)
    return FileResponse(path=file_path, filename=recent_file_name)


@router.get("/check")
def check_file():
    base_path = get_path()
    file_path, recent_file_name = get_latest(base_path)
    return recent_file_name
