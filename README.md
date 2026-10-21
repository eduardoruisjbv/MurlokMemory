# MurlokMemory 0.1.2-beta

MurlokMemory is a small, MuscleMemory-style Retail addon for choosing a Murlok talent build by activity and importing it into WoW's native talent-loadout dialog.

## Modes

- Mythic+ (default)
- Solo Shuffle
- 2v2
- 3v3
- Rated Battlegrounds (RBG)

The addon detects the player's current class and specialization. Each profile shows its hero talent icon, the rank of that talent string, and the hero specialization's aggregate Murlok rating and sample count. Each row also shows `2h` (two-handed) or `2w` (dual wield) when the weapon setup can be determined. Hover a row for a note about how those figures are grouped.

## Data source and update behavior

WoW addons cannot make arbitrary HTTP requests to murlok.io. MurlokMemory therefore reads the talent strings from the global `MurlokExport` data table provided by the separate MurlokExport addon. Install and keep MurlokExport updated with CurseForge to receive its daily Murlok data snapshot. MurlokMemory does not copy MurlokExport code or bundle its dataset.

If MurlokExport is missing, MurlokMemory shows a clear dependency message instead of pretending it has current data.

## Import safety

Selecting a profile opens Blizzard's native talent-loadout import dialog with the chosen string prefilled. The player reviews the name and presses WoW's Import button. MurlokMemory never spends talent points or switches the active loadout on its own, and it blocks opening the import flow in combat.

Open with `/murlokmemory` or `/mmurlok`.
