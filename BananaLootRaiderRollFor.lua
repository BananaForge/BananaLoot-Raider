-- BananaLootRaiderRollFor.lua
-- Raids OHNE BananaLoot: BananaLoot Raider erkennt beim Betreten einer Gruppe, ob jemand BananaLoot benutzt, und
-- liest sonst mit, was das Addon RollFor (github.com/sica42/RollFor) des Loot-Masters verteilt. Man muss RollFor
-- NICHT selbst installiert haben.
--
--  * Addon-Nachrichten (Praefix "RollFor", "ROLL::<Befehl>::<Daten>", auch in Teilen "ROLL::CHUNK::i::n::...") werden
--    in das vorhandene Roll-Sync-Fenster uebersetzt: START_ROLL (Item, Zeit, SR-Spieler), ROLL (MS/OS/TM-Wuerfe),
--    TIE, FINISH (Gewinner), CANCEL_ROLL, AWARDED.
--  * RollFor schreibt die Beute-Ansage in den Raidchat ("1. [Item] (HR)", "2. [Item] (SR by Name [2 rolls] (+3), ...)").
--    Daraus liest Raider die SR-/HR-Info je Item fuer den Tooltip (nur Raidchat/Gruppenchat).
--  * Beim Betreten einer Gruppe fragt Raider per "HQ" nach BananaLoot. Antwortet niemand (und kommt auch keine andere
--    BananaLoot-Nachricht), sind die BananaLoot-Funktionen "SR einreichen" und "SR+ Liste" ausgegraut.
--
-- Lua 5.0: kein #, kein string.match/gmatch.

local RF = {}
BananaLootRaider_RollFor = RF

local PROBE_WAIT = 8          -- Sekunden Wartezeit auf BananaLoot-Antworten nach dem Beitritt
local CHUNK_TIMEOUT = 20

BananaLootRaider.raidMode = "unknown"     -- "unknown" | "bananaloot" | "rollfor" | "none"
BananaLootRaider.rfSR = {}                -- [itemID] = { { n = Name, p = SR+, rolls = n }, ... }  (aus dem Raidchat)
BananaLootRaider.rfHR = {}                -- [itemID] = true

-- ------------------------------------------------------------
-- Parser fuer RollFors Datenformat: {["i"]={["id"]=123,...},[1]={...}} (Leerzeichen entfernt)
-- ------------------------------------------------------------
local function ParseTable(str)
    local pos = string.find(str, "{", 1, true)
    if not pos then return nil end
    local len = string.len(str)
    local function parse()
        pos = pos + 1
        local t = {}
        while pos <= len do
            local c = string.sub(str, pos, pos)
            if c == "}" then
                pos = pos + 1
                return t
            elseif c == "[" then
                local e = string.find(str, "]=", pos, true)
                if not e then return t end
                local key = string.sub(str, pos + 1, e - 1)
                key = string.gsub(key, "\"", "")
                key = tonumber(key) or key
                pos = e + 2
                if string.sub(str, pos, pos) == "{" then
                    t[key] = parse()
                else
                    local s = string.find(str, "[,}]", pos)
                    if not s then s = len + 1 end
                    local raw = string.sub(str, pos, s - 1)
                    if raw == "true" then t[key] = true
                    elseif raw == "false" then t[key] = false
                    elseif raw == "nil" then t[key] = nil
                    else t[key] = tonumber(raw) or raw end
                    pos = s
                end
            else
                pos = pos + 1
            end
        end
        return t
    end
    return parse()
end
RF.ParseTable = ParseTable

-- ------------------------------------------------------------
-- BananaLoot-Erkennung / Verfuegbarkeit der BananaLoot-Funktionen
-- ------------------------------------------------------------
local greyedBtns = { "BananaLootRaiderHistorySrBtn", "BananaLootRaiderHistoryListBtn" }

