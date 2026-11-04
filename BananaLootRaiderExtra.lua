-- BananaLootRaiderExtra.lua
-- Optionsfenster (Roll-Sync/Trade-Tracking/Sound/Skalierung/Sprache)
-- sowie das Befehlsuebersicht-Popup.

local localeTexts = {}
local function RegisterLocaleText(obj, key)
    table.insert(localeTexts, { obj = obj, key = key })
    obj:SetText(BananaLootRaider:L(key))
end

-- ============================================================
-- 1) OPTIONSFENSTER
-- Einspaltiges Layout mit grosszuegigen, fest verifizierten Abstaenden
-- (keine zwei Spalten nebeneinander, siehe frueherer Overlap-Bug: lange
-- deutsche Labels/Hinweistexte kollidierten bei zu knapper Platzierung).
-- ============================================================
local optFrame = CreateFrame("Frame", "BananaLootRaiderOptionsFrame", UIParent)
optFrame:SetWidth(460)
optFrame:SetHeight(700)
optFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
optFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 11, top = 11, bottom = 11 },
})
BananaLootRaider_Theme.Darken(optFrame)
optFrame:SetMovable(true)
optFrame:EnableMouse(true)
optFrame:RegisterForDrag("LeftButton")
optFrame:SetScript("OnDragStart", function() optFrame:StartMoving() end)
optFrame:SetScript("OnDragStop", function() optFrame:StopMovingOrSizing() end)
optFrame:SetFrameStrata("DIALOG")
optFrame:Hide()

local optLogo = optFrame:CreateTexture(nil, "ARTWORK")
optLogo:SetWidth(100)
optLogo:SetHeight(100)
optLogo:SetPoint("TOP", optFrame, "TOP", 0, -8)
optLogo:SetTexture("Interface\\AddOns\\BananaLootRaider\\Icons\\BananaLootRaider_Logo_256")

local optCloseBtn = CreateFrame("Button", "BananaLootRaiderOptionsCloseButton", optFrame, "UIPanelCloseButton")
optCloseBtn:SetPoint("TOPRIGHT", optFrame, "TOPRIGHT", -4, -4)
optCloseBtn:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    this:GetParent():Hide()
end)

local optTitle = optFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
optTitle:SetPoint("TOP", optFrame, "TOP", 0, -118)
RegisterLocaleText(optTitle, "UI_TITLE_OPT")

-- ------------------------------------------------------------
-- Roll-Sync empfangen
-- ------------------------------------------------------------
local rollSyncCheck = CreateFrame("CheckButton", "BananaLootRaiderRollSyncCheck", optFrame, "UICheckButtonTemplate")
rollSyncCheck:SetPoint("TOPLEFT", optFrame, "TOPLEFT", 18, -148)
rollSyncCheck:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    BananaLootRaider:SetRollSyncEnabled(rollSyncCheck:GetChecked() and true or false)
end)

local rollSyncLabel = optFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rollSyncLabel:SetPoint("LEFT", rollSyncCheck, "RIGHT", 2, 0)
RegisterLocaleText(rollSyncLabel, "OPT_ROLLSYNC_LABEL")

local rollSyncHint = optFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
rollSyncHint:SetPoint("TOPLEFT", optFrame, "TOPLEFT", 20, -172)
rollSyncHint:SetWidth(420)
rollSyncHint:SetJustifyH("LEFT")
RegisterLocaleText(rollSyncHint, "OPT_ROLLSYNC_HINT")

-- ------------------------------------------------------------
-- Trade-Tracking (naechster Abschnitt beginnt erst bei -276, damit auch
-- ein 6-7-zeilig umbrechender Hinweistext oben druebor garantiert Platz hat)
-- ------------------------------------------------------------
local tradeTrackingCheck = CreateFrame("CheckButton", "BananaLootRaiderTradeTrackingCheck", optFrame, "UICheckButtonTemplate")
tradeTrackingCheck:SetPoint("TOPLEFT", optFrame, "TOPLEFT", 18, -276)
tradeTrackingCheck:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    BananaLootRaider:SetTradeTrackingEnabled(tradeTrackingCheck:GetChecked() and true or false)
end)

