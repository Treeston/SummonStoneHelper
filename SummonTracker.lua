local _, addon = ...

local PRIORITY_CAST_OBSERVED = 0
local PRIORITY_CHAT_NOTIFIED = 10
local PRIORITY_SELF_INFO = 100
local PRIORITY_CHANNEL_ONGOING = 10000

local SendAddonMessage = C_ChatInfo.SendAddonMessage

local updateCallbacks = {}
local summonChannels = {}
local summonIncomingChannels = setmetatable({},{__index=function(t,k) t[k] = {} return t[k] end})
local pendingSummons = {}

local function NotifyUpdateCallbacks()
    for fn in pairs(updateCallbacks) do
        xpcall(fn, geterrorhandler())
    end
end

local function RegisterPendingSummon(target, summoner, duration, priority)
    local existing = pendingSummons[target]
    if existing then
        if existing.priority > priority then return end
        existing.priority = priority
        existing.expiry = GetTime()+duration
        existing.summoner = summoner
    else
        pendingSummons[target] = { priority=priority, expiry=(GetTime()+duration), summoner=summoner }
    end
    NotifyUpdateCallbacks()
end

local function RegisterIncomingSummon(summoner, duration)
    RegisterPendingSummon(UnitGUID("player"), summoner, duration, PRIORITY_SELF_INFO)
        
    local c = IsInRaid() and "RAID" or IsInGroup() and "PARTY"
    if c then
        SendAddonMessage("SSH_SumTrack", ("%d|%s"):format(duration,summoner), c)
    end
end

local function SummonChannelCancelled(arg1)
    local summoner = UnitGUID(arg1)
    local target = summonChannels[summoner]
    if not target then return end
    
    local summonerName = GetUnitName(arg1)
    summonChannels[summoner] = nil
    summonIncomingChannels[target][summonerName] = nil
    RegisterPendingSummon(target, GetUnitName(arg1), 20, PRIORITY_CAST_OBSERVED)
end

local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(_,e,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,arg12)
    if e == "UNIT_SPELLCAST_CHANNEL_START" then
        if arg3 ~= 23598 then return end
        local summoner = UnitGUID(arg1)
        local target = UnitGUID(arg1.."target")
        if not target then return end
        
        local currentChannelTarget = summonChannels[summoner]
        if target == currentChannelTarget then return end
        
        if currentChannelTarget then
            SummonChannelCancelled(arg1)
        end
        
        local summonerName = GetUnitName(arg1)
        summonChannels[summoner] = target
        summonIncomingChannels[target][summonerName] = true
        
        NotifyUpdateCallbacks()
        
        if arg1 == "player" then
            local c = IsInRaid() and "RAID" or IsInGroup() and "PARTY"
            if c and (addon.opt.summonAnnounceText ~= "") then
                SendChatMessage(addon.opt.summonAnnounceText:format(GetUnitName("target")), c)
            end
        end
    elseif e == "UNIT_SPELLCAST_CHANNEL_STOP" then
        if arg3 ~= 23598 then return end
        SummonChannelCancelled(arg1)
    elseif e == "CONFIRM_SUMMON" then
        local duration = C_SummonInfo.GetSummonConfirmTimeLeft()
        if duration <= 0 then return end
        local summoner = C_SummonInfo.GetSummonConfirmSummoner()
        if not summoner then return end
        RegisterIncomingSummon(summoner, duration)
    elseif e == "CHAT_MSG_ADDON" then
        if arg1 ~= "SSH_SumTrack" then return end
        local target = UnitGUID(arg5)
        if not target then return end
        local duration, summoner = ("|"):split(arg2)
        duration = tonumber(duration)
        if not (duration and summoner) then return end
        
        RegisterPendingSummon(target, summoner, duration-1, PRIORITY_CHAT_NOTIFIED)
    else -- chat events
        if arg1:find("^%s*123") then
            RegisterPendingSummon(arg12, "-", -1, PRIORITY_CAST_OBSERVED)
        end
    end
end)
f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
f:RegisterEvent("CONFIRM_SUMMON")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("CHAT_MSG_RAID")
f:RegisterEvent("CHAT_MSG_RAID_LEADER")
f:RegisterEvent("CHAT_MSG_PARTY")
f:RegisterEvent("CHAT_MSG_PARTY_LEADER")
f:RegisterEvent("CHAT_MSG_WHISPER")
hooksecurefunc(C_SummonInfo, "CancelSummon", function() RegisterIncomingSummon("-",-1) end)

C_ChatInfo.RegisterAddonMessagePrefix("SSH_SumTrack")

addon.SummonTracker = {
    GetPendingSummonInfo = function(unit)
        local guid = UnitGUID(unit)
        if not guid then return end
        
        local currentlyChannelingName = next(summonIncomingChannels[guid])
        if currentlyChannelingName then
            return currentlyChannelingName, -1, PRIORITY_CHANNEL_ONGOING
        end
        
        local pendingSummon = pendingSummons[guid]
        if not pendingSummon then return end
        
        local duration = pendingSummon.expiry - GetTime()
        if duration <= 0 then
            pendingSummons[guid] = nil
            return
        end
        return pendingSummon.summoner, duration, pendingSummon.priority
    end,
    RegisterUpdateCallback = function(fn)
        updateCallbacks[fn] = true
    end,
    UnregisterUpdateCallback = function(fn)
        updateCallbacks[fn] = nil
    end,
}
