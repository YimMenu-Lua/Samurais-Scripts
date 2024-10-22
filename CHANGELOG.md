### v1.3.6 Changelog:

- Bumped version for game build 3351.
- Stopped checking modshop active state for both **Keep Engine On** and **Keep Wheels Turned** because the function returns true even if the player was only in close proximity to a modshop, which disables both functions. The script now simply checks if the player is outside.
- **Custom Paint Jobs:** Added the ability to set different paint jobs for primary and secondary colors.
- Added a few more missing translations.
- Fixed **handling flags** logic. It was retarded... Still is but much less.
- Fixed a crash caused by trying to reset handling flags when changing vehicles. And by fixed I mean I removed the whole thing hat was causing the crash.