local tradeTrackingLabel = optFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
tradeTrackingLabel:SetPoint("LEFT", tradeTrackingCheck, "RIGHT", 2, 0)
RegisterLocaleText(tradeTrackingLabel, "OPT_TRADETRACKING_LABEL")

local tradeTrackingHint = optFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
tradeTrackingHint:SetPoint("TOPLEFT", optFrame, "TOPLEFT", 20, -300)
tradeTrackingHint:SetWidth(420)
tradeTrackingHint:SetJustifyH("LEFT")
RegisterLocaleText(tradeTrackingHint, "OPT_TRADETRACKING_HINT")

-- ------------------------------------------------------------
-- Sound (naechster Abschnitt ab -392, gleiche grosszuegige Logik)
-- ------------------------------------------------------------
local soundSectionLabel = optFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
soundSectionLabel:SetPoint("TOPLEFT", optFrame, "TOPLEFT", 20, -392)
RegisterLocaleText(soundSectionLabel, "OPT_SOUND_LABEL")

local soundEnabledCheck = CreateFrame("CheckButton", "BananaLootRaiderSoundEnabledCheck", optFrame, "UICheckButtonTemplate")
soundEnabledCheck:SetPoint("TOPLEFT", optFrame, "TOPLEFT", 18, -414)
soundEnabledCheck:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    BananaLootRaider:SetSoundEnabled(soundEnabledCheck:GetChecked() and true or false)
end)
local soundEnabledLabel = optFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
soundEnabledLabel:SetPoint("LEFT", soundEnabledCheck, "RIGHT", 2, 0)
RegisterLocaleText(soundEnabledLabel, "OPT_SOUND_MASTER_LABEL")

local soundRollCheck = CreateFrame("CheckButton", "BananaLootRaiderSoundRollCheck", optFrame, "UICheckButtonTemplate")
soundRollCheck:SetPoint("TOPLEFT", optFrame, "TOPLEFT", 30, -436)
soundRollCheck:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    BananaLootRaider:SetSoundRollStartedEnabled(soundRollCheck:GetChecked() and true or false)
end)
local soundRollLabel = optFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
soundRollLabel:SetPoint("LEFT", soundRollCheck, "RIGHT", 2, 0)
RegisterLocaleText(soundRollLabel, "OPT_SOUND_ROLL_LABEL")

local soundWinnerCheck = CreateFrame("CheckButton", "BananaLootRaiderSoundWinnerCheck", optFrame, "UICheckButtonTemplate")
soundWinnerCheck:SetPoint("TOPLEFT", optFrame, "TOPLEFT", 30, -458)
soundWinnerCheck:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    BananaLootRaider:SetSoundWinnerEnabled(soundWinnerCheck:GetChecked() and true or false)
end)
local soundWinnerLabel = optFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
soundWinnerLabel:SetPoint("LEFT", soundWinnerCheck, "RIGHT", 2, 0)
RegisterLocaleText(soundWinnerLabel, "OPT_SOUND_WINNER_LABEL")

local soundClickCheck = CreateFrame("CheckButton", "BananaLootRaiderSoundClickCheck", optFrame, "UICheckButtonTemplate")
soundClickCheck:SetPoint("TOPLEFT", optFrame, "TOPLEFT", 18, -480)
soundClickCheck:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    BananaLootRaider:SetSoundButtonClicksEnabled(soundClickCheck:GetChecked() and true or false)
end)
local soundClickLabel = optFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
soundClickLabel:SetPoint("LEFT", soundClickCheck, "RIGHT", 2, 0)
RegisterLocaleText(soundClickLabel, "OPT_SOUND_CLICK_LABEL")

