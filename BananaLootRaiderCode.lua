-- BananaLootRaiderCode.lua
-- Raid-Code: SR an den Loot-Master von BananaLoot schicken.
--
-- Der Loot-Master nennt einen Raid-Code (z.B. MC-7K3Q). Hier wird er eingegeben,
-- danach waehlt man aus der Beute des Raids seine SR-Items (Icon, Tooltip, Suche,
-- Qualitaetsfilter) und sendet sie per Addon-Nachricht in den Raid-Chat (ohne Raid:
-- Gruppe bzw. Gilde). Jeder BananaLoot-Client, der den Raid kennt (Loot-Master und
-- Stellvertreter), nimmt die SR an und bestaetigt sie.
--
-- Protokoll: siehe BananaLootRaidCode.lua in BananaLoot (Praefix "BananaLoot").
--   gesendet:  SQ~code            Status + Listen anfragen
--              SR~code~spieler~id,id   komplette SR-Liste (ersetzt die alte)
--              SW                    "welcher Raid laeuft in meiner Gruppe?" (nur RAID/PARTY)
--   empfangen: SS~code~O|C~max~raid~name   SR offen/geschlossen, max. SR
--              SH~code~H|R|B~id,id,...      Hard-Reserve-, Raid-Roll- bzw. Bankreserve-Items (gesperrt)
--              SC~code~name~O|C             aktiver Raid der Gruppe (Antwort auf SW, Auto-Verbindung)
--              SA~code~spieler~OK|ERR~...   Bestaetigung / Ablehnung
--
-- Lua 5.0: kein #-Operator, kein %-Operator, kein string.gmatch/match, Events ueber
-- this/arg1.

local PREFIX = "BananaLoot"
local ROW_H = 26
local NUM_ROWS = 11
local BOSS_ROW_H = 20
local NUM_BOSS_ROWS = 18
local ACK_TIMEOUT = 6
local QUALITY_HEX = {
    [0] = "9d9d9d", [1] = "ffffff", [2] = "1eff00", [3] = "0070dd",
    [4] = "a335ee", [5] = "ff8000", [6] = "e6cc80",
}

local R = {
    code = "",         -- normalisierter Raid-Code
    status = nil,      -- { state = "O"|"C", max, raidKey, name, hr = {}, rr = {} }
    sel = {},          -- gewaehlte Item-IDs [id] = true
    selCount = 0,
    bossIdx = 0,
    search = "",
    qual = {},
    offset = 0,
    entries = {},
    rows = {},
    bossRows = {},
    auto = false,      -- Code wurde automatisch aus der Gruppe uebernommen
    lastAuto = 0,      -- Zeit der letzten SW-Anfrage
    waiting = nil,     -- "status" | "ack"
    waitUntil = 0,
    loading = false,
}
BananaLootRaider_CodeState = R

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

local function IdsToList(str)
    local ids = {}
    if not str or str == "" then return ids end
    local parts = Split(str, ",")
    for i = 1, table.getn(parts) do
        local n = tonumber(parts[i])
        if n then table.insert(ids, n) end
    end
    return ids
end

local function Normalize(code)
    code = string.upper(code or "")
    code = string.gsub(code, "%s", "")
    return code
end

local function Say(key, a, b)
    local text = BananaLootRaider:L(key)
    if a ~= nil then text = string.format(text, a, b) end
    DEFAULT_CHAT_FRAME:AddMessage(text)
end

-- ============================================================
-- 1) DATEN
-- ============================================================
function BananaLootRaider:RaidCodeChannel()
    if GetNumRaidMembers() > 0 then return "RAID" end
    if GetNumPartyMembers() > 0 then return "PARTY" end
    if GetGuildInfo and GetGuildInfo("player") then return "GUILD" end
    return nil
end

-- Raid-Typ aus dem Code ("MC-7K3Q" -> "MC").
function R.KeyFromCode(code)
    local s = string.find(code or "", "-", 1, true)
    if s and s > 1 then return string.sub(code, 1, s - 1) end
    return nil
end

