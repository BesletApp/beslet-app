import json
import io

# Consistent source attribution per section kind in the curated study bank.
# - whatTextSays / biblicalConnections / reflection are plain readings or
#   cross-references: the Scripture text itself.
# - setting / context frame the passage from received knowledge.
# - meaningBackground and whatCanBeUnderstood blend the text with the
#   historic reading (tiers like "widely read" are received teaching).
KIND_TO_SOURCES = {
    "setting": ["tradition"],
    "context": ["tradition"],
    "whatTextSays": ["scripture"],
    "meaningBackground": ["scripture", "tradition"],
    "biblicalConnections": ["scripture"],
    "whatCanBeUnderstood": ["scripture", "tradition"],
    "reflection": ["scripture"],
}

path = "assets/data/study.json"
with io.open(path, encoding="utf-8") as f:
    data = json.load(f)

count = 0
for entry in data["entries"]:
    for section in entry["sections"]:
        kind = section["kind"]
        if kind not in KIND_TO_SOURCES:
            raise SystemExit(f"unknown kind {kind} in {entry['id']}")
        section["sourceIds"] = KIND_TO_SOURCES[kind]
        count += 1

with io.open(path, "w", encoding="utf-8", newline="\n") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")

print(f"wired sourceIds on {count} sections across {len(data['entries'])} entries")