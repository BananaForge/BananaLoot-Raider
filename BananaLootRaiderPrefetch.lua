-- BananaLootRaiderPrefetch.lua
-- Laedt beim Betreten einer Instanz (Dungeon/Raid) alle Items vor, die dort
-- droppen koennen und dem Client noch unbekannt sind.
--
-- Hintergrund: Das Blizzard-Wuerfelfenster zeigt fuer Items, die der Client noch
-- nie gesehen hat, nur ein Fragezeichen ohne Tooltip. Eine Tooltip-Abfrage per
-- SetHyperlink("item:ID...") veranlasst den Client, das Item beim Server
-- anzufragen und lokal zu cachen. Das passiert hier gedrosselt im Hintergrund.
--
-- Daten: BananaLootRaiderZoneLoot.lua (Quelle: AtlasLoot Turtle WoW Edition).

local INTERVAL = 0.25   -- Sekunden zwischen zwei Abfragen (kein Lag/Disconnect-Risiko)
local ZONE_DELAY = 3    -- Sekunden Wartezeit nach Zonenwechsel (Zonentext ist anfangs oft noch leer)

-- Lokalisierte bzw. abweichende Zonennamen -> Schluessel in BananaLootRaider_ZoneLoot.
-- Ein Schluessel gilt auch fuer alle Eintraege "<Schluessel> (...)", z.B. werden
-- alle Fluegel von Scarlet Monastery / Dire Maul zusammen geladen.
local ZONE_ALIASES = {
    -- deutsche Clients
    ["Flammenschlund"] = "Ragefire Chasm",
    ["Der Flammenschlund"] = "Ragefire Chasm",
    ["Höhlen des Wehklagens"] = "Wailing Caverns",
    ["Die Todesminen"] = "The Deadmines",
    ["Burg Schattenfang"] = "Shadowfang Keep",
    ["Das Verlies"] = "The Stockade",
    ["Tiefschwarze Grotte"] = "Blackfathom Deeps",
    ["Gnomeregan"] = "Gnomeregan",
    ["Kral der Klingenhauer"] = "Razorfen Kraul",
    ["Hügel der Klingenhauer"] = "Razorfen Downs",
    ["Scharlachrotes Kloster"] = "Scarlet Monastery",
    ["Uldaman"] = "Uldaman",
    ["Maraudon"] = "Maraudon",
    ["Zul'Farrak"] = "Zul'Farrak",
    ["Der Tempel von Atal'Hakkar"] = "The Sunken Temple",
    ["Versunkener Tempel"] = "The Sunken Temple",
    ["Die Schwarzfelstiefen"] = "Blackrock Depths",
    ["Schwarzfelstiefen"] = "Blackrock Depths",
    ["Düsterbruch"] = "Dire Maul",
    ["Scholomance"] = "Scholomance",
    ["Stratholme"] = "Stratholme",
    ["Untere Schwarzfelsspitze"] = "Lower Blackrock Spire",
    ["Obere Schwarzfelsspitze"] = "Upper Blackrock Spire",
    ["Zul'Gurub"] = "Zul'Gurub",
    ["Ruinen von Ahn'Qiraj"] = "Ruins of Ahn'Qiraj",
    ["Tempel von Ahn'Qiraj"] = "Temple of Ahn'Qiraj",
    ["Onyxias Hort"] = "Onyxia's Lair",
    ["Geschmolzener Kern"] = "Molten Core",
    ["Pechschwingenhort"] = "Blackwing Lair",
    ["Naxxramas"] = "Naxxramas",
    -- Namensabweichungen auf Turtle WoW
    ["Black Morass"] = "Caverns of Time: Black Morass",
    ["The Black Morass"] = "Caverns of Time: Black Morass",
}

local tip = CreateFrame("GameTooltip", "BananaLootRaiderPrefetchTooltip", nil, "GameTooltipTemplate")
tip:SetOwner(WorldFrame, "ANCHOR_NONE")

local queue, qHead, qTail = {}, 1, 0
local requested = {}   -- [itemID] = true, in dieser Sitzung bereits abgefragt
local total, done = 0, 0
local announce = false
local zoneName = nil

local function IsKnown(id)
    return GetItemInfo("item:" .. id .. ":0:0:0:0:0:0:0") ~= nil
end

local function Say(de, en)
    local lang = BananaLootRaider.GetLanguage and BananaLootRaider:GetLanguage() or "de"
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99BananaLoot Raider|r: " .. (lang == "en" and en or de))
end

local function Enabled()
    if not BananaLootRaider_DB or not BananaLootRaider_DB.settings then return true end
    return BananaLootRaider_DB.settings.prefetchEnabled ~= false
end

-- Sammelt alle Item-IDs der Instanz zum aktuellen Zonennamen.
local function CollectZoneItems(zone)
    local data = BananaLootRaider_ZoneLoot
    if not data or not zone or zone == "" then return nil end
    local key = ZONE_ALIASES[zone] or zone
    local ids, any = {}, false
    for name, list in pairs(data) do
        if name == key or string.sub(name, 1, string.len(key) + 2) == key .. " (" then
            any = true
            for i = 1, table.getn(list) do ids[list[i]] = true end
        end
    end
    if not any then return nil end
    return ids
