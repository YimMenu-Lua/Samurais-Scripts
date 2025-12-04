import os, sys, importlib.util, subprocess

BASE_PATH = "../includes/lib/translations"
EN_STR_PATH = os.path.join(BASE_PATH, "en-US.lua")
LOCALES_PATH = os.path.join(BASE_PATH, "__locales.lua")

if not os.path.exists(BASE_PATH):
    print("Base translations directory not found!")
    quit(0)

if not os.path.exists(EN_STR_PATH):
    print("Translations file not found!")
    quit(0)

if not os.path.exists(LOCALES_PATH):
    print("Supported languages file not found!")
    quit(0)


MODULES = { "slpp", "langcodes[data]", "deep_translator", "alive_progress", "langcodes" }

for module in MODULES:
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
import deep_translator.exceptions
import re


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


def write_lua_table(path: str, table: dict):
    with open(path, "w", encoding="utf-8") as Lua_file:
        Lua_file.write("return ")
        Lua_file.write(Lua.encode(table))
        Lua_file.write("\n")


LOCALES = read_lua_table(LOCALES_PATH)
LABELS  = read_lua_table(EN_STR_PATH)


def get_lang_name(iso: str):
    unk = False
    try:
        name = Lang.get(iso).display_name()
        unk = (name is None or name.find("Unknown") != -1)
    except Exception:
        name = Lang.get(iso[:2]).display_name()
        unk = (name is None or name.find("Unknown") != -1)

    if unk:
        return f"({iso})"
    return name


def translate(iso: str, text: str):
    try:
        return GoogleTranslator(source="en", target=iso).translate(text)
    except deep_translator.exceptions.LanguageNotSupportedException:
        return GoogleTranslator(source="en", target=iso[:2]).translate(text)


def generate_translations():
    translations = {}

    with alive_bar(len(LOCALES) - 1) as bar1:
        for label, text in LABELS.items():
            for dictionary in LOCALES:
                lang = dictionary["iso"]
                fname = f"{lang}.lua"

                if lang == "en-US":
                    continue

                print(f"Generating translations for {get_lang_name(lang)}...")
                translated_text = translate(lang, text)
                if fname not in translations:
                    translations[fname] = {}

                translations[fname][label] = translated_text
                bar1()

    print("All translations generated successfully!")
    print("\n\nWriting files...")

    with alive_bar(len(translations)) as bar2:
        for fname, content in translations.items():
            write_lua_table(os.path.join(BASE_PATH, fname), content)
            bar2()


if __name__ == "__main__":
    generate_translations()
