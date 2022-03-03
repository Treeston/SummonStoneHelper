local _G, StaticTooltip_Show, GetCursorPosition, CreateFrame =
      _G, StaticTooltip_Show, GetCursorPosition, CreateFrame
local GameTooltipTextLeft1, GameTooltipTextLeft2 =
      GameTooltipTextLeft1, GameTooltipTextLeft2

local _, addon = ...

local SummonTracker, SummonStoneData, LocalizedString = addon.SummonTracker, addon.SummonStoneData, addon.LocalizedString

if not LocalizedString then return end

print(LocalizedString["|cffffd300SummonStoneHelper|r: Loaded. |cffffd300/ssh|r for settings."])

-- { name, stoneMapId, maps, zones }
local activeMeetingStone

local function GetMemberNeedsSummon(idx)
    if not activeMeetingStone then return end
    
    local name, _, _, level, class, classFile, subzone, isOnline, isDead = GetRaidRosterInfo(idx)
    if not isOnline then return end
    if (level < activeMeetingStone.levelMin) or (level > activeMeetingStone.levelMax) then return end
    if not UnitExists(name) then return end
    
    if UnitIsVisible(name) then return end
    local _,_,_, mapId = UnitPosition(name)
    if activeMeetingStone.maps[mapId] then return end
    
    if activeMeetingStone.stoneMapId == mapId then
        if activeMeetingStone.zones[subzone] then return end
    end
    
    if SummonTracker.GetPendingSummonInfo(name) then return end
    
    return name, subzone, class, RAID_CLASS_COLORS[classFile], isDead
end

local dummyFrameTarget = CreateFrame("Button", "SummonStoneHelperTargetButton", nil, "SecureActionButtonTemplate")
dummyFrameTarget:SetAttribute("type", "macro")
dummyFrameTarget:RegisterForClicks("LeftButtonUp")

local dummyFrameScrollUp = CreateFrame("Button", "SummonStoneHelperScrollUpButton")
dummyFrameScrollUp:RegisterForClicks("LeftButtonUp")

local dummyFrameScrollDown = CreateFrame("Button", "SummonStoneHelperScrollDownButton")
dummyFrameScrollDown:RegisterForClicks("LeftButtonUp")

local targetFrame = CreateFrame("Frame", nil, UIParent)
targetFrame:SetIgnoreParentScale(true)
targetFrame:SetSize(2,2)
local targetFrameTextContainer = CreateFrame("Frame", "SummonStoneHelperTargetFrame", UIParent)
targetFrameTextContainer:SetPoint("BOTTOM", targetFrame, "TOP", 5, 0)
targetFrameTextContainer:SetSize(170,55)
local bgTexture = targetFrameTextContainer:CreateTexture(nil, "BACKGROUND")
bgTexture:SetAllPoints()
bgTexture:SetColorTexture(0,0,0)
bgTexture:SetAlpha(0.3)
local fontFace = DEFAULT_CHAT_FRAME:GetFont()
local targetLabelText = targetFrameTextContainer:CreateFontString(nil, "ARTWORK")
targetLabelText:SetPoint("TOP", 0, -5)
targetLabelText:SetPoint("LEFT", 5, 0)
local targetPlayerNameText = targetFrameTextContainer:CreateFontString(nil, "ARTWORK")
targetPlayerNameText:SetPoint("TOP", targetLabelText, "BOTTOM", 0, -2)
targetPlayerNameText:SetPoint("LEFT", 7, 0)
local targetPlayerSubzoneText = targetFrameTextContainer:CreateFontString(nil, "ARTWORK")
targetPlayerSubzoneText:SetTextColor(1,.83,0)
targetPlayerSubzoneText:SetPoint("TOP", targetPlayerNameText, "BOTTOM", 0, 0)
targetPlayerSubzoneText:SetPoint("LEFT", 9, 0)
local targetScrollLabelText = targetFrameTextContainer:CreateFontString(nil, "ARTWORK")
targetScrollLabelText:SetPoint("TOP", targetPlayerSubzoneText, "BOTTOM", 0, -5)
targetScrollLabelText:SetPoint("LEFT", 5, 0)

local function UpdateTargetFrameDimensions()
    local hSLT = targetScrollLabelText:GetHeight()
    local hTLT = targetLabelText:GetHeight()
    local hTPNT = targetPlayerNameText:GetHeight()
    local hTPST = targetPlayerSubzoneText:GetHeight()
    if hSLT > 2 then hSLT = hSLT + 5 else hSLT = 0 end
    targetFrameTextContainer:SetHeight(12
            + hSLT
            + hTLT
            + hTPNT
            + hTPST
    )
    targetFrameTextContainer:SetWidth(max(
        10+targetScrollLabelText:GetWidth(),
        10+targetLabelText:GetWidth(),
        12+targetPlayerNameText:GetWidth(),
        14+targetPlayerSubzoneText:GetWidth()
    ))