function R.GetKey()
    if R.status and R.status.raidKey and R.status.raidKey ~= "" then return R.status.raidKey end
    return R.KeyFromCode(R.code)
end

function R.Pool()
    return BananaLootRaider_RaidLoot and BananaLootRaider_RaidLoot[R.GetKey()]
end

function R.MaxSR()
    if R.status and R.status.max then return R.status.max end
    return 1
end

-- Name, Qualitaet, Icon zu einer Item-ID: statische DB, Beutetabellen-Fallback, Client.
function R.ItemInfo(id)
    local name, quality, icon
    local st = BananaLootRaider:GetStaticItemInfo(id)
    if st then name, quality, icon = st.name, st.quality, st.icon end
    if not name and BananaLootRaider_RaidLootInfo then
        local ri = BananaLootRaider_RaidLootInfo[id]
        if ri then name, quality, icon = ri[1], ri[2], ri[3] end
    end
    if not name or not icon then
        local cn, _, cq, _, _, _, _, _, ctex = GetItemInfo("item:" .. id .. ":0:0:0:0:0:0:0")
        if cn then
            name = name or cn
            quality = quality or cq
            if not icon and ctex then icon = string.gsub(ctex, "^Interface\\Icons\\", "") end
        end
    end
    return name or ("Item #" .. id), quality or 1, icon, st
end

function R.Blocked(id)
    if R.status then
        if R.status.br and R.status.br[id] then return "SR_TAG_BR" end
        if R.status.hr[id] then return "SR_TAG_HR" end
        if R.status.rr[id] then return "SR_TAG_RR" end
    end
    return nil
end

local function SaveSel()
    BananaLootRaider.EnsureDB()
    local d = BananaLootRaider_DB
    d.raidCode = R.code
    if not d.srSel then d.srSel = {} end
    local list = {}
    for id, v in pairs(R.sel) do if v then table.insert(list, id) end end
    d.srSel[R.code] = list
end

local function LoadSel()
    R.sel = {}
    R.selCount = 0
    local d = BananaLootRaider_DB
    local list = d and d.srSel and d.srSel[R.code]
    if list then
        for i = 1, table.getn(list) do
            R.sel[list[i]] = true
            R.selCount = R.selCount + 1
        end
    end
end

