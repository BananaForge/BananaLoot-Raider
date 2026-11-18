-- BananaLootRaiderBossHelp.lua
-- Boss-Hilfen: kleines Info-Fenster mit der Erklaerung fuer die ROLLE des Spielers (Tank/DD/Heiler).
--   Ausloeser A: Addon-Nachricht des Raidleiters (BananaLoot):  BA~raid~boss (Feld 1), BB~raid~boss (Feld 2)
--                BT~raid~boss~feld~nr~gesamt~stueck  = vom Raidleiter bearbeiteter Text (wird gespeichert)
--   Ausloeser B (Fallback): Boss anvisieren (nach 3 Sekunden, falls keine Nachricht kam)
-- Das Fenster schliesst sich nur per X oder bei Kampfbeginn.
-- Texte: Standard aus BananaLootRaiderBossData.lua, bearbeitete aus BananaLootRaider_DB.bossTexts.

BananaLootRaider.bossShown = {}     -- ["RAID:boss"] = GetTime() der letzten Anzeige
BananaLootRaider.bossBuf = {}       -- Stuecke bearbeiteter Texte (BT)

local function DB()
    BananaLootRaider.EnsureDB()
    local d = BananaLootRaider_DB
    if not d.bossTexts then d.bossTexts = {} end
    if not d.bossHidden then d.bossHidden = {} end
    return d
end

-- ------------------------------------------------------------
-- Einstellungen
-- ------------------------------------------------------------
function BananaLootRaider:GetBossHelpEnabled()
    BananaLootRaider.EnsureDB()
    if BananaLootRaider_DB.settings.bossHelp == nil then return true end
    return BananaLootRaider_DB.settings.bossHelp
end
function BananaLootRaider:SetBossHelpEnabled(v)
    BananaLootRaider.EnsureDB()
    BananaLootRaider_DB.settings.bossHelp = v and true or false
end
function BananaLootRaider:GetBossHelpRole()
    BananaLootRaider.EnsureDB()
    return BananaLootRaider_DB.settings.bossHelpRole or "auto"
end
function BananaLootRaider:SetBossHelpRole(r)
    BananaLootRaider.EnsureDB()
    BananaLootRaider_DB.settings.bossHelpRole = r
end

-- ------------------------------------------------------------
-- Rolle: Einstellung oder automatisch ueber die Talentverteilung
-- ------------------------------------------------------------
function BananaLootRaider:DetectRole()
    local _, class = UnitClass("player")
    local best, bestPts, total = 0, -1, 0
    if GetTalentTabInfo then
        for tab = 1, 3 do
            local _, _, pts = GetTalentTabInfo(tab)
            pts = pts or 0
            total = total + pts
            if pts > bestPts then bestPts = pts; best = tab end
        end
    end
    if class == "PRIEST" then
        if total > 0 and best == 3 then return "dd" end
        return "heal"
    elseif total == 0 then
        return "dd"
    elseif class == "WARRIOR" then
        return best == 3 and "tank" or "dd"
    elseif class == "PALADIN" then
        if best == 1 then return "heal" elseif best == 2 then return "tank" end
        return "dd"
    elseif class == "DRUID" then
        return best == 3 and "heal" or "dd"
    elseif class == "SHAMAN" then
        return best == 3 and "heal" or "dd"
    end
    return "dd"
end

-- Wer bin ich? Rolle (Einstellung oder Talente), Klasse und Talentbaum. Im Test-Fenster kann beides
-- vorgetaeuscht werden (simRole / simClass), damit sich jede Rolle und Klasse ansehen laesst.
local DEFAULT_ROLE = { PRIEST = "heal" }
function BananaLootRaider:GetMyIdentity()
    local _, class = UnitClass("player")
    local spec = nil
    if GetTalentTabInfo then
        local bestPts = 0
        for tab = 1, 3 do
            local name, _, pts = GetTalentTabInfo(tab)
            if (pts or 0) > bestPts then bestPts = pts; spec = name end
        end
    end
    if self.simClass then class = self.simClass; spec = nil end
    local role, auto
    local r = self.simRole or self:GetBossHelpRole()
    if r == "tank" or r == "dd" or r == "heal" then
        role, auto = r, false
    elseif self.simClass then
        role, auto = DEFAULT_ROLE[class] or "dd", true
    else
        role, auto = self:DetectRole(), true
    end
    return role, auto, class, spec
