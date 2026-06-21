#!/usr/bin/env python3
"""
YFK ÇŞB şartnameler sayfasındaki PDF dosyalarını indirir ve ZIP olarak paketler.
Resmi Gazete HTML sayfalarını WeasyPrint ile PDF'e dönüştürür.

Bağımlılıklar:
    pip install requests beautifulsoup4 lxml weasyprint

Kullanım:
    python download_yfk_sartnameler.py

Çalıştırma dizinine yfk_pdfs/ klasörü ve yfk_sartnameler.zip oluşturur.
"""

from __future__ import annotations

import logging
import os
import re
import sys
import time
import zipfile
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path
from threading import Lock
from typing import Iterable
from urllib.parse import unquote, urljoin, urlparse, urlunparse

import requests
from bs4 import BeautifulSoup
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

START_URL = "https://yfk.csb.gov.tr/sartnameler-i-330"
OUTPUT_DIR = Path("yfk_pdfs")
ZIP_NAME = "yfk_sartnameler.zip"

USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/124.0.0.0 Safari/537.36"
)

ALLOWED_HOSTS = {
    "yfk.csb.gov.tr",
    "webdosya.csb.gov.tr",
    "csb.gov.tr",
    "resmigazete.gov.tr",
}

PDF_URL_RE = re.compile(r"https?://[^\s\"'<>]+\.pdf(?:\?[^\s\"'<>]*)?", re.IGNORECASE)
GENERIC_URL_RE = re.compile(
    r"https?://(?:www\.)?(?:resmigazete|webdosya|yfk|csb)\.gov\.tr[^\s\"'<>]*",
    re.IGNORECASE,
)

REQUEST_TIMEOUT = 30
VERIFY_TIMEOUT = 12
MAX_RETRIES = 4
VERIFY_RETRIES = 2
HTML_FETCH_RETRIES = 2
RETRY_BACKOFF = 1.5
CRAWL_WORKERS = 8
DOWNLOAD_WORKERS = 6
CONVERT_WORKERS = 3
CHUNK_SIZE = 256 * 1024
CONVERT_RESMI_GAZETE_HTML = True

PDF_PRINT_CSS = """
@page { size: A4; margin: 14mm 12mm; }
body {
  font-family: "DejaVu Sans", sans-serif;
  font-size: 10pt;
  line-height: 1.45;
  color: #111;
}
h1, h2, h3 { page-break-after: avoid; }
table { width: 100%; border-collapse: collapse; margin: 8px 0; }
td, th { border: 1px solid #666; padding: 4px 6px; vertical-align: top; }
p { margin: 6px 0; }
.source-url {
  font-size: 8pt;
  color: #555;
  border-bottom: 1px solid #ccc;
  margin-bottom: 12px;
  padding-bottom: 6px;
}
"""

logger = logging.getLogger("yfk_pdf_scraper")


@dataclass(frozen=True)
class PdfTarget:
    url: str
    source: str


@dataclass(frozen=True)
class HtmlConvertTarget:
    url: str
    filename: str


class ProgressTracker:
    def __init__(self, total: int, label: str) -> None:
        self.total = max(total, 1)
        self.label = label
        self.completed = 0
        self._lock = Lock()
        self._last_pct = -1

    def advance(self, step: int = 1) -> None:
        with self._lock:
            self.completed += step
            pct = int((self.completed / self.total) * 100)
            if pct != self._last_pct:
                self._last_pct = pct
                print(f"\r{self.label}: {pct:3d}% ({self.completed}/{self.total})", end="", flush=True)

    def finish(self) -> None:
        print()


def setup_logging() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%H:%M:%S",
    )


def normalize_host(host: str) -> str:
    return host.lower().removeprefix("www.")


def normalize_url(url: str) -> str:
    parsed = urlparse(url.strip())
    path = re.sub(r"/{2,}", "/", parsed.path or "/")
    if path != "/" and path.endswith("/"):
        path = path.rstrip("/")
    normalized = parsed._replace(
        scheme=parsed.scheme.lower(),
        netloc=parsed.netloc.lower(),
        path=path,
        fragment="",
    )
    return urlunparse(normalized)


def is_allowed_url(url: str) -> bool:
    parsed = urlparse(url)
    if parsed.scheme not in {"http", "https"}:
        return False
    return normalize_host(parsed.netloc) in ALLOWED_HOSTS


def is_pdf_url(url: str) -> bool:
    path = urlparse(url).path.lower()
    return path.endswith(".pdf")


