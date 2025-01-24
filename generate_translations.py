import os, sys, re
Lua_path = "./includes/lib/Translations.lua"
if not os.path.exists(Lua_path):
    print("Translations file not found!")
    quit(0)

# import subprocess
# modules = {'slpp', 'deep_translator', 'alive_progress', 'langcodes'}
# for module in modules:
#     if module not in sys.modules:
#         try:
#             subprocess.check_call([sys.executable, '-m', 'pip', 'install', '--upgrade', 'pip'])
#             subprocess.check_call([sys.executable, '-m', 'pip', 'install', module])
#         except WindowsError:
#             print("Failed to install necessary modules due to insufficient user privileges. Please run the program as administrator.")


from slpp import slpp as Lua
from alive_progress import alive_bar
from deep_translator import GoogleTranslator
import deep_translator.exceptions
import langcodes as Lang

try:
    import pyperclip
except ModuleNotFoundError:
    print("An optional module (pyperclip) was not found. The option to automatically copy the field's name will be skipped.")

with open(Lua_path, "r", encoding = "utf-8") as Lua_file:
    raw = Lua_file.read()
    Lua_file.close()

match = re.search(r"Labels\s*=\s*(\{.*\})", raw, re.DOTALL)
if match:
    Lua_data = match.group(1)
else:
    print("Error: Could not find a valid Lua table.")
    quit(0)

try:
    Labels = Lua.decode(Lua_data)
except Exception as e:
    print("Error parsing Lua table:", e)
    quit(0)

translator = GoogleTranslator
clear      = lambda: os.system("cls" if os.name == "nt" else "clear")


def Lua_write(data):
    with open(Lua_path, "w", encoding = "utf-8") as Lua_file:
        Lua_file.write("Labels = ")
        Lua_file.write(Lua.encode(data))
        Lua_file.write("\n")
        Lua_file.flush()
        Lua_file.close()


def get_n_strings(labels, iso):
    count = 0
    for key in labels:
        for entry in labels[key]:
            if entry["iso"] == iso:
                count += 1
    return count


def does_lang_exist(iso):
    for key in Labels:
        for entry in Labels[key]:
            if iso == entry["iso"] or iso[:2] == entry["iso"][:2]:
                return True
    return False


def add_translation(labels, key, iso, target_lang):
    for entry in labels[key]:
        if entry["iso"] == "en-US":
            translated_text = translator(source = "en", target = target_lang).translate(entry["text"])
            labels[key].append({"iso": iso, "text": translated_text})


def add_new_entry(label_content, existing_langs):
    translations = []
    with alive_bar(len(existing_langs)) as bar:
        for lang in existing_langs:
            try:
                translated_text = translator(source = "en", target = lang).translate(label_content)
                translations.append({"iso": lang, "text": translated_text})
            except:
                deep_translator.exceptions.LanguageNotSupportedException
                try:
                    translated_text = translator(source = "en", target = lang[:2]).translate(label_content)
                    translations.append({"iso": lang, "text": translated_text})
                except Exception as e:
                    print(f"\nAn error has occured!\n{e}")
            bar()
    return translations


def get_lang_name(iso):
    try:
        return f"{Lang.get(iso).display_name()} ({Lang.get(iso).autonym()})"
    except Exception:
        return f"({iso})"


def get_existing_langs():
    existing_langs = []
    for key in Labels:
        for entry in Labels[key]:
            if entry["iso"] != "en-US":
                if not entry["iso"] in existing_langs:
                    existing_langs.append(entry["iso"])
    return existing_langs


def add_new_label():
    clear()
    new_label = input("Assign a global variable name to your new label. (Uppercase, ending with _): ").strip()
    if new_label in Labels:
        clear()
        new_label = input("This label already exists. Please choose a different one: ").strip()

    if not new_label.isupper():
        new_label = new_label.upper()

    if not new_label.endswith("_"):
        new_label += "_"
    clear()

    label_content = input("Enter the English description for the label: ").strip()
    if not label_content:
        clear()
        label_content = input("Label content cannot be empty. Enter the English description for the label: ").strip()
    clear()

    existing_langs = get_existing_langs()
    translations   = [{"iso": "en-US", "text": label_content}]

    translations.extend(add_new_entry(label_content, [lang for lang in existing_langs]))
    Labels[new_label] = translations
    print(f"\nTranslations updated with {new_label}")
    print("")
    Lua.encode(Labels)
    print(f"Writing table to Translations.lua")
    Lua_write(Labels)

    if "pyperclip" in sys.modules:
        pyperclip.copy(new_label)
        print(f"\n{new_label} copied to clipboard.")

    print("\nDone!")
    print("")
    

def add_new_lang():
    clear()
    iso = input('Enter your desired language code (example: \"zh-CN\" for Chinese Simplified or \"fr\" for French): ')
    target_lang = None
    try:
        if len(iso) < 2:
            clear()
            print("\nIncorrect language code. Visit https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes for more info.\n")
            return
        elif len(iso) == 2:
            if not does_lang_exist(iso):
                target_lang = iso
                clear()
                print(f"\nGenerating {get_n_strings(Labels, 'en-US')} translations for {get_lang_name(iso)}.\n")
                iso = iso + "-" + iso.upper()
            else:
                clear()
                iso = input('Language already exists. Please choose a different one: ')
                target_lang = iso
        elif len(iso) == 5:
            if not does_lang_exist(iso):
                clear()
                target_lang = iso
                print(f"\nGenerating {get_n_strings(Labels, 'en-US')} translations for {get_lang_name(iso)}.\n")
            else:
                clear()
                iso = input('Language already exists. Please choose a different one: ')
                target_lang = iso
        else:
            clear()
            print("\nIncorrect language code. Visit https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes for more info.\n")
            iso = input('Enter your desired language code (example: \"zh-CN\" for Chinese Simplified or \"fr\" for French): ')
            target_lang = iso

    except deep_translator.exceptions.LanguageNotSupportedException:
        try:
            target_lang = iso[:2]
            print(f"\nGenerating {get_n_strings(Labels, 'en-US')} translations for {get_lang_name(iso)}.\n")
        except deep_translator.exceptions.LanguageNotSupportedException:
            clear()
            print(f"Unsupported language: {iso}")
            return

    if target_lang is not None:
        try:
            clear()
            with alive_bar(get_n_strings(Labels, 'en-US')) as bar:
                for key in Labels:
                    add_translation(Labels, key, iso, target_lang)
                    bar()
            print(f'All strings translated to {get_lang_name(iso)}')
            Lua_write(Labels)
            print(f"Added {get_n_strings(Labels, iso)} translated strings to Translations.lua")
            print("")
        except deep_translator.exceptions.LanguageNotSupportedException:
            clear()
            print(f"Unsupported language: {iso}")
            return


def main_loop():
    while True:
        try:
            choice = input("Choose an option then press enter to proceed:\n- Type 1 to add a new language.\n- Type 2 to add a new label.\n- Type 0 to exit.\n")
            if choice == "0":
                quit(0)
            elif choice == "1":
                add_new_lang()
            elif choice == "2":
                add_new_label()
            else:
                clear()
                print('Invalid choice.')

        except KeyboardInterrupt:
            clear()
            print("Operation canceled by the user.")
            quit(0)


if __name__ == "__main__":
    main_loop()
