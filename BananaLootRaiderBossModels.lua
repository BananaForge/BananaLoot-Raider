-- BananaLootRaiderBossModels.lua
-- 3D-Modelle fuer das Boss-Fenster. Schluessel "RAID:boss" -> Dateipfad des Spielmodells (1.12-Pfade, .mdx).
-- Erzeugt aus den Client-Tabellen CreatureDisplayInfo/CreatureModelData (Turtle-Client) und den Boss-Eintraegen der
-- Classic-Datenbank (Name -> Display-ID -> Modell). Hinweise:
--  * Ueber einen Dateipfad laedt das Spiel das Modell OHNE Texturen (sie kommen sonst aus der Display-Info des
--    Kreaturen-Ziels): im Boss-Test sind Modelle daher weiss/grau. "tint" faerbt sie ueber das Modell-Licht
--    thematisch ein (Feuer orange, Frost blau, Gift gruen ...). Im echten Kampf wird stattdessen das anvisierte Ziel
--    gezeigt - mit den echten Farben.
--  * Humanoide Bosse (Trolle, Menschen, Orcs) fehlen absichtlich; Turtle-Bosse (Custom) haben keinen Eintrag.
-- scale: Start-Zoom je Modellgroesse (Groessenklasse aus den Client-Tabellen); wird pro Boss im Fenster mit +/- angepasst
-- und gespeichert (/blr modeltune).

