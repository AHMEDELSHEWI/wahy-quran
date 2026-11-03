#!/usr/bin/env python3
"""Phase 0 evidence generator for the Wahy repository.

Reads the repository at ROOT (default: current directory) and writes:
  PAGE_MAPPING.csv                       one row per mushaf page image (604 rows)
  SOURCE_MANIFEST.json                   hashes + sizes of every bundled asset
  evidence/phase0/db_audit.json          structural and integrity checks on assets/db/quran.db
  evidence/phase0/image_audit.json       dimensions and duplicate checks on assets/mushaf_pages

Nothing here calls the network. Every number in the reports is reproducible by running:
  python3 scripts/phase0/phase0_audit.py <repo-root>
"""
import csv
import glob
import hashlib
import json
import os
import re
import sqlite3
import struct
import sys
import unicodedata

ROOT = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else ".")
DB = os.path.join(ROOT, "assets/db/quran.db")
IMG_DIR = os.path.join(ROOT, "assets/mushaf_pages")
FONT = os.path.join(ROOT, "assets/fonts/AmiriQuran-Regular.ttf")
EVI = os.path.join(ROOT, "evidence/phase0")
os.makedirs(EVI, exist_ok=True)


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def jpeg_size(path):
    with open(path, "rb") as f:
        d = f.read()
    i = 2
    while i < len(d):
        if d[i] != 0xFF:
            i += 1
            continue
        m = d[i + 1]
        if m in (0xC0, 0xC1, 0xC2):
            h, w = struct.unpack(">HH", d[i + 5:i + 9])
            return [w, h]
        i += 2 + struct.unpack(">H", d[i + 2:i + 4])[0]
    return None


# Strip tashkeel and tatweel, Quranic marks, verse-number suffix, and whitespace.
MARKS = re.compile(r"[ؐ-ًؚ-ٰٟۖ-ۭ࣓-ࣿـ]")
SUFFIX = re.compile(r" [٠-٩\d]+$")
WS = re.compile(r"[\s ‌‍]+")


def skeleton(s):
    s = SUFFIX.sub("", s)
    s = unicodedata.normalize("NFD", s)
    return WS.sub("", MARKS.sub("", s))


# ---------- images ----------
imgs = {}
for p in glob.glob(os.path.join(IMG_DIR, "*.jpg")):
    n = int(os.path.basename(p)[:-4])
    imgs[n] = {"path": os.path.relpath(p, ROOT), "sha256": sha256(p),
               "bytes": os.path.getsize(p), "wh": jpeg_size(p)}
image_audit = {
    "count": len(imgs),
    "min_page": min(imgs), "max_page": max(imgs),
    "missing_pages": sorted(set(range(1, 605)) - set(imgs)),
    "extra_pages": sorted(set(imgs) - set(range(1, 605))),
    "dimension_groups": {},
    "non_standard_dimensions": [],
    "duplicate_content_groups": [],
    "total_bytes": sum(v["bytes"] for v in imgs.values()),
}
groups = {}
for n, v in imgs.items():
    groups.setdefault(str(v["wh"]), []).append(n)
image_audit["dimension_groups"] = {k: len(v) for k, v in groups.items()}
mode = max(groups, key=lambda k: len(groups[k]))
image_audit["non_standard_dimensions"] = [
    {"page": n, "wh": imgs[n]["wh"]} for n in sorted(imgs) if str(imgs[n]["wh"]) != mode]
by_hash = {}
for n, v in imgs.items():
    by_hash.setdefault(v["sha256"], []).append(n)
image_audit["duplicate_content_groups"] = [sorted(v) for v in by_hash.values() if len(v) > 1]
with open(os.path.join(EVI, "image_audit.json"), "w", encoding="utf-8") as f:
    json.dump(image_audit, f, ensure_ascii=False, indent=2)

# ---------- database ----------
con = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
cur = con.cursor()
db = {"sha256": sha256(DB), "bytes": os.path.getsize(DB),
      "tables": {t: cur.execute(f'select count(*) from "{t}"').fetchone()[0]
                 for (t,) in cur.execute("select name from sqlite_master where type='table'")}}
db["qiraat_table"] = cur.execute("select id, name_ar, variant_count from qiraat").fetchall()
db["provenance_rows"] = cur.execute("select dataset_name, source_name, license from data_provenance").fetchall()
db["ayat_riwayah_status"] = cur.execute(
    "select riwayah, verification_status, source_primary, count(*) from ayat group by 1,2,3").fetchall()
db["ayat_multi_by_qiraat"] = [
    {"qiraat_id": q, "rows": n, "distinct_ayah": d, "empty_text": e}
    for q, n, d, e in cur.execute(
        "select qiraat_id, count(*), count(distinct ayah_global_id), sum(text is null or text='') "
        "from ayat_multi group by qiraat_id")]
db["ayat_multi_non_integer_page_or_line"] = cur.execute(
    "select qiraat_id, count(*) from ayat_multi where typeof(page)<>'integer' "
    "or typeof(line_start)<>'integer' or typeof(line_end)<>'integer' group by qiraat_id").fetchall()
