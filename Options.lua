local name,addon = ...

local LocalizedString = addon.LocalizedString
if not LocalizedString then return end

local _G, tonumber, unpack, pairs, ipairs =
      _G, tonumber, unpack, pairs, ipairs
local LibStub, InterfaceOptionsFrame, InterfaceOptionsFrame_OpenToCategory, InterfaceOptionsListButton_ToggleSubCategories = 
      LibStub, InterfaceOptionsFrame, InterfaceOptionsFrame_OpenToCategory, InterfaceOptionsListButton_ToggleSubCategories

local LSM = LibStub("LibSharedMedia-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")

local defaults = {
    profile = {
        keybindTargetSelected = "SHIFT-BUTTON1",
        keybindPreviousTarget = "SHIFT-MOUSEWHEELUP",
        keybindNextTarget     = "SHIFT-MOUSEWHEELDOWN",
        
        fonts = {
            label = { enableFont = false, font = "Arial Narrow", size =  8, outline = "OUTLINE" },
            name =  { enableFont = false, font = "Arial Narrow", size = 14, outline = "OUTLINE" },
            zone =  { enableFont = false, font = "Arial Narrow", size = 10, outline = "OUTLINE" },
        },
    },
}

local options = {
    name = "SummonStoneHelper",
    type = "group",
    args = {
        keyBindings={
            name=LocalizedString["Key Bindings"],
            type="group",
            inline=true,
            order=1,
            args={
                targetSelected={
                    name=LocalizedString["Target selected player"],
                    type="keybinding",
                    order=1,
                    width="full",
                    get=function() return addon.opt.keybindTargetSelected end,
                    set=function(_,v)
                        if v=="" then
                            v=defaults.profile.keybindTargetSelected
                        end
                        addon.opt.keybindTargetSelected=v
                        addon:UpdateBindings()
                    end,
                },
                previousTarget={
                    name=LocalizedString["Select previous"],
                    type="keybinding",
                    order=2,
                    width=1.7,
                    get=function() return addon.opt.keybindPreviousTarget end,
                    set=function(_,v) addon.opt.keybindPreviousTarget=(v~="" and v) addon:UpdateBindings() end,
                },
                nextTarget={
                    name=LocalizedString["Select next"],
                    type="keybinding",
                    order=3,
                    width=1.7,
                    get=function() return addon.opt.keybindNextTarget end,
                    set=function(_,v) addon.opt.keybindNextTarget=(v~="" and v) addon:UpdateBindings() end,
                },
            }
        }
    }
}