-- ------------------------------------------------------------
-- Sprache (eigene Zeile, volle Breite -- NICHT mehr neben der
-- Skalierung, da die langen deutschen Labels sonst kollidieren)
-- ------------------------------------------------------------
local languageLabel = optFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
languageLabel:SetPoint("TOPLEFT", optFrame, "TOPLEFT", 20, -516)
RegisterLocaleText(languageLabel, "OPT_LANGUAGE_LABEL")

local langDeBtn = CreateFrame("Button", "BananaLootRaiderLangDeBtn", optFrame, "UIPanelButtonTemplate")
langDeBtn:SetWidth(90)
langDeBtn:SetHeight(20)
langDeBtn:SetPoint("TOPLEFT", optFrame, "TOPLEFT", 26, -538)
langDeBtn:SetText("Deutsch")
langDeBtn:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    BananaLootRaider:SetLanguage("de")
    DEFAULT_CHAT_FRAME:AddMessage(BananaLootRaider:L("OPT_LANGUAGE_SET"))
    if BananaLootRaider_UI and BananaLootRaider_UI.ApplyLocaleAll then BananaLootRaider_UI:ApplyLocaleAll() end
end)

local langEnBtn = CreateFrame("Button", "BananaLootRaiderLangEnBtn", optFrame, "UIPanelButtonTemplate")
langEnBtn:SetWidth(90)
langEnBtn:SetHeight(20)
langEnBtn:SetPoint("LEFT", langDeBtn, "RIGHT", 10, 0)
langEnBtn:SetText("English")
langEnBtn:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    BananaLootRaider:SetLanguage("en")
    DEFAULT_CHAT_FRAME:AddMessage(BananaLootRaider:L("OPT_LANGUAGE_SET"))
    if BananaLootRaider_UI and BananaLootRaider_UI.ApplyLocaleAll then BananaLootRaider_UI:ApplyLocaleAll() end
end)

-- ------------------------------------------------------------
-- Fenster-Skalierung (Roll-Sync-Popup, Historie, SR-Sende-Fenster) --
-- eigene Zeile, volle Breite, unterhalb der Sprache.
-- ------------------------------------------------------------
local scaleLabel = optFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
scaleLabel:SetPoint("TOPLEFT", optFrame, "TOPLEFT", 20, -570)
RegisterLocaleText(scaleLabel, "OPT_SCALE_LABEL")

local scaleEditBox = CreateFrame("EditBox", "BananaLootRaiderScaleEditBox", optFrame, "InputBoxTemplate")
scaleEditBox:SetWidth(50)
scaleEditBox:SetHeight(20)
scaleEditBox:SetPoint("TOPLEFT", optFrame, "TOPLEFT", 26, -592)
scaleEditBox:SetAutoFocus(false)
scaleEditBox:SetNumeric(true)

local scaleSaveBtn = CreateFrame("Button", "BananaLootRaiderScaleSaveBtn", optFrame, "UIPanelButtonTemplate")
scaleSaveBtn:SetWidth(80)
scaleSaveBtn:SetHeight(20)
scaleSaveBtn:SetPoint("LEFT", scaleEditBox, "RIGHT", 16, 0)
RegisterLocaleText(scaleSaveBtn, "OPT_SAVE_BTN")
scaleSaveBtn:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    local value = tonumber(scaleEditBox:GetText())
    if BananaLootRaider:SetUIScalePercent(value) then
        DEFAULT_CHAT_FRAME:AddMessage(string.format(BananaLootRaider:L("OPT_SCALE_SET"), value))
        if BananaLootRaider_UI and BananaLootRaider_UI.ApplyScale then BananaLootRaider_UI:ApplyScale() end
    else
        DEFAULT_CHAT_FRAME:AddMessage(BananaLootRaider:L("OPT_SCALE_INVALID"))
    end
end)

local scaleHint = optFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
scaleHint:SetPoint("TOPLEFT", optFrame, "TOPLEFT", 20, -616)
scaleHint:SetWidth(420)
scaleHint:SetJustifyH("LEFT")
RegisterLocaleText(scaleHint, "OPT_SCALE_HINT")