def is_resmigazete_html(url: str) -> bool:
    if normalize_host(urlparse(url).netloc) != "resmigazete.gov.tr":
        return False
    return urlparse(url).path.lower().endswith((".htm", ".html"))


def html_url_to_pdf_filename(url: str) -> str:
    stem = Path(urlparse(url).path).stem or "resmigazete"
    return sanitize_filename(f"{stem}.pdf")


def is_crawl_candidate(url: str) -> bool:
    if not is_allowed_url(url):
        return False
    if is_pdf_url(url):
        return False

    path = urlparse(url).path.lower()
    host = normalize_host(urlparse(url).netloc)

    if host == "resmigazete.gov.tr" and path.endswith((".htm", ".html")):
        return True

    if host == "webdosya.csb.gov.tr" and "/db/yfk/" in path:
        return True

    if host == "yfk.csb.gov.tr" and path.endswith((".htm", ".html", ".php", ".asp", ".aspx")):
        return True

    return False


def sanitize_filename(name: str) -> str:
    cleaned = unquote(name).strip().replace("\\", "/").split("/")[-1]
    cleaned = re.sub(r"[^\w.\- ()\u0080-\uFFFF]+", "_", cleaned, flags=re.UNICODE)
    cleaned = cleaned.strip("._") or "document.pdf"
    if not cleaned.lower().endswith(".pdf"):
        cleaned += ".pdf"
    return cleaned


def esc_html(text: str) -> str:
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


def build_session() -> requests.Session:
    session = requests.Session()
    session.headers.update(
        {
            "User-Agent": USER_AGENT,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7",
            "Connection": "keep-alive",
        }
    )
    retry = Retry(
        total=0,
        connect=0,
        read=0,
        status=0,
        raise_on_status=False,
    )
    adapter = HTTPAdapter(max_retries=retry, pool_connections=20, pool_maxsize=20)
    session.mount("http://", adapter)
    session.mount("https://", adapter)
    return session


def request_with_retries(
    session: requests.Session,
    method: str,
    url: str,
    *,
    stream: bool = False,
    allow_redirects: bool = True,
    timeout: int = REQUEST_TIMEOUT,
    max_retries: int = MAX_RETRIES,
) -> requests.Response:
    last_error: Exception | None = None
    for attempt in range(1, max_retries + 1):
        try:
            response = session.request(
                method,
                url,
                timeout=timeout,
                stream=stream,
                allow_redirects=allow_redirects,
            )
            if response.status_code == 404:
                response.close()
                raise FileNotFoundError(f"404 Not Found: {url}")
            return response
        except FileNotFoundError:
            raise
        except requests.RequestException as exc:
            last_error = exc
            if attempt >= max_retries:
                break
            wait = RETRY_BACKOFF ** attempt
            logger.warning(
                "İstek hatası (%s/%s) %s -> %s (%.1fs sonra tekrar)",
                attempt,
                max_retries,
                url,
                exc,
                wait,
            )
            time.sleep(wait)
    assert last_error is not None
    raise last_error


def extract_links_from_html(html: str, base_url: str) -> set[str]:
    links: set[str] = set()
    soup = BeautifulSoup(html, "lxml")

    for tag in soup.find_all(["a", "iframe", "embed", "object", "source"], href=True):
        links.add(urljoin(base_url, tag["href"]))
    for tag in soup.find_all(["iframe", "embed", "object", "source"], src=True):
        links.add(urljoin(base_url, tag["src"]))
    for tag in soup.find_all("a", download=True):
        if tag.has_attr("href"):
            links.add(urljoin(base_url, tag["href"]))

    for match in PDF_URL_RE.findall(html):
        links.add(match)
    for match in GENERIC_URL_RE.findall(html):
        links.add(match.rstrip(".,;)'\"}]"))

    return {normalize_url(link) for link in links if is_allowed_url(link)}