end

local worker = CreateFrame("Frame")
worker:Hide()
local elapsed = 0
worker:SetScript("OnUpdate", function()
    elapsed = elapsed + arg1
    if elapsed < INTERVAL then return end
    elapsed = 0
    local id = (qHead <= qTail) and queue[qHead] or nil
    if not id then
        worker:Hide()
        if announce and total > 0 then
            Say("Item-Cache fuer " .. (zoneName or "?") .. " fertig (" .. total .. " Items angefragt).",
                "Item cache for " .. (zoneName or "?") .. " ready (" .. total .. " items requested).")
        end
        announce = false
        return
    end
    queue[qHead] = nil
    qHead = qHead + 1
    if not IsKnown(id) then
        pcall(function()
            tip:SetOwner(WorldFrame, "ANCHOR_NONE")
            tip:SetHyperlink("item:" .. id .. ":0:0:0:0:0:0:0")
        end)
    end
    done = done + 1
end)

function BananaLootRaider:PrefetchZoneItems(zone, verbose)
    -- Ist BananaLoot installiert, uebernimmt dessen Prefetch (gleicher Client-Cache): kein
    -- doppeltes Abfragen und keine doppelte Chat-Meldung. Manuell (/blr prefetch) laeuft es immer.
    if not verbose and BananaLoot and BananaLoot.PrefetchZoneItems and BananaLoot.GetPrefetchEnabled
        and BananaLoot:GetPrefetchEnabled() then
        return 0
    end
    zone = zone or GetRealZoneText()
    local ids = CollectZoneItems(zone)
    if not ids then
        if verbose then
            Say("Keine Loot-Daten fuer '" .. tostring(zone) .. "' (keine bekannte Instanz).",
                "No loot data for '" .. tostring(zone) .. "' (not a known instance).")
        end
        return 0
    end
    -- Rest der alten Queue behalten, neue unbekannte Items anhaengen
    local fresh, k = {}, 0
    for i = qHead, qTail do
        if queue[i] then k = k + 1; fresh[k] = queue[i] end
    end
    -- dauerhaft merken, was schon angefragt wurde (3 Tage), statt bei jedem Login alles neu
    BananaLootRaider.EnsureDB()
    if not BananaLootRaider_DB.prefetchSeen then BananaLootRaider_DB.prefetchSeen = {} end
    local seen, now = BananaLootRaider_DB.prefetchSeen, time()
    for id in pairs(ids) do
        if not requested[id] then
            requested[id] = true
            local t = seen[id]
            if not IsKnown(id) and (verbose or not t or (now - t) > 3 * 86400) then
                seen[id] = now
                k = k + 1; fresh[k] = id
            end
        end
    end
    queue, qHead, qTail = fresh, 1, k
    total, done, zoneName, announce = k, 0, zone, true
    if total > 0 then
        Say("Lade " .. total .. " unbekannte Items fuer " .. zone .. " vor...",
            "Preloading " .. total .. " unknown items for " .. zone .. "...")
        elapsed = 0
        worker:Show()
    elseif verbose then
        Say("Alle Items fuer " .. zone .. " sind dem Client bereits bekannt.",
            "All items for " .. zone .. " are already known to the client.")
    end
    return total
end

-- Einzelnes Item sofort beim Server anfragen (fuer Popup/Historie). Pro Item
-- hoechstens alle 5 Sekunden; force=true (z.B. Maus-Hover) ueberspringt diese Sperre.
local lastQuery = {}
function BananaLootRaider:QueryItem(id, force)
    if not id or IsKnown(id) then return end
    local now = GetTime()
    if not force and lastQuery[id] and now - lastQuery[id] < 5 then return end
    lastQuery[id] = now
    pcall(function()
        tip:SetOwner(WorldFrame, "ANCHOR_NONE")
        tip:SetHyperlink("item:" .. id .. ":0:0:0:0:0:0:0")
    end)
end

function BananaLootRaider:SetPrefetchEnabled(on)
    if not BananaLootRaider_DB then BananaLootRaider_DB = {} end
    if not BananaLootRaider_DB.settings then BananaLootRaider_DB.settings = {} end
    BananaLootRaider_DB.settings.prefetchEnabled = on and true or false
end

function BananaLootRaider:GetPrefetchEnabled()
    return Enabled()
end

-- Zonenwechsel -> nach kurzer Verzoegerung Instanz-Items vorladen
local pending = nil
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ev:SetScript("OnEvent", function()
    pending = ZONE_DELAY
    ev:Show()
end)
ev:SetScript("OnUpdate", function()
    if not pending then return end
    pending = pending - arg1
    if pending <= 0 then
        pending = nil
        if Enabled() then BananaLootRaider:PrefetchZoneItems(GetRealZoneText(), false) end
    end
end)
