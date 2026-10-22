<!-- markdownlint-disable MD028 -->
<!-- markdownlint-disable MD033 -->
<!-- markdownlint-disable MD041 -->

<div align="center">
  <a href="https://github.com/YimMenu-Lua/Samurais-Scripts/blob/main/LICENSE">
    <img alt="License" src="https://img.shields.io/badge/License-GPL--3.0-white?style=plastic">
  </a>
  <a href="https://github.com/YimMenu-Lua/Samurais-Scripts/releases/latest">
    <img alt="Latest Release" src="https://img.shields.io/badge/Latest%20Release-v2.0.3-blue?style=plastic">
  </a>
  <a href="https://github.com/YimMenu-Lua/Samurais-Scripts/issues">
    <img alt="Issues" src="https://img.shields.io/github/issues/YimMenu-Lua/Samurais-Scripts?style=plastic">
  </a>
  <a href="https://github.com/YimMenu-Lua/Samurais-Scripts/pulls">
    <img alt="PRs" src="https://img.shields.io/github/issues-pr/YimMenu-Lua/Samurais-Scripts?style=plastic">
  </a>

  <h3>Supported Builds</h3>

  <a href="https://github.com/YimMenu-Lua/Samurais-Scripts">
    <img alt="Online" src="https://img.shields.io/badge/Online%20Version-1.73-green?style=for-the-badge">
  </a>
  <br>
  <a href="https://github.com/YimMenu-Lua/Samurais-Scripts">
    <img alt="Legacy Build" src="https://img.shields.io/badge/Legacy-3889.0-green?style=for-the-badge">
  </a>
  <a href="https://github.com/YimMenu-Lua/Samurais-Scripts">
    <img alt="Enhanced Build" src="https://img.shields.io/badge/Enhanced-1158.16-green?style=for-the-badge">
  </a>
</div><br><br>

<details>
  <summary><strong>Table of Contents</strong></summary>
  <ul>
    <li><a href="#about">About</a></li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#setup">Setup</a></li>
        <li><a href="#commands-console">Commands Console</a></li>
      </ul>
    </li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#documentation">Documentation</a></li>
    <li><a href="#features">Features</a></li>
    <li><a href="#faq">FAQ</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ul>
</details>
<br>

# About

![ss](./docs/ss.png)

A modular GTA V Lua framework focused on enhancing the player's experience through fun features, online business options, and unpopular opinions.

## Getting Started

### Setup

