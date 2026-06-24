"""Validation engine for imported poz records."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any


@dataclass
class ValidationIssue:
    field: str
    message: str
    severity: str = "error"  # error | warning | review


@dataclass
class ValidationResult:
    valid: bool
    issues: list[ValidationIssue] = field(default_factory=list)
    record: dict[str, Any] | None = None


SUSPICIOUS_POZ_CHARS = set("OIl|")


def validate_record(record: dict[str, Any]) -> ValidationResult:
    issues: list[ValidationIssue] = []
    poz_no = (record.get("poz_no") or record.get("pozNo") or "").strip()
    poz_adi = (record.get("poz_adi") or record.get("analizAdi") or "").strip()
    birim = (record.get("birim") or record.get("olcuBirimi") or "").strip()
    kaynak = (record.get("kaynak_dosya") or record.get("_meta", {}).get("kaynak_dosya") or "").strip()
    sayfa = record.get("kaynak_sayfa")

    if not poz_no:
        issues.append(ValidationIssue("poz_no", "Poz numarası boş olamaz"))
    if not poz_adi:
        issues.append(ValidationIssue("poz_adi", "Poz adı boş olamaz"))
    if not birim:
        issues.append(ValidationIssue("birim", "Birim boş olamaz"))
    if not kaynak:
        issues.append(ValidationIssue("kaynak_dosya", "Kaynak dosya bilgisi boş olamaz"))
    if sayfa is None and "kaynak_sayfa" in record:
        issues.append(ValidationIssue("kaynak_sayfa", "Sayfa referansı boş olamaz"))

    for ch in poz_no:
        if ch in SUSPICIOUS_POZ_CHARS:
            issues.append(
                ValidationIssue(
                    "poz_no",
                    f"Şüpheli karakter '{ch}' — OCR doğrulama kuyruğuna alınmalı",
                    severity="review",
                )
            )

    return ValidationResult(valid=not any(i.severity == "error" for i in issues), issues=issues, record=record)


def validate_batch(records: list[dict[str, Any]]) -> tuple[list[ValidationResult], list[ValidationResult]]:
    ok: list[ValidationResult] = []
    bad: list[ValidationResult] = []
    seen: set[str] = set()

    for rec in records:
        poz = (rec.get("poz_no") or rec.get("pozNo") or "").strip()
        if poz in seen:
            vr = ValidationResult(
                valid=False,
                issues=[ValidationIssue("poz_no", f"Aynı poz numarası tekrar ediyor: {poz}")],
                record=rec,
            )
            bad.append(vr)
            continue
        seen.add(poz)

        vr = validate_record(rec)
        (ok if vr.valid else bad).append(vr)

    return ok, bad


def import_report(expected: int, imported: int, duplicates: int, failed: int) -> dict[str, Any]:
    missing = max(0, expected - imported)
    success = missing == 0 and duplicates == 0 and failed == 0
    return {
        "expected_in_pdf": expected,
        "imported": imported,
        "missing": missing,
        "duplicates": duplicates,
        "failed": failed,
        "success": success,
    }