end

function BananaLootRaider:GetMyRole()
    local role, auto = self:GetMyIdentity()
    return role, auto
end

-- ------------------------------------------------------------
-- Bossdaten und Texte
-- ------------------------------------------------------------
local function FindRaid(key)
    local data = BananaLootRaider_RaidData
    if not data then return nil end
    for i = 1, table.getn(data) do
        if data[i].key == key then return data[i] end
    end
    return nil
end

local function FindBossByKey(raidKey, bossKey)
    local raid = FindRaid(raidKey)
    if not raid then return nil end
    for b = 1, table.getn(raid.bosses) do
        if raid.bosses[b].key == bossKey then return raid, raid.bosses[b] end
    end
    return nil
end

local function ZoneRaidKey()
    local data = BananaLootRaider_RaidData
    if not data then return nil end
    local zone = GetRealZoneText and GetRealZoneText() or nil
    if not zone or zone == "" then zone = GetZoneText and GetZoneText() or nil end
    if not zone or zone == "" then return nil end
    zone = string.lower(zone)
    for i = 1, table.getn(data) do
        for z = 1, table.getn(data[i].zones) do
            if string.lower(data[i].zones[z]) == zone then return data[i].key, zone end
        end
    end
    return nil, zone
end

function BananaLootRaider:FindBossByUnit(name)
    local data = BananaLootRaider_RaidData
    if not name or not data then return nil end
    local zoneKey, zone = ZoneRaidKey()
    if zone and string.find(zone, "stratholm") then return nil end
    local fallbackRaid, fallbackBoss
    for i = 1, table.getn(data) do
        local raid = data[i]
        for b = 1, table.getn(raid.bosses) do
            local boss = raid.bosses[b]
            for u = 1, table.getn(boss.units) do
                if boss.units[u] == name then
                    if raid.key == zoneKey then return raid, boss end
                    if not boss.zoneOnly and not raid.optional and not fallbackBoss then
                        fallbackRaid, fallbackBoss = raid, boss
                    end
                end
            end
        end
    end
    return fallbackRaid, fallbackBoss
end

function BananaLootRaider:GetBossText(raidKey, boss, field)
    local t = DB().bossTexts[raidKey]
    if t and t[boss.key] and t[boss.key][field] ~= nil then return t[boss.key][field] end
    return boss[field] or ""
end

-- Text in Abschnitte nach Rolle zerlegen: Tank/Tanks, DD/DDs, Heiler, Alle. Rueckgabe: intro, segs
-- (segs = Liste { role = "tank"|"dd"|"heal"|"all", text = ... }) oder nil, wenn der Text keine Rollen nennt.
local ROLE_OF = { Tank = "tank", Tanks = "tank", DD = "dd", DDs = "dd", Heiler = "heal", Alle = "all" }
function BananaLootRaider:SplitRoles(text)
    local marks = {}
    local init = 1
    while true do
        local s, e, label = string.find(text, "(%a+): ", init)
        if not s then break end
        if ROLE_OF[label] and (s == 1 or string.sub(text, s - 1, s - 1) == " ") then
            table.insert(marks, { s = s, e = e, role = ROLE_OF[label] })
        end
        init = e + 1
    end
    if table.getn(marks) == 0 then return nil end
    local intro = string.gsub(string.sub(text, 1, marks[1].s - 1), "%s+$", "")
    local segs = {}
    for i = 1, table.getn(marks) do
        local stop = marks[i + 1] and (marks[i + 1].s - 1) or string.len(text)
        local body = string.gsub(string.sub(text, marks[i].e + 1, stop), "%s+$", "")
        table.insert(segs, { role = marks[i].role, text = body })
    end
    return intro, segs
end

