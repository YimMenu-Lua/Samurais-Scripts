# Samurai's Scripts Script Global/Local Offset Updater
#
# Usage:
#	python update_offsets.py			: normal run (just hit F5 if in VS Code and have Python Debugger installed, reads raw files from a remote repository)
#	python update_offsets.py --version	: 0: Legacy | 1: Enhanced; defaults to 0: Legacy
#	python update_offsets.py --local	: Read from local files; this must be followed by the path to local decompiled scritps
#	python update_offsets.py --diff 	: Show diff only, do not overwrite Lua table
#
#	CI Run: Don't pass any arguments


import sys, importlib.util, subprocess

for module in {"requests", "slpp"}:
    if importlib.util.find_spec(module) is None:
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", module])
        except subprocess.CalledProcessError:
            print(f"Failed to install {module}! Try running as administrator.")
            sys.exit(1)


import os, re, requests
from argparse import ArgumentParser as ArgParser
from pathlib import Path
from slpp import slpp as Lua


PARENT_PATH = Path(__file__).resolve().parent.parent
SCRIPT_ROOT = PARENT_PATH.parent.parent
REPO_URLS = [
    "https://raw.githubusercontent.com/acidlabsgg/gtav-legacy-scripts/refs/heads/main/scripts",
    "https://raw.githubusercontent.com/acidlabsgg/gtav-enhanced-scripts/refs/heads/main/scripts",
]
SS_NOTICE = """-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


"""


def has_c_file(path) -> bool:
    for _, _, files in os.walk(path):
        for file_name in files:
            if file_name.endswith(".c"):
                return True
    return False


def read_raw_file(file_name: str, version: int=0) -> str:
    url = f"{REPO_URLS[version]}/{file_name}"
    try:
        resp = requests.get(url)
        resp.raise_for_status()
    except requests.RequestException as e:
        print(f"Failed to fetch '{file_name}' from GitHub: {e}")
        sys.exit(1)

    return resp.text


def read_local_file(file_path: str) -> str:
    if not os.path.exists(file_path):
        print(f"Local file not found: {file_path}")
        sys.exit(1)
    with open(file_path, "r", encoding="utf-8") as f:
        return f.read()


def read_file(local: bool, file_name: str, decomps_path: str, version: int):
    if local:
        if not (os.path.isdir(decomps_path) and has_c_file(decomps_path)):
            print("The path specified is invalid.")
            sys.exit(1)
        return read_local_file(script_file_path(decomps_path, file_name))
    else:
        return read_raw_file(file_name, version)


def read_lua_table(path: str):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    match = re.search(r"return\s*(\{.*\})", content, re.DOTALL)

    if match:
        data = match.group(1)
    else:
        print("Could not find a valid Lua table!")
        quit(0)

    return Lua.decode(data)


def digits(s: str, default=None):
    m = re.search(r"\d+", s or "")
    return int(m.group()) if m else default


def script_file_path(root: str, filepath: str):
    return os.path.join(root, filepath)


def scan_entry(entry: dict, file_content: str, file_name: str):
    if not entry or "pattern" not in entry:
        return None

    pattern = re.compile(entry["pattern"])
    capture_group = int(entry.get("capture_group", 0))

    for lineno, line in enumerate(file_content.splitlines(), 1):
        match = pattern.search(line)
        if not match:
            continue

        try:
            target = match.group(capture_group)
        except IndexError:
            target = match.group(0)

        base_value = digits(target)
        offsets = []

        for offset in entry.get("offsets", []):
            if not offset or "value" not in offset:
                offsets.append(None)
                continue

            offset_capture_group = int(offset.get("capture_group", 0))
            try:
                result = match.group(offset_capture_group)
            except IndexError:
                result = match.group(0)
            offsets.append(digits(result))

        return {
            "file": file_name,
            "lineno": lineno,
            "match": match.group(0),
            "base_value": base_value,
            "offset_values": offsets,
        }
    return None


def serialize_lua(v, indent=1):
    sp = "\t" * indent
    if isinstance(v, dict):
        if not v:
            return "{}"

        parts = []
        for k, vv in v.items():
            if k == "pattern":
                vv = f"[[{vv}]]"
                parts.append(f"{sp}{k} = {vv}")
            else:
                parts.append(f"{sp}{k} = {serialize_lua(vv, indent+1)}")
        return "{\n" + ",\n".join(parts) + f"\n{"\t" * (indent - 1)}}}"

    if isinstance(v, list):
        if not v:
            return "{}"

        parts = []
        for _, vv in enumerate(v):
            parts.append(f"{sp}{serialize_lua(vv, indent+1)}")
        return "{\n" + ",\n".join(parts) + f"\n{"\t" * (indent - 1)}}}"

    if isinstance(v, bool):
        return "true" if v else "false"
    if v is None:
        return "nil"
    if isinstance(v, (int, float)):
        return str(v)

    s = str(v).replace("\\", "\\\\").replace('"', '\\"')
    return f'"{s}"'


def generate(offsets_table: list, version: int, local: bool, path: str):
    version_key = "LEGACY" if version == 0 else "ENHANCED"

    for name, data in offsets_table.items():
        ver = data.get(version_key)
        if not ver:
            continue

        print(f"\n--- Scanning for: {name} ({version_key}) ---")
        file_name = data["file"]
        file_content = read_file(local, file_name, path, version)
        result = scan_entry(ver, file_content, file_name)
        if not result:
            print(f"[MISS] {name} (pattern not found in {file_name})")
            continue

        print(f"[FOUND] {result['file']}:{result['lineno']} -> {result['match']}")

        if result["base_value"] is not None:
            ver["value"] = result["base_value"]

        if "offsets" in ver and result["offset_values"]:
            for i, newv in enumerate(result["offset_values"]):
                if newv is not None and i < len(ver["offsets"]):
                    print(f"\tFound offset for {name} ({version_key}): .f_{newv}")
                    ver["offsets"][i]["value"] = newv


def main(auto: bool = True):
    table_path = SCRIPT_ROOT / "SSV2/includes/data/globals_locals.lua"
    if not os.path.exists(table_path):
        print("Lookup file not found: globals_locals.lua")
        sys.exit(1)

    offsets_table = read_lua_table(table_path)

    if auto:
        generate(offsets_table, 0, False, "")
        generate(offsets_table, 1, False, "")	
    else:
        parser = ArgParser(description="Update offsets from local path or GitHub repository.")
        parser.add_argument("--version", type=int, help="Choose game version. (0: Legacy | 1: Enhanced)")
        parser.add_argument("--local", action="store_true", help="Read from local decompiled scripts")
        parser.add_argument("--diff", action="store_true", help="Show diff only. Do not write Lua table.")
        parser.add_argument("decomps_path", type=str, nargs="?", default="", help="Path to your local decompiled scripts")
        args = parser.parse_args()
        version = args.version or 0
        local = args.local
        path = args.decomps_path
        generate(offsets_table, version, local, path)
        if (args.diff):
            return
    
    data = serialize_lua(offsets_table)
    with open(table_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(SS_NOTICE)
        f.write("return ")
        f.write(data)
        f.write("\n")


if __name__ == "__main__":
    main(len(sys.argv) == 1)
