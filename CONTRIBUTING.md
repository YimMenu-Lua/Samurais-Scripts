# Contributing

## Translations

### Editing a pre-existing language

1. Fork the repo then open `/lib/Translations.lua`
2. Find each entry for the language you want to modify/correct and edit the `text =` field.

   **Example:**

     ```lua
     ["Self"] = {
        {iso = "fr-FR", text = "Traduction du mot 'Self' en Français."},
     },
     ```

3. Open a PR.

### Adding a new language

#### Manual (horrible)

1. Follow the same structure by adding a new table under each field containing your language's iso code and the translated text. So let's suppose you want to add Portuguese support:

   **Example:**

     ```lua
     ["Self"] = {
       {iso = "fr-FR", text = "Traduction du mot 'Self' en Français."},
     -- leave the other tables as they are and add yours below the last one:
       {iso = "pt-BR", text = "Tradução da palavra 'Self' em Português."},
     },
     ```

2. Open `samurais_scripts.lua` and check if your new language exists in the `lang_T` table. If it doesn't then simply add it by following the same structure.
3. Open a PR.

#### Automatic (suggested)

1. Fork the repo.
2. Locate `generate_translations.py`
3. Install all requirements by either manually installing each module in the `modules` list at line 3 in the Python file or un-commenting lines 1 to 10 and running the script.
4. Run the script if it's not already running and once prompted, enter your language code.

> [!NOTE]
> both `fr` and `fr-FR` are valid for French but just `zh` will throw an error because you have to specify which Chinese dialect you want: `zh-CN` for simplified and `zh-TW` for traditional. Same thing applies for all languages with multiple dialects.

> [!NOTE]
> **Important:** Do not enter a full language name like `french`. It will work but it will mess up the Lua file which in turn will prevent the main script from recognizing the language.

5. Open `Translations.lua` and make sure your new language was correctly added and most importantly, double check the `iso` field. If it says `iso = ja-JA` then it will not work because that's not the correct iso code for Japanese, `ja-JP` is. This happens because the py script tries to set the iso country code if you don't provide one but it doesn't know that `JP` is the correct one so it simply adds a dash and an upper-case version of the iso code you provided.
6. Open `samurais_scripts.lua` and check if your new language exists in the `lang_T` table. If it doesn't then simply add it by following the same structure.
7. Open a PR.

## Main Script

- If you have any feature you want to add to the script, feel free to open a PR. If the feature code is not yours, make sure you have permission from the author before contributing it.