- Download the latest zip archive from the [releases section](https://github.com/YimMenu-Lua/Samurais-Scripts/releases/latest).
- Extract the archive and place the `SSV2` folder in YimMenu's `scripts` folder:

       %AppData%\YimMenu\scripts

- Once in-game, press **[F5]** to toggle the script's UI.

For the native YimMenuV2 Lua API, use **`SSV2-enhanced`** from the same release ZIP.
Copy its `samurais_v2.lua` and `includes/ssv2` directory into
`%AppData%\YimMenuV2\scripts`, then load `samurais_v2.lua`.

>[!Note]
> Releases are scheduled for Sundays at 8AM.

### Commands Console

- Use **[F4]** to toggle the console window.
- Type `!ls` or `!dump` to dump all available commands.
- All default commands are prefixed with an exclamation mark `<!>`.

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

This project was rewritten from scratch using the [SmallBase](https://github.com/xesdoog/SmallBase) template.

A full documentation will be uploaded to this repository soon. In the meantime, feel free to explore [SmallBase's docs](https://github.com/xesdoog/SmallBase/tree/main/docs).

>[!Note]
> Some parts of the API were refactored or extended but nothing has drastically changed.
> All changes introduced in this project are documented in the source.

## Features

A full list of available features and their usage [can be found here](docs/Features.md).

## FAQ

- **Q:** Does this support Enhanced?
- **A:** The `SSV2-enhanced` edition targets GTA V Enhanced and the native YimMenuV2 Lua API.

- **Q:** What is YimLuaAPI and how do I use it?
- **A:**
  - **What is it:** [YimLuaAPI](https://github.com/TupoyeMenu/YimLuaAPI) is a universal Lua API that works for both Legacy and Enhanced.
  - **How to use it:** Right now there is no release because it's still in development. If you want to try it, you have to compile it yourself. Once you have `YimLuaAPI.dll`, inject it into any GTA branch (Legacy/Enhanced), it will create a folder on first injection: `%AppData%\YimLuaAPI`. Simply place the script there and you're done. You can still use YimMenu/YimMenuV2 but the script has to only exist in YimLuaAPI.

- **Q:** Which edition runs in YimMenuV2?
- **A:** Use `SSV2-enhanced`. The original `SSV2` runtime uses Lua 5.4 and the V1/YimLuaAPI environment; the Enhanced edition uses LuaJIT and native V2 APIs. The release contains both editions so you can select the correct one.

## Contact

<div>
  <a href="https://discord.gg/RHBUxJ5Qhp">
    <img height="64" width="192" alt="Discord" src="https://substackcdn.com/image/fetch/$s_!nfCP!,w_1456,c_limit,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F8a41e45e-aac9-44e5-8b69-55a81058ecbf_875x280.png">
  </a>
</div>

## Acknowledgments

| Name | Contribution |
| :---: | :---: |
| <a href="https://github.com/harmless05"><img height="40" width="40" alt="Harmless" src="https://avatars.githubusercontent.com/harmless05"><br/>Harmless</a> | Shift-Drift |
| <a href="https://github.com/NiiV3AU"><img height="40" width="40" alt="NiiV3AU" src="https://avatars.githubusercontent.com/NiiV3AU"><br/>NiiV3AU</a> | German translations |
| <a href="https://github.com/gir489returns"><img height="40" width="40" alt="gir489returns" src="https://avatars.githubusercontent.com/gir489returns"><br/>gir489returns</a> | [Casino Pacino](https://github.com/YimMenu-Lua/Casino-Pacino) |
| <a href="https://github.com/tupoy-ya"><img height="40" width="40" alt="tupoy-ya" src="https://avatars.githubusercontent.com/tupoy-ya"><br/>tupoy-ya</a> | Several contributions and shared knowledge. Owner of [YimLuaAPI](https://github.com/TupoyeMenu/YimLuaAPI) |
| <a href="https://github.com/szalikdev"><img height="40" width="40" alt="szalikdev" src="https://avatars.githubusercontent.com/szalikdev"><br/>szalikdev</a> | Revived the project and joined the cause. Owner of [Acid Labs](https://github.com/acidlabsdev) |
| <a href="https://github.com/How-Bout-No"><img height="40" width="40" alt="How-Bout-No" src="https://avatars.githubusercontent.com/How-Bout-No"><br/>How-Bout-No</a> | Enhanced compatibility (YimLuaAPI), Mastermind module, and more. |
| <a href="https://github.com/shinywasabi"><img height="40" width="40" alt="Arthur" src="https://avatars.githubusercontent.com/shinywasabi"><br/>ShinyWasabi</a> | [scrDbg](https://github.com/ShinyWasabi/scrDbg) and other foundational community contributions frequently used as reference |
| <a href="https://github.com/durtyfree"><img height="40" width="40" alt="DurtyFree" src="https://avatars.githubusercontent.com/durtyfree"><br/>Alexander Schmid</a> | [GTA V data dumps](https://github.com/DurtyFree/gta-v-data-dumps) |
| <a href="https://github.com/yimura"><img height="40" width="40" alt="Yimura" src="https://avatars.githubusercontent.com/yimura"><br/>Andreas Maerten</a> | GTA V classes (archived/removed) |
| <a href="https://github.com/sch-lda"><img height="40" width="40" alt="SCH" src="https://avatars.githubusercontent.com/sch-lda"><br/>sch-lda (SCH)</a> | [MiniGameHack](https://github.com/YimMenu-Lua/MiniGameHack) |
| <a href="https://github.com/TCRoid"><img height="40" width="40" alt="TCRoid" src="https://avatars.githubusercontent.com/TCRoid"><br/>TCRoid (Rostal)</a> | [SoloMissions](https://github.com/YimMenu-Lua/SoloMissions) |
| <a href="https://github.com/tuyilmaz"><img height="40" width="40" alt="tuyilmaz" src="https://avatars.githubusercontent.com/tuyilmaz"><br/>tuyilmaz</a> | Free Shopping |
| <a href="https://unknowncheats.me"><img height="40" width="40" alt="UC" src="https://avatars.githubusercontent.com/u/29552835"><br/>UnknownCheats</a> | A treasure trove of information |

## TODO

- [ ] Generate our own docs since we're no longer in sync with [SmallBase](https://github.com/xesdoog/SmallBase).
- [ ] Fully Refactor EntityForge.
- [ ] Add support in YimActions for defining custom animations. This will require extracting EntityForge's attachment handler into a reusable module for animation prop configuration.
