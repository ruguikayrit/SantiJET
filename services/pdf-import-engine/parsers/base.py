"""Base parser interface for Şantijet PDF Import Engine."""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


@dataclass
class ParsedRecord:
    kurum: str
    yil: int
    kaynak_dosya: str
    kaynak_sayfa: int | None
    poz_no: str
    poz_adi: str
    birim: str
    yapim_sarti: str = ""
    analiz: str = ""
    birim_fiyat: float | None = None
    para_birimi: str = "TRY"
    kategori: str = ""
    alt_kategori: str = ""
    kalemler: list[dict[str, Any]] = field(default_factory=list)
    raw: dict[str, Any] = field(default_factory=dict)


@dataclass
class ParseResult:
    records: list[ParsedRecord]
    source_file: str
    page_count: int
    warnings: list[str] = field(default_factory=list)


class BasePdfParser(ABC):
    """Kurum/format bazlı PDF parser arayüzü."""

    kurum: str = ""
    format_id: str = ""

    @abstractmethod
    def parse_file(self, pdf_path: Path) -> ParseResult:
        raise NotImplementedError

    @abstractmethod
    def count_expected_records(self, pdf_path: Path) -> int:
        """PDF içindeki beklenen poz sayısı (doğrulama için)."""
        raise NotImplementedError