local ROLE_KEY = { tank = "BH_R_TANK", dd = "BH_R_DD", heal = "BH_R_HEAL" }

-- Satzweise Zuordnung: welche Rollen/Klassen spricht ein Satz an? (Stichworte im Text)
local ROLE_WORDS = {
    tank = { "Tank", "Taunt", "taunt", "Aggro", "wegdrehen", "Rücken zur Wand", "Off-Tank" },
    heal = { "Heiler", "heilen", "Heilung", "überheilen" },
    dd = { "DD", "Melee", "Nahkämpfer", "Nahkampf", "Ranged", "Fernkämpfer", "Fernkampf", "Zauberwirker", "Caster" },
}
local CLASS_WORDS = {
    HUNTER = { "Hunter", "Jäger", "Tranquilizing" },
    MAGE = { "Magier", "Mage" },
    DRUID = { "Druide", "Druid " },
    PRIEST = { "Priester", "Fear Ward", "Mind Control" },
    SHAMAN = { "Schamane", "Tremor Totem" },
    PALADIN = { "Paladin" },
    WARRIOR = { "Krieger" },
    ROGUE = { "Schurke", "Rogue" },
    WARLOCK = { "Hexenmeister", "Warlock" },
}
-- Faehigkeiten, die bestimmte Klassen ausfuehren (ohne dass die Klasse im Text genannt wird)
local ACTION_CLASSES = {
    { "decurs", { "DRUID", "MAGE" } },
    { "dispell", { "PRIEST", "PALADIN" } },
    { "purg", { "PRIEST", "SHAMAN" } },
    { "cleans", { "PALADIN", "DRUID", "SHAMAN" } },
    { "unterbrech", { "ROGUE", "WARRIOR", "MAGE", "SHAMAN" } },
    { "stunn", { "ROGUE", "WARRIOR", "PALADIN" } },
}

local function HasWord(sentence, list)
    for i = 1, table.getn(list) do
        if string.find(sentence, list[i], 1, true) then return true end
    end
    return false
end

-- Rueckgabe: roles = { tank=true, ... }, classes = { HUNTER=true, ... } (nil, wenn nichts)
function BananaLootRaider:TagSentence(sentence)
    local roles, classes, any = {}, {}, false
    local sn = string.gsub(sentence, "Druids of the Talon", "")   -- Gegner, nicht die Klasse
    for role, list in pairs(ROLE_WORDS) do
        if HasWord(sn, list) then roles[role] = true; any = true end
    end
    for class, list in pairs(CLASS_WORDS) do
        if HasWord(sn, list) then classes[class] = true; any = true end
    end
    for i = 1, table.getn(ACTION_CLASSES) do
        local act = ACTION_CLASSES[i]
        if string.find(sn, act[1], 1, true) then
            for k = 1, table.getn(act[2]) do classes[act[2][k]] = true end
            any = true
        end
    end
    return roles, classes, any
end

-- Text in Saetze teilen (Abkuerzungen wie "ca." und "Sek." bleiben zusammen)
local function SplitSentences(text)
    local t = string.gsub(text, "ca%.", "ca\\1")
    t = string.gsub(t, "Sek%.", "Sek\\1")
    t = string.gsub(t, "Min%.", "Min\\1")
    t = string.gsub(t, "z%.B%.", "zB\\1")
    local out = {}
    local init = 1
    while init <= string.len(t) do
        local s, e = string.find(t, "[.!?]%s+", init)
        local piece
        if s then piece = string.sub(t, init, s); init = e + 1 else piece = string.sub(t, init); init = string.len(t) + 1 end
        piece = string.gsub(piece, "\\1", ".")
        piece = string.gsub(piece, "^%s+", "")
        piece = string.gsub(piece, "%s+$", "")
        if piece ~= "" then table.insert(out, piece) end
    end
    return out
end

