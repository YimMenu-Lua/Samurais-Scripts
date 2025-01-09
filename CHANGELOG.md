### v1.5.4 Changelog

#### Self -> Hide & Seek

- Fixed **Hide In Car Trunk:**
  - The feature no longer causes an `EXCEPTION_ACCESS_VIOLATION` on it's first call.
  > *Other features that also use the same function like "Bring x Vehicle" are fixed as well.*

  - The feature now only detects vehicles that are in front of the player, as opposed to vehicles that are in a radius around the player.
  - The feature now correctly determines engine placement *(it used to wrongly assume placement if a particular vehicle bone was broken off)*.
  - The feature no longer works on destroyed vehicles.

#### Weapon

- **Improved Laser Sight:**
  - The laser no longer goes through entities. It now detects them and adds a small visual enhancement.

- **Improved Katana:**
  - You can now choose which weapon to replace with a Katana: **Baseball Bat**, **Golf Club**, **Machete**, or **Pool Que**.

#### Vehicle

- Fixed a small issue in "**Flatbed**" *(nothing major)*.
- Fixed "**Bring Last Vehicle**" and "**Bring Personal Vehicle**": Both options no longer bring destroyed vehicles.

#### Actions

- When playing one of the DJ animations or just playing radio music from the **SoundPlayer** tab, the music can now be heard a little bit louder especially from other players' perspective.

#### Business Manager

- Auto-Sell now waits for phone calls to end if a call is ongoing.
