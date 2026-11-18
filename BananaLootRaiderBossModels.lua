-- BananaLootRaiderBossModels.lua
-- 3D-Modelle fuer das Boss-Fenster. Schluessel "RAID:boss" -> Dateipfad des Spielmodells (Vanilla-Pfade, .mdx).
-- Quelle der Pfade: Community-Listfile (wowdev/wow-listfile); in 1.12 sind es .mdx statt .m2. Fuer Bosse ohne Eintrag
-- gibt es im echten Kampf trotzdem das Modell des anvisierten Ziels (SetUnit("target")); im Test-Fenster dort kein Modell.
-- scale: Start-Zoom (1 = Standard); wird pro Boss im Fenster mit +/- angepasst und gespeichert (/blr modeltune).

BananaLootRaider_BossModels = {
    ["MC:ragnaros"]      = { path = "Creature\\Ragnaros\\Ragnaros.mdx", scale = 1 },
    ["ONY:onyxia"]       = { path = "Creature\\Dragon\\DragonOnyxia.mdx", scale = 1 },
    ["BWL:nefarian"]     = { path = "Creature\\Dragon\\DragonNefarian.mdx", scale = 1 },
    ["ZG:hakkar"]        = { path = "Creature\\Hakkar\\Hakkar.mdx", scale = 1 },
    ["NAXX:kelthuzad"]   = { path = "Creature\\KelThuzad\\KelThuzad.mdx", scale = 1 },
    ["WB:taerar"]        = { path = "Creature\\Dragon\\Taerar.mdx", scale = 1 },
    ["WB:lethon"]        = { path = "Creature\\Dragon\\Lethon.mdx", scale = 1 },
    ["AQ20:defenders"]   = { path = "Creature\\Anubisath\\Anubisath.mdx", scale = 1 },
    ["UKH:echo"]         = { path = "Creature\\Medivh\\Medivh.mdx", scale = 1 },
}
