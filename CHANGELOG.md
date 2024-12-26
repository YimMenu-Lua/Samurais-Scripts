### v1.4.9 Changelog

#### Features

🎉 **New Feature: Vehicle -> ABS Brake Lights:**

- Flashes your brake lights repeatedly when you apply the brakes at a speed higher than 100km/h, similar to modern sports cars *(Only works on cars that have ABS as standard)*.

🎉 **New Feature: Command Executor:**

- Allows you to execute a few commands on the fly. Wanna quickly full up your hangar? Open the Command Executor by pressing the assigned button and type `autofill.hangar`.
- **Default Buttons:**
  - **Open:** **[NUMPAD7]** (can be changed in the **Hotkeys** tab).
  - **Close:** **[ESC]** (hardcoded).

- **Full list of commands:**.
  - `autoheal` : Enables/Disables the script's auto-heal feature.
  - `rod` : Enables/Disables the **Ragdoll On Demand** feature.
  - `autofill.hangar` : Starts auto-filling your hangar cargo.
  - `autofill.whouse1` : Starts auto-filling your CEO Warehouse N°1 *(if oyu have more than one, use the same command with corresponding number. Ex: `autofill.whouse4`)*.
  - `finish_sale` : Instantly finishes a sale mission (from a list of missions supported by the script). Will be skipped if you have the **Auto-Sell** option enabled.
  - `spawnmeaperv` : No comment.
  - `kys` : Kills you.
  - `PANIK` : Resets all changes done by the script (same as the panic button).
  - `resetcfg` : Resets the script and restores your saved config to default.

#### MISC

- Hotkeys UI is now properly aligned.
- Fixed `isKeyJustPressed()` returning true when the button is held down. It now only returns true once, when the button is released.
- Other minor fixes.