local function HookTooltip(btn)
    if btn.blRfHooked then return end
    btn.blRfHooked = true
    local old = btn:GetScript("OnEnter")
    btn:SetScript("OnEnter", function()
        if old then old() end
        if BananaLootRaider.raidMode == "none" then
            if not GameTooltip:IsShown() then GameTooltip:SetOwner(btn, "ANCHOR_RIGHT") end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(BananaLootRaider:L("RF_DISABLED_TIP"), 1, 0.5, 0.2, 1)
            GameTooltip:Show()
        end
    end)
end

function BananaLootRaider:ApplyAvailability()
    local off = (self.raidMode == "none")
    for i = 1, table.getn(greyedBtns) do
        local b = getglobal(greyedBtns[i])
        if b then
            HookTooltip(b)
            if off then b:Disable() else b:Enable() end
        end
    end
    if self.RefreshAvailabilityLabel then self:RefreshAvailabilityLabel() end
end

function BananaLootRaider:SetRaidMode(mode)
    if self.raidMode == mode then return end
    self.raidMode = mode
    self:ApplyAvailability()
end

-- Eine echte BananaLoot-Nachricht aus meiner Gruppe (oder Testmodus) ist angekommen.
function BananaLootRaider:NoteBananaLoot(channel)
    if channel and channel ~= "RAID" and channel ~= "PARTY" and channel ~= "TEST" then return end
    RF.probeUntil = nil
    self:SetRaidMode("bananaloot")
end

local function Grouped()
    return (GetNumRaidMembers() > 0) or (GetNumPartyMembers() > 0)
end

local function StartProbe()
    RF.probeUntil = GetTime() + PROBE_WAIT
    BananaLootRaider:SetRaidMode("unknown")
    local channel = (GetNumRaidMembers() > 0) and "RAID" or "PARTY"
    pcall(function() SendAddonMessage("BananaLoot", "HQ", channel) end)
end

local function FinishProbe()
    RF.probeUntil = nil
    if not Grouped() then return end
    if BananaLootRaider.raidMode == "bananaloot" then return end
    BananaLootRaider.rfMode = RF.rollforSeen and true or nil
    BananaLootRaider:SetRaidMode("none")
    BananaLootRaider:ApplyAvailability()
    DEFAULT_CHAT_FRAME:AddMessage(BananaLootRaider:L(RF.rollforSeen and "RF_NO_BL_ROLLFOR" or "RF_NO_BL"))
end

local ev = CreateFrame("Frame", "BananaLootRaiderRollForFrame")
ev:RegisterEvent("RAID_ROSTER_UPDATE")
ev:RegisterEvent("PARTY_MEMBERS_CHANGED")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
local wasGrouped = false
ev:SetScript("OnEvent", function()
    local g = Grouped()
    if g and (not wasGrouped or event == "PLAYER_ENTERING_WORLD") then
        StartProbe()
    elseif wasGrouped and not g then
        RF.probeUntil = nil
        RF.rollforSeen = nil
        BananaLootRaider.rfMode = nil
        BananaLootRaider.rfSR, BananaLootRaider.rfHR = {}, {}
        BananaLootRaider:SetRaidMode("unknown")
    end
    wasGrouped = g
end)
ev:SetScript("OnUpdate", function()
    if RF.probeUntil and GetTime() >= RF.probeUntil then FinishProbe() end
    -- unvollstaendige Teilnachrichten verwerfen
    if RF.chunks then
        for sender, c in pairs(RF.chunks) do
            if GetTime() - c.t > CHUNK_TIMEOUT then RF.chunks[sender] = nil end
        end
    end
end)

-- ------------------------------------------------------------
-- RollFor-Addon-Nachrichten -> Roll-Sync-Fenster
-- ------------------------------------------------------------
local TYPE_MAP = { MainSpec = "ms", OffSpec = "os", Transmog = "tmog", SoftRes = "ms" }

local function Feed(msgType, fields, sender)
    if BananaLootRaider_UI and BananaLootRaider_UI.HandleRollSync then
        BananaLootRaider_UI:HandleRollSync(msgType, fields, sender)
    end
end

local function SameGroupSender(sender)
    if not sender then return false end
    if sender == UnitName("player") then return true end
    if BananaLoot and BananaLoot.testMode then return true end
    for i = 1, GetNumRaidMembers() do if UnitName("raid" .. i) == sender then return true end end
    for i = 1, GetNumPartyMembers() do if UnitName("party" .. i) == sender then return true end end
    return false
