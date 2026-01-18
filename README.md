<!-- markdownlint-disable MD033 -->
<!-- markdownlint-disable MD041 -->

<div align="center">
  <a href="https://github.com/YimMenu-Lua/Samurais-Scripts/releases/latest">
    <img alt="Script Version" src="https://img.shields.io/badge/Script%20Version-v1.8.0-blue?style=for-the-badge">
  </a>
  <a href="https://github.com/YimMenu-Lua/Samurais-Scripts/blob/main/LICENSE">
    <img alt="License" src="https://img.shields.io/badge/License-GPL--3.0-white?style=for-the-badge">
  </a>
  <a href="https://github.com/YimMenu-Lua/Samurais-Scripts">
    <img alt="Game Version" src="https://img.shields.io/badge/Game%20Build-latest-green?style=for-the-badge">
  </a>
  <a href="https://github.com/YimMenu-Lua/Samurais-Scripts">
    <img alt="Online Version" src="https://img.shields.io/badge/Online%20Version-latest-green?style=for-the-badge">
  </a>
  <br/>
  <a href="https://github.com/YimMenu-Lua/Samurais-Scripts/issues">
    <img alt="Issues" src="https://img.shields.io/github/issues/YimMenu-Lua/Samurais-Scripts?style=plastic">
  </a>
  <a href="https://github.com/YimMenu-Lua/Samurais-Scripts/pulls">
    <img alt="PRs" src="https://img.shields.io/github/issues-pr/YimMenu-Lua/Samurais-Scripts?style=plastic">
  </a>
</div>

# About

![ss](./docs/ss.png)

A modular GTA V Lua framework focused on enhancing the player's experience through fun features, online business options, and unpopular opinions.

## Getting Started

### Setup

- Download the latest zip archive from the [releases section](https://github.com/YimMenu-Lua/Samurais-Scripts/releases/latest).
- Extract the archive and place the `SSV2` folder in YimMenu's `scripts` folder:

       %AppData%\YimMenu\scripts

- Once in-game, press **[F5]** to toggle the script's UI.

### Commands Console

- Use **[F4]** to toggle the console window.
- Type `!ls` or `!dump` to dump all available commands.
- All default commands are prefixed with an exclamation mark `<!>`.

>[!Important]
> **Do not use this in YimMenuV2. It will not work.**

## Contributing

Contributions are what make the open source community a great place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this project better, please fork the repo and create a pull request. You can also simply open a [feature request](https://github.com/YimMenu-Lua/Samurais-Scripts/issues/new?template=request.yml).

Don't forget to give the project a star!

1. Fork the repo
2. Create your feature branch.
3. Commit your changes.
4. Open a Pull Request.

Refer to the [Contribution Guidelines](./CONTRIBUTING.md) for more details on the project's structure and conventions.

## Documentation

This project was rewritten from scratch using [SmallBase](https://github.com/xesdoog/SmallBase). For API documentation, please refer to the [docs](https://github.com/xesdoog/SmallBase/tree/main/docs).

>[!Note]
> Some parts of the API were refactored or extended but nothing has drastically changed.
> All changes introduced in this project are documented in the source.

## FAQ

- **Q:** Does this support Enhanced?
- **A:** Partially. You can use [YimLuaAPI](https://github.com/TupoyeMenu/YimLuaAPI) to test it but stability is not guaranteed as of now.

- **Q:** What is YimLuaAPI and how do I use it?
- **A:**
  - **What is it:** [YimLuaAPI](https://github.com/TupoyeMenu/YimLuaAPI) is a universal Lua API that works for both Legacy and Enhanced.
  - **How to use it:** Right now there is no release because it's still in development. If you want to try it, you have to compile it yourself. Once you have `YimLuaAPI.dll`, inject it into any GTA branch (Legacy/Enhanced), it will create a folder on first injection: `%AppData%\YimLuaAPI`. Simply place the script there and you're done. You can still use YimMenu/YimMenuV2 but the script has to only exist in YimLuaAPI.

- **Q:** Why can't-I run this in YimMenuV2?
- **A:** There are several reasons why:
  - YimMenuV2 doesn't have a finished Lua API. `require` isn't even present, let alone custom bindings.
  - There are several versions and flavors of the Lua programming language. This project is written in [Lua 5.4](https://www.lua.org/manual/5.4/) and YimMenuV2's API uses [LuaJIT](https://luajit.org/). Explaining the difference here is not ideal but it's not only the language difference, it's also how they are embedded in each menu.

- **Q:** Can this be made compatible with YimMenuV2 once its API is finished?
- **Short Answer:** No.
- **Long Answer:** Yes, a compatibility layer can be added to accomodate for all language and API differences but is it worth the trouble and code bloat? Absolutely not. We would be better off rewriting this for V2's API.

## Acknowledgments

| Name | Contribution |
| :---: | :---: |
| <a href="https://github.com/harmless05"><img height="40" width="40" alt="Harmless" src="https://avatars.githubusercontent.com/harmless05"><br/>Harmless</a> | Shift-Drift |
| <a href="https://github.com/NiiV3AU"><img height="40" width="40" alt="NiiV3AU" src="https://avatars.githubusercontent.com/NiiV3AU"><br/>NiiV3AU</a> | German translations |
| <a href="https://github.com/gir489returns"><img height="40" width="40" alt="gir489returns" src="https://avatars.githubusercontent.com/gir489returns"><br/>gir489returns</a> | [Casino Pacino](https://github.com/YimMenu-Lua/Casino-Pacino) |
| <a href="https://github.com/tupoy-ya"><img height="40" width="40" alt="tupoy-ya" src="https://avatars.githubusercontent.com/tupoy-ya"><br/>tupoy-ya</a> | Several contributions and shared knowledge. Owner of [YimLuaAPI](https://github.com/TupoyeMenu/YimLuaAPI) |
| <a href="https://github.com/szalikdev"><img height="40" width="40" alt="szalikdev" src="https://avatars.githubusercontent.com/szalikdev"><br/>szalikdev</a> | Revived the project and joined the cause. Owner of [Acid Labs](https://github.com/acidlabsdev) |
| <a href="https://github.com/shinywasabi"><img height="40" width="40" alt="Arthur" src="https://avatars.githubusercontent.com/shinywasabi"><br/>ShinyWasabi</a> | [scrDbg](https://github.com/ShinyWasabi/scrDbg) and other foundational community contributions frequently used as reference |
| <a href="https://github.com/durtyfree"><img height="40" width="40" alt="DurtyFree" src="https://avatars.githubusercontent.com/durtyfree"><br/>Alexander Schmid</a> | [GTA V data dumps](https://github.com/DurtyFree/gta-v-data-dumps) |
| <a href="https://github.com/yimura"><img height="40" width="40" alt="Yimura" src="https://avatars.githubusercontent.com/yimura"><br/>Andreas Maerten</a> | GTA V classes (archived/removed) |
| <a href="https://unknowncheats.me"><img height="40" width="40" alt="UC" src="https://avatars.githubusercontent.com/u/29552835"><br/>UnknownCheats</a> | A treasure trove of information |

## Contact

<div>
  <a href="https://discord.gg/RHBUxJ5Qhp">
    <img height="96" width="192" alt="Discord" src="https://substackcdn.com/image/fetch/$s_!nfCP!,w_1456,c_limit,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F8a41e45e-aac9-44e5-8b69-55a81058ecbf_875x280.png">
  </a>
</div>
