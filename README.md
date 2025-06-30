<h1 align="center">
   Samurai's-Scripts
</h1>

#### A Lua script written for [YimMenu](https://github.com/YimMenu/YimMenu) and [Tupoye-Menu](https://github.com/TupoyeMenu/TupoyeMenu), centered around roleplaying and having fun in a game full of ad bots and toxic cheaters

[![sv](https://img.shields.io/badge/Script%20Version-v1.7.0-blue)](https://github.com/YimMenu-Lua/Samurais-Scripts/releases/latest)
[![gv](https://img.shields.io/badge/Game%20Version-Online%201.70%20|%20Build%203521-orange)](https://github.com/YimMenu-Lua/Samurais-Scripts)

###  

> [!Note]
> **Legacy Only.**
>

> [!Important]
> **Discontinued.** I can no longer maintain this project.
> Pull requests are still welcome if any other dev wants to maintain it. There are a few minor errors that need to be fixed *(few missing symbols in `string.format`, I forgot what else)* and only globals and locals for CasinoPacino and YimResupplierV3 need to be updated. I can provide a json and a small Python script that will update them for you if you have decompiled scripts *(you don't need all of them, reading the json file gives you an idea of what files are needed.)*.
>

###  

## Features

- Full list of features is documented [here](FEATURES.md).  

## Setup

1. Download the latest zip archive from the [releases section](https://github.com/YimMenu-Lua/Samurais-Scripts/releases).
2. Extract the archive to YimMenu's `scripts` folder:

       %AppData%\YimMenu\scripts

## TODO

- [x] Improve and merge [YimActions](https://github.com/xesdoog/YimActions). ✔️ Done.
- [x] Improve and merge [TokyoDrift](https://github.com/YimMenu-Lua/TokyoDrift). ✔️ Done.
- [x] Improve and merge [Object Spawner](https://github.com/xesdoog/object-spawner). ✔️ Done.
- [x] Improve and merge [YimResupplier](https://github.com/YimMenu-Lua/YimResupplier). ✔️ Done.

## Commands

> *Default command executor button: **[NUMPAD7]***

- `autoheal` : Enables/Disables the script's auto-heal feature.
- `rod` : Enables/Disables the **Ragdoll On Demand** feature.
- `autofill.hangar` : Starts auto-filling your hangar cargo.
- `autofill.whouse1` : Starts auto-filling your CEO Warehouse N°1 *(if you have more than one, use the same command with the corresponding number. Ex: `autofill.whouse4`)*.
- `yrv2.fillall` : Fills all your owned businesses with supplies.
- `finishsale` : Instantly finishes a sale mission (from a list of missions supported by the script). Will be skipped if you have the **Auto-Sell** option enabled.
- `fastvehs` : Increases the top speed of any *land* vehicle you drive.
- `spawnmeaperv` : No comment.
- `kys` : Kills you.
- `vehlock` : Locks/unlocks your vehicle.
- `PANIK` : Resets all changes done by the script (same as the panic button).
- `resetcfg` : Resets the script and restores your saved config to default.

## Credits

| Awesome Person                                    | Contribution                                                                   |
|     :---:                                         | :---:                                                                          |
| [Harmless](https://github.com/harmless05)         | Config system *(now YimConfig)* & Shift-Drift                                  |
| [NiiV3AU](https://github.com/NiiV3AU)             | German translations                                                            |
| [xiaoxiao](https://github.com/xiaoxiao921)        | YimMenu's Lua API                                                              |
| [YimMenu](https://github.com/YimMenu/YimMenu)     | I was never fond of any other project. It's just beautiful!                    |
| [gir489returns](https://github.com/gir489returns) | [Casino Pacino](https://github.com/YimMenu-Lua/Casino-Pacino)                  |
| [tupoy-ya](https://github.com/tupoy-ya)           | Bugfixes, better date&time, helped me finally figure out handling flags in Lua |
