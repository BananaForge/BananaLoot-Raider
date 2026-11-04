-- BananaLootRaider.lua
-- Kernlogik: SavedVariables (Settings), Roll-Sync-Empfang (identisches
-- Nachrichtenprotokoll wie BananaLoot, siehe Abschnitt 4b/4c in
-- BananaLoot.lua), geteilte Loot-Historie, Whisper-Sende-Komfort
-- (sr/unsr per Shift-Klick an einen frei eingetippten Lootmaster-Namen).
-- Vanilla 1.12 kompatibel (Lua 5.0 -> KEIN "#" Operator, KEIN string.gmatch!)
--
-- BananaLoot Raider ist bewusst KEIN Masterloot-Addon: es empfaengt nur
-- Roll-Sync-Broadcasts eines BananaLoot-Lootmasters und hilft beim
-- Senden von sr/unsr-Whispers. Es fuehrt selbst keine SR-Liste, keine
-- Vergabe und keine Loot-Fenster-Logik.

BananaLootRaider = {}
BananaLootRaider.VERSION = "1.0"

-- ============================================================
-- 1) DATENBANK / SAVEDVARIABLES
-- ============================================================
local function EnsureDB()
    if not BananaLootRaider_DB then BananaLootRaider_DB = {} end
    if not BananaLootRaider_DB.settings then BananaLootRaider_DB.settings = {} end
    -- [itemID] = { winner = Name } -- letzter per Roll-Sync bekannter
    -- Besitzer eines durch BananaLoot vergebenen Items, Grundlage fuer
    -- die Weitergabe-Erkennung im eigenen Handelsfenster (Abschnitt 4c).
    if not BananaLootRaider_DB.awardedItems then BananaLootRaider_DB.awardedItems = {} end
end
BananaLootRaider.EnsureDB = EnsureDB

