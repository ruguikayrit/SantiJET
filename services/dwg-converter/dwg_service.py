from __future__ import annotations

import tempfile
from pathlib import Path

from dxf_segments import parse_all_segments


def extract_segments_from_dxf(content: str) -> list[dict[str, object]]:
    segments = parse_all_segments(content)
    return [
        {"layerName": segment.layer_name, "length": segment.length}
        for segment in segments
        if segment.length > 0
    ]


def extract_segments_from_dwg_bytes(data: bytes) -> list[dict[str, object]]:
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
        return extract_segments_from_dxf(content)