-- Teilt einen Boss-Text in Items { text, roles, classes, general } (bei "Tank:/DDs:/Heiler:"-Abschnitten
-- gilt die Rolle des Abschnitts fuer alle seine Saetze).
function BananaLootRaider:ClassifyText(text)
    local items = {}
    local intro, segs = self:SplitRoles(text)
    local function addSentences(str, segRole)
        local sentences = SplitSentences(str)
        for i = 1, table.getn(sentences) do
            local roles, classes, any = self:TagSentence(sentences[i])
            if segRole and segRole ~= "all" then roles[segRole] = true; any = true end
            table.insert(items, { text = sentences[i], roles = roles, classes = classes, tagged = any, seg = segRole })
        end
    end
    if segs then
        if intro ~= "" then addSentences(intro, nil) end
        for i = 1, table.getn(segs) do addSentences(segs[i].text, segs[i].role) end
    else
        addSentences(text, nil)
    end
    return items
end

-- Ist der Satz fuer mich (Rolle oder Klasse)?
local function IsForMe(item, role, class)
    if item.roles[role] then return true end
    if class and item.classes[class] then return true end
    return false
end

-- Fertigen Anzeigetext bauen: oben "FUER DICH" (hervorgehoben), darunter allgemeine Saetze, zuletzt - gedaempft - Saetze,
-- die nur andere Rollen/Klassen betreffen (onlyMine blendet die letzten beiden Gruppen aus).
function BananaLootRaider:BuildBossBody(text, role, class, onlyMine)
    if type(class) == "boolean" then onlyMine = class; class = nil end   -- aeltere Aufrufe: (text, role, showAll)
    local items = self:ClassifyText(text)
    local mine, general, other = {}, {}, {}
    for i = 1, table.getn(items) do
        local it = items[i]
        if IsForMe(it, role, class) then table.insert(mine, it)
        elseif not it.tagged or it.seg == "all" then table.insert(general, it)
        else table.insert(other, it) end
    end
    local out = ""
    if table.getn(mine) > 0 then
        out = out .. "|cff33ff99" .. self:L("BH_FOR_YOU") .. "|r\n"
        for i = 1, table.getn(mine) do out = out .. "|cffffd100> " .. mine[i].text .. "|r\n" end
    end
    if table.getn(general) > 0 then
        if table.getn(mine) > 0 then out = out .. "|cffaaaaaa" .. self:L("BH_FOR_ALL") .. "|r\n" end
        for i = 1, table.getn(general) do out = out .. general[i].text .. "\n" end
    end
    if table.getn(mine) == 0 and table.getn(general) == 0 and table.getn(other) > 0 and onlyMine then
        out = out .. self:L("BH_NO_ROLE_TEXT") .. "\n"
    end
    if table.getn(other) > 0 and not onlyMine then
        out = out .. "|cff777777" .. self:L("BH_FOR_OTHERS") .. "|r\n"
        for i = 1, table.getn(other) do out = out .. "|cff888888" .. other[i].text .. "|r\n" end
    end
    return out
end

-- ------------------------------------------------------------
-- Fenster
-- ------------------------------------------------------------
local F = CreateFrame("Frame", "BananaLootRaiderBossFrame", UIParent)
BananaLootRaider.bossFrame = F
F:SetWidth(380)
F:SetHeight(200)
F:SetPoint("TOP", UIParent, "TOP", 0, -140)
F:SetFrameStrata("HIGH")
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

F.close = CreateFrame("Button", "BananaLootRaiderBossFrameClose", F, "UIPanelCloseButton")
F.close:SetPoint("TOPRIGHT", F, "TOPRIGHT", -4, -4)
F.close:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    F:Hide()
end)

F.title = F:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
F.title:SetPoint("TOP", F, "TOP", 0, -18)
F.title:SetWidth(320)
F.raid = F:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
F.raid:SetPoint("TOP", F.title, "BOTTOM", 0, -2)
F.role = F:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
F.role:SetPoint("TOPLEFT", F, "TOPLEFT", 22, -62)
F.body = F:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
F.body:SetPoint("TOPLEFT", F, "TOPLEFT", 22, -84)
F.body:SetWidth(336)
F.body:SetJustifyH("LEFT")
F.body:SetJustifyV("TOP")

