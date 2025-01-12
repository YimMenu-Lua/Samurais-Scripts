### v1.5.5 Changelog

#### Self -> Hide & Seek

- Improved **Hide In Dumpster:**
  - Decreased the distance at which a dumpster is detected.
  - The feature will not prompt the player unless they're facing a dumpster.

#### Vehicle -> Planes & Helis

- Moved aircraft features into their own zone.
- Increased top speed for the "**Real Jet Speed**" option to 576km/h (the game's max).
- 🎉 Added 3 new features:

  - **No Engine Stalling:** When flying planes and holding the brake button, your engine will not shut off.
  
  - **Cannon Triggerbot:** When using a weaponized plane or heli and having the machine gun selected, it will automatically shoot targets in front of you. Also has the option to only shoot enemies.
  
  - **Cannon Triggerbot:** When using a weaponized plane or heli and having the machine gun selected, it will automatically shoot targets in front of you. Also has the option to only shoot enemies.
  
  - **Cannon Manual Aim:** Gives you the ability to manually aim and shoot an explosive cannon. The only requirement is to be using an aircraft that has a machine gun (doesn't have to be an explosive MG) and the machine gun is the selected weapon. Also works with **Cannon Triggerbot**: if you manually aim at an entity while having the triggerbot enabled, it will automatically blast it wil explosive MG.

#### Translations

- Added missing translations.
- Added Korean support.

#### MISC

- Added missing objects.
- Removed unused code.

#### Devs

- `generate_translations.py` now also adds new entries and translates them to all supported languages.