end

function RF.OnCommand(command, data, sender)
    if command == "START_ROLL" then
        local item = data.i or {}
        local id = tonumber(item.id)
        if not id then return end
        RF.itemID = id
        local sr = {}
        local srList = data.sr or {}
        for k = 1, 40 do
            local p = srList[k]
            if not p then break end
            table.insert(sr, { n = p.n, p = 0, rolls = tonumber(p.ro) or 1 })
        end
        if table.getn(sr) > 0 then BananaLootRaider.rfSR[id] = sr end
        local mode = (data.st == "SoftResRoll" and table.getn(sr) > 0) and 1 or 0
        Feed("RS", { "RS", tostring(id), tostring(tonumber(data.s) or 30), tostring(mode) }, sender)
    elseif command == "ROLL" then
        if not RF.itemID or not data.pn then return end
        Feed("RU", { "RU", tostring(RF.itemID), data.pn, tostring(tonumber(data.r) or 0), TYPE_MAP[data.rt] or "ms" }, sender)
    elseif command == "TIE" or command == "TIESTART" then
        if RF.itemID then Feed("RT", { "RT", tostring(RF.itemID) }, sender) end
    elseif command == "FINISH" then
        if not RF.itemID then return end
        local w = data[1]
        if w and w.n then
            Feed("RW", { "RW", tostring(RF.itemID), w.n, tostring(tonumber(w.r) or 0), tostring(tonumber(w.r) or 0),
                TYPE_MAP[w.rt] or "ms" }, sender)
        end
    elseif command == "CANCEL_ROLL" then
        if RF.itemID then Feed("RC", { "RC", tostring(RF.itemID) }, sender) end
    elseif command == "AWARDED" then
        local id = tonumber(data.id)
        if id and data.pn then
            BananaLootRaider.EnsureDB()
            BananaLootRaider_DB.awardedItems[id] = { winner = data.pn }
            if BananaLootRaider_UI and BananaLootRaider_UI.AddHistoryEntry then
                pcall(function() BananaLootRaider_UI:AddHistoryEntry(id, data.pn, "manual") end)
            end
        end
    end
end

-- text = Nachricht ohne Praefix, z.B. "ROLL::START_ROLL::{...}" oder "VERSION::4.8.1"
function RF.HandleAddonMessage(text, sender)
    if not text or not SameGroupSender(sender) then return end
    RF.rollforSeen = true
    if BananaLootRaider.raidMode == "none" and not BananaLootRaider.rfMode then
        BananaLootRaider.rfMode = true
        BananaLootRaider:RefreshAvailabilityLabel()
    end
    local _, _, rest = string.find(text, "^ROLL::(.*)$")
    if not rest then return end
    local _, _, i, n, chunk = string.find(rest, "^CHUNK::(%d+)::(%d+)::(.*)$")
    if i then
        RF.chunks = RF.chunks or {}
        local c = RF.chunks[sender]
        if not c or c.n ~= tonumber(n) then
            c = { n = tonumber(n), parts = {}, got = 0, t = GetTime() }
            RF.chunks[sender] = c
        end
        i = tonumber(i)
        if not c.parts[i] then c.got = c.got + 1 end
        c.parts[i] = chunk
        if c.got < c.n then return end
        rest = ""
        for k = 1, c.n do rest = rest .. (c.parts[k] or "") end
        RF.chunks[sender] = nil
    end
    local _, _, command, dataStr = string.find(rest, "^(.-)::(.*)$")
    if not command then command, dataStr = rest, "" end
    local data = {}
    if dataStr and dataStr ~= "" then data = ParseTable(dataStr) or {} end
    RF.OnCommand(command, data, sender)
end

