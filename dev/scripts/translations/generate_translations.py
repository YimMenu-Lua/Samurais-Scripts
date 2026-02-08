# Samurai's Scripts Translation Generator
#
# Usage:
#	python generate_translations.py				: normal run (just hit F5 if in VS Code and have Python Debugger installed)
#	python generate_translations.py --dry-run	: don't write files, just show diff summary (CLI)
#	python generate_translations.py --diff		: print diff summary only (CLI)
#
#	CI Run: Don't pass any arguments


import os
import sys
import json
import re
import subprocess
import importlib.util
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Dict


for module in {"slpp", "langcodes[data]", "deep_translator", "alive_progress", "langcodes"}:
    if importlib.util.find_spec(module) is None:
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", module])
        except subprocess.CalledProcessError:
            print(f"Failed to install {module}. Run as administrator.")
            sys.exit(1)
 

from slpp import slpp as Lua
from alive_progress import alive_bar
from deep_translator import GoogleTranslator
from langcodes import Language as Lang
from argparse import ArgumentParser as ArgParser
import deep_translator.exceptions
import threading


PARENT_PATH = Path(__file__).resolve().parent
LUA_PATH = PARENT_PATH.parent.parent / "SSV2/includes/lib/translations"
HASHMAP_PATH = LUA_PATH / "__hashmap.json"
MAX_WORKERS = min(16, (os.cpu_count() or 2) * 4)
TRANSLATOR_LOCK = threading.Lock()
TRANSLATORS: Dict[str, GoogleTranslator] = {}
FAILED_LANGS = set()
HASHMAP = {}


if HASHMAP_PATH.exists():
    with open(HASHMAP_PATH, "r", encoding="utf-8") as f:
        try:
            HASHMAP = json.load(f)
        except Exception:
            HASHMAP = {}


def joaat(key: str) -> int:
    key = key.lower()
    hash = 0

    for i in range(0, len(key)):
        hash += ord(key[i])
        hash += (hash << 10)
        hash = hash & 0xFFFFFFFF
        hash = hash ^ (hash >> 6)

    hash += (hash << 3)
    hash = hash & 0xFFFFFFFF
    hash = hash ^ (hash >> 11)
    hash += (hash << 15)
    hash = hash & 0xFFFFFFFF

    return hash


def read_lua_table(path: str):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    match = re.search(r"return\s*(\{.*\})", content, re.DOTALL)
    if not match:
        raise RuntimeError(f"Could not find a valid Lua table in {path}")
    return Lua.decode(match.group(1))


def write_lua_table(path: str, table: dict):
    newdata = table

    if os.path.exists(path):
        existing = read_lua_table(path)
        if existing:
            for k, v in table.items():
                if k not in existing or existing[k] != v:
                    existing[k] = v
            newdata = existing

    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("return ")
        f.write(Lua.encode(newdata))
        f.write("\n")


def get_lang_name(iso: str) -> str:
    try:
        name = Lang.get(iso).display_name()
        if not name or "Unknown" in name:
            return f"({iso})"
        return name
    except Exception:
        try:
            name = Lang.get(iso[:2]).display_name()
            if not name or "Unknown" in name:
                return f"({iso})"
            return name
        except Exception:
            return f"({iso})"


# def create_translator(iso: str):
# 	iso_norm = iso.strip()
# 	return GoogleTranslator(source="en", target=iso_norm)


# def get_translator(iso: str):
# 	iso = iso.strip()
# 	if iso in FAILED_LANGS:
# 		return None

# 	with TRANSLATOR_LOCK:
# 		if iso in TRANSLATORS:
# 			return TRANSLATORS[iso]

# 		try:
# 			tr = create_translator(iso)
# 			TRANSLATORS[iso] = tr
# 			return tr
# 		except deep_translator.exceptions.LanguageNotSupportedException:
# 			FAILED_LANGS.add(iso)
# 			return None
# 		except Exception:
# 			FAILED_LANGS.add(iso)
# 			return None


# def translate_text(iso: str, text: str) -> str:
# 	tr = get_translator(iso)
# 	if tr is not None:
# 		try:
# 			return tr.translate(text)
# 		except deep_translator.exceptions.LanguageNotSupportedException:
# 			FAILED_LANGS.add(iso)
# 		except Exception:
# 			pass

# 	short = iso[:2]
# 	tr2 = get_translator(short)
# 	if tr2 is not None:
# 		try:
# 			return tr2.translate(text)
# 		except Exception:
# 			pass