-- ============================================================
-- 1a) SPRACHE / UEBERSETZUNGEN
-- ============================================================
local LOCALE = {
    de = {
        MSG_ADDON_LOADED = "|cff33ff99BananaLoot Raider|r geladen. /blr oeffnet die Loot-Historie, /blr help zeigt alle Befehle.",

        -- Roll-Sync-Popup
        RSWIN_TITLE = "BananaLoot Raider - Roll",
        RSWIN_MODE_SR = "SR",
        RSWIN_MODE_OPEN = "Offen",
        RSWIN_MODE_ARF = "ARF",
        RSWIN_TIME_LEFT = "Noch %d Sekunden",
        RSWIN_TIE = "|cffffcc00Gleichstand -- bitte erneut rollen!|r",
        RSWIN_WINNER = "Gewinner: %s (Wurf %d, Wertung %d)",
        RSWIN_NO_ROLLS = "|cff888888(noch keine Wuerfe)|r",
        RSWIN_MS_BTN = "MS",
        RSWIN_OS_BTN = "OS",
        RSWIN_TM_BTN = "TM",
        RSWIN_OVERFLOW = "|cffff5555%d weitere|r",
        RSWIN_RR_LEGEND = "|cffff5555X|r = nicht gewertet (hoehere RR)",

        TRADE_DETECTED = "|cff33ccff[BananaLoot]|r Weitergabe erkannt: %s -- %s an %s.",

        POOL_MS = "Hauptspec",
        POOL_OS = "Off-Spec",
        POOL_TMOG = "Transmog",
        POOL_MANUAL = "Manuell",
        POOL_BANK = "Bankreserve",
        POOL_RAIDROLL = "Raid Roll",

        -- Geteilte Loot-Historie
        WIN_HISTORY_TITLE = "Loot-Historie",
        WIN_HISTORY_HINT = "Nur fuer diese Session -- wird nicht gespeichert. Zeigt Vergaben eines Lootmasters mit aktiviertem Roll-Sync. Bankreserve-Vergaben erscheinen hier bewusst nicht.",
        HISTORY_EMPTY = "|cff888888(noch keine Vergaben in dieser Session)|r",
        HISTORY_OVERFLOW = "|cffff5555%d aeltere Eintraege werden nicht angezeigt|r",

        -- Optionen
        UI_TITLE_OPT = "BananaLoot Raider - Optionen",
        UI_BTN_OPTIONS = "Optionen",
        OPT_TAB_GENERAL = "Allgemein",
        OPT_TAB_DISPLAY = "Anzeige & Sound",
        OPT_ROLLSYNC_LABEL = "Roll-Sync empfangen",
        OPT_ROLLSYNC_HINT = "Zeigt ein Popup-Fenster, sobald ein Lootmaster mit BananaLoot und aktiviertem Roll-Sync einen Roll startet (Item, Countdown, laufende Wuerfe), inkl. MS/OS/TM-Buttons zum direkten Wuerfeln. Ohne diese Option passiert nichts -- normales /roll-basiertes Spielen ist davon unabhaengig.",
        OPT_TRADETRACKING_LABEL = "Trade-Tracking (automatisch)",
        OPT_TRADETRACKING_HINT = "Hilft mit, Weitergaben von durch BananaLoot vergebenen Items sichtbar zu machen (erkennt es im eigenen Handelsfenster und meldet es an andere Trade-Tracking-Nutzer weiter). Ohne eigene Loot-Log-Ansicht rein unterstuetzend fuer den/die Lootmaster.",
        OPT_SOUND_LABEL = "Sound",
        OPT_SOUND_MASTER_LABEL = "Sounds aktivieren (Hauptschalter)",
        OPT_SOUND_ROLL_LABEL = "Roll gestartet",
        OPT_SOUND_WINNER_LABEL = "Gewinner ermittelt",
        OPT_SOUND_CLICK_LABEL = "Klick-Sound auf allen Buttons",
        OPT_SCALE_LABEL = "Roll-Fenster-Skalierung in % (Standard: 100):",
        OPT_SCALE_HINT = "Verkleinert oder vergroessert das Roll-Sync-Popup, z.B. 70-90 auf kleinen Bildschirmen. Bereich: 50-150.",
        OPT_SCALE_SET = "|cff33ff99BananaLoot Raider|r: Fenster-Skalierung auf %d%% gesetzt.",
        OPT_SCALE_INVALID = "|cffff5555BananaLoot Raider|r: Bitte einen Wert zwischen 50 und 150 eingeben.",
        OPT_LANGUAGE_LABEL = "Sprache der Chat- und UI-Ausgaben:",
        OPT_LANGUAGE_SET = "|cff33ff99BananaLoot Raider|r: Sprache umgestellt.",
        OPT_SAVE_BTN = "Speichern",

        -- SR/unSR-Komfort per Shift-Klick
        UI_SR_TITLE = "SR an Lootmaster senden",
        UI_SR_HINT = "Item per Shift-Klick einfuegen, Lootmaster-Namen eintragen, dann senden. Genaue Schreibweise des Namens beachten.",
        UI_SR_NAME_LABEL = "Lootmaster:",
        UI_SR_ITEM_LABEL = "Item:",
        UI_SR_SEND_BTN = "sr senden",
        UI_SR_UNSEND_BTN = "unsr senden",
        UI_SR_NEED_NAME = "|cffff5555BananaLoot Raider|r: Bitte einen Lootmaster-Namen eintragen.",
        UI_SR_NEED_ITEM = "|cffff5555BananaLoot Raider|r: Bitte zuerst ein Item per Shift-Klick einfuegen.",
        UI_SR_SENT = "|cff33ff99BananaLoot Raider|r: 'sr %s' an %s gesendet.",
        UI_SR_UNSENT = "|cff33ff99BananaLoot Raider|r: 'unsr %s' an %s gesendet.",

        -- Slash-Befehle / Hilfe
        UI_BTN_HELP_TOOLTIP = "Befehlsuebersicht anzeigen",
        WIN_HELP_TITLE = "Befehlsuebersicht",
        WIN_HELP_HINT = "Strg+A, Strg+C zum Kopieren",
        CMD_LEGEND_TEXT = "=== SLASH-BEFEHLE (Raider) ===\n" ..
            "/blr                   Loot-Historie oeffnen/schliessen\n" ..
            "/blr sr                SR-Sende-Fenster oeffnen (sr/unsr per Shift-Klick)\n" ..
            "/blr options           Einstellungen oeffnen\n" ..
            "/blr help              Diese Uebersicht anzeigen\n" ..
            "\n" ..
            "=== WHISPER AN DEN LOOTMASTER (von Hand) ===\n" ..
            "sr [Item]              Item reservieren\n" ..
            "unsr [Item]            Reservierung entfernen\n" ..
            "srlist                 Eigene Reservierungen anzeigen\n" ..
            "hr / hrlist            Aktuelle Hard-Reserve-Items anzeigen\n" ..
            "\n" ..
            "=== ROLL-KATEGORIEN ===\n" ..
            "/roll                  Hauptspec (1-100)\n" ..
            "/roll 1 99             Off-Spec\n" ..
            "/roll 1 98             Transmog",
        CMD_HELP = "|cff33ff99BananaLoot Raider|r Befehle: /blr, /blr sr, /blr options, /blr help",

        -- Minimap
        MM_TOOLTIP_LEFT = "Linksklick: Loot-Historie oeffnen",
        MM_TOOLTIP_RIGHT = "Rechtsklick: Einstellungen",
        MM_TOOLTIP_SHIFT = "Shift-Linksklick: SR-Sende-Fenster",
        MM_TOOLTIP_DRAG = "Ziehen: Position am Minimap-Rand aendern",
    },

    en = {
        MSG_ADDON_LOADED = "|cff33ff99BananaLoot Raider|r loaded. /blr opens the loot history, /blr help shows all commands.",

        RSWIN_TITLE = "BananaLoot Raider - Roll",
        RSWIN_MODE_SR = "SR",
        RSWIN_MODE_OPEN = "Open",
        RSWIN_MODE_ARF = "ARF",
        RSWIN_TIME_LEFT = "%d seconds left",
        RSWIN_TIE = "|cffffcc00Tie -- please roll again!|r",
        RSWIN_WINNER = "Winner: %s (roll %d, score %d)",
        RSWIN_NO_ROLLS = "|cff888888(no rolls yet)|r",
        RSWIN_MS_BTN = "MS",
        RSWIN_OS_BTN = "OS",
        RSWIN_TM_BTN = "TM",
        RSWIN_OVERFLOW = "|cffff5555%d more|r",
        RSWIN_RR_LEGEND = "|cffff5555X|r = not counted (higher RR)",

        TRADE_DETECTED = "|cff33ccff[BananaLoot]|r Handoff detected: %s -- %s to %s.",

        POOL_MS = "Main Spec",
        POOL_OS = "Off-Spec",
        POOL_TMOG = "Transmog",
        POOL_MANUAL = "Manual",
        POOL_BANK = "Bank Reserve",
        POOL_RAIDROLL = "Raid Roll",

        WIN_HISTORY_TITLE = "Loot History",
        WIN_HISTORY_HINT = "Current session only -- not saved. Shows awards from a loot master with roll-sync enabled. Bank reserve awards deliberately don't appear here.",
        HISTORY_EMPTY = "|cff888888(no awards in this session yet)|r",
        HISTORY_OVERFLOW = "|cffff5555%d older entries not shown|r",

        UI_TITLE_OPT = "BananaLoot Raider - Options",
        UI_BTN_OPTIONS = "Options",
        OPT_TAB_GENERAL = "General",
        OPT_TAB_DISPLAY = "Display & Sound",
        OPT_ROLLSYNC_LABEL = "Receive roll sync",
        OPT_ROLLSYNC_HINT = "Shows a popup window whenever a loot master running BananaLoot with roll-sync enabled starts a roll (item, countdown, incoming rolls), with MS/OS/TM buttons to roll directly. With this off, nothing happens -- normal /roll-based play is unaffected.",
        OPT_TRADETRACKING_LABEL = "Trade tracking (automatic)",
        OPT_TRADETRACKING_HINT = "Helps make hand-offs of items awarded via BananaLoot traceable (detects it in your own trade window and relays it to other trade-tracking users). No own loot-log view -- purely supportive of the loot master(s).",
        OPT_SOUND_LABEL = "Sound",
        OPT_SOUND_MASTER_LABEL = "Enable sounds (master switch)",
        OPT_SOUND_ROLL_LABEL = "Roll started",
        OPT_SOUND_WINNER_LABEL = "Winner determined",
        OPT_SOUND_CLICK_LABEL = "Click sound on all buttons",
        OPT_SCALE_LABEL = "Roll window scale in % (default: 100):",
        OPT_SCALE_HINT = "Shrinks or enlarges the roll-sync popup, e.g. 70-90 on small screens. Range: 50-150.",
        OPT_SCALE_SET = "|cff33ff99BananaLoot Raider|r: Window scale set to %d%%.",
        OPT_SCALE_INVALID = "|cffff5555BananaLoot Raider|r: Please enter a value between 50 and 150.",
        OPT_LANGUAGE_LABEL = "Chat and UI language:",
        OPT_LANGUAGE_SET = "|cff33ff99BananaLoot Raider|r: Language switched.",
        OPT_SAVE_BTN = "Save",

        UI_SR_TITLE = "Send SR to loot master",
        UI_SR_HINT = "Shift-click the item in, enter the loot master's name, then send. Watch the exact spelling of the name.",
        UI_SR_NAME_LABEL = "Loot master:",
        UI_SR_ITEM_LABEL = "Item:",
        UI_SR_SEND_BTN = "send sr",
        UI_SR_UNSEND_BTN = "send unsr",
        UI_SR_NEED_NAME = "|cffff5555BananaLoot Raider|r: Please enter a loot master name.",
        UI_SR_NEED_ITEM = "|cffff5555BananaLoot Raider|r: Please shift-click an item first.",
        UI_SR_SENT = "|cff33ff99BananaLoot Raider|r: sent 'sr %s' to %s.",
        UI_SR_UNSENT = "|cff33ff99BananaLoot Raider|r: sent 'unsr %s' to %s.",

        UI_BTN_HELP_TOOLTIP = "Show command legend",
        WIN_HELP_TITLE = "Command Legend",
        WIN_HELP_HINT = "Ctrl+A, Ctrl+C to copy",
        CMD_LEGEND_TEXT = "=== SLASH COMMANDS (Raider) ===\n" ..
            "/blr                   Open/close loot history\n" ..
            "/blr sr                Open the SR send window (sr/unsr via shift-click)\n" ..
            "/blr options           Open settings\n" ..
            "/blr help              Show this legend\n" ..
            "\n" ..
            "=== WHISPER TO THE LOOT MASTER (by hand) ===\n" ..
            "sr [Item]              Reserve item\n" ..
            "unsr [Item]            Remove reservation\n" ..
            "srlist                 Show your own reservations\n" ..
            "hr / hrlist            Show current Hard Reserve items\n" ..
            "\n" ..
            "=== ROLL CATEGORIES ===\n" ..
            "/roll                  Main Spec (1-100)\n" ..
            "/roll 1 99             Off-Spec\n" ..
            "/roll 1 98             Transmog",
        CMD_HELP = "|cff33ff99BananaLoot Raider|r Commands: /blr, /blr sr, /blr options, /blr help",

        MM_TOOLTIP_LEFT = "Left-click: open loot history",
        MM_TOOLTIP_RIGHT = "Right-click: settings",
        MM_TOOLTIP_SHIFT = "Shift-left-click: SR send window",
        MM_TOOLTIP_DRAG = "Drag: change position along minimap edge",
    },
}