local FONTOPTS = {[""]="No Outline", OUTLINE="Outline", THICKOUTLINE="Thick Outline", MONOCHROME="No Outline + Monochrome", ["OUTLINE,MONOCHROME"]="Outline + Monochrome", ["THICKOUTLINE,MONOCHROME"]="Thick Outline + Monochrome"}
local fontGroupArgs = {
    enableFont={
        name="",
        type="toggle",
        width=0.15,
        order=1,
    },
    font={
        name=function(ctx)
            if addon.opt.fonts[ctx[#ctx-1]].enableFont then
                return LocalizedString["Always use this font:"]
            else
                return LocalizedString["|cffffd300Override default chat font?|r"]
            end
        end,
        get=function(ctx)
            if addon.opt.fonts[ctx[#ctx-1]].enableFont then
                return addon.opt.fonts[ctx[#ctx-1]].font
            else
                return ""
            end
        end,
        type="select",
        values=LSM:HashTable("font"),
        dialogControl="LSM30_Font",
        disabled=function(ctx) return not addon.opt.fonts[ctx[#ctx-1]].enableFont end,
        order=2,
    },
    size={
        name=LocalizedString["Font size"],
        type="range",
        min=4,
        max=64,
        bigStep=1,
        order=3,
    },
    outline={
        name=LocalizedString["Font flags"],
        type="select",
        values=FONTOPTS,
        order=4,
    },
}
local fontOptions = {
    name = LocalizedString["SummonStoneHelper: Fonts"],
    type = "group",
    get = function(ctx)
        return addon.opt.fonts[ctx[#ctx-1]][ctx[#ctx]]
    end,
    set = function(ctx,v)
        addon.opt.fonts[ctx[#ctx-1]][ctx[#ctx]] = v
        addon:UpdateFonts()
    end,
    args = {
        label={
            name=LocalizedString["Labels"],
            type="group",
            inline=true,
            order=1,
            args=fontGroupArgs,
        },
        name={
            name=LocalizedString["Selected player's name"],
            type="group",
            inline=true,
            order=2,
            args=fontGroupArgs,
        },
        zone={
            name=LocalizedString["Selected player's current location"],
            type="group",
            inline=true,
            order=3,
            args=fontGroupArgs,
        },
    }
}

local listener = CreateFrame("Frame")
listener:SetScript("OnEvent", function(_, _, arg)
    if arg ~= name then return end
    listener:UnregisterEvent("ADDON_LOADED")
    addon.db = LibStub("AceDB-3.0"):New("SummonStoneHelper__DB", defaults, true)
    addon.db.RegisterCallback(addon, "OnProfileChanged", "OnProfileEnable")
    addon.db.RegisterCallback(addon, "OnProfileCopied", "OnProfileEnable")
    addon.db.RegisterCallback(addon, "OnProfileReset", "OnProfileEnable")
    addon:OnProfileEnable()
    
    local AC, ACD = LibStub("AceConfig-3.0"), LibStub("AceConfigDialog-3.0")
    AC:RegisterOptionsTable("SummonStoneHelper", options)
    local optionsRef = ACD:AddToBlizOptions("SummonStoneHelper")
    optionsRef.default = function()
        addon.opt.keybindTargetSelected = defaults.profile.keybindTargetSelected
        addon.opt.keybindPreviousTarget = defaults.profile.keybindPreviousTarget
        addon.opt.keybindNextTarget = defaults.profile.keybindNextTarget
        addon:UpdateBindings()
        ACR:NotifyChange("SummonStoneHelper")
    end
    local optionsRefDummy = { element = optionsRef }
    
    AC:RegisterOptionsTable("SummonStoneHelper-Fonts", fontOptions)
    local fontsRef = ACD:AddToBlizOptions("SummonStoneHelper-Fonts", LocalizedString["Fonts"], "SummonStoneHelper")
    fontsRef.default = function()
        for key in pairs(addon.opt.fonts) do
            local optT = addon.opt.fonts[key]
            local defaultT = defaults.profile.fonts[key]
            optT.enableFont = defaultT.enableFont
            optT.font = defaultT.font
            optT.size = defaultT.size
            optT.outline = defaultT.outline
        end
        addon:UpdateFonts()
        ACR:NotifyChange("SummonStoneHelper-Fonts")
    end
    
    AC:RegisterOptionsTable("SummonStoneHelper-Profile", LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db))
    ACD:AddToBlizOptions("SummonStoneHelper-Profile", LocalizedString["Profiles"], "SummonStoneHelper")
    
    _G.SlashCmdList.SummonStoneHelper = function()
        InterfaceOptionsFrame:Show() -- force it to load first
        InterfaceOptionsFrame_OpenToCategory(optionsRef) -- open to our category
        if optionsRef.collapsed then -- expand our sub-categories
            InterfaceOptionsListButton_ToggleSubCategories(optionsRefDummy)
        end
    end
    _G.SLASH_SummonStoneHelper1 = "/ssh"
    _G.SLASH_SummonStoneHelper2 = "/summonstonehelper"
    _G.SLASH_SummonStoneHelper3 = "/summon"
end)
listener:RegisterEvent("ADDON_LOADED")

function addon:OnProfileEnable()
    addon.opt = addon.db.profile
    addon:UpdateFonts()
    addon:UpdateBindings()
end
