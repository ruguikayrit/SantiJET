from __future__ import annotations

import tempfile
from pathlib import Path

from dxf_segments import parse_all_texts


def extract_texts_from_dxf(content: str) -> list[dict[str, str]]:
    return parse_all_texts(content)


def extract_texts_from_dwg_bytes(data: bytes) -> list[dict[str, str]]:
    with tempfile.TemporaryDirectory() as tmp_dir:
        tmp = Path(tmp_dir)
        input_path = tmp / "upload.dwg"
        output_path = tmp / "upload.dxf"
        input_path.write_bytes(data)

        import subprocess

        result = subprocess.run(
            [
                "dwg2dxf",
                "-y",
                "-o",
                str(output_path),
                str(input_path),
            ],
            capture_output=True,
            text=True,
            timeout=120,
            check=False,
        )

        if result.returncode != 0 or not output_path.exists():
            stderr = (result.stderr or result.stdout or "").strip()
            raise ValueError(stderr or "DWG dosyası DXF'e dönüştürülemedi.")

        content = output_path.read_text(encoding="latin-1", errors="ignore")
        return extract_texts_from_dxf(content)
