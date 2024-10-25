### v1.3.7 Changelog

**Translations:**

- Initialize all strings once instead of calling `tanslateLabel()` inside the GUI loop.

**Custom Paint Jobs:**

- Improved the "Sort By Color" option.
- Added "Sort By Manufacturer" option.
- Added more custom paint jobs.

**Handling Flags:**

- Further improvements.
- Only auto-enable saved handling flags in the background and let the user manually disable them to avoid mistakenly disabling flags for vehicles that already have them by default.

**General:**

- Avoid using string concatenation inside loops.
