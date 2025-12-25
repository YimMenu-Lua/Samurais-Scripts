# Commit Convention

These are recommended, but not enforced yet. We follow slightly similar commit guidelines to [YimMenu](https://github.com/Mr-X-GTA/YimMenu/blob/master/CONTRIBUTING.md):

## Commit Structure

  ```text
  <type>(scope): <description>

  [optional body]

  [optional footer]
  ```

- **Types (lowercase only):**
  - feat: New features.
  - fix: Bug fixes.
  - style: Feature and updates related to styling.
  - refactor: Refactoring a specific section of the codebase.
  - test: Everything related to testing.
  - docs: Everything related to documentation.
  - chore: Regular code maintenance.

- **Scope:**
  - A scope is a phrase describing parts of the code affected by the changes. For example `(translations)`.

- **Body (Optional):**
  - The commit body can provide additional contextual information. For breaking changes, the body MUST start with "BREAKING CHANGE".

- **Footer (Optional):**
  - A commit footer is used to reference issues affected by the code changes. For example: "Fixes #13". It can also be used to indicate breaking changes by starting with "BREAKING CHANGE".

- **Example:**

  ```text
  fix(SomeFeature): fix constructor returning an empty object.
  docs(Readme): document coding conventions
  ```

## Coding Standards

### Annotations

Annotate all enums, classes, and class methods using [LuaLS](https://luals.github.io/wiki/annotations/)'s style.

Annotations are critical for readability, code completion, error checking, and automatic generation of class documentations.

For comments/summaries/descriptions, you can use either 2 or 3 dashes but please **leave a space** between the last dash and the text.

- **Example:**

    ```lua
    -- Calculates the sum of two numbers.
    ---@param a number The first number
    ---@param b number The second number
    ---@return number The sum of both numbers
    function MyClass:Add(a, b)
        return a + b
    end
    ```

### Global Variables

There are two ways to declare globals:

1. Globals that should be serialized to JSON:
Index the global `GVars` table. Even if the variable was never declared before:

    ```lua
    GVars.some_feature_enabled, _ = ImGui.Checkbox("My Checkbox", GVars.some_feature_enabled)
    ```

2. Regular globals:
Use Lua's default global table `_G`:

    ```lua
    some_global_number = 123
    ```

### Style

You are free to use any style you want, except in these cases:

| Scope | Naming | Example |
| ----------- | ----------- | ---------- |
| Global Functions | PascalCase | `function DoSomething(...) end` |
| Local Functions | any (consistent) | You are free to use any style as long as it stays consistent throughout the whole file |
| Standard Lib Extensions | Use the lib's default style | `string.somefunc = function(...) end` |
| Enums | PascalCase prefixed with a lowercase `e` | `eExampleEnum` |
| Enum Members | Preferably UPPER_SNAKE_CASE but PascalCase is also allowed | `eExampleEnum.SOME_MEMBER`/`eExampleEnum.SomeMember` |
| Classes | PascalCase | `MyNewClass = Class("MyNewClass")` |
| Class Methods | PascalCase | `function MyNewClass:ExampleMethod(...) end` |
| Class Members | snake_case prefixed with an `m` | `m_handle` |

### Formatting

- **Indentations:**
  - Does not matter. If using tabs, make sure one tab equals **four** spaces.

- **Line Wrapping:**
  - Try to wrap wide lines using either your IDE's formatter or a Pythonic way.

    - Example:

        ```lua
        SomeFunc(param1, param2, param3, param4, param5, param6, param7, param8, param9, ...)
        ```

    - Preferred (Pythonic) style:

        ```lua
        SomeFunc(
            param1,
            param2,
            param3,
            param4,
            param5,
            param6,
            param7,
            param8,
            param9,
            ...
        )
        ```

- **Nested `if` Statements:**

  - Always try to use guarded if statements when applicable.

    - Example:

        ```lua
        local cond_1 = false
        local cond_2 = nil
        local cond_3 = true

        if cond_1 then
            if cond_2 then
                if cond_3 then
                    DoSomething()
                end
            end
        end
        ```

    - Preferred approach:

        ```lua
        local cond_1 = false
        local cond_2 = nil
        local cond_3 = true

        if not cond_1 then
            return
        end

        if not cond_2 then
            return
        end

        if not cond_3 then
            return
        end

        DoSomething()
        ```

    - Shorter version:

        ```lua
        local cond_1 = false
        local cond_2 = nil
        local cond_3 = true

        if not (cond_1 and cond_2 and cond_3) then
            return
        end

        DoSomething()
        ```

## Translations

- The primary language for all labels is English (US) (`includes/lib/translations/en-US.lua`).
- To add a new language, add its name and ISO code to `includes/lib/translations/__locales.lua`.
- To add a new label, update `/lib/translations/en-US.lua`.
- All other language files will be automatically generated via GitHub Actions.

### Examples

#### Adding A New Label

Suppose you want to draw some text that gets automatically translated:

1. Open `includes/lib/translations/en-US.lua`.
2. Add a key-value pair for your new label:

    ```lua
    return {
      ...
      ["MY_LABEL"] = "My label's text in English."
    }
    ```

3. Use the `key` with the `_T` wrapper for the [`Translator:Translate(...)`](docs/services/Translator.md) method:

    ```lua
    ImGui.Text(_T("MY_LABEL"))
    ```

#### Adding A New Language

1. Open `includes/lib/translations/__locales.lua`.
2. Add a new language dictionary `{ name, iso }`:

    ```lua
    return {
      ..., -- pre-existing tables
      { name = "Türkçe", iso = "tr-TR" }, -- Your new language
    }
    ```

## What To Avoid

- Manually editing any language file except `en-US.lua`. They are auto-generated so any changes you add will be overwritten by GitHub Actions.
