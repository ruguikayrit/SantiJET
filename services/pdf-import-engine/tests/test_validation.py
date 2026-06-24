"""Validation engine tests."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from validation.engine import import_report, validate_batch, validate_record  # noqa: E402


def test_validate_record_ok():
    rec = {
        "poz_no": "25.100.1001",
        "poz_adi": "Lavabo",
        "birim": "Ad",
        "kaynak_dosya": "test.pdf",
        "kaynak_sayfa": 2,
    }
    vr = validate_record(rec)
    assert vr.valid


def test_validate_record_missing_poz():
    vr = validate_record({"poz_adi": "X", "birim": "Ad", "kaynak_dosya": "a.pdf"})
    assert not vr.valid


def test_duplicate_detection():
    recs = [
        {"pozNo": "25.1", "analizAdi": "A", "olcuBirimi": "Ad", "kaynak_dosya": "a.pdf"},
        {"pozNo": "25.1", "analizAdi": "B", "olcuBirimi": "Ad", "kaynak_dosya": "a.pdf"},
    ]
    ok, bad = validate_batch(recs)
    assert len(ok) == 1
    assert len(bad) == 1


def test_import_report_failure_on_missing():
    report = import_report(expected=100, imported=98, duplicates=0, failed=2)
    assert not report["success"]
    assert report["missing"] == 2
