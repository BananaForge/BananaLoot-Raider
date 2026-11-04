-- BananaLootRaiderUI.lua
-- Drei Fenster:
--   1) Roll-Sync-Popup: zeigt eingehende Rolls eines BananaLoot-
--      Lootmasters (Item, Countdown, laufende Wuerfe), MS/OS/TM-Buttons.
--   2) Loot-Historie: session-lokale Liste aller per Roll-Sync
--      empfangenen Vergaben.
--   3) SR-Sende-Fenster: sr/unsr per Shift-Klick an einen frei
--      eingetippten Lootmaster-Namen senden (reiner Sende-Komfort).
-- Dazu Minimap-Button und Sprachumschaltung.

BananaLootRaider_UI = {}

local function Trim(str)
    if not str then return str end
    local _, _, captured = string.find(str, "^%s*(.-)%s*$")
    return captured or str
end

local function AttachIconTooltip(row)
    row.iconFrame:SetScript("OnEnter", function()
        -- Fallback fuer Fragezeichen-Icons: Beim Drueberfahren das Item
        -- erneut aktiv beim Server anfragen und das Icon danach ein paar
        -- Sekunden lang neu aufloesen, bis die Textur da ist.
        if row.getItemID and row.refresh then
            local id = row.getItemID()
            if id then
                BananaLootRaider:QueryItem(id, true)
                row.hoverLeft = 4
                row.hoverTick = 0
                row.iconFrame:SetScript("OnUpdate", function()
                    row.hoverTick = row.hoverTick + arg1
                    if row.hoverTick < 0.5 then return end
                    row.hoverTick = 0
                    row.hoverLeft = row.hoverLeft - 0.5
                    row.refresh()
                    if row.hoverLeft <= 0 or BananaLootRaider:GetItemTexture(id) then
                        row.iconFrame:SetScript("OnUpdate", nil)
                    end
                end)
            end
        end
        if row.currentLink and string.find(row.currentLink, "|Hitem:") then
            GameTooltip:SetOwner(row.iconFrame, "ANCHOR_RIGHT")
            local _, _, raw = string.find(row.currentLink, "item:([%d:%-]+)")
            if raw then
                pcall(function() GameTooltip:SetHyperlink("item:" .. raw) end)
            end
            GameTooltip:Show()
        end
    end)
    row.iconFrame:SetScript("OnLeave", function()
        row.iconFrame:SetScript("OnUpdate", nil)
        GameTooltip:Hide()
    end)
end

-- ============================================================
-- 1) ROLL-SYNC-POPUP
-- ============================================================
local rollSyncFrame = CreateFrame("Frame", "BananaLootRaiderRollSyncFrame", UIParent)
rollSyncFrame:SetWidth(260)
rollSyncFrame:SetHeight(320)
rollSyncFrame:SetPoint("CENTER", UIParent, "CENTER", -260, 0)
rollSyncFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 11, top = 11, bottom = 11 },
})
BananaLootRaider_Theme.Darken(rollSyncFrame)
rollSyncFrame:SetMovable(true)
rollSyncFrame:EnableMouse(true)
rollSyncFrame:RegisterForDrag("LeftButton")
rollSyncFrame:SetScript("OnDragStart", function() rollSyncFrame:StartMoving() end)
rollSyncFrame:SetScript("OnDragStop", function() rollSyncFrame:StopMovingOrSizing() end)
rollSyncFrame:SetFrameStrata("HIGH")
rollSyncFrame:Hide()

local rsCloseBtn = CreateFrame("Button", "BananaLootRaiderRollSyncCloseButton", rollSyncFrame, "UIPanelCloseButton")
rsCloseBtn:SetPoint("TOPRIGHT", rollSyncFrame, "TOPRIGHT", -4, -4)
rsCloseBtn:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    rollSyncFrame:Hide()
end)

local rsTitle = rollSyncFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
rsTitle:SetPoint("TOP", rollSyncFrame, "TOP", 0, -12)
rsTitle:SetText(BananaLootRaider:L("RSWIN_TITLE"))

local rsIcon = rollSyncFrame:CreateTexture(nil, "ARTWORK")
rsIcon:SetWidth(28)
rsIcon:SetHeight(28)
rsIcon:SetPoint("TOPLEFT", rollSyncFrame, "TOPLEFT", 16, -36)

local rsIconFrame = CreateFrame("Frame", nil, rollSyncFrame)
rsIconFrame:SetWidth(28)
rsIconFrame:SetHeight(28)
rsIconFrame:SetPoint("TOPLEFT", rollSyncFrame, "TOPLEFT", 16, -36)
rsIconFrame:EnableMouse(true)
local rsIconRow = { iconFrame = rsIconFrame, currentLink = nil }
local rollSyncState, RefreshRollSyncPopup -- Vorwaertsdeklaration (unten befuellt)
rsIconRow.getItemID = function() return rollSyncState and rollSyncState.itemID end
rsIconRow.refresh = function() if RefreshRollSyncPopup then RefreshRollSyncPopup() end end
AttachIconTooltip(rsIconRow)

