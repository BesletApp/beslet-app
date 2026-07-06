"""
Bible Text Asset Preparation Script
=====================================
Takes raw Amharic Protestant + NET Bible JSON sources and produces
compressed per-book JSON files for the Beslet app.

Usage:
    python scripts/prepare_bible_assets.py \
        --amharic path/to/amharic_bible.json \
        --net path/to/net_bible.json \
        --output assets/bible

Input JSON format expected:
    amharic.json: { "genesis": { "1": [ {"verse":1, "text":"..."}, ... ], ... }, ... }
    net.json:     { "genesis": { "1": [ {"verse":1, "text":"..."}, ... ], ... }, ... }

Output:
    assets/bible/genesis.json.gz
    assets/bible/exodus.json.gz
    ... (one gzipped JSON file per book)

Each output file format:
    { "chapters": { "1": [ {"v":1, "am":"...", "en":"..."}, ... ], ... } }
"""

import json
import gzip
import os
import sys
import argparse
from pathlib import Path


# Map common book name variations to the app's book IDs
BOOK_ID_MAP = {
    "genesis": "genesis", "exodus": "exodus", "leviticus": "leviticus",
    "numbers": "numbers", "deuteronomy": "deuteronomy",
    "joshua": "joshua", "judges": "judges", "ruth": "ruth",
    "1 samuel": "1_samuel", "2 samuel": "2_samuel",
    "1 kings": "1_kings", "2 kings": "2_kings",
    "1 chronicles": "1_chronicles", "2 chronicles": "2_chronicles",
    "ezra": "ezra", "nehemiah": "nehemiah", "esther": "esther",
    "job": "job", "psalms": "psalms", "psalm": "psalms",
    "proverbs": "proverbs", "ecclesiastes": "ecclesiastes",
    "song of solomon": "song_of_solomon", "song of songs": "song_of_solomon",
    "isaiah": "isaiah", "jeremiah": "jeremiah",
    "lamentations": "lamentations",
    "ezekiel": "ezekiel",
    "daniel": "daniel",
    "hosea": "hosea", "joel": "joel", "amos": "amos",
    "obadiah": "obadiah", "jonah": "jonah", "micah": "micah",
    "nahum": "nahum", "habakkuk": "habakkuk",
    "zephaniah": "zephaniah", "haggai": "haggai",
    "zechariah": "zechariah", "malachi": "malachi",
    "matthew": "matthew",
    "mark": "mark",
    "luke": "luke",
    "john": "john",
    "acts": "acts",
    "romans": "romans",
    "1 corinthians": "1_corinthians", "2 corinthians": "2_corinthians",
    "galatians": "galatians", "ephesians": "ephesians",
    "philippians": "philippians", "colossians": "colossians",
    "1 thessalonians": "1_thessalonians", "2 thessalonians": "2_thessalonians",
    "1 timothy": "1_timothy", "2 timothy": "2_timothy",
    "titus": "titus", "philemon": "philemon",
    "hebrews": "hebrews",
    "james": "james",
    "1 peter": "1_peter", "2 peter": "2_peter",
    "1 john": "1_john", "2 john": "2_john", "3 john": "3_john",
    "jude": "jude",
    "revelation": "revelation", "revelations": "revelation",
}


def normalize_book_name(name: str) -> str | None:
    """Normalize a book name to the app's book ID."""
    key = name.strip().lower()
    # Try direct lookup
    if key in BOOK_ID_MAP:
        return BOOK_ID_MAP[key]
    # Try with ' of ' replacements
    key = key.replace("song of solomon", "song_of_solomon")
    return BOOK_ID_MAP.get(key)


def merge_books(
    amharic_data: dict, net_data: dict, book_ids: list[str]
) -> dict[str, dict]:
    """Merge Amharic and NET Bible texts into per-book format."""
    merged = {}
    for book_id in book_ids:
        am_book = amharic_data.get(book_id, {})
        en_book = net_data.get(book_id, {})
        chapters = {}
        all_chapter_nums = set(list(am_book.keys()) + list(en_book.keys()))
        for ch_str in sorted(all_chapter_nums, key=lambda x: int(x)):
            am_ch = am_book.get(ch_str, [])
            en_ch = en_book.get(ch_str, [])
            verses = []
            max_len = max(len(am_ch) if isinstance(am_ch, list) else 0,
                          len(en_ch) if isinstance(en_ch, list) else 0)
            for i in range(max_len):
                v = i + 1  # verses are 1-indexed
                am_text = ""
                en_text = ""
                if isinstance(am_ch, list) and i < len(am_ch):
                    if isinstance(am_ch[i], dict):
                        am_text = am_ch[i].get("text", "")
                    elif isinstance(am_ch[i], str):
                        am_text = am_ch[i]
                if isinstance(en_ch, list) and i < len(en_ch):
                    if isinstance(en_ch[i], dict):
                        en_text = en_ch[i].get("text", "")
                    elif isinstance(en_ch[i], str):
                        en_text = en_ch[i]
                if am_text or en_text:
                    verses.append({"v": v, "am": am_text, "en": en_text})
            if verses:
                chapters[ch_str] = verses
        merged[book_id] = {"chapters": chapters}
    return merged