function BananaLootRaider:GetLanguage()
    EnsureDB()
    return BananaLootRaider_DB.settings.language or "de"
end

function BananaLootRaider:SetLanguage(lang)
    EnsureDB()
    if lang ~= "de" and lang ~= "en" then return false end
    BananaLootRaider_DB.settings.language = lang
    return true
end

function BananaLootRaider:L(key)
    local lang = self:GetLanguage()
    local tbl = LOCALE[lang] or LOCALE.de
    return tbl[key] or LOCALE.de[key] or key
end

-- ============================================================
-- 1b) OPTIONEN (Getter/Setter)
-- ============================================================
function BananaLootRaider:GetRollSyncEnabled()
    EnsureDB()
    if BananaLootRaider_DB.settings.rollSyncEnabled == nil then return true end
    return BananaLootRaider_DB.settings.rollSyncEnabled
end

function BananaLootRaider:SetRollSyncEnabled(value)
    EnsureDB()
    BananaLootRaider_DB.settings.rollSyncEnabled = value and true or false
end

function BananaLootRaider:GetTradeTrackingEnabled()
    EnsureDB()
    if BananaLootRaider_DB.settings.tradeTrackingEnabled == nil then return true end
    return BananaLootRaider_DB.settings.tradeTrackingEnabled