local rsItemText = rollSyncFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rsItemText:SetPoint("LEFT", rsIcon, "RIGHT", 8, 0)
rsItemText:SetJustifyH("LEFT")
rsItemText:SetWidth(160)

local rsModeText = rollSyncFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
rsModeText:SetPoint("TOPLEFT", rsIcon, "BOTTOMLEFT", 0, -8)

local rsTimeText = rollSyncFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
rsTimeText:SetPoint("LEFT", rsModeText, "RIGHT", 12, 0)

local rsStatusText = rollSyncFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
rsStatusText:SetPoint("TOPLEFT", rsModeText, "BOTTOMLEFT", 0, -8)
rsStatusText:SetWidth(220)
rsStatusText:SetJustifyH("LEFT")

local rsScroll = CreateFrame("ScrollFrame", "BananaLootRaiderRollSyncScroll", rollSyncFrame, "UIPanelScrollFrameTemplate")
rsScroll:SetPoint("TOPLEFT", rollSyncFrame, "TOPLEFT", 16, -112)
rsScroll:SetPoint("BOTTOMRIGHT", rollSyncFrame, "BOTTOMRIGHT", -30, 60)

local rsChild = CreateFrame("Frame", "BananaLootRaiderRollSyncScrollChild", rsScroll)
rsChild:SetWidth(200)
rsChild:SetHeight(1)
rsScroll:SetScrollChild(rsChild)

local RS_ROW_H = 18
local RS_MAX = 15
local rsRows = {}

local function CreateRSListRow(i)
    local r = CreateFrame("Frame", "BananaLootRaiderRollSyncRow" .. i, rsChild)
    r:SetWidth(200)
    r:SetHeight(RS_ROW_H)
    r:SetPoint("TOPLEFT", rsChild, "TOPLEFT", 0, -(i - 1) * RS_ROW_H)

    r.nameText = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.nameText:SetPoint("LEFT", r, "LEFT", 0, 0)
    r.nameText:SetWidth(130)
    r.nameText:SetJustifyH("LEFT")

    r.valueText = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.valueText:SetPoint("RIGHT", r, "RIGHT", 0, 0)
    r.valueText:SetJustifyH("RIGHT")

    return r
end

for i = 1, RS_MAX do
    rsRows[i] = CreateRSListRow(i)
    rsRows[i]:Hide()
end

local rsOverflowText = rollSyncFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
rsOverflowText:SetPoint("BOTTOM", rollSyncFrame, "BOTTOM", 0, 66)
rsOverflowText:SetText("")

local rsMsBtn = CreateFrame("Button", "BananaLootRaiderRollSyncMsBtn", rollSyncFrame, "UIPanelButtonTemplate")
rsMsBtn:SetWidth(60)
rsMsBtn:SetHeight(20)
rsMsBtn:SetPoint("BOTTOMLEFT", rollSyncFrame, "BOTTOMLEFT", 16, 16)
rsMsBtn:SetText(BananaLootRaider:L("RSWIN_MS_BTN"))
rsMsBtn:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    RandomRoll(1, 100)
end)

local rsOsBtn = CreateFrame("Button", "BananaLootRaiderRollSyncOsBtn", rollSyncFrame, "UIPanelButtonTemplate")
rsOsBtn:SetWidth(60)
rsOsBtn:SetHeight(20)
rsOsBtn:SetPoint("LEFT", rsMsBtn, "RIGHT", 6, 0)
rsOsBtn:SetText(BananaLootRaider:L("RSWIN_OS_BTN"))
rsOsBtn:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    RandomRoll(1, 99)
end)

local rsTmBtn = CreateFrame("Button", "BananaLootRaiderRollSyncTmBtn", rollSyncFrame, "UIPanelButtonTemplate")
rsTmBtn:SetWidth(60)
rsTmBtn:SetHeight(20)
rsTmBtn:SetPoint("LEFT", rsOsBtn, "RIGHT", 6, 0)
rsTmBtn:SetText(BananaLootRaider:L("RSWIN_TM_BTN"))
rsTmBtn:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    RandomRoll(1, 98)
end)

rollSyncState = {
    active = false,
    itemID = nil,
    mode = 0,
    duration = 0,
    startTime = 0,
    resolved = false,
    tie = false,
    winner = nil, winnerScore = nil, winnerRoll = nil, winnerPoolCode = nil,
    rolls = {},
    hideAt = nil,
}

