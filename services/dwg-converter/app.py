from __future__ import annotations

import uvicorn
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware

from dwg_service import extract_texts_from_dwg_bytes

app = FastAPI(title="ŞantiJET DWG Converter")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/convert")
async def convert(file: UploadFile = File(...)) -> dict[str, object]:
    data = await file.read()
    if not data:
        raise HTTPException(status_code=400, detail="Boş dosya gönderildi.")

    try:
        texts = extract_texts_from_dwg_bytes(data)
    except ValueError as error:
        raise HTTPException(status_code=422, detail=str(error)) from error

    return {"texts": texts}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
