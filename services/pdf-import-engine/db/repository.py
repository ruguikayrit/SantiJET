"""PostgreSQL import repository."""

from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any

try:
    import psycopg2
    import psycopg2.extras
except ImportError:  # pragma: no cover
    psycopg2 = None  # type: ignore


def get_dsn() -> str:
    return os.environ.get(
        "DATABASE_URL",
        "postgresql://santijet:santijet@localhost:5432/santijet_pdf",
    )


def run_migrations(migrations_dir: Path | None = None) -> None:
    if psycopg2 is None:
        raise RuntimeError("psycopg2 required: pip install psycopg2-binary")
    migrations_dir = migrations_dir or Path(__file__).resolve().parent / "migrations"
    conn = psycopg2.connect(get_dsn())
    try:
        with conn.cursor() as cur:
            for sql_file in sorted(migrations_dir.glob("*.sql")):
                cur.execute(sql_file.read_text(encoding="utf-8"))
        conn.commit()
    finally:
        conn.close()


def insert_records(job_id: int, records: list[dict[str, Any]]) -> int:
    if psycopg2 is None:
        raise RuntimeError("psycopg2 required")
    conn = psycopg2.connect(get_dsn())
    inserted = 0
    try:
        with conn.cursor() as cur:
            for rec in records:
                cur.execute(
                    """
                    INSERT INTO poz_kayitlari (
                        job_id, kurum, yil, kaynak_dosya, kaynak_sayfa,
                        poz_no, poz_adi, birim, yapim_sarti, analiz,
                        birim_fiyat, para_birimi, kategori, alt_kategori, payload
                    ) VALUES (
                        %(job_id)s, %(kurum)s, %(yil)s, %(kaynak_dosya)s, %(kaynak_sayfa)s,
                        %(poz_no)s, %(poz_adi)s, %(birim)s, %(yapim_sarti)s, %(analiz)s,
                        %(birim_fiyat)s, %(para_birimi)s, %(kategori)s, %(alt_kategori)s, %(payload)s
                    )
                    ON CONFLICT (kurum, yil, poz_no) DO UPDATE SET
                        poz_adi = EXCLUDED.poz_adi,
                        birim = EXCLUDED.birim,
                        birim_fiyat = EXCLUDED.birim_fiyat,
                        payload = EXCLUDED.payload,
                        guncelleme_tarihi = NOW()
                    """,
                    {
                        "job_id": job_id,
                        "kurum": rec.get("kurum"),
                        "yil": rec.get("yil"),
                        "kaynak_dosya": rec.get("kaynak_dosya"),
                        "kaynak_sayfa": rec.get("kaynak_sayfa"),
                        "poz_no": rec.get("poz_no") or rec.get("pozNo"),
                        "poz_adi": rec.get("poz_adi") or rec.get("analizAdi"),
                        "birim": rec.get("birim") or rec.get("olcuBirimi"),
                        "yapim_sarti": rec.get("yapim_sarti") or rec.get("yapimSartlari") or "",
                        "analiz": rec.get("analiz") or rec.get("pozTarifi") or "",
                        "birim_fiyat": rec.get("birim_fiyat") or rec.get("birimFiyati"),
                        "para_birimi": rec.get("para_birimi") or "TRY",
                        "kategori": rec.get("kategori") or "",
                        "alt_kategori": rec.get("alt_kategori") or "",
                        "payload": json.dumps(rec),
                    },
                )
                inserted += 1
        conn.commit()
    finally:
        conn.close()
    return inserted