function RefreshRollSyncPopup()
    if not rollSyncState.active then return end

    local icon = BananaLootRaider:ResolveItemIcon(rollSyncState.itemID)
    local display = BananaLootRaider:ResolveItemDisplay(rollSyncState.itemID)
    rsIcon:SetTexture(icon)
    if string.find(display, "|Hitem:") then
        rsIconRow.currentLink = display
    else
        rsIconRow.currentLink = nil
    end
    rsItemText:SetText(display)

    local modeText
    if rollSyncState.mode == 1 then modeText = BananaLootRaider:L("RSWIN_MODE_SR")
    elseif rollSyncState.mode == 2 then modeText = BananaLootRaider:L("RSWIN_MODE_ARF")
    else modeText = BananaLootRaider:L("RSWIN_MODE_OPEN") end
    rsModeText:SetText(modeText)

    if rollSyncState.resolved then
        rsTimeText:SetText("")
    else
        local remaining = rollSyncState.duration - (GetTime() - rollSyncState.startTime)
        if remaining < 0 then remaining = 0 end
        rsTimeText:SetText(string.format(BananaLootRaider:L("RSWIN_TIME_LEFT"), math.ceil(remaining)))
    end

    if rollSyncState.resolved then
        rsStatusText:SetText(string.format(BananaLootRaider:L("RSWIN_WINNER"), BananaLootRaider:ColoredName(rollSyncState.winner), rollSyncState.winnerRoll, rollSyncState.winnerScore))
        rsMsBtn:Disable()
        rsOsBtn:Disable()
        rsTmBtn:Disable()
    elseif rollSyncState.tie then
        rsStatusText:SetText(BananaLootRaider:L("RSWIN_TIE"))
        rsMsBtn:Enable()
        rsOsBtn:Enable()
        rsTmBtn:Enable()
    else
        rsStatusText:SetText("")
        rsMsBtn:Enable()
        rsOsBtn:Enable()
        rsTmBtn:Enable()
    end

    -- Sortierung: Pool-Prioritaet zuerst (Hauptspec schlaegt Off-Spec
    -- schlaegt Transmog), erst innerhalb derselben Kategorie nach Wurf-
    -- Wert absteigend. Round Robin (nur wenn der Lootmaster RR-Stufen
    -- mitsendet, siehe RU~...~RR-Feld): niedrigste RR unter den MS-
    -- Wuerfen gewinnt, Wuerfe mit hoeherer RR sind "nicht gewertet".
    local POOL_SYNC_PRIORITY = { ms = 1, os = 2, tmog = 3 }
    local names = {}
    local minRR = nil
    for name, entry in pairs(rollSyncState.rolls) do
        table.insert(names, name)
        if entry.type == "ms" and entry.rr and (not minRR or entry.rr < minRR) then minRR = entry.rr end
    end
    table.sort(names, function(a, b)
        local ea, eb = rollSyncState.rolls[a], rollSyncState.rolls[b]
        local pa = POOL_SYNC_PRIORITY[ea.type] or 9
        local pb = POOL_SYNC_PRIORITY[eb.type] or 9
        if pa ~= pb then return pa < pb end
        if ea.type == "ms" and ea.rr and eb.rr and ea.rr ~= eb.rr then return ea.rr < eb.rr end
        return ea.value > eb.value
    end)

    local anyExcluded = false
    for name, entry in pairs(rollSyncState.rolls) do
        if entry.type == "ms" and entry.rr and minRR and entry.rr > minRR then anyExcluded = true end
    end
    if table.getn(names) > RS_MAX then
        rsOverflowText:SetText(string.format(BananaLootRaider:L("RSWIN_OVERFLOW"), table.getn(names) - RS_MAX))
    elseif anyExcluded then
        rsOverflowText:SetText(BananaLootRaider:L("RSWIN_RR_LEGEND"))
    else
        rsOverflowText:SetText("")
    end

    local shown = 0
    for i = 1, table.getn(names) do
        shown = shown + 1
        if shown > RS_MAX then break end
        local name = names[i]
        local entry = rollSyncState.rolls[name]
        local row = rsRows[shown]
        local poolSuffix = ""
        if entry.type == "os" then poolSuffix = " (" .. BananaLootRaider:L("POOL_OS") .. ")"
        elseif entry.type == "tmog" then poolSuffix = " (" .. BananaLootRaider:L("POOL_TMOG") .. ")" end
        if entry.type == "ms" and entry.rr and minRR and entry.rr > minRR then
            -- Round Robin: Wurf zaehlt nicht (hoehere RR als der beste MS-Roller)
            row.nameText:SetText("|cff888888" .. name .. "|r")
            row.valueText:SetText("|cff888888" .. tostring(entry.value) .. " RR" .. entry.rr .. "|r |cffff5555X|r")
        else
            row.nameText:SetText(BananaLootRaider:ColoredName(name))
            local rrTag = ""
            if entry.type == "ms" and entry.rr then rrTag = " |cffffcc00RR" .. entry.rr .. "|r" end
            row.valueText:SetText(tostring(entry.value) .. rrTag .. poolSuffix)
        end
        row:Show()
    end
    for i = shown + 1, RS_MAX do rsRows[i]:Hide() end
    rsChild:SetHeight(math.max(1, shown * RS_ROW_H))

    if shown == 0 then
        rsRows[1].nameText:SetText(BananaLootRaider:L("RSWIN_NO_ROLLS"))
        rsRows[1].valueText:SetText("")
        rsRows[1]:Show()
    end
end