end

function BananaLootRaider:SetTradeTrackingEnabled(value)
    EnsureDB()
    BananaLootRaider_DB.settings.tradeTrackingEnabled = value and true or false
end

function BananaLootRaider:GetSoundEnabled()
    EnsureDB()
    if BananaLootRaider_DB.settings.soundEnabled == nil then return true end
    return BananaLootRaider_DB.settings.soundEnabled
end

function BananaLootRaider:SetSoundEnabled(value)
    EnsureDB()
    BananaLootRaider_DB.settings.soundEnabled = value and true or false
end

function BananaLootRaider:GetSoundRollStartedEnabled()
    EnsureDB()
    if BananaLootRaider_DB.settings.soundRollStarted == nil then return true end
    return BananaLootRaider_DB.settings.soundRollStarted
end

function BananaLootRaider:SetSoundRollStartedEnabled(value)
    EnsureDB()
    BananaLootRaider_DB.settings.soundRollStarted = value and true or false
end

function BananaLootRaider:GetSoundWinnerEnabled()
    EnsureDB()
    if BananaLootRaider_DB.settings.soundWinner == nil then return true end
    return BananaLootRaider_DB.settings.soundWinner
end

function BananaLootRaider:SetSoundWinnerEnabled(value)
    EnsureDB()
    BananaLootRaider_DB.settings.soundWinner = value and true or false
end

function BananaLootRaider:GetSoundButtonClicksEnabled()
    EnsureDB()
    if BananaLootRaider_DB.settings.soundButtonClicks == nil then return true end
    return BananaLootRaider_DB.settings.soundButtonClicks
end

function BananaLootRaider:SetSoundButtonClicksEnabled(value)
    EnsureDB()
    BananaLootRaider_DB.settings.soundButtonClicks = value and true or false
end

function BananaLootRaider:PlayEventSound(soundName, specificEnabled)
    if not self:GetSoundEnabled() then return end
    if not specificEnabled then return end
    pcall(function() PlaySound(soundName) end)
end

function BananaLootRaider:PlayClickSound()
    if not self:GetSoundEnabled() then return end
    if not self:GetSoundButtonClicksEnabled() then return end
    pcall(function() PlaySound("igMainMenuOptionCheckBoxOn") end)
end

-- Skalierung des Roll-Sync-Popups in Prozent (Standard: 100, Bereich 50-150).
function BananaLootRaider:GetUIScalePercent()
    EnsureDB()
    return BananaLootRaider_DB.settings.uiScalePercent or 100
end

function BananaLootRaider:SetUIScalePercent(value)
    EnsureDB()
    value = tonumber(value)
    if not value or value < 50 or value > 150 then return false end
    BananaLootRaider_DB.settings.uiScalePercent = value
    return true
end

function BananaLootRaider:GetUIScale()
    return self:GetUIScalePercent() / 100
end

-- ============================================================
-- 2) HILFSFUNKTIONEN: Klassenfarben, Item-Qualitaetsfarben, Item-DB
-- ============================================================
local QUALITY_COLOR_HEX = {
    [0] = "9d9d9d", [1] = "ffffff", [2] = "1eff00", [3] = "0070dd",
    [4] = "a335ee", [5] = "ff8000", [6] = "e6cc80",
}

