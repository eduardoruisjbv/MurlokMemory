# MurlokMemory 0.1.2-beta

- Keep the selected profile when the list is rebuilt (spec change, loading screen), or clear it if that build is gone.
- Compute the 2h/2w badge against the whole main-hand sample, so two-handed users are counted.
- Open the talents panel through Blizzard's panel manager and check the import dialog before opening anything.
- Include the hero tree in loadout names so different builds no longer share a name.
- Ignore talent strings from another serialization version and stop parsing truncated strings.
- Refresh only while the window is open; the version shown comes from the .toc.
- Add the MIT license.

# MurlokMemory 0.1.1-beta

- Show a "2h" or "2w" badge on each profile row (two-handed or dual wield) and in its tooltip.
- Frost Death Knight and Fury Warrior builds are classified from the talent string itself; other specs use the weapons worn in the hero-tree sample, and show no badge when the data is inconclusive.

# MurlokMemory 0.1.0-beta

- Initial Retail addon for selecting Murlok talent profiles by Mythic+, Solo, 2v2, 3v3, and RBG.
- Detect the current class and specialization and list available hero-tree talent strings from MurlokExport data.
- Prefill Blizzard's native talent import dialog; player confirmation is required to create a loadout.
- Keep talent changes manual and block the import flow in combat.
# MurlokMemory 0.1.0-beta

- Add a MuscleMemory-style panel for M+, Solo Shuffle, 2v2, 3v3, and RBG profiles.
- Read ranked talent strings from the installed MurlokExport data provider.
- Prefill Blizzard's native talent import dialog and leave final import confirmation to the player.
- Default to M+ and persist the selected mode per account.
