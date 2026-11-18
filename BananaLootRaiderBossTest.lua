-- BananaLootRaiderBossTest.lua
-- Boss-Test: Uebersicht aller Raids (aufklappbar) mit ihren Bossen. Ein Klick auf einen Boss zeigt das
-- Info-Fenster so, wie es ein Raider sieht (Rolle/Klasse hervorgehoben). Rolle und Klasse lassen sich
-- vortaeuschen. Nur waehrend des BananaLoot-Testlaufs (BananaLoot.testMode) nutzbar.

local T = { open = {}, rows = {} }
local ROW_H = 20
local CLASSES = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }

local F = CreateFrame("Frame", "BananaLootRaiderBossTestFrame", UIParent)
T.frame = F
F:SetWidth(380)
F:SetHeight(560)
F:SetPoint("CENTER", UIParent, "CENTER", -300, 0)
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

F.close = CreateFrame("Button", "BananaLootRaiderBossTestClose", F, "UIPanelCloseButton")
F.close:SetPoint("TOPRIGHT", F, "TOPRIGHT", -4, -4)
F.close:SetScript("OnClick", function() BananaLootRaider:PlayClickSound(); F:Hide() end)
F.title = F:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
F.title:SetPoint("TOP", F, "TOP", 0, -16)
F.hint = F:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
F.hint:SetPoint("TOP", F, "TOP", 0, -40)
F.hint:SetWidth(330)

-- Rolle / Klasse vortaeuschen
F.roleLabel = F:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
F.roleLabel:SetPoint("TOPLEFT", F, "TOPLEFT", 22, -82)
F.classLabel = F:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
F.classLabel:SetPoint("TOPLEFT", F, "TOPLEFT", 22, -112)

local function Refresh() BananaLootRaider_BossTestRefresh() end

local function MakeBtn(name, w, text)
    local b = CreateFrame("Button", name, F, "UIPanelButtonTemplate")
    b:SetWidth(w)
    b:SetHeight(20)
    return b
end

F.roleBtns = {}
local roleDefs = { { nil, "BHT_REAL" }, { "tank", "BH_R_TANK" }, { "dd", "BH_R_DD" }, { "heal", "BH_R_HEAL" } }
for i = 1, 4 do
    local b = MakeBtn("BananaLootRaiderBossTestRole" .. i, 70)
    b:SetPoint("TOPLEFT", F, "TOPLEFT", 70 + (i - 1) * 74, -78)
    b.role = roleDefs[i][1]
    b.key = roleDefs[i][2]
    b:SetScript("OnClick", function()
        BananaLootRaider:PlayClickSound()
        BananaLootRaider.simRole = this.role
        Refresh()
    end)
    F.roleBtns[i] = b
end
F.classBtns = {}
for i = 1, 9 do
    local b = MakeBtn("BananaLootRaiderBossTestClass" .. i, 64)
    local col, row = math.mod(i - 1, 5), math.floor((i - 1) / 5)
    b:SetPoint("TOPLEFT", F, "TOPLEFT", 70 + col * 60, -106 - row * 22)
    b:SetWidth(58)
    b.class = CLASSES[i]
    b:SetScript("OnClick", function()
        BananaLootRaider:PlayClickSound()
        BananaLootRaider.simClass = (BananaLootRaider.simClass == this.class) and nil or this.class
        Refresh()
    end)
    F.classBtns[i] = b
end

-- Liste (scrollbar), Zeilen lazy
F.scroll = CreateFrame("ScrollFrame", "BananaLootRaiderBossTestScroll", F, "UIPanelScrollFrameTemplate")
F.scroll:SetPoint("TOPLEFT", F, "TOPLEFT", 20, -162)
F.scroll:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT", -34, 20)
F.child = CreateFrame("Frame", "BananaLootRaiderBossTestChild", F.scroll)
F.child:SetWidth(300)
F.child:SetHeight(1)
F.scroll:SetScrollChild(F.child)
F.scroll:EnableMouseWheel(true)
F.scroll:SetScript("OnMouseWheel", function()
    local cur = F.scroll:GetVerticalScroll()
    local max = F.scroll:GetVerticalScrollRange()
    local nv = cur - arg1 * ROW_H * 3
    if nv < 0 then nv = 0 end
    if nv > max then nv = max end
    F.scroll:SetVerticalScroll(nv)
    local bar = getglobal("BananaLootRaiderBossTestScrollScrollBar")
    if bar then bar:SetValue(nv) end
end)