function BananaLootRaider_UI:HandleRollSync(msgType, fields, sender)
    if msgType == "RS" then
        rollSyncState.active = true
        rollSyncState.itemID = tonumber(fields[2]) or 0
        rollSyncState.duration = tonumber(fields[3]) or 60
        rollSyncState.mode = tonumber(fields[4]) or 0
        rollSyncState.startTime = GetTime()
        rollSyncState.resolved = false
        rollSyncState.tie = false
        rollSyncState.winner = nil
        rollSyncState.rolls = {}
        rollSyncState.hideAt = nil
        if BananaLootRaider_UI.ApplyScale then BananaLootRaider_UI:ApplyScale() end
        rollSyncFrame:Show()
        BananaLootRaider:PlayEventSound("RaidWarning", BananaLootRaider:GetSoundRollStartedEnabled())
        RefreshRollSyncPopup()

    elseif msgType == "RU" then
        local itemID = tonumber(fields[2])
        if not rollSyncState.active or itemID ~= rollSyncState.itemID then return end
        rollSyncState.rolls[fields[3]] = { value = tonumber(fields[4]) or 0, type = fields[5], rr = tonumber(fields[6]) }
        RefreshRollSyncPopup()

    elseif msgType == "RT" then
        local itemID = tonumber(fields[2])
        if not rollSyncState.active or itemID ~= rollSyncState.itemID then return end
        rollSyncState.rolls = {}
        rollSyncState.tie = true
        rollSyncState.startTime = GetTime()
        RefreshRollSyncPopup()

    elseif msgType == "RW" then
        local itemID = tonumber(fields[2])
        if not rollSyncState.active or itemID ~= rollSyncState.itemID then return end
        rollSyncState.resolved = true
        rollSyncState.winner = fields[3]
        rollSyncState.winnerScore = tonumber(fields[4]) or 0
        rollSyncState.winnerRoll = tonumber(fields[5]) or 0
        rollSyncState.winnerPoolCode = fields[6]
        rollSyncState.hideAt = GetTime() + 6
        BananaLootRaider:PlayEventSound("LEVELUP", BananaLootRaider:GetSoundWinnerEnabled())
        RefreshRollSyncPopup()

    elseif msgType == "RC" then
        local itemID = tonumber(fields[2])
        if not rollSyncState.active or itemID ~= rollSyncState.itemID then return end
        rollSyncState.active = false
        rollSyncFrame:Hide()
    end
end

-- ============================================================
-- 2) GETEILTE LOOT-HISTORIE
-- ============================================================
local historyFrame = CreateFrame("Frame", "BananaLootRaiderHistoryFrame", UIParent)
historyFrame:SetWidth(440)
historyFrame:SetHeight(420)
historyFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
historyFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 11, top = 11, bottom = 11 },
})
BananaLootRaider_Theme.Darken(historyFrame)
historyFrame:SetMovable(true)
historyFrame:EnableMouse(true)
historyFrame:RegisterForDrag("LeftButton")
historyFrame:SetScript("OnDragStart", function() historyFrame:StartMoving() end)
historyFrame:SetScript("OnDragStop", function() historyFrame:StopMovingOrSizing() end)
historyFrame:SetFrameStrata("HIGH")
historyFrame:Hide()

local historyTitleIcon = historyFrame:CreateTexture(nil, "ARTWORK")
historyTitleIcon:SetWidth(18)
historyTitleIcon:SetHeight(18)
historyTitleIcon:SetTexture("Interface\\AddOns\\BananaLootRaider\\Icons\\BananaLootRaider_Icon_64")

local historyTitle = historyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
historyTitle:SetText(BananaLootRaider:L("WIN_HISTORY_TITLE"))
historyTitle:SetPoint("TOP", historyFrame, "TOP", 0, -16)
historyTitleIcon:SetPoint("RIGHT", historyTitle, "LEFT", -6, 0)

local historyCloseBtn = CreateFrame("Button", "BananaLootRaiderHistoryCloseButton", historyFrame, "UIPanelCloseButton")
historyCloseBtn:SetPoint("TOPRIGHT", historyFrame, "TOPRIGHT", -6, -6)
historyCloseBtn:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    this:GetParent():Hide()
end)

local historyHelpBtn = CreateFrame("Button", "BananaLootRaiderHistoryHelpBtn", historyFrame, "UIPanelButtonTemplate")
historyHelpBtn:SetWidth(20)
historyHelpBtn:SetHeight(20)
historyHelpBtn:SetPoint("LEFT", historySrBtn, "RIGHT", 4, 0)
historyHelpBtn:SetText("?")
historyHelpBtn:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    BananaLootRaider_UI:ShowHelp()
end)
historyHelpBtn:SetScript("OnEnter", function()
    GameTooltip:SetOwner(historyHelpBtn, "ANCHOR_LEFT")
    GameTooltip:SetText(BananaLootRaider:L("UI_BTN_HELP_TOOLTIP"))
    GameTooltip:Show()
end)
historyHelpBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

local historySrBtn = CreateFrame("Button", "BananaLootRaiderHistorySrBtn", historyFrame, "UIPanelButtonTemplate")
historySrBtn:SetWidth(50)
historySrBtn:SetHeight(20)
historySrBtn:SetPoint("LEFT", historyOptBtn, "RIGHT", 4, 0)
historySrBtn:SetText("SR")
historySrBtn:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    if BananaLootRaider_UI.ToggleSR then BananaLootRaider_UI:ToggleSR() end
end)