-- ------------------------------------------------------------
-- Beute-Ansage im Raidchat: "1. [Item] (HR)" / "2. 2x[Item] (SR by Alice [2 rolls] (+3), Bob and Cara)"
-- ------------------------------------------------------------
local function SplitNames(list)
    list = string.gsub(list, " and ", ", ")
    local out = {}
    local start = 1
    while true do
        local s, e = string.find(list, ", ", start, true)
        local piece = string.sub(list, start, s and (s - 1) or nil)
        if piece ~= "" then table.insert(out, piece) end
        if not s then break end
        start = e + 1
    end
    return out
end

function RF.ParseChat(text)
    if not text then return end
    local _, _, itemStr = string.find(text, "^%d+%.%s+(.-)%s*%(HR%)%s*$")
    if itemStr then
        local _, _, id = string.find(itemStr, "|Hitem:(%d+):")
        if id then
            BananaLootRaider.rfHR[tonumber(id)] = true
            return "hr"
        end
        return
    end
    local _, _, head, names = string.find(text, "^%d+%.%s+(.-)%s*%(SR by (.+)%)%s*$")
    if head and names then
        local _, _, id = string.find(head, "|Hitem:(%d+):")
        if not id then return end
        id = tonumber(id)
        local list = {}
        local pieces = SplitNames(names)
        for i = 1, table.getn(pieces) do
            local piece = pieces[i]
            local _, _, plus = string.find(piece, "%(%+(%d+)%)")
            local _, _, rolls = string.find(piece, "%[(%d+) rolls%]")
            local _, _, name = string.find(piece, "^([^%s%[%(]+)")
            if name then table.insert(list, { n = name, p = tonumber(plus) or 0, rolls = tonumber(rolls) or 1 }) end
        end
        if table.getn(list) > 0 then
            BananaLootRaider.rfSR[id] = list
            return "sr"
        end
    end
end

local chat = CreateFrame("Frame", "BananaLootRaiderRollForChat")
chat:RegisterEvent("CHAT_MSG_RAID")
chat:RegisterEvent("CHAT_MSG_RAID_LEADER")
chat:RegisterEvent("CHAT_MSG_PARTY")
chat:SetScript("OnEvent", function()
    if event == "CHAT_MSG_PARTY" and GetNumRaidMembers() > 0 then return end
    if BananaLootRaider.raidMode == "bananaloot" then return end
    local kind = RF.ParseChat(arg1)
    if kind then
        RF.rollforSeen = true
        if BananaLootRaider.raidMode == "none" then BananaLootRaider.rfMode = true end
    end
end)

-- Zusatzzeilen fuer den Tooltip (Aufruf aus AppendSRLines), nur ausserhalb von BananaLoot-Raids.
-- Rueckgabe: true, wenn etwas angezeigt wurde
function BananaLootRaider:AppendRollForLines(tip, itemID)
    if self.raidMode == "bananaloot" then return false end
    local sr, hr = self.rfSR[itemID], self.rfHR[itemID]
    if not sr and not hr then return false end
    tip:AddLine(" ")
    tip:AddLine(self:L("RF_TIP_HEAD"), 0.2, 1, 0.6)
    if hr then
        tip:AddLine(self:L("RF_TIP_HR"), 1, 0.3, 0.3)
    end
    if sr then
        local shown = math.min(table.getn(sr), 14)
        for i = 1, shown do
            local e = sr[i]
            local right = (e.p and e.p > 0) and ("SR+ " .. e.p) or "SR"
            if e.rolls and e.rolls > 1 then right = right .. " x" .. e.rolls end
            tip:AddDoubleLine(self:ColoredName(e.n), right, 1, 1, 1, 1, 0.82, 0)
        end
    end
    return true
end

-- Hinweiszeile im Raider-Hauptfenster
function BananaLootRaider:RefreshAvailabilityLabel()
    local f = getglobal("BananaLootRaiderHistoryFrame")
    if not f then return end
    if not RF.label then
        RF.label = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        RF.label:SetPoint("BOTTOM", f, "BOTTOM", 0, 8)
        RF.label:SetWidth(400)
    end
    if self.raidMode == "none" then
        RF.label:SetText(self:L(self.rfMode and "RF_LABEL_RF" or "RF_LABEL_NONE"))
        RF.label:SetTextColor(1, 0.5, 0.2)
    else
        RF.label:SetText("")
    end
end