BananaLootRaider.itemQualityHints = {} -- [itemID] = Qualitaetsstufe, aus der statischen DB bzw. Roll-Sync-Kontext

function BananaLootRaider:GetQualityColorHex(itemID)
    local quality = self.itemQualityHints[itemID]
    return (quality and QUALITY_COLOR_HEX[quality]) or "ffffff"
end

local CLASS_COLOR_HEX = {
    WARRIOR = "c79c6e", PALADIN = "f58cba", HUNTER = "abd473",
    ROGUE = "fff569", PRIEST = "ffffff", SHAMAN = "0070de",
    MAGE = "69ccf0", WARLOCK = "9482c9", DRUID = "ff7d0a",
}

BananaLootRaider.playerClasses = {} -- [name] = Klassen-Token, aus dem Raid-/Gruppen-Roster

function BananaLootRaider:GetClassColorHex(name)
    local class = self.playerClasses[name]
    return (class and CLASS_COLOR_HEX[class]) or "ffffff"
end

function BananaLootRaider:ColoredName(name)
    if not name then return name end
    return "|cff" .. self:GetClassColorHex(name) .. name .. "|r"
end

-- Baut nebenbei den Klassen-Farb-Cache mit auf, siehe BananaLoot.lua
-- (identisches Prinzip, hier nur lesend fuer die Anzeige gebraucht).
local function RefreshRosterClassCache()
    local n = GetNumRaidMembers()
    if n > 0 then
        for i = 1, n do
            local name = UnitName("raid" .. i)
            if name then
                local _, class = UnitClass("raid" .. i)
                if class then BananaLootRaider.playerClasses[name] = class end
            end
        end
    else
        local myName = UnitName("player")
        local _, myClass = UnitClass("player")
        if myClass then BananaLootRaider.playerClasses[myName] = myClass end
        local pn = GetNumPartyMembers()
        for i = 1, pn do
            local name = UnitName("party" .. i)
            if name then
                local _, class = UnitClass("party" .. i)
                if class then BananaLootRaider.playerClasses[name] = class end
            end
        end
    end
end

function BananaLootRaider:GetStaticItemInfo(itemID)
    if not BananaLootRaider_ItemDB then return nil end
    return BananaLootRaider_ItemDB[itemID]
end

function BananaLootRaider:BuildItemLink(itemID, name)
    return "|cff" .. self:GetQualityColorHex(itemID) .. "|Hitem:" .. itemID .. ":0:0:0:0:0:0:0|h[" .. name .. "]|h|r"
end

-- Loest best-effort einen anzeigbaren Item-Link/Text aus einer itemID auf
-- (kein Link wird per Roll-Sync mitgesendet, siehe Protokollkommentar in
-- BananaLoot.lua). Statische DB zuerst, dann GetItemInfo, sonst Platzhalter.
function BananaLootRaider:ResolveItemDisplay(itemID)
    local staticInfo = self:GetStaticItemInfo(itemID)
    if staticInfo and staticInfo.name then
        if staticInfo.quality and not self.itemQualityHints[itemID] then
            self.itemQualityHints[itemID] = staticInfo.quality
        end
        return self:BuildItemLink(itemID, staticInfo.name)
    end
    local itemName = GetItemInfo("item:" .. itemID .. ":0:0:0:0:0:0:0")
    if itemName then
        return self:BuildItemLink(itemID, itemName)
    end
    return "|cff" .. self:GetQualityColorHex(itemID) .. "Item #" .. itemID .. "|r"
end

-- Best-effort Icon fuer eine Item-ID, gleiche Prioritaet wie in
-- BananaLootUI.lua (statische DB kennt keine Icons, daher primaer
-- GetItemInfo/Bag-Scan).
local function GetBagIconForItem(itemID)
    for bag = 0, 4 do
        local slots = GetContainerNumSlots(bag)
        if slots and slots > 0 then
            for slot = 1, slots do
                local link = GetContainerItemLink(bag, slot)
                if link then
                    local _, _, id = string.find(link, "item:(%d+)")
                    if id and tonumber(id) == itemID then
                        local texture = GetContainerItemInfo(bag, slot)
                        if type(texture) == "string" and texture ~= "" then
                            return texture
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- Textur aus GetItemInfo. Die Position des Icons unterscheidet sich je nach
-- Client: in 1.12 ist es der 9. Rueckgabewert (kein itemLevel), in neueren
-- Clients der 10. Der Index wird daher nicht fest angenommen, sondern das
-- erste Ergebnis genommen, das wie ein Icon-Pfad aussieht.
function BananaLootRaider:GetItemTexture(id)
    local r = { GetItemInfo("item:" .. id .. ":0:0:0:0:0:0:0") }
    for i = 8, 10 do
        local v = r[i]
        if type(v) == "string" and string.find(string.lower(v), "^interface") then
            return v
        end
    end
    return nil