-- ============================================================
-- 2) NACHRICHTEN
-- ============================================================
function BananaLootRaider:HandleCodeMessage(text, sender, channel)
    -- Kurznachrichten (SW, HQ) bestehen nur aus dem Typ, alle anderen haben "~" an Stelle 3
    if not text or (string.len(text) > 2 and string.sub(text, 3, 3) ~= "~") then return false end
    local t = string.sub(text, 1, 2)
    if t ~= "SS" and t ~= "SH" and t ~= "SA" and t ~= "SR" and t ~= "SQ" and t ~= "SJ" and t ~= "SD"
        and t ~= "SW" and t ~= "SC" and t ~= "HQ" and t ~= "HA" and t ~= "HO" and t ~= "RV" then
        return false
    end
    -- nur fuer BananaLoot bestimmt
    -- HQ: "wer hat BananaLoot?" -- BananaLoot Raider antwortet mit seiner Version (RV), leicht
    -- verzoegert, damit nicht alle Antworten gleichzeitig kommen (BananaLoot: /bl version)
    if t == "HQ" then
        if channel == "RAID" or channel == "PARTY" then
            R.after(math.random() * 1.2, function()
                pcall(function() SendAddonMessage(PREFIX, "RV~" .. BananaLootRaider.VERSION, channel) end)
            end)
        end
        return true
    end
    if t == "SR" or t == "SQ" or t == "SJ" or t == "SD" or t == "SW" or t == "HA" or t == "HO" or t == "RV" then
        return true
    end
    local fields = Split(text, "~")

    -- SC: BananaLoot meldet den aktiven Raid der Gruppe. Nur ueber Raid/Gruppe akzeptieren (nie
    -- ueber die Gilde): der Kanal beweist, dass der Absender in meiner Gruppe ist.
    if t == "SC" then
        if channel ~= "RAID" and channel ~= "PARTY" then return true end
        local newCode = Normalize(fields[2])
        if newCode == "" or newCode == R.code then return true end
        if R.code == "" or R.auto then
            R.code = ""   -- Auswahl des alten Raids verwerfen
            R.status = nil
            R.auto = true
            Say("SR_AUTO", fields[3] or newCode)
            R.Connect(newCode, true)
        end
        return true
    end
    local code = Normalize(fields[2])
    if code ~= R.code then return true end

    if t == "SS" then
        local first = (R.status == nil) or (R.waiting == "status")
        if not R.status or R.fresh then
            R.status = { hr = {}, rr = {} }
            R.fresh = nil
        end
        R.status.state = fields[3]
        R.status.max = tonumber(fields[4]) or 1
        R.status.raidKey = fields[5]
        R.status.name = fields[6]
        if R.waiting == "status" then R.waiting = nil end
        if first then R.offset = 0; R.bossIdx = 0 end
        if R.frame:IsShown() then R.Refresh() end
    elseif t == "SH" then
        if R.status then
            local target = R.status.rr
            if fields[3] == "H" then target = R.status.hr elseif fields[3] == "B" then
                if not R.status.br then R.status.br = {} end
                target = R.status.br
            end
            local ids = IdsToList(fields[4])
            for i = 1, table.getn(ids) do target[ids[i]] = true end
            -- gesperrte Items aus der Auswahl nehmen
            for i = 1, table.getn(ids) do
                if R.sel[ids[i]] then R.sel[ids[i]] = nil; R.selCount = R.selCount - 1 end
            end
            if R.frame:IsShown() then R.Refresh() end
        end
    elseif t == "SA" then
        if fields[3] == UnitName("player") and R.waiting == "ack" then
            R.waiting = nil
            if fields[4] == "OK" then
                local skip = tonumber(fields[6]) or 0
                local extra = ""
                if skip > 0 then extra = string.format(BananaLootRaider:L("SR_ACK_SKIP"), skip) end
                DEFAULT_CHAT_FRAME:AddMessage(string.format(BananaLootRaider:L("SR_ACK_OK"), tonumber(fields[5]) or 0, extra))
            else
                local why = fields[5]
                if why == "closed" then Say("SR_ACK_CLOSED")
                elseif why == "limit" then Say("SR_ACK_LIMIT", R.MaxSR())
                else Say("SR_ACK_OTHER", tostring(why)) end
            end
            if R.frame:IsShown() then R.Refresh() end
        end
    end
    return true
end

function R.Connect(code, auto)
    code = Normalize(code)
    if not auto then R.auto = false end   -- von Hand eingegebener Code bleibt
    if code == "" then
        Say("SR_NEED_CODE")
        return
    end
    local channel = BananaLootRaider:RaidCodeChannel()
    if not channel then
        Say("SR_NO_CHANNEL")
        return
    end
    if code ~= R.code then
        R.code = code
        R.status = nil
        LoadSel()
    else
        R.fresh = true
    end
    R.offset = 0
    R.bossIdx = 0
    R.waiting = "status"
    R.waitUntil = GetTime() + ACK_TIMEOUT
    BananaLootRaider.EnsureDB()
    BananaLootRaider_DB.raidCode = code
    pcall(function() SendAddonMessage(PREFIX, "SQ~" .. code, channel) end)
    R.watch:Show()
    if R.frame:IsShown() then R.Refresh() end
end

function R.Send()
    if R.code == "" or not R.status then
        Say("SR_NEED_CODE")
        return
    end
    local channel = BananaLootRaider:RaidCodeChannel()
    if not channel then
        Say("SR_NO_CHANNEL")
        return
    end
    local ids = {}
    for id, v in pairs(R.sel) do if v then table.insert(ids, id) end end
    table.sort(ids)
    SaveSel()
    R.waiting = "ack"
    R.waitUntil = GetTime() + ACK_TIMEOUT
    pcall(function()
        SendAddonMessage(PREFIX, "SR~" .. R.code .. "~" .. UnitName("player") .. "~" .. table.concat(ids, ","), channel)
    end)
    Say("SR_SENT", table.getn(ids), R.status.name or R.code)
    R.watch:Show()
    R.Refresh()
