#!/usr/bin/env python3
"""
Normalise Markdown prayer files into JSON.

Produces:
  data/<category-slug>/prayers.json   — prayers for that category
  data/prayers.json                   — combined index of all prayers

Text content is encoded as DatoCMS DAST (Document Abstract Syntax Tree).
Each blank-line-separated paragraph becomes one `paragraph` node.
"""

import json
import re
from pathlib import Path

DATA_DIR = Path(__file__).parent.parent / "data"

CATEGORY_NAMES: dict[str, str] = {
    "andro-manelanelana": "Andro manelanelana",
    "ankizy": "Ankizy",
    "antenimiera-am-panahy": "Antenimiera am-panahy",
    "fahafatesana": "Fahafatesana",
    "fahamarinana": "Fahamarinana",
    "fahasitranana": "Fahasitranana",
    "famaranana-ny-fivoarian-ny-antenimiera-am-panahy": "Famaranana ny fivoarian'ny Antenimiera am-panahy",
    "famelan-keloka": "Famelan-keloka",
    "fampianarana": "Fampianarana",
    "fanambadiana": "Fanambadiana",
    "fanampiana-sy-fanatrehana": "Fanampiana sy fanatrehana",
    "fiarovana": "Fiarovana",
    "fiderana-sy-fisaorana": "Fiderana sy fisaorana",
    "fifadian-kanina": "Fifadian-kanina",
    "firaisankina": "Firaisankina",
    "fivahinianana-masina": "Fivahinianana masina",
    "fivoriana": "Fivoriana",
    "hariva": "Hariva",
    "mangiran-dratsy": "Mangiran-dratsy",
    "maraina": "Maraina",
    "martiora": "Martiora",
    "naw-ruz": "Naw-Rúz",
    "sedra-sy-fahasahiranana": "Sedra sy fahasahiranana",
    "takelak-i-ahmad": "Takelak'i Ahmad",
    "takela-pahatsiarovana": "Takela pahatsiarovana",
    "toetra-ara-panahy": "Toetra ara-panahy",
    "vavaka-fahasitranana-lava": "Vavaka fahasitranana lava",
    "vavaka-ho-an-ny-firenen-drehetra": "Vavaka ho an'ny firenena drehetra",
}


def normalise_quotes(s: str) -> str:
    return s.replace("‘", "'").replace("’", "'").replace("“", '"').replace("”", '"')


def make_title(text: str, max_len: int = 60) -> str:
    """Truncate the first paragraph to a readable title, breaking at a word boundary."""
    first_para = re.split(r"\n{2,}", text.strip())[0]
    first_para = " ".join(first_para.split())
    if len(first_para) <= max_len:
        return first_para
    truncated = first_para[:max_len].rsplit(" ", 1)[0]
    return truncated + "…"


def to_dast(text: str) -> dict:
    """Convert plain text (blank-line-separated paragraphs) to DatoCMS DAST."""
    raw_paragraphs = re.split(r"\n{2,}", text.strip())
    nodes = []
    for para in raw_paragraphs:
        value = " ".join(para.split())  # collapse internal whitespace
        if value:
            nodes.append({
                "type": "paragraph",
                "children": [{"type": "span", "value": value}],
            })
    return {
        "schema": "dast",
        "document": {"type": "root", "children": nodes},
    }


def parse_prayer_file(path: Path, category_slug: str, index: int) -> dict:
    raw = normalise_quotes(path.read_text(encoding="utf-8"))

    # Strip the H1 title line
    lines = raw.splitlines()
    if lines and lines[0].startswith("# "):
        lines = lines[1:]
    body = "\n".join(lines).strip()

    # Extract trailing attribution (—Author)
    author = None
    author_match = re.search(r"\n—(.+)$", body)
    if author_match:
        author = author_match.group(1).strip()
        body = body[: author_match.start()].strip()

    # Extract optional leading context note enclosed in parentheses on its own block
    notes = None
    context_match = re.match(r"^\((.+?)\)\.\s*\n", body, re.DOTALL)
    if context_match:
        notes = context_match.group(1).strip()
        body = body[context_match.end():].strip()

    prayer_id = f"{category_slug}-{index:02d}"

    return {
        "id": prayer_id,
        "title": make_title(body),
        "category": category_slug,
        "author": author,
        "notes": notes,
        "transliteration": None,
        "content": to_dast(body),
    }


def process_category(folder: Path) -> list[dict]:
    slug = re.sub(r"^\d+-", "", folder.name)

    md_files = sorted(folder.glob("vavaka-*.md"))
    prayers = []
    for i, md_file in enumerate(md_files, start=1):
        prayers.append(parse_prayer_file(md_file, slug, i))

    if prayers:
        out = folder / "prayers.json"
        out.write_text(json.dumps(prayers, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"  wrote {out.relative_to(DATA_DIR.parent)} ({len(prayers)} prayers)")

    return prayers


def main() -> None:
    all_prayers: list[dict] = []

    for folder in sorted(f for f in DATA_DIR.iterdir() if f.is_dir()):
        all_prayers.extend(process_category(folder))

    # Global index: categories with lightweight prayer stubs (no content)
    categories: dict[str, dict] = {}
    for prayer in all_prayers:
        slug = prayer["category"]
        if slug not in categories:
            categories[slug] = {
                "category": slug,
                "name": CATEGORY_NAMES.get(slug, slug),
                "prayers": [],
            }
        categories[slug]["prayers"].append({
            "id": prayer["id"],
            "title": prayer["title"],
            "author": prayer["author"],
        })

    index = {"categories": list(categories.values())}
    combined = DATA_DIR / "index.json"
    combined.write_text(json.dumps(index, ensure_ascii=False, indent=2), encoding="utf-8")
    total = sum(len(c["prayers"]) for c in index["categories"])
    print(f"\n  wrote data/index.json ({len(index['categories'])} categories, {total} prayers)")


if __name__ == "__main__":
    main()