def extract_sartname_links(html: str, base_url: str) -> tuple[set[str], set[str]]:
    soup = BeautifulSoup(html, "lxml")
    content = soup.select_one("div.page_content") or soup.select_one("div.main") or soup

    pdf_links: set[str] = set()
    crawl_links: set[str] = set()

    def register(url: str) -> None:
        if not is_allowed_url(url):
            return
        normalized = normalize_url(url)
        if is_pdf_url(normalized):
            pdf_links.add(normalized)
        elif is_crawl_candidate(normalized):
            crawl_links.add(normalized)

    for table in content.find_all("table"):
        for anchor in table.find_all("a", href=True):
            register(urljoin(base_url, anchor["href"]))
        for cell in table.find_all(["td", "th"]):
            text = cell.get_text(" ", strip=True)
            for match in GENERIC_URL_RE.findall(text):
                register(match.rstrip(".,;)'\"}]"))

    for anchor in content.find_all("a", href=True):
        register(urljoin(base_url, anchor["href"]))

    # Görev bölümündeki Kanun/Kararname/Yönetmelik bağlantıları sidebar menüdedir.
    for item in soup.find_all("li"):
        label = item.get_text(" ", strip=True)
        if not any(keyword in label for keyword in ("Kanun:", "Kararname:", "Yönetmelik:")):
            continue
        for anchor in item.find_all("a", href=True):
            register(urljoin(base_url, anchor["href"]))

    page_html = str(content)
    for match in PDF_URL_RE.findall(page_html):
        register(match)
    for match in GENERIC_URL_RE.findall(page_html):
        register(match.rstrip(".,;)'\"}]"))

    for match in PDF_URL_RE.findall(html):
        register(match)

    return pdf_links, crawl_links


def pdf_candidates_from_page_url(page_url: str) -> list[str]:
    parsed = urlparse(page_url)
    path = parsed.path
    candidates: list[str] = []

    if path.lower().endswith((".htm", ".html")):
        base = path.rsplit(".", 1)[0]
        candidates.append(urlunparse(parsed._replace(path=f"{base}.pdf")))

    return [normalize_url(item) for item in candidates]


def discover_pdfs_on_page(session: requests.Session, page_url: str) -> tuple[set[str], set[str]]:
    discovered_pdfs: set[str] = set()
    discovered_crawl: set[str] = set()

    try:
        response = request_with_retries(session, "GET", page_url)
    except FileNotFoundError:
        logger.warning("Sayfa bulunamadı: %s", page_url)
        return discovered_pdfs, discovered_crawl
    except requests.RequestException as exc:
        logger.warning("Sayfa alınamadı: %s -> %s", page_url, exc)
        return discovered_pdfs, discovered_crawl

    content_type = response.headers.get("Content-Type", "").lower()
    if "application/pdf" in content_type or response.content[:4] == b"%PDF":
        discovered_pdfs.add(normalize_url(response.url))
        response.close()
        return discovered_pdfs, discovered_crawl

    if "text/html" not in content_type and "application/xhtml" not in content_type:
        response.close()
        return discovered_pdfs, discovered_crawl

    html = response.text
    response.close()
    final_url = normalize_url(response.url)

    for link in extract_links_from_html(html, final_url):
        if is_pdf_url(link):
            discovered_pdfs.add(link)
        elif is_crawl_candidate(link):
            discovered_crawl.add(link)

    for candidate in pdf_candidates_from_page_url(final_url):
        discovered_pdfs.add(candidate)

    return discovered_pdfs, discovered_crawl


def verify_pdf_url(session: requests.Session, url: str) -> bool:
    if normalize_host(urlparse(url).netloc) == "webdosya.csb.gov.tr" and is_pdf_url(url):
        return True

    try:
        response = request_with_retries(
            session,
            "HEAD",
            url,
            allow_redirects=True,
            timeout=VERIFY_TIMEOUT,
            max_retries=VERIFY_RETRIES,
        )
        content_type = response.headers.get("Content-Type", "").lower()
        ok = response.status_code < 400 and (
            "application/pdf" in content_type or is_pdf_url(response.url)
        )
        response.close()
        if ok:
            return True
    except FileNotFoundError:
        return False
    except requests.RequestException:
        pass

    try:
        response = request_with_retries(
            session,
            "GET",
            url,
            stream=True,
            allow_redirects=True,
            timeout=VERIFY_TIMEOUT,
            max_retries=VERIFY_RETRIES,
        )
        chunk = next(response.iter_content(chunk_size=8), b"")
        content_type = response.headers.get("Content-Type", "").lower()
        ok = response.status_code < 400 and (
            chunk.startswith(b"%PDF") or "application/pdf" in content_type
        )
        response.close()
        return ok
    except (FileNotFoundError, requests.RequestException, StopIteration):
        return False


