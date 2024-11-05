### v1.4.2 Changelog

#### Dangerous Car Crashes: Tweaks and Improvements

- The feature now increases vehicle deformation by a lot. No more minor scratches after hitting a wall at high speed. Your vehicle will be visually very deformed.
- Changed the speeds at which things start to happen:
  - **From 70km/h** Shakes the gameplay camera.
  - **From 120km/h up to 179km/h:** Applies damage to the vehicle and everyone inside it and simulates disorientation by applying a screen effect for 5 seconds. If playing online, plays a hurt ped sound as well.
  - **180km/h and up:** Destroys the vehicle's engine and kills everyone inside it. If playing online, plays a dying ped sound as well.

#### Animations

- Reworked animation names:
  - Before this change, animations had their categories included in their names, Example: "MISC: Sit On Chair 01". This was added along time ago in YimActions to help sort same-category anims together. This has been removed and the categories are now saved internally, so the same animation's name is now "Sit On Chair 01" but it's still under the "MISC" category.
- Added an option to sort animations by category.
- Fixed and improved the internal "anim interrupt" feature:
  - This is an internal feature that works in the background without needing any user interaction. It simply checks if the user's animation is supposed to keep playing but was interrupted *(the player died, was hit, ragdolled, bumped into, etc...)* then waits for certain conditions to be met and either restarts the animation or stops it cleans up. This was in here for quite some time but it needed some love. Well, now it got it.
- Added checks for animations that should only be played inside vehicles.
- Fixed 2 animations that were not spawning props because my fingers keep typing stuff incorrectly.

#### Ride With NPCs

**Improved the feature by adding a bunch of new stuff:**

- Pressing **[F]** to exit the vehicle while it's moving will make the driver NPC stop the vehicle before letting you out.
- When you get inside an NPC's vehicle as a passenger, a few new options will appear in the UI:
  - **Seat Controls:** Shuffle through all free vehicle seats.
  - **Radio Controls:** Control the vehicle's radio from any seat.
  - **Roof Controls** *(Convertible vehicles only)***:** Raise or lower the convertible roof.
  - **Driving Style:** Change the driver NPC's driving style. You can switch between **Chill** *(normal)* or **Aggressive**.
  - **Driving Commands:** Ask the driver NPC to take you to your waypoint, your objective, simply go for a ride, or just stop the vehicle.

#### MISC

- Genereal fixes & improvements.

#### GitHub

- Added [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/deed.en) license.