BananaLootRaider_BossModels = {
    -- Molten Core
    ["MC:lucifron"] = { path = "Creature\\Salamander\\SalamanderMale.mdx", scale = 0.9, tint = { 1.0, 0.55, 0.25 } },  -- Lucifron
    ["MC:magmadar"] = { path = "Creature\\FelBeast\\FelBeast.mdx", scale = 0.6, tint = { 1.0, 0.5, 0.45 } },  -- Magmadar
    ["MC:gehennas"] = { path = "Creature\\Salamander\\SalamanderMale.mdx", scale = 0.9, tint = { 1.0, 0.55, 0.25 } },  -- Gehennas
    ["MC:garr"] = { path = "Creature\\ElementalEarth\\ElementalEarth.mdx", scale = 0.9, tint = { 1.0, 0.5, 0.45 } },  -- Garr
    ["MC:shazzrah"] = { path = "Creature\\Salamander\\SalamanderMale.mdx", scale = 0.9, tint = { 1.0, 0.55, 0.25 } },  -- Shazzrah
    ["MC:geddon"] = { path = "Creature\\FireElemental\\FireElemental.mdx", scale = 0.9, tint = { 1.0, 0.55, 0.25 } },  -- Baron Geddon
    ["MC:sulfuron"] = { path = "Creature\\Salamander\\SalamanderMale.mdx", scale = 0.9, tint = { 1.0, 0.55, 0.25 } },  -- Sulfuron Harbinger
    ["MC:golemagg"] = { path = "Creature\\MountainGiant\\MountainGiant.mdx", scale = 0.35, tint = { 1.0, 0.55, 0.25 } },  -- Golemagg the Incinerator
    ["MC:majordomo"] = { path = "Creature\\Salamander\\SalamanderMale.mdx", scale = 0.9, tint = { 1.0, 0.55, 0.25 } },  -- Majordomo Executus
    ["MC:ragnaros"] = { path = "Creature\\Ragnaros\\Ragnaros.mdx", scale = 0.14, tint = { 1.0, 0.55, 0.25 } },  -- Ragnaros
    -- Onyxia's Lair
    ["ONY:onyxia"] = { path = "Creature\\Dragon\\DragonOnyxia.mdx", scale = 0.14, tint = { 1.0, 0.5, 0.45 } },  -- Onyxia
    -- Blackwing Lair
    ["BWL:razorgore"] = { path = "Creature\\DragonSpawn\\DragonSpawnOverlord.mdx", scale = 0.35, tint = { 1.0, 0.5, 0.45 } },  -- Razorgore the Untamed
    ["BWL:vaelastrasz"] = { path = "Creature\\Dragon\\Dragon.mdx", scale = 0.14, tint = { 1.0, 0.5, 0.45 } },  -- Vaelastrasz the Corrupt
    ["BWL:broodlord"] = { path = "Creature\\DragonFootSoldier\\DragonFootSoldier.mdx", scale = 0.9, tint = { 1.0, 0.5, 0.45 } },  -- Broodlord Lashlayer
    ["BWL:firemaw"] = { path = "Creature\\Drake\\Drake.mdx", scale = 0.6, tint = { 1.0, 0.5, 0.45 } },  -- Firemaw
    ["BWL:ebonroc"] = { path = "Creature\\Drake\\Drake.mdx", scale = 0.6, tint = { 0.75, 0.65, 0.85 } },  -- Ebonroc
    ["BWL:flamegor"] = { path = "Creature\\Drake\\Drake.mdx", scale = 0.6, tint = { 0.55, 1.0, 0.55 } },  -- Flamegor
    ["BWL:chromaggus"] = { path = "Creature\\Drakeadon\\Drakeadon.mdx", scale = 0.35, tint = { 1.0, 0.5, 0.45 } },  -- Chromaggus
    ["BWL:nefarian"] = { path = "Creature\\Dragon\\DragonNefarian.mdx", scale = 0.14, tint = { 0.75, 0.65, 0.85 } },  -- Nefarian
    -- Zul'Gurub
    ["ZG:edge"] = { path = "Creature\\TrollDire\\TrollDire.mdx", scale = 0.6 },  -- Edge of Madness
    ["ZG:gahzranka"] = { path = "Creature\\Hydra\\Hydra.mdx", scale = 0.35, tint = { 0.55, 0.85, 1.0 } },  -- Gahz'ranka
    ["ZG:hakkar"] = { path = "Creature\\Hakkar\\Hakkar.mdx", scale = 1.5 },  -- Hakkar the Soulflayer
    -- Ruins of Ahn'Qiraj
    ["AQ20:kurinnaxx"] = { path = "Creature\\SandReaver\\SandReaver.mdx", scale = 0.6, tint = { 0.95, 0.85, 0.5 } },  -- Kurinnaxx
    ["AQ20:rajaxx"] = { path = "Creature\\QuirajGladiator\\QuirajGladiator.mdx", scale = 0.9, tint = { 0.95, 0.85, 0.5 } },  -- General Rajaxx
    ["AQ20:moam"] = { path = "Creature\\ObsidianDestroyer\\ObsidianDestroyer.mdx", scale = 0.35, tint = { 0.95, 0.85, 0.5 } },  -- Moam
    ["AQ20:buru"] = { path = "Creature\\SilithidTankBoss\\SilithidTankBoss.mdx", scale = 0.6, tint = { 0.95, 0.85, 0.5 } },  -- Buru der Verschlinger
    ["AQ20:ayamiss"] = { path = "Creature\\SilithidWaspBoss\\SilithidWaspBoss.mdx", scale = 0.6, tint = { 0.55, 1.0, 0.55 } },  -- Ayamiss der Jäger
    ["AQ20:ossirian"] = { path = "Creature\\Horisath\\Horisath.mdx", scale = 0.35, tint = { 0.95, 0.85, 0.5 } },  -- Ossirian der Narbenlose
    ["AQ20:tuubid"] = { path = "Creature\\QuirajGladiator\\QuirajGladiator.mdx", scale = 0.9, tint = { 0.95, 0.85, 0.5 } },  -- Captain Tuubid (Custom)
    ["AQ20:drenn"] = { path = "Creature\\QuirajGladiator\\QuirajGladiator.mdx", scale = 0.9, tint = { 0.95, 0.85, 0.5 } },  -- Captain Drenn (Custom)
    ["AQ20:defenders"] = { path = "Creature\\Anubisath\\Anubisath.mdx", scale = 0.9, tint = { 0.95, 0.85, 0.5 } },  -- Anubisath Defenders (Custom)
    -- Temple of Ahn'Qiraj
    ["AQ40:skeram"] = { path = "Creature\\QuirajProphet\\QuirajProphet.mdx", scale = 0.9, tint = { 0.95, 0.85, 0.5 } },  -- Prophet Skeram
    ["AQ40:sartura"] = { path = "Creature\\QuirajBattleguard\\BattleGuard.mdx", scale = 0.6, tint = { 0.95, 0.85, 0.5 } },  -- Schlachtwache Sartura
    ["AQ40:bugtrio"] = { path = "Creature\\SilithidTankBoss\\SilithidTankBoss.mdx", scale = 0.6, tint = { 0.95, 0.85, 0.5 } },  -- Bug-Trio (Kri, Vem, Yauj)
    ["AQ40:fankriss"] = { path = "Creature\\SandReaver\\SandReaver.mdx", scale = 0.6, tint = { 0.95, 0.85, 0.5 } },  -- Fankriss der Unnachgiebige
    ["AQ40:viscidus"] = { path = "Creature\\SlimeGiant\\GiantSlime.mdx", scale = 0.35, tint = { 0.55, 1.0, 0.55 } },  -- Viscidus
    ["AQ40:huhuran"] = { path = "Creature\\SilithidWaspBoss\\SilithidWaspBoss.mdx", scale = 0.6, tint = { 0.55, 1.0, 0.55 } },  -- Prinzessin Huhuran
    ["AQ40:twins"] = { path = "Creature\\TwinEmperor\\TwinEmperor.mdx", scale = 0.6, tint = { 0.95, 0.85, 0.5 } },  -- Zwillingsimperatoren
    ["AQ40:ouro"] = { path = "Creature\\SandWorm\\SandWorm.mdx", scale = 0.14, tint = { 0.95, 0.85, 0.5 } },  -- Ouro
    ["AQ40:cthun"] = { path = "Creature\\HalfBodyofKathune\\HalfBodyofKathune.mdx", scale = 0.14, tint = { 0.55, 1.0, 0.55 } },  -- C'Thun
    -- Naxxramas
    ["NAXX:anub"] = { path = "Creature\\CryptLord\\CryptLord.mdx", scale = 0.6, tint = { 0.75, 0.65, 0.85 } },  -- Anub'Rekhan
    ["NAXX:maexxna"] = { path = "Creature\\GiantSpider\\GiantSpider.mdx", scale = 0.9, tint = { 0.75, 0.65, 0.85 } },  -- Maexxna
    ["NAXX:heigan"] = { path = "Creature\\Necromancer\\Necromancer.mdx", scale = 0.9, tint = { 0.75, 0.65, 0.85 } },  -- Heigan the Unclean
    ["NAXX:loatheb"] = { path = "Creature\\FungalMonster\\FungalMonster.mdx", scale = 0.35, tint = { 0.55, 1.0, 0.55 } },  -- Loatheb
    ["NAXX:gothik"] = { path = "Creature\\Necromancer\\Necromancer.mdx", scale = 0.9, tint = { 0.75, 0.65, 0.85 } },  -- Gothik the Harvester
    ["NAXX:horsemen"] = { path = "Creature\\MOUNTEDDEATHKNIGHT\\MountedDeathKnight_Korthazz.mdx", scale = 1.5, tint = { 0.75, 0.65, 0.85 } },  -- Die vier Reiter
    ["NAXX:patchwerk"] = { path = "Creature\\FleshGolem\\FleshGolem.mdx", scale = 0.6, tint = { 0.95, 0.75, 0.7 } },  -- Patchwerk
    ["NAXX:grobbulus"] = { path = "Creature\\FleshGiant\\FleshGiant.mdx", scale = 0.35, tint = { 0.55, 1.0, 0.55 } },  -- Grobbulus
    ["NAXX:gluth"] = { path = "Creature\\UndeadBeast\\UndeadBeast.mdx", scale = 0.35, tint = { 0.95, 0.75, 0.7 } },  -- Gluth
    ["NAXX:thaddius"] = { path = "Creature\\FleshTitan\\FleshTitan.mdx", scale = 0.9, tint = { 0.95, 0.75, 0.7 } },  -- Thaddius
    ["NAXX:sapphiron"] = { path = "Creature\\FrostWurm\\FrostWurm.mdx", scale = 0.35, tint = { 0.55, 0.75, 1.0 } },  -- Sapphiron
    ["NAXX:kelthuzad"] = { path = "Creature\\KelThuzad\\KelThuzad.mdx", scale = 0.35, tint = { 0.55, 0.75, 1.0 } },  -- Kel'Thuzad
    -- Tower of Karazhan
    ["UKH:anomalus"] = { path = "Creature\\Anomalus\\Anomalus.mdx", scale = 0.9 },  -- Anomalus
    ["UKH:echo"] = { path = "Creature\\medivh\\medivh.mdx", scale = 0.9, tint = { 0.5, 0.65, 1.0 } },  -- Echo of Medivh
    -- World Bosses
    ["WB:azuregos"] = { path = "Creature\\Dragon\\DragonAzurgoz.mdx", scale = 0.35, tint = { 0.5, 0.65, 1.0 } },  -- Azuregos
    ["WB:kazzak"] = { path = "Creature\\Lord Kezzak\\LordKezzak.mdx", scale = 0.35, tint = { 1.0, 0.55, 0.25 } },  -- Lord Kazzak
    ["WB:emeriss"] = { path = "Creature\\Dragon\\Dragon.mdx", scale = 0.14, tint = { 0.55, 1.0, 0.55 } },  -- Emeriss
    ["WB:lethon"] = { path = "Creature\\Dragon\\Lethon.mdx", scale = 0.35, tint = { 0.55, 1.0, 0.55 } },  -- Lethon
    ["WB:taerar"] = { path = "Creature\\Dragon\\Taerar.mdx", scale = 0.35, tint = { 0.55, 1.0, 0.55 } },  -- Taerar
    ["WB:ysondre"] = { path = "Creature\\Dragon\\Lethon.mdx", scale = 0.35, tint = { 0.55, 1.0, 0.55 } },  -- Ysondre
    ["WB:overseer"] = { path = "Creature\\CryptFiend\\CryptFiend.mdx", scale = 0.9, tint = { 0.75, 0.65, 0.85 } },  -- Nerubian Overseer (Custom)
    -- Upper Blackrock Spire
    ["UBRS:emberseer"] = { path = "Creature\\FireElemental\\FireElemental.mdx", scale = 0.9, tint = { 1.0, 0.55, 0.25 } },  -- Pyroguard Emberseer
    ["UBRS:solakar"] = { path = "Creature\\DragonSpawn\\DragonSpawnArmored.mdx", scale = 0.6, tint = { 1.0, 0.5, 0.45 } },  -- Solakar Flamewreath (optional)
    ["UBRS:beast"] = { path = "Creature\\FelBeast\\FelBeast.mdx", scale = 0.6, tint = { 1.0, 0.55, 0.25 } },  -- The Beast
    ["UBRS:drakkisath"] = { path = "Creature\\DragonSpawn\\DragonSpawnOverlord.mdx", scale = 0.35, tint = { 1.0, 0.5, 0.45 } },  -- General Drakkisath
}
