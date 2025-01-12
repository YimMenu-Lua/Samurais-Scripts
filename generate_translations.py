import sys

# import subprocess

# modules = {'luadata', 'deep_translator', 'alive_progress', 'langcodes'}
# for module in modules:
#     if module not in sys.modules:
#         try:
#             subprocess.check_call([sys.executable, '-m', 'pip', 'install', '--upgrade', 'pip'])
#             subprocess.check_call([sys.executable, '-m', 'pip', 'install', module])
#         except WindowsError:
#             print("Failed to install necessary modules due to insufficient user privileges. Please run the program as administrator.")


import luadata
import deep_translator.exceptions
from alive_progress import alive_bar
from deep_translator import GoogleTranslator
import langcodes as Lang
try:
    import pyperclip
except ModuleNotFoundError:
    print("An optional module (pyperclip) was not found. The option to automatically copy the field's name will be skipped.")

lua_file   = './includes/lib/Translations.lua'
Labels     = luadata.read(lua_file, encoding = "utf-8", multival = True)
translator = GoogleTranslator


def get_n_strings(labels, iso):
    count = 0
    for key in labels:
        for entry in labels[key]:
            if entry["iso"] == iso:
                count += 1
    return count


def add_translation(labels, key, iso, target_lang):
    for entry in labels[key]:
        if entry['iso'] == 'en-US':
            translated_text = translator(source = 'en', target = target_lang).translate(entry['text'])
            labels[key].append({"iso": iso, "text": translated_text})


def add_new_entry(label_content, existing_langs):
    translations = []
    with alive_bar(len(existing_langs)) as bar:
        for lang in existing_langs:
            try:
                # print(f"Translating to: {get_lang_name(lang)}         \r",)
                translated_text = translator(source = 'en', target = lang).translate(label_content)
                translations.append({"iso": lang, "text": translated_text})
            except:
                deep_translator.exceptions.LanguageNotSupportedException
                try:
                    # print(f"Translating to: {get_lang_name(lang)}         \r",)
                    translated_text = translator(source = 'en', target = lang[:2]).translate(label_content)
                    translations.append({"iso": lang, "text": translated_text})
                except Exception as e:
                    print(f"\nAn error has occured!\n{e}")
            bar()
    return translations


def get_lang_name(iso):
    try:
        return f'{Lang.get(iso).display_name()} ({Lang.get(iso).autonym()})'
    except Exception:
        return f'({iso})'


def get_existing_langs():
    existing_langs = []
    for key in Labels:
        for entry in Labels[key]:
            if entry['iso'] != 'en-US':
                if not entry['iso'] in existing_langs:
                    existing_langs.append(entry['iso'])
    return existing_langs


def add_new_label():
    new_label = input("Assign a global variable name to your new label. (Uppercase, ending with _): ").strip()
    if new_label in Labels:
        new_label = input("This label already exists. Please choose a different one: ").strip()

    if not new_label.isupper():
        new_label = new_label.upper()

    if not new_label.endswith("_"):
        new_label += "_"

    label_content = input("Enter the English description for the label: ").strip()
    if not label_content:
        new_label = input("Label content cannot be empty. Enter your label name: ").strip()

    new_label
    existing_langs = get_existing_langs()
    translations   = [{"iso": "en-US", "text": label_content}]

    translations.extend(add_new_entry(label_content, [lang for lang in existing_langs]))

    print(f"\nGenerated Lua Table for {new_label}")
    # wtf am I doing?????????
    # print(f"{new_label} = {{")
    # for entry in translations:
    #     print(f"    {{ iso = \"{entry['iso']}\", text = \"{entry['text']}\" }},")
    # print("},\n")
    print(f"Writing table to {lua_file}")
    Labels[new_label] = translations
    luadata.write(lua_file, Labels, encoding = "utf-8", indent = "\t", prefix = "Labels = ")
    print('Done!')
    if 'pyperclip' in sys.modules:
        pyperclip.copy(new_label)
        print(f"{new_label} copied to clipboard.")

def add_new_lang():
    iso = input('Enter your desired language code (example: \"zh-CN\" for Chinese Simplified or \"fr\" for French): ')
    try:
        if len(iso) < 2:
            print("\nIncorrect language code. Visit https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes for more info.\n")
        elif len(iso) == 2:
            target_lang = iso
            print(f"\nGenerating {get_n_strings(Labels, 'en-US')} translations for {get_lang_name(iso)}.\n")
            iso = iso + "-" + iso.upper()
        elif len(iso) == 5:
            target_lang = iso
            print(f"\nGenerating {get_n_strings(Labels, 'en-US')} translations for {get_lang_name(iso)}.\n")
        else:
            print("\nIncorrect language code. Visit https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes for more info.\n")
    except deep_translator.exceptions.LanguageNotSupportedException:
        try:
            target_lang = iso[:2]
            print(f"\nGenerating {get_n_strings(Labels, 'en-US')} translations for {get_lang_name(iso)}.\n")
        except deep_translator.exceptions.LanguageNotSupportedException:
            print("Unsupported language.")

    try:
        with alive_bar(get_n_strings(Labels, 'en-US')) as bar:
            for key in Labels:
                add_translation(Labels, key, iso, target_lang)
                bar()
        print(f'All strings translated to {get_lang_name(iso)}')
        luadata.write(lua_file, Labels, encoding = "utf-8", indent = "\t", prefix = "Labels = ")
        print("\n")
        print(f"Added {get_n_strings(Labels, iso)} translated strings to {lua_file}")
    except Exception as exc:
        print("\n")
        print(f'An error occured!\nTraceback: {exc}')


def main_loop():
    while True:
        try:
            choice = input("Choose an option then press enter to proceed:\n- Type 1 to add a new language.\n- Type 2 to add a new label.\n- Type 0 to exit.\n")
            if choice == "0":
                quit(0)
            elif choice == "1":
                add_new_lang()
            elif choice == '2':
                add_new_label()
            else:
                print('Invalid choice.')

        except KeyboardInterrupt:
            print("\n")
            print("Operation canceled by the user.")
            quit(0)


if __name__ == "__main__":
    main_loop()
