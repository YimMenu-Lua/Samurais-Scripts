# import subprocess, sys

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

def get_lang_name(iso):
    try:
        return f'{Lang.get(iso).display_name()} ({Lang.get(iso).autonym()})'
    except Exception:
        return f'({iso})'

def main_loop():
    while True:
        try:
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

        except KeyboardInterrupt:
            print("\n")
            print("Operation canceled by the user.")
            quit(0)

if __name__ == "__main__":
    main_loop()