local function GetRow(i)
    if not T.rows[i] then
        local r = CreateFrame("Button", "BananaLootRaiderBossTestRow" .. i, F.child)
        r:SetWidth(300)
        r:SetHeight(ROW_H - 1)
        r:SetPoint("TOPLEFT", F.child, "TOPLEFT", 0, -(i - 1) * ROW_H)
        r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        r.text:SetPoint("LEFT", r, "LEFT", 6, 0)
        r.text:SetWidth(288)
        r.text:SetJustifyH("LEFT")
        r.hl = r:CreateTexture(nil, "BACKGROUND")
        r.hl:SetAllPoints(r)
        r.hl:SetTexture(1, 1, 1, 0.08)
        r.hl:Hide()
        r:SetScript("OnEnter", function() this.hl:Show() end)
        r:SetScript("OnLeave", function() this.hl:Hide() end)
        r:EnableMouseWheel(true)
        r:SetScript("OnMouseWheel", function() F.scroll:GetScript("OnMouseWheel")() end)
        r:SetScript("OnClick", function()
            BananaLootRaider:PlayClickSound()
            if this.isBoss == false then
                T.open[this.raid.key] = not T.open[this.raid.key]
                Refresh()
            elseif this.isBoss == true then
                BananaLootRaider:ShowBossHelp(this.raid, this.boss, "m2", true)   -- Text 1 + 2, ohne Schalter
            end
        end)
        T.rows[i] = r
    end
    return T.rows[i]
end

function BananaLootRaider_BossTestRefresh()
    F.title:SetText(BananaLootRaider:L("BHT_TITLE"))
    F.hint:SetText(BananaLootRaider:L("BHT_HINT"))
    F.roleLabel:SetText(BananaLootRaider:L("BHT_ROLE"))
    F.classLabel:SetText(BananaLootRaider:L("BHT_CLASS"))
    for i = 1, 4 do
        local b = F.roleBtns[i]
        b:SetText(BananaLootRaider:L(b.key))
        local fs = b.GetFontString and b:GetFontString()
        if fs then
            if b.role == BananaLootRaider.simRole then fs:SetTextColor(1, 0.82, 0) else fs:SetTextColor(0.8, 0.8, 0.8) end
        end
    end
    for i = 1, 9 do
        local b = F.classBtns[i]
        b:SetText((LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[b.class]) or b.class)
        local fs = b.GetFontString and b:GetFontString()
        if fs then
            if b.class == BananaLootRaider.simClass then fs:SetTextColor(1, 0.82, 0) else fs:SetTextColor(0.8, 0.8, 0.8) end
        end
    end
    local n = 0
    local data = BananaLootRaider_RaidData or {}
    for i = 1, table.getn(data) do
        local raid = data[i]
        n = n + 1
        local r = GetRow(n)
        r.raid, r.boss, r.isBoss = raid, nil, false
        r.text:SetText("|cffffd100" .. (T.open[raid.key] and "[-] " or "[+] ") .. raid.name .. "|r  |cff888888(" .. table.getn(raid.bosses) .. ")|r")
        r:Show()
        if T.open[raid.key] then
            for b = 1, table.getn(raid.bosses) do
                n = n + 1
                local br = GetRow(n)
                br.raid, br.boss, br.isBoss = raid, raid.bosses[b], true
                br.text:SetText("      " .. raid.bosses[b].label)
                br:Show()
            end
        end
    end
    for i = n + 1, table.getn(T.rows) do T.rows[i]:Hide() end
    F.child:SetHeight(math.max(1, n * ROW_H))
    F.scroll:UpdateScrollChildRect()
    if BananaLootRaider.bossFrame and BananaLootRaider.bossFrame:IsShown() then BananaLootRaider:RefreshBossFrame() end
end

-- nur im BananaLoot-Testlauf
function BananaLootRaider:OpenBossTest()
    if not (BananaLoot and BananaLoot.testMode) then
        DEFAULT_CHAT_FRAME:AddMessage(self:L("BHT_NEED_TEST"))
        return false
    end
    F:Show()
    BananaLootRaider_BossTestRefresh()
    return true
end

F:SetScript("OnHide", function()
    BananaLootRaider.simRole, BananaLootRaider.simClass = nil, nil
    if BananaLootRaider.bossFrame and BananaLootRaider.bossFrame:IsShown() then BananaLootRaider:RefreshBossFrame() end
end)

-- Testlauf beendet -> Test-Fenster und Info-Fenster schliessen
local elapsed = 0
F:SetScript("OnUpdate", function()
    elapsed = elapsed + (arg1 or 0)
    if elapsed < 1 then return end
    elapsed = 0
    if not (BananaLoot and BananaLoot.testMode) then
        F:Hide()
        if BananaLootRaider.bossFrame then BananaLootRaider.bossFrame:Hide() end
    end
end)

BananaLootRaider.bossTest = T