local historyOptBtn = CreateFrame("Button", "BananaLootRaiderHistoryOptBtn", historyFrame, "UIPanelButtonTemplate")
historyOptBtn:SetWidth(90)
historyOptBtn:SetHeight(20)
historyOptBtn:SetPoint("TOPLEFT", historyFrame, "TOPLEFT", 20, -44)
historyOptBtn:SetText(BananaLootRaider:L("UI_BTN_OPTIONS"))
historyOptBtn:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    if BananaLootRaider_UI.ToggleOptions then BananaLootRaider_UI:ToggleOptions() end
end)

local historyHint = historyFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
historyHint:SetPoint("TOP", historyFrame, "TOP", 0, -72)
historyHint:SetWidth(400)
historyHint:SetJustifyH("CENTER")
historyHint:SetText(BananaLootRaider:L("WIN_HISTORY_HINT"))

local historyScroll = CreateFrame("ScrollFrame", "BananaLootRaiderHistoryScroll", historyFrame, "UIPanelScrollFrameTemplate")
historyScroll:SetPoint("TOPLEFT", historyFrame, "TOPLEFT", 16, -124)
historyScroll:SetPoint("BOTTOMRIGHT", historyFrame, "BOTTOMRIGHT", -30, 20)

local historyChild = CreateFrame("Frame", "BananaLootRaiderHistoryScrollChild", historyScroll)
historyChild:SetWidth(380)
historyChild:SetHeight(1)
historyScroll:SetScrollChild(historyChild)

local HISTORY_ROW_H = 20
local HISTORY_MAX = 30
local historyRows = {}

local function CreateHistoryRow(i)
    local r = CreateFrame("Frame", "BananaLootRaiderHistoryRow" .. i, historyChild)
    r:SetWidth(380)
    r:SetHeight(HISTORY_ROW_H)
    r:SetPoint("TOPLEFT", historyChild, "TOPLEFT", 0, -(i - 1) * HISTORY_ROW_H)

    r.timeText = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.timeText:SetPoint("LEFT", r, "LEFT", 0, 0)
    r.timeText:SetWidth(40)
    r.timeText:SetJustifyH("LEFT")

    r.itemText = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.itemText:SetPoint("LEFT", r.timeText, "RIGHT", 4, 0)
    r.itemText:SetWidth(160)
    r.itemText:SetJustifyH("LEFT")

    r.winnerText = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.winnerText:SetPoint("LEFT", r.itemText, "RIGHT", 4, 0)
    r.winnerText:SetWidth(100)
    r.winnerText:SetJustifyH("LEFT")

    r.poolText = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.poolText:SetPoint("LEFT", r.winnerText, "RIGHT", 4, 0)
    r.poolText:SetWidth(70)
    r.poolText:SetJustifyH("LEFT")

    return r
end

for i = 1, HISTORY_MAX do
    historyRows[i] = CreateHistoryRow(i)
    historyRows[i]:Hide()
end

local historyOverflowText = historyFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
historyOverflowText:SetPoint("BOTTOM", historyFrame, "BOTTOM", 0, 4)
historyOverflowText:SetText("")

local historyEntries = {}

local HISTORY_POOL_LABEL_KEY = {
    ms = "POOL_MS", os = "POOL_OS", tmog = "POOL_TMOG",
    manual = "POOL_MANUAL", bank = "POOL_BANK", raidroll = "POOL_RAIDROLL",
}

local function RefreshHistoryList()
    local total = table.getn(historyEntries)
    if total > HISTORY_MAX then
        historyOverflowText:SetText(string.format(BananaLootRaider:L("HISTORY_OVERFLOW"), total - HISTORY_MAX))
    else
        historyOverflowText:SetText("")
    end

    local shown = 0
    for i = 1, total do
        shown = shown + 1
        if shown > HISTORY_MAX then break end
        local entry = historyEntries[i]
        local row = historyRows[shown]
        row.timeText:SetText(entry.time)
        row.itemText:SetWidth(160)
        row.itemText:SetText(BananaLootRaider:ResolveItemDisplay(entry.itemID))
        row.winnerText:SetText(BananaLootRaider:ColoredName(entry.winner))
        local labelKey = HISTORY_POOL_LABEL_KEY[entry.poolCode]
        row.poolText:SetText(labelKey and BananaLootRaider:L(labelKey) or (entry.poolCode or ""))
        row:Show()
    end
    for i = shown + 1, HISTORY_MAX do historyRows[i]:Hide() end
    historyChild:SetHeight(math.max(1, shown * HISTORY_ROW_H))

    if shown == 0 then
        historyRows[1].timeText:SetText("")
        historyRows[1].itemText:SetWidth(330)
        historyRows[1].itemText:SetText(BananaLootRaider:L("HISTORY_EMPTY"))
        historyRows[1].winnerText:SetText("")
        historyRows[1].poolText:SetText("")
        historyRows[1]:Show()
    end
