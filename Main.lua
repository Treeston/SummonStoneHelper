local _G, StaticTooltip_Show, GetCursorPosition, CreateFrame =
      _G, StaticTooltip_Show, GetCursorPosition, CreateFrame
local GameTooltipTextLeft1, GameTooltipTextLeft2 =
      GameTooltipTextLeft1, GameTooltipTextLeft2

local _, addon = ...

local SummonTracker, SummonStoneData, LocalizedString = addon.SummonTracker, addon.SummonStoneData, addon.LocalizedString

if not LocalizedString then return end

print(("|cffffd300SummonStoneHelper|r: Loaded for locale |cffffd300%s|r."):format(GetLocale()))

-- { name, stoneMapId, maps, zones }
local activeMeetingStone

local function GetMemberNeedsSummon(idx)
    if not activeMeetingStone then return end
    
    local name, _, _, _, class, classFile, subzone, isOnline, isDead = GetRaidRosterInfo(idx)
    if not isOnline then return end
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
targetLabelText:SetFont(fontFace, 8, "OUTLINE")
targetLabelText:SetPoint("TOPLEFT", 5, -5)
targetLabelText:SetText(LocalizedString["Use %s to target:"]:format(("|cffffd300%s|r"):format(GetBindingText("SHIFT-BUTTON1"))))
local targetPlayerNameText = targetFrameTextContainer:CreateFontString(nil, "ARTWORK")
targetPlayerNameText:SetFont(fontFace, 14, "OUTLINE")
targetPlayerNameText:SetPoint("TOPLEFT", 7, -15)
local targetPlayerSubzoneText = targetFrameTextContainer:CreateFontString(nil, "ARTWORK")
targetPlayerSubzoneText:SetFont(fontFace, 10, "OUTLINE")
targetPlayerSubzoneText:SetTextColor(1,.83,0)
targetPlayerSubzoneText:SetPoint("TOPLEFT", 9, -30)
local targetScrollLabelText = targetFrameTextContainer:CreateFontString(nil, "ARTWORK")
targetScrollLabelText:SetFont(fontFace, 8, "OUTLINE")
targetScrollLabelText:SetPoint("TOPLEFT", 5, -42)
targetScrollLabelText:SetText(LocalizedString["Use %s to switch."]:format(("|cffffd300%s|r"):format(GetBindingText("SHIFT-MOUSEWHEELDOWN"))))


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
    if not isImprovement then isImprovement = UpdateFnDefault end

    local nFound = 0
    local selectedName, selectedSubzone, selectedClass, selectedClassColors, selectedIsDead
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
    
    targetFrameSelected = selectedName
    if selectedName then
        if targetFrame:IsShown() then targetFrameTextContainer:Show() end
        targetPlayerNameText:SetTextColor(selectedClassColors:GetRGB())
        targetPlayerNameText:SetText(selectedName)
        targetPlayerSubzoneText:SetText(selectedSubzone)
        dummyFrameTarget:SetAttribute("macrotext", ("/target %s"):format(selectedName))
    else
        targetFrameTextContainer:Hide()
        dummyFrameTarget:SetAttribute("macrotext", "")
    end
end
dummyFrameScrollUp:SetScript("OnClick", function() TargetFrameUpdate(UpdateFnDecrease) end)
dummyFrameScrollDown:SetScript("OnClick", function() TargetFrameUpdate(UpdateFnIncrease) end)

SummonTracker.RegisterUpdateCallback(function() TargetFrameUpdate() end)

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
local function SetActiveMeetingStone(which)
    local stoneData = which and SummonStoneData[which]
    if which and not stoneData then
        if not unknownStonesNotified[which] then
            unknownStonesNotified[which] = true
            print(("|cffffd300SummonStoneHelper:|r Unknown Meeting Stone |cffffd300%s|r."):format(which))
        end
    end
    
    if activeMeetingStone == stoneData then return end
    
    activeMeetingStone = stoneData
    
    if stoneData then
        SetOverrideBindingClick(targetFrame, true, "SHIFT-BUTTON1", "SummonStoneHelperTargetButton")
        SetOverrideBindingClick(targetFrame, true, "SHIFT-MOUSEWHEELUP", "SummonStoneHelperScrollUpButton")
        SetOverrideBindingClick(targetFrame, true, "SHIFT-MOUSEWHEELDOWN", "SummonStoneHelperScrollDownButton")
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
    SetActiveMeetingStone(GameTooltipTextLeft2:GetText())
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

-- @todo aceconfig support
