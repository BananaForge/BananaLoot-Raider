-- BananaLootRaiderSRList.lua
-- SR+-Uebersicht: empfaengt die Reservierungen samt SR+ der Raids des Loot-Masters (BananaLoot, siehe
-- BananaLootSRSync.lua) und zeigt sie
--   * als Liste nach Item sortiert (Fenster "SR+ Liste": wer hat welches Item auf SR, mit wie viel SR+),
--   * als Zusatz im Item-Tooltip der SR-Auswahlliste (Raid-Code-Fenster),
--   * als Zusatz im Item-Fenster, wenn man einen Item-Link anklickt, der im RAID-Chat gepostet wurde.
-- Nachrichten:  OB~id~A|N~raidKey~name  /  OI~id~itemID~teil~Name:p,Name:p  /  OE~id~anzahl  /  OQ~cur|all (Anfrage)

local function Split(str, sep)
    local result = {}
    local start = 1
    while true do
        local s, e = string.find(str, sep, start, true)
        if not s then table.insert(result, string.sub(str, start)) break end
        table.insert(result, string.sub(str, start, s - 1))
        start = e + 1
    end
    return result
end

local function DB()
    BananaLootRaider.EnsureDB()
    local d = BananaLootRaider_DB
    if not d.srOverview then d.srOverview = {} end
    return d
end

BananaLootRaider.srStage = {}          -- ["Sender:id"] = Raid im Aufbau (zwischen OB und OE)
BananaLootRaider.raidChatItems = {}    -- [itemID] = GetTime() des letzten Item-Links im Raidchat
local MAX_OVERVIEWS = 14
local MAX_AGE = 30 * 24 * 3600
local ACTIVE_AGE = 15 * 60                 -- "aktiv" gilt nur fuer Uebersichten, die juenger sind

-- Name des Loot-Masters der Gruppe (nil = keiner/unbekannt)
local function LootMasterName()
    if not GetLootMethod then return nil end
    local method, partyID, raidID = GetLootMethod()
    if method ~= "master" then return nil end
    if GetNumRaidMembers() > 0 then
        if raidID and raidID > 0 then
            local n = GetRaidRosterInfo(raidID)
            return n
        end
    elseif partyID then
        if partyID == 0 then return UnitName("player") end
        return UnitName("party" .. partyID)
    end
    return nil
end

local function SenderInGroup(name)
    if BananaLoot and BananaLoot.testMode then return true end
    if not name then return false end
    if name == UnitName("player") then return true end
    for i = 1, GetNumRaidMembers() do
        if UnitName("raid" .. i) == name then return true end
    end
    for i = 1, GetNumPartyMembers() do
        if UnitName("party" .. i) == name then return true end
    end
    return false
end

-- Ist die gespeicherte Uebersicht wirklich der gerade laufende Raid? (frisch + Sender in meiner Gruppe)
local function IsEffectivelyActive(ov)
    if not ov.active then return false end
    if (time() - (ov.time or 0)) > ACTIVE_AGE then return false end
    return SenderInGroup(ov.sender)
end
BananaLootRaider.IsOverviewActive = IsEffectivelyActive

