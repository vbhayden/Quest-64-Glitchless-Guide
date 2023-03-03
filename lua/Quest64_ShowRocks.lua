
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

function Factorial(k)
	local result = 1;
    
    for i = 1, k do
	    result = result * i;
    end

	return result;
end

function NChooseK(n, k)
    local numerator = Factorial(n)
    local demoninator = Factorial(n - k) * Factorial(k)

    return numerator / demoninator
end

function Binomial(chance, successes, trials)
    
    local coefficient = NChooseK(trials, successes)
    return coefficient * (chance ^ successes) * (1 - chance) ^ (trials - successes)
end

function Round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function Ternary ( cond , T , F )
    if cond then return T else return F end
end

function GuiTextWithColor(row_index, text, color)
    
    local borderWidth = client.borderwidth();
    gui.text(borderWidth + 40, 200 + row_index * 15, text, color)
end

function GuiText(row_index, text)
    GuiTextWithColor(row_index, text, "white")
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

    local hitChance = (1.0 * validRocks) / totalPossible

    return validRocks, hitChance, totalPossible
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

function HowManyRocksCurrently(index)

    local brianX = memory.readfloat(0x7BACC, true, "RDRAM")
    local brianY = memory.readfloat(0x7BAD4, true, "RDRAM")

    local i = 1 -- Enemy number 1 (starting at 1)

    local EnemyX = memory.readfloat(0x7C9BC + 296 * (i - 1), true, "RDRAM")
    local EnemyY = memory.readfloat(0x7C9C4 + 296 * (i - 1), true, "RDRAM")
    
    local XDiff = brianX - EnemyX
    local YDiff = brianY - EnemyY
    
    local size = CalculateBossSize()
    local distance = math.sqrt(XDiff * XDiff + YDiff * YDiff)

    local validRocks, hitChance, total = RocksBrianToEnemy(brianX, brianY, EnemyX, EnemyY, size)
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

    GuiText(index + 1, "Boss Size:  " .. size)
    GuiText(index + 2, "Boss Distance: " .. Round(distance, 3))

    -- GuiText(index + 4, "Live")
    GuiTextWithColor(index + 4, "Positioning: " .. comparedString, color)
    GuiText(index + 5, "Intersections:  " .. validRocks .. " of " .. total)
    GuiText(index + 6, "Expected Rocks: " .. expected)

    -- GuiText(index + 9, "Best")
    -- GuiText(index + 10, "Best Intersections:  " .. BestIntersections)
    -- GuiText(index + 11, "Best Expected Rocks: " .. BestExpected)
    
    GuiText(index + 8, "Avalanche Outcomes:")

    local expectedHitsRounded = Round(expected, 0)
    local atLeastOne = 1 - (1 - hitChance) ^ 10

    for hits = 0, 10 do
        local number = Ternary(hits < 10, " " .. hits, hits)
        local chance = Binomial(hitChance, hits, 10)
        local blocks = Round(chance * 100) / 4

        GuiText(index + 9 + hits, number .. "|" .. string.rep("=", blocks))
    end

    return expected
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

    HowManyRocksCurrently(0)

    emu.frameadvance()
end
