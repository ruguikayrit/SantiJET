from __future__ import annotations

import math
from dataclasses import dataclass


@dataclass
class DxfSegment:
    layer_name: str
    length: float


def parse_all_segments(content: str) -> list[DxfSegment]:
    pairs = _read_pairs(content)
    segments: list[DxfSegment] = []
    in_entities = False
    index = 0

    while index < len(pairs):
        code, value = pairs[index]

        if code == 0 and value == "SECTION":
            if index + 1 < len(pairs) and pairs[index + 1][0] == 2:
                in_entities = pairs[index + 1][1].upper() == "ENTITIES"
            index += 1
            continue

        if code == 0 and value == "ENDSEC":
            in_entities = False
            index += 1
            continue

        if not in_entities or code != 0:
            index += 1
            continue

        entity_type = value.upper()
        start = index
        index += 1
        while index < len(pairs) and pairs[index][0] != 0:
            index += 1

        entity_pairs = pairs[start:index]
        if entity_type == "LINE":
            segments.append(_line_segment(entity_pairs))
        elif entity_type == "LWPOLYLINE":
            segments.extend(_lw_polyline_segments(entity_pairs))

    return [segment for segment in segments if segment.length > 0]


def _read_pairs(content: str) -> list[tuple[int, str]]:
    normalized = content.replace("\r\n", "\n").replace("\r", "\n")
    lines = normalized.split("\n")
    pairs: list[tuple[int, str]] = []
    index = 0
    while index + 1 < len(lines):
        code_text = lines[index].strip()
        value = lines[index + 1].strip()
        code = int(code_text) if code_text.lstrip("-").isdigit() else None
        if code is not None:
            pairs.append((code, value))
        index += 2
    return pairs


def _line_segment(pairs: list[tuple[int, str]]) -> DxfSegment:
    layer = _string_value(pairs, 8, "0")
    x1 = _double_value(pairs, 10)
    y1 = _double_value(pairs, 20)
    z1 = _double_value(pairs, 30)
    x2 = _double_value(pairs, 11)
    y2 = _double_value(pairs, 21)
    z2 = _double_value(pairs, 31)
    return DxfSegment(layer, _distance(x1, y1, z1, x2, y2, z2))


def _lw_polyline_segments(pairs: list[tuple[int, str]]) -> list[DxfSegment]:
    layer = _string_value(pairs, 8, "0")
    flags = _int_value(pairs, 70)
    closed = flags is not None and (flags & 1) == 1
    xs: list[float] = []
    ys: list[float] = []
    for code, value in pairs:
        if code == 10:
            xs.append(float(value))
        elif code == 20 and len(xs) > len(ys):
            ys.append(float(value))
    count = min(len(xs), len(ys))
    if count < 2:
        return []
    total = 0.0
    for idx in range(1, count):
        total += _distance(xs[idx - 1], ys[idx - 1], 0, xs[idx], ys[idx], 0)
    if closed and count > 2:
        total += _distance(xs[-1], ys[-1], 0, xs[0], ys[0], 0)
    return [DxfSegment(layer, total)]


def _string_value(pairs: list[tuple[int, str]], code: int, fallback: str) -> str:
    for pair_code, value in pairs:
        if pair_code == code:
            return value
    return fallback


def _double_value(pairs: list[tuple[int, str]], code: int) -> float:
    for pair_code, value in pairs:
        if pair_code == code:
            try:
                return float(value)
            except ValueError:
                return 0.0
    return 0.0


def _int_value(pairs: list[tuple[int, str]], code: int) -> int | None:
    for pair_code, value in pairs:
        if pair_code == code:
            try:
                return int(value)
            except ValueError:
                return None
    return None


def _distance(x1: float, y1: float, z1: float, x2: float, y2: float, z2: float) -> float:
    return math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2 + (z2 - z1) ** 2)