end

-- Automatische Raid-Erkennung: in einer Gruppe/einem Raid fragt der Raider im Hintergrund
-- "welcher BananaLoot-Raid laeuft hier?" (SW). Antwortet ein Loot-Master mit SC, verbindet er
-- sich selbst -- kein Abschreiben des Codes noetig. Ein von Hand eingegebener Code bleibt.
function R.AutoSync(force)
    local channel
    if GetNumRaidMembers() > 0 then channel = "RAID" elseif GetNumPartyMembers() > 0 then channel = "PARTY" end
    if not channel then return end
    if R.code ~= "" and not R.auto then return end          -- von Hand verbunden
    local now = GetTime()
    if not force and (now - R.lastAuto) < 20 then return end
    R.lastAuto = now
    pcall(function() SendAddonMessage(PREFIX, "SW", channel) end)
end

R.autoDelay = nil
R.timers = {}
function R.after(delay, fn)
    table.insert(R.timers, { at = GetTime() + delay, fn = fn })
end
R.ev = CreateFrame("Frame", "BananaLootRaiderCodeEvents")
R.ev:RegisterEvent("PLAYER_ENTERING_WORLD")
R.ev:RegisterEvent("RAID_ROSTER_UPDATE")
R.ev:RegisterEvent("PARTY_MEMBERS_CHANGED")
R.ev:SetScript("OnEvent", function()
    R.autoDelay = 4        -- kurz warten, bis sich die Gruppe gesetzt hat
    R.ev:Show()
end)
R.ev:SetScript("OnUpdate", function()
    if table.getn(R.timers) > 0 then
        local now = GetTime()
        for i = table.getn(R.timers), 1, -1 do
            local t = R.timers[i]
            if now >= t.at then
                table.remove(R.timers, i)
                pcall(t.fn)
            end
        end
    end
    if not R.autoDelay then return end
    R.autoDelay = R.autoDelay - arg1
    if R.autoDelay <= 0 then
        R.autoDelay = nil
        R.AutoSync(false)
    end
end)

-- Zeitueberwachung fuer Antworten
R.watch = CreateFrame("Frame", "BananaLootRaiderCodeWatch")
R.watch:Hide()
R.watch:SetScript("OnUpdate", function()
    if not R.waiting then
        R.watch:Hide()
        return
    end
    if GetTime() >= R.waitUntil then
        local what = R.waiting
        R.waiting = nil
        Say("SR_NO_ANSWER", R.code)
        if what == "status" and R.frame:IsShown() then R.Refresh() end
        R.watch:Hide()
        if R.frame:IsShown() then R.Refresh() end
    end
end)

-- ============================================================
-- 3) FENSTER
-- ============================================================
local BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 11, top = 11, bottom = 11 },
}
local PANEL_BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

local function MakeButton(name, parent, w, h)
    local b = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    b:SetWidth(w)
    b:SetHeight(h)
    return b
end

local F = CreateFrame("Frame", "BananaLootRaiderCodeFrame", UIParent)
R.frame = F
F:SetWidth(720)
F:SetHeight(520)
F:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
F:SetBackdrop(BACKDROP)
BananaLootRaider_Theme.Darken(F)
F:SetMovable(true)
F:EnableMouse(true)
F:RegisterForDrag("LeftButton")
F:SetScript("OnDragStart", function() this:StartMoving() end)
F:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
F:SetFrameStrata("DIALOG")
F:Hide()

F.close = CreateFrame("Button", "BananaLootRaiderCodeClose", F, "UIPanelCloseButton")
F.close:SetPoint("TOPRIGHT", F, "TOPRIGHT", -4, -4)
F.close:SetScript("OnClick", function() this:GetParent():Hide() end)

F.title = F:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
F.title:SetPoint("TOP", F, "TOP", 0, -16)