function BananaLootRaider_UI:ToggleOptions()
    if optFrame:IsShown() then
        optFrame:Hide()
    else
        BananaLootRaider.EnsureDB()
        rollSyncCheck:SetChecked(BananaLootRaider:GetRollSyncEnabled())
        tradeTrackingCheck:SetChecked(BananaLootRaider:GetTradeTrackingEnabled())
        scaleEditBox:SetText(tostring(BananaLootRaider:GetUIScalePercent()))
        soundEnabledCheck:SetChecked(BananaLootRaider:GetSoundEnabled())
        soundRollCheck:SetChecked(BananaLootRaider:GetSoundRollStartedEnabled())
        soundWinnerCheck:SetChecked(BananaLootRaider:GetSoundWinnerEnabled())
        soundClickCheck:SetChecked(BananaLootRaider:GetSoundButtonClicksEnabled())
        optFrame:Show()
    end
end

-- ============================================================
-- 2) BEFEHLSUEBERSICHT
-- ============================================================
local helpFrame = CreateFrame("Frame", "BananaLootRaiderHelpFrame", UIParent)
helpFrame:SetWidth(420)
helpFrame:SetHeight(360)
helpFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
helpFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 11, top = 11, bottom = 11 },
})
BananaLootRaider_Theme.Darken(helpFrame)
helpFrame:SetMovable(true)
helpFrame:EnableMouse(true)
helpFrame:RegisterForDrag("LeftButton")
helpFrame:SetScript("OnDragStart", function() helpFrame:StartMoving() end)
helpFrame:SetScript("OnDragStop", function() helpFrame:StopMovingOrSizing() end)
helpFrame:SetFrameStrata("DIALOG")
helpFrame:Hide()

local helpTitle = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
helpTitle:SetPoint("TOP", helpFrame, "TOP", 0, -16)
RegisterLocaleText(helpTitle, "WIN_HELP_TITLE")

local helpCloseBtn = CreateFrame("Button", "BananaLootRaiderHelpCloseButton", helpFrame, "UIPanelCloseButton")
helpCloseBtn:SetPoint("TOPRIGHT", helpFrame, "TOPRIGHT", -4, -4)
helpCloseBtn:SetScript("OnClick", function()
    BananaLootRaider:PlayClickSound()
    this:GetParent():Hide()
end)

local helpScroll = CreateFrame("ScrollFrame", "BananaLootRaiderHelpScroll", helpFrame, "UIPanelScrollFrameTemplate")
helpScroll:SetPoint("TOPLEFT", helpFrame, "TOPLEFT", 20, -50)
helpScroll:SetPoint("BOTTOMRIGHT", helpFrame, "BOTTOMRIGHT", -34, 46)

local helpEditBox = CreateFrame("EditBox", "BananaLootRaiderHelpEditBox", helpScroll)
helpEditBox:SetMultiLine(true)
helpEditBox:SetFontObject(ChatFontNormal)
helpEditBox:SetWidth(360)
helpEditBox:SetAutoFocus(true)
helpEditBox:SetScript("OnEscapePressed", function() helpFrame:Hide() end)
helpScroll:SetScrollChild(helpEditBox)

local helpHint = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
helpHint:SetPoint("BOTTOM", helpFrame, "BOTTOM", 0, 16)
RegisterLocaleText(helpHint, "WIN_HELP_HINT")

function BananaLootRaider_UI:ShowHelp()
    local text = BananaLootRaider:L("CMD_LEGEND_TEXT")
    helpEditBox:SetText(text)
    helpEditBox:HighlightText()
    helpFrame:Show()
    helpEditBox:SetFocus()
end

-- ============================================================
-- 3) SPRACHUMSCHALTUNG
-- ============================================================
function BananaLootRaider_UI:ApplyLocaleExtra()
    for i = 1, table.getn(localeTexts) do
        local entry = localeTexts[i]
        entry.obj:SetText(BananaLootRaider:L(entry.key))
    end
    if helpFrame:IsShown() then BananaLootRaider_UI:ShowHelp() end
end