def write_book_files(merged: dict, output_dir: str, book_ids: list[str]):
    """Write one gzipped JSON file per book."""
    os.makedirs(output_dir, exist_ok=True)
    for book_id in book_ids:
        data = merged.get(book_id, {"chapters": {}})
        json_bytes = json.dumps(data, ensure_ascii=False).encode("utf-8")
        out_path = os.path.join(output_dir, f"{book_id}.json.gz")
        with gzip.open(out_path, "wb", compresslevel=9) as f:
            f.write(json_bytes)
        size_kb = os.path.getsize(out_path) / 1024
        chapter_count = len(data.get("chapters", {}))
        print(f"  {book_id:20s} {size_kb:6.1f} KB  ({chapter_count} chapters)")


def generate_sample_assets(output_dir: str):
    """
    Generate minimal sample files so the app can display something
    before the full Bible text is ready.
    """
    sample = {
        "genesis": {
            "chapters": {
                "1": [
                    {"v": 1, "am": "መጀመሪያ ላይ እግዚአብሔር ሰማይንና ምድርን ፈጠረ።",
                     "en": "In the beginning God created the heavens and the earth."},
                    {"v": 2, "am": "ምድርም ባድማና ባዶ ነበረች፥ ጨለማም በጥልቁ ላይ ነበረ፤ የእግዚአብሔርም መንፈስ በውኃ ላይ ሲንቀሳቀስ ነበር።",
                     "en": "The earth was without form and void, and darkness was over the face of the deep. And the Spirit of God was hovering over the face of the waters."},
                ]
            }
        },
        "matthew": {
            "chapters": {
                "1": [
                    {"v": 1, "am": "የኢየሱስ ክርስቶስ የዳዊት ልጅ የአብርሃም ልጅ የሆነው የትውልድ ሐሳብ።",
                     "en": "The book of the genealogy of Jesus Christ, the son of David, the son of Abraham."},
                ]
            }
        },
        "psalms": {
            "chapters": {
                "1": [
                    {"v": 1, "am": "ክፉ ሰዎች ምክር የማይከተል ፣ በኃጢአተኞች መንገድ የማይቆም ፣ በሌጦችም ወንበር የማይቀመጥ ሰው ብፁዕ ነው።",
                     "en": "Blessed is the man who walks not in the counsel of the wicked, nor stands in the way of sinners, nor sits in the seat of scoffers."},
                ]
            }
        },
        "john": {
            "chapters": {
                "1": [
                    {"v": 1, "am": "በመጀመሪያ ቃል ነበረ፥ ቃልም በእግዚአብሔር ዘንድ ነበረ፥ ቃልም እግዚአብሔር ነበረ።",
                     "en": "In the beginning was the Word, and the Word was with God, and the Word was God."},
                ]
            }
        }
    }

    write_book_files(sample, output_dir, list(sample.keys()))
    total = sum(
        os.path.getsize(os.path.join(output_dir, f"{bid}.json.gz"))
        for bid in sample
    )
    print(f"\nSample assets: {total / 1024:.1f} KB total")
    print("Replace these with full Bible text when ready.")


def main():
    parser = argparse.ArgumentParser(description="Prepare Bible text assets")
    parser.add_argument("--amharic", help="Path to Amharic Bible JSON")
    parser.add_argument("--net", help="Path to NET Bible JSON")
    parser.add_argument("--output", default="assets/bible",
                        help="Output directory")
    parser.add_argument("--sample", action="store_true",
                        help="Generate sample assets (for testing)")
    args = parser.parse_args()

    if args.sample:
        print("Generating sample Bible text assets...")
        generate_sample_assets(args.output)
        print("\nDone. Remember to add 'assets/bible/' to pubspec.yaml assets section.")
        return

    if not args.amharic or not args.net:
        print("Error: Both --amharic and --net are required (or use --sample)")
        sys.exit(1)

    print(f"Loading Amharic Bible from: {args.amharic}")
    with open(args.amharic, "r", encoding="utf-8") as f:
        amharic = json.load(f)

    print(f"Loading NET Bible from: {args.net}")
    with open(args.net, "r", encoding="utf-8") as f:
        net = json.load(f)

    # Determine book IDs from the intersection of both sources
    book_ids = sorted(set(amharic.keys()) & set(net.keys()),
                      key=lambda x: list(BOOK_ID_MAP.values()).index(x)
                      if x in BOOK_ID_MAP.values() else 999)

    if not book_ids:
        print("Warning: No matching book IDs found between sources.")
        print("Available Amharic books:", list(amharic.keys())[:10])
        print("Available NET books:", list(net.keys())[:10])
        # Fall back to all known book IDs
        book_ids = [v for v in BOOK_ID_MAP.values() if v in amharic or v in net]

    print(f"Merging {len(book_ids)} books...")
    merged = merge_books(amharic, net, book_ids)

    total_chapters = sum(len(b.get("chapters", {})) for b in merged.values())
    print(f"Total chapters processed: {total_chapters}")

    print(f"\nWriting {len(book_ids)} book files to {args.output}/")
    write_book_files(merged, args.output, book_ids)

    total_size = sum(
        os.path.getsize(os.path.join(args.output, f"{bid}.json.gz"))
        for bid in book_ids
    )
    print(f"\nTotal: {total_size / 1024 / 1024:.1f} MB")
    print("Done!")


if __name__ == "__main__":
    main()