-- Code-Zeile
F.codeLabel = F:CreateFontString(nil, "OVERLAY", "GameFontNormal")
F.codeLabel:SetPoint("TOPLEFT", F, "TOPLEFT", 24, -50)
F.codeBox = CreateFrame("EditBox", "BananaLootRaiderCodeBox", F, "InputBoxTemplate")
F.codeBox:SetWidth(120)
F.codeBox:SetHeight(22)
F.codeBox:SetPoint("LEFT", F.codeLabel, "RIGHT", 12, 0)
F.codeBox:SetAutoFocus(false)
F.codeBox:SetMaxLetters(16)
F.codeBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
F.codeBox:SetScript("OnEnterPressed", function()
    this:ClearFocus()
    R.Connect(this:GetText())
end)
F.connectBtn = MakeButton("BananaLootRaiderCodeConnect", F, 100, 22)
F.connectBtn:SetPoint("LEFT", F.codeBox, "RIGHT", 8, 0)
F.connectBtn:SetScript("OnClick", function() R.Connect(F.codeBox:GetText()) end)
F.statusText = F:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
F.statusText:SetPoint("LEFT", F.connectBtn, "RIGHT", 14, 0)
F.statusText:SetWidth(330)
F.statusText:SetJustifyH("LEFT")

F.hint = F:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
F.hint:SetPoint("TOP", F, "TOP", 0, -78)
F.hint:SetWidth(670)
F.hint:SetJustifyH("CENTER")

-- Linke Spalte: Bosse
F.left = CreateFrame("Frame", "BananaLootRaiderCodeBosses", F)
F.left:SetWidth(200)
F.left:SetHeight(NUM_BOSS_ROWS * BOSS_ROW_H + 12)
F.left:SetPoint("TOPLEFT", F, "TOPLEFT", 20, -100)
F.left:SetBackdrop(PANEL_BACKDROP)
F.left:SetBackdropColor(0, 0, 0, BananaLootRaider_Theme.PANEL_ALPHA)
for i = 1, NUM_BOSS_ROWS do
    local r = CreateFrame("Button", "BananaLootRaiderCodeBoss" .. i, F.left)
    r:SetWidth(186)
    r:SetHeight(BOSS_ROW_H)
    r:SetPoint("TOPLEFT", F.left, "TOPLEFT", 7, -6 - (i - 1) * BOSS_ROW_H)
    r:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.text:SetPoint("LEFT", r, "LEFT", 4, 0)
    r.text:SetWidth(178)
    r.text:SetJustifyH("LEFT")
    r.sel = r:CreateTexture(nil, "BACKGROUND")
    r.sel:SetAllPoints(r)
    r.sel:SetTexture(1, 0.82, 0, 0.25)
    r.sel:Hide()
    r.idx = i - 1
    r:SetScript("OnClick", function()
        R.bossIdx = this.idx
        R.offset = 0
        R.Refresh()
    end)
    R.bossRows[i] = r
end

-- Suche, Qualitaetsfilter, Zaehler
F.searchLabel = F:CreateFontString(nil, "OVERLAY", "GameFontNormal")
F.searchLabel:SetPoint("TOPLEFT", F, "TOPLEFT", 240, -106)
F.searchBox = CreateFrame("EditBox", "BananaLootRaiderCodeSearch", F, "InputBoxTemplate")
F.searchBox:SetWidth(170)
F.searchBox:SetHeight(20)
F.searchBox:SetPoint("LEFT", F.searchLabel, "RIGHT", 12, 0)
F.searchBox:SetAutoFocus(false)
F.searchBox:SetMaxLetters(40)
F.searchBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
F.searchBox:SetScript("OnEnterPressed", function() this:ClearFocus() end)
F.searchBox:SetScript("OnTextChanged", function()
    if R.loading then return end
    R.search = string.lower(this:GetText() or "")
    R.offset = 0
    R.Refresh()
end)
F.countText = F:CreateFontString(nil, "OVERLAY", "GameFontNormal")
F.countText:SetPoint("TOPRIGHT", F, "TOPRIGHT", -34, -110)
F.countText:SetJustifyH("RIGHT")