-- ------------------------------------------------------------
-- Empfang
-- ------------------------------------------------------------
function BananaLootRaider:HandleOverviewMessage(msgType, fields, sender)
    local id = fields[2]
    if not id or not sender then return end
    local ch = self.lastMsgChannel or "TEST"
    -- im Raid/in der Gruppe zaehlt nur der Loot-Master als Quelle
    if ch == "RAID" or ch == "PARTY" then
        local master = LootMasterName()
        if master and master ~= sender then return end
    end
    -- je Kanal getrennt aufbauen, damit sich Gilde und Raid nicht vermischen
    local key = id                                   -- derselbe Raid (gleiche Raid-ID) ersetzt sich, egal wer ihn sendet
    local skey = sender .. ":" .. id .. ":" .. ch
    if msgType == "OB" then
        self.srStage[skey] = { id = id, sender = sender, active = (fields[3] == "A"),
            raidKey = fields[4] or "", name = fields[5] or "", items = {}, channel = ch,
            stamp = tonumber(fields[6]) or 0 }
    elseif msgType == "OI" then
        local st = self.srStage[skey]
        local itemID, part = tonumber(fields[3]), tonumber(fields[4])
        if not st or not itemID then return end
        if part == 1 or not st.items[itemID] then st.items[itemID] = {} end
        local list = Split(fields[5] or "", ",")
        for i = 1, table.getn(list) do
            local _, _, n, p = string.find(list[i], "^(.-):(%-?%d+)$")
            if n and n ~= "" then table.insert(st.items[itemID], { n = n, p = tonumber(p) or 0 }) end
        end
    elseif msgType == "OE" then
        local st = self.srStage[skey]
        if not st then return end
        self.srStage[skey] = nil
        st.time = time()
        local d = DB()
        local old = d.srOverview[key]
        -- ein aelterer Stand eines anderen Senders ersetzt keinen neueren (z.B. Vertreter mit altem Import)
        if old and old.sender ~= st.sender and (old.stamp or 0) > (st.stamp or 0) then return end
        d.srOverview[key] = st
        -- aufraeumen: zu alte und ueberzaehlige Raids entfernen
        local keys = {}
        for k, v in pairs(d.srOverview) do table.insert(keys, k) end
        table.sort(keys, function(a, b) return (d.srOverview[a].time or 0) > (d.srOverview[b].time or 0) end)
        for i = 1, table.getn(keys) do
            local v = d.srOverview[keys[i]]
            if i > MAX_OVERVIEWS or (time() - (v.time or 0)) > MAX_AGE then d.srOverview[keys[i]] = nil end
        end
        if self.RefreshSRList then self:RefreshSRList() end
    end
end

-- ------------------------------------------------------------
-- Abfragen
-- ------------------------------------------------------------
-- Liste aller bekannten Raids: aktive zuerst, dann neueste zuerst
function BananaLootRaider:GetOverviewList()
    local list = {}
    for k, v in pairs(DB().srOverview) do table.insert(list, v) end
    table.sort(list, function(a, b)
        local aa, ba = IsEffectivelyActive(a), IsEffectivelyActive(b)
        if aa ~= ba then return aa end
        local master = LootMasterName()
        if master and (a.sender == master) ~= (b.sender == master) then return a.sender == master end
        return (a.time or 0) > (b.time or 0)
    end)
    return list
end

function BananaLootRaider:GetBestOverview()
    return self:GetOverviewList()[1]
end

local function OverviewName(ov)
    if ov.name and ov.name ~= "" then return ov.name end
    if ov.raidKey and ov.raidKey ~= "" then return ov.raidKey end
    return "?"
end
BananaLootRaider.OverviewName = OverviewName

-- Zusatzzeilen fuer einen Tooltip: wer hat das Item auf SR, mit wie viel SR+
function BananaLootRaider:AppendSRLines(tip, itemID)
    if self.raidMode ~= "bananaloot" and self.AppendRollForLines and tip and self:AppendRollForLines(tip, itemID) then
        return true   -- Raid ohne BananaLoot: SR/HR-Info aus der RollFor-Ansage im Raidchat
    end
    local ov = self:GetBestOverview()
    if not ov or not tip then return false end
    local list = ov.items[itemID]
    tip:AddLine(" ")
    tip:AddLine(string.format(self:L("SRL_TIP_HEAD"), OverviewName(ov)), 0.2, 1, 0.6)
    if not list or table.getn(list) == 0 then
        tip:AddLine(self:L("SRL_TIP_NONE"), 0.6, 0.6, 0.6)
        return true
    end
    local shown = math.min(table.getn(list), 14)
    for i = 1, shown do
        local e = list[i]
        tip:AddDoubleLine(self:ColoredName(e.n), (e.p and e.p > 0) and ("SR+ " .. e.p) or "SR", 1, 1, 1, 1, 0.82, 0)
    end
    if table.getn(list) > shown then
        tip:AddLine(string.format(self:L("SRL_TIP_MORE"), table.getn(list) - shown), 0.7, 0.7, 0.7)
    end
    return true
end