# 	return text

def translate_text(iso: str, text: str) -> str:
    try:
        return GoogleTranslator(source="en", target=iso).translate(text)
    except Exception:
        pass

    try:
        return GoogleTranslator(source="en", target=iso[:2]).translate(text)
    except Exception:
        return text


def write_hashmap():
    print("Updating hash map...")
    with open(HASHMAP_PATH, "w", encoding="utf-8", newline="\n") as f:
        json.dump(HASHMAP, f, indent=4)


def generate_translations(dry_run: bool = False, diff_only: bool = False):
    en_keys_path = LUA_PATH / "en-US.lua"
    locales_path = LUA_PATH / "__locales.lua"

    if not os.path.exists(LUA_PATH):
        raise RuntimeError("Base translations directory not found!")

    if not os.path.exists(en_keys_path):
        raise RuntimeError("Translations file not found!")

    if not os.path.exists(locales_path):
        raise RuntimeError("Supported languages file not found!")

    locales = read_lua_table(locales_path)
    labels = read_lua_table(en_keys_path)
    
    print("Checking hash map...")
    key_set = [k for k, v in labels.items() if HASHMAP.get(k) != joaat(v)]

    for k, v in labels.items():
        if k not in HASHMAP:
            HASHMAP[k] = joaat(v)

    if not key_set:
        print("Nothing changed.")
        if not dry_run:
            write_hashmap()
        return {"new": [], "updated": [], "skipped": list(labels.keys())}

    translations = {}
    target_locales = [d for d in locales if d.get("iso") != "en-US"]
    total_tasks = len(target_locales) * len(key_set)
    workers = min(MAX_WORKERS, max(1, int(total_tasks / 4)))
    workers = min(workers, MAX_WORKERS)

    with ThreadPoolExecutor(max_workers=workers) as exec:
        futures = {}
        with alive_bar(total_tasks, title="Translating", force_tty=True) as bar:
            for locale in target_locales:
                iso = locale["iso"]
                fname = f"{iso}.lua"
                translations.setdefault(fname, {})

                for label in key_set:
                    text = labels[label]
                    fut = exec.submit(translate_text, iso, text)
                    futures[fut] = (iso, label, text, fname)

            for fut in as_completed(futures):
                iso, label, orig_text, fname = futures[fut]
                try:
                    translated = fut.result()
                except Exception:
                    translated = orig_text
                translations[fname][label] = translated
                bar()

    new_labels = []
    updated_labels = []
    for label in key_set:
        prev_hash = HASHMAP.get(label)
        new_hash = joaat(labels[label])
        if prev_hash is None:
            new_labels.append(label)
        elif prev_hash != new_hash:
            updated_labels.append(label)
        HASHMAP[label] = new_hash

    summary = {
        "new": new_labels,
        "updated": updated_labels,
        "skipped": [k for k in labels.keys() if k not in key_set],
        "languages": [d["iso"] for d in target_locales],
    }

    if diff_only or dry_run:
        print("\nSummary:")
        print(f"\t- Languages to generate: {len(target_locales)}")
        print(f"\t- Keys changed: {len(key_set)} (new: {len(new_labels)}, updated: {len(updated_labels)})")
        if new_labels:
            print("\nNew labels:")
            for l in new_labels:
                print(f"\t- {l}")
        if updated_labels:
            print("\nUpdated labels:")
            for l in updated_labels:
                print(f"\t - {l}")

        if not dry_run:
            write_hashmap()
        return summary

    with alive_bar(len(translations), title="Writing locale files", force_tty=True) as bar2:
        for fname, content in translations.items():
            write_lua_table(os.path.join(LUA_PATH, fname), content)
            bar2()

    write_hashmap()
    print("\nDone. Files written for languages:", ", ".join([d["iso"] for d in target_locales]))
    return summary


def main():
    parser = ArgParser(description="Generate translations from SSV2/includes/lib/translations/en-US.lua")
    parser.add_argument("--dry-run", action="store_true", help="Don't write files; print diff summary")
    parser.add_argument("--diff", action="store_true", help="Print diff summary only (no writes)")
    args = parser.parse_args()

    try:
        generate_translations(dry_run=args.dry_run, diff_only=args.diff)
    except Exception as e:
        print("ERROR:", e)
        sys.exit(1)

if __name__ == "__main__":
    main()