end

function BananaLootRaider_UI:AddHistoryEntry(itemID, winner, poolCode)
    table.insert(historyEntries, 1, {
        time = date("%H:%M"),
        itemID = itemID,
        winner = winner,
        poolCode = poolCode,
    })
    if historyFrame:IsShown() then RefreshHistoryList() end
end

function BananaLootRaider_UI:Toggle()
    if historyFrame:IsShown() then
        historyFrame:Hide()
    else
        if BananaLootRaider_UI.ApplyScale then BananaLootRaider_UI:ApplyScale() end
        RefreshHistoryList()
        historyFrame:Show()
    end
end

-- ============================================================
-- 3) SR-SENDE-FENSTER (sr/unsr per Shift-Klick, reiner Sende-Komfort)
-- ============================================================
local srSendFrame = CreateFrame("Frame", "BananaLootRaiderSRSendFrame", UIParent)
srSendFrame:SetWidth(360)
srSendFrame:SetHeight(200)
srSendFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
srSendFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 11, top = 11, bottom = 11 },
})
BananaLootRaider_Theme.Darken(srSendFrame)
srSendFrame:SetMovable(true)
srSendFrame:EnableMouse(true)
srSendFrame:RegisterForDrag("LeftButton")
srSendFrame:SetScript("OnDragStart", function() srSendFrame:StartMoving() end)
srSendFrame:SetScript("OnDragStop", function() srSendFrame:StopMovingOrSizing() end)
srSendFrame:SetFrameStrata("DIALOG")
srSendFrame:Hide()

local srSendCloseBtn = CreateFrame("Button", "BananaLootRaiderSRSendCloseButton", srSendFrame, "UIPanelCloseButton")
srSendCloseBtn:SetPoint("TOPRIGHT", srSendFrame, "TOPRIGHT", -4, -4)
srSendCloseBtn:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    this:GetParent():Hide()
end)

local srSendTitle = srSendFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
srSendTitle:SetPoint("TOP", srSendFrame, "TOP", 0, -16)
srSendTitle:SetText(BananaLootRaider:L("UI_SR_TITLE"))

local srSendHint = srSendFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
srSendHint:SetPoint("TOP", srSendFrame, "TOP", 0, -38)
srSendHint:SetWidth(320)
srSendHint:SetJustifyH("CENTER")
srSendHint:SetText(BananaLootRaider:L("UI_SR_HINT"))

local srSendNameLabel = srSendFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
srSendNameLabel:SetPoint("TOPLEFT", srSendFrame, "TOPLEFT", 20, -80)
srSendNameLabel:SetText(BananaLootRaider:L("UI_SR_NAME_LABEL"))

local srSendNameBox = CreateFrame("EditBox", "BananaLootRaiderSRSendNameBox", srSendFrame, "InputBoxTemplate")
srSendNameBox:SetWidth(180)
srSendNameBox:SetHeight(20)
srSendNameBox:SetPoint("TOPLEFT", srSendNameLabel, "BOTTOMLEFT", 6, -6)
srSendNameBox:SetAutoFocus(false)
srSendNameBox:SetMaxLetters(24)

local srSendItemLabel = srSendFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
srSendItemLabel:SetPoint("TOPLEFT", srSendNameBox, "BOTTOMLEFT", -6, -14)
srSendItemLabel:SetText(BananaLootRaider:L("UI_SR_ITEM_LABEL"))

local srSendItemBox = CreateFrame("EditBox", "BananaLootRaiderSRSendItemBox", srSendFrame, "InputBoxTemplate")
srSendItemBox:SetWidth(300)
srSendItemBox:SetHeight(20)
srSendItemBox:SetPoint("TOPLEFT", srSendItemLabel, "BOTTOMLEFT", 6, -6)
srSendItemBox:SetAutoFocus(false)

-- Shift-Klick auf ein Item traegt normalerweise ueber ChatEdit_InsertLink
-- automatisch in die aktuell fokussierte EditBox ein, sobald sie sich
-- selbst als Ziel meldet (siehe globale ChatEdit_InsertLink-Kette in
-- Blizzards FrameXML). SetAutoFocus(false) reicht dafuer nicht aus --
-- die Box muss beim Klicken den Fokus tatsaechlich halten, daher wird
-- der Fokus explizit beim Betreten des Fensters gesetzt.
srSendFrame:SetScript("OnShow", function()
    srSendItemBox:SetFocus()
end)

local srSendSendBtn = CreateFrame("Button", "BananaLootRaiderSRSendSendBtn", srSendFrame, "UIPanelButtonTemplate")
srSendSendBtn:SetWidth(100)
srSendSendBtn:SetHeight(20)
srSendSendBtn:SetPoint("BOTTOMLEFT", srSendFrame, "BOTTOMLEFT", 20, 16)
srSendSendBtn:SetText(BananaLootRaider:L("UI_SR_SEND_BTN"))
srSendSendBtn:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    local name = Trim(srSendNameBox:GetText())
    local item = srSendItemBox:GetText()
    local ok, err = BananaLootRaider:SendSR(name, item)
    if ok then
        DEFAULT_CHAT_FRAME:AddMessage(string.format(BananaLootRaider:L("UI_SR_SENT"), item, name))
    elseif err == "need_name" then
        DEFAULT_CHAT_FRAME:AddMessage(BananaLootRaider:L("UI_SR_NEED_NAME"))
    else
        DEFAULT_CHAT_FRAME:AddMessage(BananaLootRaider:L("UI_SR_NEED_ITEM"))
    end