F.qualLabel = F:CreateFontString(nil, "OVERLAY", "GameFontNormal")
F.qualLabel:SetPoint("TOPLEFT", F, "TOPLEFT", 240, -136)
R.qualBtns = {}
local QUAL_KEYS = { "SR_QUAL_1", "SR_QUAL_2", "SR_QUAL_3", "SR_QUAL_4", "SR_QUAL_5" }
for q = 1, 5 do
    local b = MakeButton("BananaLootRaiderCodeQual" .. q, F, 66, 20)
    b:SetPoint("TOPLEFT", F, "TOPLEFT", 306 + (q - 1) * 68, -133)
    b.q = q
    b.sel = b:CreateTexture(nil, "OVERLAY")
    b.sel:SetAllPoints(b)
    b.sel:SetTexture(1, 0.82, 0, 0.35)
    b.sel:Hide()
    b:SetScript("OnClick", function()
        if R.qual[this.q] then R.qual[this.q] = nil else R.qual[this.q] = true end
        R.offset = 0
        R.Refresh()
    end)
    R.qualBtns[q] = b
end

-- Liste
F.list = CreateFrame("Frame", "BananaLootRaiderCodeList", F)
F.list:SetWidth(440)
F.list:SetHeight(NUM_ROWS * ROW_H)
F.list:SetPoint("TOPLEFT", F, "TOPLEFT", 234, -160)
F.list:EnableMouseWheel(true)

F.slider = CreateFrame("Slider", "BananaLootRaiderCodeSlider", F, "UIPanelScrollBarTemplate")
F.slider:SetPoint("TOPLEFT", F.list, "TOPRIGHT", 6, -16)
F.slider:SetPoint("BOTTOMLEFT", F.list, "BOTTOMRIGHT", 6, 16)
F.slider:SetMinMaxValues(0, 0)
F.slider:SetValueStep(1)
F.slider:SetValue(0)
F.slider:SetScript("OnValueChanged", function()
    if R.loading then return end
    R.offset = math.floor((arg1 or 0) + 0.5)
    R.UpdateRows()
end)
local upBtn = getglobal("BananaLootRaiderCodeSliderScrollUpButton")
local downBtn = getglobal("BananaLootRaiderCodeSliderScrollDownButton")
if upBtn then upBtn:SetScript("OnClick", function() F.slider:SetValue(F.slider:GetValue() - 1) end) end
if downBtn then downBtn:SetScript("OnClick", function() F.slider:SetValue(F.slider:GetValue() + 1) end) end
F.list:SetScript("OnMouseWheel", function() F.slider:SetValue(F.slider:GetValue() - arg1 * 3) end)

function R.ShowTooltip(owner, id)
    BananaLootRaider:ShowItemTooltip(owner, id, "ANCHOR_RIGHT")
end

for i = 1, NUM_ROWS do
    local r = CreateFrame("Button", "BananaLootRaiderCodeRow" .. i, F.list)
    r:SetWidth(440)
    r:SetHeight(ROW_H)
    r:SetPoint("TOPLEFT", F.list, "TOPLEFT", 0, -(i - 1) * ROW_H)
    r:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    r.check = CreateFrame("CheckButton", "BananaLootRaiderCodeRow" .. i .. "Check", r, "UICheckButtonTemplate")
    r.check:SetWidth(24)
    r.check:SetHeight(24)
    r.check:SetPoint("LEFT", r, "LEFT", 2, 0)
    r.check:EnableMouse(false)
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetWidth(20)
    r.icon:SetHeight(20)
    r.icon:SetPoint("LEFT", r.check, "RIGHT", 2, 0)
    r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.text:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
    r.text:SetWidth(280)
    r.text:SetJustifyH("LEFT")
    r.tag = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.tag:SetPoint("RIGHT", r, "RIGHT", -6, 0)
    r.tag:SetWidth(100)
    r.tag:SetJustifyH("RIGHT")
    r:SetScript("OnClick", function() R.OnRowClick(this) end)
    r:SetScript("OnEnter", function()
        if this.entry and this.entry.id then R.ShowTooltip(this, this.entry.id) end
    end)
    r:SetScript("OnLeave", function() GameTooltip:Hide() end)
    R.rows[i] = r
end

