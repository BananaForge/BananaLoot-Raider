# Third-Party Notices

BananaLoot Raider is an original addon project by Bareg, a lightweight companion
to BananaLoot for raiders (no master loot functionality). The BananaLoot Raider
source code and original artwork are developed independently and are licensed
under the MIT License.

This repository also contains item data from a third-party source. The data is
identified below.

## Item Database

BananaLoot Raider's bundled item database (`BananaLootRaiderItemDB.lua`) contains
item data (names, qualities, icons and further item attributes) sourced from
Bananaforge Luminar. It is the same underlying dataset shipped with BananaLoot
(`BananaLootItemDB.lua`), copied here under a renamed global table
(`BananaLootRaider_ItemDB`) to avoid a naming collision when both addons are
loaded together.

## Instance Loot Data

`BananaLootRaiderZoneLoot.lua` (instance -> item IDs) is generated from the
loot tables of AtlasLoot Turtle WoW Edition and used with permission of its
developer. It is only used to preload item information from the game server.
`tools/gen_zone_loot.py` regenerates the file from an AtlasLoot copy.

`BananaLootRaiderRaidLoot.lua` (raid -> boss -> item IDs, plus name/quality/icon
for items missing from the bundled item database) is generated from the same
AtlasLoot data (script `tools/gen_raid_loot.py` in BananaLoot) and used with the
same permission. It is only used to show the item selection of the SR window.

## Separation of Licenses

The MIT License included in this repository applies to the original BananaLoot
Raider source code and original BananaLoot Raider artwork created by Bareg. It
does not replace or modify any license or rights that may apply to third-party
data.

Third-party data remains subject to the applicable terms and licenses of its
respective source.

## Disclaimer

This file is provided to document the sources of third-party data used by
BananaLoot Raider. If a rights holder requires additional attribution or a
change to the use of its data, please open an issue or contact the BananaLoot
maintainer.
