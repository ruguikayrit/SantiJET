"""FastAPI admin panel — PDF yükleme ve import geçmişi."""

from __future__ import annotations

from pathlib import Path
from typing import Any

try:
    from fastapi import FastAPI, File, UploadFile
    from fastapi.responses import JSONResponse
except ImportError:  # pragma: no cover
    FastAPI = None  # type: ignore

UPLOAD_DIR = Path("/tmp/santijet-pdf-uploads")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

app = FastAPI(title="Şantijet PDF Import Engine", version="0.1.0") if FastAPI else None


if app is not None:

    @app.get("/health")
    def health() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/imports")
    def list_imports() -> list[dict[str, Any]]:
        return []

    @app.get("/errors")
    def list_errors(kurum: str | None = None, yil: int | None = None) -> list[dict[str, Any]]:
        return []

    @app.get("/review-queue")
    def review_queue() -> list[dict[str, Any]]:
        return []

    @app.post("/upload")
    async def upload_pdf(
        kurum: str,
        yil: int,
        format_id: str = "mekanik_bfa",
        file: UploadFile = File(...),
    ) -> JSONResponse:
        dest = UPLOAD_DIR / file.filename
        content = await file.read()
        dest.write_bytes(content)
        return JSONResponse(
            {
                "message": "PDF yüklendi — import kuyruğa alındı",
                "path": str(dest),
                "kurum": kurum,
                "yil": yil,
                "format_id": format_id,
            }
        )