-- ------------------------------------------------------------
-- Anfrage an den Loot-Master
-- ------------------------------------------------------------
local lastRequest = 0
function BananaLootRaider:RequestSROverview(scope)
    if GetTime() - lastRequest < 10 then return false end
    lastRequest = GetTime()
    local text = "OQ~" .. (scope or "cur")
    if BananaLoot and BananaLoot.testMode and BananaLoot.SRSyncOnRequest then
        BananaLoot:SRSyncOnRequest(scope or "cur", "TEST")
        return true
    end
    local sent = false
    local channel
    if GetNumRaidMembers() > 0 then channel = "RAID" elseif GetNumPartyMembers() > 0 then channel = "PARTY" end
    if channel then pcall(function() SendAddonMessage("BananaLoot", text, channel) end) sent = true end
    if GetGuildInfo and GetGuildInfo("player") then pcall(function() SendAddonMessage("BananaLoot", text, "GUILD") end) sent = true end
    return sent
end

-- ------------------------------------------------------------
-- Item-Links im RAID-Chat: Item-Fenster um die SR+-Liste ergaenzen
-- ------------------------------------------------------------
local chatFrame = CreateFrame("Frame", "BananaLootRaiderSRChatFrame")
chatFrame:RegisterEvent("CHAT_MSG_RAID")
chatFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
chatFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")
chatFrame:RegisterEvent("CHAT_MSG_PARTY")
chatFrame:SetScript("OnEvent", function()
    if event == "CHAT_MSG_PARTY" and GetNumRaidMembers() > 0 then return end   -- im Raid zaehlt nur der Raidchat
    local msg = arg1
    if not msg then return end
    for id in string.gfind(msg, "|Hitem:(%d+):") do
        BananaLootRaider.raidChatItems[tonumber(id)] = GetTime()
    end
end)

local function FromRaidChat(itemID)
    if BananaLoot and BananaLoot.testMode then return true end     -- im Testlauf ueberall (zum Ausprobieren)
    local t = BananaLootRaider.raidChatItems[itemID]
    return t and (GetTime() - t) < 900
end

local origSetItemRef = SetItemRef
SetItemRef = function(link, text, button)
    if origSetItemRef then origSetItemRef(link, text, button) end
    if not link or button ~= "LeftButton" then return end
    if IsShiftKeyDown() or IsControlKeyDown() or IsAltKeyDown() then return end
    local _, _, idStr = string.find(link, "^item:(%d+)")
    local itemID = idStr and tonumber(idStr)
    if not itemID or not FromRaidChat(itemID) then return end
    if ItemRefTooltip and ItemRefTooltip:IsVisible() and BananaLootRaider:GetBestOverview() then
        BananaLootRaider:AppendSRLines(ItemRefTooltip, itemID)
        ItemRefTooltip:Show()
    end
end

-- ------------------------------------------------------------
-- Fenster "SR+ Liste"
-- ------------------------------------------------------------
local T = { idx = 1, rows = {} }
local ROW_H = 38
local F = CreateFrame("Frame", "BananaLootRaiderSRListFrame", UIParent)
BananaLootRaider.srListFrame = F
F:SetWidth(540)
F:SetHeight(540)
F:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
F:SetFrameStrata("DIALOG")
F:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 11, top = 11, bottom = 11 },
})
if BananaLootRaider_Theme and BananaLootRaider_Theme.Darken then BananaLootRaider_Theme.Darken(F) end
F:SetMovable(true)
F:EnableMouse(true)
F:RegisterForDrag("LeftButton")
F:SetScript("OnDragStart", function() F:StartMoving() end)
F:SetScript("OnDragStop", function() F:StopMovingOrSizing() end)
F:Hide()
F.close = CreateFrame("Button", "BananaLootRaiderSRListClose", F, "UIPanelCloseButton")
F.close:SetPoint("TOPRIGHT", F, "TOPRIGHT", -4, -4)
F.close:SetScript("OnClick", function() BananaLootRaider:PlayClickSound(); F:Hide() end)
F.title = F:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
F.title:SetPoint("TOP", F, "TOP", 0, -16)

