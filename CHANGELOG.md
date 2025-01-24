### v1.5.7 Changelog

#### 🎉 New Feature: Weapon -> Magic Bullet

- Different from an aimbot, this feature automatically shoots the last ped you aimed at in the head when you press [FIRE], regardless of whether your crosshair is still on the ped or not. The only requirement is that the ped has to be in your field of view and not too far away from you.
- If you aim at a vehicle that has a driver, the magic bullet will automatically hit the driver in the head as soon as you fire your weapon.

#### Vehicle

- **Handling Editor:**
  - Restored the 3 Steering options. I removed them a long time ago because they required you to delete your vehicle then spawn it again to be able to **visually** see the changes. After some feedback, it seemed that most of my script users weren't bothered by it so all 3 options are back.

  > **NOTE:** The actual changes are applied instantly but the steering will not be rendered unless you respawn the vehicle.

  - Added **Rocket Boost**, similar to the Vigilante.
  - Added **Vehicle Jump**, similar to the Ruiner 2000.
  - Added **Parachute**, similar to the Ruiner 2000. *(requires **Vehicle Jump**)*

- **Launch Control:**
  - Added an indicator that shows the charging progress of the launch control system. (appears at the bottom of the screen when holding **[ACCELERATE]** + **[Brake]**)

- NOS and similar features no longer work on electric vehicles.

#### MISC

- Fixed wrong variable name in Casino Pacino that caused the "**Cart Autograb**" feature to stop working. (#31)
- Fixed new line parsing issue in `generate_translations.py`.