def resolve_pdf_targets(
    session: requests.Session,
    seed_pdfs: set[str],
    seed_crawl: set[str],
    *,
    convert_resmigazete_html: bool = CONVERT_RESMI_GAZETE_HTML,
) -> list[PdfTarget]:
    crawl_queue = {
        url
        for url in seed_crawl
        if not (convert_resmigazete_html and is_resmigazete_html(url))
    }
    pdf_urls: set[str] = set(seed_pdfs)
    visited_pages: set[str] = set()
    verified_pdfs: set[str] = set()

    for page_url in crawl_queue:
        pdf_urls.update(pdf_candidates_from_page_url(page_url))

    while crawl_queue:
        batch = sorted(crawl_queue - visited_pages)
        if not batch:
            break
        visited_pages.update(batch)
        crawl_queue.difference_update(batch)

        progress = ProgressTracker(len(batch), "Alt sayfa taraması")
        with ThreadPoolExecutor(max_workers=CRAWL_WORKERS) as executor:
            futures = {
                executor.submit(discover_pdfs_on_page, session, page_url): page_url
                for page_url in batch
            }
            for future in as_completed(futures):
                page_url = futures[future]
                try:
                    pdfs, nested = future.result()
                    pdf_urls.update(pdfs)
                    crawl_queue.update(nested - visited_pages)
                except Exception as exc:  # noqa: BLE001
                    logger.warning("Tarama hatası %s -> %s", page_url, exc)
                progress.advance()
        progress.finish()

    candidate_list = sorted(pdf_urls)
    logger.info("Doğrulanacak PDF adayı: %s", len(candidate_list))

    progress = ProgressTracker(len(candidate_list), "PDF doğrulama")
    with ThreadPoolExecutor(max_workers=CRAWL_WORKERS) as executor:
        futures = {
            executor.submit(verify_pdf_url, session, url): url for url in candidate_list
        }
        for future in as_completed(futures):
            url = futures[future]
            try:
                if future.result():
                    verified_pdfs.add(url)
            except Exception as exc:  # noqa: BLE001
                logger.warning("PDF doğrulama hatası %s -> %s", url, exc)
            progress.advance()
    progress.finish()

    return [PdfTarget(url=url, source="yfk_sartnameler") for url in sorted(verified_pdfs)]


def filename_from_response(url: str, response: requests.Response) -> str:
    content_disposition = response.headers.get("Content-Disposition", "")
    match = re.search(r"filename\*=UTF-8''([^;]+)|filename=\"?([^\";]+)\"?", content_disposition, re.I)
    if match:
        raw_name = match.group(1) or match.group(2) or ""
        if raw_name:
            return sanitize_filename(unquote(raw_name))

    parsed = urlparse(response.url or url)
    basename = os.path.basename(parsed.path)
    return sanitize_filename(basename or "document.pdf")


def unique_destination_path(directory: Path, filename: str) -> Path:
    candidate = directory / filename
    if not candidate.exists():
        return candidate

    stem = Path(filename).stem
    suffix = Path(filename).suffix or ".pdf"
    index = 2
    while True:
        alt = directory / f"{stem}_{index}{suffix}"
        if not alt.exists():
            return alt
        index += 1


def wayback_fallback_urls(url: str) -> list[str]:
    match = re.search(r"/eskiler/(\d{4})/", urlparse(url).path)
    years: list[str] = []
    if match:
        year = int(match.group(1))
        years.extend(str(y) for y in range(year, min(year + 3, 2026)))
    years.extend(["2024", "2023", ""])
    seen: set[str] = set()
    candidates: list[str] = []
    for year in years:
        prefix = f"https://web.archive.org/web/{year}/" if year else "https://web.archive.org/web/"
        candidate = f"{prefix}{url}"
        if candidate not in seen:
            seen.add(candidate)
            candidates.append(candidate)
    return candidates


def fetch_html_page(session: requests.Session, url: str) -> tuple[str, str] | None:
    sources = [url, *wayback_fallback_urls(url)]
    last_error: str | None = None

    for source in sources:
        try:
            response = request_with_retries(
                session,
                "GET",
                source,
                max_retries=HTML_FETCH_RETRIES,
            )
        except FileNotFoundError:
            last_error = f"404: {source}"
            continue
        except requests.RequestException as exc:
            last_error = str(exc)
            continue

        content_type = response.headers.get("Content-Type", "").lower()
        if "text/html" not in content_type and "application/xhtml" not in content_type:
            response.close()
            last_error = f"HTML değil: {source}"
            continue

        html = response.text
        final_url = normalize_url(url)
        response.close()

        if len(re.sub(r"\s+", "", html)) < 200:
            last_error = f"Çok kısa içerik: {source}"
            continue

        if source != url:
            logger.info("Wayback yedek kaynak kullanıldı: %s", source)
        return html, final_url

    logger.warning("HTML sayfa alınamadı: %s -> %s", url, last_error)
    return None


