### v1.5.3 Changelog

#### Self -> Hide & Seek

- Fixed and improved **Hide In Car Trunk:**
  - The feature no longer prompts you when you're not standing near a vehicle's trunk.
  - The feature now recognizes rear-engined vehicles and adjusts accordingly. *(it will no longer place you on top of a red hot engine 😅)*
  - Your ped will now play a brief animation when opening the car's trunk.
  - Your ped will now turn to face the vehicle if you're looking away from it.
  - The feature no longer teleports you to the trunk of a vehicle if it starts moving right after you press **[E]**. The vehicle has to be stopped for you to be able to enter its trunk.
  - Getting out of the trunk of a moving vehicle now ragdolls you if the vehicle's speed is higher than *approx* 14km/h.

#### Business Manager

- Fixed bunker instant sell. The feature no longer shows a **Mission Failed** message.
- Fixed hangar air cargo instant sell paying more than the actual amount of cargo sold.
- Disabled instant sell for hangar land sales. The option was broken. It showed a success message and the amount of money supposedly gained but did not actually pay the player.
- Added a **potential** fix for #28 . I said *potential* because I was never able to reproduce the issue.

#### Vehicle

- Locking your vehicle now also sets its alarm.

#### Flatbed

- Refactored code and got rid of unnecessary bloat.

#### Actions

- Refactored code and got rid of *most of the* unnecessary bloat.