F.prev = CreateFrame("Button", "BananaLootRaiderSRListPrev", F, "UIPanelButtonTemplate")
F.prev:SetWidth(28); F.prev:SetHeight(22)
F.prev:SetPoint("TOPLEFT", F, "TOPLEFT", 22, -46)
F.prev:SetText("<")
F.next = CreateFrame("Button", "BananaLootRaiderSRListNext", F, "UIPanelButtonTemplate")
F.next:SetWidth(28); F.next:SetHeight(22)
F.next:SetPoint("TOPRIGHT", F, "TOPRIGHT", -24, -46)
F.next:SetText(">")
F.raidName = F:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
F.raidName:SetPoint("LEFT", F.prev, "RIGHT", 10, 0)
F.raidName:SetPoint("RIGHT", F.next, "LEFT", -10, 0)
F.info = F:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
F.info:SetPoint("TOP", F, "TOP", 0, -74)
F.info:SetWidth(480)
F.empty = F:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
F.empty:SetPoint("TOP", F, "TOP", 0, -150)
F.empty:SetWidth(420)

F.scroll = CreateFrame("ScrollFrame", "BananaLootRaiderSRListScroll", F, "UIPanelScrollFrameTemplate")
F.scroll:SetPoint("TOPLEFT", F, "TOPLEFT", 20, -96)
F.scroll:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT", -34, 56)
F.child = CreateFrame("Frame", "BananaLootRaiderSRListChild", F.scroll)
F.child:SetWidth(480)
F.child:SetHeight(1)
F.scroll:SetScrollChild(F.child)
F.scroll:EnableMouseWheel(true)
F.scroll:SetScript("OnMouseWheel", function()
    local cur = F.scroll:GetVerticalScroll()
    local max = F.scroll:GetVerticalScrollRange()
    local nv = cur - arg1 * ROW_H * 2
    if nv < 0 then nv = 0 end
    if nv > max then nv = max end
    F.scroll:SetVerticalScroll(nv)
    local bar = getglobal("BananaLootRaiderSRListScrollScrollBar")
    if bar then bar:SetValue(nv) end
end)

F.reqBtn = CreateFrame("Button", "BananaLootRaiderSRListRequest", F, "UIPanelButtonTemplate")
F.reqBtn:SetWidth(150); F.reqBtn:SetHeight(24)
F.reqBtn:SetPoint("BOTTOMLEFT", F, "BOTTOMLEFT", 22, 20)
F.reqBtn:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    if BananaLootRaider:RequestSROverview("all") then
        DEFAULT_CHAT_FRAME:AddMessage(BananaLootRaider:L("SRL_REQUESTED"))
    end
end)
F.hint = F:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
F.hint:SetPoint("LEFT", F.reqBtn, "RIGHT", 12, 0)
F.hint:SetWidth(330)
F.hint:SetJustifyH("LEFT")

local function GetRow(i)
    if not T.rows[i] then
        local r = CreateFrame("Button", "BananaLootRaiderSRListRow" .. i, F.child)
        r:SetWidth(480)
        r:SetHeight(ROW_H - 2)
        r:SetPoint("TOPLEFT", F.child, "TOPLEFT", 0, -(i - 1) * ROW_H)
        r:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        r:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        r:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetWidth(28); r.icon:SetHeight(28)
        r.icon:SetPoint("LEFT", r, "LEFT", 5, 0)
        r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.name:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
        r.name:SetWidth(160)
        r.name:SetJustifyH("LEFT")
        r.players = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        r.players:SetPoint("LEFT", r.name, "RIGHT", 8, 0)
        r.players:SetWidth(268)
        r.players:SetHeight(32)
        r.players:SetJustifyH("LEFT")
        r.players:SetJustifyV("MIDDLE")
        r:EnableMouseWheel(true)
        r:SetScript("OnMouseWheel", function() F.scroll:GetScript("OnMouseWheel")() end)
        r:SetScript("OnEnter", function()
            if not this.itemID then return end
            BananaLootRaider:ShowItemTooltip(this, this.itemID, "ANCHOR_RIGHT")
            BananaLootRaider:AppendSRLines(GameTooltip, this.itemID)
            GameTooltip:Show()
        end)
        r:SetScript("OnLeave", function() GameTooltip:Hide() end)
        T.rows[i] = r
    end
    return T.rows[i]
end

local function ItemSortName(id)
    local info = BananaLootRaider:GetStaticItemInfo(id)
    return string.lower((info and info.name) or ("zz" .. id))
end