end

BananaLootRaider.pendingIcons = {} -- [itemID] = Anzahl bisheriger Versuche

function BananaLootRaider:ResolveItemIcon(id)
    local itemTexture = self:GetItemTexture(id)
    local bagIcon = GetBagIconForItem(id)
    local staticInfo = self:GetStaticItemInfo(id)
    local staticIcon = staticInfo and staticInfo.icon or nil
    local iconFromDedicatedApi = nil
    if GetItemIcon then
        local ok, result = pcall(GetItemIcon, "item:" .. id .. ":0:0:0:0:0:0:0")
        if ok then iconFromDedicatedApi = result end
    end

    -- Prioritaet identisch zu BananaLootUI.lua:ResolveRowIcon (ohne den
    -- dortigen knownLootIcons-Cache, der nur beim Lootmaster durch das
    -- eigene Scannen des Loot-Fensters entsteht): Bag-Icon zuerst (wenn
    -- das Item im eigenen Inventar liegt, ist das die "Wahrheit"), dann
    -- das neue Icon-Feld der statischen Item-DB (sofort verfuegbar, ganz
    -- ohne auf den Server zu warten), erst danach die unzuverlaessigeren
    -- Server-Abfragen.
    local texture = nil
    if type(bagIcon) == "string" and bagIcon ~= "" then
        texture = bagIcon
    elseif type(staticIcon) == "string" and staticIcon ~= "" then
        texture = "Interface\\Icons\\" .. staticIcon
    elseif type(iconFromDedicatedApi) == "string" and iconFromDedicatedApi ~= "" then
        texture = iconFromDedicatedApi
    elseif type(itemTexture) == "string" and itemTexture ~= "" then
        texture = itemTexture
    end

    if texture then
        self.pendingIcons[id] = nil
        return texture
    end

    if self.pendingIcons[id] == nil then
        self.pendingIcons[id] = 0
    end
    -- Dem Client unbekanntes Item aktiv beim Server anfragen (sonst wartet
    -- der Retry nur darauf, dass irgendwer das Item zufaellig sieht).
    if self.QueryItem then self:QueryItem(id) end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- ============================================================
-- 3) SR/unSR-KOMFORT: sendet "sr [Item]"/"unsr [Item]" per Whisper an
-- einen frei eingetippten Lootmaster-Namen. Rein sendend -- BananaLoot
-- Raider fuehrt selbst keine SR-Liste und wertet keine Antworten aus
-- (die kommen als normaler Whisper vom Lootmaster zurueck, wie ohne
-- Addon auch).
-- ============================================================
local function SendWhisper(target, msg)
    SendChatMessage(msg, "WHISPER", nil, target)
end

function BananaLootRaider:SendSR(lootmasterName, itemLink)
    if not lootmasterName or lootmasterName == "" then return false, "need_name" end
    if not itemLink or itemLink == "" then return false, "need_item" end
    SendWhisper(lootmasterName, "sr " .. itemLink)
    return true
end

function BananaLootRaider:SendUnSR(lootmasterName, itemLink)
    if not lootmasterName or lootmasterName == "" then return false, "need_name" end
    if not itemLink or itemLink == "" then return false, "need_item" end
    SendWhisper(lootmasterName, "unsr " .. itemLink)
    return true
end

-- ============================================================
-- 4) ROLL-SYNC-EMPFANG (identisches Protokoll wie BananaLoot.lua,
-- Abschnitt 4b/4c -- gleicher Prefix, gleiches Nachrichtenformat, damit
-- Broadcasts eines BananaLoot-Lootmasters empfangen werden koennen):
--   RS~itemID~dauerSek~modus              Roll gestartet (modus: 0 offen, 1 SR, 2 ARF)
--   RU~itemID~Spieler~Wert~Typ[~RR]       Einzelner gezaehlter Wurf (Typ: ms/os/tmog;
--                                         RR = Round-Robin-Stufe, nur bei aktivem RR-MS)
--   RT~itemID~Namen(Komma-getrennt)       Gleichstand, nur diese Spieler rollen erneut
--   RW~itemID~Gewinner~Score~Wurf~Pool    Roll abgeschlossen (Pool: ms/os/tmog)
--   RC~itemID~Grund                       Abgebrochen (Grund: 0 manuell, 1 niemand gerollt)
--   AW~itemID~Gewinner~PoolCode           Vergabe (fuer geteilte Loot-Historie)
--   TT~itemID~Von~An                      Trade-Tracking-Weitergabe
--   RL~Schluessel                         Raidlead-Ansage eines anderen Clients
--                                         (nur Lootmaster-Feature, wird ignoriert)
-- ============================================================
local ROLL_SYNC_PREFIX = "BananaLoot"

local function Split(str, sep)
    local result = {}
    local start = 1
    while true do
        local s, e = string.find(str, sep, start, true)
        if not s then
            table.insert(result, string.sub(str, start))
            break
        end
        table.insert(result, string.sub(str, start, s - 1))
        start = e + 1
    end
    return result
end