F.allBtn = CreateFrame("Button", "BananaLootRaiderBossAllBtn", F, "UIPanelButtonTemplate")
F.allBtn:SetWidth(110)
F.allBtn:SetHeight(20)
F.allBtn:SetPoint("TOPRIGHT", F, "TOPRIGHT", -22, -58)
F.allBtn:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    F.onlyMine = not F.onlyMine
    BananaLootRaider:RefreshBossFrame()
end)

F.hideCheck = CreateFrame("CheckButton", "BananaLootRaiderBossHideCheck", F, "UICheckButtonTemplate")
F.hideCheck:SetPoint("BOTTOMLEFT", F, "BOTTOMLEFT", 16, 12)
F.hideCheck:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    if F.key then DB().bossHidden[F.key] = F.hideCheck:GetChecked() and true or nil end
end)
F.hideLabel = F:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
F.hideLabel:SetPoint("LEFT", F.hideCheck, "RIGHT", 2, 1)

local function Estimate(text)
    local lines = 0
    local pos = 1
    for line in string.gfind(text .. "\n", "(.-)\n") do
        lines = lines + math.max(1, math.ceil(string.len(string.gsub(line, "|c%x%x%x%x%x%x%x%x", "")) / 52))
    end
    return lines * 13
end

function BananaLootRaider:RefreshBossFrame()
    if not F.raidObj or not F.bossObj then return end
    local role, auto, class, spec = self:GetMyIdentity()
    F.title:SetText(F.bossObj.label)
    F.raid:SetText(F.raidObj.name)
    local className = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class]) or class or ""
    local who = className .. ((spec and spec ~= "") and (" - " .. spec) or "")
    F.role:SetText(string.format(self:L("BH_ROLE"), "|cff33ff99" .. self:L(ROLE_KEY[role]) .. "|r")
        .. "  |cffaaaaaa(" .. who .. (auto and (", " .. self:L("BH_AUTO")) or "") .. ")|r")
    F.allBtn:SetText(self:L(F.onlyMine and "BH_SHOW_ALL" or "BH_SHOW_MINE"))
    F.hideLabel:SetText(self:L("BH_HIDE_BOSS"))
    local body = ""
    local m1 = self:GetBossText(F.raidObj.key, F.bossObj, "m1")
    if m1 ~= "" then body = self:BuildBossBody(m1, role, class, F.onlyMine) end
    if F.showSecond then
        local m2 = self:GetBossText(F.raidObj.key, F.bossObj, "m2")
        if m2 ~= "" then
            body = body .. "\n|cff88ccff" .. self:L("BH_SECOND") .. "|r\n" .. self:BuildBossBody(m2, role, class, F.onlyMine)
        end
    end
    body = string.gsub(body, "%s+$", "")
    F.body:SetText(body)
    local h = F.body:GetHeight()
    if not h or h < 14 then h = Estimate(body) end
    F:SetHeight(84 + h + 54)
    F.hideCheck:SetChecked(DB().bossHidden[F.key] and true or false)
end

-- Fenster fuer einen Boss zeigen. field = "m1" oder "m2" (BB: Zusatztext). force = ignoriert Schalter.
function BananaLootRaider:ShowBossHelp(raid, boss, field, force)
    if not raid or not boss then return end
    local key = raid.key .. ":" .. boss.key
    if not force then
        if not self:GetBossHelpEnabled() then return end
        if DB().bossHidden[key] then return end
        if UnitAffectingCombat and UnitAffectingCombat("player") then return end
    end
    local same = F:IsShown() and F.key == key
    F.raidObj, F.bossObj, F.key = raid, boss, key
    if not same then F.onlyMine = false; F.showSecond = false end
    if field == "m2" then F.showSecond = true end
    self.bossShown[key] = GetTime()
    self:RefreshBossFrame()
    F:Show()
end