end)

local srSendUnsendBtn = CreateFrame("Button", "BananaLootRaiderSRSendUnsendBtn", srSendFrame, "UIPanelButtonTemplate")
srSendUnsendBtn:SetWidth(100)
srSendUnsendBtn:SetHeight(20)
srSendUnsendBtn:SetPoint("LEFT", srSendSendBtn, "RIGHT", 10, 0)
srSendUnsendBtn:SetText(BananaLootRaider:L("UI_SR_UNSEND_BTN"))
srSendUnsendBtn:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    local name = Trim(srSendNameBox:GetText())
    local item = srSendItemBox:GetText()
    local ok, err = BananaLootRaider:SendUnSR(name, item)
    if ok then
        DEFAULT_CHAT_FRAME:AddMessage(string.format(BananaLootRaider:L("UI_SR_UNSENT"), item, name))
    elseif err == "need_name" then
        DEFAULT_CHAT_FRAME:AddMessage(BananaLootRaider:L("UI_SR_NEED_NAME"))
    else
        DEFAULT_CHAT_FRAME:AddMessage(BananaLootRaider:L("UI_SR_NEED_ITEM"))
    end
end)

function BananaLootRaider_UI:ToggleSR()
    if srSendFrame:IsShown() then
        srSendFrame:Hide()
    else
        srSendFrame:Show()
    end
end

-- ============================================================
-- 4) BEFEHLSUEBERSICHT (wiederverwendet dieselbe Copy-Box wie Export
-- in BananaLootRaiderExtra.lua -- hier nur der Aufrufer, das eigentliche
-- Fenster wird dort gebaut, damit CreateCopyBoxFrame nicht doppelt
-- gepflegt werden muss).
-- ============================================================
-- (BananaLootRaider_UI:ShowHelp wird in BananaLootRaiderExtra.lua definiert.)

-- ============================================================
-- 5) SPRACHUMSCHALTUNG + SKALIERUNG
-- ============================================================
function BananaLootRaider_UI:ApplyLocale()
    rsTitle:SetText(BananaLootRaider:L("RSWIN_TITLE"))
    rsMsBtn:SetText(BananaLootRaider:L("RSWIN_MS_BTN"))
    rsOsBtn:SetText(BananaLootRaider:L("RSWIN_OS_BTN"))
    rsTmBtn:SetText(BananaLootRaider:L("RSWIN_TM_BTN"))
    if rollSyncState.active then RefreshRollSyncPopup() end

    historyTitle:SetText(BananaLootRaider:L("WIN_HISTORY_TITLE"))
    historyHint:SetText(BananaLootRaider:L("WIN_HISTORY_HINT"))
    historyOptBtn:SetText(BananaLootRaider:L("UI_BTN_OPTIONS"))
    if historyFrame:IsShown() then RefreshHistoryList() end

    srSendTitle:SetText(BananaLootRaider:L("UI_SR_TITLE"))
    srSendHint:SetText(BananaLootRaider:L("UI_SR_HINT"))
    srSendNameLabel:SetText(BananaLootRaider:L("UI_SR_NAME_LABEL"))
    srSendItemLabel:SetText(BananaLootRaider:L("UI_SR_ITEM_LABEL"))
    srSendSendBtn:SetText(BananaLootRaider:L("UI_SR_SEND_BTN"))
    srSendUnsendBtn:SetText(BananaLootRaider:L("UI_SR_UNSEND_BTN"))
end

function BananaLootRaider_UI:ApplyScale()
    rollSyncFrame:SetScale(BananaLootRaider:GetUIScale())
    historyFrame:SetScale(BananaLootRaider:GetUIScale())
    srSendFrame:SetScale(BananaLootRaider:GetUIScale())
end

-- ============================================================
-- 6) TICKER: Live-Update waehrend ein Roll laeuft + Icon-Retry
-- ============================================================
local ticker = CreateFrame("Frame")
local lastUpdate = 0
ticker:SetScript("OnUpdate", function()
    lastUpdate = lastUpdate + arg1
    if lastUpdate > 1 then
        lastUpdate = 0

        if rollSyncFrame:IsShown() then
            if rollSyncState.hideAt and GetTime() >= rollSyncState.hideAt then
                rollSyncFrame:Hide()
                rollSyncState.active = false
            else
                RefreshRollSyncPopup()
            end
        end

        local needRefresh = false
        for id, tries in pairs(BananaLootRaider.pendingIcons) do
            local itemTexture = BananaLootRaider:GetItemTexture(id)
            if itemTexture then
                BananaLootRaider.pendingIcons[id] = nil
                needRefresh = true
            elseif tries >= 15 then
                BananaLootRaider.pendingIcons[id] = nil
            else
                BananaLootRaider.pendingIcons[id] = tries + 1
                if BananaLootRaider.QueryItem then BananaLootRaider:QueryItem(id, true) end
            end
        end

        if needRefresh then
            if rollSyncFrame:IsShown() then RefreshRollSyncPopup() end
            if historyFrame:IsShown() then RefreshHistoryList() end
        end
    end
end)