-- Untere Buttons
F.sendBtn = MakeButton("BananaLootRaiderCodeSend", F, 190, 26)
F.sendBtn:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT", -20, 16)
F.sendBtn:SetScript("OnClick", function() R.Send() end)
F.clearBtn = MakeButton("BananaLootRaiderCodeClear", F, 130, 24)
F.clearBtn:SetPoint("BOTTOMLEFT", F, "BOTTOMLEFT", 20, 18)
F.clearBtn:SetScript("OnClick", function()
    R.sel = {}
    R.selCount = 0
    R.Refresh()
end)

-- ------------------------------------------------------------
-- Logik
-- ------------------------------------------------------------
function R.QualityOK(id)
    local any = false
    for q = 1, 5 do if R.qual[q] then any = true end end
    if not any then return true end
    local _, quality = R.ItemInfo(id)
    return R.qual[quality] == true
end

function R.Visible(id)
    if not R.QualityOK(id) then return false end
    if R.search ~= "" then
        local nm = string.lower((R.ItemInfo(id)))
        if not string.find(nm, R.search, 1, true) then return false end
    end
    return true
end

function R.BuildEntries()
    local entries = {}
    local raid = R.Pool()
    if raid then
        local first, last = 1, table.getn(raid)
        if R.bossIdx > 0 and R.bossIdx <= last then first, last = R.bossIdx, R.bossIdx end
        for b = first, last do
            local ids = raid[b][2]
            local items = {}
            for i = 1, table.getn(ids) do
                if R.Visible(ids[i]) then table.insert(items, { kind = "item", id = ids[i] }) end
            end
            if table.getn(items) > 0 then
                if first ~= last then table.insert(entries, { kind = "boss", name = raid[b][1] }) end
                for i = 1, table.getn(items) do table.insert(entries, items[i]) end
            end
        end
    end
    R.entries = entries
end

function R.UpdateRows()
    for i = 1, NUM_ROWS do
        local r = R.rows[i]
        local e = R.entries[R.offset + i]
        r.entry = e
        if not e then
            r:Hide()
        else
            r.tag:SetText("")
            if e.kind == "boss" then
                r.check:Hide()
                r.icon:Hide()
                r.text:ClearAllPoints()
                r.text:SetPoint("LEFT", r, "LEFT", 8, 0)
                r.text:SetText("|cffffd100" .. e.name .. "|r")
            else
                local name, quality, icon = R.ItemInfo(e.id)
                r.check:Show()
                r.icon:Show()
                r.icon:SetTexture("Interface\\Icons\\" .. (icon or "INV_Misc_QuestionMark"))
                r.text:ClearAllPoints()
                r.text:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
                local why = R.Blocked(e.id)
                if why then
                    r.check:SetChecked(false)
                    r.text:SetText("|cff808080" .. name .. "|r")
                    r.tag:SetText("|cff808080" .. BananaLootRaider:L(why) .. "|r")
                else
                    r.check:SetChecked(R.sel[e.id] and true or false)
                    r.text:SetText("|cff" .. (QUALITY_HEX[quality] or "ffffff") .. name .. "|r")
                end
            end
            r:Show()
        end
    end
end

function R.UpdateBossRows()
    local raid = R.Pool()
    local nBoss = raid and table.getn(raid) or 0
    for i = 1, NUM_BOSS_ROWS do
        local r = R.bossRows[i]
        local text
        if i == 1 then
            text = BananaLootRaider:L("SR_ALL_BOSSES")
        elseif raid and raid[i - 1] then
            local ids = raid[i - 1][2]
            local n = 0
            for k = 1, table.getn(ids) do if R.sel[ids[k]] then n = n + 1 end end
            text = raid[i - 1][1] .. " |cffaaaaaa(" .. n .. ")|r"
        end
        if text and i - 1 <= nBoss then
            r.text:SetText(text)
            if R.bossIdx == i - 1 then r.sel:Show() else r.sel:Hide() end
            r:Show()
        else
            r:Hide()
        end
    end
end