end

function addon:UpdateBindings()
    if activeMeetingStone then
        ClearOverrideBindings(targetFrame)
        SetOverrideBindingClick(targetFrame, true, addon.opt.keybindTargetSelected, "SummonStoneHelperTargetButton")
        if addon.opt.keybindPreviousTarget then
            SetOverrideBindingClick(targetFrame, true, addon.opt.keybindPreviousTarget, "SummonStoneHelperScrollUpButton")
        end
        if addon.opt.keybindNextTarget then
            SetOverrideBindingClick(targetFrame, true, addon.opt.keybindNextTarget, "SummonStoneHelperScrollDownButton")
        end
    end
    targetLabelText:SetText(LocalizedString["Use %s to target:"]:format(("|cffffd300%s|r"):format(GetBindingText(addon.opt.keybindTargetSelected))))
    if addon.opt.keybindNextTarget then
        targetScrollLabelText:SetText(LocalizedString["Use %s to switch."]:format(("|cffffd300%s|r"):format(GetBindingText(addon.opt.keybindNextTarget))))
    else
        targetScrollLabelText:SetText("")
    end
    UpdateTargetFrameDimensions()
end

local LSM = LibStub("LibSharedMedia-3.0")
local function fontopt(t)
    local fontFile = t.enableFont and LSM:Fetch("font", t.font) or DEFAULT_CHAT_FRAME:GetFont()
    return fontFile, t.size, t.outline
end
function addon:UpdateFonts()
    local labelFont, labelSize, labelOutline = fontopt(addon.opt.fonts.label)
    targetLabelText:SetFont(labelFont, labelSize, labelOutline)
    targetScrollLabelText:SetFont(labelFont, labelSize, labelOutline)
    targetPlayerNameText:SetFont(fontopt(addon.opt.fonts.name))
    targetPlayerSubzoneText:SetFont(fontopt(addon.opt.fonts.zone))
    UpdateTargetFrameDimensions()
end

local UpdateFnDefault = function(target, current, candidate)
    if target <= current then
        return ((target <= candidate) and (candidate < current))
    else
        return ((target <= candidate) or (candidate < current))
    end
end

local UpdateFnIncrease = function(target, current, candidate)
    if target < current then
        return ((target < candidate) and (candidate < current))
    else
        return ((target < candidate) or (candidate < current))
    end
end

local UpdateFnDecrease = function(target, current, candidate)
    if target <= current then
        return ((candidate < target) or (current < candidate))
    else
        return ((candidate < target) and (current < candidate))
    end
end
local targetFrameSelected = nil
local function TargetFrameUpdate(isImprovement)
    if not activeMeetingStone then
        targetFrameTextContainer:Hide()
        dummyFrameTarget:SetAttribute("macrotext", "")
        return
    end

    if not isImprovement then isImprovement = UpdateFnDefault end

    local nFound = 0
    local selectedName, selectedSubzone, selectedClass, selectedClassColors, selectedIsDead
    local playerLevel = UnitLevel("player")
    if (playerLevel >= activeMeetingStone.levelMin) and (playerLevel <= activeMeetingStone.levelMax) then
        for i=1, GetNumGroupMembers() do
            local name, subzone, class, classColors, isDead = GetMemberNeedsSummon(i)
            if name then
                if (not targetFrameSelected) then
                    nFound = nFound+1
                    if random(nFound) == 1 then
                        selectedName, selectedSubzone, selectedClass, selectedClassColors, selectedIsDead = name, subzone, class, classColors, isDead
                    end
                elseif (not selectedName) or isImprovement(targetFrameSelected, selectedName, name) then
                    selectedName, selectedSubzone, selectedClass, selectedClassColors, selectedIsDead = name, subzone, class, classColors, isDead
                end
            end
        end
    end
    
    targetFrameSelected = selectedName
    if selectedName then
        if targetFrame:IsShown() then targetFrameTextContainer:Show() end
        targetPlayerNameText:SetTextColor(selectedClassColors:GetRGB())
        targetPlayerNameText:SetText(selectedName)
        targetPlayerSubzoneText:SetText(selectedSubzone)
        UpdateTargetFrameDimensions()
        dummyFrameTarget:SetAttribute("macrotext", ("/target %s"):format(selectedName))
    else
        targetFrameTextContainer:Hide()
        dummyFrameTarget:SetAttribute("macrotext", "")
    end