-- ============================================================
-- 7) MINIMAP-BUTTON
-- ============================================================
local mmButton = CreateFrame("Button", "BananaLootRaiderMinimapButton", Minimap)
mmButton:SetWidth(31)
mmButton:SetHeight(31)
mmButton:SetFrameStrata("MEDIUM")
mmButton:SetFrameLevel(8)
mmButton:SetToplevel(true)
mmButton:SetMovable(true)
mmButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
mmButton:RegisterForDrag("LeftButton")

local mmIcon = mmButton:CreateTexture(nil, "BACKGROUND")
mmIcon:SetWidth(20)
mmIcon:SetHeight(20)
mmIcon:SetPoint("CENTER", mmButton, "CENTER", 0, 0)
mmIcon:SetTexture("Interface\\AddOns\\BananaLootRaider\\Icons\\BananaLootRaider_Icon_64")

local mmBorder = mmButton:CreateTexture(nil, "OVERLAY")
mmBorder:SetWidth(54)
mmBorder:SetHeight(54)
mmBorder:SetPoint("TOPLEFT", mmButton, "TOPLEFT", 0, 0)
mmBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

mmButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local function GetSavedAngle()
    BananaLootRaider.EnsureDB()
    return BananaLootRaider_DB.settings.minimapAngle or 220
end

local function SetSavedAngle(angle)
    BananaLootRaider.EnsureDB()
    BananaLootRaider_DB.settings.minimapAngle = angle
end

local function UpdateMinimapButtonPosition(angle)
    local radius = 80
    local rad = angle * (math.pi / 180)
    local x = math.cos(rad) * radius
    local y = math.sin(rad) * radius
    mmButton:ClearAllPoints()
    mmButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

mmButton:SetScript("OnDragStart", function()
    this.dragging = true
end)

mmButton:SetScript("OnDragStop", function()
    this.dragging = false
end)

mmButton:SetScript("OnUpdate", function()
    if this.dragging then
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        px, py = px / scale, py / scale
        local angle = math.deg(math.atan2(py - my, px - mx))
        UpdateMinimapButtonPosition(angle)
        SetSavedAngle(angle)
    end
end)

mmButton:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    if arg1 == "RightButton" then
        BananaLootRaider_UI:ToggleOptions()
    elseif IsShiftKeyDown() then
        BananaLootRaider_UI:ToggleSR()
    else
        BananaLootRaider_UI:Toggle()
    end
end)

mmButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:SetText("BananaLoot Raider")
    GameTooltip:AddLine(BananaLootRaider:L("MM_TOOLTIP_LEFT"), 1, 1, 1)
    GameTooltip:AddLine(BananaLootRaider:L("MM_TOOLTIP_SHIFT"), 1, 1, 1)
    GameTooltip:AddLine(BananaLootRaider:L("MM_TOOLTIP_RIGHT"), 1, 1, 1)
    GameTooltip:AddLine(BananaLootRaider:L("MM_TOOLTIP_DRAG"), 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)
mmButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Sofort beim Laden mit dem Standardwinkel positionieren und anzeigen
-- (SavedVariables sind zu diesem Zeitpunkt noch nicht geladen), damit
-- der Button nie ohne Anker/unsichtbar bleibt. Der gespeicherte Winkel
-- wird danach bei ADDON_LOADED/PLAYER_LOGIN/PLAYER_ENTERING_WORLD
-- nachgezogen (mehrfach schadet nicht, z.B. falls ein Minimap-Addon
-- wie pfUI die Minimap erst spaeter umbaut).
UpdateMinimapButtonPosition(220)
mmButton:SetFrameLevel(Minimap:GetFrameLevel() + 8)
mmButton:Show()

local mmInitFrame = CreateFrame("Frame")
mmInitFrame:RegisterEvent("ADDON_LOADED")
mmInitFrame:RegisterEvent("PLAYER_LOGIN")
mmInitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
mmInitFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 ~= "BananaLootRaider" then return end
    UpdateMinimapButtonPosition(GetSavedAngle())
    mmButton:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    mmButton:Show()
end)

-- ============================================================
-- 8) ZENTRALER SPRACH-EINSTIEGSPUNKT (auch fuer Extra.lua)
-- ============================================================
function BananaLootRaider_UI:ApplyLocaleAll()
    if BananaLootRaider.ApplyLocaleCode then BananaLootRaider:ApplyLocaleCode() end
    if self.ApplyLocale then self:ApplyLocale() end
    if self.ApplyLocaleExtra then self:ApplyLocaleExtra() end
end