def extract_resmigazete_body(html: str) -> tuple[str, str]:
    soup = BeautifulSoup(html, "lxml")

    for tag in soup.find_all(["script", "style", "noscript", "iframe", "meta", "link"]):
        tag.decompose()

    title = soup.title.get_text(" ", strip=True) if soup.title else "Resmî Gazete"

    content = None
    for selector in ("div.html-content", "#PageContent", "div#page-content", "body"):
        node = soup.select_one(selector)
        if node and len(node.get_text(" ", strip=True)) >= 80:
            content = node
            break

    if content is None:
        content = soup.body or soup

    for tag in content.find_all(["nav", "header", "footer", "form"]):
        tag.decompose()

    for node in content.find_all(string=re.compile(r"Resmî Gazete'nin kurumsal mobil uygulaması", re.I)):
        parent = node.parent
        if parent is not None:
            parent.decompose()

    inner_html = content.decode_contents() if hasattr(content, "decode_contents") else str(content)
    return title, inner_html


def build_printable_html(title: str, body_html: str, source_url: str) -> str:
    safe_title = esc_html(title)
    safe_url = esc_html(source_url)
    return f"""<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <title>{safe_title}</title>
</head>
<body>
  <div class="source-url">Kaynak: {safe_url}</div>
  <h1>{safe_title}</h1>
  {body_html}
</body>
</html>"""


def convert_html_to_pdf_file(html_document: str, base_url: str, destination: Path) -> None:
    from weasyprint import CSS, HTML

    HTML(string=html_document, base_url=base_url).write_pdf(
        target=str(destination),
        stylesheets=[CSS(string=PDF_PRINT_CSS)],
    )


def html_convert_targets(seed_crawl: set[str], output_dir: Path) -> list[HtmlConvertTarget]:
    targets: list[HtmlConvertTarget] = []
    seen_names: set[str] = set()

    for url in sorted(seed_crawl):
        if not is_resmigazete_html(url):
            continue

        filename = html_url_to_pdf_filename(url)
        if filename in seen_names:
            continue
        if (output_dir / filename).exists():
            continue

        seen_names.add(filename)
        targets.append(HtmlConvertTarget(url=url, filename=filename))

    return targets


def convert_html_page(
    session: requests.Session,
    target: HtmlConvertTarget,
    output_dir: Path,
) -> Path | None:
    fetched = fetch_html_page(session, target.url)
    if fetched is None:
        return None

    raw_html, final_url = fetched
    try:
        title, body_html = extract_resmigazete_body(raw_html)
        printable = build_printable_html(title, body_html, final_url)
        destination = unique_destination_path(output_dir, target.filename)
        convert_html_to_pdf_file(printable, final_url, destination)

        with destination.open("rb") as handle:
            if handle.read(4) != b"%PDF":
                destination.unlink(missing_ok=True)
                logger.error("HTML'den üretilen dosya geçerli PDF değil: %s", target.url)
                return None

        logger.info("HTML→PDF: %s -> %s", target.url, destination.name)
        return destination
    except Exception as exc:  # noqa: BLE001
        logger.error("HTML→PDF dönüşüm hatası %s -> %s", target.url, exc)
        return None


def convert_all_html_pages(
    session: requests.Session,
    targets: Iterable[HtmlConvertTarget],
    output_dir: Path,
) -> list[Path]:
    target_list = list(targets)
    if not target_list:
        return []

    converted: list[Path] = []
    progress = ProgressTracker(len(target_list), "HTML→PDF dönüşüm")
    with ThreadPoolExecutor(max_workers=CONVERT_WORKERS) as executor:
        futures = {
            executor.submit(convert_html_page, session, target, output_dir): target
            for target in target_list
        }
        for future in as_completed(futures):
            target = futures[future]
            try:
                path = future.result()
                if path is not None:
                    converted.append(path)
            except Exception as exc:  # noqa: BLE001
                logger.error("Dönüşüm hatası %s -> %s", target.url, exc)
            progress.advance()
    progress.finish()
    return converted


