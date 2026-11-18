-- BananaLootRaiderBossModels.lua
-- 3D-Modelle fuer das Boss-Fenster. Schluessel "RAID:boss" -> Dateipfad des Spielmodells (1.12-Pfade, .mdx).
-- Erzeugt aus den Client-Tabellen CreatureDisplayInfo/CreatureModelData (Turtle-Client) und den Boss-Eintraegen der
-- Classic-Datenbank (Name -> Display-ID -> Modell). Hinweise:
--  * Viele Bosse teilen sich ein Modell mit anderem Aussehen (andere Farbe/Textur); ueber den Pfad sieht man das Standard-
--    Aussehen. Im echten Kampf zeigt das Fenster stattdessen das Modell des anvisierten Ziels (richtiges Aussehen).
--  * Humanoide Bosse (Trolle, Menschen, Orcs) fehlen absichtlich: ihr Aussehen kommt aus Ausruestungsdaten.
--  * Turtle-Bosse (Custom) und viele Neue-Instanz-Bosse haben hier keinen Eintrag.
-- scale: Start-Zoom (1 = Standard); wird pro Boss im Fenster mit +/- angepasst und gespeichert (/blr modeltune).

BananaLootRaider_BossModels = {
    -- Molten Core
    ["MC:lucifron"] = { path = "Creature\\Salamander\\SalamanderMale.mdx", scale = 1 },  -- Lucifron
    ["MC:magmadar"] = { path = "Creature\\FelBeast\\FelBeast.mdx", scale = 1 },  -- Magmadar
    ["MC:gehennas"] = { path = "Creature\\Salamander\\SalamanderMale.mdx", scale = 1 },  -- Gehennas
    ["MC:garr"] = { path = "Creature\\ElementalEarth\\ElementalEarth.mdx", scale = 1 },  -- Garr
    ["MC:shazzrah"] = { path = "Creature\\Salamander\\SalamanderMale.mdx", scale = 1 },  -- Shazzrah
    ["MC:geddon"] = { path = "Creature\\FireElemental\\FireElemental.mdx", scale = 1 },  -- Baron Geddon
    ["MC:sulfuron"] = { path = "Creature\\Salamander\\SalamanderMale.mdx", scale = 1 },  -- Sulfuron Harbinger
    ["MC:golemagg"] = { path = "Creature\\MountainGiant\\MountainGiant.mdx", scale = 1 },  -- Golemagg the Incinerator
    ["MC:majordomo"] = { path = "Creature\\Salamander\\SalamanderMale.mdx", scale = 1 },  -- Majordomo Executus
    ["MC:ragnaros"] = { path = "Creature\\Ragnaros\\Ragnaros.mdx", scale = 1 },  -- Ragnaros
    -- Onyxia's Lair
    ["ONY:onyxia"] = { path = "Creature\\Dragon\\DragonOnyxia.mdx", scale = 1 },  -- Onyxia
    -- Blackwing Lair
    ["BWL:razorgore"] = { path = "Creature\\DragonSpawn\\DragonSpawnOverlord.mdx", scale = 1 },  -- Razorgore the Untamed
    ["BWL:vaelastrasz"] = { path = "Creature\\Dragon\\Dragon.mdx", scale = 1 },  -- Vaelastrasz the Corrupt
    ["BWL:broodlord"] = { path = "Creature\\DragonFootSoldier\\DragonFootSoldier.mdx", scale = 1 },  -- Broodlord Lashlayer
    ["BWL:firemaw"] = { path = "Creature\\Drake\\Drake.mdx", scale = 1 },  -- Firemaw
    ["BWL:ebonroc"] = { path = "Creature\\Drake\\Drake.mdx", scale = 1 },  -- Ebonroc
    ["BWL:flamegor"] = { path = "Creature\\Drake\\Drake.mdx", scale = 1 },  -- Flamegor
    ["BWL:chromaggus"] = { path = "Creature\\Drakeadon\\Drakeadon.mdx", scale = 1 },  -- Chromaggus
    ["BWL:nefarian"] = { path = "Creature\\Dragon\\DragonNefarian.mdx", scale = 1 },  -- Nefarian
    -- Zul'Gurub
    ["ZG:edge"] = { path = "Creature\\TrollDire\\TrollDire.mdx", scale = 1 },  -- Edge of Madness
    ["ZG:gahzranka"] = { path = "Creature\\Hydra\\Hydra.mdx", scale = 1 },  -- Gahz'ranka
    ["ZG:hakkar"] = { path = "Creature\\Hakkar\\Hakkar.mdx", scale = 1 },  -- Hakkar the Soulflayer
    -- Ruins of Ahn'Qiraj
    ["AQ20:kurinnaxx"] = { path = "Creature\\SandReaver\\SandReaver.mdx", scale = 1 },  -- Kurinnaxx
    ["AQ20:rajaxx"] = { path = "Creature\\QuirajGladiator\\QuirajGladiator.mdx", scale = 1 },  -- General Rajaxx
    ["AQ20:moam"] = { path = "Creature\\ObsidianDestroyer\\ObsidianDestroyer.mdx", scale = 1 },  -- Moam
    ["AQ20:buru"] = { path = "Creature\\SilithidTankBoss\\SilithidTankBoss.mdx", scale = 1 },  -- Buru der Verschlinger
    ["AQ20:ayamiss"] = { path = "Creature\\SilithidWaspBoss\\SilithidWaspBoss.mdx", scale = 1 },  -- Ayamiss der Jäger
    ["AQ20:ossirian"] = { path = "Creature\\Horisath\\Horisath.mdx", scale = 1 },  -- Ossirian der Narbenlose
    ["AQ20:tuubid"] = { path = "Creature\\QuirajGladiator\\QuirajGladiator.mdx", scale = 1 },  -- Captain Tuubid (Custom)
    ["AQ20:drenn"] = { path = "Creature\\QuirajGladiator\\QuirajGladiator.mdx", scale = 1 },  -- Captain Drenn (Custom)
    ["AQ20:defenders"] = { path = "Creature\\Anubisath\\Anubisath.mdx", scale = 1 },  -- Anubisath Defenders (Custom)
    -- Temple of Ahn'Qiraj
    ["AQ40:skeram"] = { path = "Creature\\QuirajProphet\\QuirajProphet.mdx", scale = 1 },  -- Prophet Skeram
    ["AQ40:sartura"] = { path = "Creature\\QuirajBattleguard\\BattleGuard.mdx", scale = 1 },  -- Schlachtwache Sartura
    ["AQ40:bugtrio"] = { path = "Creature\\SilithidTankBoss\\SilithidTankBoss.mdx", scale = 1 },  -- Bug-Trio (Kri, Vem, Yauj)
    ["AQ40:fankriss"] = { path = "Creature\\SandReaver\\SandReaver.mdx", scale = 1 },  -- Fankriss der Unnachgiebige
    ["AQ40:viscidus"] = { path = "Creature\\SlimeGiant\\GiantSlime.mdx", scale = 1 },  -- Viscidus
    ["AQ40:huhuran"] = { path = "Creature\\SilithidWaspBoss\\SilithidWaspBoss.mdx", scale = 1 },  -- Prinzessin Huhuran
    ["AQ40:twins"] = { path = "Creature\\TwinEmperor\\TwinEmperor.mdx", scale = 1 },  -- Zwillingsimperatoren
    ["AQ40:ouro"] = { path = "Creature\\SandWorm\\SandWorm.mdx", scale = 1 },  -- Ouro
    ["AQ40:cthun"] = { path = "Creature\\HalfBodyofKathune\\HalfBodyofKathune.mdx", scale = 1 },  -- C'Thun
    -- Naxxramas
    ["NAXX:anub"] = { path = "Creature\\CryptLord\\CryptLord.mdx", scale = 1 },  -- Anub'Rekhan
    ["NAXX:maexxna"] = { path = "Creature\\GiantSpider\\GiantSpider.mdx", scale = 1 },  -- Maexxna
    ["NAXX:heigan"] = { path = "Creature\\Necromancer\\Necromancer.mdx", scale = 1 },  -- Heigan the Unclean
    ["NAXX:loatheb"] = { path = "Creature\\FungalMonster\\FungalMonster.mdx", scale = 1 },  -- Loatheb
    ["NAXX:gothik"] = { path = "Creature\\Necromancer\\Necromancer.mdx", scale = 1 },  -- Gothik the Harvester
    ["NAXX:horsemen"] = { path = "Creature\\MOUNTEDDEATHKNIGHT\\MountedDeathKnight_Korthazz.mdx", scale = 1 },  -- Die vier Reiter
    ["NAXX:patchwerk"] = { path = "Creature\\FleshGolem\\FleshGolem.mdx", scale = 1 },  -- Patchwerk
    ["NAXX:grobbulus"] = { path = "Creature\\FleshGiant\\FleshGiant.mdx", scale = 1 },  -- Grobbulus
    ["NAXX:gluth"] = { path = "Creature\\UndeadBeast\\UndeadBeast.mdx", scale = 1 },  -- Gluth
    ["NAXX:thaddius"] = { path = "Creature\\FleshTitan\\FleshTitan.mdx", scale = 1 },  -- Thaddius
    ["NAXX:sapphiron"] = { path = "Creature\\FrostWurm\\FrostWurm.mdx", scale = 1 },  -- Sapphiron
    ["NAXX:kelthuzad"] = { path = "Creature\\KelThuzad\\KelThuzad.mdx", scale = 1 },  -- Kel'Thuzad
    -- Tower of Karazhan
    ["UKH:anomalus"] = { path = "Creature\\Anomalus\\Anomalus.mdx", scale = 1 },  -- Anomalus
    ["UKH:echo"] = { path = "Creature\\medivh\\medivh.mdx", scale = 1 },  -- Echo of Medivh
    -- World Bosses
    ["WB:azuregos"] = { path = "Creature\\Dragon\\DragonAzurgoz.mdx", scale = 1 },  -- Azuregos
    ["WB:kazzak"] = { path = "Creature\\Lord Kezzak\\LordKezzak.mdx", scale = 1 },  -- Lord Kazzak
    ["WB:emeriss"] = { path = "Creature\\Dragon\\Dragon.mdx", scale = 1 },  -- Emeriss
    ["WB:lethon"] = { path = "Creature\\Dragon\\Lethon.mdx", scale = 1 },  -- Lethon
    ["WB:taerar"] = { path = "Creature\\Dragon\\Taerar.mdx", scale = 1 },  -- Taerar
    ["WB:ysondre"] = { path = "Creature\\Dragon\\Lethon.mdx", scale = 1 },  -- Ysondre
    ["WB:overseer"] = { path = "Creature\\CryptFiend\\CryptFiend.mdx", scale = 1 },  -- Nerubian Overseer (Custom)
    -- Upper Blackrock Spire
    ["UBRS:emberseer"] = { path = "Creature\\FireElemental\\FireElemental.mdx", scale = 1 },  -- Pyroguard Emberseer
    ["UBRS:solakar"] = { path = "Creature\\DragonSpawn\\DragonSpawnArmored.mdx", scale = 1 },  -- Solakar Flamewreath (optional)
    ["UBRS:beast"] = { path = "Creature\\FelBeast\\FelBeast.mdx", scale = 1 },  -- The Beast
    ["UBRS:drakkisath"] = { path = "Creature\\DragonSpawn\\DragonSpawnOverlord.mdx", scale = 1 },  -- General Drakkisath
}