function R.StatusLine()
    if R.code == "" then return "|cffaaaaaa" .. BananaLootRaider:L("SR_STATUS_NONE") .. "|r" end
    if R.waiting == "status" then return "|cffffd100" .. string.format(BananaLootRaider:L("SR_STATUS_WAIT"), R.code) .. "|r" end
    if not R.status then return "|cffff5555" .. string.format(BananaLootRaider:L("SR_STATUS_UNKNOWN"), R.code) .. "|r" end
    local name = R.status.name or R.code
    if R.status.state == "O" then
        return "|cff33ff99" .. string.format(BananaLootRaider:L("SR_STATUS_OPEN"), name, R.status.max or 1) .. "|r"
    end
    return "|cffff8080" .. string.format(BananaLootRaider:L("SR_STATUS_CLOSED"), name) .. "|r"
end

function R.Refresh()
    if not F:IsShown() then return end
    F.title:SetText(BananaLootRaider:L("SR_WIN_TITLE"))
    F.codeLabel:SetText(BananaLootRaider:L("SR_CODE_LABEL"))
    F.connectBtn:SetText(BananaLootRaider:L("SR_CONNECT"))
    F.searchLabel:SetText(BananaLootRaider:L("SR_SEARCH"))
    F.qualLabel:SetText(BananaLootRaider:L("SR_QUAL_LABEL"))
    F.sendBtn:SetText(BananaLootRaider:L("SR_SEND"))
    F.clearBtn:SetText(BananaLootRaider:L("SR_CLEAR"))
    F.hint:SetText(BananaLootRaider:L("SR_HINT"))
    F.statusText:SetText(R.StatusLine())
    for q = 1, 5 do
        R.qualBtns[q]:SetText("|cff" .. QUALITY_HEX[q] .. BananaLootRaider:L(QUAL_KEYS[q]) .. "|r")
        if R.qual[q] then R.qualBtns[q].sel:Show() else R.qualBtns[q].sel:Hide() end
    end
    F.countText:SetText(string.format(BananaLootRaider:L("SR_COUNT"), R.selCount, R.MaxSR()))
    local ready = R.status and R.status.state == "O" and R.waiting ~= "ack"
    if ready then F.sendBtn:Enable() else F.sendBtn:Disable() end
    R.UpdateBossRows()
    R.BuildEntries()
    local n = table.getn(R.entries)
    local maxOff = math.max(0, n - NUM_ROWS)
    if R.offset > maxOff then R.offset = maxOff end
    R.loading = true
    F.slider:SetMinMaxValues(0, maxOff)
    F.slider:SetValue(R.offset)
    R.loading = false
    R.UpdateRows()
end

function R.OnRowClick(row)
    local e = row.entry
    if not e or e.kind ~= "item" then return end
    local id = e.id
    if R.Blocked(id) then return end
    if R.sel[id] then
        R.sel[id] = nil
        R.selCount = R.selCount - 1
    else
        local max = R.MaxSR()
        if R.selCount >= max then
            if max <= 1 then
                -- Limit 1: neue Auswahl ersetzt die alte
                R.sel = {}
                R.selCount = 0
            else
                Say("SR_LIMIT_MSG", max)
                return
            end
        end
        R.sel[id] = true
        R.selCount = R.selCount + 1
    end
    SaveSel()
    R.Refresh()
end

F:SetScript("OnShow", function() R.Refresh() end)

-- ============================================================
-- 4) EINSTIEGSPUNKTE
-- ============================================================
function BananaLootRaider:ShowRaidCode(code)
    BananaLootRaider.EnsureDB()
    if code and code ~= "" then
        F:Show()
        F.codeBox:SetText(Normalize(code))
        R.Connect(code)
        return
    end
    if R.code == "" and BananaLootRaider_DB.raidCode then
        R.code = Normalize(BananaLootRaider_DB.raidCode)
        LoadSel()
    end
    R.loading = true
    F.codeBox:SetText(R.code)
    F.searchBox:SetText("")
    R.search = ""
    R.loading = false
    F:Show()
    R.Refresh()
    if R.code == "" or R.auto then R.AutoSync(true) end
end

function BananaLootRaider:ApplyLocaleCode()
    if F:IsShown() then R.Refresh() end
end
