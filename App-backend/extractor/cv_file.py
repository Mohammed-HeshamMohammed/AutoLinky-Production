"""
CV files from the app: read with a hard size cap, identify the real type from the file's first bytes
(never from its name or the declared Content-Type) and pull the text out. PDF (pypdf) and Word .docx only.

Hostile files are expected:
  - size: counted while reading; the read stops at MAX_BYTES + 1
  - .docx is a zip: entry count and unzipped XML size are capped (zip bombs), and the XML is never given
    to an XML parser (no entity tricks): the text is taken from the <w:t> elements with a regex
  - PDF: only the first MAX_PDF_PAGES pages are read; encrypted files are refused unless they open
    without a password; any parser error is "unreadable"

Before the text goes to the AI, e-mails, phone numbers and links are replaced (redact_contacts): the
analysis does not need them.
"""

import hashlib
import html
import io
import logging
import re
import unicodedata
import zipfile
from dataclasses import dataclass
from typing import List, Optional

MAX_BYTES = 4 * 1024 * 1024        # Vercel accepts request bodies up to 4.5 MB
MAX_PDF_PAGES = 10
MAX_ZIP_ENTRIES = 500
MAX_DOCX_XML = 8 * 1024 * 1024     # word/document.xml once unzipped
MAX_TEXT_CHARS = 40_000
MIN_TEXT_CHARS = 200               # less than this: a scanned (image) PDF, or nearly empty

PDF_MIME = "application/pdf"
DOCX_MIME = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
MIME = {"pdf": PDF_MIME, "docx": DOCX_MIME}

logging.getLogger("pypdf").setLevel(logging.ERROR)


class CVFileError(Exception):
    """A file the API refuses. `code` is a stable value the app turns into a message."""

    def __init__(self, code: str, status: int = 422):
        super().__init__(code)
        self.code, self.status = code, status


@dataclass(frozen=True)
class CVText:
    file_type: str          # "pdf" | "docx"
    text: str
    pages: Optional[int]
    size: int
    sha256: str


# ── reading the upload ──────────────────────────────────────────────────────

async def read_upload(request, limit: int = MAX_BYTES) -> bytes:
    """The request body, refused (413) as soon as it is bigger than limit."""
    declared = request.headers.get("content-length")
    if declared and declared.isdigit() and int(declared) > limit:
        raise CVFileError("cv_too_large", 413)
    chunks, size = [], 0
    async for chunk in request.stream():
        size += len(chunk)
        if size > limit:
            raise CVFileError("cv_too_large", 413)
        chunks.append(chunk)
    if size == 0:
        raise CVFileError("cv_empty", 400)
    return b"".join(chunks)


def detect_type(data: bytes) -> str:
    if data.startswith(b"%PDF-"):
        return "pdf"
    if data.startswith(b"PK\x03\x04"):
        return "docx"   # confirmed when the zip is opened (word/document.xml)
    raise CVFileError("cv_bad_type", 415)


# ── text extraction ─────────────────────────────────────────────────────────

def _pdf_text(data: bytes):
    from pypdf import PdfReader

    try:
        reader = PdfReader(io.BytesIO(data))
        if reader.is_encrypted:
            try:
                opened = reader.decrypt("")
            except Exception:
                opened = 0
            if not opened:
                raise CVFileError("cv_encrypted")
        pages = len(reader.pages)
        parts, total = [], 0
        for i in range(min(pages, MAX_PDF_PAGES)):
            part = reader.pages[i].extract_text() or ""
            parts.append(part)
            total += len(part)
            if total > MAX_TEXT_CHARS:
                break
        return "\n".join(parts), pages
    except CVFileError:
        raise
    except Exception:
        raise CVFileError("cv_unreadable")


MAX_LINKS = 20
_DOCX_LINK = re.compile(r'Target="(https?://[^"]{4,300})"[^>]*TargetMode="External"|'
                        r'TargetMode="External"[^>]*Target="(https?://[^"]{4,300})"')


