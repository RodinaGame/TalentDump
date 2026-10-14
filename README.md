# TalentDump

Customizable character dump addon for **World of Warcraft 1.12.1** (Vanilla / Vanilla+).

Authors: **Grok**, **Rodina**

## Features

- Minimap button opens an options panel
- Select what to dump with checkboxes:
  - Equipment
  - Talents (taken only)
  - Talents (full tree, including 0/x)
  - BCS stats (BetterCharacterStats)
  - Bags
  - Bank (requires open bank window)
  - **Spellbook** (all spells with ranks and tooltip descriptions)
- Dump window for Ctrl+A / Ctrl+C

## Usage

1. Click the minimap button (book icon), or type `/talentdump`
2. Tick the sections you need
3. Press **Dump**
4. Copy the text from the window

Slash commands:
- `/talentdump` — toggle options panel
- `/talentdump dump` — run dump with current settings
- `/fulldump` — same as `/talentdump`

## Installation

1. Download / clone this repository
2. Copy the folder into `World of Warcraft\Interface\AddOns` as `TalentDump`
3. Ensure the folder contains `TalentDump.toc` and `TalentDump.lua`
4. Restart the client or `/reload`

## Notes

- Bank data is only available while the bank UI is open
- Spellbook dump is useful for reviewing LazyScript rotations
- BCS section requires BetterCharacterStats (optional)