end
dummyFrameScrollUp:SetScript("OnClick", function() TargetFrameUpdate(UpdateFnDecrease) end)
dummyFrameScrollDown:SetScript("OnClick", function() TargetFrameUpdate(UpdateFnIncrease) end)

SummonTracker.RegisterUpdateCallback(function() if activeMeetingStone then TargetFrameUpdate() end end)

local targetFrameUpdateDelay = 0.2
targetFrame:SetScript("OnUpdate", function(_,e)
    local x,y = GetCursorPosition()
    targetFrame:SetPoint("CENTER", WorldFrame, "BOTTOMLEFT", x, min(y, WorldFrame:GetHeight()-50))
    
    if e < targetFrameUpdateDelay then
        targetFrameUpdateDelay = targetFrameUpdateDelay-e
    else
        targetFrameUpdateDelay = 0.2
        TargetFrameUpdate()
    end
end)
targetFrame:Hide()
targetFrame:SetScript("OnHide", function() targetFrameSelected = nil targetFrameTextContainer:Hide() end)

local unknownStonesNotified = {}
local function SetActiveMeetingStone(which, levels)
    local stoneData = which and SummonStoneData[which]
    if which and not stoneData then
        if not unknownStonesNotified[which] then
            unknownStonesNotified[which] = true
            print(LocalizedString["|cffffd300SummonStoneHelper:|r Unknown Meeting Stone |cffffd300%s|r."]:format(which))
        end
    end
    
    if activeMeetingStone == stoneData then return end
    
    activeMeetingStone = stoneData
    
    if stoneData then
        local levelMin, levelMax = levels:match("(%d+)%-(%d+)")
        if levelMin then
            levelMin, levelMax = tonumber(levelMin), tonumber(levelMax)
        else
            if not unknownStonesNotified[which] then
                unknownStonesNotified[which] = true
                if not levels:match("1d%-2d") then -- workaround for a blizzard formatstring bug; cf. issue #1
                    print(LocalizedString["|cffffd300SummonStoneHelper:|r Failed to parse level range for |cffffd300%s|r: |cffffd300%s|r"]:format(which, levels))
                end
            end
            levelMin = 1
            levelMax = 255
        end
        activeMeetingStone.levelMin = levelMin
        activeMeetingStone.levelMax = levelMax

        SetOverrideBindingClick(targetFrame, true, addon.opt.keybindTargetSelected, "SummonStoneHelperTargetButton")
        if addon.opt.keybindPreviousTarget then
            SetOverrideBindingClick(targetFrame, true, addon.opt.keybindPreviousTarget, "SummonStoneHelperScrollUpButton")
        end
        if addon.opt.keybindNextTarget then
            SetOverrideBindingClick(targetFrame, true, addon.opt.keybindNextTarget, "SummonStoneHelperScrollDownButton")
        end
        targetFrameUpdateDelay = 0.2
        TargetFrameUpdate()
        targetFrame:Show()
    else
        ClearOverrideBindings(targetFrame)
        targetFrame:Hide()
    end
end

local combatDisable = false
local updateTick = 0.2
local f = CreateFrame("Frame")
GameTooltip:HookScript("OnUpdate", function(_,e)
    if combatDisable then return end
    targetFrameTextContainer:SetAlpha(GameTooltip:GetAlpha())
    if e < updateTick then updateTick = updateTick-e return end
    updateTick = 0.2
    if GetMouseFocus() ~= WorldFrame or GameTooltipTextLeft1:GetText() ~= LocalizedString["Meeting Stone"] then
        SetActiveMeetingStone(nil)
        return
    end
    SetActiveMeetingStone(GameTooltipTextLeft2:GetText(), GameTooltipTextLeft3:GetText())
end)
GameTooltip:HookScript("OnShow", function() if not combatDisable then updateTick = 0 f:Show() end end)
GameTooltip:HookScript("OnHide", function() SetActiveMeetingStone(nil) f:Hide() end)

f:SetScript("OnEvent", function(_,e)
    if e == "PLAYER_REGEN_DISABLED" then
        combatDisable = true
        SetActiveMeetingStone(nil)
        f:Hide()
    elseif e == "PLAYER_REGEN_ENABLED" then
        combatDisable = false
        if GameTooltip:IsShown() then
            updateTick = 0
            f:Show()
        end
    end
end)
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