def extract_links(data: bytes, file_type: str) -> List[str]:
    """The web links of a CV that only show as words ("LinkedIn", "GitHub"): a PDF's link annotations, a Word
    file's hyperlinks. Nothing found / unreadable: []. Never raises."""
    found: List[str] = []
    try:
        if file_type == "pdf":
            from pypdf import PdfReader

            reader = PdfReader(io.BytesIO(data))
            if reader.is_encrypted and not reader.decrypt(""):
                return []
            for page in reader.pages[:3]:                 # contacts are at the top
                for annot in page.get("/Annots") or []:
                    action = (annot.get_object() or {}).get("/A") or {}
                    uri = action.get("/URI") if hasattr(action, "get") else None
                    if isinstance(uri, (str, bytes)):
                        found.append(uri.decode("latin-1") if isinstance(uri, bytes) else str(uri))
        elif file_type == "docx":
            with zipfile.ZipFile(io.BytesIO(data)) as zf:
                info = next((i for i in zf.infolist() if i.filename == "word/_rels/document.xml.rels"), None)
                if info is None or info.file_size > 1_000_000:
                    return []
                xml = zf.read(info).decode("utf-8", errors="replace")
            found = [html.unescape(a or b) for a, b in _DOCX_LINK.findall(xml)]
    except Exception:
        return []
    clean = [u.strip() for u in found if u.strip().lower().startswith(("http://", "https://")) and len(u) <= 300]
    return list(dict.fromkeys(clean))[:MAX_LINKS]


_DOCX_TOKEN = re.compile(r"<w:t(?:\s[^>]*)?>([^<]*)</w:t>|<w:(tab|br|cr)\b[^>]*/>|</w:p>")


def _docx_text(data: bytes):
    try:
        with zipfile.ZipFile(io.BytesIO(data)) as zf:
            infos = zf.infolist()
            if len(infos) > MAX_ZIP_ENTRIES:
                raise CVFileError("cv_unreadable")
            info = next((i for i in infos if i.filename == "word/document.xml"), None)
            if info is None:
                raise CVFileError("cv_bad_type", 415)   # a zip, but not a Word document
            if info.file_size > MAX_DOCX_XML:
                raise CVFileError("cv_unreadable")
            with zf.open(info) as f:
                raw = f.read(MAX_DOCX_XML + 1)
    except CVFileError:
        raise
    except Exception:   # bad zip, encrypted zip, CRC errors, ...
        raise CVFileError("cv_unreadable")
    if len(raw) > MAX_DOCX_XML:
        raise CVFileError("cv_unreadable")
    xml = raw.decode("utf-8", errors="replace")
    out = []
    for m in _DOCX_TOKEN.finditer(xml):
        if m.group(1) is not None:
            out.append(html.unescape(m.group(1)))
        elif m.group(2) == "tab":
            out.append(" ")
        else:
            out.append("\n")
        if len(out) > 200_000:
            break
    return "".join(out), None


_CONTROL = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")


def clean_text(text: str) -> str:
    """Single spaces inside lines, no empty lines, no control characters, at most MAX_TEXT_CHARS."""
    text = _CONTROL.sub(" ", unicodedata.normalize("NFC", text or ""))
    lines = (" ".join(line.split()) for line in text.splitlines())
    return "\n".join(line for line in lines if line)[:MAX_TEXT_CHARS]


def extract(data: bytes) -> CVText:
    file_type = detect_type(data)
    text, pages = _pdf_text(data) if file_type == "pdf" else _docx_text(data)
    text = clean_text(text)
    if len(text) < MIN_TEXT_CHARS:
        raise CVFileError("cv_no_text")
    return CVText(file_type, text, pages, len(data), hashlib.sha256(data).hexdigest())


# ── names and privacy ───────────────────────────────────────────────────────

def clean_file_name(name: Optional[str], file_type: str) -> str:
    """For display only: no folders, no control characters, short, with the real extension."""
    base = re.split(r"[\\/]", name or "")[-1]
    base = "".join(c for c in unicodedata.normalize("NFC", base) if unicodedata.category(c)[0] != "C")
    stem = re.sub(r"\.(pdf|docx?)$", "", " ".join(base.split()), flags=re.IGNORECASE).strip(" .")
    return f"{stem[:100] or 'CV'}.{file_type}"


_EMAIL = re.compile(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)+")
_LINK = re.compile(r"(?:https?://|www\.)\S+|\b[\w-]+\.(?:com|net|org|io|me|dev)/\S*", re.IGNORECASE)
_PHONE = re.compile(r"(?<![\w+])\+?\(?\d[\d\s().\-/]{6,}\d(?!\w)")
_YEAR = re.compile(r"(?:19|20)\d\d")


def _phone(m: "re.Match") -> str:
    s = m.group(0)
    groups = re.findall(r"\d+", s)
    digits = sum(len(g) for g in groups)
    if not 9 <= digits <= 15 or all(len(g) == 4 and _YEAR.fullmatch(g) for g in groups):
        return s    # dates ("2018 - 2022"), not a phone number
    return "[phone]"


def redact_contacts(text: str) -> str:
    text = _EMAIL.sub("[email]", text)
    text = _LINK.sub("[link]", text)
    return _PHONE.sub(_phone, text)