-- ------------------------------------------------------------
-- Nachrichten des Raidleiters
-- ------------------------------------------------------------
function BananaLootRaider:HandleBossMessage(msgType, fields)
    local raidKey, bossKey = fields[2], fields[3]
    if not raidKey or not bossKey then return end
    if msgType == "BT" then
        local field = fields[4]
        local nr, total = tonumber(fields[5]), tonumber(fields[6])
        if (field ~= "m1" and field ~= "m2") or not nr or not total then return end
        local bk = raidKey .. "~" .. bossKey .. "~" .. field
        local buf = self.bossBuf[bk]
        if not buf or buf.total ~= total or nr == 1 then buf = { total = total, parts = {} }; self.bossBuf[bk] = buf end
        buf.parts[nr] = fields[7] or ""
        for i = 1, total do
            if buf.parts[i] == nil then return end
        end
        local text = ""
        for i = 1, total do text = text .. buf.parts[i] end
        self.bossBuf[bk] = nil
        local raid, boss = FindBossByKey(raidKey, bossKey)
        local d = DB()
        if boss and text == (boss[field] or "") then
            if d.bossTexts[raidKey] and d.bossTexts[raidKey][bossKey] then d.bossTexts[raidKey][bossKey][field] = nil end
        else
            if not d.bossTexts[raidKey] then d.bossTexts[raidKey] = {} end
            if not d.bossTexts[raidKey][bossKey] then d.bossTexts[raidKey][bossKey] = {} end
            d.bossTexts[raidKey][bossKey][field] = text
        end
        return
    end
    local raid, boss = FindBossByKey(raidKey, bossKey)
    if not boss then return end
    local key = raidKey .. ":" .. bossKey
    if msgType == "BA" then
        -- Fallback hat vor wenigen Sekunden schon gezeigt: nicht doppelt aufpoppen
        local last = self.bossShown[key]
        if last and (GetTime() - last) < 20 and F:IsShown() and F.key == key then
            self:RefreshBossFrame()
            return
        end
        self:ShowBossHelp(raid, boss, "m1")
    else
        self:ShowBossHelp(raid, boss, "m2")
    end
end

-- ------------------------------------------------------------
-- Fallback: Boss anvisieren; Kampfbeginn schliesst das Fenster
-- ------------------------------------------------------------
local ev = CreateFrame("Frame", "BananaLootRaiderBossEvents")
ev:RegisterEvent("PLAYER_TARGET_CHANGED")
ev:RegisterEvent("PLAYER_REGEN_DISABLED")
local pending = nil
ev:SetScript("OnEvent", function()
    if event == "PLAYER_REGEN_DISABLED" then
        F:Hide()
        pending = nil
    elseif event == "PLAYER_TARGET_CHANGED" then
        pending = nil
        if not BananaLootRaider:GetBossHelpEnabled() then return end
        if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then return end
        if not UnitExists("target") or UnitIsPlayer("target") or UnitIsDead("target") then return end
        if UnitCanAttack and not UnitCanAttack("player", "target") then return end
        local name = UnitName("target")
        local raid, boss = BananaLootRaider:FindBossByUnit(name)
        if not boss then return end
        local key = raid.key .. ":" .. boss.key
        local last = BananaLootRaider.bossShown[key]
        if last and (GetTime() - last) < 1800 then return end
        pending = { due = GetTime() + 3, raid = raid, boss = boss, name = name, key = key }
    end
end)
ev:SetScript("OnUpdate", function()
    if not pending or GetTime() < pending.due then return end
    local p = pending
    pending = nil
    if UnitExists("target") and UnitName("target") == p.name and not UnitIsDead("target") then
        local last = BananaLootRaider.bossShown[p.key]
        if not last or (GetTime() - last) >= 1800 then
            BananaLootRaider:ShowBossHelp(p.raid, p.boss, "m1")
        end
    end
end)

