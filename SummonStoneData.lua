local _, addon = ...

local LocalizedString = addon.LocalizedString
if not LocalizedString then return end

local GetAreaInfo = C_Map.GetAreaInfo

local DATA = {}
addon.SummonStoneData = DATA

local patchString,buildString = GetBuildInfo()
local buildInfoString = ("%s.%s"):format(patchString,buildString)

local function RegisterStone(stoneAreaId, stoneMapId, acceptedMapIds, acceptedAreaIds)
    local stoneNameL = GetAreaInfo(stoneAreaId)
    if not stoneNameL then
        print(("|cffffd300SummonStoneHelper:|r Missing data for Meeting Stone |cffffd300%d|r (build |cffffd300%s|r) - skipped."):format(stoneAreaId, buildInfoString))
        return
    end
    
    local mapsIdx, zonesIdx = {},{[stoneNameL]=true}
    for _,mapId in ipairs(acceptedMapIds) do
        mapsIdx[mapId] = true
    end
    for _,areaId in ipairs(acceptedAreaIds) do
        local zoneNameL = GetAreaInfo(areaId)
        if zoneNameL then
            zonesIdx[zoneNameL] = true
        else
            print(("|cffffd300SummonStoneHelper:|r Missing data for subzone |cffffd300%d|r near the |cffffd300%s|r stone (build |cffffd300%s|r) - skipped."):format(areaId, stoneNameL, buildInfoString))
        end
    end
    
    DATA[stoneNameL] = { name=stoneNameL, stoneMapId=stoneMapId, maps=mapsIdx, zones=zonesIdx }
end

RegisterStone(3545, -- Hellfire Citadel (can be either 5mans or Magtheridon, the stones have the same name)
    530, -- Outland
    { 543, 542, 540, 544 }, -- Ramps, BF, SHH, Magtheridon
    { 3545, 3955 } -- Hellfire Citadel, Hellfire Basin
)

RegisterStone(3519, -- Auchindoun
    530, -- Outland
    { 557, 558, 556, 555 }, -- MT, AC, SEH, SL
    { 3519, 3893 } -- Auchindoun, Ring of Observance
)

RegisterStone(3959, -- Black Temple
    530, -- Outland
    { 564 }, -- BT
    { 3520, 3756, 3757 } -- Shadowmoon Valley, Ruins of Karabor, Ata'mal Terrace
)

RegisterStone(3607, -- Serpentshrine Cavern
    530, -- Outland
    { 547, 545, 546, 548 }, -- SP, UB, SV, SSC
    { 3905 } -- Coilfang Reservoir
)

RegisterStone(3522, -- Blade's Edge Mountains
    530, -- Outland
    { 565 }, -- Gruul's Lair
    { 3774 } -- Gruul's Lair
)

RegisterStone(3523, -- Netherstorm
    530, -- Outland
    { 553, 554, 552, 550 }, -- Bota, Mech, Arca, TK
    { 3728, 3731, 3721, 3724, 3842 } -- The Vortex Fields, The Tempest Rift, The Crumbling Waste, Cosmowrench, Tempest Keep
)

RegisterStone(2437, -- Ragefire Chasm
    1, -- Kalimdor
    { 389 }, -- Ragefire Chasm
    { 1637 } -- Orgrimmar
)

RegisterStone(719, -- Blackfathom Deeps
    1, -- Kalimdor
    { 48 }, -- Blackfathom Deeps
    { 414, 2797 } -- The Zoram Strand, Blackfathom Deeps
)

RegisterStone(718,
    1, -- Kalimdor
    { 43 }, -- Wailing Caverns
    { 387, 718 } -- Lushwater Oasis, Wailing Caverns
)

RegisterStone(2100,
    1, -- Kalimdor
    { 349 }, -- Maraudon
    { 607, 2100 } -- Valley of Spears, Maraudon
)

RegisterStone(2557, -- Dire Maul
    1, -- Kalimdor
    { 429 }, -- Dire Maul
    { 2577 } -- Dire Maul
)

RegisterStone(491, -- Razorfen Kraul
    1, -- Kalimdor
    { 47 }, -- Razorfen Kraul
    { 1717 } -- Razorfen Kraul
)

RegisterStone(722, -- Razorfen Downs
    1, -- Kalimdor
    { 129 }, -- Razorfen Downs
    { 1316 } -- Razorfen Downs
)

RegisterStone(2159, -- Onyxia's Lair
    1, -- Kalimdor
    { 249 }, -- Onyxia's Lair
    { 511, 2159 } -- Wyrmbog, Onyxia's Lair
)

RegisterStone(1176, -- Zul'Farrak
    1, -- Kalimdor
    { 209 }, -- Zul'Farrak
    { 978, 979 } -- Zul'Farrak, Sandsorrow Watch
)

RegisterStone(2300, -- Caverns of Time
    1, -- Kalimdor
    { 560, 269, 534 }, -- OHF, BM, MH
    { 2300 } -- Caverns of Time
)
-- @todo add data for other meeting stones