def download_pdf(session: requests.Session, target: PdfTarget, output_dir: Path) -> Path | None:
    try:
        response = request_with_retries(session, "GET", target.url, stream=True)
    except FileNotFoundError:
        logger.error("PDF bulunamadı: %s", target.url)
        return None
    except requests.RequestException as exc:
        logger.error("PDF indirilemedi: %s -> %s", target.url, exc)
        return None

    try:
        filename = filename_from_response(target.url, response)
        destination = unique_destination_path(output_dir, filename)

        with destination.open("wb") as handle:
            for chunk in response.iter_content(chunk_size=CHUNK_SIZE):
                if chunk:
                    handle.write(chunk)

        with destination.open("rb") as handle:
            if handle.read(4) != b"%PDF":
                destination.unlink(missing_ok=True)
                logger.error("Geçersiz PDF içeriği: %s", target.url)
                return None

        logger.info("İndirildi: %s -> %s", target.url, destination.name)
        return destination
    finally:
        response.close()


def create_zip(source_dir: Path, zip_path: Path) -> None:
    pdf_files = sorted(source_dir.glob("*.pdf"))
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for pdf_file in pdf_files:
            archive.write(pdf_file, arcname=pdf_file.name)
    logger.info("ZIP oluşturuldu: %s (%s dosya)", zip_path, len(pdf_files))


def download_all_pdfs(session: requests.Session, targets: Iterable[PdfTarget], output_dir: Path) -> list[Path]:
    target_list = list(targets)
    if not target_list:
        return []

    downloaded: list[Path] = []
    progress = ProgressTracker(len(target_list), "PDF indirme")
    with ThreadPoolExecutor(max_workers=DOWNLOAD_WORKERS) as executor:
        futures = {
            executor.submit(download_pdf, session, target, output_dir): target for target in target_list
        }
        for future in as_completed(futures):
            target = futures[future]
            try:
                path = future.result()
                if path is not None:
                    downloaded.append(path)
            except Exception as exc:  # noqa: BLE001
                logger.error("İndirme hatası %s -> %s", target.url, exc)
            progress.advance()
    progress.finish()
    return downloaded


def main() -> int:
    setup_logging()
    session = build_session()
    output_dir = Path.cwd() / OUTPUT_DIR
    zip_path = Path.cwd() / ZIP_NAME
    output_dir.mkdir(parents=True, exist_ok=True)

    if CONVERT_RESMI_GAZETE_HTML:
        try:
            import weasyprint  # noqa: F401
        except ImportError:
            logger.error("WeasyPrint bulunamadı. Kurulum: pip install weasyprint")
            return 4

    logger.info("Başlangıç sayfası alınıyor: %s", START_URL)
    try:
        response = request_with_retries(session, "GET", START_URL)
    except requests.RequestException as exc:
        logger.error("Ana sayfa alınamadı: %s", exc)
        return 1

    html = response.text
    final_url = normalize_url(response.url)
    response.close()

    seed_pdfs, seed_crawl = extract_sartname_links(html, final_url)
    resmigazete_pages = sorted(url for url in seed_crawl if is_resmigazete_html(url))
    logger.info(
        "Ana sayfada %s doğrudan PDF, %s taranacak alt bağlantı, %s Resmi Gazete HTML sayfası",
        len(seed_pdfs),
        len(seed_crawl),
        len(resmigazete_pages),
    )

    targets = resolve_pdf_targets(session, seed_pdfs, seed_crawl)
    logger.info("Toplam %s doğrudan PDF indirilecek", len(targets))

    downloaded_native: list[Path] = []
    if targets:
        downloaded_native = download_all_pdfs(session, targets, output_dir)

    html_targets: list[HtmlConvertTarget] = []
    converted_html: list[Path] = []
    if CONVERT_RESMI_GAZETE_HTML:
        html_targets = html_convert_targets(seed_crawl, output_dir)
        logger.info("HTML→PDF dönüştürülecek %s Resmi Gazete sayfası", len(html_targets))
        if html_targets:
            converted_html = convert_all_html_pages(session, html_targets, output_dir)

    all_downloaded = downloaded_native + converted_html
    if not all_downloaded:
        logger.error("Hiç PDF oluşturulamadı veya indirilemedi.")
        return 3

    create_zip(output_dir, zip_path)

    print("\nÖzet")
    print(f"  PDF klasörü      : {output_dir.resolve()}")
    print(f"  ZIP dosyası      : {zip_path.resolve()}")
    print(f"  Doğrudan PDF      : {len(downloaded_native)}")
    print(f"  HTML'den üretilen : {len(converted_html)}")
    print(f"  Toplam            : {len(all_downloaded)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
