
-- Maps for each boss
--
-- Beigis and Mammon share a map (Brannoch Castle),
-- so they will be differentiated by submap
--
MAP_SOLVARING = 31
MAP_ZELSE = 33
MAP_NEPTY = 35
MAP_SHILF = 28
MAP_FARGO = 29
MAP_GUILTY = 30
MAP_BEIGIS = 30
MAP_MAMMON = 34

HITS_GUILTY = 74
HITS_BEIGIS = 60

MAP_BRANNOCH_CASTLE = 30

SUBMAP_GUILTY = 10
SUBMAP_BEIGIS = 14

MapIDToBossHits = {
    [MAP_SOLVARING] = 67,
    [MAP_ZELSE] = 60,
    [MAP_NEPTY] = 56,
    [MAP_SHILF] = 56,
    [MAP_FARGO] = 62,
    [MAP_GUILTY] = 74,
    [MAP_BEIGIS] = 60,
    [MAP_MAMMON] = 160
}

function GetBossHits(mapID, subMapID)
    if mapID == MAP_BRANNOCH_CASTLE then
        if subMapID == SUBMAP_GUILTY then
            return HITS_GUILTY
        else
            return HITS_BEIGIS
        end
    else
        return MapIDToBossHits[mapID]
    end
end

function Round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function GetExpectedRockHits(overlaps)
    local TOTAL_POSSIBLE = 320
    local ROCK_COUNT = 10

    local percent = (1.0 * overlaps) / TOTAL_POSSIBLE
    local expected = ROCK_COUNT * percent

    return expected
end

function RocksBrianToEnemy(BrianX1, BrianY1, EnemyX1, EnemyY1, Size1)

    local validRocks = 0
    local totalPossible = 0

    for i = 0, 15 do -- Angles
        for j = 20, 39 do -- Distances
            local x = BrianX1 + j * math.cos(i * 22.5 * math.pi / 180)
            local y = BrianY1 + j * math.sin(i * 22.5 * math.pi / 180)

            XDiff1 = x - EnemyX1
            YDiff1 = y - EnemyY1
            D1 = math.sqrt(XDiff1 * XDiff1 + YDiff1 * YDiff1)
            if D1 <= Size1 + 10 then
                validRocks = validRocks + 1
            end

            totalPossible = totalPossible + 1
        end
    end

    local percent = (1.0 * validRocks) / totalPossible

    return validRocks, 100.0 * percent, totalPossible
end

function HeatMapGenerator()
    MapSize = 120
    brianX = math.floor(MapSize / 2)
    brianY = math.floor(MapSize / 2)
    Size = 6.3
    -- Solvaring 10 + 8.4  Note: Solvaring is moving about half a pixel during standing.
    -- Zelse 10 + 5.6  (Investigate Zelse Mid-Range)  Zelse moves about 0.4 pixels during standing.  He recoils a couple pixels when hit.
    -- Nepty 10 + 4.9  Nepty moves about 0.4 px during standing.
    -- Shilf 10 + 4.9  Shilf moves about 0.05
    -- Fargo 10 + 7 moves about 0.05
    -- Guilty 10 + 9.52 No movement
    -- Beigis 10 + 6.3 No movement
    -- Mammon 10 + 94.5 Moves around 0.6 px.
    heatTextfile = "HeatMap"
    heatDumpfile = heatTextfile .. ".txt"
    io.output(heatDumpfile)

    Max = 0

    for EnemyX = 0, MapSize do
        for EnemyY = MapSize, 0, -1 do
            R = RocksBrianToEnemy(brianX, brianY, EnemyX, EnemyY, Size)
            if R > Max then
                Max = R
            end
            io.write(string.format("%02X ", R))
        end
        io.write("\n")
    end

    io.write("\n")
    io.write("EnemySize: " .. Size)
    io.write("\n")
    io.write("Max: ", string.format("%02X", Max))
    io.write("\n")
    io.write("MapSize: " .. MapSize + 1)

    io.output():close()

end

function GetMapIDs()
    local mapID = memory.readbyte(0x8536B, "RDRAM")
    local subMapID = memory.readbyte(0x8536F, "RDRAM")

    return mapID, subMapID
end

function CalculateBossSize()
    local sizeModifier = memory.readfloat(0x7C9E0, true, "RDRAM")
    local trueSize = memory.readfloat(0x7C9E4, true, "RDRAM")
    local size = sizeModifier * trueSize

    return Round(size, 3)
end

LastMapID = -1
LastSubMapID = -1
BestExpected = 0
BestIntersections = 0

function HowManyRocksCurrently(x, y)

    local brianX = memory.readfloat(0x7BACC, true, "RDRAM")
    local brianY = memory.readfloat(0x7BAD4, true, "RDRAM")

    local i = 1 -- Enemy number 1 (starting at 1)

    local EnemyX = memory.readfloat(0x7C9BC + 296 * (i - 1), true, "RDRAM")
    local EnemyY = memory.readfloat(0x7C9C4 + 296 * (i - 1), true, "RDRAM")
    
    local XDiff = brianX - EnemyX
    local YDiff = brianY - EnemyY
    
    local size = CalculateBossSize()

    local D = math.sqrt(XDiff * XDiff + YDiff * YDiff)
    local A = math.atan2(XDiff, YDiff) * (180 / (math.pi))

    local validRocks, percent, total = RocksBrianToEnemy(brianX, brianY, EnemyX, EnemyY, size)
    local expected = GetExpectedRockHits(validRocks)

    if (BestExpected < expected) then
        BestExpected = expected
    end
    if (BestIntersections < validRocks) then
        BestIntersections = validRocks
    end

    local comparedToBest = -1
    if BestExpected > 0 then
        comparedToBest = expected / BestExpected
    end

    local color = "red"
    if (comparedToBest > 0.9) then
        color = "cyan"
    elseif (comparedToBest > 0.75) then
        color = "yellow"
    elseif (comparedToBest > 0.5) then
        color = "orange"
    elseif (comparedToBest == -1) then
        color = "gray"
    end

    local comparedString = "Unknown"
    if (comparedToBest ~= -1) then
        comparedString = Round(100 * comparedToBest, 0) .. "% optimal"
    end

    gui.text(x, y + 15 * 1, "Boss Size:  " .. size)
    gui.text(x, y + 15 * 2, "Boss Distance: " .. Round(D, 3))

    gui.text(x, y + 15 * 4, "Live")
    gui.text(x, y + 15 * 5, "Positioning: " .. comparedString, color)
    gui.text(x, y + 15 * 6, "Intersections:  " .. validRocks .. " of " .. total)
    gui.text(x, y + 15 * 7, "Expected Rocks: " .. expected)

    gui.text(x, y + 15 * 9, "Best")
    gui.text(x, y + 15 * 10, "Best Intersections:  " .. BestIntersections)
    gui.text(x, y + 15 * 11, "Best Expected Rocks: " .. BestExpected)
    
end

while true do

    local mapID, subMapID = GetMapIDs()
    if (mapID ~= LastMapID or subMapID ~= LastSubMapID) then

        local idealHits = GetBossHits(mapID, subMapID)
        if (idealHits ~= nil) then
            local expected = GetExpectedRockHits(idealHits)
    
            LastMapID = mapID
            LastSubMapID = subMapID
            BestIntersections = idealHits
            BestExpected = expected
        end
    end 

    HowManyRocksCurrently(50, 225)

    emu.frameadvance()
end
