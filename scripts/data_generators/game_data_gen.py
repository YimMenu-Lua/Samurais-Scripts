# Samurai's Scripts Game Data Generator
#
# Usage:
#	python game_data_gen.py				: default, generates all 3 lists (just hit F5 if in VS Code and have Python Debugger installed)
#	python game_data_gen.py --vehicles	: generates vehicle list only.
#	python game_data_gen.py --peds		: generates ped list only.
#	python game_data_gen.py --objects	: generates object list only.
#
#	CI Run: None. Only local.


import sys, subprocess, importlib.util

for module in {"requests", "alive_progress"}:
    if importlib.util.find_spec(module) is None:
            try:
                subprocess.check_call([sys.executable, "-m", "pip", "install", module])
            except subprocess.CalledProcessError:
                print(f"Failed to install {module}. Run as administrator.")
                sys.exit(1)


import requests, datetime
from alive_progress import alive_bar
from argparse import ArgumentParser as ArgParser
from pathlib import Path


PARENT_PATH = Path(__file__).resolve().parent
SCRIPT_ROOT = PARENT_PATH.parent.parent
LUA_DATA_PATH = SCRIPT_ROOT / "SSV2/includes/data"
SS_NOTICE = """-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


"""

ePedType = {
    "PLAYER_0": 0,
    "PLAYER_1": 1,
    "NETWORK_PLAYER": 2,
    "PLAYER_2": 3,
    "CIVMALE": 4,
    "CIVFEMALE": 5,
    "COP": 6,
    "GANG_ALBANIAN": 7,
    "GANG_BIKER_1": 8,
    "GANG_BIKER_2": 9,
    "GANG_ITALIAN": 10,
    "GANG_RUSSIAN": 11,
    "GANG_RUSSIAN_2": 12,
    "GANG_IRISH": 13,
    "GANG_JAMAICAN": 14,
    "GANG_AFRICAN_AMERICAN": 15,
    "GANG_KOREAN": 16,
    "GANG_CHINESE_JAPANESE": 17,
    "GANG_PUERTO_RICAN": 18,
    "DEALER": 19,
    "MEDIC": 20,
    "FIREMAN": 21,
    "CRIMINAL": 22,
    "BUM": 23,
    "PROSTITUTE": 24,
    "SPECIAL": 25,
    "MISSION": 26,
    "SWAT": 27,
    "ANIMAL": 28,
    "ARMY": 29,
}


def gen_file_header() -> str:
    today = datetime.date.today()
    date_str = today.strftime("%d-%m-%Y")
    buff = SS_NOTICE
    buff += f"\n-- Auto-generated on <{date_str}>\n\n"
    buff += "\n---@diagnostic disable\n\n"
    return buff


def serialize_lua(v, indent=0) -> str:
    sp = "\t" * indent

    if isinstance(v, dict):
        if not v:
            return "{}"

        parts = []
        for k, vv in v.items():
            if isinstance(k, int):
                k = f"[{k}]"
            parts.append(f"{sp}\t{k} = {serialize_lua(vv, indent+1)}")
        return "{\n" + ",\n".join(parts) + f"\n{sp}}}"

    if isinstance(v, list):
        if not v:
            return "{}"

        parts = []
        for k, vv in enumerate(v):
            if isinstance(k, int):
                k = f"[{k}]"
            parts.append(f"{sp}\t{serialize_lua(vv, indent+1)}")
        return "{\n" + ",\n".join(parts) + f"\n{sp}}}"

    if isinstance(v, bool):
        return "true" if v else "false"
    if v is None:
        return "nil"
    if isinstance(v, (int, float)):
        return str(v)

    s = str(v).replace("\\", "\\\\").replace('"', '\\"')
    return f'"{s}"'


def write_lua_table(lua_path, data):
    with open(lua_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(gen_file_header())
        f.write("return ")
        f.write(serialize_lua(data))
        f.write("\n")


def read_raw_file(file_name: str, as_json: bool = True):
    url = f"https://raw.githubusercontent.com/DurtyFree/gta-v-data-dumps/refs/heads/master/{file_name}"
    try:
        resp = requests.get(url)
        resp.raise_for_status()
    except requests.RequestException as e:
        print(f"Failed to fetch '{file_name}' from GitHub: {e}")
        sys.exit(1)

    out = resp.json() if as_json else resp.text
    return out


def gen_vehicles():
    jsondata = read_raw_file("vehicles.json")
    out = {}
    hash_lookup = {}

    with alive_bar(len(jsondata), title="Generating Vehicles", force_tty=True) as bar:
        for veh in jsondata:
            str_name = str(veh["Name"]).lower()
            joaat_hash = veh["Hash"]

            out[str_name] = {
                "model_hash": joaat_hash,
                "display_name": veh["DisplayName"]["English"],
                "manufacturer": veh["ManufacturerDisplayName"]["English"],
                "class_id": veh["ClassId"],
                "class_name": veh["Class"],
            }

            hash_lookup[joaat_hash] = str_name
            bar()

    write_lua_table(LUA_DATA_PATH / "vehicles.lua", out)
    write_lua_table(LUA_DATA_PATH / "vehicle_hashmap.lua", hash_lookup)


def gen_peds():
    jsondata = read_raw_file("peds.json")
    out = {}
    hash_lookup = {}

    with alive_bar(len(jsondata), title="Generating Peds", force_tty=True) as bar:
        for ped in jsondata:
            str_name = str(ped["Name"]).lower()
            str_pedtype = str(ped["Pedtype"]).lower()
            is_human = str_pedtype != "animal"
            if is_human:
                gender = 0 if ped["PedCapsuleName"] == "standard_male" else 1
            else:
                gender = 2

            ped_type = ePedType.get(str_pedtype.upper(), 4) # not sure if it's a good idea to default to civmale
            joaat_hash = ped["Hash"]

            out[str_name] = {
                "model_hash": joaat_hash,
                "ped_type": ped_type,
                "ped_gender": gender,
                "is_human": is_human,
            }

            hash_lookup[joaat_hash] = str_name
            bar()

    write_lua_table(LUA_DATA_PATH / "peds.lua", out)
    write_lua_table(LUA_DATA_PATH / "ped_hashmap.lua", hash_lookup)


def gen_objects():
    resp_text = read_raw_file("ObjectList.ini", as_json=False)
    data = resp_text.splitlines()
    out = []

    with alive_bar(len(data), title="Generating Objects", force_tty=True) as bar:
        for i, line in enumerate(data, 1):
            out.insert(i, line)
            bar()

    write_lua_table(LUA_DATA_PATH / "objects.lua", out)


def generate_lists(vehicles: bool = True, peds: bool = True, objects: bool = True):
    if vehicles:
        gen_vehicles()
    if peds:
        gen_peds()
    if objects:
        gen_objects()


if __name__ == "__main__":
    parser = ArgParser(description="Generate raw game entity data from durtyfree's repository. If no arguments passed, all lists will be generated (peds, vehicles, objects).")
    parser.add_argument("--vehicles", action="store_true", help="Generate vehicle list.")
    parser.add_argument("--peds", action="store_true", help="Generate ped list.")
    parser.add_argument("--objects", action="store_true", help="Generate object list.")
    args = parser.parse_args()

    genvehs = args.vehicles
    genpeds = args.peds
    genobj  = args.objects

    if (len(sys.argv) == 1):
        print("No arguments passed. Generating all lists...")
        genvehs, genpeds, genobj = True, True, True

    generate_lists(genvehs, genpeds, genobj)