local function AgeText(t)
    local m = math.floor((time() - (t or 0)) / 60)
    if m < 1 then return BananaLootRaider:L("SRL_NOW") end
    if m < 120 then return string.format(BananaLootRaider:L("SRL_MIN"), m) end
    return string.format(BananaLootRaider:L("SRL_HOURS"), math.floor(m / 60))
end

function BananaLootRaider:RefreshSRList()
    if not F:IsShown() then return end
    F.title:SetText(self:L("SRL_TITLE"))
    F.reqBtn:SetText(self:L("SRL_REQUEST"))
    F.hint:SetText(self:L("SRL_HINT"))
    local list = self:GetOverviewList()
    local n = table.getn(list)
    if T.idx > n then T.idx = n end
    if T.idx < 1 then T.idx = 1 end
    local ov = list[T.idx]
    for i = 1, table.getn(T.rows) do T.rows[i]:Hide() end
    if not ov then
        F.raidName:SetText("-")
        F.info:SetText("")
        F.empty:SetText(self:L("SRL_NONE"))
        F.child:SetHeight(1)
        F.scroll:UpdateScrollChildRect()
        return
    end
    F.empty:SetText("")
    F.raidName:SetText(OverviewName(ov) .. (IsEffectivelyActive(ov) and (" |cff33ff99*|r") or ""))
    local ids, count = {}, 0
    for id in pairs(ov.items) do table.insert(ids, id) end
    table.sort(ids, function(a, b)
        local na, nb = ItemSortName(a), ItemSortName(b)
        if na ~= nb then return na < nb end
        return a < b
    end)
    F.info:SetText(string.format(self:L("SRL_INFO"), table.getn(ids), ov.sender or "?", AgeText(ov.time)
        ) .. (n > 1 and ("  |cff888888(" .. T.idx .. "/" .. n .. ")|r") or ""))
    for i = 1, table.getn(ids) do
        local id = ids[i]
        local r = GetRow(i)
        r.itemID = id
        r.icon:SetTexture(self:ResolveItemIcon(id))
        r.name:SetText(self:ResolveItemDisplay(id))
        local parts = {}
        local entries = ov.items[id]
        for k = 1, table.getn(entries) do
            local e = entries[k]
            parts[k] = self:ColoredName(e.n) .. ((e.p and e.p > 0) and (" |cffffcc00+" .. e.p .. "|r") or "")
        end
        r.players:SetText(table.concat(parts, ", "))
        r:Show()
    end
    F.child:SetHeight(math.max(1, table.getn(ids) * ROW_H))
    F.scroll:UpdateScrollChildRect()
end

F.prev:SetScript("OnClick", function() BananaLootRaider:PlayClickSound(); T.idx = T.idx - 1; BananaLootRaider:RefreshSRList() end)
F.next:SetScript("OnClick", function() BananaLootRaider:PlayClickSound(); T.idx = T.idx + 1; BananaLootRaider:RefreshSRList() end)
F:SetScript("OnShow", function() BananaLootRaider:RefreshSRList() end)

function BananaLootRaider:ToggleSRList()
    if F:IsShown() then F:Hide() else T.idx = 1; F:Show() end
end
BananaLootRaider.srListState = T

-- ------------------------------------------------------------
-- Beim Betreten eines Raids/einer Gruppe automatisch die Uebersicht anfragen
-- ------------------------------------------------------------
local joinFrame = CreateFrame("Frame", "BananaLootRaiderSRJoinFrame")
joinFrame:RegisterEvent("RAID_ROSTER_UPDATE")
joinFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
joinFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
local wasGrouped, joinAt = false, nil
joinFrame:SetScript("OnEvent", function()
    local grouped = (GetNumRaidMembers() > 0) or (GetNumPartyMembers() > 0)
    if grouped and (not wasGrouped or event == "PLAYER_ENTERING_WORLD") then joinAt = GetTime() + 4 end
    wasGrouped = grouped
end)
joinFrame:SetScript("OnUpdate", function()
    if joinAt and GetTime() >= joinAt then
        joinAt = nil
        if (GetNumRaidMembers() > 0) or (GetNumPartyMembers() > 0) then
            BananaLootRaider:RequestSROverview("cur")
        end
    end
end)