-- ------------------------------------------------------------
-- 4c) TRADE-TRACKING: identische Logik wie beim Lootmaster
-- (BananaLoot.lua Abschnitt 4c), hier als Empfaenger/Mitwirkender.
-- SendAddonMessage an "RAID"/"PARTY" erreicht bereits in einem Schritt
-- JEDEN im Kanal -- ein zusaetzliches Weiterleiten ist unnoetig und
-- wuerde bei mehreren Trade-Tracking-Nutzern nur zu doppelten/
-- mehrfachen Meldungen fuehren. Stattdessen merkt sich jeder Client mit
-- aktiviertem Trade-Tracking selbst den letzten bekannten Besitzer
-- (awardedItems, aus AW-Nachrichten gespeist) und meldet nur SELBST
-- beobachtete Handelsvorgaenge (eigenes Handelsfenster) per TT-Broadcast.
-- ------------------------------------------------------------
local function GetItemIDFromLink(link)
    if not link then return nil end
    local _, _, id = string.find(link, "item:(%d+)")
    if id then return tonumber(id) end
    return nil
end

local function SendTradeTrackingMessage(text)
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then return end
    local channel = GetNumRaidMembers() > 0 and "RAID" or "PARTY"
    pcall(function() SendAddonMessage(ROLL_SYNC_PREFIX, text, channel) end)
end

local function BroadcastTrade(itemID, fromName, toName)
    SendTradeTrackingMessage("TT~" .. itemID .. "~" .. fromName .. "~" .. toName)
end

-- Liefert best-effort einen reinen Item-Namen (ohne Farbe/Link) zu einer
-- Item-ID, fuer die Chat-Meldung -- dieselbe Fallback-Kette (statische DB
-- zuerst, dann GetItemInfo) wie an anderen Stellen im Addon.
local function ResolveItemNameForItemID(itemID)
    local staticInfo = BananaLootRaider:GetStaticItemInfo(itemID)
    if staticInfo and staticInfo.name then return staticInfo.name end
    return GetItemInfo("item:" .. itemID .. ":0:0:0:0:0:0:0")
end

-- Zentrale Stelle fuer einen erkannten Besitzerwechsel eines ueber
-- BananaLoot vergebenen Items -- egal ob lokal im eigenen Handelsfenster
-- erkannt (broadcast=true, siehe HandleTradeMatch) oder per TT-Netzwerk-
-- nachricht von einem anderen Trade-Tracking-Client empfangen
-- (broadcast=false, siehe HandleRollSyncMessage).
function BananaLootRaider:RecordTradeHandoff(itemID, fromName, toName, broadcast)
    EnsureDB()
    BananaLootRaider_DB.awardedItems[itemID] = { winner = toName }

    local itemName = ResolveItemNameForItemID(itemID)
    DEFAULT_CHAT_FRAME:AddMessage(string.format(self:L("TRADE_DETECTED"), itemName or ("Item " .. itemID), fromName, toName))

    if broadcast then
        BroadcastTrade(itemID, fromName, toName)
    end
end

-- Prueft ein per Handelsfenster beobachtetes Item (siehe SnapshotTradeItems
-- unten): nur wenn "fromName" laut awardedItems der zuletzt bekannte
-- Besitzer dieses ueber BananaLoot vergebenen Items ist, wird es als
-- Weitergabe gewertet.
function BananaLootRaider:HandleTradeMatch(itemID, fromName, toName)
    if not self:GetTradeTrackingEnabled() then return end
    EnsureDB()
    local entry = BananaLootRaider_DB.awardedItems[itemID]
    if not entry or entry.winner ~= fromName then return end
    self:RecordTradeHandoff(itemID, fromName, toName, true)
end

-- Liest die eigene, gerade beidseitig akzeptierte Handelssitzung aus
-- (GetTradePlayerItemLink/GetTradeTargetItemLink liefern nur in diesem
-- kurzen Zeitfenster gueltige Daten, siehe TRADE_ACCEPT_UPDATE-Handler
-- weiter unten) und prueft jeden der bis zu 6 Item-Slots je Seite.
-- UnitName("NPC") ist trotz des irrefuehrenden Namens der korrekte
-- Unit-Token fuer den Handelspartner (Blizzard-FrameXML-Konvention).
local function SnapshotTradeItems()
    if not BananaLootRaider:GetTradeTrackingEnabled() then return end
    local partnerName = UnitName("NPC")
    if not partnerName then return end
    local myName = UnitName("player")

    for i = 1, 6 do
        local givenLink = GetTradePlayerItemLink(i)
        if givenLink then
            local id = GetItemIDFromLink(givenLink)
            if id then BananaLootRaider:HandleTradeMatch(id, myName, partnerName) end
        end
        local receivedLink = GetTradeTargetItemLink(i)
        if receivedLink then
            local id = GetItemIDFromLink(receivedLink)
            if id then BananaLootRaider:HandleTradeMatch(id, partnerName, myName) end
        end
    end
end
BananaLootRaider.SnapshotTradeItems = SnapshotTradeItems

