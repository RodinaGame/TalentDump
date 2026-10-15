# TalentDump v3.0

Modular character dump for **WoW 1.12 / Vanilla+**.

Authors: **Grok**, **Rodina**

## Modules

| File | Role |
|------|------|
| `TalentDump_Core.lua` | Namespace, DB, helpers |
| `TalentDump_Sections.lua` | Equipment, talents, BCS, bags, bank, spellbook, trainer |
| `TalentDump_AtlasLoot.lua` | AtlasLoot boss / instance loot dump buttons |
| `TalentDump_UI.lua` | Minimap, options panel, copy window, slash |

## Character dump

Minimap button or `/talentdump` → checkboxes → **Dump**.

## AtlasLoot dump

With **AtlasLoot** open:

- **Dump Boss** — loot for the currently selected boss
- **Dump Inst** — all bosses on the current Atlas map

Slash:

- `/talentdump boss`
- `/talentdump inst`

## Update

```bat
cd /d c:\\Vanillaplus\\Interface\\AddOns\\TalentDump
git pull
```

Then `/reload` in game.