-- ------------------------------------------------------------
-- /blr boss [Name|reset]  -- Vorschau bzw. ausgeblendete Bosse zuruecksetzen
-- ------------------------------------------------------------
function BananaLootRaider:BossSlash(arg)
    arg = string.lower(arg or "")
    if arg == "reset" then
        DB().bossHidden = {}
        DEFAULT_CHAT_FRAME:AddMessage(self:L("BH_CMD_RESET"))
        return
    end
    local data = BananaLootRaider_RaidData
    if arg ~= "" and data then
        for i = 1, table.getn(data) do
            for b = 1, table.getn(data[i].bosses) do
                local boss = data[i].bosses[b]
                if string.find(string.lower(boss.label), arg, 1, true) or string.find(string.lower(boss.key), arg, 1, true) then
                    self:ShowBossHelp(data[i], boss, "m1", true)
                    return
                end
            end
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage(self:L("BH_CMD_NOTFOUND"))
end

-- ------------------------------------------------------------
-- Optionen (im Raider-Optionsfenster, unter der Skalierung)
-- ------------------------------------------------------------
local optFrame = getglobal("BananaLootRaiderOptionsFrame")
if optFrame then
    optFrame:SetHeight(800)
    local O = {}
    O.check = CreateFrame("CheckButton", "BananaLootRaiderBossHelpCheck", optFrame, "UICheckButtonTemplate")
    O.check:SetPoint("TOPLEFT", optFrame, "TOPLEFT", 18, -650)
    O.check:SetScript("OnClick", function()
        BananaLootRaider:PlayClickSound()
        BananaLootRaider:SetBossHelpEnabled(O.check:GetChecked() and true or false)
    end)
    O.label = optFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    O.label:SetPoint("LEFT", O.check, "RIGHT", 2, 1)
    O.hint = optFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    O.hint:SetPoint("TOPLEFT", optFrame, "TOPLEFT", 20, -680)
    O.hint:SetWidth(420)
    O.hint:SetJustifyH("LEFT")
    O.roleLabel = optFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    O.roleLabel:SetPoint("TOPLEFT", optFrame, "TOPLEFT", 20, -732)
    O.btns = {}
    local defs = { { "auto", "BH_OPT_AUTO" }, { "tank", "BH_R_TANK" }, { "dd", "BH_R_DD" }, { "heal", "BH_R_HEAL" } }
    local prev
    for i = 1, 4 do
        local b = CreateFrame("Button", "BananaLootRaiderBossRoleBtn" .. i, optFrame, "UIPanelButtonTemplate")
        b:SetWidth(80)
        b:SetHeight(20)
        if prev then b:SetPoint("LEFT", prev, "RIGHT", 6, 0) else b:SetPoint("TOPLEFT", optFrame, "TOPLEFT", 26, -754) end
        b.role = defs[i][1]
        b.key = defs[i][2]
        b:SetScript("OnClick", function()
            BananaLootRaider:PlayClickSound()
            BananaLootRaider:SetBossHelpRole(this.role)
            BananaLootRaider_BossOptRefresh()
        end)
        O.btns[i] = b
        prev = b
    end
    function BananaLootRaider_BossOptRefresh()
        O.check:SetChecked(BananaLootRaider:GetBossHelpEnabled())
        O.label:SetText(BananaLootRaider:L("BH_OPT_ENABLE"))
        O.hint:SetText(BananaLootRaider:L("BH_OPT_HINT"))
        O.roleLabel:SetText(BananaLootRaider:L("BH_OPT_ROLE"))
        local cur = BananaLootRaider:GetBossHelpRole()
        for i = 1, 4 do
            local b = O.btns[i]
            b:SetText(BananaLootRaider:L(b.key))
            local fs = b.GetFontString and b:GetFontString()
            if fs then
                if b.role == cur then fs:SetTextColor(1, 0.82, 0) else fs:SetTextColor(0.8, 0.8, 0.8) end
            end
        end
        if BananaLootRaider.bossFrame:IsShown() then BananaLootRaider:RefreshBossFrame() end
    end
    optFrame:SetScript("OnShow", function() BananaLootRaider_BossOptRefresh() end)
    local origApply = BananaLootRaider_UI.ApplyLocaleAll
    BananaLootRaider_UI.ApplyLocaleAll = function(self)
        if origApply then origApply(self) end
        BananaLootRaider_BossOptRefresh()
    end
    BananaLootRaider_BossOptRefresh()
end