function BananaLootRaider:HandleRollSyncMessage(text, sender)
    local isSelf = (sender == UnitName("player"))
    local fields = Split(text, "~")
    local msgType = fields[1]

    if msgType == "AW" then
        if not isSelf and BananaLootRaider_UI and BananaLootRaider_UI.AddHistoryEntry then
            BananaLootRaider_UI:AddHistoryEntry(tonumber(fields[2]), fields[3], fields[4])
        end
        -- Merkt sich auf JEDEM Client mit aktiviertem Trade-Tracking (nicht
        -- nur beim Lootmaster) den aktuellen Besitzer eines ueber BananaLoot
        -- vergebenen Items, damit ein spaeterer Trade dieses Items -- auf
        -- welchem Client auch immer er stattfindet -- erkannt werden kann.
        if self:GetTradeTrackingEnabled() then
            local itemID = tonumber(fields[2])
            if itemID and fields[3] then
                EnsureDB()
                BananaLootRaider_DB.awardedItems[itemID] = { winner = fields[3] }
            end
        end
        return
    end

    -- RL: Raidlead-Ansage eines anderen BananaLoot-Clients -- reines
    -- Lootmaster-Feature (verhindert doppeltes Posten von Boss-Ansagen
    -- unter mehreren Raidleads), fuer BananaLoot Raider ohne Bedeutung.
    if msgType == "RL" then return end

    if msgType == "TT" then
        if self:GetTradeTrackingEnabled() and not isSelf then
            local itemID = tonumber(fields[2])
            if itemID and fields[3] and fields[4] then
                self:RecordTradeHandoff(itemID, fields[3], fields[4], false)
            end
        end
        return
    end

    if not self:GetRollSyncEnabled() then return end

    if BananaLootRaider_UI and BananaLootRaider_UI.HandleRollSync then
        BananaLootRaider_UI:HandleRollSync(msgType, fields, sender)
    end
end

-- ============================================================
-- 5) EVENT HANDLING
-- ============================================================
local eventFrame = CreateFrame("Frame", "BananaLootRaiderEventFrame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
eventFrame:RegisterEvent("TRADE_ACCEPT_UPDATE")

eventFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "BananaLootRaider" then
        EnsureDB()
        DEFAULT_CHAT_FRAME:AddMessage(BananaLootRaider:L("MSG_ADDON_LOADED"))
        if BananaLootRaider_UI and BananaLootRaider_UI.ApplyLocaleAll then BananaLootRaider_UI:ApplyLocaleAll() end
        RefreshRosterClassCache()

    elseif event == "CHAT_MSG_ADDON" then
        if arg1 == ROLL_SYNC_PREFIX then
            BananaLootRaider:HandleRollSyncMessage(arg2, arg4)
        end

    elseif event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" then
        RefreshRosterClassCache()

    elseif event == "TRADE_ACCEPT_UPDATE" then
        -- arg1/arg2 = playerAccepted/targetAccepted (0 oder 1). Erst wenn
        -- BEIDE Seiten akzeptiert haben, liefern GetTradePlayerItemLink/
        -- GetTradeTargetItemLink noch kurz vor dem eigentlichen Abschluss
        -- gueltige Daten.
        if arg1 == 1 and arg2 == 1 then
            BananaLootRaider.SnapshotTradeItems()
        end
    end
end)

-- ============================================================
-- 6) SLASH COMMANDS
-- ============================================================
local function Trim(str)
    if not str then return str end
    local _, _, captured = string.find(str, "^%s*(.-)%s*$")
    return captured or str
end

SLASH_BANANALOOTRAIDER1 = "/blr"
SLASH_BANANALOOTRAIDER2 = "/bananalootraider"
SlashCmdList["BANANALOOTRAIDER"] = function(msg)
    msg = Trim(msg or "")
    local cmd = string.lower(msg)

    if cmd == "sr" then
        if BananaLootRaider_UI and BananaLootRaider_UI.ToggleSR then BananaLootRaider_UI:ToggleSR() end

    elseif cmd == "options" or cmd == "config" then
        if BananaLootRaider_UI and BananaLootRaider_UI.ToggleOptions then BananaLootRaider_UI:ToggleOptions() end

    elseif cmd == "prefetch" then
        BananaLootRaider:PrefetchZoneItems(GetRealZoneText(), true)

    elseif cmd == "prefetch off" or cmd == "prefetch on" then
        BananaLootRaider:SetPrefetchEnabled(cmd == "prefetch on")
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99BananaLoot Raider|r: Prefetch " .. (cmd == "prefetch on" and "on" or "off"))

    elseif cmd == "help" then
        if BananaLootRaider_UI and BananaLootRaider_UI.ShowHelp then BananaLootRaider_UI:ShowHelp() end

    elseif cmd == "" then
        if BananaLootRaider_UI and BananaLootRaider_UI.Toggle then BananaLootRaider_UI:Toggle() end

    else
        DEFAULT_CHAT_FRAME:AddMessage(BananaLootRaider:L("CMD_HELP"))
    end
end
