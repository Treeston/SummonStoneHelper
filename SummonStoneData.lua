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

RegisterStone(3688, -- Auchindoun
    530, -- Outland
    { 557, 558, 556, 555 }, -- MT, AC, SEH, SL
    { 3688, 3893 } -- Auchindoun, Ring of Observance
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

RegisterStone(718, -- Wailing Caverns
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

RegisterStone(3428, -- Ahn'Qiraj
    1, -- Kalimdor
    { 509, 531 }, -- AQ20, AQ40
    { 2737, 2741, 3478 } -- The Scarab Wall, The Scarab Dais, Gates of Ahn'Qiraj
)

RegisterStone(796, -- Scarlet Monastery
    0, -- Eastern Kingdoms
    { 189 }, -- Scarlet Monastery
    { 160, 796 } -- Whispering Gardens, Scarlet Monastery
)

RegisterStone(2057, -- Scholomance
    0, -- Eastern Kingdoms
    { 289 }, -- Scholomance
    { 2298, 2057 } -- Caer Darrow, Scholomance
)

RegisterStone(2017, -- Stratholme
    0, -- Eastern Kingdoms
    { 329 }, -- Stratholme
    { 2625, 2277, 2627, 2279 } -- Eastwall Gate, Plaguewood, Terrordale, Stratholme
)

RegisterStone(3805, -- Zul'Aman
    530, -- "Outland" (Ghostlands)
    { --[[ @todo ZA map ID --]] }, -- Zul'Aman
    { 3508, 3805 } -- Amani Pass, Zul'Aman
)

RegisterStone(209, -- Shadowfang Keep
    0, -- Eastern Kingdoms
    { 33 }, -- Shadowfang Keep
    { 130 } -- Shadowfang Keep
)

RegisterStone(721, -- Gnomeregan
    0, -- Eastern Kingdoms
    { 90 }, -- Gnomeregan
    { 133 } -- Gnomeregan
)

RegisterStone(1337, -- Uldaman
    0, -- Eastern Kingdoms
    { 70 }, -- Uldaman
    { 1517, 1897 } -- Uldaman, The Maker's Terrace
)

RegisterStone(1584, -- Blackrock Depths
    0, -- Eastern Kingdoms
    { 230, 229, 409, 469 }, -- Blackrock Depths, Blackrock Spire, Molten Core, Blackwing Lair
    { 25, 254, 1445, } -- Blackrock Mountain (x3)
)

RegisterStone(1583, -- Blackrock Spire
    0, -- Eastern Kingdoms
    { 230, 229, 409, 469 }, -- Blackrock Depths, Blackrock Spire, Molten Core, Blackwing Lair
    { 25, 254, 1445, } -- Blackrock Mountain (x3)
)

RegisterStone(717, -- The Stockade
    0, -- Eastern Kingdoms
    { 34 }, -- The Stockade
    { 1519 } -- Stormwind City
)

RegisterStone(1581, -- The Deadmines
    0, -- Eastern Kingdoms
    { 36 }, -- The Deadmines
    { 1581, 20 } -- The Deadmines, Moonbrook
)

RegisterStone(3457, -- Karazhan
    0, -- Eastern Kingdoms
    { 532 }, -- Karazhan
    { 2562, 2837 } -- Karazhan, The Master's Cellar
)

RegisterStone(1477, -- Sunken Temple
    0, -- Eastern Kingdoms
    { 109 }, -- Sunken Temple
    { 74, 1477 } -- Poor of Tears, The Temple of Atal'Hakkar
)

RegisterStone(1977, -- Zul'Gurub
    0, -- Eastern Kingdoms
    { 309 }, -- Zul'Gurub
    { 19 } -- Zul'Gurub
)
