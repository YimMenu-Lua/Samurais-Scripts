import sys, importlib.util, subprocess

if importlib.util.find_spec("slpp") is None:
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "slpp"])
    except subprocess.CalledProcessError:
        print(f"Failed to install slpp! Try running as administrator.")
        sys.exit(1)


import os, re
from slpp import slpp as Lua


def has_c_file(path) -> bool:
    for _, _, files in os.walk(path):
        for file_name in files:
            if file_name.endswith(".c"):
                return True
    return False


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


def scan_entry(entry: dict, path: str):
    if not entry or "pattern" not in entry or not os.path.exists(path):
        return None

    pattern = re.compile(entry["pattern"])
    capture_group = int(entry.get("capture_group", 0))

    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        for lineno, line in enumerate(f, 1):
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
                "file": os.path.basename(path),
                "lineno": lineno,
                "match": match.group(0),
                "base_value": base_value,
                "offset_values": offsets,
            }
    return None


def serialize_lua(v, indent=0):
    sp = " " * indent
    if isinstance(v, dict):
        if not v:
            return "{}"

        parts = []
        for k, vv in v.items():
            if k == "pattern":
                vv = f"[[{vv}]]"
                parts.append(f"{sp}    {k} = {vv}")
            else:
                parts.append(f"{sp}    {k} = {serialize_lua(vv, indent+4)}")
        return "{\n" + ",\n".join(parts) + f"\n{sp}}}"

    if isinstance(v, list):
        if not v:
            return "{}"

        parts = []
        for _, vv in enumerate(v):
            parts.append(f"{sp}    {serialize_lua(vv, indent+4)}")
        return "{\n" + ",\n".join(parts) + f"\n{sp}}}"

    if isinstance(v, bool):
        return "true" if v else "false"
    if v is None:
        return "nil"
    if isinstance(v, (int, float)):
        return str(v)

    s = str(v).replace("\\", "\\\\").replace('"', '\\"')
    return f'"{s}"'


def main():
    TABLE_PATH = "../includes/data/globals_locals.lua"
    decomp_root = input("Paste your decompiled scripts path: ").strip().replace("\"", "")
    if not (os.path.isdir(decomp_root) and has_c_file(decomp_root)):
        print("The path specified is invalid.")
        sys.exit(1)

    if not os.path.exists(TABLE_PATH):
        print("Lookup file not found: globals_locals.lua")
        sys.exit(1)

    offsets_table = read_lua_table(TABLE_PATH)

    match int(input("Choose a game version (1: Legacy/2: Enhanced): ").strip()):
        case 1:
            version_key = "LEGACY"
        case 2:
            version_key = "ENHANCED"
        case _:
            print("Invalid choice.")
            sys.exit(1)

    for name, data in offsets_table.items():
        ver = data.get(version_key)
        if not ver:
            continue

        print(f"\n--- Scanning for: {name} ({version_key}) ---")
        path = script_file_path(decomp_root, data["file"])
        result = scan_entry(ver, path)
        if not result:
            print(f"[MISS] {name} (pattern not found in {data['file']})")
            continue

        print(f"[FOUND] {result['file']}:{result['lineno']} -> {result['match']}")

        if result["base_value"] is not None:
            ver["value"] = result["base_value"]

        if "offsets" in ver and result["offset_values"]:
            for i, newv in enumerate(result["offset_values"]):
                if newv is not None and i < len(ver["offsets"]):
                    print(f"\tFound offset for {name} ({version_key}): .f_{newv}")
                    ver["offsets"][i]["value"] = newv

    data = serialize_lua(offsets_table)
    with open(TABLE_PATH, "w", encoding="utf-8") as f:
        f.write("return ")
        f.write(data)
        f.write("\n")


if __name__ == "__main__":
    main()