db["ayat_multi_non_integer_examples"] = cur.execute(
    "select qiraat_id, surah_id, ayah_number, page, line_start, line_end from ayat_multi "
    "where typeof(page)<>'integer' limit 5").fetchall()

hafs = {(s, a): (t, p, ls, le) for s, a, t, p, ls, le in cur.execute(
    "select surah_id, ayah_number, text, page, line_start, line_end from ayat_multi where qiraat_id='hafs'")}
ayat = {(s, a): t for s, a, t in cur.execute("select surah_id, ayah_number, text_uthmani from ayat")}
db["hafs_vs_ayat_skeleton_mismatch"] = [
    {"surah": s, "ayah": a} for (s, a), (t, *_r) in hafs.items()
    if skeleton(t) != skeleton(ayat.get((s, a), ""))]
db["hafs_vs_ayat_exact_mismatch_count"] = sum(
    1 for (s, a), (t, *_r) in hafs.items() if SUFFIX.sub("", t) != ayat.get((s, a)))

for q in ["shouba", "warsh", "qaloon", "doori"]:
    rows = cur.execute("select surah_id, ayah_number, text from ayat_multi where qiraat_id=?", (q,)).fetchall()
    db.setdefault("variant_vs_hafs_skeleton_equal", {})[q] = {
        "rows": len(rows),
        "equal_after_skeleton": sum(1 for s, a, t in rows if (s, a) in hafs and skeleton(t) == skeleton(hafs[(s, a)][0])),
        "exact_equal": sum(1 for s, a, t in rows if (s, a) in hafs and t == hafs[(s, a)][0]),
    }

# Page checks: hafs page column against image set and page monotonicity
pages = {}
for (s, a), (t, p, ls, le) in hafs.items():
    pages.setdefault(p, []).append((s, a))
db["hafs_pages_distinct"] = len(pages)
db["hafs_page_range"] = [min(k for k in pages if isinstance(k, int)), max(k for k in pages if isinstance(k, int))]
db["pages_without_image"] = sorted(set(k for k in pages if isinstance(k, int)) - set(imgs))
order = sorted(hafs, key=lambda k: (k[0], k[1]))
prev = None
non_monotonic = 0
for k in order:
    p = hafs[k][1]
    if isinstance(p, int) and isinstance(prev, int) and p < prev:
        non_monotonic += 1
    if isinstance(p, int):
        prev = p
db["hafs_page_non_monotonic"] = non_monotonic
con.close()

with open(os.path.join(EVI, "db_audit.json"), "w", encoding="utf-8") as f:
    json.dump(db, f, ensure_ascii=False, indent=2, default=str)

# ---------- page mapping (separate artifact, spec section 3) ----------
rows_out = []
for n in range(1, 605):
    ayahs = sorted(pages.get(n, []))
    first = f"{ayahs[0][0]}:{ayahs[0][1]}" if ayahs else ""
    last = f"{ayahs[-1][0]}:{ayahs[-1][1]}" if ayahs else ""
    rows_out.append({
        "source_pdf": "MISSING_KUWAIT_PDF_NOT_IN_CONTAINER",
        "source_document_page": f"assets/mushaf_pages/{n}.jpg",
        "printed_page_label": "",
        "canonical_madinah_1405_page": "",
        "candidate_madinah_page": n,
        "mapping_status": "UNCERTAIN",
        "visual_hash": imgs[n]["sha256"] if n in imgs else "",
        "text_verification_status": "NOT_VERIFIED",
        "reviewer": "",
        "db_first_ayah": first,
        "db_last_ayah": last,
        "db_ayah_count": len(ayahs),
        "image_wh": f"{imgs[n]['wh'][0]}x{imgs[n]['wh'][1]}" if n in imgs else "",
        "notes": "",
    })
with open(os.path.join(ROOT, "PAGE_MAPPING.csv"), "w", encoding="utf-8", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(rows_out[0].keys()))
    w.writeheader()
    w.writerows(rows_out)

# ---------- source manifest with hashes ----------
manifest = {
    "generated_by": "scripts/phase0/phase0_audit.py",
    "assets": {
        "assets/db/quran.db": {"sha256": sha256(DB), "bytes": os.path.getsize(DB)},
        "assets/fonts/AmiriQuran-Regular.ttf": {"sha256": sha256(FONT), "bytes": os.path.getsize(FONT)},
        "assets/mushaf_pages/*.jpg": {"count": len(imgs), "total_bytes": image_audit["total_bytes"]},
    },
}
with open(os.path.join(ROOT, "SOURCE_MANIFEST.json"), "w", encoding="utf-8") as f:
    json.dump(manifest, f, ensure_ascii=False, indent=2)

print("ok: pages", len(rows_out), "| db hash", db["sha256"][:12],
      "| hafs/ayat exact mismatches", db["hafs_vs_ayat_exact_mismatch_count"],
      "| skeleton mismatches", len(db["hafs_vs_ayat_skeleton_mismatch"]),
      "| non-integer page rows", sum(x[1] for x in db["ayat_multi_non_integer_page_or_line"]))
